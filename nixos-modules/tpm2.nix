{
  config,
  lib,
  ...
}:
let
  cfg = config.sebastianrasor.tpm2;
in
{
  options.sebastianrasor.tpm2 = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    security.tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };
}
