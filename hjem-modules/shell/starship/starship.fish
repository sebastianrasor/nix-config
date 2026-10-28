if status is-interactive; and test "$TERM" != dumb
    starship init fish | source
    enable_transience
end
