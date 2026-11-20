{
  pkgs ? import <nixpkgs> { },
}:
pkgs.craneLib.devShell {
  inputsFrom = [
    pkgs.www-sebastianrasor-com
  ];

  packages = with pkgs; [
    mailpit
    rust-analyzer
  ];

  MP_SMTP_AUTH = "noreply:password1";
  MP_SMTP_AUTH_ALLOW_INSECURE = true;
  WWW_ASSETS_DIR = pkgs.www-sebastianrasor-com.assets;
  WWW_HOME_DIR = pkgs.www-sebastianrasor-com.homeDir;
}
