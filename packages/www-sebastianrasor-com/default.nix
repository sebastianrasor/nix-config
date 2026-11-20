{
  lib,
  atkinson-hyperlegible-mono,
  callPackage,
  craneLib,
  esbuild,
  fetchgit,
  fetchurl,
  groff,
  jq,
  man-pages,
  openssl,
  pkg-config,
  runCommand,
  seabios,
  targets ? callPackage ../targets { },
  woff2,
}:
let
  libappsSrc = fetchgit {
    url = "https://chromium.googlesource.com/apps/libapps";
    rev = "36a229521ce03f008d32c91f2063a1088e31f0a9";
    hash = "sha256-GJ8dDUiR58iDUfGHjiJfxAt4j8LFeq93XuIFZgPBu3c=";
  };

  v86Tarball = fetchurl {
    url = "https://registry.npmjs.org/v86/-/v86-0.5.473.tgz";
    hash = "sha256-Nkq2emjB2DZG4t33yvc8JFdGlKEysrQ2ia0PcuckJjY=";
  };

  qemuBios = (seabios.override { ___build-type = "qemu"; }).firmware;
  homeDir =
    runCommand "www-sebastianrasor-com-home"
      {
        nativeBuildInputs = [ groff ];
      }
      ''
        mkdir -p "$out/targets"
        cp -r --no-preserve=mode ${./home}/. "$out/"
        chmod -R u+w "$out"
        install -Dm644 -t "$out/targets" ${targets}/*.pdf
        gzip -dc ${lib.getMan man-pages}/share/man/man0/intro.0.gz \
          | awk '
            /^\.TH intro / { sub(/^\.TH intro 0 /, ".TH intro 1 ") }
            /^intro \\- / { $0 = "intro \\- introduction to user commands" }
            /^\.(SH|SS) / {
              skip = ($0 ~ /^\.SS (Login|Disks and filesystems|Getting information)$/ || $0 == ".SH SEE ALSO")
              drop = 0
            }
            skip { next }
            /^\.P$/ { drop = 0 }
            /^See also$/ || /^Large searches on a multi-GB disk/ { drop = 1 }
            drop { next }
            /^You can change your shell,$/ || /^and everybody has their own favorite one\.$/ { next }
            /^\.RB "(knuth login|Password): "/ { next }
            /sent to "standard output"$/ { $0 = $0 "," }
            /^\(see$/ || /^\.BR stdout / { next }
            { print }
          ' \
          | groff -man -rHY=0 -dAD=l -Tutf8 -P -cbou > "$out/linux-intro"
      '';
  vmKernel = callPackage ./vm/kernel.nix { };
  vmRootfs = callPackage ./vm/rootfs.nix {
    inherit
      homeDir
      libappsSrc
      ;
  };

  assets =
    runCommand "www-sebastianrasor-com-assets"
      {
        nativeBuildInputs = [
          esbuild
          jq
          woff2
        ];
      }
      ''
        mkdir -p "$out" vendor/v86
        cp -r --no-preserve=mode ${./assets}/. "$out/"

        cp -r ${libappsSrc}/libdot ${libappsSrc}/hterm vendor/
        chmod -R u+w vendor
        tar -xzf ${v86Tarball} --strip-components=1 -C vendor/v86

        for pkg in vendor/hterm/package.json vendor/libdot/package.json; do
          jq '. + { gitCommitHash: "${lib.substring 0 12 libappsSrc.rev}", gitDate: "unknown" }' \
            "$pkg" > "$pkg.tmp"
          mv "$pkg.tmp" "$pkg"
        done

        jq 'with_entries(
          select(
            (.key | startswith("HTERM_"))
            and (.key | startswith("HTERM_PREF_") | not)
            and (.key | startswith("HTERM_NAME_PREF_") | not)
            and (.key | startswith("HTERM_TITLE_PREF_") | not)
          )
          | .value |= del(.description)
        )' ${libappsSrc}/nassh/_locales/en/messages.json > vendor/hterm_messages.json

        substituteInPlace vendor/hterm/index.js \
          --replace-fail './dist/js/hterm_resources.js' './js/deps_resources.shim.js'
        substituteInPlace vendor/libdot/index.js \
          --replace-fail './dist/js/libdot_resources.js' './js/deps_resources.shim.js'

        cat > vendor/hterm/js/deps_punycode.rollup.js <<'EOF'
        export const punycode = {
          toASCII(domain) {
            try {
              return new URL("http://" + domain).hostname;
            } catch {
              return domain;
            }
          },
        };
        EOF

        cp ${./assets/app.js} app.js
        esbuild app.js \
          --bundle \
          --minify \
          --format=esm \
          --platform=browser \
          --target=es2022 \
          --loader:.html=text \
          --loader:.svg=text \
          --loader:.png=dataurl \
          --loader:.ogg=dataurl \
          "--external:node:*" \
          --external:crypto \
          --external:fs \
          --external:perf_hooks \
          --outfile="$out/app.js"

        cp "${atkinson-hyperlegible-mono}/share/fonts/truetype/AtkinsonHyperlegibleMono[wght].ttf" \
          AtkinsonHyperlegibleMono.ttf
        woff2_compress AtkinsonHyperlegibleMono.ttf
        install -Dm644 AtkinsonHyperlegibleMono.woff2 \
          "$out/AtkinsonHyperlegibleMono.woff2"

        install -Dm644 vendor/v86/build/v86.wasm "$out/v86.wasm"
        install -Dm644 ${qemuBios} "$out/seabios.bin"
        install -Dm644 ${vmKernel}/bzImage "$out/bzImage"
        install -Dm644 ${vmRootfs} "$out/initramfs.img"
      '';

  src = lib.fileset.toSource {
    root = ./.;
    fileset = craneLib.fileset.commonCargoSources ./.;
  };

  commonArgs = {
    inherit src;
    strictDeps = true;
    buildInputs = [ openssl ];
    nativeBuildInputs = [ pkg-config ];
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  packageArgs = commonArgs // {
    inherit cargoArtifacts;
    env = {
      WWW_ASSETS_DIR = assets;
      WWW_HOME_DIR = homeDir;
    };
  };
in
craneLib.buildPackage (
  packageArgs
  // {
    passthru = {
      inherit
        assets
        homeDir
        vmKernel
        vmRootfs
        ;
      checks.clippy = craneLib.cargoClippy (
        packageArgs
        // {
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        }
      );
    };
    meta = {
      description = "Personal website of Sebastian Rasor";
      mainProgram = (craneLib.crateNameFromCargoToml { inherit src; }).pname;
      platforms = [ "x86_64-linux" ];
    };
  }
)
