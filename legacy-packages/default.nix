{ callPackages, lib, pkgs, ... }:
lib.filterAttrsRecursive
(_: v: !(lib.isDerivation v) || lib.meta.availableOn { inherit (pkgs.stdenv.hostPlatform) system; } v)
rec {
  fabricmcServers = callPackages ./fabricmc-servers { };
  inherit (fabricmcServers) fabricmc-server-latest;
}
