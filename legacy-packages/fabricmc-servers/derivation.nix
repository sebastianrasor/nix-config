{
  lib,
  fetchurl,
  makeBinaryWrapper,
  curl,
  jq,
  writeShellApplication,
  stdenvNoCC,
  version,
  url,
  sha256,
  udev,
  jre_headless,
  symlinkJoin,
  fabricMods ? [ ],
  ...
}:
let
  combinedMods =
    if (builtins.length fabricMods > 0) then
      symlinkJoin {
        name = "fabricmc-server-mods";
        paths = fabricMods;
      }
    else
      null;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "fabricmc-server";
  inherit version url sha256;

  src = fetchurl {
    inherit url sha256;
  };

  installPhase = ''
    runHook preInstall

    install -D $src $out/share/fabricmc/server.jar

    makeBinaryWrapper ${lib.getExe jre_headless} $out/bin/minecraft-server \
      ${lib.optionalString (combinedMods != null) ''--add-flags "-Dfabric.addMods=${combinedMods}"''} \
      --append-flags "-jar $out/share/fabricmc/server.jar nogui" \
      ${lib.optionalString stdenvNoCC.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ udev ]}"}

    runHook postInstall
  '';

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  dontUnpack = true;

  passthru = {
    updateScript = lib.getExe (writeShellApplication {
      name = "update-versions";

      runtimeInputs = [
        curl
        jq
      ];

      text = ''
        echo "1" >&2
        echo "${dirOf finalAttrs.finalPackage.meta.position}/versions.json" >&2
        echo "2" >&2

        outPath="${
          # if this is an absolute path in nix store, use path relative to the store path
          if lib.hasPrefix "${builtins.storeDir}/" (toString ./versions.json) then
            builtins.concatStringsSep "/" (
              lib.drop 1 (
                lib.splitString "/" (lib.removePrefix "${builtins.storeDir}/" (toString ./versions.json))
              )
            )
          # if this is an absolute path anywhere else, just use that path
          else if lib.hasPrefix "/" (toString ./versions.json) then
            toString ./versions.json
          # otherwise, use a path relative to the package
          else
            "${dirOf finalAttrs.finalPackage.meta.position}/versions.json"
          #throw "don't know how to proceed"
        }"

        versions="$(curl 'https://meta.fabricmc.net/v2/versions' | jq --from-file ${./parse_versions.jq})"

        echo "''${versions@P}" >$outPath
      '';
    });
  };

  meta = {
    description = "aoeu";
  };
})
