_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.zed-editor;
in
{
  options.sebastianrasor.zed-editor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    sebastianrasor.secrets."google/apiKeys/gemini" = { };

    packages = [
      (pkgs.symlinkJoin {
        name = "${lib.getName pkgs.zed-editor}-wrapped-${lib.getVersion pkgs.zed-editor}";
        paths = [ pkgs.zed-editor ];
        preferLocalBuild = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild =
          let
            geminiApiKeyPath = config.sebastianrasor.secrets."google/apiKeys/gemini".path;
          in
          ''
            wrapProgram $out/bin/${pkgs.zed-editor.meta.mainProgram} \
              --suffix PATH : ${lib.makeBinPath [ pkgs.bubblewrap ]} \
              ${lib.optionalString (geminiApiKeyPath != null) ''
                --run 'export GEMINI_API_KEY="$(< ${lib.escapeShellArg geminiApiKeyPath})"'
              ''}
          '';
      })
    ];

    xdg.config.files."zed/settings.json".source = ./settings.json;
  };
}
