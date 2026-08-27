inputs@{ nixos-hardware, ... }:
{ lib, ... }:
{
  networking.hostName = "sakura";

  sebastianrasor = {
    core.enable = true;
    core.laptop = true;

    # https://forum.makemkv.com/forum/viewtopic.php?p=203406
    # makemkv.enable = true;
    steam.enable = true;

    unas = {
      enable = true;
      host = "unas-pro.internal";
    };
    unas-lazy-media.enable = true;
  };

  imports = [
    nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ./hardware-configuration.nix
    (lib.modules.importApply ./disk-config.nix inputs)
  ]
  ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "26.05";
}
