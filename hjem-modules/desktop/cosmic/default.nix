{ nixpkgs, ... }:
let
  inherit (nixpkgs) lib;

  cosmicConfigFiles = lib.pipe ./cosmic [
    lib.filesystem.listFilesRecursive
    (map (file: {
      name = "cosmic/${lib.strings.removePrefix "./" (lib.path.removePrefix ./cosmic file)}";
      value.source = file;
    }))
    builtins.listToAttrs
  ];
in
{
  config,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.cosmic;

  cosmicTheme =
    pkgs.runCommand "cosmic-theme"
      {
        nativeBuildInputs = [ pkgs.cosmic-ext-ctl ];
        preferLocalBuild = true;
      }
      ''
        export XDG_CONFIG_HOME="$out"
        mkdir -p "$out/cosmic/com.system76.CosmicTheme.Dark.Builder/v2"
        cp ${./cosmic/com.system76.CosmicTheme.Dark.Builder/v2/accent} \
          "$out/cosmic/com.system76.CosmicTheme.Dark.Builder/v2/accent"
        cosmic-ctl build-theme
      '';
in
{
  options.sebastianrasor.cosmic = {
    enable = lib.mkEnableOption "COSMIC desktop user configuration";
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.cosmic-term
    ];

    xdg.data.files."wallpapers/bliss-600dpi.png".source = pkgs.fetchurl {
      url = "https://archive.org/download/bliss-600dpi/bliss-600dpi.png";
      hash = "sha256-py1E7kDEBqG4g3qU5/yINL1/byLoxdqaoo2p1ZItR9o=";
    };

    xdg.config.files = cosmicConfigFiles // {
      "cosmic-initial-setup-done".text = "";
      "cosmic/com.system76.CosmicTheme.Dark/v2".source =
        "${cosmicTheme}/cosmic/com.system76.CosmicTheme.Dark/v2";
      "cosmic/com.system76.CosmicTheme.Light/v2".source =
        "${cosmicTheme}/cosmic/com.system76.CosmicTheme.Light/v2";
    };
  };
}
