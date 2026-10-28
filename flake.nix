{
  description = "Sebastian Rasor's Nix configurations";

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      constants = import ./constants.nix;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      pkgsFor = nixpkgs.lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          config = constants.nixConfig;
          overlays = builtins.attrValues self.overlays;
        }
      );
      inputsWithConstants = inputs // {
        inherit constants pkgsFor;
      };
      forAllSystems = f: nixpkgs.lib.mapAttrs (_: f) pkgsFor;
    in
    {
      buildbotJobs = import ./buildbot-jobs.nix inputsWithConstants;

      devShells = forAllSystems (pkgs: import ./devshells.nix pkgs);

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      herculesCI = import ./hercules-ci.nix inputsWithConstants;

      hjemConfigurations = import ./hjem-configurations inputsWithConstants;

      hjemModules = import ./hjem-modules inputsWithConstants;

      nixosConfigurations = import ./nixos-configurations inputsWithConstants;

      nixosModules = import ./nixos-modules inputsWithConstants;

      overlays = import ./overlays inputs;

      packages = forAllSystems (pkgs: import ./packages pkgs);
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # TODO(sebastianrasor): Go back to main when this PR is merged
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/pull/1994/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "hercules-ci-effects/flake-parts";
        flake-compat.follows = "";
      };
    };

    crane.url = "github:ipetkov/crane";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "";
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        crane.follows = "crane";
        pre-commit.follows = "";
      };
    };

    nixbot = {
      url = "github:Mic92/nixbot";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
