{
  description = "Sebastian Rasor's Nix configurations";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      constants = import ./constants.nix;
      supportedSystems = [
        "x86_64-linux"
      ];
      eachSupportedSystem = nixpkgs.lib.genAttrs supportedSystems;
      forAllSystems =
        f:
        eachSupportedSystem (
          system:
          f (
            import nixpkgs {
              inherit system;
              config = constants.nixConfig;
              overlays = builtins.attrValues self.overlays;
            }
          )
        );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = import ./shell.nix { inherit pkgs; };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      homeModules = import ./home-modules self;

      hydraJobs = {
        inherit (self) packages;
        legacyPackages =
          (nixpkgs.lib.filterAttrsRecursive (
            n: _: n != "recurseForDerivations" && n != "overrideDerivation" && n != "override"
          ))
            self.legacyPackages;
        nixosConfigurations = builtins.mapAttrs (
          _: n: n.config.system.build.toplevel
        ) self.nixosConfigurations;
      };

      legacyPackages = forAllSystems (pkgs: pkgs.callPackages ./legacy-packages { });

      nixosConfigurations = import ./nixos-configurations self;

      nixosModules = import ./nixos-modules self;

      overlays = import ./overlays self;

      packages = forAllSystems (pkgs: import ./packages pkgs);
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

    impermanence.url = "github:nix-community/impermanence";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets.url = "git+ssh://git@github.com/sebastianrasor/nix-secrets.git?ref=main&shallow=1";

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    server-mods.url = "git+ssh://git@github.com/sebastianrasor/server-mods.git?ref=main&shallow=1";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tailscale-golink = {
      url = "github:tailscale/golink";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yubikey-touch-detector = {
      url = "github:maximbaz/yubikey-touch-detector";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
