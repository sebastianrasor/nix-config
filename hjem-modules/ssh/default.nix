_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.ssh;
in
{
  options.sebastianrasor.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    files = {
      ".ssh" = {
        type = "directory";
        permissions = "0700";
      };
      ".ssh/config" = {
        type = "copy";
        permissions = "0600";
        source = ./config;
      };
    };

    xdg.config.files."user-tmpfiles.d/ssh.conf".source = ./user-tmpfiles.conf;

    sebastianrasor.persistence.files = [ "${config.directory}/.ssh/known_hosts" ];
  };
}
