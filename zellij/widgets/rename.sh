#!/usr/bin/env bash
# Rename prompt ($1 = session|tab). Uppercases the name, like the tmux
# auto-uppercase hooks. Runs as an IN-PLACE pane (temporarily replaces the
# focused pane): floating panes are never involved, so the hidden Ctrl+f
# popup stays hidden. The pane closes itself via close_on_exit, restoring
# the original pane.
kind=$1
printf 'rename %s: ' "$kind"
IFS= read -r name
[ -n "$name" ] && zellij action "rename-$kind" "$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')"
exit 0
