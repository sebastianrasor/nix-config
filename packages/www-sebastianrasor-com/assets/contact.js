const API_ENDPOINT = "/api/contact";
const TURNSTILE_HEADER = "CF-Turnstile-Token";
const TURNSTILE_FIELD = "cf-turnstile-response";
const PROBLEM_JSON_MEDIA_TYPE = "application/problem+json";
const PLAIN_TEXT_MEDIA_TYPE = "text/plain";

const BASE_NOTICE_DURATION_MS = 3_000;
const MS_PER_CHARACTER = 50;

const BUTTON_VALUE = {
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
const messageInput = document.getElementById("message");
const messageLabel = document.querySelector("label[for=message]");
const formFields = [...form.querySelectorAll("input:not(.button), textarea")];

const defaultMessageLabel = messageLabel.textContent;

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

  if (isBusy) {
    messageInput.blur();
  }

  messageLabel.textContent = currentNotice ?? defaultMessageLabel;

  submitButton.disabled = !isReady;
  submitButton.value = isReady ? BUTTON_VALUE.READY : BUTTON_VALUE.WAITING;

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
 * Turnstile widget callbacks, named in `contact.html.hbs`.
 *
 * These only update the UI: Turnstile retries failures and refreshes expired tokens on its
 * own (`retry` and `refresh-expired` both default to `auto`), calling `onSuccess` again
 * with the new token.
 */
const turnstileCallbacks = {
  onSuccess(token) {
    turnstileToken = token;
    syncUiState();
  },

  onError() {
    verificationFailed(NOTICE.ERROR);
    // Marks the error as handled, so Turnstile doesn't also log a console warning.
    return true;
  },

  onExpired() {
    verificationFailed(NOTICE.EXPIRED);
  },

  onUnsupported() {
    verificationFailed(NOTICE.UNSUPPORTED);
  },
};

Object.assign(window, turnstileCallbacks);

/**
 * Extracts a user-facing message and the offending field (if any) from an error response.
 *
 * The contact API answers with RFC 9457 problem details and the Turnstile middleware with
 * plain text. Any other body (such as a proxy's HTML error page) isn't fit to display.
 */
async function readErrorResponse(response) {
  const mediaType = response.headers
    .get("Content-Type")
    ?.split(";")[0]
    .trim()
    .toLowerCase();

  if (mediaType === PROBLEM_JSON_MEDIA_TYPE) {
    const problem = await response.json().catch(() => null);
    const message =
      (typeof problem?.detail === "string" && problem.detail.trim()) ||
      (typeof problem?.title === "string" && problem.title.trim()) ||
      NOTICE.SERVER_ERROR;
    const field = typeof problem?.field === "string" ? problem.field : null;
    return { message, field };
  }

  if (mediaType === PLAIN_TEXT_MEDIA_TYPE) {
    const text = (await response.text()).trim();
    return { message: text || NOTICE.SERVER_ERROR, field: null };
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

  // The token travels in a header, so drop the copy the widget adds to the form.
  const formData = new FormData(form);
  formData.delete(TURNSTILE_FIELD);

  let failureNotice = NOTICE.NETWORK_ERROR;

  try {
    const response = await fetch(API_ENDPOINT, {
      method: "POST",
      headers: {
        [TURNSTILE_HEADER]: turnstileToken,
      },
      body: new URLSearchParams(formData),
    });

    if (response.ok) {
      form.hidden = true;
      successArticle.hidden = false;
      return;
    }

    const { message, field } = await readErrorResponse(response);
    formFields.find((el) => el.name === field)?.setCustomValidity(message);
    failureNotice = message;
  } catch {
    // Use default `NOTICE.NETWORK_ERROR`.
  }

  // Only failed attempts get here. Tokens are single-use, so get a fresh one.
  turnstileToken = null;
  isSubmitting = false;
  window.turnstile?.reset();
  showNotice(failureNotice);
}

form.addEventListener("input", (event) => event.target.setCustomValidity(""));
form.addEventListener("submit", handleSubmit);

// The Turnstile script loads `async`, so it may have rendered the widget and solved the
// challenge before this module defined `onSuccess`. Pick up any token issued in the meantime.
const existingToken = window.turnstile?.getResponse();
if (existingToken) {
  turnstileCallbacks.onSuccess(existingToken);
}
