{
  lib,
  atkinson-hyperlegible-next,
  callPackage,
  fetchzip,
  openssl,
  pkg-config,
  rustPlatform,
  stdenvNoCC,
  woff2,
  targets ? callPackage ../targets { },
}:
let
  atkinson-hyperlegible-next-woff2 = stdenvNoCC.mkDerivation (finalAttrs: {
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
  });
  cargoToml = fromTOML (builtins.readFile ./Cargo.toml);
in
rustPlatform.buildRustPackage {
  inherit (cargoToml.package) version;
  pname = cargoToml.package.name;
  buildInputs = [ openssl ];
  nativeBuildInputs = [ pkg-config ];
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
  postPatch = ''
    install -Dm644 -t assets/ ${targets}/*.pdf
    install -Dm644 -t assets/ ${atkinson-hyperlegible-next-woff2}/AtkinsonHyperlegibleNextVF-Variable.woff2
  '';
  meta = {
    inherit (targets.meta) platforms;
    mainProgram = cargoToml.package.name;
  };
}
