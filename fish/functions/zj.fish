function zj --description "Start a new zellij session with auto-incrementing numeric name"
    set -l count (zellij list-sessions -n 2>/dev/null | grep -cv "EXITED")
    set -l next (math $count + 1)
    zellij -s $next $argv
end
