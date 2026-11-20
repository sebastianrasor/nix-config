{
  stdenv,
  linux_6_12,
  bc,
  bison,
  cpio,
  elfutils,
  flex,
  openssl,
  perl,
  python3Minimal,
  writeShellScriptBin,
  xz,
  zstd,
}:
let
  binutils = stdenv.cc.bintools.bintools;
  kernelCc = writeShellScriptBin "i386-kernel-gcc" ''
    exec ${stdenv.cc.cc}/bin/gcc -B${binutils}/bin "$@"
  '';
in
stdenv.mkDerivation {
  pname = "linux-v86";
  inherit (linux_6_12) src version;

  nativeBuildInputs = [
    bc
    bison
    cpio
    elfutils
    flex
    kernelCc
    openssl
    perl
    python3Minimal
    xz
    zstd
  ];

  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;

  env = {
    KBUILD_BUILD_TIMESTAMP = "Thu Jan  1 00:00:00 UTC 1970";
    KBUILD_BUILD_USER = "nix";
    KBUILD_BUILD_HOST = "nix";
    KBUILD_BUILD_VERSION = "1";
  };

  makeFlags = [
    "ARCH=i386"
    "HOSTCC=${stdenv.cc}/bin/gcc"
    "CC=${kernelCc}/bin/i386-kernel-gcc"
    "LD=${binutils}/bin/ld"
    "AR=${binutils}/bin/ar"
    "NM=${binutils}/bin/nm"
    "STRIP=${binutils}/bin/strip"
    "OBJCOPY=${binutils}/bin/objcopy"
    "OBJDUMP=${binutils}/bin/objdump"
    "READELF=${binutils}/bin/readelf"
  ];

  buildFlags = [ "bzImage" ];

  postPatch = ''
    patchShebangs scripts/
  '';

  configurePhase = ''
    runHook preConfigure

    make $makeFlags allnoconfig

    ./scripts/config \
      --disable 64BIT \
      --enable X86_32 \
      --disable SMP \
      --enable M686 \
      --enable X86_TSC \
      --disable X86_UP_APIC \
      --enable PCI \
      --enable PCI_BIOS \
      --enable PCI_DIRECT \
      --set-str DEFAULT_HOSTNAME "www" \
      --enable KERNEL_ZSTD \
      --enable COMPAT_32BIT_TIME \
      --enable BUG \
      --enable PRINTK \
      --enable PRINTK_TIME \
      --enable SYSFS \
      --enable PROC_FS \
      --enable PROC_SYSCTL \
      --enable SYSCTL \
      --enable SHMEM \
      --enable TMPFS \
      --enable DEVTMPFS \
      --enable BLK_DEV \
      --enable BLK_DEV_INITRD \
      --enable RD_ZSTD \
      --enable BINFMT_ELF \
      --enable BINFMT_SCRIPT \
      --enable FUTEX \
      --enable EPOLL \
      --enable SIGNALFD \
      --enable TIMERFD \
      --enable EVENTFD \
      --enable ADVISE_SYSCALLS \
      --enable MEMFD_CREATE \
      --enable POSIX_TIMERS \
      --enable HIGH_RES_TIMERS \
      --enable TTY \
      --disable VT \
      --enable SERIAL_8250 \
      --disable SERIAL_8250_PCI \
      --disable SERIAL_8250_EXAR \
      --set-val SERIAL_8250_NR_UARTS 1 \
      --set-val SERIAL_8250_RUNTIME_UARTS 1 \
      --enable VIRTIO_MENU \
      --enable VIRTIO_PCI \
      --enable VIRTIO_PCI_LEGACY \
      --enable VIRTIO_CONSOLE \
      --enable NET \
      --disable WIRELESS \
      --disable ETHTOOL_NETLINK \
      --enable NET_9P \
      --enable NET_9P_VIRTIO \
      --enable 9P_FS

    make $makeFlags olddefconfig

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
