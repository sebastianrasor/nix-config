{ self, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.minecraft-server;

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
    self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.fabricmcServers.fabricmc-server-26_2.override
      {
        fabricMods = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.server-mods
          self.packages.${pkgs.stdenv.hostPlatform.system}.secureseed-reborn

          (pkgs.fetchMavenArtifact {
            groupId = "net.fabricmc.fabric-api";
            artifactId = "fabric-api";
            version = "0.155.2+26.2";
            repos = [ "https://maven.fabricmc.net/" ];
            sha256 = "sha256-1lGMdwAky+ilViSPFvzbuRxqYvUCJ6bDuugZBRHiwbg=";
          })
          (pkgs.fetchMavenArtifact {
            groupId = "net.fabricmc";
            artifactId = "fabric-language-kotlin";
            version = "1.13.13+kotlin.2.4.10";
            repos = [ "https://maven.fabricmc.net/" ];
            sha256 = "sha256-NMzazxO7k1H+Q85hkSwuCbcjZOQ+eH02uj0tBN7HWlI=";
          })

          (modrinthMod {
            project = "anti-xray";
            version = "fabric-1.4.16+26.1";
            sha256 = "sha256-+2NLYG0SN4ZjM3heAmUiaVLIx6ueGAcRWnTHB3OT5gM=";
          })
          (modrinthMod {
            project = "appleskin";
            version = "3.0.10+mc26.2";
            sha256 = "sha256-A9B9tH0h/BSNLDNIqcLyzzhdIW7zQnb3erv87ToY418=";
          })
          (modrinthMod {
            project = "c2me-fabric";
            version = "0.4.1-beta.1.0+26.2";
            sha256 = "sha256-qqLRxUEm3gc99UE+j/4ynQzV1nw8T+FkcDLClNDkb7A=";
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
            version = "26.2.8+fabric";
            sha256 = "sha256-nWqT6b62c5kll/A5sVOllkYH13gSUES3GwVf8gJOq/g=";
          })
          (modrinthMod {
            project = "ledger";
            version = "1.3.23";
            sha256 = "sha256-vQ4e7ew8HKZapriYtupJKbaNnGn/VbtVlwRZ/vVUL8s=";
          })
          (modrinthMod {
            project = "lithium";
            version = "mc26.2-0.25.2-fabric";
            sha256 = "sha256-dYjUp2mJSY9W4R5jorEXD/9Hbo2cSqyU4xCz59tGng8=";
          })
          (modrinthMod {
            project = "luckperms";
            version = "v5.5.57-fabric";
            sha256 = "sha256-uiUkirieleg6rIRaleQvPodD1YvVt33O1Q0elEpaZYw=";
          })
          (modrinthMod {
            project = "scalablelux";
            version = "0.2.1+fabric.2b08348";
            sha256 = "sha256-uMKAfsGsPn6H/z3Cws/YOru10oOzWooctxo02W8WILo=";
          })
          (modrinthMod {
            project = "spark";
            version = "1.10.173-fabric";
            sha256 = "sha256-B27SKI2yoFym6AYWFeGjHRkSzxsQZl5PCaF5TV25lDM=";
          })
        ];
      };

  opsFile = pkgs.writeText "ops.json" (builtins.toJSON cfg.ops);
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
      default = [
        {
          uuid = "e4722f02-7b74-434c-912b-ec7805ace63c";
          name = "sebastianrasor";
          level = 4;
          bypassesPlayerLimit = true;
        }
      ];
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

      if [ -d mods/ ]; then
        ${lib.getExe pkgs.fd} . 'mods/' -e jar -X rm
      fi

      mkdir -p config/luckperms
      ln -sf ${config.sops.templates."minecraft/luckperms.conf".path} config/luckperms/luckperms.conf

      ln -sf ${config.sops.templates."minecraft/FabricProxy-Lite.toml".path} config/FabricProxy-Lite.toml
    '';

    sops = {
      secrets = {
        "postgres/databasePasswords/minecraft_luckperms" = {
          inherit (config.users.users.minecraft) group;
          owner = config.users.users.minecraft.name;
        };
        "minecraft/velocitySecret" = {
          inherit (config.users.users.minecraft) group;
          owner = config.users.users.minecraft.name;
        };
      };
      templates = {
        "minecraft/luckperms.conf" = {
          inherit (config.users.users.minecraft) group;
          owner = config.users.users.minecraft.name;
          content = ''
            storage-method: postgresql
            data: {
              address: "localhost"
              database: "minecraft_luckperms"
              username: "minecraft_luckperms"
              password: ${config.sops.placeholder."postgres/databasePasswords/minecraft_luckperms"}
            }
          '';
        };
        "minecraft/FabricProxy-Lite.toml" = {
          inherit (config.users.users.minecraft) group;
          owner = config.users.users.minecraft.name;
          content = ''
            disconnectMessage = "You did not connect using the proper IP address."
            hackEarlySend = true
            secret = "${config.sops.placeholder."minecraft/velocitySecret"}"
          '';
        };
      };
    };

    sebastianrasor.persistence.directories = [
      {
        directory = config.services.minecraft-server.dataDir;
        user = config.users.users.minecraft.name;
        group = config.users.groups.minecraft.name;
        mode = "0700";
      }
    ];

  };
}
