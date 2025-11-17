{
  config,
  inputs,
  lib,
  ...
}: {
  options = {
    sebastianrasor.secrets.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.secrets.enable {
    sops = {
      defaultSopsFile = (builtins.toString inputs.nix-secrets) + "/secrets.yaml";
      validateSopsFiles = false;

      age = {
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };
    };
  };
}
