{
  lib,
  atkinson-hyperlegible-next,
  chromium,
  qpdf,
  stdenvNoCC,
  writeShellApplication,
}:
let
  svg2pdf = (
    writeShellApplication {
      name = "svg2pdf";

      runtimeInputs = [
        chromium
        qpdf
      ];

      text = ''
        for svg
        do
          temp_pdf="$(mktemp --suffix=.pdf)"
          chromium --headless --print-to-pdf="$temp_pdf" --no-pdf-header-footer "$svg"
          qpdf --empty --pages "$temp_pdf" 1-z -- --deterministic-id "''${svg%.svg}.pdf"
          rm "$temp_pdf"
        done
      '';
    }
  );

in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "targets";
  version = "1.0.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    atkinson-hyperlegible-next
    svg2pdf
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)

    svg2pdf *.svg

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 -t "$out" *.pdf

    runHook postInstall
  '';

  meta = {
    platforms = [ "x86_64-linux" ];
  };
})
