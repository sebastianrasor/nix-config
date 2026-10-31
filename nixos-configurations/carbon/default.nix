{ constants, ... }:
_: {
  networking.hostName = "carbon";

  sebastianrasor = {
    core.enable = true;

    acme.enable = true;
    actual.enable = true;
    authentik.enable = true;
    cheaters-swear-jar.enable = true;
    forgejo.enable = true;
    harmonia.enable = true;
    headscale.enable = true;
    homebox.enable = true;
    immich.enable = true;
    intel-arc-a380.enable = true;
    jellyfin.enable = true;
    nixbot.enable = true;
    paperless.enable = true;
    persistence.enable = true;
    postgresql.enable = true;
    radicale.enable = true;
    reverse-proxy = {
      enable = true;
      baseDomainName = "ts.${constants.domain}";
    };
    secrets.tpmAgeKey = "AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYZFJSNYGX9PTKR0TZXQF4MA58ACCJN07D8Z37HQTANJ7ETCKGK6CUQPQXXCZHV32GNG22UYQVFHNJZW9XXYV0YTL7RSPSV3YCV5JNQAEGNFQQLSQYZHEQLK46XV3XLHY4AV8A5FT3WZZVE59RPCDHGP3H5UG8UGAJ5HTQQQS0W8WPFEAWUPNP7X4GJ9D90ETXH7ET7S7FTP570CP858W3M6RM8K2DS4YSUH5LUZHH4RYUXST8AHJ406M9GDNZDC658VE09JDJ4FGC7UUC9ZSQM838ZY3LGKKDEG6QY3LV6CR99NSD6YGEJH6QQ3QQZE7NA8KG5VWEG8EK3NHP53DV93WK7PYN52YPZHGMHCHV6R3S9UFEV6HW48D";
    sshd.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAGdZ/fyPx7w2GsbE337H0kNst+GWL/gN4piJizkWj/9";
    systemd-networkd.interfacesRequiredForOnline."enp10s0f0np0" = "routable";
    tailscale-golink.enable = true;
    unas = {
      enable = true;
      host = "10.0.0.103";
    };
    vaultwarden.enable = true;
    wireguard = {
      enable = true;
      address = "10.100.0.2/24";
      publicKey = "o16hcIqhoWUYUxdQzmhpygf/5noF9ovkn1McQmPICFA=";
    };
    www-sebastianrasor-com.enable = true;
  };

  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.05";
}
