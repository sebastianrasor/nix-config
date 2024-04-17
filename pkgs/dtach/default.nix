{ stdenv }:
stdenv.mkDerivation {
  pname = "dtach";
  version = "0.10.0";

  src = ./.;

  buildPhase = ''
    ./configure && make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp dtach $out/bin
  '';
}
