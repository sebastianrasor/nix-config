{
  config,
  lib,
  pkgs,
  ...
}:
{
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
          source = config.sebastianrasor.gpg-key;
        }
      ];
    };

    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-qt;
    };

    programs.ssh.matchBlocks.gpg-agent.match =
      lib.mkIf config.programs.ssh.enable "Host * exec \"gpg-connect-agent UPDATESTARTUPTTY /bye\"";

    home.activation.removeGpgSmartCardPrompt = lib.hm.dag.entryAfter [ "importGpgKeys" ] ''
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
