{ ... }:
{
  sebastianrasor = {
    core.enable = true;

    atkinson-hyperlegible.enable = true;
    browserpass.enable = true;
    cosmic.enable = true;
    discord.enable = true;
    git.enable = true;
    google-chrome.enable = true;
    gpg.enable = true;
    monaspace.enable = true;
    mpv.enable = true;
    nvf.enable = true;
    pass.enable = true;
    persistence.enable = true;
    posy-cursors.enable = true;
    prismlauncher.enable = true;
    tailscale-systray.enable = true;
    thunderbird.enable = true;
    yubikey-touch-detector.enable = true;
  };

  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "23.11";
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
}
