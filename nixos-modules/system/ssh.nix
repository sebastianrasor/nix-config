{ constants, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.ssh;
in
{
  options.sebastianrasor.ssh = {
    enable = lib.mkEnableOption "SSH";

    addSshKeysToUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enableAskPassword = true;
      askPassword = "${pkgs.openssh-askpass}/libexec/gtk-ssh-askpass";
      startAgent = true;
    };

    users.users = builtins.listToAttrs (
      map (user: {
        name = user;
        value = {
          openssh.authorizedKeys.keys = constants.sshPublicKeys;
        };
      }) cfg.addSshKeysToUsers
    );
  };
}
