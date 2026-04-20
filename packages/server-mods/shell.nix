{
  pkgs ? import <nixpkgs> { },
}:
let
  pkg = pkgs.callPackage ./default.nix { };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    just
  ];
  inputsFrom = [ pkg ];
  shellHook = ''
    # GRADLE_HOME is required for Intellij IDEA to work without a wrapper
    export GRADLE_HOME="${pkgs.gradle_9}/libexec/gradle"
    export JAVA_HOME="${pkgs.temurin-bin-25}"
  '';
}
