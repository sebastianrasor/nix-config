{
  hjem,
  pkgsFor ? { },
  self,
  ...
}:
let
  mkHjemCli = pkgs: pkgs.callPackage "${hjem}/cli/package.nix" { };
  hjemCliBySystem = builtins.mapAttrs (_: mkHjemCli) pkgsFor;
in
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.hjem;
in
{
  options.sebastianrasor.hjem = {
    enable = lib.mkEnableOption "hjem";
  };

  imports = [
    hjem.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    environment.pathsToLink = [ "/share/fish" ];

    hjem = {
      cli.package = hjemCliBySystem.${pkgs.stdenv.hostPlatform.system} or (mkHjemCli pkgs);
      clobberByDefault = true;
      extraModules = lib.attrsets.attrValues self.hjemModules;
      users.sebastian.sebastianrasor = {
        core = {
          enable = lib.mkDefault true;
          graphical = lib.mkDefault config.sebastianrasor.laptop.enable;
        };
        persistence.enable = lib.mkDefault config.sebastianrasor.persistence.enable;
      };
    };
  };
}
