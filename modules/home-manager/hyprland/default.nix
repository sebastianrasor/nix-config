{
  config = import ./config.nix;
  init = import ./init.nix;
  input = import ./input.nix;
  monitor = import ./monitor.nix;
  portal = import ./portal.nix;
}
