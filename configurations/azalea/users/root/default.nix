{ ... }:
{
  # TODO: implement a global NixOS Home Manager config
  # home-manager.users.root = lib.mkIf config.sebastianrasor.home-manager.enable import ./home.nix;
  home-manager.users.root = import ./home.nix;
}
