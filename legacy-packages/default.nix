{ callPackages, ... }:
rec {
  fabricmcServers = callPackages ./fabricmc-servers { };
  fabricmc-server-latest = fabricmcServers.fabricmc-server-latest;
}
