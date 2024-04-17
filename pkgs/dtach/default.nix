{ fetchFromGitHub, stdenv }:
stdenv.mkDerivation {
  pname = "dtach";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "sebastianrasor";
    repo = "dtach";
    rev = "f3dc5886992a5544fe7412565b4ce4a47d019a19";
    hash = "sha256-eZWpP2IYwTKlKXx8Wnmau1B1jKb4qdIWjTiD77/to0Y=";
  };

  buildPhase = ''
    ./configure && make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp dtach $out/bin
  '';
}
