{ constants, ... }:
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
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      extraOptionOverrides = {
        AddKeysToAgent = "yes";
        CanonicalizeHostname = "yes";
        CanonicalDomains = "ts.${constants.domain}";
        ControlMaster = "auto";
        ControlPath = "\${XDG_RUNTIME_DIR}/ssh/control/%C";
        ControlPersist = "10m";
      };
      settings = {
        "Host *.ts.rasor.us" = {
          ForwardAgent = "yes";
        };
      };
    };

    #systemd.user.tmpfiles.settings."10-ssh".rules = {
    #  "%t/ssh" = {
    #    d = {
    #      mode = "0700";
    #    };
    #  };
    #  "%t/ssh/control" = {
    #    d = {
    #      mode = "0700";
    #    };
    #  };
    #};
    systemd.user.tmpfiles.rules = [
      #Type  Path            Mode  User  Group  Age  Argument
      "d     %t/ssh          0700  -     -      -    -"
      "d     %t/ssh/control  0700  -     -      -    -"
    ];

    sebastianrasor.persistence.files = [ "${config.home.homeDirectory}/.ssh/known_hosts" ];
  };
}
