{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.gate;
  secretsEnabled = config.sebastianrasor.secrets.enable;
  minecraftInternalServerPort = config.sebastianrasor.minecraft-server.serverProperties.server-port;

  yaml = pkgs.formats.yaml { };
  gateConfigYamlFile = yaml.generate "config.yaml" cfg.config;

  startScript = pkgs.writeShellApplication {
    name = "minecraft-world-backup";
    runtimeInputs = with pkgs; [
      gate
      javaPackages.compiler.temurin-bin.jre-25
    ];
    text = "gate -c config.yaml";
  };
in
{
  options.sebastianrasor.gate = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    config = lib.mkOption {
      type = lib.types.submodule {
        freeformType = yaml.type;
      };
      default = {
        config = {
          bind = "0.0.0.0:25565";
          servers = {
            default = "carbon.ts.${config.sebastianrasor.domain}:${toString minecraftInternalServerPort}";
            local = "localhost:${toString minecraftInternalServerPort}";
          };
          try = [
            "local"
            "default"
          ];
          status = {
            motd = "A Minecraft Server";
            showMaxPlayers = 20;
            favicon = pkgs.fetchurl {
              url = "https://packpng.com/static/pack.png";
              sha256 = "0m9yw0llhqvvg9dbhwmisb97ldk12r01lw2nhq194s6nhawcyzcl";
            };
          };
          builtinCommands = false;
          forwarding = {
            mode = "velocity";
            velocitySecret =
              if secretsEnabled then config.sops.placeholder."minecraft/velocity-secret" else null;
          };
          bedrock = {
            managed = true;
            floodgateKeyPath = config.sops.secrets."minecraft/floodgate.pem".path;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.gate = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      description = "High performant & paralleled Minecraft proxy server";

      preStart = ''
        cp --dereference --remove-destination ${
          if secretsEnabled then config.sops.templates."gate/config.yaml".path else gateConfigYamlFile
        } config.yaml
      '';

      serviceConfig = {
        ExecStart = lib.getExe startScript;

        Restart = "always";

        User = config.users.users.gate.name;
        WorkingDirectory = config.users.users.gate.home;
      };
    };
    users.users.gate = {
      description = "High performant & paralleled Minecraft proxy server user";
      home = "/var/lib/gate";
      createHome = true;
      isSystemUser = true;
      group = config.users.groups.gate.name;
    };
    users.groups.gate = { };
    sops = lib.mkIf secretsEnabled {
      secrets = {
        "minecraft/velocity-secret" = {
          owner = lib.mkDefault config.users.users.gate.name;
          group = lib.mkDefault config.users.users.gate.group;
        };
        "minecraft/floodgate.pem" = {
          format = "binary";
          sopsFile = (builtins.toString inputs.nix-secrets) + "/floodgate.pem";
          owner = config.users.users.gate.name;
          group = config.users.users.gate.group;
        };
      };
      templates = {
        "gate/config.yaml" = {
          file = gateConfigYamlFile;
          owner = config.users.users.gate.name;
          group = config.users.users.gate.group;
          restartUnits = [ "gate.service" ];
        };
      };
    };
    networking.firewall.allowedTCPPorts = [ 25565 ];
  };
}
