# nix-config

This is my collection of NixOS and Home Manager configurations and modules, with
an attempt to do everything in an idiomatic way.

## Structure

```
.
├── modules
│   ├── nixos
│   │   ├── nixos-module-1
│   │   │   ├── default.nix
│   │   │   └── ...
│   │   ├── nixos-module-2.nix
│   │   └── ...
│   ├── home-manager
│   │   ├── hm-module-1
│   │   │   ├── default.nix
│   │   │   └── ...
│   │   ├── hm-module-2.nix
│   │   └── ...
│   ├── global-module-1
│   │   ├── default.nix
│   │   └── ...
│   ├── global-module-2.nix
│   └── ...
├── nixos-configurations
│   ├── nixos-host-1
│   │   ├── users
│   │   │   └── user-1
│   │   │       ├── default.nix
│   │   │       └── home.nix
│   │   ├── default.nix
│   │   ├── disk-config.nix
│   │   └── hardware-configuration.nix
│   ├── nixos-host-2.nix
│   └── ...
└── flake.nix
```

`flake.nix` will provide the `nixosConfigurations` output by reading files from
the `nixos-configurations/` directory. These files, while technically also being
modules themselves, are intended to define the configuration of a host/machine.
I have followed roughly the same structure for each host/machine, however it is
perfectly acceptable to neglect this structure and define all configurations in
a single `.nix` file. A minimal amount of configuration should be declared by
modules in this folder, instead these modules should enable options declared by
modules in the `modules/` directory to configure the host/machine.

I have chosen to not provide a `homeConfigurations` output, as Impermanence is
not compatible with standalone Home Manager and it's currently enabled on all of
my Home Manager configurations. I do use standalone Home Manager on one
non-NixOS system, though: my work laptop. I feel the best way to handle that,
though, is to just have a similar repo to this one in my workplace internal Git
that imports and uses my Home Manager modules from this repo.

Modules can exist in three places within the `modules/` directory:

- `modules/nixos/*`
- `modules/home-manager/*`
- `modules/*`

NixOS configurations have access to modules in `modules/nixos/*` and
`modules/*`, excluding `modules/home-manager/*`.

Home Manager configurations have access to module `modules/home-manager/*` and
`modules/*`, excluding `modules/nixos/*`.

Modules defined directly under the `modules/` directory are modules that are
intended to be globally accessible, from NixOS configurations/modules _and_ Home
Manager configurations/modules.

**All accessible modules are imported by default**, meaning that a module should
never modify the configuration by default. For most modules, this just means
having an enable option with the entire configuration declaration gated behind
`lib.mkIf cfg.enable`.

## Configured Hosts/Machines

- [Azalea](https://github.com/sebastianrasor/nix-config/tree/main/configurations/azalea) -
  My primary laptop, a Framework Laptop 13.
- [Carbon](https://github.com/sebastianrasor/nix-config/tree/main/configurations/carbon) -
  My homelab server, it hosts most of the services I rely on.
- [Nephele](https://github.com/sebastianrasor/nix-config/tree/main/configurations/nephele) -
  Vultr VPS, hosts Headscale as well as proxying certain services to the public
  internet.
- [Sunflower](https://github.com/sebastianrasor/nix-config/tree/main/configurations/sunflower) -
  My other laptop, a Framework Laptop 12. This is the one I bring with me when I
  leave the house.

## Notable Modules

- [home-manager/cosmic.nix](https://github.com/sebastianrasor/nix-config/blob/main/modules/home-manager/cosmic.nix) -
  My COSMIC desktop environment configuration.
- [home-manager/nvf.nix](https://github.com/sebastianrasor/nix-config/blob/main/modules/home-manager/nvf.nix) -
  My Neovim configuration.
- [nixos/pam.nix](https://github.com/sebastianrasor/nix-config/blob/main/modules/nixos/pam.nix) -
  Sets up user authentication on my devices to use my security keys. When
  authenticating locally, a physical security key is required. When
  authenticating remotely, ssh-agent forwarding is used, which also requires a
  local security key.
- [nixos/persistence.nix](https://github.com/sebastianrasor/nix-config/blob/main/modules/nixos/persistence.nix) -
  An abstraction to easily define which files should survive a reboot on tmpfs
  root systems.
- [nixos/reverse-proxy.nix](https://github.com/sebastianrasor/nix-config/blob/main/modules/nixos/reverse-proxy.nix) -
  An abstraction to easily configure reverse proxy hosts.

## Configured Inputs

- [authentik-nix](https://github.com/nix-community/authentik-nix) - Community
  authentik flake
- [Cachix Deploy](https://docs.cachix.org/deploy/) - Pull based deployment
  system
- [cosmic-manager](https://github.com/HeitorAugustoLN/cosmic-manager) -
  Declarative COSMIC configurations
- [disko](https://github.com/nix-community/disko) - Declarative disk
  configurations
- [Home Manager](https://github.com/nix-community/home-manager) - Declarative
  dotfiles
- [Impermanence](https://github.com/nix-community/impermanence) -
  [Erase your darlings](https://grahamc.com/blog/erase-your-darlings/)
- [Lanzaboote](https://github.com/nix-community/lanzaboote) - Secure boot
- [nvf](https://github.com/NotAShelf/nvf) - Declarative Neovim configuration
- [sops-nix](https://github.com/Mic92/sops-nix) - Secrets management
- [tailscale/golink](https://github.com/tailscale/golink) - Self hosted golinks
