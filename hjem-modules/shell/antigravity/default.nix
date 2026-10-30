_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.antigravity;
in
{
  options.sebastianrasor.antigravity = {
    enable = lib.mkEnableOption "Antigravity";
  };

  config = lib.mkIf cfg.enable {
    packages = [ pkgs.antigravity-cli ];

    files.".gemini/antigravity-cli/settings.json".source = ./settings.json;

    sebastianrasor.persistence.directories = [ "${config.directory}/.gemini/antigravity-cli" ];
  };
}
