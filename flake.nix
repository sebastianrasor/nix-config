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
      checks =
        let
          packages = eachSupportedSystem (
            system: nixpkgs.lib.mapAttrs' (n: nixpkgs.lib.nameValuePair "package-${n}") self.packages.${system}
          );
          legacyPackages =
            let
              lib = nixpkgs.lib;
              nameValuePair = path: value: {
                inherit value;
                name = "legacyPackage-${lib.last path}";
              };
              recurseForDerivations =
                _: value: (builtins.isAttrs value && value ? recurseForDerivations && value.recurseForDerivations);
              optionalDerivation = path: value: lib.optional (lib.isDerivation value) (nameValuePair path value);
            in
            eachSupportedSystem (
              system:
              # Shamelessly stolen from here:
              # https://github.com/liquidnya/infrastructure/blob/7441244acb50625da2d9221308bf1ce0581197ec/packages/default.nix#L9-L24
              nixpkgs.lib.pipe self.legacyPackages.${system} [
                (nixpkgs.lib.mapAttrsToListRecursiveCond recurseForDerivations optionalDerivation)
                (nixpkgs.lib.concatMap nixpkgs.lib.id)
                builtins.listToAttrs
              ]
            );
          checks = {
            x86_64-linux = nixpkgs.lib.mapAttrs' (
              name: value:
              nixpkgs.lib.nameValuePair "nixosConfiguration-${name}" value.config.system.build.toplevel
            ) self.nixosConfigurations;
          };
        in
        builtins.foldl' nixpkgs.lib.recursiveUpdate { } [
          checks
          legacyPackages
          packages
        ];

      herculesCI = self.inputs.hercules-ci-effects.lib.mkHerculesCI { inherit inputs; } {
        herculesCI = herculesCI: {
          onPush.default.outputs.effects =
            let
              pkgs = import nixpkgs { system = "x86_64-linux"; };
              hci-effects = self.inputs.hercules-ci-effects.lib.withPkgs pkgs;
            in
            nixpkgs.lib.pipe self.nixosConfigurations [
              builtins.attrValues
              (map (
                nixosConfiguration:
                let
                  hostName = nixosConfiguration.config.networking.hostName;
                in
                {
                  name = "deploy-${hostName}";
                  value = hci-effects.runIf (herculesCI.config.repo.branch == "main") (
                    hci-effects.mkEffect {
                      inputs = with pkgs; [
                        openssh
                      ];
                      effectScript = ''
                        writeSSHKey ssh
                        # todo: move this into the configuration itself somehow
                        cat >~/.ssh/known_hosts <<EOF
                        azalea.ts.${constants.domain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO5pVGXbupdNG/9acDwOd6loG8CBBaNsreyoYCY4at9J
                        carbon.ts.${constants.domain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAGdZ/fyPx7w2GsbE337H0kNst+GWL/gN4piJizkWj/9
                        nephele.ts.${constants.domain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIISaqWRMez2mFczqhMmiYe0KzNeENKsqEQw/AsOC+Ay+
                        sunflower.ts.${constants.domain} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII85WkAO+BoPgHC8Vj7Y3ab3aOOLDx9e8jul4rBLAXiM
                        EOF

                        if ! ssh -o ConnectTimeout=30 "sunflower.ts.rasor.us" "systemctl start nixos-upgrade.service"; then
                          exit "''${?/255/0}"
                        fi

                        exit 0
                      '';
                    }
                  );
                }
              ))
              builtins.listToAttrs
            ];
        };
      };

      devShells = forAllSystems (pkgs: {
        default = import ./shell.nix { inherit pkgs; };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      homeModules = import ./home-modules self;

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

    buildbot-nix = {
      url = "github:nix-community/buildbot-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    checkemail = {
      url = "github:sebastianrasor/checkemail";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comin = {
      url = "github:nlewo/comin";
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

    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
