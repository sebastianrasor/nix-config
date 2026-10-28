inputs@{
  constants,
  hercules-ci-effects,
  nixpkgs,
  self,
  ...
}:
let
  inherit (constants) domain;
  inherit (nixpkgs) lib;
in
hercules-ci-effects.lib.mkHerculesCI { inherit inputs; } {
  herculesCI = herculesCI: {
    onPush.default.outputs.effects = lib.pipe self.nixosConfigurations [
      builtins.attrValues
      (map (
        nixosConfiguration:
        let
          inherit (nixosConfiguration) config pkgs;
          inherit (config.networking) hostName;
          inherit (config.system.build) toplevel;
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
              secretsMap.ssh = "ssh";
              effectScript = ''
                writeSSHKey ssh
                cat >~/.ssh/known_hosts <<EOF
                ${hostName}.ts.${domain} ${config.sebastianrasor.sshd.publicKey}
                EOF

                ${sshCommand} || exit "''${?/255/0}"
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
