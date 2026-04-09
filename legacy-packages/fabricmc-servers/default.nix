{
  callPackage,
  lib,
  javaPackages,
  fabricMods ? [ ],
  ...
}:
let
  versions = lib.importJSON ./versions.json;

  latestVersion = lib.last (builtins.sort lib.versionOlder (builtins.attrNames versions));
  escapeVersion = builtins.replaceStrings [ "." ] [ "_" ];

  packages = lib.mapAttrs' (version: value: {
    name = "fabricmc-server-${escapeVersion version}";
    value = callPackage ./derivation.nix {
      inherit fabricMods version;
      inherit (value) url sha256;
      jre_headless = javaPackages.compiler.openjdk25.headless;
    };
  }) versions;
in
lib.recurseIntoAttrs (
  packages
  // {
    fabricmc-server = builtins.getAttr "fabricmc-server-${escapeVersion latestVersion}" packages;
  }
)
