{ sops-nix, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.secrets;

  hostKeyFile = if cfg.tpmAgeKey != null then builtins.toFile "key.txt" cfg.tpmAgeKey else null;
in
{
  options.sebastianrasor.secrets = {
    enable = lib.mkEnableOption "secrets";

    tpmAgeKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  imports = [ sops-nix.nixosModules.sops ];

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./secrets.yaml;

      age =
        if cfg.tpmAgeKey != null then
          {
            plugins = with pkgs; [
              age-plugin-tpm
            ];
            sshKeyPaths = lib.mkForce [ ];
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = false;
          }
        else
          {
            sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };

      secrets = lib.mkMerge (
        lib.mapAttrsToList (
          username: userCfg:
          lib.mkIf userCfg.enable (
            lib.mapAttrs (_: _: {
              owner = username;
            }) userCfg.sebastianrasor.secrets
          )
        ) config.hjem.users
      );
    };

    system.activationScripts.install-age-key =
      let
        escapedHostFile = lib.escapeShellArg hostKeyFile;
        escapedKeyFile = lib.escapeShellArg config.sops.age.keyFile;
      in
      lib.mkIf (hostKeyFile != null) (
        lib.stringAfter [ ] ''
          if [[ ! -f ${escapedKeyFile} ]]; then
            echo installing tpm age key
            install -Dm0600 ${escapedHostFile} ${escapedKeyFile}
          fi
        ''
      );
  };
}
