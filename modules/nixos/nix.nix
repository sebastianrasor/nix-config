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
    nixpkgs.config.allowUnfree = true;
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
          "https://nix-community.cachix.org"
          "https://sebastianrasor.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "sebastianrasor.cachix.org-1:GLTqReyK+C9RY+2NQoLu/S/jdJ9nQ1TJGGuaV7oSuMg="
        ];
        trusted-users = [
          "@wheel"
        ];
      };
    };
  };
}
