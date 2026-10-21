const READING_WPM = 200;

const form = document.getElementById('contact-form');
const labelForMessage = document.querySelector('label[for=message]');
const originalInnerText = labelForMessage.innerText;

let blockEnableSubmit = false;

window.enableSubmit = () => {
    if (blockEnableSubmit) return;

    form.btnSubmit.disabled = false;
    form.btnSubmit.value = 'Send Message';
    form.btnSubmit.classList.remove('button-disabled');
}

window.disableSubmit = () => {
    form.btnSubmit.disabled = true;
    form.btnSubmit.value = 'Please wait...';
    form.btnSubmit.classList.add('button-disabled');
}

window.handleError = (errorMessage) => {
    labelForMessage.innerText = errorMessage;

    const duration = 1 + errorMessage.split(/\s/g).length / (READING_WPM / 60);
    setTimeout(function () {
        labelForMessage.innerText = originalInnerText;
        form.name.readOnly = false;
        form.email.readOnly = false;
        form.message.readOnly = false;
        blockEnableSubmit = false;
        enableSubmit();
    }, duration * 1000)

    return false;
}

window.addEventListener('submit', async (event) => {
    event.preventDefault();

    const form = event.target;

    if (form.btnSubmit.disabled) {
        return false
    }

    disableSubmit();
    blockEnableSubmit = true;

    form.name.readOnly = true;
    form.email.readOnly = true;
    form.message.readOnly = true;
    form.name.blur();
    form.email.blur();
    form.message.blur();

    labelForMessage.innerText = "Submitting your message...";

    const formData = new FormData(form);

    formData.delete("cf-turnstile-response");

    const token = document.querySelector('[name="cf-turnstile-response"]').value;

    const response = await fetch('/api/contact', {
        method: 'POST',
        headers: {
            'CF-Turnstile-Token': token,
        },
        body: new URLSearchParams(formData),
    })

    if (!response.ok) {
        handleError(`HTTP ERROR ${response.status}: ${await response.text()}`);
        return false;
    }

    const success = document.getElementById('success');
    form.hidden = true;
    success.hidden = false;
    turnstile.remove();

    return false;
})
