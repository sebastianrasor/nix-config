# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{
  description = "Sebastian Rasor's Nix configurations";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      nixpkgs,
      nixos-hardware,
      nixos-cosmic,
      home-manager,
      lanzaboote,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ];
      specialArgs = {
        inherit
          inputs
          outputs
          nixpkgs-stable
          nixpkgs-unstable
          nixpkgs
          nixos-hardware
          nixos-cosmic
          lanzaboote
          ;
      };
    in
    {
      common = builtins.listToAttrs (
        map (commonDir: {
          name = commonDir;
          value = builtins.listToAttrs (
            map
              (configModule: {
                name = builtins.replaceStrings [ ".nix" ] [ "" ] configModule;
                value = import ((./common + ("/" + commonDir)) + ("/" + configModule));
              })
              (
                builtins.filter (f: f != "default.nix") (
                  builtins.attrNames (builtins.readDir (./common + ("/" + commonDir)))
                )
              )
          );
        }) (builtins.attrNames (builtins.readDir ./common))
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              fd
              nixd
              nixf
              nixfmt-rfc-style
              reuse
            ];
          };
        }
      );

      nixosConfigurations = builtins.listToAttrs (
        map (hostModule: {
          name = hostModule;
          value = nixpkgs.lib.nixosSystem {
            inherit specialArgs;
            modules = [
              home-manager.nixosModules.home-manager
              {
                home-manager.extraSpecialArgs = specialArgs;
                home-manager.backupFileExtension = "bak";
              }
              (./hosts + ("/" + hostModule))
            ];
          };
        }) (builtins.attrNames (builtins.readDir ./hosts))
      );

      homeConfigurations = builtins.listToAttrs (
        map (userModule: {
          name = userModule;
          value = home-manager.lib.homeManagerConfiguration {
            extraSpecialArgs = specialArgs;
            modules = [ (./users + ("/" + userModule + "/home.nix")) ];
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
          };
        }) (builtins.attrNames (builtins.readDir ./users))
      );
    };
}
