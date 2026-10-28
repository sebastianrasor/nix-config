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
    dahlia = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYZE5CF60SJLT8TTSPAFNFQW6XVCDSQ8XZ2TCNTSVNMMY88JY47G25QPQ5RQS2EFDXQN4F9WJC74CF5089HRMKDTW8PP6KVL7P8W8JFJNN95QQLSQYPE3NCADUYNJGJYKHLHJTKV0CJNSSTX9CXUFV8N55WJ2V8U6W8GAWQQSTLM33E8H4DNUUJUUHCN983LUJGQQ7DUTAFF02XZU46N9T73GQW2APE80YUR6P30GCXM7GADA3GHVFM9FT6SDAHJZ3GLHMXVDW3CFK0ZLP24C4TWS0FUXMQVLZ5QTF46LTTP6LS9N964XJ2VCQQ3QQZ7KQXUG0E283SD5SXJTHJ5KXW8GHQ20VCA909X2NM04ZQ99ZUTFJ57SQ7U5";
    sakura = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYZWQW3SRPQ9NRJLCH5M68CCZRWU3JND7JELART8QFKZWLSYH83DLWQPQDYZCRDKUJWZGZF0ZS7EU8TTKJ65RSMSXAZL8WUNHEC7XR67HFXSSQLSQYQC4GPP8S3DC2EQCFYZ46YDD4GZ7CJLJMS5C50FGYTLNF8EHVS7QWQQS9NDREZTWUCQGEFUA4CM8K8QNCTEC3APASGYDZCPKSU6F2VXETSCUYVFHTVEF8QK4KVLLS03U73ARDYDM6XC4P2887JFQKTD3TKVUF2A3AJM4CD058D7VWJ6XH7F40RDHQ2CGJTKZFHVPQA7UQQ3QQZ6WKNN0DM9R38ME4HJE25GM0G7LQU9P6X0EG7SLRJCCMR4X7LTLX5FZJK5P";
  };

  hostKeyFile =
    if builtins.hasAttr config.networking.hostName hostKeys then
      builtins.toFile "key.txt" hostKeys.${config.networking.hostName}
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

      secrets = lib.mkMerge (
        lib.mapAttrsToList (
          username: userCfg:
          lib.mkIf userCfg.enable (
            lib.mapAttrs (_: _: {
              owner = username;
            }) userCfg.sebastianrasor.secrets
          )
        ) config.hjem.users
      );
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
