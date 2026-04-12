{
  config,
  constants,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.minecraft-server;
  secretsEnabled = config.sebastianrasor.secrets.enable;

  modrinthMod =
    {
      project,
      version,
      sha256,
    }:
    pkgs.fetchMavenArtifact {
      inherit version sha256;
      artifactId = project;
      groupId = "maven.modrinth";
      repos = [ "https://api.modrinth.com/maven" ];
    };

  minecraftServer =
    outputs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.fabricmcServers.fabricmc-server-26_1_1.override
      {
        fabricMods = [
          inputs.server-mods.packages.${pkgs.stdenv.hostPlatform.system}.default
          outputs.packages.${pkgs.stdenv.hostPlatform.system}.secureseed-reborn

          (pkgs.fetchMavenArtifact {
            groupId = "net.fabricmc.fabric-api";
            artifactId = "fabric-api";
            version = "0.145.4+26.1.1";
            repos = [ "https://maven.fabricmc.net/" ];
            sha256 = "sha256-5PLLHYnvthiW60B8PAKkbUkx5arWQ1Di2LopgeP5Wnk=";
          })
          (pkgs.fetchMavenArtifact {
            groupId = "net.fabricmc";
            artifactId = "fabric-language-kotlin";
            version = "1.13.10+kotlin.2.3.20";
            repos = [ "https://maven.fabricmc.net/" ];
            sha256 = "sha256-8ojwJz+p1ZKweGn6K7173KJ0mYo4uH64SFwQlCCSHio=";
          })

          (modrinthMod {
            project = "anti-xray";
            version = "fabric-1.4.16+26.1";
            sha256 = "sha256-+2NLYG0SN4ZjM3heAmUiaVLIx6ueGAcRWnTHB3OT5gM=";
          })
          (modrinthMod {
            project = "appleskin";
            version = "3.0.9+mc26.1";
            sha256 = "sha256-Mr/h7T3qBoQllWjb8rb+Auk5vzmOVK84Mji7O4ysTaY=";
          })
          (modrinthMod {
            project = "c2me-fabric";
            version = "0.3.7+alpha.0.63+26.1.1";
            sha256 = "sha256-A9hd3Zt+cY5F4oOZjMmm/4zlimof0AKTJ+QHBYO0Gpw=";
          })
          (modrinthMod {
            project = "c2me-fabric";
            version = "0.3.7+alpha.0.63+26.1.1";
            sha256 = "sha256-A9hd3Zt+cY5F4oOZjMmm/4zlimof0AKTJ+QHBYO0Gpw=";
          })
          (modrinthMod {
            project = "fabricproxy-lite";
            version = "v2.12.0";
            sha256 = "sha256-3KDQVoWvqiXVVDcq0RjZC2sn+F3tk+bbC4XYIqopNCo=";
          })
          (modrinthMod {
            project = "ferrite-core";
            version = "9.0.0-fabric";
            sha256 = "sha256-ITlmxy7ZZ6zHOSvrKKhm+6MB/1a5l2wueAHC233mvyI=";
          })
          (modrinthMod {
            project = "jade";
            version = "26.0.8+fabric";
            sha256 = "sha256-Pc3R5eO4Jf+94mNMPtY/vvpbomp+S+qnAUAVbQk1r2Y=";
          })
          (modrinthMod {
            project = "ledger";
            version = "1.3.20";
            sha256 = "sha256-uAqoL1bpLTkNvF6qnhuwYqsenpcmA1AGhEPYNDSx9/8=";
          })
          (modrinthMod {
            project = "lithium";
            version = "mc26.1.1-0.23.0-fabric";
            sha256 = "sha256-xdvvGh9TNS0ifaYxesgYiiZY+4uByRZbOoRegQmMuvc=";
          })
          (modrinthMod {
            project = "luckperms";
            version = "v5.5.42-fabric";
            sha256 = "sha256-d1G9hD4UOwgeYHRNiGvVv0EczTvo3t8XgnaPvKIRXOw=";
          })
          (modrinthMod {
            project = "scalablelux";
            version = "0.2.0+fabric.2b63825";
            sha256 = "sha256-bamBsryRWGU1zjuw+kGXWonMRgO5w6EG0kMaIUF7HfA=";
          })
          (modrinthMod {
            project = "spark";
            version = "1.10.172-fabric";
            sha256 = "sha256-m++Dstsza1EwD2nfcw7ejGTEEHp5aKDAGylNLu8HWQw=";
          })
        ];
      };

  opsFile = pkgs.writeText "ops.json" (builtins.toJSON cfg.ops);

  hocon = pkgs.formats.hocon { };
  luckPermsConfFile = hocon.generate "luckperms.conf" {
    storage-method = "postgresql";
    data = {
      address = "localhost";
      database = "minecraft_luckperms";
      username = "minecraft_luckperms";
      password =
        if secretsEnabled then config.sops.placeholder."minecraft/luckperms-postgres-password" else null;
    };

  };

  toml = pkgs.formats.toml { };
  fabricProxyLiteTomlFile = toml.generate "FabricProxy-Lite.toml" {
    #hackOnlineMode = true;
    hackEarlySend = true;
    #hackMessageChain = true;
    disconnectMessage = "This server requires you connect at the following server IP mc.${constants.domain}";
    secret = if secretsEnabled then config.sops.placeholder."minecraft/velocity-secret" else null;
  };
in
{
  options.sebastianrasor.minecraft-server = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    ops = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            uuid = lib.mkOption {
              type = lib.types.str;
            };
            name = lib.mkOption {
              type = lib.types.str;
            };
            level = lib.mkOption {
              type = lib.types.int;
            };
            bypassesPlayerLimit = lib.mkOption {
              type = lib.types.bool;
            };
          };
        }
      );
      default = inputs.nix-secrets.minecraft.ops;
    };
  };

  config = lib.mkIf cfg.enable {
    services.minecraft-server = {
      enable = true;
      package = minecraftServer;
      eula = true;
      declarative = true;
      serverProperties = {
        hardcore = true;
        level-seed = "-9223372036049690939";
        server-port = 25555;
        spawn-protection = 200;
      };
    };

    systemd.services.minecraft-server.preStart = lib.optionalString config.services.minecraft-server.declarative ''
      cp --dereference --remove-destination ${opsFile} ops.json
      chmod 644 ops.json

      ${lib.getExe pkgs.fd} . 'mods/' -e jar -X rm

      mkdir -p config/luckperms
      ln -sf ${
        if secretsEnabled then config.sops.templates."minecraft/luckperms.conf".path else luckPermsConfFile
      } config/luckperms/luckperms.conf

      cp --dereference --remove-destination ${
        if secretsEnabled then
          config.sops.templates."minecraft/FabricProxy-Lite.toml".path
        else
          fabricProxyLiteTomlFile
      } config/FabricProxy-Lite.toml
    '';

    sops = lib.mkIf secretsEnabled {
      secrets = {
        "minecraft/luckperms-postgres-password" = {
          inherit (config.users.users.minecraft) group;
          owner = config.users.users.minecraft.name;
        };
        "minecraft/velocity-secret" = {
          inherit (config.users.users.minecraft) group;
          owner = config.users.users.minecraft.name;
        };
      };
      templates = {
        "minecraft/luckperms.conf" = {
          inherit (config.users.users.minecraft) group;
          file = luckPermsConfFile;
          owner = config.users.users.minecraft.name;
        };
        "minecraft/FabricProxy-Lite.toml" = {
          inherit (config.users.users.minecraft) group;
          file = fabricProxyLiteTomlFile;
          owner = config.users.users.minecraft.name;
        };
      };
    };

    sebastianrasor.persistence.directories = [
      {
        directory = config.services.minecraft-server.dataDir + "/world";
        user = config.users.users.minecraft.name;
        group = config.users.groups.minecraft.name;
        mode = "0700";
      }
    ];

  };
}
