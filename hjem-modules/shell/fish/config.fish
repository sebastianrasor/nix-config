if status is-interactive
    abbr --add --function last_history_item --position anywhere -- !!
    abbr --add --command nix --regex search -- nix-search 'search nixpkgs'
    abbr --add --command nix --regex shell --set-cursor -- nix-shell 'shell nixpkgs#% -c fish'
    abbr --add -- yssh 'ssh-keygen -K && rename _sk_rk _sk id_ed25519_sk_rk* && mv id_ed25519_sk* ~/.ssh'

    abbr --add -- cat bat
    abbr --add -- top btm
    abbr --add -- df dysk

    alias eza 'eza --group-directories-first --header'
    alias la 'eza -a'
    alias ll 'eza -l'
    alias lla 'eza -la'
    alias ls eza
    alias lt 'eza --tree'
    abbr --add -- ls eza
    abbr --add -- tree 'eza --tree'

    zoxide init fish | source
end
