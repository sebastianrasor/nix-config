{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.core.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.core.enable {
    sebastianrasor.home-manager.enable = true;
    sebastianrasor.i18n.enable = true;
    sebastianrasor.nix.enable = true;
    sebastianrasor.secrets.enable = true;
    sebastianrasor.sshd.enable = true;
    sebastianrasor.sudo.enable = true;

    networking.domain = config.sebastianrasor.domain;
  };
}
