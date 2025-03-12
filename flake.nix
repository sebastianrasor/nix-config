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
      # import all NixOS configurations from ./configurations/*
      nixosConfigurations = builtins.listToAttrs (
        map (
          nixosConfiguration: with pkgs.lib; {
            name = removeSuffix ".nix" nixosConfiguration;
            value = nixpkgs.lib.nixosSystem {
              specialArgs = inputs // {
                inherit inputs;
              };
              modules = [
                (./configurations + ("/" + nixosConfiguration))
              ] ++ attrsets.attrValues self.nixosModules;
            };
          }
        ) (builtins.attrNames (builtins.readDir ./configurations))
      );

      # import all Home Manager configurations from ./configurations/*/users/*/home.nix
      homeConfigurations =
        with pkgs.lib;
        concatMapAttrs
          (
            hostName: usernames:
            builtins.listToAttrs (
              map (username: {
                name = username + "@" + hostName;
                value = home-manager.lib.homeManagerConfiguration {
                  inherit pkgs;
                  extraSpecialArgs = inputs // {
                    inherit inputs;
                  };
                  modules = [
                    ./configurations/${hostName}/users/${username}/home.nix
                  ] ++ attrsets.attrValues self.homeModules;
                };
              }) usernames
            )
          )
          (
            mapAttrs' (
              hostName: _:
              nameValuePair hostName (attrNames (builtins.readDir ./configurations/${hostName}/users))
            ) (builtins.readDir ./configurations)
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
          stylua
        ];
      };
    };
}
