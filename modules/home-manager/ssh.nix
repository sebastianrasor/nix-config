{
  config,
  lib,
  ...
}: {
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
    systemd.user.tmpfiles.rules = [
      #Type  Path            Mode  User  Group  Age  Argument
      "d     %t/ssh          0700  -     -      -    -"
      "d     %t/ssh/control  0700  -     -      -    -"
    ];
    home.persistence."${config.sebastianrasor.persistence.storagePath}".files = lib.mkIf config.sebastianrasor.persistence.enable (builtins.map (lib.strings.removePrefix config.home.homeDirectory) ["${config.home.homeDirectory}/.ssh/known_hosts"]);
  };
}
