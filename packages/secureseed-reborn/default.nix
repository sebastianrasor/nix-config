{ stdenvNoCC, pkgs }:
let
  gradle = pkgs.gradle_9;
in 
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "secureseed-reborn";
  version = "1.1.0";

  src = fetchGit {
    url = "https://github.com/HaHaWTH/SecureSeed-Reborn";
    ref = "refs/pull/2/head";
    rev = "c4ebc165d974bb454d98b0cfdff643fb83fbb938";
  };

  nativeBuildInputs = [ gradle ];

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

    mkdir -p $out/share/secureseed-reborn
    install -Dm644 build/libs/secure-seed-reborn-1.1.0.jar $out/share/secureseed-reborn

    runHook postInstall
  '';

  meta = {
    inherit (gradle.meta) platforms;
    sourceProvenance = with pkgs.lib.sourceTypes; [
      fromSource
      binaryBytecode # mitm cache
    ];
  };

})
