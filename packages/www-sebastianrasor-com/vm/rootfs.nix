{
  cpio,
  ncurses,
  pkgsi686Linux,
  runCommand,
  writeShellScript,
  libappsSrc,
}:
let
  muslCc = writeShellScript "i686-musl-cc" ''
    exec ${pkgsi686Linux.stdenv.cc.cc}/bin/gcc \
      -B${pkgsi686Linux.stdenv.cc.bintools.bintools}/bin \
      -isystem ${pkgsi686Linux.linuxHeaders}/include \
      -L${pkgsi686Linux.stdenv.cc.cc}/lib \
      -static "$@" -specs ${pkgsi686Linux.musl.dev}/lib/musl-gcc.specs
  '';

  muslStatic =
    pkg: extraFlags:
    pkg.overrideAttrs (old: {
      configureFlags =
        (old.configureFlags or [ ])
        ++ [
          "CC=${muslCc}"
          "CFLAGS=-Os -ffunction-sections -fdata-sections"
          "LDFLAGS=-Wl,--gc-sections"
        ]
        ++ extraFlags;
      dontPatchELF = true;
      stripAllList = [ "bin" ];
      __structuredAttrs = true;
    });

  guestNcurses = muslStatic (pkgsi686Linux.ncurses.override {
    enableStatic = true;
    withCxx = false;
  }) [ ];

  guestNano =
    muslStatic
      (pkgsi686Linux.nano.override {
        ncurses = guestNcurses;
        enableNls = false;
        file = null;
      })
      [
        "CPPFLAGS=-I${guestNcurses.dev}/include -I${guestNcurses.dev}/include/ncursesw"
        "LIBS=-L${guestNcurses}/lib -lncursesw"
        "--disable-histories"
        "--disable-mouse"
        "--disable-operatingdir"
        "--disable-speller"
      ];

  guestBusybox = pkgsi686Linux.busybox.override {
    enableStatic = true;
    useMusl = true;
  };

  guestMsmtp =
    (muslStatic
      (pkgsi686Linux.msmtp.override {
        withScripts = false;
        withKeyring = false;
      })
      [
        "--without-tls"
        "--without-libgsasl"
        "--without-libidn"
        "--disable-nls"
      ]
    ).overrideAttrs
      { buildInputs = [ ]; };

  guestSocat =
    (muslStatic pkgsi686Linux.socat [
      "--disable-openssl"
      "--disable-readline"
      "--disable-libwrap"
      "--disable-fips"
    ]).overrideAttrs
      { buildInputs = [ ]; };
in
runCommand "www-v86-initramfs.cpio"
  {
    nativeBuildInputs = [ cpio ];
  }
  ''
    mkdir -p root/{bin,dev,etc/init.d,proc,root,run,sys,tmp,usr/share/nano,usr/share/terminfo}

    cp -a ${guestBusybox}/bin/. root/bin/
    chmod u+w root/bin
    ln -s ../bin root/usr/bin
    ln -s bin root/sbin
    ln -s ../bin root/usr/sbin

    install -Dm755 ${guestNano}/bin/nano root/bin/nano
    install -Dm644 -t root/usr/share/nano "${guestNano}"/share/nano/{default,email,nanorc,sh}.nanorc
    printf 'include "/usr/share/nano/*.nanorc"\n' > root/etc/nanorc

    for term in d/dumb l/linux v/vt100 x/xterm x/xterm-256color; do
      install -Dm644 "${ncurses}/share/terminfo/$term" "root/usr/share/terminfo/$term"
    done

    install -Dm755 -t root/bin \
      "${libappsSrc}/hterm/etc/hterm-show-file.sh" \
      "${libappsSrc}/hterm/etc/osc52.sh"

    rm -f root/bin/sendmail
    install -Dm755 ${guestMsmtp}/bin/msmtp root/bin/msmtp
    ln -s msmtp root/bin/sendmail
    install -Dm755 ${guestSocat}/bin/socat root/bin/socat

    printf 'default: sebastian@www.sebastianrasor.com\n' > root/etc/aliases
    cat > root/etc/msmtprc <<'EOF'
    account default
    socket /run/smtp.sock
    from root@www
    set_from_header off
    aliases /etc/aliases
    timeout 30
    logfile -
    logfile_time_format none
    EOF

    printf 'root:x:0:0:root:/root:/bin/sh\n' > root/etc/passwd
    printf 'root:x:0:\n' > root/etc/group
    cat > root/etc/profile <<'EOF'
    export HISTFILE=/tmp/.ash_history
    export EDITOR=nano
    export VISUAL=nano
    export PAGER=less
    cd "$HOME" 2>/dev/null || true
    EOF

    cat > root/etc/init.d/rcS <<'EOF'
    #!/bin/sh
    /bin/mount -t proc proc /proc
    /bin/mount -t sysfs sysfs /sys
    /bin/mount -t devtmpfs devtmpfs /dev
    /bin/mount -t 9p -o trans=virtio,version=9p2000.L,msize=131072,cache=loose host9p /root
    free_mb=$(/bin/awk '/^MemFree:/ { m = int($2 / 1024) - 4; print (m > 0 ? m : 0) }' /proc/meminfo)
    if [ "$free_mb" -gt 0 ]; then
      /bin/dd if=/dev/zero of=/tmp/.zero bs=1M count="$free_mb" 2>/dev/null || true
      /bin/rm -f /tmp/.zero
    fi
    EOF
    chmod 0755 root/etc/init.d/rcS

    cat > root/etc/inittab <<'EOF'
    ::sysinit:/etc/init.d/rcS
    ::respawn:/bin/socat UNIX-LISTEN:/run/smtp.sock,mode=0666,fork,max-children=1,unlink-early 'SYSTEM:exec 3<>/dev/ttyS0; stty raw -echo min 0 time 0 <&3; cat <&3 >/dev/null; stty min 1 <&3; dd if=/dev/zero bs=1 count=1 >&3 2>/dev/null; exec socat -T 35 - /proc/self/fd/3 2>/dev/null' 2>/dev/null
    hvc0::respawn:-/bin/sh
    EOF

    (
      cd root
      find . -exec touch -h -d '@0' {} +
      find . -print0 | sort -z | cpio --null -o -H newc -R 0:0 --reproducible > "$out"
    )
  ''
