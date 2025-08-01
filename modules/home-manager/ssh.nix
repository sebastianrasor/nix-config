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
      controlMaster = "auto";
      controlPersist = "10m";
      matchBlocks.tailnet = {
        match = "localnetwork 100.64.0.0/10";
        forwardAgent = true;
      };
    };
  };
}
