{inputs, ...}: {
  networking.hostName = "azalea";

  sebastianrasor.core.enable = true;
  sebastianrasor.core.laptop = true;

  sebastianrasor.makemkv.enable = true;
  sebastianrasor.steam.enable = true;

  sebastianrasor.unas = {
    enable = true;
    host = "unas-pro.internal";
  };
  sebastianrasor.unas-lazy-media.enable = true;

  imports =
    [
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ./hardware-configuration.nix
    ]
    ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "23.11";
}
