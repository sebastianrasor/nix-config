{...}: {
  sebastianrasor.core.enable = true;

  sebastianrasor.atkinson-hyperlegible.enable = true;
  sebastianrasor.bottom.enable = true;
  sebastianrasor.browserpass.enable = true;
  sebastianrasor.cosmic.enable = true;
  sebastianrasor.discord.enable = true;
  sebastianrasor.git.enable = true;
  sebastianrasor.google-chrome.enable = true;
  sebastianrasor.gpg.enable = true;
  sebastianrasor.monaspace.enable = true;
  sebastianrasor.mpv.enable = true;
  sebastianrasor.neovim.enable = true;
  sebastianrasor.pass.enable = true;
  sebastianrasor.persistence.enable = true;
  sebastianrasor.posy-cursors.enable = true;
  sebastianrasor.thunderbird.enable = true;
  sebastianrasor.yubikey-touch-detector.enable = true;

  home = {
    username = "sebastian";
    homeDirectory = "/home/sebastian";
    keyboard.variant = "dvorak";

    stateVersion = "25.11";
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
}
