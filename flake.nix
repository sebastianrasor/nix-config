{
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

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      lanzaboote,
      nixos-cosmic,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # import all NixOS configurations from ./configurations/nixos/*
      nixosConfigurations = builtins.listToAttrs (
        map (
          nixosConfiguration: with pkgs.lib; {
            name = removeSuffix ".nix" nixosConfiguration;
            value = nixpkgs.lib.nixosSystem {
              specialArgs = inputs // {
                inherit inputs;
              };
              modules = [
                (./configurations/nixos + ("/" + nixosConfiguration))
              ] ++ attrsets.attrValues self.nixosModules;
            };
          }
        ) (builtins.attrNames (builtins.readDir ./configurations/nixos))
      );

      # import all Home Manager configurations from ./configurations/home-manager/*
      homeConfigurations = builtins.listToAttrs (
        map (
          homeConfiguration: with pkgs.lib; {
            name = removeSuffix ".nix" homeConfiguration;
            value = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                (./configurations/home-manager + ("/" + homeConfiguration))
              ] ++ attrsets.attrValues self.homeModules;
            };
          }
        ) (builtins.attrNames (builtins.readDir ./configurations/home-manager))
      );

      # import all NixOS modules from ./modules/nixos/*
      nixosModules =
        with pkgs.lib;
        attrsets.mapAttrs' (
          name: _: attrsets.nameValuePair (removeSuffix ".nix" name) (import (./modules/nixos + ("/" + name)))
        ) (builtins.readDir ./modules/nixos)
        // {
          flake-home-manager = home-manager.nixosModules.home-manager;
          flake-lanzaboote = lanzaboote.nixosModules.lanzaboote;
          flake-nixos-cosmic = nixos-cosmic.nixosModules.default;
          home-manager-extra = {
            home-manager = {
              extraSpecialArgs = inputs // {
                inherit inputs;
              };
              sharedModules = attrsets.attrValues self.homeModules;
            };
          };
        };

      # import all Home Manager modules from ./modules/home-manager/*
      homeModules =
        with pkgs.lib;
        attrsets.mapAttrs' (
          name: _:
          attrsets.nameValuePair (removeSuffix ".nix" name) (import (./modules/home-manager + ("/" + name)))
        ) (builtins.readDir ./modules/home-manager);

      # create a simple development shell for working with Nix
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          fd
          nixd
          nixfmt-rfc-style
          nixf
        ];
      };
    };
}
