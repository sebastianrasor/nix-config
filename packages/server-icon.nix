{
  stdenvNoCC,
  fetchzip,
  pkgs,
}:
stdenvNoCC.mkDerivation {
  name = "server-icon.png";

  src = fetchzip {
    url = "https://resources.download.minecraft.net/a9/a9945dba2bc4d4841c0dae23faaa8be9bd9e56f1";
    extension = "zip";
    sha256 = "07n36y9a2gb9kps29s8gf0aviq6ryx17nlbmzffjhpy73qsjv7ik";
    stripRoot = false;
  };

  buildInputs = with pkgs; [
    imagemagick
  ];

  buildPhase = ''
    runHook preBuild

    magick assets/minecraft/textures/item/diamond.png -sample 64x64 server-icon.png

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp server-icon.png $out

    runHook postInstall
  '';
}
