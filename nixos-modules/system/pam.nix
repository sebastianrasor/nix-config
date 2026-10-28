{ constants, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.pam;
in
{
  options.sebastianrasor.pam = {
    enable = lib.mkEnableOption "PAM";
  };

  config = lib.mkIf cfg.enable {
    security.pam = {
      services = {
        login.unixAuth = false;
        sudo.unixAuth = false;
        sudo.rssh = true;
      };

      u2f = lib.mkIf config.sebastianrasor.yubikey.enable {
        enable = true;
        settings = {
          origin = "pam://sebastianrasor";
          appid = "pam://sebastianrasor";
          authfile = lib.mkDefault (
            builtins.toFile "u2f_mappings" (
              lib.concatMapStringsSep "\n" (user: lib.concatStringsSep ":" ([ user ] ++ constants.u2fKeys)) [
                "sebastian"
                # more users if needed
              ]
            )
          );
          cue = true;
          pinverification = 1;
        };
      };

      rssh = lib.mkIf config.sebastianrasor.sshd.enable {
        enable = true;
        settings = {
          auth_key_file = "/etc/ssh/authorized_keys.d/$ruser";
          #cue = true;
        };
      };
    };
  };
}
