{ config, ... }: {
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    scdaemonSettings = {
      disable-ccid = true;
    };
    settings = {
      limit-card-insert-tries = "1";
    };
    publicKeys = [
      {
        trust = "ultimate";
        text =
          ''
            -----BEGIN PGP PUBLIC KEY BLOCK-----
            
            mDMEY4K99xYJKwYBBAHaRw8BAQdA/IQHHXTVylX+N6IyS/CR2UPy4ZUlucmbjUB0
            cnQgivK0D1NlYmFzdGlhbiBSYXNvcoiWBBMWCAA+AhsDBQsJCAcCBhUKCQgLAgQW
            AgMBAh4BAheAFiEECHjtFi+LKV8lrBl78g3kuls21OkFAmVk2pgFCQPDUCEACgkQ
            8g3kuls21Onp2gD/ZVbp7P0zIgCEkzBDKMtr8FTkr/JRfqrx8WHpMuCR51sA/298
            EDFLpR7LfmBf+NxtuEx7WpdNlc+xvkYQcFnFGzMHuDMEY4K99xYJKwYBBAHaRw8B
            AQdAQq3L8BJxA9SNhw6l/ZAZrC4tlkHCS2OYhndmKIL1V6qIfgQYFggAJgIbIBYh
            BAh47RYviylfJawZe/IN5LpbNtTpBQJlZNqJBQkDw1ASAAoJEPIN5LpbNtTp2lcB
            AJANRqFrPIM/KFVtQQvRHsrlcUuTldkEX9C+ybJxU0OcAP4ktPUSgujThDZrPEbC
            e4UZ2e8YwfR50QeRfisROURNB7g4BGOCvfcSCisGAQQBl1UBBQEBB0Dsx95y8DZf
            QoX/vLDvByNsFMVdVIPK511vnKKa3HWgHwMBCAeIfgQYFggAJgIbDBYhBAh47RYv
            iylfJawZe/IN5LpbNtTpBQJlZNqlBQkDw1AuAAoJEPIN5LpbNtTpVnMBALQkYhBG
            0R+NbqEDTtYerEpX6Ys0xHD5+jwj1v71ggbBAP98JMSajhG2g9LD1OoyoeJRuGed
            i654JPGrqBbzUJPnDA==
            =Ufog
            -----END PGP PUBLIC KEY BLOCK-----
          '';
      }
      {
        trust = "ultimate";
        text =
          ''
            -----BEGIN PGP PUBLIC KEY BLOCK-----
            
            mDMEY2lVThYJKwYBBAHaRw8BAQdAOxQ25BqNMmdCWLnGfYYHsZSefSMcTw9mAfcr
            BdtUZQa0D1NlYmFzdGlhbiBSYXNvcoiZBBMWCABBAhsDBQsJCAcCBhUKCQgLAgQW
            AgMBAh4BAheAAhkBFiEETzmDd8azDWOX7NfOShSp4qwlYEQFAmX2PBgFCQRuGkoA
            CgkQShSp4qwlYESTQQEAgxJ1iQU2FrlgFA88XB2C9XNgDHmy5fsSRi+I+nAdhT0B
            AJs9wGAmaAqpwqOnc3qs9cGmQZIQ4AEzydZ5Zqw9GmUMuDMEY2lVThYJKwYBBAHa
            Rw8BAQdAC0EUJ6bKfcL23qocXYtP4MazXXo6G1YKHQwO+JvXihmIfgQYFggAJgIb
            IBYhBE85g3fGsw1jl+zXzkoUqeKsJWBEBQJl9jw7BQkEbhptAAoJEEoUqeKsJWBE
            fKgBAOepvCAaggwSl7MYobY7P5Vj3ydgZKYHjGVXnARUytS2AQDroOzp/JHfNoS9
            LeAKOeYk2Zk5SPaa96witXOh1xvtBbg4BGNpVU4SCisGAQQBl1UBBQEBB0BFv0GO
            AinAlGosxYxGB266FyMLx63BiSeefrq34PxFAAMBCAeIfgQYFggAJgIbDBYhBE85
            g3fGsw1jl+zXzkoUqeKsJWBEBQJl9jw7BQkEbhptAAoJEEoUqeKsJWBEyjQBAJkq
            Yt3sV6K68RHU7j2jfesy6izdBof3U4BQS2uhKx1uAQDhZrJz8idvUQiNw5f4YGSp
            RlP9OgkRC6ERg28vKsIPAA==
            =jf6Z
            -----END PGP PUBLIC KEY BLOCK-----
          '';
      }
      {
        trust = "ultimate";
        text =
          ''
            -----BEGIN PGP PUBLIC KEY BLOCK-----
            
            mDMEZfco2BYJKwYBBAHaRw8BAQdAF3YzGTdiQQbTGzr6cpKk1mtk6gkbU/aycKuX
            gLZaami0D1NlYmFzdGlhbiBSYXNvcoiWBBMWCAA+FiEEeDLWvsmwZPR7faBD8QwP
            /VtTMSYFAmX3KNgCGwMFCQHhM4AFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AACgkQ
            8QwP/VtTMSaCoAD9HWsMPWgfdsAJOlYvGqLZaxpGxfJalu0kCmBKvb0CtQoBAMHN
            +wiTHjuRy/caUaEPxx1nY4a4TDkwr44KLMQE2ZsDuDMEZfco2BYJKwYBBAHaRw8B
            AQdAbHHb6mdsxgr/Gxx+6/PT7FAXEZR/txI5QPfORQqzcBSIfgQYFggAJhYhBHgy
            1r7JsGT0e32gQ/EMD/1bUzEmBQJl9yjYAhsgBQkB4TOAAAoJEPEMD/1bUzEm1oAA
            /353u8xsUA35iciyAsKmuSHz9e5kJrgGOPgSGJYWtqusAP9tREJadXOE3YN02UuL
            PkYTqaCQ50aOW9q6C0q3AhupCLg4BGX3KNgSCisGAQQBl1UBBQEBB0CTxoqmyU0S
            eRoGCD6aesBX2x94EP0C8lZB/LViNiacfAMBCAeIfgQYFggAJhYhBHgy1r7JsGT0
            e32gQ/EMD/1bUzEmBQJl9yjYAhsMBQkB4TOAAAoJEPEMD/1bUzEmzGgA/2BG7cUQ
            NhqN/vHkOD5JKmBRniMWavAjhxJCf6OycFGbAP9m6ddBmYE613XysOv57eWvUjuJ
            8wScOzv2t19wWda9Dg==
            =5l1D
            -----END PGP PUBLIC KEY BLOCK-----
          '';
      }
    ];
  };

  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableSshSupport = true;
  };
}
