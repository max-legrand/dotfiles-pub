; rex-prefix.ahk - tmux-style Ctrl+Space prefix for the Rex Windows app.
;
; The Windows app (rex-native 0.1.1) doesn't run init.lua's key bindings, so:
;   - single-key shortcuts live in the app's own config.ini [keybinds]
;   - this script handles the Ctrl+Space prefix. For the app's own actions it
;     presses the app's native shortcut (instant); for actions that only exist
;     in init.lua it runs `rex.exe do <action>` in the background.
;
;   Ctrl+Space, <key>    run the prefix action for <key> (Ctrl may stay held)
;   Ctrl+Space, Space    send a literal Ctrl+Space to the terminal
;   Ctrl+Space, Esc      cancel
;   Ctrl+Shift+Space     toggle tmux passthrough (Ctrl+Space goes to tmux)
;   Ctrl+F               floating session shell (init.lua action)
;   Ctrl+H/J/K/L         focus pane (init.lua focus_pane_* actions)
;
; Only these exact key combos are taken; every other key reaches the app.
; Requires AutoHotkey v2. Only active while a Rex window is focused.

#Requires AutoHotkey v2.0
#SingleInstance Force

REX := EnvGet("LOCALAPPDATA") "\Programs\Rex\rex.exe"
global Passthrough := false

; Second key -> ["send", keys] (an app shortcut from config.ini, "^" = Ctrl,
; "+" = Shift, "!" = Alt) or ["do", "action args"] (an init.lua action).
; "do_last" waits for the action, then shows the last tab (tab_select_last,
; Ctrl+Shift+9): the server can't change which tab the app is showing.
; Case-sensitive: "T" is Shift+T. Shifted punctuation is the character typed.
PREFIX := Map(
  "t", ["send", "^+t"],                ; tab_new
  "c", ["send", "^+t"],
  "n", ["send", "^e"],                 ; tab_next
  "p", ["send", "^q"],                 ; tab_prev
  "v", ["send", "^d"],                 ; pane_split:right
  "%", ["send", "^d"],
  "s", ["send", "^+d"],                ; pane_split:down
  '"', ["send", "^+d"],
  "z", ["send", "^+{Enter}"],          ; pane_maximize_toggle
  "X", ["send", "^+w"],                ; pane_close
  "w", ["send", "^+w"],
  "&", ["do", "srv_close_tab"],
  "r", ["send", "{F2}"],               ; tab_rename_prompt
  "R", ["send", "^!+r"],               ; session_rename_prompt
  "S", ["send", "^!+s"],               ; session_picker
  "T", ["send", "^+s"],                ; tab_style_toggle
  "<", ["send", "^+{PgUp}"],           ; tab_move_backward
  ">", ["send", "^+{PgDn}"],           ; tab_move_forward
  "h", ["do", "swap_pane_left"],
  "j", ["do", "swap_pane_down"],
  "k", ["do", "swap_pane_up"],
  "l", ["do", "swap_pane_right"],
  "x", ["do_last", "srv_scrollback_nvim"],  ; opens a new tab, then show it
  "3", ["do", "three_columns"],
  "f", ["do", "floating_tab_shell"],
  "u", ["do", "session_order_up"],
  "d", ["do", "session_order_down"],
  "Y", ["do", "apply_usgc_polyminimal_theme"],
)

LOG_FILE := EnvGet("TEMP") "\rex-prefix.log"
WriteLog(msg) {
  FileAppend(FormatTime(, "HH:mm:ss") " " msg "`n", LOG_FILE)
}

RUN_LUA := EnvGet("APPDATA") "\rex\rex-run.lua"

; Build `rex.exe [-S HOST] do rex-run.lua title=... action=NAME [args]`.
; The window title is "<pane title> - Rex" locally and
; "<pane title> - Rex (<host url>)" when the app is on a remote host;
; rex-run.lua uses the pane title to find the session being shown.
RexCmd(action) {
  title := WinGetTitle("A"), pane := "", host := ""
  if RegExMatch(title, "^(.*) - Rex(?: \((.+)\))?$", &m) {
    pane := m[1]
    host := m[2]
  }
  cmd := '"' REX '"'
  if (host != "")
    cmd .= ' -S "' host '"'
  cmd .= ' do "' RUN_LUA '" "title=' StrReplace(pane, '"', '\"') '" action=' action
  return cmd
}

RexDo(action) {
  cmd := RexCmd(action)
  WriteLog("do " cmd)
  Run(cmd, , "Hide")
}

RexDoWait(action) {
  cmd := RexCmd(action)
  WriteLog("do (wait) " cmd)
  RunWait(cmd, , "Hide")
}

IsRex() => WinActive("ahk_exe rex.exe")

#HotIf IsRex()
^+Space:: {
  global Passthrough := !Passthrough
  ToolTip(Passthrough ? "tmux passthrough ON" : "tmux passthrough off", 10, 10)
  SetTimer(() => ToolTip(), -1500)
}

^f:: RexDo("floating_session_shell")

; Pane focus with init.lua's "return to the pane you came from" logic.
; config.ini binds the same keys to the app's geometric focus as a fallback
; for when this script isn't running.
^h:: RexDo("focus_pane_left")
^j:: RexDo("focus_pane_down")
^k:: RexDo("focus_pane_up")
^l:: RexDo("focus_pane_right")

#HotIf IsRex() && !Passthrough
^Space:: {
  WriteLog("prefix pressed (window: " WinGetTitle("A") ")")
  ToolTip("Rex ▸", 10, 10)
  ih := InputHook("L1 T3 M", "{Escape}")
  ih.Start()
  ih.Wait()
  ToolTip()
  key := ih.Input
  WriteLog("input=" (key = "" ? "<none: " ih.EndReason ">" : "chr " Ord(key)))
  if (key = "")
    return
  ; With Ctrl still held, M turns letters into control characters (Ctrl+T
  ; is chr 20). Map them back to the plain letter.
  code := Ord(key)
  if (code >= 1 && code <= 26)
    key := Chr(code + 96)
  if (key = " ") {
    Send("^{Space}")
    return
  }
  if !PREFIX.Has(key)
    return
  entry := PREFIX[key]
  ; Let go of Ctrl/Shift the user may still be holding, so the app sees
  ; exactly the shortcut we send.
  KeyWait("Ctrl"), KeyWait("Shift")
  if (entry[1] = "do_last") {
    RexDoWait(entry[2])
    Send("^+9")
    return
  }
  if (entry[1] = "send") {
    WriteLog("send " entry[2])
    Send(entry[2])
  }
  else
    RexDo(entry[2])
}
#HotIf
