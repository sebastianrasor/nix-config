{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.comin;
  secretsEnabled = config.sebastianrasor.secrets.enable;
in
{
  options.sebastianrasor.comin = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/sebastianrasor/nix-config";
          branches.main.name = "main";
        }
      ];
    };
    sops.secrets.comin = lib.mkIf secretsEnabled {
      format = "binary";
      sopsFile = (builtins.toString inputs.nix-secrets) + "/comin";
      #owner = config.users.users.comin.name;
      #group = config.users.users.comin.group;
    };
    systemd.services.comin.environment.GIT_SSH_COMMAND =
      lib.mkIf secretsEnabled "${pkgs.openssh}/bin/ssh -i ${config.sops.secrets.comin.path} -o IdentitiesOnly=yes -o ForwardAgent=no";
  };
}
