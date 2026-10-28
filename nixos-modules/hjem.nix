inputs@{
  hjem,
  self,
  ...
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.hjem;
  hostSuffix = "@${config.networking.hostName}";
  hostUsers = lib.pipe ../hjem-configurations [
    builtins.readDir
    builtins.attrNames
    (builtins.filter (name: name != "default.nix"))
    (map (entry: {
      inherit entry;
      name = lib.removeSuffix ".nix" entry;
    }))
    (builtins.filter (x: lib.hasSuffix hostSuffix x.name))
    (map (x: {
      name = lib.removeSuffix hostSuffix x.name;
      value = lib.modules.importApply ../hjem-configurations/${x.entry} inputs;
    }))
    builtins.listToAttrs
  ];
in
{
  options.sebastianrasor.hjem = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  imports = [
    hjem.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    environment.pathsToLink = [ "/share/fish" ];

    hjem = {
      clobberByDefault = true;
      extraModules = lib.attrsets.attrValues self.hjemModules;
      users = hostUsers;
    };
  };
}
