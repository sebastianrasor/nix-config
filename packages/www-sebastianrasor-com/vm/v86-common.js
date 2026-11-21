export const BASE_V86_OPTIONS = {
  memory_size: 75_497_472,
  vga_memory_size: 65_536,
  virtio_console: true,
  disable_keyboard: true,
  disable_mouse: true,
  disable_speaker: true,
  autostart: true,
};

export function getReadyVirtioRx(vm) {
  const rxQueue = vm?.v86?.cpu?.devices?.virtio_console?.virtio?.queues?.[0];
  return rxQueue?.is_configured() && rxQueue.has_request() ? rxQueue : null;
}
