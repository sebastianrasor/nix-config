{lib, ...}: {
  options = {
    sebastianrasor.domain = lib.mkOption {
      default = "rasor.us";
    };
  };
}
