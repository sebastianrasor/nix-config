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
    nixpkgs.config.allowUnfree = true;
    nix = {
      registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
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
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        trusted-users = [
          "@wheel"
        ];
      };
    };
  };
}
