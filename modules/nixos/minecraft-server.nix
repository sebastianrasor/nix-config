{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.minecraft-server.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.minecraft-server.enable {
    nixpkgs.overlays = [inputs.nix-minecraft.overlay];
    environment.persistence."${config.sebastianrasor.persistence.storagePath}".directories = lib.mkIf config.sebastianrasor.persistence.enable ["/srv/minecraft"];
    # For Simple Voice Chat mod
    networking.firewall.allowedUDPPorts = [24454];
    services.minecraft-servers = {
      enable = true;
      eula = true;
      servers."mc.${config.sebastianrasor.domain}" = {
        enable = true;
        jvmOpts = "-Xmx24G -Xms24G";
        package = pkgs.fabricServers.fabric-1_21_10.override {
          jre_headless = pkgs.openjdk25_headless;
        };
        whitelist = {
          sebastianrasor = "e4722f02-7b74-434c-912b-ec7805ace63c";
        };
        operators = {
          sebastianrasor = "e4722f02-7b74-434c-912b-ec7805ace63c";
        };
        serverProperties = {
          difficulty = "hard";
          simulation-distance = 12;
          spawn-protection = 0;
          view-distance = 32;
          white-list = true;
        };
        symlinks.mods = pkgs.linkFarmFromDrvs "mods" (
          builtins.attrValues {
            C2ME = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/VSNURh3q/versions/eY3dbqLu/c2me-fabric-mc1.21.10-0.3.5.0.0.jar";
              sha512 = "a3422b75899a9355aa13128651ed2815ff83ff698c4c22a94ea7f275c656aff247440085a47de20353ff54469574c84adc9b428c2e963a80a3c6657fb849825d";
            };
            Chunky = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/fALzjamp/versions/kkEljQ4R/Chunky-Fabric-1.4.51.jar";
              sha512 = "a9bf1e7ce7618acdf202eb93b14bd5f1e50a8fa09c6d2661711a22f8de501c89c7d480c264aa26ef8386c2dab2c88abe467a64e7fb662d3b0865c70e0f72b3e9";
            };
            Fabric-API = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/lxeiLRwe/fabric-api-0.136.0%2B1.21.10.jar";
              sha512 = "d6ad5afeb57dc6dbe17a948990fc8441fbbc13a748814a71566404d919384df8bd7abebda52a58a41eb66370a86b8c4f910b64733b135946ecd47e53271310b5";
            };
            FerriteCore = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/uXXizFIs/versions/CtMpt7Jr/ferritecore-8.0.0-fabric.jar";
              sha512 = "131b82d1d366f0966435bfcb38c362d604d68ecf30c106d31a6261bfc868ca3a82425bb3faebaa2e5ea17d8eed5c92843810eb2df4790f2f8b1e6c1bdc9b7745";
            };
            Lithium = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/oGKQMdyZ/lithium-fabric-0.20.0%2Bmc1.21.10.jar";
              sha512 = "755c0e0fc7f6f38ac4d936cc6023d1dce6ecfd8d6bdc2c544c2a3c3d6d04f0d85db53722a089fa8be72ae32fc127e87f5946793ba6e8b4f2c2962ed30d333ed2";
            };
            NoChatReports = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/qQyHxfxd/versions/78RjC1gi/NoChatReports-FABRIC-1.21.10-v2.16.0.jar";
              sha512 = "39b2f284f73f8290012b8b9cc70085d59668547fc7b4ec43ab34e4bca6b39a6691fbe32bc3326e40353ba9c16a06320e52818315be77799a5aad526370cbc773";
            };
            ScalableLux = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/Ps1zyz6x/versions/PV9KcrYQ/ScalableLux-0.1.6%2Bfabric.c25518a-all.jar";
              sha512 = "729515c1e75cf8d9cd704f12b3487ddb9664cf9928e7b85b12289c8fbbc7ed82d0211e1851375cbd5b385820b4fedbc3f617038fff5e30b302047b0937042ae7";
            };
            SimpleVoiceChat = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/BjR2lc4k/voicechat-fabric-1.21.10-2.6.6.jar";
              sha512 = "fc0b838a0906ddafeabf9db3b459d4226a2f06458443ee1dee44d937e5896f0d8d3e7c7bbc2a93ea74b4665f37249e7da719bbabf8449c756d2a49116be61197";
            };
            Spark = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/l6YH9Als/versions/eqIoLvsF/spark-1.10.152-fabric.jar";
              sha512 = "f99295f91e4bdb8756547f52e8f45b1649d08ad18bc7057bb68beef8137fea1633123d252cfd76a177be394a97fc1278fe85df729d827738d8c61f341604d679";
            };
          }
        );
      };
    };
  };
}
