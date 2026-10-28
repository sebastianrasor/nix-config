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
    enable = lib.mkEnableOption "SSH";
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

    sebastianrasor.persistence.files = [ "${config.directory}/.ssh/known_hosts" ];
  };
}
