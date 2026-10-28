if status is-interactive
    abbr --add --function last_history_item --position anywhere -- !!
    abbr --add --command nix --regex search -- nix-search 'search nixpkgs'
    abbr --add --command nix --regex shell --set-cursor -- nix-shell 'shell nixpkgs#% -c fish'
    abbr --add -- yssh 'ssh-keygen -K && rename _sk_rk _sk id_ed25519_sk_rk* && mv id_ed25519_sk* ~/.ssh'
end
