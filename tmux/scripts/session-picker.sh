#!/bin/sh
HL="#CDC1FF"
selected=$(tmux list-sessions \
  -f '#{?#{==:#{session_name},__HIDDEN__},0,#{?#{==:#{session_name},popup},0,1}}' \
  -F '#{session_name}' \
  | fzf-tmux -p 50%,40% \
       --layout=default --no-info --no-clear \
       --color "fg:#DDDDDD,hl:$HL,fg+:$HL,hl+:$HL,info:#898989,prompt:$HL,pointer:$HL,marker:$HL,spinner:#66A5AD,header:#EC8FB0,border:#403833")
[ -n "$selected" ] && tmux switch-client -t "$selected"
exit 0
