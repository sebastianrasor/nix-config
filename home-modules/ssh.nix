{
  config,
  constants,
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
        CanonicalizeHostname = "yes";
        CanonicalDomains = "ts.${constants.domain}";
      };
      matchBlocks."*" = {
        addKeysToAgent = "yes"; # required for rssh to work properly
        controlMaster = "auto";
        controlPath = "\${XDG_RUNTIME_DIR}/ssh/control/%C";
        controlPersist = "10m";
      };
      matchBlocks."*.ts.${constants.domain}" = {
        forwardAgent = true;
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
