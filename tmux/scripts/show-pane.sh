#!/usr/bin/env bash
# Restore the last hidden pane from the hidden session
STATE_FILE="${HOME}/.tmux_hidden"

if [ ! -f "$STATE_FILE" ]; then
  tmux display-message "No hidden pane recorded."
  exit 0
fi

read -r pane_id src_win split < "$STATE_FILE"

# Verify the hidden pane still exists
if ! tmux list-panes -a -F '#{pane_id}' | grep -qx "$pane_id"; then
  tmux display-message "Hidden pane no longer exists."
  rm -f "$STATE_FILE"
  exit 0
fi

# Verify the target window still exists
if ! tmux list-windows -a -F '#{session_name}:#{window_id}' | grep -qx "$src_win"; then
  src_win="$(tmux display -p '#{session_name}:#{window_id}')"
fi

# Restore the pane with its orientation
if [ "$split" = "v" ]; then
  tmux join-pane -v -s "$pane_id" -t "$src_win"
else
  tmux join-pane -h -s "$pane_id" -t "$src_win"
fi

tmux switch-client -t "$src_win"
tmux select-pane -t "$pane_id"

rm -f "$STATE_FILE"
tmux display-message "Pane restored to $src_win with original orientation."
