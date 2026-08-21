#!/bin/sh
# Per-tab popup shell, backed by a persistent tmux session so its contents
# (scrollback, shell history, running jobs) survive close/reopen.
#
# display-popup spawns a fresh process every time it is opened, so running the
# shell directly inside the popup loses everything on close. Instead each tmux
# window gets its own hidden session (TABPOPUP_<window_id>) on the same server,
# and the popup just attaches to it — closing the popup only detaches.
#
# Bound to prefix + f: pressing it inside the popup detaches (toggles it shut).

width=${1:-80%}
height=${2:-80%}

session="$(tmux display-message -p -F '#{session_name}')"

# Already inside a tab popup -> toggle it closed.
case "$session" in
    TABPOPUP_*)
        tmux detach-client
        exit 0
        ;;
esac

window_id="$(tmux display-message -p -F '#{window_id}')"   # e.g. @7
pane_path="$(tmux display-message -p -F '#{pane_current_path}')"
name="TABPOPUP_${window_id#@}"

# Reap popup sessions whose window is gone (tmux has no reliable
# window-destroyed hook, so prune lazily on each open).
live="$(tmux list-windows -a -F '#{window_id}' | tr '\n' ' ')"
tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^TABPOPUP_' | while read -r s; do
    case " $live " in
        *" @${s#TABPOPUP_} "*) ;;
        *) tmux kill-session -t "=$s" ;;
    esac
done

if ! tmux has-session -t "=$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$pane_path" -e TMUX_POPUP=tab
fi
# after-new-session turns the status bar back on; keep it off for popups.
tmux set-option -t "=$name" status off
# Also set on existing sessions, not just new ones (see -e above).
tmux set-environment -t "=$name" TMUX_POPUP tab

# Border title + colour identify which of the three popup scopes this is.
# '#' is a format introducer in titles, so double it in the parent's name.
window_name="$(tmux display-message -p -F '#{window_name}')"
title=" tab · $(printf '%s' "$window_name" | sed 's/#/##/g') "

tmux popup -d "$pane_path" -xC -yC -w"$width" -h"$height" -b rounded \
    -S "fg=#66a5ad" -T "$title" \
    -E "tmux attach -t '=$name'"
