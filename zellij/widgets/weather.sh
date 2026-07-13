#!/usr/bin/env bash
# zjstatus weather widget — wraps the dracula/tmux weather script
# (zjstatus splits commands on whitespace with no shell quoting, so the
#  "Philadelphia PA" arg has to live here)
exec bash ~/.tmux/plugins/tmux/scripts/weather.sh true false "Philadelphia PA" true
