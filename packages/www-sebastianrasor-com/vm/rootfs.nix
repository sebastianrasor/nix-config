{
  cpio,
  nano,
  ncurses,
  pkg-config,
  pkgsi686Linux,
  runCommand,
  stdenv,
  writeShellScriptBin,
  xz,
  zstd,
  libappsSrc,
  targets,
}:
let
  i686Cc = pkgsi686Linux.stdenv.cc.cc;
  i686Binutils = pkgsi686Linux.stdenv.cc.bintools.bintools;
  i686Musl = pkgsi686Linux.musl;

  muslCc = writeShellScriptBin "i686-musl-gcc" ''
    exec ${i686Cc}/bin/gcc \
      -B${i686Binutils}/bin \
      -isystem ${pkgsi686Linux.linuxHeaders}/include \
      -L${i686Cc}/lib \
      -static \
      "$@" \
      -specs ${i686Musl.dev}/lib/musl-gcc.specs
  '';

  guestNcurses = stdenv.mkDerivation {
    pname = "ncurses-i686-musl-static";
    inherit (ncurses) src version;

    nativeBuildInputs = [
      i686Binutils
      muslCc
      pkg-config
    ];

    hardeningDisable = [ "all" ];
    dontPatchELF = true;
    dontStrip = true;
    enableParallelBuilding = true;

    postPatch = ''
      sed -i '1i #include <stdbool.h>' include/curses.h.in
    '';

    configurePhase = ''
      runHook preConfigure
      CC=i686-musl-gcc \
      AR=${i686Binutils}/bin/ar \
      RANLIB=${i686Binutils}/bin/ranlib \
      LD=${i686Binutils}/bin/ld \
      NM=${i686Binutils}/bin/nm \
      CFLAGS="-Os -ffunction-sections -fdata-sections" \
      ./configure \
        --prefix="$out" \
        --without-shared \
        --without-debug \
        --without-ada \
        --without-cxx \
        --without-cxx-binding \
        --without-progs \
        --without-tests \
        --without-manpages \
        --enable-widec \
        --enable-pc-files \
        --with-pkg-config-libdir="$out/lib/pkgconfig" \
        --with-terminfo-dirs="/etc/terminfo:/usr/share/terminfo"
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      make -j"$NIX_BUILD_CORES" -C include
      make -j"$NIX_BUILD_CORES" -C ncurses
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      make -C include install
      make -C ncurses install.libs
      make -C misc install.libs || true
      runHook postInstall
    '';
  };

  guestNano = stdenv.mkDerivation {
    pname = "nano-i686-musl-static";
    inherit (nano) src version;

    nativeBuildInputs = [
      i686Binutils
      muslCc
      pkg-config
      xz
    ];

    hardeningDisable = [ "all" ];
    dontPatchELF = true;
    dontStrip = true;
    enableParallelBuilding = true;

    configurePhase = ''
      runHook preConfigure
      PKG_CONFIG_PATH="${guestNcurses}/lib/pkgconfig" \
      CC=i686-musl-gcc \
      AR=${i686Binutils}/bin/ar \
      RANLIB=${i686Binutils}/bin/ranlib \
      LD=${i686Binutils}/bin/ld \
      NM=${i686Binutils}/bin/nm \
      CFLAGS="-Os -ffunction-sections -fdata-sections -Wno-error=format-security" \
      CPPFLAGS="-I${guestNcurses}/include -I${guestNcurses}/include/ncursesw" \
      LDFLAGS="-L${guestNcurses}/lib -Wl,--gc-sections" \
      ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-nls \
        --disable-speller
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      make -j"$NIX_BUILD_CORES" -C lib
      make -j"$NIX_BUILD_CORES" -C src
      ${i686Binutils}/bin/strip -s src/nano
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 src/nano "$out/bin/nano"
      install -Dm644 -t "$out/share/nano" syntax/*.nanorc
      runHook postInstall
    '';
  };

  guestBusybox = pkgsi686Linux.busybox.override {
    enableStatic = true;
    useMusl = true;
  };
in
runCommand "www-v86-initramfs.cpio.zst"
  {
    nativeBuildInputs = [
      cpio
      zstd
    ];
  }
  ''
    mkdir -p root/{bin,dev,etc,proc,root/targets,sys,tmp,usr/share/nano,usr/share/terminfo}

    cp -a ${guestBusybox}/bin/. root/bin/
    chmod u+w root/bin
    ln -s ../bin root/usr/bin
    ln -s bin root/sbin
    ln -s ../bin root/usr/sbin

    install -Dm755 ${guestNano}/bin/nano root/bin/nano
    install -Dm644 -t root/usr/share/nano ${guestNano}/share/nano/*.nanorc
    printf 'include "/usr/share/nano/*.nanorc"\n' > root/etc/nanorc

    for term in d/dumb l/linux v/vt100 x/xterm x/xterm-256color; do
      install -Dm644 "${ncurses}/share/terminfo/$term" "root/usr/share/terminfo/$term"
    done

    install -Dm755 -t root/bin \
      "${libappsSrc}/hterm/etc/hterm-show-file.sh" \
      "${libappsSrc}/hterm/etc/osc52.sh"
    install -Dm755 ${./smtpd.sh} root/bin/smtpd

    rm -f root/bin/sendmail
    cat > root/bin/sendmail <<'EOF'
    #!/bin/sh
    exec /bin/busybox sendmail -f root@www -H /bin/smtpd "$@"
    EOF
    chmod 0755 root/bin/sendmail

    cat > root/etc/inittab <<'EOF'
    ::sysinit:/bin/mount -t proc proc /proc
    ::sysinit:/bin/mount -t sysfs sysfs /sys
    ::sysinit:/bin/mount -t devtmpfs devtmpfs /dev
    hvc0::respawn:-/bin/sh -c 'cd && exec /bin/sh'
    EOF

    cp -r --no-preserve=mode ${../home}/. root/root/
    install -Dm644 -t root/root/targets ${targets}/*.pdf

    (
      cd root
      find . -print0 | sort -z | cpio --null -o -H newc -R 0:0 --reproducible | zstd -19 -T0 > "$out"
    )
  ''
