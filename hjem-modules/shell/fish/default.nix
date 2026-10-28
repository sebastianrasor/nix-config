_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.fish;
in
{
  options.sebastianrasor.fish = {
    enable = lib.mkEnableOption "Fish shell";

    bashInit = lib.mkOption {
      type = lib.types.bool;
      default = config.sebastianrasor.bash.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.fish
    ];

    xdg.config.files = {
      "fish/config.fish".source = ./config.fish;
      "fish/functions/fish_greeting.fish".source = ./functions/fish_greeting.fish;
      "fish/functions/fish_user_key_bindings.fish".source = ./functions/fish_user_key_bindings.fish;
      "fish/functions/last_history_item.fish".source = ./functions/last_history_item.fish;
      "bashrc.d/fish.sh" = lib.mkIf cfg.bashInit {
        source = ./fish.sh;
      };
    };
  };
}
