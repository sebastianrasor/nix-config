{inputs, ...}: {
  networking.hostName = "sunflower";

  sebastianrasor.core.enable = true;

  sebastianrasor.bluetooth.enable = true;
  sebastianrasor.cosmic.enable = true;
  sebastianrasor.dvorak.enable = true;
  sebastianrasor.fwupd.enable = true;
  sebastianrasor.lanzaboote.enable = true;
  sebastianrasor.networkmanager.enable = true;
  sebastianrasor.persistence.enable = true;
  sebastianrasor.pipewire.enable = true;
  sebastianrasor.plymouth.enable = true;
  sebastianrasor.systemd-boot.enable = true;
  sebastianrasor.yubikey.enable = true;

  imports =
    [
      inputs.nixos-hardware.nixosModules.framework-12-13th-gen-intel
      ./hardware-configuration.nix
      ./disk-config.nix
    ]
    ++ map (moduleFile: ./users + ("/" + moduleFile)) (builtins.attrNames (builtins.readDir ./users));

  system.stateVersion = "25.11";
}
