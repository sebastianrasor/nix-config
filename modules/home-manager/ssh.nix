{
  config,
  lib,
  ...
}:
{
  options = {
    sebastianrasor.ssh.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.ssh.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      extraOptionOverrides = {
        CanonicalizeHostname = "yes";
        CanonicalDomains = "ts.rasor.us";
      };
      matchBlocks."*.ts.${config.sebastianrasor.domain}" = {
        controlMaster = "auto";
        controlPath = "\${XDG_RUNTIME_DIR}/ssh/control/%C";
        controlPersist = "10m";
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
