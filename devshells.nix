pkgs:
let
  inherit (pkgs) lib;
in
(lib.pipe ./packages [
  builtins.readDir
  (lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists ./packages/${name}/shell.nix
  ))
  (lib.mapAttrs' (
    name: _:
    lib.nameValuePair "packages/${name}" (import ./packages/${name}/shell.nix { inherit pkgs; })
  ))
])
// {
  default = import ./shell.nix { inherit pkgs; };
}
