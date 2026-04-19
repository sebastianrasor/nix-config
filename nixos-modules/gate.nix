{ self, ... }:
{
  config,
  constants,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.gate;
  carbonMinecraftServerPort =
    self.nixosConfigurations.carbon.config.services.minecraft-server.serverProperties.server-port;

  startScript = pkgs.writeShellApplication {
    name = "minecraft-world-backup";
    runtimeInputs = with pkgs; [
      gate
      javaPackages.compiler.temurin-bin.jre-25
    ];
    text = "gate --no-auto-reload -c ${config.sops.templates."gate/config.yaml".path}";
  };

  favicon = pkgs.stdenvNoCC.mkDerivation {
    name = "server-icon.png";

    src = pkgs.fetchzip {
      url = "https://resources.download.minecraft.net/a9/a9945dba2bc4d4841c0dae23faaa8be9bd9e56f1";
      extension = "zip";
      sha256 = "07n36y9a2gb9kps29s8gf0aviq6ryx17nlbmzffjhpy73qsjv7ik";
      stripRoot = false;
    };

    buildInputs = with pkgs; [
      imagemagick
    ];

    buildPhase = ''
      runHook preBuild

      magick assets/minecraft/textures/item/diamond.png -sample 64x64 server-icon.png

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp server-icon.png $out

      runHook postInstall
    '';
  };
in
{
  options.sebastianrasor.gate = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.gate = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      description = "High performant & paralleled Minecraft proxy server";

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
    sops = {
      secrets."minecraft/velocitySecret" = {
        owner = lib.mkDefault config.users.users.gate.name;
        group = lib.mkDefault config.users.users.gate.group;
      };
      templates."gate/config.yaml" = {
        inherit (config.users.users.gate) group;
        owner = config.users.users.gate.name;
        restartUnits = [ "gate.service" ];
        content = ''
          config:
            bind: 0.0.0.0:25565
            servers:
              carbon: carbon.ts.${constants.domain}:${toString carbonMinecraftServerPort}
            status:
              motd: A Minecraft Server
              showMaxPlayers: 20
              favicon: ${favicon}
            builtinCommands: false
            forceKeyAuthentication: true
            forwarding:
              mode: velocity
              velocitySecret: ${config.sops.placeholder."minecraft/velocitySecret"}
            forcedHosts:
              "mine.diamonds": ["carbon"]
              "mc.ts.rasor.us": ["carbon"]
        '';
      };
    };
    networking.firewall.allowedTCPPorts = [ 25565 ];
  };
}
