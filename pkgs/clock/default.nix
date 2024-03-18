{ pkgs, lib, stdenv }:
stdenv.mkDerivation {
  name = "clock";

  propagatedBuildInputs = [
    pkgs.python3
  ];

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = "install -Dm755 ${./clock.py} $out/bin/clock";
}
