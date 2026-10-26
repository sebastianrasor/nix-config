const API_ENDPOINT = "/api/contact";
const TURNSTILE_HEADER = "CF-Turnstile-Token";
const PROBLEM_JSON_MEDIA_TYPE = "application/problem+json";
const PLAIN_TEXT_MEDIA_TYPE = "text/plain";

const BASE_NOTICE_DURATION_MS = 3_000;
const MS_PER_CHARACTER = 50;

const BUTTON_TEXT = {
  READY: "Send Message",
  WAITING: "Please wait...",
};

const NOTICE = {
  SENDING: "Sending your message...",
  ERROR: "Security verification failed. Retrying...",
  EXPIRED: "Security verification expired. Refreshing...",
  UNSUPPORTED: "Your browser does not support security verification.",
  NETWORK_ERROR: "Network error. Please check your connection and try again.",
  SERVER_ERROR:
    "The server was unable to complete your request. Please try again later.",
};

const form = document.getElementById("contact-form");
const successArticle = document.getElementById("success");
const submitButton = document.getElementById("submit-button");
const statusText = document.getElementById("form-status");
const turnstileContainer = form.querySelector(".cf-turnstile");
const formFields = [...form.querySelectorAll("input, textarea")];

let turnstileToken = null;
let isSubmitting = false;
let activeNotice = null;
let noticeTimeoutId = null;

function calculateNoticeDuration(message) {
  return BASE_NOTICE_DURATION_MS + message.length * MS_PER_CHARACTER;
}

function canSubmit() {
  return Boolean(turnstileToken) && !isSubmitting && activeNotice === null;
}

function syncUiState() {
  const currentNotice = activeNotice ?? (isSubmitting ? NOTICE.SENDING : null);
  const isBusy = currentNotice !== null;
  const isReady = canSubmit();

  if (isBusy && formFields.includes(document.activeElement)) {
    document.activeElement.blur();
  }

  statusText.textContent = currentNotice ?? "";

  submitButton.disabled = !isReady;
  submitButton.textContent = isReady ? BUTTON_TEXT.READY : BUTTON_TEXT.WAITING;

  for (const field of formFields) {
    field.readOnly = isBusy;
  }
}

function showNotice(message) {
  if (noticeTimeoutId !== null) {
    clearTimeout(noticeTimeoutId);
  }

  activeNotice = message;
  syncUiState();

  noticeTimeoutId = setTimeout(() => {
    activeNotice = null;
    noticeTimeoutId = null;
    syncUiState();
  }, calculateNoticeDuration(message));
}

function verificationFailed(notice) {
  turnstileToken = null;
  showNotice(notice);
}

/**
 * Renders the Turnstile widget explicitly once the Turnstile script has loaded.
 *
 * Callbacks only update the UI: Turnstile retries failures and refreshes expired tokens on
 * its own (`retry` and `refresh-expired` both default to `auto`), calling `callback` again
 * with the new token.
 */
function renderTurnstile() {
  window.turnstile.render(turnstileContainer, {
    callback(token) {
      turnstileToken = token;
      syncUiState();
    },
    "error-callback"() {
      verificationFailed(NOTICE.ERROR);
      // Marks the error as handled, so Turnstile doesn't also log a console warning.
      return true;
    },
    "expired-callback"() {
      verificationFailed(NOTICE.EXPIRED);
    },
    "unsupported-callback"() {
      verificationFailed(NOTICE.UNSUPPORTED);
    },
    "before-interactive-callback"() {
      turnstileContainer.hidden = false;
    },
    "after-interactive-callback"() {
      turnstileContainer.hidden = true;
    },
  });
}

if (window.turnstile) {
  renderTurnstile();
} else {
  const turnstileScript = document.querySelector('script[src*="turnstile"]');
  turnstileScript?.addEventListener("load", renderTurnstile, { once: true });
  turnstileScript?.addEventListener(
    "error",
    () => verificationFailed(NOTICE.ERROR),
    { once: true },
  );
}

/**
 * Extracts a user-facing message and the offending field (if any) from an error response.
 *
 * The contact API answers with RFC 9457 problem details and the Turnstile middleware with
 * plain text. Any other body (such as a proxy's HTML error page) isn't fit to display.
 */
async function readErrorResponse(response) {
  const contentType = response.headers.get("Content-Type") ?? "";

  if (contentType.startsWith(PROBLEM_JSON_MEDIA_TYPE)) {
    const { detail, title, field } = await response.json();
    return {
      message: detail ?? title ?? NOTICE.SERVER_ERROR,
      field: field ?? null,
    };
  }

  if (contentType.startsWith(PLAIN_TEXT_MEDIA_TYPE)) {
    return { message: await response.text(), field: null };
  }

  return { message: NOTICE.SERVER_ERROR, field: null };
}

async function handleSubmit(event) {
  event.preventDefault();

  if (!canSubmit()) {
    return;
  }

  isSubmitting = true;
  syncUiState();

  let failureNotice = NOTICE.NETWORK_ERROR;
  let invalidField = null;

  try {
    const response = await fetch(API_ENDPOINT, {
      method: "POST",
      headers: {
        [TURNSTILE_HEADER]: turnstileToken,
      },
      body: new URLSearchParams(new FormData(form)),
    });

    if (response.ok) {
      form.hidden = true;
      successArticle.hidden = false;
      successArticle.focus();
      return;
    }

    const { message, field } = await readErrorResponse(response);
    const candidate = field ? form.elements.namedItem(field) : null;
    invalidField = candidate instanceof HTMLElement ? candidate : null;
    invalidField?.setCustomValidity(message);
    failureNotice = message;
  } catch {
    // Use default `NOTICE.NETWORK_ERROR`.
  }

  // Only failed attempts get here. Tokens are single-use, so get a fresh one.
  turnstileToken = null;
  isSubmitting = false;
  window.turnstile?.reset();

  if (invalidField !== null) {
    syncUiState();
    invalidField.reportValidity();
  } else {
    showNotice(failureNotice);
  }
}

form.addEventListener("input", (event) => event.target.setCustomValidity(""));
form.addEventListener("submit", handleSubmit);

syncUiState();
