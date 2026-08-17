#!/bin/sh

shell="$(tmux show-option -gv default-shell 2>/dev/null)"
[ -n "$shell" ] || shell="${SHELL:-/bin/sh}"

case "$shell" in
    */fish)
        # Popup overlays pass these keys to the shell rather than through
        # tmux's normal prefix key table.
        exec "$shell" -i -C '
            bind --mode default ctrl-space,f "tmux display-popup -C"
            bind --mode default ctrl-space,w "tmux display-popup -C"
            bind --mode default ctrl-w "tmux display-popup -C"
            bind --mode insert ctrl-space,f "tmux display-popup -C"
            bind --mode insert ctrl-space,w "tmux display-popup -C"
            bind --mode insert ctrl-w "tmux display-popup -C"
        '
        ;;
    *)
        exec "$shell"
        ;;
esac
