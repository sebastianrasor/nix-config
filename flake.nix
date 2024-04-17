{
  description = "Sebastian's nix config";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    nixos-hardware.url = github:nixos/nixos-hardware;

    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hypr-contrib = {
      url = github:hyprwm/contrib;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprcursor = {
      url = github:hyprwm/hyprcursor;
      inputs.hyprlang.follows = "hyprlang";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    hypridle = {
      url = github:hyprwm/hypridle;
      inputs.hyprlang.follows = "hyprlang";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    hyprland = {
      url = github:hyprwm/hyprland;
      inputs.hyprcursor.follows = "hyprcursor";
      inputs.hyprlang.follows = "hyprlang";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.wlroots.follows = "wlroots";
      inputs.xdph.follows = "xdph";
    };

    hyprland-protocols = {
      url = github:hyprwm/hyprland-protocols;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    hyprlang = {
      url = github:hyprwm/hyprlang;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    hyprlock = {
      url = github:hyprwm/hyprlock;
      inputs.hyprlang.follows = "hyprlang";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    hyprpaper = {
      url = github:hyprwm/hyprpaper;
      inputs.hyprlang.follows = "hyprlang";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    hyprpicker = {
      url = github:hyprwm/hyprpicker;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xdph = {
      url = github:hyprwm/xdg-desktop-portal-hyprland;
      inputs.hyprlang.follows = "hyprlang";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    systems = {
      url = github:nix-systems/default;
    };

    wlroots = {
      type = "gitlab";
      host = "gitlab.freedesktop.org";
      owner = "wlroots";
      repo = "wlroots";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-hardware,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    homeManagerModules = import ./modules/home-manager;

    nixosConfigurations = {
      framework = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/framework/configuration.nix
          nixos-hardware.nixosModules.framework-11th-gen-intel
        ];
      };
    };

    homeConfigurations = {
      "sebastian@framework" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./${"sebastian@framework.nix"}
        ];
      };
    };
  };
}
