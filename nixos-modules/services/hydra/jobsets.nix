{ pulls, ... }:
let
  prs = builtins.fromJSON (builtins.readFile pulls);
  mkFlakeJobset = description: flake: {
    inherit description flake;
    enabled = 1;
    type = 1;
    hidden = false;
    keepnr = 3;
    schedulingshares = 100;
    checkinterval = 60;
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
        main = mkFlakeJobset "main branch" "github:sebastianrasor/nix-config/main";
      }
      // builtins.listToAttrs (
        map (num: {
          name = "pr-${num}";
          value = mkFlakeJobset "PR #${num}: ${prs.${num}.title}" "github:sebastianrasor/nix-config/${prs.${num}.head.sha}";
        }) (builtins.attrNames prs)
      )
    );
    args = [
      "-c"
      "printf '%s\\n' \"$json\" > \"$out\""
    ];
  };
}
