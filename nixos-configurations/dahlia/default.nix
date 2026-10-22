inputs@{ nixos-hardware, ... }:
{ lib, ... }:
{
  networking.hostName = "dahlia";

  sebastianrasor = {
    core.enable = true;
    core.laptop = true;
  };

  imports = [
    nixos-hardware.nixosModules.framework-12-intel-core-series3
    ./hardware-configuration.nix
    (lib.modules.importApply ./disk-config.nix inputs)
  ]
  ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.11";
}
