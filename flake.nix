{
  description = "Sebastian Rasor's Nix configurations";

  outputs = inputs @ {
    self,
    nixpkgs,
    authentik-nix,
    deploy-rs,
    disko,
    home-manager,
    impermanence,
    lanzaboote,
    sops-nix,
    ...
  }: let
    inherit (self) outputs;

    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});
  in {
    # import all NixOS configurations from ./configurations/*
    nixosConfigurations = with nixpkgs.lib;
      pipe ./configurations [
        builtins.readDir

        # { hostName = ... } -> { hostName = nixosConfiguration; }
        (mapAttrs' (hostName: _:
          nameValuePair hostName (nixosSystem {
            specialArgs = {inherit inputs outputs;};
            modules =
              [./configurations/${hostName}]
              ++ attrsets.attrValues self.nixosModules;
          })))
      ];

    # import all Home Manager configurations from ./configurations/*/users/*/home.nix
    homeConfigurations = with nixpkgs.lib;
      pipe ./configurations [
        builtins.readDir

        # { hostName = ... } -> { hostName = ["sebastian", ...]; }
        (mapAttrs' (hostName: _:
          nameValuePair hostName (
            pipe ./configurations/${hostName}/users [
              builtins.readDir
              builtins.attrNames
            ]
          )))

        # { hostName = ["sebastian", ...]; } -> { "sebastian@hostName" = homeManagerConfiguration; ... }
        (concatMapAttrs (hostName: usernames:
          pipe usernames [
            (map (username: {
              name = "${username}@${hostName}";
              value = home-manager.lib.homeManagerConfiguration {
                pkgs = self.nixosConfigurations.${hostName}.pkgs;
                extraSpecialArgs = {inherit inputs outputs;};
                modules =
                  [./configurations/${hostName}/users/${username}/home.nix]
                  ++ attrsets.attrValues self.homeModules;
              };
            }))
            builtins.listToAttrs
          ]))
      ]; #

    nixosModules = with nixpkgs.lib;
      mergeAttrsList [
        # ./modules/nixos/*
        (pipe ./modules/nixos [
          builtins.readDir
          (mapAttrs' (nixosModule: _:
              nameValuePair (removeSuffix ".nix" nixosModule) (import ./modules/nixos/${nixosModule})))
        ])

        # ./modules/* (excluding nixos & home-manager)
        (pipe ./modules [
          builtins.readDir
          (filterAttrs (name: _: !(builtins.elem name ["nixos" "home-manager"])))
          (mapAttrs' (module: _:
              nameValuePair (removeSuffix ".nix" module) (import ./modules/${module})))
        ])

        # flake modules
        {
          flake-authentik-nix = authentik-nix.nixosModules.default;
          flake-disko = disko.nixosModules.disko;
          flake-home-manager = home-manager.nixosModules.home-manager;
          flake-impermanence = impermanence.nixosModules.impermanence;
          flake-lanzaboote = lanzaboote.nixosModules.lanzaboote;
          flake-sops-nix = sops-nix.nixosModules.sops;
          home-manager-extra = {
            home-manager = {
              extraSpecialArgs = {inherit inputs outputs;};
              sharedModules = attrsets.attrValues self.homeModules;
            };
          };
        }
      ];

    homeModules = with nixpkgs.lib;
      mergeAttrsList [
        # ./modules/home-manager/*
        (pipe ./modules/home-manager [
          builtins.readDir
          (mapAttrs' (homeModule: _:
              nameValuePair (removeSuffix ".nix" homeModule) (import ./modules/home-manager/${homeModule})))
        ])

        # ./modules/* (excluding nixos & home-manager)
        (pipe ./modules [
          builtins.readDir
          (filterAttrs (name: _: !(builtins.elem name ["nixos" "home-manager"])))
          (mapAttrs' (module: _:
              nameValuePair (removeSuffix ".nix" module) (import ./modules/${module})))
        ])
      ];

    formatter = forAllSystems (pkgs: pkgs.alejandra);

    # create a simple development shell for working with Nix
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          alejandra
          pkgs.deploy-rs
          fd
          nixd
          nixf
        ];
      };
    });

    packages = with nixpkgs.lib;
      forAllSystems (
        pkgs:
          attrsets.mapAttrs' (
            name: _:
              attrsets.nameValuePair
              (removeSuffix ".nix" name)
              (pkgs.callPackage (./packages + ("/" + name)) {inherit inputs outputs;})
          ) (builtins.readDir ./packages)
      );

    deploy = {
      sshUser = "sebastian";
      user = "root";
      fastConnection = true;
      nodes = {
        carbon = {
          remoteBuild = true;
          hostname = "carbon";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.carbon;
          };
        };
        nephele = {
          remoteBuild = false;
          hostname = "nephele";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nephele;
          };
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
    };

    checkemail = {
      url = "github:sebastianrasor/checkemail";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mysecrets = {
      url = "git+ssh://git@github.com/sebastianrasor/nix-secrets.git?ref=main&shallow=1";
      flake = false;
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yubikey-touch-detector = {
      url = "github:maximbaz/yubikey-touch-detector";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
