{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.gpg.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.gpg.enable {
    programs.gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      settings = {
        limit-card-insert-tries = "1";
      };
      scdaemonSettings = {
        disable-ccid = true;
      };
      publicKeys = [
        {
          trust = "ultimate";
          source = ./0xE346A2A083D90F7D.asc;
        }
        {
          trust = "ultimate";
          source = ./0x4A14A9E2AC256044.asc;
        }
        {
          trust = "ultimate";
          source = ./0xF10C0FFD5B533126.asc;
        }
        {
          trust = "ultimate";
          source = ./0xF20DE4BA5B36D4E9.asc;
        }
      ];
    };

    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-tty;
    };

    programs.ssh.matchBlocks.gpg-agent.match =
      lib.mkIf config.programs.ssh.enable "Host * exec \"gpg-connect-agent UPDATESTARTUPTTY /bye\"";

    home.activation.removeGpgSmartCardPrompt = lib.hm.dag.entryAfter ["importGpgKeys"] ''
         shopt -s nullglob
         for key in ${config.programs.gpg.homedir}/private-keys-v1.d/*.key; do
           if grep -q 'shadowed-private-key' $key && ! grep -q '^Prompt:' $key; then
             if [ -z ''${DRY_RUN+x} ]; then
        echo 'Prompt: no' >> $key
      else
        printf "echo 'Prompt: no' >> $key\n"
      fi
           fi
         done
    '';
  };
}
