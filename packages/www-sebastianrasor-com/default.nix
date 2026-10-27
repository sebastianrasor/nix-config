{
  lib,
  callPackage,
  craneLib,
  fetchzip,
  openssl,
  pkg-config,
  stdenvNoCC,
  targets ? callPackage ../targets { },
}:
let
  atkinson-hyperlegible-next-woff2 = stdenvNoCC.mkDerivation {
    pname = "atkinson-hyperlegible-next-woff2";
    version = "1.0.0";

    src = fetchzip {
      url = "https://brailleinstitute.box.com/shared/static/waaf5z9gfss6w6tf5118im5hhlwolacc.zip";
      hash = "sha256-CGrFm+Uyeap6rWI12/MRhFxj1Al4PMwtTlm6brqDNGs=";
      stripRoot = false;
    };

    installPhase = ''
      install -Dm644 "Atkinson Hyperlegible Next/For Professional Use Only/Variable/AtkinsonHyperlegibleNextVF-Variable.woff2" "$out/AtkinsonHyperlegibleNextVF-Variable.woff2"
    '';
  };
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      (craneLib.fileset.commonCargoSources ./.)
      ./assets
    ];
  };
  commonArgs = {
    inherit src;
    strictDeps = true;
    buildInputs = [ openssl ];
    nativeBuildInputs = [ pkg-config ];
  };
in
craneLib.buildPackage (
  commonArgs
  // {
    cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    postPatch = ''
      install -Dm644 -t assets/ ${targets}/*.pdf
      install -Dm644 -t assets/ ${atkinson-hyperlegible-next-woff2}/AtkinsonHyperlegibleNextVF-Variable.woff2
    '';
    meta = {
      inherit (targets.meta) platforms;
      mainProgram = (craneLib.crateNameFromCargoToml { inherit src; }).pname;
    };
  }
)
