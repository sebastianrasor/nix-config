{ inputs, ... }:
{
  networking.hostName = "sunflower";

  sebastianrasor.core.enable = true;
  sebastianrasor.core.laptop = true;

  sebastianrasor.deep-sleep.enable = true;
  sebastianrasor.suspend-fix.enable = true;

  imports = [
    inputs.nixos-hardware.nixosModules.framework-12-13th-gen-intel
    ./hardware-configuration.nix
    ./disk-config.nix
  ]
  ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.11";
}
