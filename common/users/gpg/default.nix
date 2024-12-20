# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    settings = {
      limit-card-insert-tries = "1";
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
}
