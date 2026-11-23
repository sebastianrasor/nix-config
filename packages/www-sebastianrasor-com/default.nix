{
  lib,
  atkinson-hyperlegible-mono,
  callPackage,
  cargo,
  craneLib,
  curl,
  esbuild,
  fetchgit,
  fetchzip,
  git,
  groff,
  jq,
  man-pages,
  nix,
  nix-prefetch-git,
  nodejs,
  runCommand,
  rustc,
  seabios,
  targets ? callPackage ../targets { },
  woff2,
  writeShellApplication,
  zstd,
}:
let
  sources = lib.importJSON ./vm/sources.json;
  libappsSrc = fetchgit sources.libapps;
  v86Src = fetchzip sources.v86;

  qemuBios = (seabios.override { ___build-type = "qemu"; }).firmware;

  vmJs = lib.fileset.toSource {
    root = ./vm;
    fileset = lib.fileset.unions [
      ./vm/mk-state.mjs
      ./vm/v86-common.js
    ];
  };

  homeDir =
    runCommand "www-sebastianrasor-com-home"
      {
        nativeBuildInputs = [ groff ];
      }
      ''
        set -euo pipefail
        mkdir -p "$out/targets"
        cp -r --no-preserve=mode ${./home}/. "$out/"
        chmod -R u+w "$out"
        install -Dm644 -t "$out/targets" ${targets}/*.pdf
        gzip -dc ${lib.getMan man-pages}/share/man/man0/intro.0.gz \
          | awk '
            /^\.TH intro / { th = sub(/^\.TH intro 0 /, ".TH intro 1 ") }
            /^intro \\- / { $0 = "intro \\- introduction to user commands"; desc = 1 }
            /^\.(SH|SS) / {
              skip = ($0 ~ /^\.SS (Login|Disks and filesystems|Getting information)$/ || $0 == ".SH SEE ALSO")
              if (skip) skipped++
              drop = 0
            }
            skip { next }
            /^\.P$/ { drop = 0 }
            /^See also$/ || /^Large searches on a multi-GB disk/ { drop = 1; dropped++ }
            drop { next }
            /^You can change your shell,$/ || /^and everybody has their own favorite one\.$/ { next }
            /^\.RB "(knuth login|Password): "/ { next }
            /sent to "standard output"$/ { $0 = $0 "," }
            /^\(see$/ || /^\.BR stdout / { next }
            { print }
            END {
              if (!th || !desc || skipped < 4 || dropped < 2) {
                print "intro.0.gz structure changed; update awk filter" > "/dev/stderr"
                exit 1
              }
            }
          ' \
          | groff -man -rHY=0 -dAD=l -Tutf8 -P -cbou > "$out/linux-intro"
      '';

  vmKernel = callPackage ./vm/kernel.nix { };
  vmRootfs = callPackage ./vm/rootfs.nix { inherit libappsSrc; };

  vmState =
    runCommand "www-sebastianrasor-com-vm-state"
      {
        nativeBuildInputs = [
          nodejs
          zstd
        ];
      }
      ''
        mkdir -p "$out"
        node ${vmJs}/mk-state.mjs \
          --libv86 "${v86Src}/build/libv86.mjs" \
          --wasm "${v86Src}/build/v86.wasm" \
          --bios "${qemuBios}" \
          --bzimage "${vmKernel}/bzImage" \
          --initrd "${vmRootfs}" \
          --home "${homeDir}" \
          --out-state state.bin \
          --out-prompt "$out/prompt.txt" \
          --out-lazy "$out/lazy"
        zstd --ultra -22 -T1 -q state.bin -o "$out/state.zst"
      '';

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
        mkdir -p "$out" assets/vendor
        cp -r ${libappsSrc}/libdot ${libappsSrc}/hterm assets/vendor/
        chmod -R u+w assets/vendor
        ln -s ${v86Src} assets/vendor/v86
        ln -s ${vmJs} vm

        for pkg in assets/vendor/hterm/package.json assets/vendor/libdot/package.json; do
          jq '. + { gitCommitHash: "${lib.substring 0 12 libappsSrc.rev}", gitDate: "unknown" }' \
            "$pkg" > "$pkg.tmp"
          mv "$pkg.tmp" "$pkg"
        done

        jq 'with_entries(
          select(.key | test("^HTERM_(?!(NAME_|TITLE_)?PREF_)"))
          | .value |= del(.description)
        )' ${libappsSrc}/nassh/_locales/en/messages.json > assets/vendor/hterm_messages.json

        substituteInPlace assets/vendor/hterm/index.js \
          --replace-fail './dist/js/hterm_resources.js' './js/deps_resources.shim.js'
        substituteInPlace assets/vendor/libdot/index.js \
          --replace-fail './dist/js/libdot_resources.js' './js/deps_resources.shim.js'
        substituteInPlace assets/vendor/hterm/js/deps_resources.shim.js \
          --replace-fail "import auBell from '../audio/bell.ogg';" "const auBell = '/bell.ogg';"
        substituteInPlace assets/vendor/hterm/js/hterm_terminal.js \
          --replace-fail 'this.bellAudio_.play();' 'this.bellAudio_.play().catch(() => {});' \
          --replace-fail 'this.bellSequelchTimeout_' 'this.bellSquelchTimeout_'

        cat > assets/vendor/hterm/js/deps_punycode.rollup.js <<'EOF'
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

        cp ${./assets/app.js} assets/app.js
        esbuild assets/app.js \
          --bundle \
          --minify \
          --format=esm \
          --platform=browser \
          --target=es2022 \
          "--define:__INITIAL_PROMPT__=$(jq -Rs . "${vmState}/prompt.txt")" \
          --loader:.html=text \
          --loader:.svg=text \
          --loader:.png=dataurl \
          "--external:node:*" \
          --external:crypto \
          --external:fs \
          --external:perf_hooks \
          --outfile="$out/app.js"

        cp "${atkinson-hyperlegible-mono}/share/fonts/truetype/AtkinsonHyperlegibleMono[wght].ttf" \
          AtkinsonHyperlegibleMono.ttf
        woff2_compress AtkinsonHyperlegibleMono.ttf
        install -Dm644 AtkinsonHyperlegibleMono.woff2 "$out/AtkinsonHyperlegibleMono.woff2"

        install -Dm644 ${./assets/robots.txt} "$out/robots.txt"
        install -Dm644 ${./assets/sitemap.xml} "$out/sitemap.xml"
        install -Dm644 "${libappsSrc}/hterm/audio/bell.ogg" "$out/bell.ogg"
        install -Dm644 "${v86Src}/build/v86.wasm" "$out/v86.wasm"
        install -Dm644 "${vmState}/state.zst" "$out/state.zst"
        cp -r --no-preserve=mode "${vmState}/lazy/." "$out/"
      '';

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      (craneLib.fileset.commonCargoSources ./.)
      ./templates
      ./home/contact/message.eml
    ];
  };

  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    strictDeps = true;
  };

  packageArgs = {
    inherit src cargoArtifacts;
    strictDeps = true;
    env.WWW_ASSETS_DIR = assets;
  };

  updateScript = writeShellApplication {
    name = "update-www-sebastianrasor-com";
    runtimeInputs = [
      cargo
      curl
      git
      jq
      nix
      nix-prefetch-git
      rustc
    ];
    text = ''
      sources_file="packages/www-sebastianrasor-com/vm/sources.json"
      manifest="packages/www-sebastianrasor-com/Cargo.toml"
      if [ ! -f "$sources_file" ] || [ ! -f "$manifest" ]; then
        echo "Run from the repository root containing $sources_file and $manifest" >&2
        exit 1
      fi

      libapps_url=$(jq -r '.libapps.url' "$sources_file")
      v86_url=$(curl -fsSL https://registry.npmjs.org/v86/latest | jq -r '.dist.tarball')

      jq -n \
        --argjson libapps "$(nix-prefetch-git --quiet "$libapps_url")" \
        --arg v86_url "$v86_url" \
        --argjson v86_prefetch "$(nix store prefetch-file --unpack --json "$v86_url")" \
        '{
          libapps: ($libapps | { url, rev, hash }),
          v86: { url: $v86_url, hash: $v86_prefetch.hash }
        }' > "$sources_file"

      cargo update --manifest-path "$manifest"
    '';
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
        vmState
        updateScript
        ;
      checks = {
        clippy = craneLib.cargoClippy (
          packageArgs
          // {
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          }
        );
        rustfmt = craneLib.cargoFmt { inherit src; };
      };
    };
    meta = {
      description = "Personal website of Sebastian Rasor";
      mainProgram = (craneLib.crateNameFromCargoToml { inherit src; }).pname;
      platforms = [ "x86_64-linux" ];
    };
  }
)
