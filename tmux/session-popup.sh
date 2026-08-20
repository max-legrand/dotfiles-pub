#!/bin/sh
# Per-session popup shell, backed by a persistent tmux session so its contents
# (scrollback, shell history, running jobs) survive close/reopen.
#
# Same trick as tab-popup.sh, one scope up: every tmux session gets its own
# hidden companion session (SESSPOPUP_<session_id>) on the same server, and the
# popup just attaches to it — closing the popup only detaches.
#
# Bound to C-f: pressing it inside the popup detaches (toggles it shut).

width=${1:-80%}
height=${2:-80%}

session="$(tmux display-message -p -F '#{session_name}')"

# Already inside a session popup -> toggle it closed.
case "$session" in
    SESSPOPUP_*)
        tmux detach-client
        exit 0
        ;;
esac

session_id="$(tmux display-message -p -F '#{session_id}')"   # e.g. $3
pane_path="$(tmux display-message -p -F '#{pane_current_path}')"
name="SESSPOPUP_${session_id#\$}"

# Reap popup sessions whose parent session is gone (prune lazily on each open,
# same as tab-popup.sh). A leading '$' makes the target a session id.
tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^SESSPOPUP_' | while read -r s; do
    tmux has-session -t "\$${s#SESSPOPUP_}" 2>/dev/null || tmux kill-session -t "=$s"
done

if ! tmux has-session -t "=$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$pane_path"
fi
# after-new-session turns the status bar back on; keep it off for popups.
tmux set-option -t "=$name" status off

tmux popup -d "$pane_path" -xC -yC -w"$width" -h"$height" -b rounded \
    -E "tmux attach -t '=$name'"
