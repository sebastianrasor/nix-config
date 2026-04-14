{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.secrets;

  hostKeys = {
    azalea = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYRVHE8LC9GY4TT2SN3X9L22W0H7F0EPEQCZNR6JLZNUVJD9D769RXQPQ022JU0EE3WP5UWKK3F2P6CX0DE0M0SE5RTNDPW7CRJ52XR5JQDYSQLSQYQ6WCCYP4WUVVXM6RRKPF4ZCDJYQFP9NYG7C2PJXM4KU950QPF5VVQQS63HT5AKHD5KSRXEG2N3D3YZYFGJMJTGWSG3RNHQ7KFNHT9EPXZHQTC8MV3HP7K2Q7Y4KM70F6FU8QE2PP86KSPVXKP9WZHNHRXETMFWNLR7JRT4ATKY6L63UFZ5X7E3XUNKV70DUSE290K95QQ3QQZ7RLP4L9T0PXEWE3TFP8MLZF4U4CSDR9FN6HD74QWQSY08JXN80JYAVVW74";
    carbon = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYQXDVVDESYSKN6ZLVEY0DE6XFH8K6DQPMWAV8P0KZ0WC0WK47D5QJQPQR5E9Z90LP2R0VFW9P2LLRE0PXNTZHP7TWQMPXGVCZ2EDJZTCU6ZQQLSQYPFZWN3NPCFETT8SYG98XVLAFHGS6LKK09TLRKDPRKKWFRJVMS2CYQQSG2MZCK88C44M6ZJSKD3NJSMHCFC5JGYQRVMSVTQ947KJTX55NGX26VHERV4FSEV0D36KHJ0H2UJ749GWTE9R6J3S9A4STGDL7WKQW2H5MR8M3X5PUJF6EZ0ZXEX35C752VM8DX6KEDN8NKJGQQ3QQZLQL352LF47UFCHQM8MRU3FMWRQGH5UXRXDAKVUV68JM0DZ5TJHGQLL8LM8";
    sunflower = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYQXDVVDESYSKN6ZLVEY0DE6XFH8K6DQPMWAV8P0KZ0WC0WK47D5QJQPQR5E9Z90LP2R0VFW9P2LLRE0PXNTZHP7TWQMPXGVCZ2EDJZTCU6ZQQLSQYPFZWN3NPCFETT8SYG98XVLAFHGS6LKK09TLRKDPRKKWFRJVMS2CYQQSG2MZCK88C44M6ZJSKD3NJSMHCFC5JGYQRVMSVTQ947KJTX55NGX26VHERV4FSEV0D36KHJ0H2UJ749GWTE9R6J3S9A4STGDL7WKQW2H5MR8M3X5PUJF6EZ0ZXEX35C752VM8DX6KEDN8NKJGQQ3QQZLQL352LF47UFCHQM8MRU3FMWRQGH5UXRXDAKVUV68JM0DZ5TJHGQLL8LM8";
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
}
// lib.optionalAttrs (inputs ? sops-nix) {
  imports = [ inputs.sops-nix.nixosModules.sops ];

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
