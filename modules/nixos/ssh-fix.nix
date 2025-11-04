# Delete this file once nixpkgs PR 450658 hits unstable
# https://nixpk.gs/pr-tracker.html?pr=450658
{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.ssh-fix.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.ssh-fix.enable {
    programs.ssh.package = pkgs.openssh_10_2;
  };
}
