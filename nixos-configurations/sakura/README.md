Documenting for my own future reference:

Command used to install sakura was:

```
nix run github:nix-community/nixos-anywhere -- --extra-files $MY_KEYS --disk-encryption-keys /tmp/secret.key /tmp/secret.key --copy-host-keys --flake .#sunflower --target-host root@10.0.0.89
```

Pre install note (still imaging the flash drive to boot a live image on sakura):

I think this install should go smoother. I'll follow [the same guide as last
time](https://ryanseipp.com/posts/nixos-automated-deployment/), however this
time I don't think SSH host keys will be an issue because now I'm using TPM for
age sops secrets. Theoretically I can boot live on Sakura, create the
age-plugin-tpm keypair, bring it into nixos-modules/secrets/default.yaml and
re-encrypt secrets.yaml to include this new key, and then things should just
work:tm:. We'll see how that goes

I booted the nixos live image and ran:
```
[root@nixos:~]# nix-shell -p age-plugin-tpm
[nix-shell:~]# age-plugin-tpm --generate
# Created: 2026-08-27 17:55:05.043813593 +0000 UTC m=+0.072939853
# Recipient: age1tag1qwwqw3srpq9nrjlch5m68cczrwu3jnd7jelart8qfkzwlsyh83dlw26ds98

AGE-PLUGIN-TPM-1QGQQQKQQYVQQKQQZQPEQQQQQZQQPJQQTQQPSQYQQYZWQW3SRPQ9NRJLCH5M68CCZRWU3JND7JELART8QFKZWLSYH83DLWQPQDYZCRDKUJWZGZF0ZS7EU8TTKJ65RSMSXAZL8WUNHEC7XR67HFXSSQLSQYQC4GPP8S3DC2EQCFYZ46YDD4GZ7CJLJMS5C50FGYTLNF8EHVS7QWQQS9NDREZTWUCQGEFUA4CM8K8QNCTEC3APASGYDZCPKSU6F2VXETSCUYVFHTVEF8QK4KVLLS03U73ARDYDM6XC4P2887JFQKTD3TKVUF2A3AJM4CD058D7VWJ6XH7F40RDHQ2CGJTKZFHVPQA7UQQ3QQZ6WKNN0DM9R38ME4HJE25GM0G7LQU9P6X0EG7SLRJCCMR4X7LTLX5FZJK5P
```

On sakura, I grabbed the `/dev/disk/by-id/...` path and updated disk-config.nix
(copied from sunflower) and also ran `nixos-generate-config
--show-hardware-config` and put the output into hardware-configuration.nix,
removing the filesystems configs.


~~With these repo changes, I went ahead and ran~~ didn't work:
```
nix run github:nix-community/nixos-anywhere -- --flake ".#sakura" --disk-encryption-keys /tmp/disk-encryption.key "$MYPASS" --build-on-remote "root@10.0.2.253"
```

After that completed, sakura didn't automatically reboot on it's own. Went ahead
and ran `sudo reboot` and caught the next boot menu with F2 to erase secure boot
settings. Hitting F10 to save and continue boot, apparently I don't have a boot
device. I guess nixos-anywhere didn't get the efi entry set up correctly?

~~Ah the issue was the command. This command took a lot more time~~ didn't work:
```
nix run github:nix-community/nixos-anywhere -- --flake ".#sakura" --disk-encryption-keys /tmp/secret.key "$MYPASS" --build-on-remote "root@10.0.2.253"
```

Turns out every part of the command I used to install sunflower was needed.
nixos-anywhere failed at lanzaboote install for
```
Failed to install generation 1: Failed to read public key from /var/lib/sbctl/keys/db/db.pem: No such file or directory (os error 2)
```

sakura:
```
[root@nixos:~]# nix-shell -p sbctl
[nix-shell:~]# sbctl create-keys
```

copy sakura /var/lib/sbctl/keys to local temp dir
```
❯ set EXTRAFILES $(mktemp -d)
❯ mkdir -p $EXTRAFILES/nix/persist/var/lib/sbctl
❯ mkdir -p $EXTRAFILES/var/lib/sbctl
❯ scp -r root@10.0.2.253:/var/lib/sbctl/keys/ $EXTRAFILES/nix/persist/var/lib/sbctl
❯ cp -r $EXTRAFILES/nix/persist/var/lib/sbctl/keys $EXTRAFILES/var/lib/sbctl
```

then ran:
```
nix run github:nix-community/nixos-anywhere -- --flake ".#sakura" --extra-files "$EXTRAFILES" --disk-encryption-keys /tmp/secret.key "$MYPASS" --build-on-remote "root@10.0.2.253"
```

nixos-anywhere rebooted the system and i booted straight into cosmic (after
entering FDE passphrase)

```
sudo systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2
# turns out /var/lib/sbctl/GUID is missing
# this command should basically be a no-op to recreate that file
sudo sbctl create-keys
```

now i should be good to go!