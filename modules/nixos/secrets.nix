{
  config,
  inputs,
  lib,
  ...
}: let
  secretspath = builtins.toString inputs.mysecrets;
in {
  options = {
    sebastianrasor.secrets.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.secrets.enable {
    sops = {
      defaultSopsFile = "${secretspath}/secrets.yaml";
      validateSopsFiles = false;

      age = {
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };

      secrets = {
        tailscale_key = {};
        acme-env = {};
      };
    };
  };
}
