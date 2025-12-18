{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.minecraft-server;
  secretsEnabled = config.sebastianrasor.secrets.enable;

  fabricServer = pkgs.fetchurl {
    url = "https://meta.fabricmc.net/v2/versions/loader/1.21.10/0.18.0/1.1.0/server/jar";
    sha256 = "0k0y4c812j37g3d946w42q0xy7wvzahy3xk7r4mkx34ikajx9shm";
  };

  javaProperties = pkgs.formats.javaProperties { };
  serverPropertiesFile = javaProperties.generate "server.properties" (
    javaProperties.type.merge null [ { value = cfg.serverProperties; } ]
  );
  opsFile = pkgs.writeText "ops.json" (builtins.toJSON cfg.ops);
  whitelistFile = pkgs.writeText "whitelist.json" (builtins.toJSON cfg.whitelist);

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
    hackOnlineMode = false;
    hackEarlySend = true;
    hackMessageChain = false;
    disconnectMessage = "This server requires you connect at the following server IP mc.${config.sebastianrasor.domain}";
    secret = if secretsEnabled then config.sops.placeholder."minecraft/velocity-secret" else null;
  };

  stopScript = pkgs.writeShellScript "minecraft-server-stop" ''
    echo stop > ${config.systemd.sockets.minecraft-server.socketConfig.ListenFIFO}

    tail --pid="$1" -f /dev/null
  '';
in
{
  options.sebastianrasor.minecraft-server = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    dir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/minecraft";
      description = "Storage directory for all Minecraft game server files";
    };

    jvmOpts = lib.mkOption {
      type = lib.types.str;
      default = "-Xmx24G -Xms24G";
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

    whitelist = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            uuid = lib.mkOption {
              type = lib.types.str;
            };
            name = lib.mkOption {
              type = lib.types.str;
            };
          };
        }
      );
      default = inputs.nix-secrets.minecraft.whitelist;
    };

    serverProperties = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        options = {
          enable-rcon = lib.mkOption {
            default = true;
            type = lib.types.bool;
          };
          difficulty = lib.mkOption {
            default = "hard";
            type = lib.types.str;
          };
          management-server-enabled = lib.mkOption {
            default = true;
            type = lib.types.bool;
          };
          management-server-host = lib.mkOption {
            default = "localhost";
            type = lib.types.str;
          };
          management-server-port = lib.mkOption {
            default = 25585;
            type = lib.types.port;
          };
          management-server-secret = lib.mkOption {
            default =
              if secretsEnabled then config.sops.placeholder."minecraft/management-server-secret" else null;
            type = lib.types.str;
          };
          management-server-tls-enabled = lib.mkOption {
            default = false;
            type = lib.types.bool;
          };
          online-mode = lib.mkOption {
            default = false;
            type = lib.types.bool;
          };
          pause-when-empty-seconds = lib.mkOption {
            default = -1;
            type = lib.types.int;
          };
          "rcon.password" = lib.mkOption {
            default = if secretsEnabled then config.sops.placeholder."minecraft/rcon-password" else null;
            type = lib.types.str;
          };
          "rcon.port" = lib.mkOption {
            default = 25575;
            type = lib.types.port;
          };
          server-port = lib.mkOption {
            default = 25555;
            type = lib.types.port;
          };
          simulation-distance = lib.mkOption {
            default = 12;
            type = lib.types.int;
          };
          spawn-protection = lib.mkOption {
            default = 0;
            type = lib.types.int;
          };
          view-distance = lib.mkOption {
            default = 32;
            type = lib.types.int;
          };
          white-list = lib.mkOption {
            default = true;
            type = lib.types.bool;
          };
        };
        freeformType = lib.types.attrsOf (
          lib.types.oneOf [
            lib.types.bool
            lib.types.int
            lib.types.str
          ]
        );
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.mkIf secretsEnabled [
      (pkgs.symlinkJoin {
        name = "mcrcon";
        paths = [
          (pkgs.writeShellScriptBin "mcrcon" ''
            export MCRCON_PASS="$(cat ${config.sops.secrets."minecraft/rcon-password".path})"
            exec ${lib.getExe' pkgs.mcrcon "mcrcon"}
          '')
          pkgs.mcrcon
        ];
      })
    ];

    sops = lib.mkIf secretsEnabled {
      secrets = {
        "minecraft/management-server-secret" = {
          owner = config.users.users.minecraft.name;
          group = config.users.users.minecraft.group;
        };
        "minecraft/rcon-password" = {
          owner = config.users.users.minecraft.name;
          group = config.users.users.minecraft.group;
          mode = "0660";
        };
        "minecraft/luckperms-postgres-password" = {
          owner = config.users.users.minecraft.name;
          group = config.users.users.minecraft.group;
        };
        "minecraft/velocity-secret" = {
          owner = config.users.users.minecraft.name;
          group = config.users.users.minecraft.group;
        };
      };
      templates = {
        "minecraft/server.properties" = {
          file = serverPropertiesFile;
          owner = config.users.users.minecraft.name;
          group = config.users.users.minecraft.group;
        };
        "minecraft/luckperms.conf" = {
          file = luckPermsConfFile;
          owner = config.users.users.minecraft.name;
          group = config.users.users.minecraft.group;
        };
        "minecraft/FabricProxy-Lite.toml" = {
          file = fabricProxyLiteTomlFile;
          owner = config.users.users.minecraft.name;
          group = config.users.users.minecraft.group;
        };
      };
    };

    users.users.minecraft = {
      description = "Minecraft game server service user";
      home = cfg.dir;
      createHome = true;
      isSystemUser = true;
      group = "minecraft";
    };
    users.groups.minecraft = { };

    systemd.sockets.minecraft-server = {
      bindsTo = [ "minecraft-server.service" ];
      socketConfig = {
        ListenFIFO = "/run/minecraft-server.stdin";
        SocketMode = "0660";
        SocketUser = config.users.users.minecraft.name;
        SocketGroup = config.users.groups.minecraft.name;
        RemoveOnStop = true;
        FlushPending = true;
      };
    };

    systemd.services.minecraft-server = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "minecraft-server.socket"
        "network.target"
      ];
      requires = [ "minecraft-server.socket" ];
      description = "Minecraft game server";

      preStart = ''
        echo "eula = true" > eula.txt

        cp --dereference --remove-destination ${opsFile} ops.json
        chmod +w ops.json
        cp --dereference --remove-destination ${
          if secretsEnabled then
            config.sops.templates."minecraft/server.properties".path
          else
            serverPropertiesFile
        } server.properties
        chmod +w server.properties

        ln -sf ${whitelistFile} whitelist.json

        mkdir -p config/luckperms
        ln -sf ${
          if secretsEnabled then config.sops.templates."minecraft/luckperms.conf".path else luckPermsConfFile
        } config/luckperms/luckperms.conf

        ln -sf ${
          if secretsEnabled then
            config.sops.templates."minecraft/FabricProxy-Lite.toml".path
          else
            fabricProxyLiteTomlFile
        } config/FabricProxy-Lite.toml

        rm -rf mods
        mkdir mods
      ''
      + (lib.strings.concatMapStringsSep "\n" (x: "ln -sf ${x} mods/") [
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/sml2FMaA/versions/EHGIPeW9/antixray-fabric-1.4.10%2B1.21.9.jar";
          sha512 = "7ee0c66cf6214e8cd17f5dee892a5abf7bf0571bc09b9609cfb4e56b38db2978f6cc6fee1ab27102cba929c8404a7a12857d4d442ab26f8228d30ea856fc57e9";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/8sbiz1lS/appleskin-fabric-mc1.21.9-3.0.7.jar";
          sha512 = "224a3qhcq3a5z5cd3q8pcxlhzi81c89k51xxdbqifjrscmdc72hwrkiw5s9253vck58bd5y903ccis1amqwvcblryvwsh4il2sd1l3r";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/VSNURh3q/versions/eY3dbqLu/c2me-fabric-mc1.21.10-0.3.5.0.0.jar";
          sha512 = "a3422b75899a9355aa13128651ed2815ff83ff698c4c22a94ea7f275c656aff247440085a47de20353ff54469574c84adc9b428c2e963a80a3c6657fb849825d";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/lxeiLRwe/fabric-api-0.136.0%2B1.21.10.jar";
          sha512 = "d6ad5afeb57dc6dbe17a948990fc8441fbbc13a748814a71566404d919384df8bd7abebda52a58a41eb66370a86b8c4f910b64733b135946ecd47e53271310b5";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/LcgnDDmT/fabric-language-kotlin-1.13.7%2Bkotlin.2.2.21.jar";
          sha512 = "0453a8a4eb8d791b5f0097a6628fae6f13b6dfba1e2bd1f91218769123808c4396a88bcdfc785f1d6bca348f267b32afc2aa9e0d5ec93a7b35bcfe295268c7bc";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/nR8AIdvx/FabricProxy-Lite-2.11.0.jar";
          sha512 = "c2e1d9279f6f19a561f934b846540b28a033586b4b419b9c1aa27ac43ffc8fad2ce60e212a15406e5fa3907ff5ecbe5af7a5edb183a9ee6737a41e464aec1375";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/uXXizFIs/versions/CtMpt7Jr/ferritecore-8.0.0-fabric.jar";
          sha512 = "131b82d1d366f0966435bfcb38c362d604d68ecf30c106d31a6261bfc868ca3a82425bb3faebaa2e5ea17d8eed5c92843810eb2df4790f2f8b1e6c1bdc9b7745";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/nvQzSEkH/versions/qC0qUqL5/Jade-1.21.9-Fabric-20.0.5.jar";
          sha512 = "1ds04prwkdflrbf0plxqb1k4r9dg4da7mrsz331cnr10yks7d1d2qz6x6ia9jv2dalbj908hbp1g3d1dfvcyrxnbmqwzar6c4zswfa0";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/LVN9ygNV/versions/O4Rna8OX/ledger-1.3.16.jar";
          sha512 = "1ki6dx21za3232l5kfyz8ichgsvawi1zkk05vfjivhjqmp3i939brq7q597pkwabslc8h31ndxm2961sisjdy5wm8873r4213mb7z8y";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/oGKQMdyZ/lithium-fabric-0.20.0%2Bmc1.21.10.jar";
          sha512 = "755c0e0fc7f6f38ac4d936cc6023d1dce6ecfd8d6bdc2c544c2a3c3d6d04f0d85db53722a089fa8be72ae32fc127e87f5946793ba6e8b4f2c2962ed30d333ed2";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/Vebnzrzj/versions/rGOrpVtr/LuckPerms-Fabric-5.5.17.jar";
          sha512 = "05ybs3ydwn2550ivdr134dnqy35ahlccnds13ydcnhhc2a2cqb1prpx3ak2p5fn7359g2plsdniv4jpqlwx58paigiy2fyas9hx20xc";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/qQyHxfxd/versions/78RjC1gi/NoChatReports-FABRIC-1.21.10-v2.16.0.jar";
          sha512 = "39b2f284f73f8290012b8b9cc70085d59668547fc7b4ec43ab34e4bca6b39a6691fbe32bc3326e40353ba9c16a06320e52818315be77799a5aad526370cbc773";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/Ps1zyz6x/versions/PV9KcrYQ/ScalableLux-0.1.6%2Bfabric.c25518a-all.jar";
          sha512 = "729515c1e75cf8d9cd704f12b3487ddb9664cf9928e7b85b12289c8fbbc7ed82d0211e1851375cbd5b385820b4fedbc3f617038fff5e30b302047b0937042ae7";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/l6YH9Als/versions/eqIoLvsF/spark-1.10.152-fabric.jar";
          sha512 = "f99295f91e4bdb8756547f52e8f45b1649d08ad18bc7057bb68beef8137fea1633123d252cfd76a177be394a97fc1278fe85df729d827738d8c61f341604d679";
        })
        (pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/fdZkP5Bb/versions/QYU98Z30/vanilla-permissions-0.3.1%2B1.21.9-rc1.jar";
          sha512 = "4d7cadaec12dfb3678d2957d91a3dcf6160c25defe7fb1a0412359f5669b5f6ead825d1dfc2e642ae77ff034b2a61e6c2f12b4b9ddd8389366ba6acf8b005444";
        })
      ]);

      environment = {
        LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.udev ];
      };

      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.javaPackages.compiler.temurin-bin.jre-25 "java"} ${cfg.jvmOpts} -jar ${fabricServer} nogui";
        ExecStop = "${stopScript} $MAINPID";

        Restart = "always";
        User = config.users.users.minecraft.name;
        WorkingDirectory = cfg.dir;

        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        # Hardening
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };

    sebastianrasor.persistence.directories = [
      {
        directory = cfg.dir + "/world";
        user = config.users.users.minecraft.name;
        group = config.users.groups.minecraft.name;
        mode = "0700";
      }
    ];
  };
}
