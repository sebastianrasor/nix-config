if status is-interactive; and not functions -q __direnv_export_eval
    direnv hook fish | source
end
