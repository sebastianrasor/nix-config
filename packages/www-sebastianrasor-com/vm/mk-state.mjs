import { isUtf8 } from "node:buffer";
import { cpSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, posix, sep } from "node:path";
import { pathToFileURL } from "node:url";
import { parseArgs } from "node:util";

import { BASE_V86_OPTIONS, getReadyVirtioRx } from "./v86-common.js";

const S_IFDIR_0755 = 0o040_755;
const S_IFREG_0644 = 0o100_644;
const S_IFREG_0755 = 0o100_755;
const MAX_EAGER_TEXT_BYTES = 16 * 1024;

const codepointCmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function isTerminalText(filePath, bytes) {
  return (
    bytes.length <= MAX_EAGER_TEXT_BYTES &&
    !/\.(?:pdf|svg)$/i.test(filePath) &&
    !bytes.includes(0) &&
    isUtf8(bytes)
  );
}

async function waitForVirtioRx(vm, initialDelayMs = 0) {
  if (initialDelayMs > 0) await sleep(initialDelayMs);
  while (!getReadyVirtioRx(vm)) {
    await sleep(10);
  }
}

function ensureDir(root, parts) {
  let current = root;
  for (const dirName of parts) {
    if (!current.has(dirName)) {
      current.set(dirName, { kind: "dir", children: new Map() });
    }
    current = current.get(dirName).children;
  }
  return current;
}

function scanHome(homeDir, outLazyDir) {
  const root = new Map();
  const eagerFiles = [];
  let totalSize = 0;

  for (const entry of readdirSync(homeDir, { recursive: true }).sort(codepointCmp)) {
    const fullPath = join(homeDir, entry);
    const rel = entry.split(sep).join(posix.sep);
    const st = statSync(fullPath);

    if (st.isDirectory()) {
      ensureDir(root, rel.split("/"));
      continue;
    }
    if (!st.isFile()) continue;

    const bytes = readFileSync(fullPath);
    if (isTerminalText(fullPath, bytes)) {
      eagerFiles.push({ rel, bytes });
      continue;
    }

    if (outLazyDir) {
      cpSync(fullPath, join(outLazyDir, rel));
    }
    totalSize += bytes.length;
    const parts = rel.split("/");
    const parent = ensureDir(root, parts.slice(0, -1));
    parent.set(parts.at(-1), {
      kind: "file",
      size: bytes.length,
      mode: (st.mode & 0o111) !== 0 ? S_IFREG_0755 : S_IFREG_0644,
      relUrl: rel,
    });
  }

  const toNodes = (children) =>
    Array.from(children, ([name, node]) =>
      node.kind === "dir"
        ? [name, 0, 0, S_IFDIR_0755, 0, 0, toNodes(node.children)]
        : [name, node.size, 0, node.mode, 0, 0, node.relUrl],
    );

  return {
    homeFs: { version: 3, size: totalSize, fsroot: toNodes(root) },
    eagerFiles,
  };
}

const { values } = parseArgs({
  options: {
    libv86: { type: "string" },
    wasm: { type: "string" },
    bios: { type: "string" },
    bzimage: { type: "string" },
    initrd: { type: "string" },
    home: { type: "string" },
    "out-state": { type: "string" },
    "out-prompt": { type: "string" },
    "out-lazy": { type: "string" },
  },
});

const { V86 } = await import(pathToFileURL(values.libv86).href);
const { homeFs, eagerFiles } = scanHome(values.home, values["out-lazy"]);
const decoder = new TextDecoder();

const { promise, resolve: resolveDone, reject } = Promise.withResolvers();
const timeout = setTimeout(
  () => reject(new Error("Timed out waiting for guest Linux shell prompt")),
  60_000,
);

let output = "";
let saving = false;

const vm = new V86({
  ...BASE_V86_OPTIONS,
  wasm_path: values.wasm,
  bios: { url: values.bios },
  bzimage: { url: values.bzimage },
  initrd: { url: values.initrd },
  filesystem: {},
  cmdline:
    "console=hvc0 rdinit=/bin/init HOME=/root TERM=xterm-256color lpj=1000000 noapic nolapic init_on_free=1 quiet",
});

vm.add_listener("emulator-started", async () => {
  try {
    vm.fs9p.load_from_json(homeFs);
    for (const { rel, bytes } of eagerFiles) {
      await vm.create_file(rel, bytes);
    }
  } catch (err) {
    reject(err);
  }
});

vm.add_listener("virtio-console0-output-bytes", async (bytes) => {
  if (saving) return;
  output += decoder.decode(bytes, { stream: true });
  if (!output.endsWith("# ")) return;

  saving = true;
  try {
    await waitForVirtioRx(vm, 25);
    await vm.stop();
    const state = await vm.save_state();
    writeFileSync(values["out-state"], new Uint8Array(state));
    writeFileSync(values["out-prompt"], output, "utf8");
    resolveDone();
  } catch (err) {
    reject(err);
  }
});

try {
  await promise;
} finally {
  clearTimeout(timeout);
  await vm.destroy();
}
