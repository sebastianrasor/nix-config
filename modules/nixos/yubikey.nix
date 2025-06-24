{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    sebastianrasor.yubikey.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.yubikey.enable {
    environment.systemPackages = with pkgs; [
      yubikey-manager
      yubikey-personalization
      yubico-piv-tool
      yubioath-flutter
    ];

    services = {
      pcscd = {
        enable = true;
        plugins = [pkgs.yubikey-personalization];
      };
      udev.packages = [pkgs.yubikey-personalization];
    };

    security.pam.u2f = {
      enable = true;
      settings = {
        authfile = lib.mkDefault (
          builtins.toFile "u2f_mappings" (
            lib.concatMapStringsSep "\n"
            (
              user:
                lib.concatStringsSep ":" [
                  user
                  "XC0l4rvWz1xsxAMV6ZwwBDwPhfccEyotFazdVduuBmb6uDJyFHPYR+mi0EO+1Ba0/NlLEi+GUzxSEuJX9DVqKw==,uEZrLrjqmSUPyKpXFSmRn9T/93Q7J0/LjuDlcrpxi7B3cpovlMDMvGDc+J6PEze5S0BNaijl8jIQ35htP0CAsw==,es256,+presence"
                  "e+WSTsiq3LiJqYKG42qYinuYkyNaNdY4sIhKujZ0ipaZXAVSL04VyenxrlAYWJhYzD7AhvItbqVUpCfyP4/asw==,2YUV0VnvmZcZU6rRGIAqVywUnLANAO6AwJ4/TGbQmH8XZFr2Jb0EaPi2JnYXoAVpWvXnh8XwHd42d2wbNAwc9A==,es256,+presence"
                  "/nLLVK7JLYamFX6KbIDni6+TqZ6NbllqQt98Z3kdSsp8q9J51sUA+iTXPu4ZKScQK3B3Y0BSVnJbVPK9V/pUOw==,8Jc9aDZ3k3Z6xABVk0X6WbC5ihhgUPY+zc6DB8vzxr2gh01AiVxGRL9kTNU8hdyEhnNCuaYJ7PZgP6Z4kWsdwA==,es256,+presence"
                ]
            )
            [
              "root"
              "sebastian"
            ]
          )
        );
        cue = true;
        pinverification = 1;
      };
    };

    hardware.gpgSmartcards.enable = true;
  };
}
