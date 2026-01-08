{ inputs, ... }:
{
  networking.hostName = "azalea";

  sebastianrasor = {
    core.enable = true;
    core.laptop = true;

    makemkv.enable = true;
    steam.enable = true;

    unas = {
      enable = true;
      host = "unas-pro.internal";
    };
    unas-lazy-media.enable = true;
  };

  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ]
  ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "23.11";
}
