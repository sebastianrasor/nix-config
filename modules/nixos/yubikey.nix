{ lib, pkgs, ... }: {
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
  environment.sessionVariables = rec {
    LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.pcsclite ];
  };
}
