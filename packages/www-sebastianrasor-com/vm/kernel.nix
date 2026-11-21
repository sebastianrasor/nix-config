{
  lib,
  stdenv,
  stdenvNoCC,
  linux_6_12,
  bc,
  bison,
  elfutils,
  flex,
  perl,
  xz,
}:
let
  kernelConfig = {
    "64BIT" = false;
    X86_32 = true;
    SMP = false;
    M686 = true;
    X86_TSC = true;
    X86_UP_APIC = false;
    CC_OPTIMIZE_FOR_PERFORMANCE = false;
    CC_OPTIMIZE_FOR_SIZE = true;
    SLUB_TINY = true;
    KALLSYMS = false;
    PCI = true;
    PCI_BIOS = true;
    PCI_DIRECT = true;
    DEFAULT_HOSTNAME = "www";
    KERNEL_GZIP = false;
    KERNEL_XZ = true;
    COMPAT_32BIT_TIME = true;
    BUG = true;
    DEBUG_BUGVERBOSE = false;
    PRINTK = true;
    PRINTK_TIME = true;
    SYSFS = true;
    PROC_FS = true;
    PROC_SYSCTL = true;
    SYSCTL = true;
    SHMEM = true;
    TMPFS = true;
    DEVTMPFS = true;
    BLK_DEV = true;
    BLK_DEV_INITRD = true;
    RD_GZIP = false;
    RD_BZIP2 = false;
    RD_LZMA = false;
    RD_XZ = false;
    RD_LZO = false;
    RD_LZ4 = false;
    RD_ZSTD = false;
    BINFMT_ELF = true;
    BINFMT_SCRIPT = true;
    FUTEX = true;
    EPOLL = true;
    SIGNALFD = true;
    TIMERFD = true;
    EVENTFD = true;
    ADVISE_SYSCALLS = true;
    MEMFD_CREATE = true;
    POSIX_TIMERS = true;
    HIGH_RES_TIMERS = true;
    TTY = true;
    VT = false;
    SERIAL_8250 = true;
    SERIAL_8250_PCI = false;
    SERIAL_8250_EXAR = false;
    SERIAL_8250_NR_UARTS = 1;
    SERIAL_8250_RUNTIME_UARTS = 1;
    VIRTIO_MENU = true;
    VIRTIO_PCI = true;
    VIRTIO_PCI_LEGACY = true;
    VIRTIO_CONSOLE = true;
    NET = true;
    UNIX = true;
    INET = false;
    WIRELESS = false;
    ETHTOOL_NETLINK = false;
    NET_9P = true;
    NET_9P_VIRTIO = true;
    "9P_FS" = true;
  };

  configArgs = lib.concatStringsSep " " (
    lib.mapAttrsToList (
      name: value:
      if builtins.isBool value then
        "${if value then "--enable" else "--disable"} ${name}"
      else if builtins.isInt value then
        "--set-val ${name} ${toString value}"
      else
        "--set-str ${name} ${lib.escapeShellArg value}"
    ) kernelConfig
  );
in
stdenvNoCC.mkDerivation {
  pname = "linux-v86";
  inherit (linux_6_12) src version;

  nativeBuildInputs = [
    bc
    bison
    elfutils
    flex
    perl
    stdenv.cc.bintools.bintools
    xz
  ];

  enableParallelBuilding = true;

  env = {
    KBUILD_BUILD_TIMESTAMP = "Thu Jan  1 00:00:00 UTC 1970";
    KBUILD_BUILD_USER = "nix";
    KBUILD_BUILD_HOST = "nix";
    KBUILD_BUILD_VERSION = "1";
  };

  makeFlags = [
    "ARCH=i386"
    "CC=${stdenv.cc.cc}/bin/gcc"
    "HOSTCC=${stdenv.cc}/bin/gcc"
  ];

  buildFlags = [ "bzImage" ];

  postPatch = ''
    patchShebangs scripts/
  '';

  configurePhase = ''
    runHook preConfigure

    make $makeFlags allnoconfig
    ./scripts/config ${configArgs}
    make $makeFlags olddefconfig

    grep -q '^CONFIG_CC_OPTIMIZE_FOR_SIZE=y$' .config
    grep -q '^CONFIG_KERNEL_XZ=y$' .config
    grep -q '^CONFIG_UNIX=y$' .config
    grep -q '^CONFIG_NET_9P=y$' .config
    grep -q '^CONFIG_NET_9P_VIRTIO=y$' .config
    grep -q '^CONFIG_9P_FS=y$' .config

    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 arch/x86/boot/bzImage "$out/bzImage"
    runHook postInstall
  '';

  meta = {
    description = "Minimal i686 Linux kernel for v86";
    platforms = [ "x86_64-linux" ];
  };
}
