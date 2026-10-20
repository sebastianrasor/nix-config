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
        temp_pdf="$(mktemp --suffix=.pdf)"
        chromium --headless --print-to-pdf="$temp_pdf" --no-pdf-header-footer "$1"
        qpdf --empty --pages "$temp_pdf" 1-z -- --deterministic-id "''${1%.svg}.pdf"
        rm "$temp_pdf"
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

    svg2pdf 10x-ibs-50.svg
    svg2pdf 10x-ibs-100.svg
    svg2pdf 25x-ara-factory.svg
    svg2pdf 25x-ara-unlimited.svg
    svg2pdf 25x-usbr.svg
    svg2pdf b-8.svg
    svg2pdf b-16.svg

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 -t "$out" \
      10x-ibs-50.pdf \
      10x-ibs-100.pdf \
      25x-ara-factory.pdf \
      25x-ara-unlimited.pdf \
      25x-usbr.pdf \
      b-8.pdf \
      b-16.pdf

    runHook postInstall
  '';

  meta = {
    platforms = [ "x86_64-linux" ];
  };
})
