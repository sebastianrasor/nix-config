{ pkgs, ... }:
let
  gradleProperties = pkgs.lib.pipe (builtins.readFile ./gradle.properties) [
    (pkgs.lib.strings.splitString "\n")
    (map (line: pkgs.lib.strings.trim line))
    (builtins.filter (line: line != "" && !(pkgs.lib.strings.hasPrefix "#" line)))
    (map (
      line:
      let
        splitLine = pkgs.lib.strings.splitString "=" line;
        key = pkgs.lib.strings.trim (builtins.elemAt splitLine 0);
        value = pkgs.lib.strings.trim (builtins.elemAt splitLine 1);
      in
      pkgs.lib.attrsets.nameValuePair key value
    ))
    (map (nameValuePair: {
      path = pkgs.lib.strings.splitString "." nameValuePair.name;
      update = _: nameValuePair.value;
    }))
    pkgs.lib.attrsets.updateManyAttrsByPath
  ] { };
in
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = gradleProperties.mod_id;
  version = gradleProperties.mod_version;

  src = ./.;

  nativeBuildInputs = with pkgs; [
    gradle_9
  ];

  mitmCache = pkgs.gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  gradleFlags = [ "-Dorg.gradle.java.home=${pkgs.temurin-bin-25}" ];

  gradleBuildTask = "build";

  doCheck = false;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/${gradleProperties.mod_id}
    install -Dm644 build/libs/${gradleProperties.mod_id}-${gradleProperties.mod_version}.jar $out/share/${gradleProperties.mod_id}

    runHook postInstall
  '';

  meta.sourceProvenance = with pkgs.lib.sourceTypes; [
    fromSource
    binaryBytecode # mitm cache
  ];
})
