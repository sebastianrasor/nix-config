const API_ENDPOINT = "/api/contact";
const TURNSTILE_HEADER = "CF-Turnstile-Token";
const TURNSTILE_FIELD = "cf-turnstile-response";
const HTTP_STATUS_UNPROCESSABLE_ENTITY = 422;

const BASE_NOTICE_DURATION_MS = 3_000;
const MS_PER_CHARACTER = 50;

const BUTTON_VALUE = Object.freeze({
  READY: "Send Message",
  WAITING: "Please wait...",
});

const NOTICE = Object.freeze({
  SENDING: "Sending your message...",
  ERROR: "Security verification failed. Retrying...",
  TIMEOUT: "Security verification timed out. Retrying...",
  EXPIRED: "Security verification expired. Refreshing...",
  UNSUPPORTED: "Your browser does not support security verification.",
  INTERACTIVE: "Additional security verification required.",
  NETWORK_ERROR: "Network error. Please check your connection and try again.",
  SERVER_ERROR:
    "The server was unable to complete your request. Please try again later.",
});

const form = document.getElementById("contact-form");
const successArticle = document.getElementById("success");
const submitButton = document.getElementById("submit-button");
const messageInput = document.getElementById("message");
const messageLabel = document.querySelector("label[for=message]");
const formFields = [...form.querySelectorAll("input:not(.button), textarea")];

const fieldNamePattern = new RegExp(
  `\\b(${formFields.map((field) => field.name).join("|")})\\b`,
  "i",
);

const defaultMessageLabel = messageLabel.textContent;

let turnstileToken = null;
let isSubmitting = false;
let activeNotice = null;
let noticeTimeoutId = null;
let invalidFields = [];

function calculateNoticeDuration(message) {
  return BASE_NOTICE_DURATION_MS + message.length * MS_PER_CHARACTER;
}

function syncUiState() {
  const currentNotice = activeNotice ?? (isSubmitting ? NOTICE.SENDING : null);
  const isBusy = currentNotice !== null;
  const isReady = Boolean(turnstileToken) && !isBusy;

  if (isBusy) {
    messageInput.blur();
  }

  messageLabel.textContent = currentNotice ?? defaultMessageLabel;

  submitButton.disabled = !isReady;
  submitButton.classList.toggle("button-disabled", !isReady);
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

  const duration = calculateNoticeDuration(message);

  noticeTimeoutId = setTimeout(() => {
    activeNotice = null;
    noticeTimeoutId = null;
    syncUiState();

    if (!turnstileToken) {
      window.turnstile?.reset();
    }
  }, duration);
}

function findInvalidFields(message) {
  const match = message.match(fieldNamePattern);
  if (!match) {
    return formFields;
  }

  const matchedName = match[1].toLowerCase();
  return formFields.filter((field) => field.name === matchedName);
}

function setValidityError(message) {
  for (const field of invalidFields) {
    field.setCustomValidity("");
  }

  invalidFields = findInvalidFields(message);

  for (const field of invalidFields) {
    field.setCustomValidity(message);
  }
}

function handleFieldInput(event) {
  if (!invalidFields.includes(event.target)) {
    return;
  }

  for (const field of invalidFields) {
    field.setCustomValidity("");
  }

  invalidFields = [];
}

const turnstileCallbacks = {
  onSuccess(token) {
    turnstileToken = token;
    syncUiState();
  },

  onError() {
    turnstileToken = null;
    showNotice(NOTICE.ERROR);
  },

  onTimeout() {
    turnstileToken = null;
    showNotice(NOTICE.TIMEOUT);
    window.turnstile?.reset();
  },

  onExpired() {
    turnstileToken = null;
    showNotice(NOTICE.EXPIRED);
    window.turnstile?.reset();
  },

  onUnsupported() {
    turnstileToken = null;
    showNotice(NOTICE.UNSUPPORTED);
  },

  onBeforeInteractive() {
    turnstileToken = null;
    showNotice(NOTICE.INTERACTIVE);
  },

  onAfterInteractive() {
    syncUiState();
  },
};

Object.assign(window, turnstileCallbacks);

async function handleSubmit(event) {
  event.preventDefault();

  if (!turnstileToken || isSubmitting || activeNotice !== null) {
    return;
  }

  isSubmitting = true;
  syncUiState();

  const formData = new FormData(form);
  const token = turnstileToken || formData.get(TURNSTILE_FIELD);
  formData.delete(TURNSTILE_FIELD);

  try {
    const response = await fetch(API_ENDPOINT, {
      method: "POST",
      headers: {
        [TURNSTILE_HEADER]: token,
      },
      body: new URLSearchParams(formData),
    });

    if (response.ok) {
      form.hidden = true;
      successArticle.hidden = false;
      return;
    }

    const errorText = (await response.text()).trim();
    const errorMessage = errorText || NOTICE.SERVER_ERROR;

    if (response.status === HTTP_STATUS_UNPROCESSABLE_ENTITY) {
      setValidityError(errorMessage);
    }

    showNotice(errorMessage);
  } catch {
    showNotice(NOTICE.NETWORK_ERROR);
  } finally {
    if (!form.hidden) {
      turnstileToken = null;
      isSubmitting = false;
      window.turnstile?.reset();
      syncUiState();
    }
  }
}

form.addEventListener("input", handleFieldInput);
form.addEventListener("submit", handleSubmit);

const existingToken = window.turnstile?.getResponse();
if (existingToken) {
  turnstileCallbacks.onSuccess(existingToken);
}
