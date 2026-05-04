#!/bin/sh
dir="$1"
src=$(tmux display-message -p '#{pane_id}')
tmux select-pane -"$dir" || exit 0
dst=$(tmux display-message -p '#{pane_id}')
[ "$src" = "$dst" ] && exit 0
tmux swap-pane -s "$src" -t "$dst"
tmux select-pane -t "$src"
