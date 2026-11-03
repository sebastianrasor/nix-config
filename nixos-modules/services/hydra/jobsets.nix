{ pulls, ... }:
let
  prs = builtins.fromJSON (builtins.readFile pulls);
  mkFlakeJobset = checkinterval: description: flake: {
    inherit checkinterval description flake;
    enabled = 1;
    type = 1;
    hidden = false;
    keepnr = 3;
    schedulingshares = 100;
    enableemail = false;
    emailoverride = "";
  };
in
{
  jobsets = derivation {
    name = "nix-config-jobsets";
    system = "x86_64-linux";
    builder = "/bin/sh";
    preferLocalBuild = true;
    allowSubstitutes = false;
    json = builtins.toJSON (
      {
        main = mkFlakeJobset 3600 "main branch" "github:sebastianrasor/nix-config/main";
      }
      // builtins.listToAttrs (
        map (num: {
          name = "pr-${num}";
          value =
            mkFlakeJobset 60 "PR #${num}: ${prs.${num}.title}"
              "github:sebastianrasor/nix-config/${prs.${num}.head.sha}";
        }) (builtins.attrNames prs)
      )
    );
    args = [
      "-c"
      "printf '%s\\n' \"$json\" > \"$out\""
    ];
  };
}
