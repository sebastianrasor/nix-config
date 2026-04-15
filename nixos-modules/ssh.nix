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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enableAskPassword = true;
      askPassword = "${pkgs.openssh-askpass}/libexec/gtk-ssh-askpass";
      startAgent = true;
    };
  };
}
