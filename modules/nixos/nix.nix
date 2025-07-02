{
  config,
  inputs,
  lib,
  ...
}: {
  options = {
    sebastianrasor.nix.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.nix.enable {
    nix = {
      registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      settings = {
        auto-optimise-store = true;
        connect-timeout = 5;
        fallback = true;
        log-lines = 25;
        max-free = 1000000000;
        min-free = 128000000;
        warn-dirty = false;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "@wheel"
        ];
      };
    };
  };
}
