{
  description = "Sebastian's nix config";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    nixos-hardware.url = github:nixos/nixos-hardware;

    home-manager.url = github:nix-community/home-manager;

    hypr-contrib.url = github:hyprwm/contrib;
    hypridle.url = github:hyprwm/hypridle;
    hyprlock.url = github:hyprwm/hyprlock;
    hyprpaper.url = github:hyprwm/hyprpaper;
    hyprpicker.url = github:hyprwm/hyprpicker;
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
