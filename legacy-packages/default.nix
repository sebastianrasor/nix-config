pkgs:
let
  inherit (pkgs) lib stdenv;
in
lib.filterAttrsRecursive
  (
    _: v:
    let
      tryAvailableOn = builtins.tryEval (
        lib.meta.availableOn { inherit (stdenv.hostPlatform) system; } v
      );
    in
    !(lib.isDerivation v) || (tryAvailableOn.success && tryAvailableOn.value)
  )
  rec {
    fabricmcServers = pkgs.callPackages ./fabricmc-servers { };
    inherit (fabricmcServers) fabricmc-server-latest;
  }
