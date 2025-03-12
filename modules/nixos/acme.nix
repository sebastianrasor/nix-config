{ config, lib, ... }:
{
  options = {
    sebastianrasor.acme.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.acme.enable {
    security.acme = {
      acceptTerms = true;
      defaults = {
        dnsResolver = "1.1.1.1:53";
        email = "general@rasor.us";
      };
    };
  };
}
