{ lib, ... }:
{
  options.sebastianrasor.domain = lib.mkOption {
    type = lib.types.str;
    default = "rasor.us";
  };
}
