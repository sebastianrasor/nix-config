{ sops-nix, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.secrets;

  hostKeys = {
    azalea = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYRVHE8LC9GY4TT2SN3X9L22W0H7F0EPEQCZNR6JLZNUVJD9D769RXQPQ022JU0EE3WP5UWKK3F2P6CX0DE0M0SE5RTNDPW7CRJ52XR5JQDYSQLSQYQ6WCCYP4WUVVXM6RRKPF4ZCDJYQFP9NYG7C2PJXM4KU950QPF5VVQQS63HT5AKHD5KSRXEG2N3D3YZYFGJMJTGWSG3RNHQ7KFNHT9EPXZHQTC8MV3HP7K2Q7Y4KM70F6FU8QE2PP86KSPVXKP9WZHNHRXETMFWNLR7JRT4ATKY6L63UFZ5X7E3XUNKV70DUSE290K95QQ3QQZ7RLP4L9T0PXEWE3TFP8MLZF4U4CSDR9FN6HD74QWQSY08JXN80JYAVVW74";
    carbon = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYZFJSNYGX9PTKR0TZXQF4MA58ACCJN07D8Z37HQTANJ7ETCKGK6CUQPQXXCZHV32GNG22UYQVFHNJZW9XXYV0YTL7RSPSV3YCV5JNQAEGNFQQLSQYZHEQLK46XV3XLHY4AV8A5FT3WZZVE59RPCDHGP3H5UG8UGAJ5HTQQQS0W8WPFEAWUPNP7X4GJ9D90ETXH7ET7S7FTP570CP858W3M6RM8K2DS4YSUH5LUZHH4RYUXST8AHJ406M9GDNZDC658VE09JDJ4FGC7UUC9ZSQM838ZY3LGKKDEG6QY3LV6CR99NSD6YGEJH6QQ3QQZE7NA8KG5VWEG8EK3NHP53DV93WK7PYN52YPZHGMHCHV6R3S9UFEV6HW48D";
    sunflower = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYQXTEA2W2RARTG7XJTJWXJ5Z0DSCZ882LS9K6SZUL8GY8KNUPZX7VQPQ83GMZYY0VVQWLX6SWVNLGWSKQHT8TXWA442J8JYAADM75RSZ5JAQQLSQYZ8U3DCTZWSF5UQ4ARMUQNKYFR9AA72SNL6ZCLP9MCESA08KF7DXSQQS9A82M807597558WAGFZM3JVFRPUCR9WQPHD2KT54W4XA536LMDJ4DZ6CER9R7WL6S6WWYF8P27LXLH40ZGT4M4U6AJTZ8KKZPS025VDU93R2K0ACX5JWTCPQPYNLSDPH9A6PKXTPPGFYMECTQQ3QQZM5SF5MS0FZ0LW7W2GDUM85EGQ46V2AKGWE8R65RT764TECDTTCTGMU3Z4A";
  };

  hostKeyFile =
    if builtins.hasAttr config.networking.hostName hostKeys then
      pkgs.writeText "key.txt" hostKeys.${config.networking.hostName}
    else
      null;
in
{
  options = {
    sebastianrasor.secrets = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  imports = [ sops-nix.nixosModules.sops ];

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./secrets.yaml;

      age =
        if builtins.hasAttr config.networking.hostName hostKeys then
          {
            plugins = with pkgs; [
              age-plugin-tpm
            ];
            sshKeyPaths = lib.mkForce [ ];
            #keyFile = pkgs.writeText "key.txt" hostKeys.${config.networking.hostName};
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = false;
          }
        else
          {
            sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };
    };

    system.activationScripts.install-age-key =
      let
        escapedHostFile = lib.escapeShellArg hostKeyFile;
        escapedKeyFile = lib.escapeShellArg config.sops.age.keyFile;
      in
      lib.mkIf (hostKeyFile != null) (
        lib.stringAfter [ ] ''
          if [[ ! -f ${escapedKeyFile} ]]; then
            echo installing tpm age key
            install -Dm0600 ${escapedHostFile} ${escapedKeyFile}
          fi
        ''
      );
  };
}
