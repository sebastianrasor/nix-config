{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sebastianrasor.passage;
  agePairs = [
    { identity = "AGE-PLUGIN-YUBIKEY-1CP32YQVZGLFVQLG2ZYC4L"; recipient = "age1yubikey1q26z4s8dkaefe0t02ry5986x20nftcqe6g4ngkuhnx4tresztnvewc47j0u"; }
    { identity = "AGE-PLUGIN-YUBIKEY-1VV43JQ5ZW3H70KSZKWT7Z"; recipient = "age1yubikey1qvag83hwxux6agjr3zj6gn4083j8kr8pucml7l92tz7rnchtzd6hv6l9us6"; }
    { identity = "AGE-PLUGIN-YUBIKEY-1CPYCKQVZF7X8TUS4Q5MW7"; recipient = "age1yubikey1q0j42dwq5dr3x7vl6hq3g3lkzr9wgp76anrs65rt3gj4nhk6dlyhgu3dscx"; }
    { identity = "AGE-PLUGIN-YUBIKEY-10RE2WQVZJAXTAZSF0K0WU"; recipient = "age1yubikey1qwlgsvduej6fdzhew5synrm92g90u6rtzjg824rjzj77mx0hf3ys758lcvr"; }
    { identity = "AGE-PLUGIN-YUBIKEY-1HTE2WQVZJK37T4CVXCV94"; recipient = "age1yubikey1qvlz7d7gfx7uaurs5jyfjd3uf9ppvk6j0ksqc3rfmverzr7dv5vygnxq8jp"; }
  ];
  identitiesFile = pkgs.writeText "age-identities" (builtins.concatStringsSep "\n" (builtins.catAttrs "identity" agePairs));
  recipientsFile = pkgs.writeText "age-recipients" (builtins.concatStringsSep "\n" (builtins.catAttrs "recipient" agePairs));
  age = lib.getExe' (pkgs.age.withPlugins (ps: with ps; [
    age-plugin-yubikey
  ])) "age";
  passage = pkgs.runCommand "passage-configured" { nativeBuildInputs = [ pkgs.makeBinaryWrapper ]; } ''
    makeBinaryWrapper ${lib.getExe pkgs.passage} $out/bin/passage \
      --set PASSAGE_DIR ${cfg.passageDir} \
      --set PASSAGE_IDENTITIES_FILE ${identitiesFile} \
      --set PASSAGE_AGE ${age} \
      --set PASSAGE_RECIPIENTS_FILE ${recipientsFile}
  '';
in
{
  options.sebastianrasor.passage = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    passageDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.xdg.dataHome}/passage/store";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      passage
    ];
  };
}
