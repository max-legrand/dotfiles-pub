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

; #SingleInstance only covers one file path, so a copy started from somewhere
; else (e.g. the dotfiles repo) would run alongside and every key would fire
; twice. Run only from %AppData%\rex: started elsewhere, deploy this script and
; its helpers there, start that copy, and exit.
INSTALLED := EnvGet("APPDATA") "\rex\rex-prefix.ahk"
if (A_ScriptFullPath != INSTALLED) {
  DirCreate(EnvGet("APPDATA") "\rex")
  FileCopy(A_ScriptFullPath, INSTALLED, true)
  for helper in ["rex-run.lua", "rex-worker.lua"]
    if FileExist(A_ScriptDir "\" helper)
      FileCopy(A_ScriptDir "\" helper, EnvGet("APPDATA") "\rex\" helper, true)
  Run('"' A_AhkPath '" "' INSTALLED '"')
  ExitApp
}

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
  "s", ["send", "!k"],                 ; session_picker (config.ini: alt+k)
  '"', ["send", "^+d"],
  "z", ["send", "^+{Enter}"],          ; pane_maximize_toggle
  "X", ["send", "^+w"],                ; pane_close
  "w", ["send", "^+w"],
  "&", ["do", "srv_close_tab"],
  "r", ["send", "{F2}"],               ; tab_rename_prompt
  "R", ["send", "+{F2}"],              ; session_rename_prompt (config.ini: shift+f2)
  "S", ["send", "!k"],                 ; session_picker (config.ini: alt+k)
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
WORKER_LUA := EnvGet("APPDATA") "\rex\rex-worker.lua"

; The window title is "<pane title> - Rex" locally and
; "<pane title> - Rex (<host url>)" when the app is on a remote host.
; The pane title tells the server-side code which session is being shown.
RexTarget(&pane, &host) {
  title := WinGetTitle("A"), pane := "", host := ""
  if RegExMatch(title, "^(.*) - Rex(?: \((.+)\))?$", &m) {
    pane := m[1]
    host := m[2]
  }
}

RexExe(host) => '"' REX '"' (host != "" ? ' -S "' host '"' : "")

; One long-running rex-worker.lua per host, fed one command per line. It
; keeps its connection open and runs commands in order, so a key press costs
; ~5ms (local) or ~20ms (remote) instead of starting rex.exe each time.
; Workers share a hidden console so no window flashes; a dead worker
; (server restart, lost connection) is replaced on the next key press.
global Workers := Map()
Worker(host) {
  static consoleReady := false
  if Workers.Has(host) && Workers[host].Status = 0
    return Workers[host]
  if !consoleReady {
    DllCall("AllocConsole")
    DllCall("ShowWindow", "ptr", DllCall("GetConsoleWindow", "ptr"), "int", 0)
    consoleReady := true
  }
  WriteLog("starting worker for " (host != "" ? host : "local"))
  w := ComObject("WScript.Shell").Exec(RexExe(host) ' do "' WORKER_LUA '"')
  Workers[host] := w
  return w
}

RexDo(action) {
  RexTarget(&pane, &host)
  RexSend(host, action "`t" pane)
}

RexSend(host, line) {
  WriteLog("do " StrReplace(line, "`t", " | ") " | " (host != "" ? host : "local"))
  try {
    Worker(host).StdIn.WriteLine(line)
  } catch as e {
    ; The worker died between the status check and the write: retry once
    ; with a fresh one.
    WriteLog("worker write failed (" e.Message "), restarting")
    Workers.Delete(host)
    Worker(host).StdIn.WriteLine(line)
  }
}

; Used when the next step must wait for the action (scrollback, then show
; its new tab): a one-shot rex.exe running rex-run.lua.
RexDoWait(action) {
  RexTarget(&pane, &host)
  cmd := RexExe(host) ' do "' RUN_LUA '" "title=' StrReplace(pane, '"', '\"') '" action=' action
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
