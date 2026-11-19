import { hterm } from "./vendor/hterm/index.js";
import htermMessages from "./vendor/hterm_messages.json";
import { lib } from "./vendor/libdot/index.js";
import { V86 } from "./vendor/v86/build/libv86.mjs";

const MEMORY_SIZE = 96 * 1024 * 1024;
const VGA_MEMORY_SIZE = 2 * 1024 * 1024;
const INPUT_CHUNK_SIZE = 2048;

const CONTACT_ENDPOINT = "/api/contact";
const CHALLENGE_HEADER = "X-Challenge";
const PROOF_HEADER = "X-Proof";
const POW_DIFFICULTY_BITS = 20;
const PROBLEM_JSON_MEDIA_TYPE = "application/problem+json";

const POW_WORKER_SOURCE = `
const K = new Uint32Array([
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
]);
const W = new Uint32Array(64);
const enc = new TextEncoder();

function sha256FirstWord(padded, view, totalLen) {
  let h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
  let h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
  for (let off = 0; off < totalLen; off += 64) {
    for (let i = 0; i < 16; i++) W[i] = view.getUint32(off + i * 4, false);
    for (let i = 16; i < 64; i++) {
      const w15 = W[i - 15], w2 = W[i - 2];
      const s0 = ((w15 >>> 7) | (w15 << 25)) ^ ((w15 >>> 18) | (w15 << 14)) ^ (w15 >>> 3);
      const s1 = ((w2 >>> 17) | (w2 << 15)) ^ ((w2 >>> 19) | (w2 << 13)) ^ (w2 >>> 10);
      W[i] = (W[i - 16] + s0 + W[i - 7] + s1) | 0;
    }
    let a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
    for (let i = 0; i < 64; i++) {
      const S1 = ((e >>> 6) | (e << 26)) ^ ((e >>> 11) | (e << 21)) ^ ((e >>> 25) | (e << 7));
      const ch = (e & f) ^ (~e & g);
      const t1 = (h + S1 + ch + K[i] + W[i]) | 0;
      const S0 = ((a >>> 2) | (a << 30)) ^ ((a >>> 13) | (a << 19)) ^ ((a >>> 22) | (a << 10));
      const maj = (a & b) ^ (a & c) ^ (b & c);
      const t2 = (S0 + maj) | 0;
      h = g; g = f; f = e; e = (d + t1) | 0;
      d = c; c = b; b = a; a = (t1 + t2) | 0;
    }
    h0 = (h0 + a) | 0; h1 = (h1 + b) | 0; h2 = (h2 + c) | 0; h3 = (h3 + d) | 0;
    h4 = (h4 + e) | 0; h5 = (h5 + f) | 0; h6 = (h6 + g) | 0; h7 = (h7 + h) | 0;
  }
  return h0 >>> 0;
}

self.onmessage = ({ data: { id, challenge, bits } }) => {
  const prefix = enc.encode(challenge + ":");
  const shift = 32 - bits;
  const padded = new Uint8Array(256);
  const view = new DataView(padded.buffer);
  let nonce = 0;
  while (true) {
    const s = String(nonce);
    const len = prefix.length + s.length;
    const totalLen = ((len + 9 + 63) >> 6) << 6;
    padded.fill(0, 0, totalLen);
    padded.set(prefix, 0);
    for (let i = 0; i < s.length; i++) padded[prefix.length + i] = s.charCodeAt(i);
    padded[len] = 0x80;
    view.setUint32(totalLen - 4, (len * 8) >>> 0, false);
    if ((sha256FirstWord(padded, view, totalLen) >>> shift) === 0) {
      self.postMessage({ id, proof: s });
      return;
    }
    nonce++;
  }
};
`;

const encoder = new TextEncoder();
const decoder = new TextDecoder();

const terminalEl = document.getElementById("terminal");
const fontUrl = terminalEl.dataset.fontUrl || "/AtkinsonHyperlegibleMono.woff2";
const wasmUrl = terminalEl.dataset.wasmUrl || "/v86.wasm";
const biosUrl = terminalEl.dataset.biosUrl || "/seabios.bin";
const bzImageUrl = terminalEl.dataset.bzimageUrl || "/bzImage";
const initrdUrl = terminalEl.dataset.initrdUrl || "/initramfs.img";

const fontBufferPromise = fetch(fontUrl)
  .then((res) => (res.ok ? res.arrayBuffer() : null))
  .catch(() => null);

const powWorkerUrl = URL.createObjectURL(
  new Blob([POW_WORKER_SOURCE], { type: "text/javascript" }),
);
const powWorker = new Worker(powWorkerUrl);
let powReqId = 0;
const powPending = new Map();
powWorker.addEventListener("message", ({ data: { id, proof } }) => {
  const resolve = powPending.get(id);
  if (resolve) {
    powPending.delete(id);
    resolve(proof);
  }
});

function solvePow(challenge) {
  const id = ++powReqId;
  return new Promise((resolve) => {
    powPending.set(id, resolve);
    powWorker.postMessage({ id, challenge, bits: POW_DIFFICULTY_BITS });
  });
}

let readyChallengePromise = null;

function prepareChallenge() {
  const promise = (async () => {
    const response = await fetch(CONTACT_ENDPOINT, { cache: "no-store" });
    if (!response.ok) return null;
    const challenge = await response.text();
    const proof = await solvePow(challenge);
    return { challenge, proof, createdAt: Date.now() };
  })().catch(() => null);
  readyChallengePromise = promise;
  return promise;
}

prepareChallenge();

async function takeChallenge() {
  let ticket = readyChallengePromise ? await readyChallengePromise : null;
  readyChallengePromise = null;
  // Refresh if missing or older than 50 minutes (server TTL is 60 minutes)
  if (!ticket || Date.now() - ticket.createdAt > 50 * 60_000) {
    ticket = await prepareChallenge();
    readyChallengePromise = null;
  }
  return ticket;
}

async function submitSmtpMessage(mailFrom, b64) {
  let data;
  try {
    const bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
    data = decoder.decode(bytes);
  } catch {
    return "554 5.6.0 Malformed message payload.";
  }

  const ticket = await takeChallenge();
  if (!ticket) {
    return "451 4.3.0 Unable to reach mail relay.";
  }

  try {
    const response = await fetch(CONTACT_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        [CHALLENGE_HEADER]: ticket.challenge,
        [PROOF_HEADER]: ticket.proof,
      },
      body: JSON.stringify({ mail_from: mailFrom, data }),
    });

    // Every POST consumes its single-use challenge; pre-compute the next one in background.
    prepareChallenge();

    if (response.ok) {
      return "250 2.0.0 Ok: queued";
    }

    if (response.status === 429) {
      return "451 4.7.1 Too many messages sent recently. Please try again later.";
    }

    const contentType = response.headers.get("Content-Type") ?? "";
    let detail = null;
    if (contentType.startsWith(PROBLEM_JSON_MEDIA_TYPE)) {
      const problem = await response.json();
      detail = problem.detail ?? problem.title ?? null;
    }

    const cleanDetail = (detail || "Request rejected by mail relay.").replace(/[\r\n]+/g, " ");
    if (response.status >= 400 && response.status < 500 && response.status !== 403) {
      return `554 5.7.1 ${cleanDetail}`;
    }
    return `451 4.3.0 ${cleanDetail}`;
  } catch {
    return "451 4.3.0 Network error while contacting mail relay.";
  }
}

await hterm.initPromise;
hterm.messageManager.addMessages(htermMessages);

const storage = new lib.Storage.Memory();
const term = new hterm.Terminal({ storage });
term.bellAudio_.preload = "none";

const origOpenUrl = hterm.openUrl.bind(hterm);
hterm.openUrl = (url) => {
  if (url.startsWith("sh:")) {
    const cmd = decodeURIComponent(url.slice(3));
    if (cmd && term.isPrimaryScreen()) {
      runInitialCommand = false;
      sendInput(`\x15${cmd}\r`);
      term.focus();
    }
    return;
  }
  origOpenUrl(url);
};

// Download non-image OSC 1337 payloads (such as PDFs from `hterm-show-file.sh`) directly
// in the top-level document and keep the Blob URL alive until the browser reads it.
const origDisplayImage = term.displayImage.bind(term);
term.displayImage = (options, onLoad, onError) => {
  const name = (options.name || "download").trim();
  const isImage = /\.(png|jpe?g|gif|webp|svgz?|bmp|ico|avif)$/i.test(name);
  if (!options.inline || !isImage) {
    const blob = options.blob ?? new Blob([options.buffer]);
    const a = document.createElement("a");
    const url = URL.createObjectURL(blob);
    a.href = url;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 60_000);
    return;
  }
  origDisplayImage({ ...options, name }, onLoad, onError);
};

const terminalReady = new Promise((resolve) => {
  term.onTerminalReady = () => resolve();
});

term.decorate(terminalEl);
// Upstream hterm's Firefox branch attaches its iframe `load` listener after
// `appendChild`, missing synchronous initial `about:blank` load in Firefox 135+.
if (!term.scrollPort_.screen_ && term.scrollPort_.iframe_) {
  term.scrollPort_.iframe_.dispatchEvent(new Event("load"));
}
if (term.scrollPort_?.iframe_) {
  term.scrollPort_.iframe_.title = "Interactive Linux terminal";
}

await terminalReady;
if (term.document_?.documentElement) {
  term.document_.documentElement.lang = "en";
}

const isCompactViewport = window.innerWidth < 640;
const prefs = term.getPrefs();

term.bellAudio_.removeAttribute("src");
prefs.set("allow-images-inline", true);
prefs.set("enable-clipboard-notice", false);
prefs.set("background-color", "#0b0f14");
prefs.set("foreground-color", "#e6edf3");
prefs.set("cursor-color", "rgba(126, 186, 228, 0.75)");
prefs.set("cursor-blink", true);
prefs.set("font-family", '"Atkinson Hyperlegible Mono", ui-monospace, monospace');
prefs.set("font-size", isCompactViewport ? 13 : 15);
prefs.set("line-height-padding-size", 2);
prefs.set("screen-padding-size", isCompactViewport ? 10 : 18);
prefs.set("pass-ctrl-n", true);
prefs.set("pass-ctrl-t", true);
prefs.set("pass-ctrl-tab", true);
prefs.set(
  "user-css-text",
  `
  x-screen {
    scrollbar-width: thin;
    scrollbar-color: rgba(126, 186, 228, 0.25) transparent;
  }
  .uri-node {
    text-decoration: underline;
    text-decoration-color: rgba(126, 186, 228, 0.55);
    text-underline-offset: 3px;
  }
  .uri-node:hover {
    text-decoration-color: #7ebae4;
  }
`,
);

await new Promise((resolve) => setTimeout(resolve, 0));

try {
  const fontBuffer = await fontBufferPromise;
  if (fontBuffer && term.document_?.fonts) {
    const FontFaceCtor = term.document_.defaultView?.FontFace ?? FontFace;
    const face = new FontFaceCtor("Atkinson Hyperlegible Mono", fontBuffer, {
      weight: "200 800",
      style: "normal",
    });
    await face.load();
    term.document_.fonts.add(face);
    term.syncFontFamily();
  }
} catch {
  // Ignore if unsupported
}

term.vt.oscTimeLimit_ = 20_000;

const io = term.io.push();
term.setCursorVisible(true);
term.keyboard.bindings.addBinding("F12", "PASS");
term.keyboard.bindings.addBinding("Ctrl+Shift+I", "PASS");
term.keyboard.bindings.addBinding("Ctrl+R", "PASS");
term.installKeyboard();
term.focus();

io.print("\x1b[2mBooting Linux...\x1b[0m");

let vm = null;
let started = false;
let txPending = [];
let txTimer = null;

function flushInput() {
  txTimer = null;
  if (!vm || !started || txPending.length === 0) return;

  const rxQueue = vm.v86?.cpu?.devices?.virtio_console?.virtio?.queues?.[0];
  if (!rxQueue || !rxQueue.is_configured() || !rxQueue.has_request()) {
    txTimer = setTimeout(flushInput, 8);
    return;
  }

  while (txPending.length > 0 && rxQueue.has_request()) {
    const chunk = new Uint8Array(txPending.splice(0, INPUT_CHUNK_SIZE));
    vm.bus.send("virtio-console0-input-bytes", chunk);
  }
  if (txPending.length > 0) {
    txTimer = setTimeout(flushInput, 4);
  }
}

function sendInput(str) {
  const bytes = encoder.encode(str);
  for (let i = 0; i < bytes.length; i++) {
    txPending.push(bytes[i]);
  }
  if (started && txTimer === null) {
    flushInput();
  }
}

function sendResize(cols, rows) {
  if (!vm || !started) return;
  const safeCols = Math.max(20, Math.floor(Number(cols) || 80));
  const safeRows = Math.max(6, Math.floor(Number(rows) || 24));
  // v86's VirtioConsole.SendWindowSize writes its two arguments in swapped order into Linux's { cols, rows }
  vm.bus.send("virtio-console0-resize", [safeRows, safeCols]);
}

let runInitialCommand = true;

io.onVTKeystroke = (str) => {
  runInitialCommand = false;
  sendInput(str);
};
io.sendString = sendInput;
io.onTerminalResize = sendResize;

let rebooting = false;

function bootVm() {
  started = false;
  let clearedScreen = false;
  let serialBuf = [];

  const instance = new V86({
    wasm_path: wasmUrl,
    memory_size: MEMORY_SIZE,
    vga_memory_size: VGA_MEMORY_SIZE,
    bios: { url: biosUrl },
    bzimage: { url: bzImageUrl },
    initrd: { url: initrdUrl },
    cmdline: "console=hvc0 rdinit=/bin/init HOME=/root TERM=xterm-256color lpj=1000000 noapic nolapic quiet",
    virtio_console: true,
    disable_keyboard: true,
    disable_mouse: true,
    disable_speaker: true,
    autostart: true,
  });
  vm = instance;

  instance.add_listener("virtio-console0-output-bytes", (bytes) => {
    if (vm !== instance) return;
    if (!clearedScreen) {
      clearedScreen = true;
      term.setAlternateMode(false);
      term.reset();
      term.clearScrollback();
    }
    io.writeUTF8(bytes);
    if (runInitialCommand) {
      runInitialCommand = false;
      sendInput("cat README\r");
    }
  });

  instance.add_listener("serial0-output-byte", (byte) => {
    if (vm !== instance) return;
    if (byte === 0x02) {
      serialBuf = [0x02];
      return;
    }
    if (serialBuf.length === 0) return;
    if (byte === 0x0a) {
      const frame = decoder.decode(new Uint8Array(serialBuf));
      serialBuf = [];
      if (frame.startsWith("\x02SMTP\t")) {
        const [, mailFrom = "", b64 = ""] = frame.split("\t");
        submitSmtpMessage(mailFrom, b64).then((replyLine) => {
          if (vm === instance) {
            instance.serial_send_bytes(0, encoder.encode(`${replyLine}\n`));
          }
        });
      }
      return;
    }
    serialBuf.push(byte);
  });

  instance.add_listener("emulator-started", () => {
    if (vm !== instance) return;

    // When booted via `bzimage`, Linux overwrites 0x100000 in RAM, so a guest hardware
    // reset (`reboot`) needs a fresh V86 instance.
    const cpu = instance.v86.cpu;
    const origRebootInternal = cpu.reboot_internal.bind(cpu);
    cpu.reboot_internal = () => {
      // Reset the WASM CPU immediately so the remainder of the active `main_loop` tick
      // runs SeaBIOS reset code instead of falling through to Linux's triple-fault path.
      origRebootInternal();
      if (rebooting) return;
      rebooting = true;
      vm = null;
      started = false;
      txPending = [];
      setTimeout(async () => {
        await instance.destroy();
        rebooting = false;
        bootVm();
      }, 0);
    };

    started = true;
    sendResize(io.columnCount || 80, io.rowCount || 24);
    flushInput();
  });
}

bootVm();
