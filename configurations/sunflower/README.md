Documenting for my own future reference:

Command used to install sunflower was:

```
nix run github:nix-community/nixos-anywhere -- --extra-files $MY_KEYS --disk-encryption-keys /tmp/secret.key /tmp/secret.key --copy-host-keys --flake .#sunflower --target-host root@10.0.0.89
```

Followed https://ryanseipp.com/post/nixos-automated-deployment/ for information
on lanzaboote.

I'll need to write a script for future installs to preserve the ssh host keys
since impermanence isn't really respected during nixos-anywhere install. To
install sunflower I had to first do the nixos-anywhere install, then do another
nixos-rebuild switch after updating my secrets repo & this repo to take into
account the new host keys. probably a better way to do all this but it worked
