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
}
