const API_ENDPOINT = "/api/contact";
const TIMESTAMP_HEADER = "X-Timestamp";
const PROBLEM_JSON_MEDIA_TYPE = "application/problem+json";

const BASE_NOTICE_DURATION_MS = 3_000;
const MS_PER_CHARACTER = 50;
const SESSION_DURATION_MS = 60 * 60 * 1_000;

const BUTTON_TEXT = {
  READY: "Send Message",
  WAITING: "Please wait...",
  EXPIRED: "Session expired",
};

const NOTICE = {
  SENDING: "Sending your message...",
  NETWORK_ERROR: "Network error. Please check your connection and try again.",
  SERVER_ERROR:
    "The server was unable to complete your request. Please try again later.",
};

const form = document.getElementById("contact-form");
const successArticle = document.getElementById("success");
const submitButton = document.getElementById("submit-button");
const statusText = document.getElementById("form-status");
const formFields = [...form.querySelectorAll("input, textarea")];

form.elements["given-name"].required = false;
form.elements["family-name"].autocomplete = "name";
form.querySelector('label[for="family-name"]').textContent = "Your Name";

const controller = new AbortController();
const { signal } = controller;

// Mirror each input's value into its underline element, followed by enough em
// spaces to run past the end of any row. Keeping the text and the extension in
// one text node gives them one continuous native underline (see stylesheet).
// The extension can't use the `word-spacing` trick, as that would also widen
// the spaces in the copied value.
const UNDERLINE_EXTENSION = "\u2003".repeat(256);

for (const input of form.querySelectorAll("input")) {
  const underline = input.parentElement.querySelector(".input-underline");
  const syncUnderline = () => {
    underline.textContent = input.value + UNDERLINE_EXTENSION;
  };
  input.addEventListener("input", syncUnderline, { signal });
  syncUnderline();
}

let activeNotice = "";
let timestamp = null;

function calculateNoticeDuration(message) {
  return BASE_NOTICE_DURATION_MS + message.length * MS_PER_CHARACTER;
}

function syncUiState() {
  const isBusy = activeNotice !== null;

  if (isBusy && formFields.includes(document.activeElement)) {
    document.activeElement.blur();
  }

  statusText.textContent = activeNotice ?? "";

  submitButton.disabled = isBusy;
  submitButton.textContent = isBusy ? BUTTON_TEXT.WAITING : BUTTON_TEXT.READY;

  for (const field of formFields) {
    field.readOnly = isBusy;
  }
}

function showNotice(message) {
  activeNotice = message;
  syncUiState();

  const timer = setTimeout(() => {
    activeNotice = null;
    syncUiState();
  }, calculateNoticeDuration(message));
  signal.addEventListener("abort", () => clearTimeout(timer), { once: true });
}

/**
 * Extracts a user-facing message and the offending field (if any) from an error response.
 *
 * The contact API answers with RFC 9457 problem details. Any other body (such as a proxy's
 * HTML error page) isn't fit to display.
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

  return { message: NOTICE.SERVER_ERROR, field: null };
}

async function handleSubmit(event) {
  event.preventDefault();

  if (activeNotice !== null) {
    return;
  }

  activeNotice = NOTICE.SENDING;
  syncUiState();

  let failureNotice = NOTICE.NETWORK_ERROR;
  let invalidField = null;

  try {
    const response = await fetch(API_ENDPOINT, {
      method: "POST",
      headers: { [TIMESTAMP_HEADER]: timestamp },
      body: new URLSearchParams(new FormData(form)),
      signal,
    });

    if (response.ok) {
      controller.abort();
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

  if (signal.aborted) {
    return;
  }

  if (invalidField !== null) {
    activeNotice = null;
    syncUiState();
    invalidField.reportValidity();
  } else {
    showNotice(failureNotice);
  }
}

syncUiState();

try {
  const response = await fetch(API_ENDPOINT);
  if (response.ok) {
    timestamp = await response.text();
    activeNotice = null;

    form.addEventListener(
      "input",
      (event) => event.target.setCustomValidity(""),
      { signal },
    );
    form.addEventListener("submit", handleSubmit, { signal });

    setTimeout(() => {
      controller.abort();
      activeNotice = null;
      syncUiState();
      submitButton.disabled = true;
      submitButton.textContent = BUTTON_TEXT.EXPIRED;
    }, SESSION_DURATION_MS);
  } else {
    activeNotice = NOTICE.SERVER_ERROR;
  }
} catch {
  activeNotice = NOTICE.NETWORK_ERROR;
}

if (activeNotice !== null) {
  controller.abort();
}
syncUiState();
