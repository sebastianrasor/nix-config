{ config, lib, ... }:
{
  home-manager.users.root = lib.mkIf config.sebastianrasor.home-manager.enable (import ./home.nix);
}
