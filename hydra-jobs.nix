{
  nixpkgs,
  pkgsFor,
  self,
  ...
}:
let
  inherit (nixpkgs) lib;
  jobs = {
    inherit (self) packages;
    checks.x86_64-linux = lib.filterAttrs (
      name: _: !(self.packages.x86_64-linux ? ${name})
    ) self.checks.x86_64-linux;
    nixosConfigurations = lib.mapAttrs (
      _: nixosConfiguration: nixosConfiguration.config.system.build.toplevel
    ) self.nixosConfigurations;
  };
in
jobs
// {
  required = pkgsFor.x86_64-linux.releaseTools.aggregate {
    name = "required";
    constituents = lib.collect lib.isDerivation jobs;
  };
}
