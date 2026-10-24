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
        "Host *.ts.${constants.domain}" = {
          ForwardAgent = "yes";
        };
      };
    };

    home.file = {
      # home-manager wrongly thinks it doesn't manage (and thus shouldn't clobber) this file due to the activation script
      ".ssh/config".force = true;
    };

    home.activation = {
      # https://github.com/nix-community/home-manager/issues/322
      fixSshPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run install -d -m 0700 "$HOME/.ssh"
        if [ -L "$HOME/.ssh/config" ]; then
          src="$(readlink -f "$HOME/.ssh/config")"
          run rm -f "$HOME/.ssh/config"
          run install -m 0600 "$src" "$HOME/.ssh/config"
        fi
      '';
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
