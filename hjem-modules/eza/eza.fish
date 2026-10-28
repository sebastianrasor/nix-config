if status is-interactive
    alias eza 'eza --group-directories-first --header'
    alias la 'eza -a'
    alias ll 'eza -l'
    alias lla 'eza -la'
    alias ls eza
    alias lt 'eza --tree'
    abbr --add -- ls eza
    abbr --add -- tree 'eza --tree'
end
