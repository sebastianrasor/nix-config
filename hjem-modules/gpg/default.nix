{
  constants,
  nixpkgs,
  ...
}:
let
  inherit (nixpkgs) lib;

  hexStringToBase32 =
    let
      mod = a: b: a - a / b * b;
      pow2 = lib.elemAt [
        1
        2
        4
        8
        16
        32
        64
        128
        256
      ];
      base32Alphabet = lib.stringToCharacters "ybndrfg8ejkmcpqxot1uwisza345h769";
      hexToIntTable = lib.listToAttrs (
        lib.genList (x: {
          name = lib.toLower (lib.toHexString x);
          value = x;
        }) 16
      );
      initState = {
        ret = "";
        buf = 0;
        bufBits = 0;
      };
      go =
        {
          ret,
          buf,
          bufBits,
        }:
        hex:
        let
          buf' = buf * pow2 4 + hexToIntTable.${hex};
          bufBits' = bufBits + 4;
          extraBits = bufBits' - 5;
        in
        if bufBits >= 5 then
          {
            ret = ret + lib.elemAt base32Alphabet (buf' / pow2 extraBits);
            buf = mod buf' (pow2 extraBits);
            bufBits = bufBits' - 5;
          }
        else
          {
            inherit ret;
            buf = buf';
            bufBits = bufBits';
          };
    in
    hexString: (lib.foldl' go initState (lib.stringToCharacters hexString)).ret;
in
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.gpg;

  homedirHash = lib.substring 0 24 (hexStringToBase32 (builtins.hashString "sha1" cfg.homedir));
  socketSubdir =
    if cfg.homedir == "${config.directory}/.gnupg" then
      "S.gpg-agent"
    else
      "d.${homedirHash}/S.gpg-agent";
in
{
  options.sebastianrasor.gpg = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    homedir = lib.mkOption {
      type = lib.types.path;
      default = "${config.xdg.data.directory}/gnupg";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.gnupg
    ];

    environment.sessionVariables.GNUPGHOME = cfg.homedir;

    xdg.config.files."fish/conf.d/gpg.fish" = lib.mkIf config.sebastianrasor.fish.enable {
      source = ./gpg.fish;
    };

    xdg.data.files = {
      "gnupg" = {
        type = "directory";
        permissions = "0700";
      };
      "gnupg/gpg.conf".source = ./gpg.conf;
      "gnupg/scdaemon.conf".source = ./scdaemon.conf;
      "gnupg/gpg-agent.conf".text = ''
        grab
        pinentry-program ${lib.getExe pkgs.pinentry-qt}
      '';
    };

    systemd.services = {
      gpg-agent = {
        description = "GnuPG cryptographic agent and passphrase cache";
        documentation = [ "man:gpg-agent(1)" ];
        requires = [ "gpg-agent.socket" ];
        after = [ "gpg-agent.socket" ];
        unitConfig.RefuseManualStart = true;
        environment.GNUPGHOME = cfg.homedir;
        serviceConfig = {
          ExecStart = "${lib.getExe' pkgs.gnupg "gpg-agent"} --supervised";
          ExecReload = "${lib.getExe' pkgs.gnupg "gpgconf"} --reload gpg-agent";
        };
      };

      gpg-import-keys = {
        description = "Import GnuPG public keys and configure smartcard stubs";
        wantedBy = [ "default.target" ];
        environment.GNUPGHOME = cfg.homedir;
        serviceConfig = {
          Type = "oneshot";
          ExecStart =
            let
              importKeysScript = pkgs.writeShellApplication {
                name = "gpg-import-keys";
                runtimeInputs = with pkgs; [
                  coreutils
                  gnugrep
                  gnupg
                ];
                text = builtins.readFile ./import-keys.sh;
              };
            in
            "${lib.getExe importKeysScript} ${constants.gpgKey}";
        };
      };
    };

    systemd.sockets.gpg-agent = {
      description = "GnuPG cryptographic agent and passphrase cache";
      documentation = [ "man:gpg-agent(1)" ];
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = "%t/gnupg/${socketSubdir}";
        FileDescriptorName = "std";
        Service = "gpg-agent.service";
        SocketMode = "0600";
        DirectoryMode = "0700";
      };
    };
  };
}
