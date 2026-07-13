#!/usr/bin/env bash
# Invisible zjstatus widget (runs every few seconds from the status bar):
# recreates the tmux auto-uppercase rename hooks. Uppercases the session name
# and the focused tab's name (the CLI can only rename the focused tab; other
# tabs get fixed whenever they gain focus).
[ -n "$ZELLIJ_SESSION_NAME" ] || exit 0

u=$(printf '%s' "$ZELLIJ_SESSION_NAME" | tr '[:lower:]' '[:upper:]')
[ "$u" != "$ZELLIJ_SESSION_NAME" ] && zellij action rename-session "$u" >/dev/null 2>&1

t=$(zellij action dump-layout 2>/dev/null | grep '^    tab .*focus=true' | sed 's/.*name="\([^"]*\)".*/\1/' | head -1)
if [ -n "$t" ]; then
    ut=$(printf '%s' "$t" | tr '[:lower:]' '[:upper:]')
    [ "$ut" != "$t" ] && zellij action rename-tab "$ut" >/dev/null 2>&1
fi
exit 0
