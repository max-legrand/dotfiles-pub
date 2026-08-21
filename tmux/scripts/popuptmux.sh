#!/bin/sh
width=${1:-80%}
height=${2:-80%}
if [ "$(tmux display-message -p -F "#{session_name}")" = "popup" ]; then
    tmux detach-client
else
    pane_path="$(tmux display-message -p -F "#{pane_current_path}")"
    # Ensure the popup session exists
    if ! tmux has-session -t popup 2>/dev/null; then
        tmux new-session -d -s popup
    fi
    # Disable status bar for the popup session
    tmux set -t popup status off
    tmux set-environment -t popup TMUX_POPUP global
    # Border title + colour identify which of the three popup scopes this is.
    tmux popup -d "$pane_path" -xC -yC -w"$width" -h"$height" -b rounded \
        -S "fg=#ec8fb0" -T " global " -E "tmux attach -t popup"
fi
