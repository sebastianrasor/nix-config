{ lib }:
rec {
  readNixDir =
    dir: fn:
    lib.pipe (builtins.readDir dir) [
      (lib.filterAttrs (
        name: type: name != "default.nix" && (type == "directory" || lib.hasSuffix ".nix" name)
      ))
      (lib.mapAttrs' (name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (fn (dir + "/${name}"))))
    ];

  readModulesDir =
    dir: inputs:
    lib.concatMapAttrs (
      name: type:
      let
        path = dir + "/${name}";
      in
      if name == "default.nix" then
        { }
      else if type == "regular" && lib.hasSuffix ".nix" name then
        { ${lib.removeSuffix ".nix" name} = lib.modules.importApply path inputs; }
      else if type == "directory" && builtins.pathExists (path + "/default.nix") then
        { ${name} = lib.modules.importApply path inputs; }
      else if type == "directory" then
        readModulesDir path inputs
      else
        { }
    ) (builtins.readDir dir);
}
