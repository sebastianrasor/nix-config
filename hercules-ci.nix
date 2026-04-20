inputs@{
  hercules-ci-effects,
  nixpkgs,
  self,
  ...
}:
let
  inherit ((import ./constants.nix)._module.args.constants) domain;
in
hercules-ci-effects.lib.mkHerculesCI { inherit inputs; } {
  herculesCI = herculesCI: {
    onPush.default.outputs.effects = nixpkgs.lib.pipe self.nixosConfigurations [
      builtins.attrValues
      (map (
        nixosConfiguration:
        let
          inherit (nixosConfiguration.config.networking) hostName;
          inherit (nixosConfiguration.config.system.build.toplevel) outPath;
          pkgs = import nixpkgs {
            inherit (nixosConfiguration.config.nixpkgs.hostPlatform) system;
          };
          hci-effects = hercules-ci-effects.lib.withPkgs pkgs;
          sshCommand =
            hci-effects.ssh
              {
                destination = "${hostName}.ts.${domain}";
                sshOptions = "-o ConnectTimeout=10";
              }
              ''
                if [ "$(readlink -f /run/current-system)" == "${outPath}" ]; then
                  exit 0
                fi

                cmd=(
                  "systemd-run"
                  "-E" "LOCALE_ARCHIVE"
                  "--collect"
                  "--no-ask-password"
                  "--pty"
                  "--quiet"
                  "--same-dir"
                  "--service-type=exec"
                  "--unit=deploy-switch-to-configuration"
                  "--wait"
                  "${outPath}/bin/switch-to-configuration"
                )

                nix-env -p /nix/var/nix/profiles/system --set ${outPath}
                "''${cmd[@]}" switch
              '';
        in
        {
          name = "deploy-${hostName}";
          value = hci-effects.runIf (herculesCI.config.repo.branch == "main") (
            hci-effects.mkEffect {
              effectScript = ''
                writeSSHKey ssh
                # todo: move this into the configuration itself somehow
                cat >~/.ssh/known_hosts <<EOF
                azalea.ts.${domain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO5pVGXbupdNG/9acDwOd6loG8CBBaNsreyoYCY4at9J
                carbon.ts.${domain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAGdZ/fyPx7w2GsbE337H0kNst+GWL/gN4piJizkWj/9
                nephele.ts.${domain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIISaqWRMez2mFczqhMmiYe0KzNeENKsqEQw/AsOC+Ay+
                sunflower.ts.${domain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII85WkAO+BoPgHC8Vj7Y3ab3aOOLDx9e8jul4rBLAXiM
                EOF

                if ${sshCommand}; then
                  exit "''${?/255/0}"
                fi

                exit 0
              '';
            }
          );
        }
      ))
      builtins.listToAttrs
    ];
  };
}
