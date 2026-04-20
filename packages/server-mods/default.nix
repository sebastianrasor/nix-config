{
  gradle_9,
  lib,
  stdenvNoCC,
  temurin-bin-25,
}:
let
  gradleProperties = lib.pipe (builtins.readFile ./gradle.properties) [
    (lib.strings.splitString "\n")
    (map (line: lib.strings.trim line))
    (builtins.filter (line: line != "" && !(lib.strings.hasPrefix "#" line)))
    (map (
      line:
      let
        splitLine = lib.strings.splitString "=" line;
        key = lib.strings.trim (builtins.elemAt splitLine 0);
        value = lib.strings.trim (builtins.elemAt splitLine 1);
      in
      lib.attrsets.nameValuePair key value
    ))
    (map (nameValuePair: {
      path = lib.strings.splitString "." nameValuePair.name;
      update = _: nameValuePair.value;
    }))
    lib.attrsets.updateManyAttrsByPath
  ] { };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = gradleProperties.mod_id;
  version = gradleProperties.mod_version;

  src = ./.;

  nativeBuildInputs = [ gradle_9 ];

  mitmCache = gradle_9.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  gradleFlags = [ "-Dorg.gradle.java.home=${temurin-bin-25}" ];

  gradleBuildTask = "build";

  doCheck = false;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/${gradleProperties.mod_id}
    install -Dm644 build/libs/${gradleProperties.mod_id}-${gradleProperties.mod_version}.jar $out/share/${gradleProperties.mod_id}

    runHook postInstall
  '';

  meta = {
    inherit (gradle_9.meta) platforms;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # mitm cache
    ];
  };
})
