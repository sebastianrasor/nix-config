{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.nix;
in
{
  options.sebastianrasor.nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      extraOptions = ''
        build-dir = /nix/persist/nix-daemon
      '';

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
        substituters = [
          "https://cache.ts.rasor.us"
        ];
        trusted-public-keys = [
          "cache.ts.rasor.us-1:f2inISwhx2bWqv3HkEjsZw6VXJpKGxKqzTAqRl6rJWc="
        ];
        trusted-users = [
          "@wheel"
        ];
      };
    };
  };
}
