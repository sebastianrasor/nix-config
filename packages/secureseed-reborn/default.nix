{
  gradle_9,
  lib,
  stdenvNoCC,
  temurin-bin-25,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "secureseed-reborn";
  version = "1.1.0";

  src = fetchGit {
    url = "https://github.com/HaHaWTH/SecureSeed-Reborn";
    ref = "refs/pull/2/head";
    rev = "cca1629629709ef23bfb6a2af143cbd2e5660917";
  };

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

    mkdir -p $out/share/secureseed-reborn
    install -Dm644 build/libs/secure-seed-reborn-${finalAttrs.version}.jar $out/share/secureseed-reborn

    runHook postInstall
  '';

  meta = {
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # mitm cache
    ];
  };
})
