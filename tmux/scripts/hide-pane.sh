#!/usr/bin/env bash
# Hide the active pane into a separate hidden session, preserving orientation
STATE_FILE="${HOME}/.tmux_hidden"

# Only hide if there’s more than one pane
if [ "$(tmux display -p '#{window_panes}')" -le 1 ]; then
  tmux display-message "Nothing to hide (only one pane in this window)."
  exit 0
fi

pane_id="$(tmux display -p '#{pane_id}')"
src_win="$(tmux display -p '#{session_name}:#{window_id}')"

win_w="$(tmux display -p '#{window_width}')"
win_h="$(tmux display -p '#{window_height}')"
pane_w="$(tmux display -p '#{pane_width}')"
pane_h="$(tmux display -p '#{pane_height}')"

# Determine orientation
# -v flag creates a vertical split (panes on top/bottom, pane is shorter)
# -h flag creates a horizontal split (panes left/right, pane is narrower)
if [ "$pane_h" -lt "$win_h" ]; then
  split="v"   # vertical split (pane is shorter)
elif [ "$pane_w" -lt "$win_w" ]; then
  split="h"   # horizontal split (pane is narrower)
else
  split="v"   # fallback
fi

# Create hidden session if not exists
if ! tmux has-session -t __HIDDEN__ 2>/dev/null; then
  tmux new-session -d -s __HIDDEN__
fi

# Save metadata
echo "${pane_id} ${src_win} ${split}" > "$STATE_FILE"

# Move pane to hidden session
tmux break-pane -s "$src_win" -t __HIDDEN__

tmux display-message "Pane hidden →  moved to hidden session (__HIDDEN__)."
