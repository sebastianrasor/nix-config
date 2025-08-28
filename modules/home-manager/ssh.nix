{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.ssh.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.ssh.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        controlMaster = "auto";
        controlPersist = "10m";
      };
      matchBlocks.tailnet = {
        match = "localnetwork 100.64.0.0/10";
        forwardAgent = true;
      };
    };
  };
}
