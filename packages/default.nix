pkgs:
let
  inherit (pkgs) lib;
  repoLib = import ../lib { inherit lib; };
  packages = repoLib.readNixDir ./. (
    path:
    let
      name = lib.removeSuffix ".nix" (baseNameOf path);
    in
    pkgs.${name} or (pkgs.callPackage path { })
  );
in
if pkgs ? stdenv then
  lib.filterAttrs (_: lib.meta.availableOn { inherit (pkgs.stdenv.hostPlatform) system; }) packages
else
  packages
