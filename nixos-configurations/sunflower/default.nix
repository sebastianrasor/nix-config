inputs@{ nixos-hardware, ... }:
_: {
  networking.hostName = "sunflower";

  sebastianrasor = {
    core.enable = true;
    core.laptop = true;
  };

  imports = [
    nixos-hardware.nixosModules.framework-12-13th-gen-intel
    ./hardware-configuration.nix
    (import ./disk-config.nix inputs)
  ]
  ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.11";
}
