{ callPackages, ... }:
rec {
  fabricmcServers = callPackages ./fabricmc-servers { };
  inherit (fabricmcServers) fabricmc-server-latest;
}
