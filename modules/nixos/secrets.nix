{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.secrets;
in
{
  options.sebastianrasor.secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = (builtins.toString inputs.nix-secrets) + "/secrets.yaml";
      validateSopsFiles = false;

      age = {
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };
    };
  };
}
