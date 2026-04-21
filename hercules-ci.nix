inputs@{
  hercules-ci-effects,
  nixpkgs,
  self,
  ...
}:
let
  inherit ((import ./constants.nix)._module.args.constants) domain;
  inherit (nixpkgs) lib;
in
hercules-ci-effects.lib.mkHerculesCI { inherit inputs; } {
  herculesCI = herculesCI: {
    onPush.default.outputs.effects = lib.pipe self.nixosConfigurations [
      builtins.attrValues
      (map (
        nixosConfiguration:
        let
          inherit (nixosConfiguration) config;
          inherit (config.networking) hostName;
          inherit (config.system.build) toplevel;
          pkgs = import nixpkgs {
            inherit (config.nixpkgs.hostPlatform) system;
          };
          hci-effects = hercules-ci-effects.lib.withPkgs pkgs;
          sshCommand =
            hci-effects.ssh
              {
                destination = "${hostName}.ts.${domain}";
                sshOptions = "-o ConnectTimeout=10";
              }
              ''
                if [ "$(readlink -f /run/current-system)" == "${toplevel}" ]; then
                  exit 0
                fi

                ${lib.getExe pkgs.nixos-rebuild-ng} --no-reexec switch --store-path ${toplevel}
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

                if ! ${sshCommand}; then
                  exit "''${?/255/0}"
                fi

                exit 0
              '';
              passthru = {
                prebuilt = toplevel // {
                  inherit config;
                };
                inherit config;
              };
            }
          );
        }
      ))
      builtins.listToAttrs
    ];
  };
}
