{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.sebastianrasor.minecraft-server;
in {
  options = {
    sebastianrasor.minecraft-server = {
      enable = lib.mkEnableOption "Minecraft game server";

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
        type = lib.types.listOf (lib.types.submodule {
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
        });
        default = inputs.nix-secrets.minecraft.ops;
      };

      whitelist = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            uuid = lib.mkOption {
              type = lib.types.str;
            };
            name = lib.mkOption {
              type = lib.types.str;
            };
          };
        });
        default = inputs.nix-secrets.minecraft.whitelist;
      };

      serverProperties = lib.mkOption {
        default = {};
        type = lib.types.submodule {
          options = {
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
              # This isn't really very secret, but with the management server
              # only listening on localhost this shouldn't be a big deal.
              # Even taking this into consideration, this does lower overall
              # security. If, somehow, an attacker gained access to my server
              # for the sole purpose of giving themselves operator permission
              # on my Minecraft server, they could use this to do so if they
              # couldn't gain write access to /run/minecraft-server.stdin
              default = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
              type = lib.types.str;
            };
            management-server-tls-enabled = lib.mkOption {
              default = false;
              type = lib.types.bool;
            };
            pause-when-empty-seconds = lib.mkOption {
              default = -1;
              type = lib.types.int;
            };
            server-port = lib.mkOption {
              default = 25565;
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
          freeformType = lib.types.attrsOf (lib.types.oneOf [
            lib.types.bool
            lib.types.int
            lib.types.str
          ]);
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.minecraft = {
      description = "Minecraft game server service user";
      home = cfg.dir;
      createHome = true;
      isSystemUser = true;
      group = "minecraft";
    };
    users.groups.minecraft = {};

    environment.persistence."${config.sebastianrasor.persistence.storagePath}".directories = lib.mkIf config.sebastianrasor.persistence.enable [
      {
        directory = cfg.dir + "/world";
        user = config.users.users.minecraft.name;
        group = config.users.groups.minecraft.name;
        mode = "0700";
      }
    ];

    systemd.sockets.minecraft-server = {
      bindsTo = ["minecraft-server.service"];
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
      wantedBy = ["multi-user.target"];
      after = [
        "minecraft-server.socket"
        "network.target"
      ];
      requires = ["minecraft-server.socket"];
      description = "Minecraft game server";

      preStart = let
        javaProperties = pkgs.formats.javaProperties {};
        opsFile = pkgs.writeText "ops.json" (builtins.toJSON cfg.ops);
        whitelistFile = pkgs.writeText "whitelist.json" (builtins.toJSON cfg.whitelist);
        serverPropertiesFile = javaProperties.generate "server.properties" (javaProperties.type.merge null [{value = cfg.serverProperties;}]);
      in
        ''
          echo "eula = true" > eula.txt

          cp --dereference --remove-destination ${opsFile} ops.json
          chmod +w ops.json
          cp --dereference --remove-destination ${serverPropertiesFile} server.properties
          chmod +w server.properties

          ln -sf ${whitelistFile} whitelist.json

          rm -f mods/*
        ''
        + (lib.strings.concatMapStringsSep "\n" (x: "ln -sf ${x} mods/") [
          (pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/VSNURh3q/versions/eY3dbqLu/c2me-fabric-mc1.21.10-0.3.5.0.0.jar";
            sha512 = "a3422b75899a9355aa13128651ed2815ff83ff698c4c22a94ea7f275c656aff247440085a47de20353ff54469574c84adc9b428c2e963a80a3c6657fb849825d";
          })
          (pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/fALzjamp/versions/kkEljQ4R/Chunky-Fabric-1.4.51.jar";
            sha512 = "a9bf1e7ce7618acdf202eb93b14bd5f1e50a8fa09c6d2661711a22f8de501c89c7d480c264aa26ef8386c2dab2c88abe467a64e7fb662d3b0865c70e0f72b3e9";
          })
          (pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/lxeiLRwe/fabric-api-0.136.0%2B1.21.10.jar";
            sha512 = "d6ad5afeb57dc6dbe17a948990fc8441fbbc13a748814a71566404d919384df8bd7abebda52a58a41eb66370a86b8c4f910b64733b135946ecd47e53271310b5";
          })
          (pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/uXXizFIs/versions/CtMpt7Jr/ferritecore-8.0.0-fabric.jar";
            sha512 = "131b82d1d366f0966435bfcb38c362d604d68ecf30c106d31a6261bfc868ca3a82425bb3faebaa2e5ea17d8eed5c92843810eb2df4790f2f8b1e6c1bdc9b7745";
          })
          (pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/oGKQMdyZ/lithium-fabric-0.20.0%2Bmc1.21.10.jar";
            sha512 = "755c0e0fc7f6f38ac4d936cc6023d1dce6ecfd8d6bdc2c544c2a3c3d6d04f0d85db53722a089fa8be72ae32fc127e87f5946793ba6e8b4f2c2962ed30d333ed2";
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
            url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/BjR2lc4k/voicechat-fabric-1.21.10-2.6.6.jar";
            sha512 = "fc0b838a0906ddafeabf9db3b459d4226a2f06458443ee1dee44d937e5896f0d8d3e7c7bbc2a93ea74b4665f37249e7da719bbabf8449c756d2a49116be61197";
          })
          (pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/l6YH9Als/versions/eqIoLvsF/spark-1.10.152-fabric.jar";
            sha512 = "f99295f91e4bdb8756547f52e8f45b1649d08ad18bc7057bb68beef8137fea1633123d252cfd76a177be394a97fc1278fe85df729d827738d8c61f341604d679";
          })
        ]);

      environment = {
        LD_LIBRARY_PATH = lib.makeLibraryPath [pkgs.udev];
      };

      serviceConfig = {
        ExecStart = let
          fabricServer = pkgs.fetchurl {
            url = "https://meta.fabricmc.net/v2/versions/loader/1.21.10/0.18.0/1.1.0/server/jar";
            sha256 = "0k0y4c812j37g3d946w42q0xy7wvzahy3xk7r4mkx34ikajx9shm";
          };
        in "${lib.getExe' pkgs.temurin-jre-bin "java"} ${cfg.jvmOpts} -jar ${fabricServer} nogui";
        ExecStop = let
          stopScript = pkgs.writeShellScript "minecraft-server-stop" ''
            echo stop > ${config.systemd.sockets.minecraft-server.socketConfig.ListenFIFO}

            tail --pid="$1" -f /dev/null
          '';
        in "${stopScript} $MAINPID";

        Restart = "always";
        User = config.users.users.minecraft.name;
        WorkingDirectory = cfg.dir;

        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        # Hardening
        CapabilityBoundingSet = [""];
        DeviceAllow = [""];
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
  };
}
