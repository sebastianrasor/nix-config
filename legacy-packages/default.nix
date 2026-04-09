{ callPackages, ... }:
rec {
  fabricmcServers = callPackages ./fabricmc-servers { };
  fabricmc-server = fabricmcServers.fabricmc-server;
}
