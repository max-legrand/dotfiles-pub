#!/usr/bin/env sh
# Installs the xterm-ghostty terminfo for the current user, so TUI programs
# (zellij, tmux, vim) know what the terminal can do. Run this INSIDE the WSL
# distro Ghostty connects to. No root needed; it writes to ~/.terminfo.
set -e
dir=$(cd "$(dirname "$0")" && pwd)
tic -x -o "$HOME/.terminfo" "$dir/ghostty.terminfo"
echo "installed. verify with: infocmp xterm-ghostty >/dev/null && echo ok"
