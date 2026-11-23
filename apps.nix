pkgs:
let
  inherit (pkgs) lib;
  repoLib = import ./lib { inherit lib; };

  # Read all packages without platform filtering so update scripts work on any host
  # (e.g. updating x86_64-linux packages from aarch64-darwin or aarch64-linux).
  allPackages = repoLib.readNixDir ./packages (
    path: pkgs.${lib.removeSuffix ".nix" (baseNameOf path)}
  );

  packageUpdaters = lib.pipe allPackages [
    (lib.filterAttrs (_: pkg: pkg ? passthru.updateScript))
    (lib.mapAttrs (_: pkg: pkg.passthru.updateScript))
  ];

  packageNames = lib.attrNames packageUpdaters;

  mkApp = description: drv: {
    type = "app";
    program = lib.getExe drv;
    meta = {
      inherit description;
    };
  };

  update = pkgs.writeShellApplication {
    name = "update";
    runtimeInputs = [
      pkgs.git
      pkgs.nix
    ];
    text = ''
      repo_root="$(git rev-parse --show-toplevel)"
      cd "$repo_root"

      available=(flake ${lib.escapeShellArgs packageNames})

      usage() {
        echo "Usage: update [target ...]"
        echo "Available targets: ''${available[*]}"
      }

      if [ "$#" -gt 0 ]; then
        for arg in "$@"; do
          case "$arg" in
            -h | --help)
              usage
              exit 0
              ;;
          esac
        done
        targets=("$@")
      else
        targets=("''${available[@]}")
      fi

      for target in "''${targets[@]}"; do
        valid=false
        for known in "''${available[@]}"; do
          if [ "$target" = "$known" ]; then
            valid=true
            break
          fi
        done
        if [ "$valid" != true ]; then
          echo "Unknown update target: $target" >&2
          usage >&2
          exit 1
        fi
      done

      for target in "''${targets[@]}"; do
        if [ "$target" = "flake" ]; then
          echo "==> Updating flake inputs"
          nix flake update
        else
          echo "==> Updating package: $target"
          nix run ".#update-$target"
        fi
      done
    '';
  };
in
(lib.mapAttrs' (
  name: script: lib.nameValuePair "update-${name}" (mkApp "Update ${name} dependencies" script)
) packageUpdaters)
// {
  update = mkApp "Update flake inputs and package dependencies" update;
}
