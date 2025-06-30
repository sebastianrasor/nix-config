{
  description = "Sebastian Rasor's Nix configurations";

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    lanzaboote,
    nixos-cosmic,
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
    nixosConfigurations = builtins.listToAttrs (
      map (
        nixosConfiguration:
          with nixpkgs.lib; {
            name = removeSuffix ".nix" nixosConfiguration;
            value = nixosSystem {
              specialArgs = {inherit inputs outputs;};
              modules =
                [
                  (./configurations + ("/" + nixosConfiguration))
                ]
                ++ attrsets.attrValues self.nixosModules;
            };
          }
      ) (builtins.attrNames (builtins.readDir ./configurations))
    );

    # import all Home Manager configurations from ./configurations/*/users/*/home.nix
    homeConfigurations = with nixpkgs.lib;
      concatMapAttrs
      (
        hostName: usernames:
          builtins.listToAttrs (
            map (username: {
              name = username + "@" + hostName;
              value = home-manager.lib.homeManagerConfiguration {
                pkgs = self.nixosConfigurations.${hostName}.pkgs;
                extraSpecialArgs = {inherit inputs outputs;};
                modules =
                  [
                    ./configurations/${hostName}/users/${username}/home.nix
                  ]
                  ++ attrsets.attrValues self.homeModules;
              };
            })
            usernames
          )
      )
      (
        mapAttrs' (
          hostName: _:
            nameValuePair hostName (attrNames (builtins.readDir ./configurations/${hostName}/users))
        ) (builtins.readDir ./configurations)
      );

    # import all NixOS modules from ./modules/nixos/*
    nixosModules = with nixpkgs.lib;
      attrsets.mapAttrs' (
        name: _: attrsets.nameValuePair (removeSuffix ".nix" name) (import (./modules/nixos + ("/" + name)))
      ) (builtins.readDir ./modules/nixos)
      // {
        flake-home-manager = home-manager.nixosModules.home-manager;
        flake-lanzaboote = lanzaboote.nixosModules.lanzaboote;
        flake-nixos-cosmic = nixos-cosmic.nixosModules.default;
        flake-sops-nix = sops-nix.nixosModules.sops;
        home-manager-extra = {
          home-manager = {
            extraSpecialArgs = {inherit inputs outputs;};
            sharedModules = attrsets.attrValues self.homeModules;
          };
        };
      };

    # import all Home Manager modules from ./modules/home-manager/*
    homeModules = with nixpkgs.lib;
      attrsets.mapAttrs' (
        name: _:
          attrsets.nameValuePair (removeSuffix ".nix" name) (import (./modules/home-manager + ("/" + name)))
      ) (builtins.readDir ./modules/home-manager);

    formatter = forAllSystems (pkgs: pkgs.alejandra);

    # create a simple development shell for working with Nix
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          alejandra
          fd
          nixd
          nixf
          sops
          stylua
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
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mysecrets = {
      url = "git+ssh://git@github.com/sebastianrasor/nix-secrets.git?ref=main&shallow=1";
      flake = false;
    };

    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
