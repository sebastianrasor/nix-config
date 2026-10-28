pkgs:
let
  inherit (pkgs) lib;
in
lib.pipe ./. [
  builtins.readDir
  builtins.attrNames
  (builtins.filter (name: name != "default.nix"))
  (map (
    entry:
    let
      name = lib.removeSuffix ".nix" entry;
    in
    {
      inherit name;
      value = pkgs.${name} or (pkgs.callPackage ./${entry} { });
    }
  ))
  builtins.listToAttrs
  (lib.filterAttrs (_: lib.meta.availableOn { inherit (pkgs.stdenv.hostPlatform) system; }))
]
