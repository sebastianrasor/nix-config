inputs@{ constants, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.nix;
in
{
  options.sebastianrasor.nix = {
    enable = lib.mkEnableOption "nix";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      channel.enable = false;
      registry = lib.mapAttrs (_: value: { flake = value; }) (
        lib.filterAttrs (_: lib.isType "flake") inputs
      );
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      settings = {
        auto-optimise-store = true;
        build-dir = lib.mkIf config.sebastianrasor.persistence.enable "${config.sebastianrasor.persistence.storagePath}/nix-daemon";
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
        substituters = [
          "https://cache.ts.${constants.domain}"
        ];
        trusted-public-keys = [
          constants.binaryCachePublicKey
        ];
        trusted-users = [
          "@wheel"
        ];
      };
    };
  };
}
