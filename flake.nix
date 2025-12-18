{
  description = "Sebastian Rasor's Nix configurations";

  outputs =
    inputs@{
      self,
      nixpkgs,
      authentik-nix,
      cachix-deploy-flake,
      cosmic-manager,
      disko,
      home-manager,
      impermanence,
      lanzaboote,
      nvf,
      sops-nix,
      ...
    }:
    let
      inherit (self) outputs;

      system = "x86_64-linux";

      pkgs = import nixpkgs { inherit system; };
    in
    {
      # import all NixOS configurations from ./configurations/*
      nixosConfigurations =
        with nixpkgs.lib;
        pipe ./configurations [
          builtins.readDir

          # { hostName = ... } -> { hostName = nixosConfiguration; }
          (mapAttrs' (
            hostName: _:
            nameValuePair hostName (nixosSystem {
              specialArgs = { inherit inputs outputs; };
              modules = [ ./configurations/${hostName} ] ++ attrsets.attrValues self.nixosModules;
            })
          ))
        ];

      # expose all NixOS configurations as Cachix Deploy agents
      packages.${system}.default =
        let
          cachix-deploy-lib = cachix-deploy-flake.lib pkgs;
        in
        cachix-deploy-lib.spec {
          agents = builtins.mapAttrs (
            _: nixosSystem: nixosSystem.config.system.build.toplevel
          ) self.nixosConfigurations;
        };

      # import all Home Manager configurations from ./configurations/*/users/*/home.nix
      homeConfigurations =
        with nixpkgs.lib;
        pipe ./configurations [
          builtins.readDir

          # { hostName = ... } -> { hostName = ["sebastian", ...]; }
          (mapAttrs' (
            hostName: _:
            nameValuePair hostName (
              pipe ./configurations/${hostName}/users [
                builtins.readDir
                builtins.attrNames
              ]
            )
          ))

          # { hostName = ["sebastian", ...]; } -> { "sebastian@hostName" = homeManagerConfiguration; ... }
          (concatMapAttrs (
            hostName: usernames:
            pipe usernames [
              (map (username: {
                name = "${username}@${hostName}";
                value = home-manager.lib.homeManagerConfiguration {
                  pkgs = self.nixosConfigurations.${hostName}.pkgs;
                  extraSpecialArgs = { inherit inputs outputs; };
                  modules = [
                    ./configurations/${hostName}/users/${username}/home.nix
                  ]
                  ++ attrsets.attrValues self.homeModules;
                };
              }))
              builtins.listToAttrs
            ]
          ))
        ];

      nixosModules =
        with nixpkgs.lib;
        mergeAttrsList [
          # ./modules/nixos/*
          (pipe ./modules/nixos [
            builtins.readDir
            (mapAttrs' (
              nixosModule: _:
              nameValuePair (removeSuffix ".nix" nixosModule) (import ./modules/nixos/${nixosModule})
            ))
          ])

          # ./modules/* (excluding nixos & home-manager)
          (pipe ./modules [
            builtins.readDir
            (filterAttrs (
              name: _:
              !(builtins.elem name [
                "nixos"
                "home-manager"
              ])
            ))
            (mapAttrs' (module: _: nameValuePair (removeSuffix ".nix" module) (import ./modules/${module})))
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
                extraSpecialArgs = { inherit inputs outputs; };
                sharedModules = attrsets.attrValues self.homeModules;
              };
            };
          }
        ];

      homeModules =
        with nixpkgs.lib;
        mergeAttrsList [
          # ./modules/home-manager/*
          (pipe ./modules/home-manager [
            builtins.readDir
            (mapAttrs' (
              homeModule: _:
              nameValuePair (removeSuffix ".nix" homeModule) (import ./modules/home-manager/${homeModule})
            ))
          ])

          # ./modules/* (excluding nixos & home-manager)
          (pipe ./modules [
            builtins.readDir
            (filterAttrs (
              name: _:
              !(builtins.elem name [
                "nixos"
                "home-manager"
              ])
            ))
            (mapAttrs' (module: _: nameValuePair (removeSuffix ".nix" module) (import ./modules/${module})))
          ])

          # flake modules
          {
            flake-cosmic-manager = cosmic-manager.homeManagerModules.cosmic-manager;
            flake-impermanence = impermanence.homeManagerModules.impermanence;
            flake-nvf = nvf.homeManagerModules.default;
          }
        ];

      formatter.${system} = pkgs.nixfmt-tree;

      # create a simple development shell for working with Nix
      devShells.${system}.default = pkgs.mkShellNoCC {
        nativeBuildInputs = with pkgs; [
          fd
          git
          nh
          nixd
          nixf
          nixfmt-rfc-style
        ];
        shellHook = ''
          export NH_FLAKE=".";
        '';
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
    };

    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";

    checkemail = {
      url = "github:sebastianrasor/checkemail";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence?ref=pull/272/head";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets.url = "git+ssh://git@github.com/sebastianrasor/nix-secrets.git?ref=main&shallow=1";

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
