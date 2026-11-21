import { BASE_V86_OPTIONS, getReadyVirtioRx } from "../vm/v86-common.js";
import { hterm } from "./vendor/hterm/index.js";
import htermMessages from "./vendor/hterm_messages.json";
import { lib } from "./vendor/libdot/index.js";
import { V86 } from "./vendor/v86/build/libv86.mjs";

const INPUT_CHUNK_SIZE = 2048;
const CONTACT_ENDPOINT = "/api/contact";
const INITIAL_PROMPT = typeof __INITIAL_PROMPT__ === "string" ? __INITIAL_PROMPT__ : "~ # ";
const DIR_READMES = new Set(["", "contact", "targets"]);

const encoder = new TextEncoder();

const terminalEl = document.getElementById("terminal");
const {
  bellUrl = "/bell.ogg",
  fontUrl = "/AtkinsonHyperlegibleMono.woff2",
  wasmUrl = "/v86.wasm",
  stateUrl = "",
} = terminalEl.dataset;

const stateBufferPromise = stateUrl
  ? fetch(stateUrl)
      .then((res) => (res.ok ? res.arrayBuffer() : null))
      .catch(() => null)
  : Promise.resolve(null);

function initialCommandForPath(pathname) {
  const rel = pathname.replace(/^\/+|\/+$/g, "");
  if (DIR_READMES.has(rel)) {
    return rel ? `cat ${rel}/README` : "cat README";
  }
  if (/^[a-zA-Z0-9._/-]+$/.test(rel) && !rel.includes("..")) {
    return `cat ${rel}`;
  }
  return "cat README";
}

const initialCommand = initialCommandForPath(window.location.pathname);

function attachSerialRelay(instance, isAlive) {
  let ws = null;
  let txBytes = [];
  let flushPending = false;

  const close = () => {
    txBytes = [];
    if (!ws) return;
    ws.onopen = ws.onmessage = ws.onclose = ws.onerror = null;
    if (ws.readyState < WebSocket.CLOSING) {
      ws.close();
    }
    ws = null;
  };

  const flush = () => {
    flushPending = false;
    if (ws?.readyState === WebSocket.OPEN && txBytes.length > 0) {
      ws.send(new Uint8Array(txBytes));
      txBytes = [];
    }
  };

  instance.add_listener("serial0-output-byte", (byte) => {
    if (!isAlive()) {
      close();
      return;
    }
    if (byte === 0x00) {
      close();
      const url = new URL(CONTACT_ENDPOINT, window.location.href);
      url.protocol = url.protocol === "https:" ? "wss:" : "ws:";
      const sock = new WebSocket(url);
      sock.binaryType = "arraybuffer";
      sock.onopen = flush;
      sock.onmessage = (e) => {
        if (isAlive()) {
          instance.serial_send_bytes(0, new Uint8Array(e.data));
        }
      };
      sock.onclose = (e) => {
        if (ws === sock) {
          ws = null;
          txBytes = [];
        }
        if (!e.wasClean && isAlive()) {
          instance.serial_send_bytes(
            0,
            encoder.encode("451 4.3.0 Network error while contacting mail relay.\r\n"),
          );
        }
      };
      ws = sock;
      return;
    }
    if (!ws || ws.readyState >= WebSocket.CLOSING) return;
    txBytes.push(byte);
    if (!flushPending) {
      flushPending = true;
      queueMicrotask(flush);
    }
  });

  return close;
}

function routeForShCommand(cmd) {
  const raw = /^cat (?:~\/)?([^\s/.]\S*)$/.exec(cmd.trim())?.[1];
  if (!raw || raw.includes("..")) return null;
  return raw === "README" ? "/" : `/${raw.replace(/\/README$/, "")}`;
}

await hterm.initPromise;
hterm.resources = { ...hterm.resources, AU_BELL: bellUrl };
hterm.messageManager.addMessages(htermMessages);

const storage = new lib.Storage.Memory();
const term = new hterm.Terminal({ storage });

const coarsePointerQuery = window.matchMedia("(pointer: coarse)");
const compactViewportQuery = window.matchMedia("(max-width: 639px)");

function focusTerminalIfDesktop() {
  if (!coarsePointerQuery.matches) {
    term.focus();
  }
}

const origOpenUrl = hterm.openUrl.bind(hterm);
hterm.openUrl = (url) => {
  if (url.startsWith("sh:")) {
    const cmd = decodeURIComponent(url.slice(3));
    if (cmd && term.isPrimaryScreen()) {
      const nextRoute = routeForShCommand(cmd);
      if (nextRoute && window.location.pathname !== nextRoute) {
        window.history.replaceState(null, "", nextRoute);
      }
      runInitialCommand = false;
      if (halted) {
        restartVm(vm, `${cmd}\r`);
      } else {
        pinScrollRow = term.scrollPort_.getTopRowIndex();
        sendInput(`\x15${cmd}\r`);
      }
      focusTerminalIfDesktop();
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
  term.onTerminalReady = resolve;
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

const prefs = term.getPrefs();

function applyViewportPrefs(compact) {
  prefs.set("font-size", compact ? 13 : 15);
  prefs.set("screen-padding-size", compact ? 10 : 18);
}

prefs.importFromJson({
  "allow-images-inline": true,
  "enable-clipboard-notice": false,
  "background-color": "#0b0f14",
  "foreground-color": "#e6edf3",
  "cursor-color": "rgba(126, 186, 228, 0.75)",
  "cursor-blink": true,
  "font-family": '"Atkinson Hyperlegible Mono", ui-monospace, monospace',
  "line-height-padding-size": 2,
  "pass-ctrl-n": true,
  "pass-ctrl-t": true,
  "pass-ctrl-tab": true,
  "user-css-text": `
    @font-face {
      font-family: "Atkinson Hyperlegible Mono";
      src: url("${fontUrl}") format("woff2");
      font-weight: 200 800;
      font-style: normal;
      font-display: swap;
    }
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
});
applyViewportPrefs(compactViewportQuery.matches);
compactViewportQuery.addEventListener("change", (e) => applyViewportPrefs(e.matches));

await new Promise((resolve) => setTimeout(resolve, 0));

term.document_?.fonts
  ?.load('15px "Atkinson Hyperlegible Mono"')
  .then(() => term.syncFontFamily(), () => {});

term.vt.oscTimeLimit_ = 20_000;

const io = term.io.push();
term.setCursorVisible(true);
term.keyboard.bindings.addBindings({
  F12: "PASS",
  "Ctrl+Shift+I": "PASS",
  "Ctrl+R": "PASS",
});
term.installKeyboard();
focusTerminalIfDesktop();

io.print("\x1b[2mBooting Linux...\x1b[0m");

let vm = null;
let started = false;
let halted = false;
let rebooting = false;
let txChunks = [];
let txTimer = null;

function flushInput() {
  txTimer = null;
  if (!vm || !started || txChunks.length === 0) return;

  const rxQueue = getReadyVirtioRx(vm);
  if (!rxQueue) {
    txTimer = setTimeout(flushInput, 8);
    return;
  }

  while (txChunks.length > 0 && rxQueue.has_request()) {
    const head = txChunks[0];
    if (head.length <= INPUT_CHUNK_SIZE) {
      txChunks.shift();
      vm.bus.send("virtio-console0-input-bytes", head);
    } else {
      vm.bus.send("virtio-console0-input-bytes", head.subarray(0, INPUT_CHUNK_SIZE));
      txChunks[0] = head.subarray(INPUT_CHUNK_SIZE);
    }
  }
  if (txChunks.length > 0) {
    txTimer = setTimeout(flushInput, 4);
  }
}

function sendInput(str) {
  const bytes = encoder.encode(str);
  if (bytes.length > 0) {
    txChunks.push(bytes);
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

function restartVm(oldVm, pendingStr = "") {
  if (rebooting) return;
  rebooting = true;
  halted = false;
  vm = null;
  started = false;
  txChunks = pendingStr ? [encoder.encode(pendingStr)] : [];
  setTimeout(async () => {
    if (oldVm) {
      await oldVm.destroy();
    }
    rebooting = false;
    await bootVm();
  }, 0);
}

let runInitialCommand = true;
let pinScrollRow = 0;

function handleUserInput(str) {
  runInitialCommand = false;
  pinScrollRow = null;
  if (halted) {
    restartVm(vm);
    return;
  }
  sendInput(str);
}

io.onVTKeystroke = handleUserInput;
io.sendString = handleUserInput;
io.onTerminalResize = sendResize;

async function bootVm() {
  started = false;
  halted = false;
  const stateBuffer = await stateBufferPromise;
  if (!stateBuffer) {
    io.print("\r\n\x1b[2mVM snapshot unavailable (enter the Nix devShell to boot Linux).\x1b[0m");
    return;
  }

  let clearedScreen = false;

  const instance = new V86({
    ...BASE_V86_OPTIONS,
    wasm_fn: async (env) =>
      (await WebAssembly.instantiateStreaming(fetch(wasmUrl), env)).instance.exports,
    initial_state: { buffer: stateBuffer },
    filesystem: { baseurl: "/" },
  });
  vm = instance;

  const closeSerialRelay = attachSerialRelay(instance, () => vm === instance);

  function ensureScreenCleared() {
    if (clearedScreen) return;
    clearedScreen = true;
    term.setAlternateMode(false);
    term.reset();
    term.clearScrollback();
  }

  function handleConsoleOutput(bytes) {
    ensureScreenCleared();
    io.writeUTF8(bytes);
    if (!term.isPrimaryScreen()) {
      if (pinScrollRow !== null) {
        pinScrollRow = null;
        term.scrollEnd();
      }
    } else if (pinScrollRow !== null && term.scrollbackRows_.length > pinScrollRow) {
      const targetRow = pinScrollRow;
      pinScrollRow = null;
      clearTimeout(term.timeouts_.scrollDown);
      delete term.timeouts_.scrollDown;
      term.scrollPort_.scrollRowToTop(targetRow);
      term.scrollPort_.scheduleRedraw();
    } else if (!term.scrollPort_.isScrolledEnd) {
      term.scrollPort_.scheduleRedraw();
    }
    if (runInitialCommand) {
      runInitialCommand = false;
      sendInput(`${initialCommand}\r`);
    }
  }

  instance.add_listener("virtio-console0-output-bytes", (bytes) => {
    if (vm !== instance) return;
    handleConsoleOutput(bytes);
  });

  instance.add_listener("cpu-event-halt", () => {
    if (vm !== instance || halted || rebooting) return;
    halted = true;
    started = false;
    txChunks = [];
    closeSerialRelay();
    instance.stop();
    io.print("\r\n\x1b[2m[System halted — press any key to reboot]\x1b[0m");
  });

  instance.add_listener("emulator-started", () => {
    if (vm !== instance) return;

    // When booted via `bzimage` or `initial_state`, guest RAM has been modified, so a
    // guest hardware reset (`reboot`) needs a fresh V86 instance.
    const cpu = instance.v86.cpu;
    const origRebootInternal = cpu.reboot_internal.bind(cpu);
    cpu.reboot_internal = () => {
      closeSerialRelay();
      instance.stop();
      origRebootInternal();
      restartVm(instance);
    };

    started = true;
    sendResize(io.columnCount || 80, io.rowCount || 24);
    handleConsoleOutput(encoder.encode(INITIAL_PROMPT));
    flushInput();
  });
}

await bootVm();
