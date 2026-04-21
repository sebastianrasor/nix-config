pkgs:
let
  inherit (pkgs) lib;
  updateName = nameUpdater: x: x // { name = nameUpdater x.name; };
in
(lib.pipe ./. [
  lib.filesystem.listFilesRecursive
  (lib.filter (file: baseNameOf file == "shell.nix"))
  (map (shell: {
    name = lib.path.removePrefix ./. shell;
    value = import shell { inherit pkgs; };
  }))
  (map (updateName lib.path.subpath.components))
  (map (updateName lib.init))
  (lib.filter (attrs: attrs.name != [ ]))
  (map (updateName (lib.join "/")))
  builtins.listToAttrs
])
// {
  default = import ./shell.nix { inherit pkgs; };
}
