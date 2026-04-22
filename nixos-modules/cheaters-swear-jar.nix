{ self, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.cheaters-swear-jar;
  cheaters-swear-jar = self.packages.${pkgs.stdenv.hostPlatform.system}.cheaters-swear-jar;
in
{
  options.sebastianrasor.cheaters-swear-jar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cheaters-swear-jar = {
      description = "Discord bot";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        Environment = [
          "DISCORD_TOKEN_PATH=%d/discordToken"
          "GOOGLE_API_KEY_PATH=%d/googleApiKey"
        ];
        ExecStart = "${lib.getExe cheaters-swear-jar}";
        LoadCredential = [
          "discordToken:${config.sops.secrets."discord/tokens/cheatersSwearJar".path}"
          "googleApiKey:${config.sops.secrets."google/apiKeys/cheatersSwearJar".path}"
        ];
        Restart = "on-failure";
        RuntimeDirectory = "cheaters-swear-jar";
      };
    };

    sops.secrets = {
      "discord/tokens/cheatersSwearJar" = {};
      "google/apiKeys/cheatersSwearJar" = {};
    };
  };
}
