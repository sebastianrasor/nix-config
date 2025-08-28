{
  config,
  lib,
  ...
}: {
  options = {
    sebastianrasor.pam.enable = lib.mkEnableOption "";
  };

  config = lib.mkIf config.sebastianrasor.pam.enable {
    security.pam.services.login.unixAuth = false;
    security.pam.services.sudo.unixAuth = false;

    security.pam.u2f = lib.mkIf config.sebastianrasor.yubikey.enable {
      enable = true;
      settings = {
        origin = "pam://sebastianrasor";
        appid = "pam://sebastianrasor";
        authfile = lib.mkDefault (
          builtins.toFile "u2f_mappings" (
            lib.concatMapStringsSep "\n"
            (
              user:
                lib.concatStringsSep ":" [
                  user
                  "+RUZCkSEWmTZHmgH0Ht0x2KMvJSRwgO8/+UOl7ew8FBP5neEtkOCGvq1ez9vGWQjRz6HAm7dG58BzMlNZ2T5ow==,oqGhe0jguLbpzShd4pL3O8AwiUTnmwbXttJMWDUGQyTkibwySDs2N/QvpSfDpKWJk5/6AOPCxb/1qfVuRSG2fA==,es256,+presence"
                  "iQCjhuV/mErNOZfGsCocSZi72e2eXT8MZJKWeIekN5SLgTsIAuqd/UNW3qzNdVqSpYLbnO9tZETtsNPcJR6POg==,EvrmUWX9Yh0mpry0CSHfz/mLTC8FpOqoaI65Nk1wQ9bmyPFBL91Z/weNLVYMsTh9lG7UehY8K1ePBIVn0QqK3g==,es256,+presence"
                  "7x2gUIu8nEHbTlWYxMJ4So0PCP4osYDrkquqSFXvXtsR4KG1OZX3yX8iQ1OO0daYUhkyWMSRm7cQEbg60fg9AA==,wHzUMdF3sult3309R0HyylZ94W7PXq1hdMHEzmKcrzzLaBeOLZH6opiOm/m9Rs/rxU5ixh4YZeqciUSoxMuysw==,es256,+presence"
                  "TbSWNmShaEjbISE1SVS9kgD+Li6L3iz9D3an7w3UTGfo8JBhOqBiT3eJBOrNptc8ewCfstNmylLRDsiBO86sCA==,WNOaGRBebrl+dHkTs7T/Ws8gh0mnlC9Rz1YLq5E6DVjyRAQq1UoJCQnag2FYLYmh/CQzGnhn2r5VQeGPH5U7ow==,es256,+presence"
                  "4ech4nXbYMeqL3rXT7C0oFqvTJ686u5XR+MO2IKIG1VVH7SuXfTFGSPruW2I8hZn8xGxqOHUiBAODLSwRg+Mdg==,S2+pqucnawDCNNOet2dBgsueIUdy9ZFh0oVoNlmQeQt/KJPXUTDKrcAeD0u9l0yRGkbz0rcG2WadKni6hQUtRQ==,es256,+presence"
                ]
            )
            [
              "sebastian"
              # more users if needed
            ]
          )
        );
        cue = true;
        pinverification = 1;
      };
    };

    security.pam.services.sudo.rssh = true;
    security.pam.rssh = lib.mkIf config.sebastianrasor.sshd.enable {
      enable = true;
      settings = {
        auth_key_file = "/etc/ssh/authorized_keys.d/$ruser";
        #cue = true;
      };
    };
  };
}
