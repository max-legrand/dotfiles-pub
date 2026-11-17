-- ~/.config/rex/init.lua
--
-- tmux-flavoured Rex config: pane focus / swap / resize, prefix sequences,
-- floating layers, and a tmux passthrough toggle.
--
-- Reload after editing:  rex config reload

local shell = "com.superlogical.terminal.shell"

-- Ctrl+Q/E: false wraps within this session; true uses Rex's tab navigation
-- across sessions in sidebar mode. Ctrl+Space, Shift+N toggles and saves it.
local TAB_NAV_ACROSS_SESSIONS = true

-- Rex's prefix, as a key sequence.
local p = "ctrl+space>"

-- == tmux passthrough ========================================================
-- Rex and tmux want the same keys (Ctrl+Space above all, plus C-hjkl,
-- C-S-hjkl, M-C-hjkl, C-f). A Rex prefix is a key *sequence*, and a sequence
-- consumes its first key, so Rex has to stop binding Ctrl+Space entirely for
-- tmux to receive it.
--
-- Rex cannot bind or unbind at runtime, but the server can reload the config,
-- so a toggle edits this file and asks for a reload. While passthrough is on
-- this file installs no bindings at all, so every key reaches the focused
-- terminal. No key mode is used, so the app's "pending keys" indicator never
-- appears.
--
-- The state is the marker line just below. It has to live in THIS file rather
-- than a side file: a reload whose config hash is unchanged is ignored by
-- clients - they keep their cached keymap - so the toggle must change the file
-- to make clients re-fetch.
--
--   Ctrl+Shift+Space   toggle tmux passthrough
-- tmux-mode: off
local CONFIG_PATH  = (os.getenv("HOME") or ".") .. "/.config/rex/init.lua"
local REX_BIN      = [[/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex]]

local function config_source()
  local f = io.open(CONFIG_PATH)
  if not f then return "" end
  local src = f:read("*a")
  f:close()
  return src
end

local tmux_mode = config_source():match("\n%-%- tmux%-mode: (%a+)") == "on"

-- Install a binding unless tmux passthrough is on.
local function rb(...)
  if not tmux_mode then rex.bind(...) end
end

-- The app's one in-app popup is the "pending keys" overlay it draws while a
-- key MODE is active (this is the box that appeared for the old tmux mode).
-- Shown for the new state on both Ctrl+Shift+Space (toggle) and Ctrl+Shift+T
-- (status only), then dismissed after ~2s by a helper process. Its position
-- follows the app's Settings > Notifications > "Notification position".
--
-- A mode only exists once it has a binding, so it must list at least one row.
-- Bind the same key that opens the popup, so that row doubles as "press again
-- to dismiss" - and in particular there is no Escape row.
-- The box is shown while passthrough is on and goes away when it is turned
-- off, so there is nothing to schedule and no helper process (and no banner).
--
-- Escape has to be bound, or the app's built-in "Escape leaves the mode" would
-- drop the box the first time you press Escape in tmux. It is bound to
-- *forwarding*, so Escape still reaches tmux. A mode needs at least one
-- binding, so that single row is the unavoidable price of a box that stays.
rex.mode("tmux-on")
rex.bind("tmux-on/escape", "client.key.forward")

-- Show the box while passthrough is on; leave it when passthrough goes off.
local function show_status(ctx, on)
  if ctx.origin ~= "key" and ctx.origin ~= "palette" then return end
  rex.client.queue("client.mode.exit_all")
  if on then
    rex.client.queue("client.mode.enter", { name = "tmux-on" })
  end
end

rex.action{
  name  = "tmux_passthrough_toggle",
  title = "Toggle tmux Passthrough",
  run = function(ctx)
    local src = config_source()
    src = src:gsub("%-%- tmux%-mode: %a+",
                   "-- tmux-mode: " .. (tmux_mode and "off" or "on"), 1)
    local f = io.open(CONFIG_PATH, "w")
    f:write(src)
    f:close()
    -- Show the popup for the state we just switched to, then dismiss it.
    show_status(ctx, not tmux_mode)
    -- Reload after the action returns: reloading while it runs cancels it.
    rex.exec{ "sh", "-c", '(sleep 0.5; "$0" config reload) >/dev/null 2>&1 &', REX_BIN }
  end,
}

-- Always bound, so it works in both states.
rex.bind("ctrl+shift+space", "tmux_passthrough_toggle")

-- == ALL-CAPS session / tab names ============================================
-- The config can't hear rename events, so a long-lived `rex do` script
-- (upper-labels.lua) re-labels renamed sessions/tabs in upper case. Start it
-- once in the background; the pgrep guard keeps reloads from stacking copies.
local UPPER_SCRIPT = (os.getenv("HOME") or ".") .. "/.config/rex/upper-labels.lua"
rex.exec{ "sh", "-c",
  'pgrep -f "upper-labels.lua" >/dev/null || (nohup "$0" do "$1" --all >/tmp/rex-upper-labels.log 2>&1 &)',
  REX_BIN, UPPER_SCRIPT }

-- == Helpers =================================================================

local function active_window(view)
  for _, w in ipairs(view.windows or {}) do
    if w.window_id == view.active_window_id then return w end
  end
end

-- Rectangles are stored on layout leaves, not in layer.blocks. Rex currently
-- reports them as {x, y, w, h} arrays (older views used named fields).
local function layout_blocks(node, blocks)
  if not node then return end
  if node.split then
    layout_blocks(node.split.before, blocks)
    layout_blocks(node.split.after, blocks)
  elseif node.block_id and node.rect then
    local r = node.rect
    blocks[#blocks + 1] = {
      block_id = node.block_id,
      rect = { x = r.x or r[1], y = r.y or r[2],
               w = r.w or r[3], h = r.h or r[4] },
    }
  end
end

local function center(r) return r.x + r.w / 2, r.y + r.h / 2 end

-- Nearest block in `dir` that overlaps `me` on the perpendicular axis.
local function neighbor_in(blocks, me, dir)
  local mx, my = center(me.rect)
  local best, best_d
  for _, b in ipairs(blocks) do
    if b.block_id ~= me.block_id then
      local bx, by = center(b.rect)
      local ahead =
        (dir == "left"  and bx < mx) or
        (dir == "right" and bx > mx) or
        (dir == "up"    and by < my) or
        (dir == "down"  and by > my)
      if ahead then
        local overlap
        if dir == "left" or dir == "right" then
          overlap = math.min(me.rect.y + me.rect.h, b.rect.y + b.rect.h)
                  - math.max(me.rect.y, b.rect.y)
        else
          overlap = math.min(me.rect.x + me.rect.w, b.rect.x + b.rect.w)
                  - math.max(me.rect.x, b.rect.x)
        end
        if overlap > 0 then
          local d
          if dir == "left" then d = mx - bx
          elseif dir == "right" then d = bx - mx
          elseif dir == "up" then d = my - by
          else d = by - my end
          if not best_d or d < best_d then best_d, best = d, b end
        end
      end
    end
  end
  return best
end

-- == Pane focus (tmux: bind -n C-h/j/k/l select-pane) ========================

-- Native pane.focus only considers geometry: in A/B | C it can choose A
-- when moving left from C even if we arrived from B. Remember which pane we
-- entered from for each return direction, across config reloads as well.
local FOCUS_STATE = (os.getenv("HOME") or ".") .. "/.config/rex/pane-focus-state.tsv"
local opposite = { left = "right", right = "left", up = "down", down = "up" }

local function load_focus_state()
  local state = {}
  local f = io.open(FOCUS_STATE, "r")
  if not f then return state end
  for line in f:lines() do
    local window, source, dir, target = line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)$")
    if window and opposite[dir] then
      state[window] = state[window] or {}
      state[window][source] = state[window][source] or {}
      state[window][source][dir] = target
    end
  end
  f:close()
  return state
end

local function save_focus_state(state)
  local tmp = FOCUS_STATE .. ".tmp"
  local f, err = io.open(tmp, "w")
  if not f then error(err, 0) end
  for window, panes in pairs(state) do
    for source, directions in pairs(panes) do
      for dir, target in pairs(directions) do
        f:write(window, "\t", source, "\t", dir, "\t", target, "\n")
      end
    end
  end
  f:close()
  local ok, rename_err = os.rename(tmp, FOCUS_STATE)
  if not ok then error(rename_err, 0) end
end

local function in_direction(from, to, dir)
  local fx, fy = center(from.rect)
  local tx, ty = center(to.rect)
  if dir == "left" or dir == "right" then
    return (dir == "left" and tx < fx or dir == "right" and tx > fx)
       and math.min(from.rect.y + from.rect.h, to.rect.y + to.rect.h)
         > math.max(from.rect.y, to.rect.y)
  end
  return (dir == "up" and ty < fy or dir == "down" and ty > fy)
     and math.min(from.rect.x + from.rect.w, to.rect.x + to.rect.w)
       > math.max(from.rect.x, to.rect.x)
end

local function define_focus(dir, key)
  local name = "focus_pane_" .. dir
  rex.action{
    name = name,
    title = "Focus Pane " .. dir,
    category = "Panes",
    repeats = true,
    run = function(ctx)
      local win = active_window(rex.session.view{})
      if not win or not win.focused_block_id then return end
      local from = win.focused_block_id
      local blocks = {}
      for _, layer in ipairs(win.layers or {}) do
        local leaves = {}
        layout_blocks(layer.layout, leaves)
        for _, b in ipairs(leaves) do blocks[b.block_id] = b end
      end
      local state = load_focus_state()
      local panes = state[win.window_id] or {}
      local preferred = panes[from] and blocks[panes[from][dir]]
      local result, err
      if blocks[from] and preferred and in_direction(blocks[from], preferred, dir) then
        result, err = rex.session.focus_block{ block_id = preferred.block_id }
      else
        result, err = rex.session.focus_direction{ direction = dir, wrap = false }
      end
      if err then error(err, 0) end
      local dest = active_window(rex.session.view{})
      if dest and dest.focused_block_id and dest.focused_block_id ~= from then
        panes[dest.focused_block_id] = panes[dest.focused_block_id] or {}
        panes[dest.focused_block_id][opposite[dir]] = from
        state[win.window_id] = panes
        save_focus_state(state)
      end
    end,
  }
  rb(key, name)
end

define_focus("left", "ctrl+h")
define_focus("down", "ctrl+j")
define_focus("up", "ctrl+k")
define_focus("right", "ctrl+l")

-- Ctrl+; clears the terminal, the same key your tmux binds to `send-keys C-l`.
-- For a full wipe including scrollback, use the terminal.clear block method
-- instead (see below).
rb("ctrl+;", "pane.send_key", { key = "ctrl+l" })

-- == Pane resize (tmux: M-C-h/j/k/l resize-pane 5, C-S-h/j/k/l resize-pane 3) ==

rb("ctrl+alt+h", "pane.resize", { direction = "left",  amount = 5 })
rb("ctrl+alt+j", "pane.resize", { direction = "down",  amount = 5 })
rb("ctrl+alt+k", "pane.resize", { direction = "up",    amount = 5 })
rb("ctrl+alt+l", "pane.resize", { direction = "right", amount = 5 })

rb("ctrl+shift+h", "pane.resize", { direction = "left",  amount = 3 })
rb("ctrl+shift+j", "pane.resize", { direction = "down",  amount = 3 })
rb("ctrl+shift+k", "pane.resize", { direction = "up",    amount = 3 })
rb("ctrl+shift+l", "pane.resize", { direction = "right", amount = 3 })

-- == Pane swap (tmux: prefix + h/j/k/l swap-pane.sh L/D/U/R) =================
-- Rex has no "swap with neighbour" primitive; find the neighbour from the
-- layout geometry, then call session.swap_blocks. Focus follows the pane.

local function define_swap(name, dir)
  rex.action{
    name     = name,
    title    = "Swap Pane " .. string.upper(string.sub(dir, 1, 1)) .. string.sub(dir, 2),
    category = "Panes",
    run = function(ctx)
      local view = rex.session.view{}
      local win = active_window(view)
      if not win then return end
      local blocks = {}
      for _, layer in ipairs(win.layers or {}) do
        layout_blocks(layer.layout, blocks)
      end
      local me
      for _, b in ipairs(blocks) do
        if b.block_id == win.focused_block_id then me = b; break end
      end
      if not me then return end
      local other = neighbor_in(blocks, me, dir)
      if not other then return end
      rex.session.swap_blocks{
        block_id       = me.block_id,
        other_block_id = other.block_id,
      }
    end,
  }
end

define_swap("swap_pane_left",  "left")
define_swap("swap_pane_right", "right")
define_swap("swap_pane_up",    "up")
define_swap("swap_pane_down",  "down")

rb(p .. "h", "swap_pane_left")
rb(p .. "j", "swap_pane_down")
rb(p .. "k", "swap_pane_up")
rb(p .. "l", "swap_pane_right")

-- == Splits, close, zoom, tabs (tmux prefix bindings) ========================
-- tmux % = split right, " = split down; the config also binds s/v like tmux's
-- extra split keys. Shifted punctuation is written without shift applied.

rb(p .. "v",       "pane.split", { direction = "right" })
rb(p .. "shift+5", "pane.split", { direction = "right" })   -- %
rb(p .. "s",       "pane.split", { direction = "down" })
rb(p .. "shift+'", "pane.split", { direction = "down" })    -- "

rb(p .. "z", "pane.zoom")
rb(p .. "c", "client.tab.new")
rb(p .. "t", "client.tab.new")
-- Ctrl+Space, Shift+T: switch between top tabs and the sidebar layout.
rb(p .. "shift+t", "client.tab_style.toggle")
rb(p .. "n", "client.tab.next")
rb(p .. "p", "client.tab.previous")

-- Ctrl+Q / Ctrl+E: previous / next tab, no prefix. These take the keys from
-- the shell (ctrl+e is end-of-line in most shells); use End or the arrow keys
-- there instead. tmux passthrough (rb) frees them again.
-- Rex's key-mode overlay provides an in-app status popup. Both modes stay
-- defined across reloads; Escape dismisses the popup without reaching the shell.
local TAB_SCOPE_SESSION = "tabs-current-session-only"
local TAB_SCOPE_ALL = "tabs-across-all-sessions"
for _, name in ipairs({ TAB_SCOPE_SESSION, TAB_SCOPE_ALL }) do
  rex.mode(name)
  rex.bind(name .. "/escape", "client.mode.exit")
end

-- Like tmux passthrough, save the toggle and reload after the action returns.
rex.action{
  name = "toggle_tab_navigation_scope",
  title = "Toggle Tab Navigation Across Sessions",
  category = "Tab",
  run = function()
    local src, count = config_source():gsub(
      "local TAB_NAV_ACROSS_SESSIONS = %a+",
      "local TAB_NAV_ACROSS_SESSIONS = " .. tostring(not TAB_NAV_ACROSS_SESSIONS),
      1
    )
    if count ~= 1 then error("Tab navigation setting not found", 0) end
    local f, err = io.open(CONFIG_PATH, "w")
    if not f then error(err, 0) end
    local ok, write_err = f:write(src)
    local closed, close_err = f:close()
    if not ok then error(write_err, 0) end
    if not closed then error(close_err, 0) end
    rex.client.queue("client.mode.exit_all")
    rex.client.queue("client.mode.enter", {
      name = TAB_NAV_ACROSS_SESSIONS and TAB_SCOPE_SESSION or TAB_SCOPE_ALL,
    })
    rex.exec{ "sh", "-c", '(sleep 0.5; "$0" config reload) >/dev/null 2>&1 &', REX_BIN }
  end,
}
rb(p .. "shift+n", "toggle_tab_navigation_scope")

-- Session-local actions are used unless TAB_NAV_ACROSS_SESSIONS is enabled.
for _, nav in ipairs({
  { key = "ctrl+q", name = "session_tab_previous", step = -1 },
  { key = "ctrl+e", name = "session_tab_next", step = 1 },
}) do
  rex.action{
    name = nav.name,
    title = nav.name == "session_tab_previous" and "Previous Tab in Session"
      or "Next Tab in Session",
    category = "Tab",
    repeats = true,
    run = function()
      local view, err = rex.session.view{}
      if err then error(err, 0) end
      local windows = view.windows or {}
      for i, window in ipairs(windows) do
        if window.window_id == view.active_window_id then
          local target = windows[(i - 1 + nav.step) % #windows + 1]
          rex.client.queue("session.select", {
            session_id = view.session_id,
            window_id = target.window_id,
          })
          return
        end
      end
    end,
  }
  local action = nav.name
  if TAB_NAV_ACROSS_SESSIONS then
    action = nav.step == -1 and "client.tab.previous" or "client.tab.next"
  end
  rb(nav.key, action)
end

-- Ctrl+1..9 jump straight to tab N (client.tab.goto is 1-based).
for i = 1, 9 do
  rb("ctrl+" .. i, "client.tab.goto", { index = i })
end

-- tmux: prefix + < / >  (swap-window -t -1 / +1) - nudge the current tab.
-- Keys are written without shift applied, so `<` is shift+, and `>` is shift+.
-- (same style as prefix+shift+5 / shift+' above).
rb(p .. "shift+,", "client.tab.move.backward")
rb(p .. "shift+.", "client.tab.move.forward")
rb(p .. "r",       "client.tab.rename")
rb(p .. "shift+r", "session.rename")

-- Fuzzy session picker in a floating terminal. fzf runs in the terminal so
-- it gets a real TTY. The switch itself must come from an action the app
-- runs (a key press): a switch sent from the picker with `rex -C ... do
-- session.select` goes through Remote Control, and the app then shows a
-- "rex: Go to Session" label. So while the picker is open, the "picker" key
-- mode routes Enter (and Escape / Ctrl-C) through actions: Enter types the
-- key into fzf, waits for the picker to write the chosen session ID to a
-- file, then queues session.select as the app. Every other key falls
-- through to fzf as usual (the mode isn't exclusive).
local PICKER_BLOCK  = "/tmp/rex-picker.block"
local PICKER_RESULT = "/tmp/rex-picker.result"

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

-- Type `data` into the focused terminal; true if that terminal is the picker.
local function picker_key(ctx, data)
  if ctx.block_id then
    rex.block.call("com.superlogical.terminal", "write",
      { block_id = ctx.block_id, data = data })
  end
  return ctx.block_id ~= nil and ctx.block_id == read_file(PICKER_BLOCK)
end

rex.action{
  name = "fzf_session_picker_enter",
  title = "Session Picker: Confirm",
  category = "Sessions",
  run = function(ctx)
    if not picker_key(ctx, "\r") then return end
    -- Wait (up to 3s) for the picker to write its result: a session ID, or
    -- "-" when there is nothing to switch to.
    local r = rex.exec({ "sh", "-c", [=[
for i in $(seq 150); do [ -s "$0" ] && { cat "$0"; exit 0; }; sleep 0.02; done; exit 1
]=], PICKER_RESULT })
    os.remove(PICKER_BLOCK)
    rex.client.queue("client.mode.exit")
    local id = r and r.ok and r.stdout:gsub("%s+$", "") or ""
    if id ~= "" and id ~= "-" then
      rex.client.queue("session.select", { session_id = id })
    end
  end,
}

rex.action{
  name = "fzf_session_picker_cancel",
  title = "Session Picker: Cancel",
  category = "Sessions",
  run = function(ctx, args)
    if picker_key(ctx, args and args.data or "\27") then
      os.remove(PICKER_BLOCK)
      rex.client.queue("client.mode.exit")
    end
  end,
}

-- Always bound (not rb): without them the picker can't switch at all.
rex.bind("picker/enter",  "fzf_session_picker_enter")
rex.bind("picker/escape", "fzf_session_picker_cancel", { data = "\27" })
rex.bind("picker/ctrl+c", "fzf_session_picker_cancel", { data = "\3" })

rex.action{
  name = "fzf_session_picker",
  title = "Fuzzy Session Picker",
  category = "Sessions",
  run = function(ctx)
    local view = rex.session.view{}
    local win = active_window(view)
    if not win then return end

    local picker = [=[
set -eu
rex_bin="$0"
out="$1"
# Tell the Enter action there's nothing to switch to, unless replaced below.
trap '[ -s "$out" ] || echo - > "$out"' EXIT
command -v fzf >/dev/null 2>&1 || { echo "fzf is required (not found on Rex server PATH)."; read -r; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required (not found on Rex server PATH)."; read -r; exit 1; }
set +e
result=$({ "$rex_bin" ls --json | jq -r '.sessions[] | "\(.label)\t\(.session_id)"'; } | fzf --print-query --delimiter='\t' --with-nth=1 --prompt='Session> ' --height=100% --layout=reverse)
status=$?
set -e
# fzf returns 1 when the query has no match; that query becomes a new session.
[ "$status" -eq 0 ] || [ "$status" -eq 1 ] || exit 0
query=$(printf '%s\n' "$result" | sed -n '1p')
selected=$(printf '%s\n' "$result" | sed -n '2p')
if [ -n "$selected" ]; then
  id=${selected##*$(printf '\t')}
else
  [ -n "$query" ] || exit 0
  name=$(printf '%s' "$query" | tr '[:lower:]' '[:upper:]')
  created=$("$rex_bin" new "$name" --json)
  id=$(printf '%s' "$created" | jq -er '.session_id')
fi
printf '%s\n' "$id" > "$out"
]=]
    os.remove(PICKER_RESULT)
    local result, err = rex.session.new_layer{
      window_id = win.window_id,
      bounds = { 0.15, 0.2, 0.7, 0.6 },
      focus = true,
      layout = rex.layout.block{
        flavor = shell,
        options = {
          command = { "sh", "-c", picker, REX_BIN, PICKER_RESULT },
          exit = { on_completion = true },
        },
      },
    }
    if err then error(err, 0) end
    local f = io.open(PICKER_BLOCK, "w")
    f:write(result.block_ids[1])
    f:close()
    rex.client.queue("client.mode.enter", { name = "picker" })
  end,
}
rb(p .. "shift+s", "fzf_session_picker")

-- == Reorder sessions ========================================================
-- These actions also appear in the command palette by title.
local function move_session_order(direction, ctx)
  local current = ctx.session_id
  local result, err = rex.call("session.list")
  if err then error(err, 0) end
  local sessions = result.sessions or {}
  local index
  for i, session in ipairs(sessions) do
    if session.session_id == current then index = i; break end
  end
  if not index then return end

  if direction == "up" and index > 1 then
    local _, move_err = rex.call("session.move", {
      session_id = current,
      before_session_id = sessions[index - 1].session_id,
    })
    if move_err then error(move_err, 0) end
  elseif direction == "down" and index < #sessions then
    local _, move_err = rex.call("session.move", {
      session_id = current,
      before_session_id = sessions[index + 2]
        and sessions[index + 2].session_id or nil,
    })
    if move_err then error(move_err, 0) end
  end
end

rex.action{
  name = "session_order_up",
  title = "Move Session Up",
  category = "Sessions",
  run = function(ctx) move_session_order("up", ctx) end,
}
rex.action{
  name = "session_order_down",
  title = "Move Session Down",
  category = "Sessions",
  run = function(ctx) move_session_order("down", ctx) end,
}
rb(p .. "u", "session_order_up")
rb(p .. "d", "session_order_down")

-- == Close pane / tab, scrollback in nvim =====================================
-- tmux: prefix x = kill-pane, prefix & = kill-window. Like your tmux.conf,
-- prefix x is taken by the scrollback viewer, so pane close moves to prefix X.

rb(p .. "shift+x", "pane.close")       -- tmux prefix x  (kill-pane)
rb(p .. "shift+7", "client.tab.close")  -- tmux prefix &  (kill-window)

-- tmux prefix w (kill-pane in your config). The app's own Close command
-- cascades: focused pane -> selected tab -> window.
rb(p .. "w", "client.close")

-- The app that should switch tabs: the client that ran the action when it is
-- an app (a key press or the palette), else the one app attached to the
-- session (e.g. when run with `rex do` from a terminal).
local function app_client(ctx, owner)
  -- The action's client ID can belong to another server. The source block's
  -- owner is identified on the server where the new terminal runs.
  if owner then return owner end
  if ctx.client_id then return ctx.client_id end
  local clients = (rex.session.list_clients{} or {}).clients or {}
  local only
  for _, c in ipairs(clients) do
    if c.info and c.info.kind == "app" then
      if c.client_id == ctx.client_id then return c.client_id end
      only = only == nil and c.client_id or false
    end
  end
  return only or nil
end

-- Capture on the terminal's server and open the result in a new tab there.
-- The action can run on a different machine from the new terminal.
rex.action{
  name     = "scrollback_nvim",
  title    = "Open Pane Scrollback in Neovim",
  category = "Panes",
  run = function(ctx)
    local term = "com.superlogical.terminal"
    if not ctx.block_id then error("No source pane for scrollback", 0) end
    -- Return to the tab holding the pane the scrollback came from. The
    -- server's active window can differ from the tab the app is showing.
    local view = rex.session.view{}
    local previous, owner
    for _, w in ipairs(view.windows or {}) do
      for _, layer in ipairs(w.layers or {}) do
        for _, b in ipairs(layer.blocks or {}) do
          if b.block_id == ctx.block_id then
            previous, owner = w, b.owner
          end
        end
      end
    end
    previous = previous or active_window(view)
    if not previous then return end
    -- Run capture and tab selection on the same server as the new terminal.
    local script = [=[
client="$1" session="$2" prev="$3" source="$4"
select_tab() {
  rex -C "$client" do session.select session_id="$session" window_id="$1" >/dev/null 2>&1
}
file=$(mktemp "${TMPDIR:-/tmp}/rex-scrollback.XXXXXXXX") || exit 1
trap 'rm -f -- "$file"' EXIT
if ! rex capture -s "$session" -b "$source" --trim --unwrap > "$file"; then
  echo 'Scrollback capture failed. Press Enter to close.' >&2
  read -r _
  exit 1
fi
if [ -n "$client" ] && [ -n "$REX_BLOCK" ]; then
  window=$(rex block inspect -s "$session" "$REX_BLOCK" --json | jq -r '.block.window_id // empty')
  if [ -n "$window" ]; then
    select_tab "$window" &
  fi
fi
nvim + "$file"
[ -n "$client" ] && select_tab "$prev"
exit 0
]=]
    local client = app_client(ctx, owner)
    local win, new_err = rex.session.new_window{
      window_label = "Scrollback",
      layout = rex.layout.block{
        flavor = term .. ".shell",
        options = {
          command = {
            "sh", "-c", script, "scrollback", client or "",
            view.session_id, previous.window_id, ctx.block_id,
          },
          exit = { on_completion = true },
        },
      },
    }
    if new_err then error(new_err, 0) end
  end,
}

rb(p .. "x", "scrollback_nvim")      -- tmux prefix x (overridden in your conf)

-- == Three columns (tmux: prefix 3) ==========================================

rex.action{
  name     = "three_columns",
  title    = "Three Columns (30/50/20)",
  category = "Panes",
  run = function(ctx)
    local anchor = ctx.block_id
    if not anchor then return end
    -- left 30% | right 70%
    local r = rex.session.new_split{
      anchor_block_id = anchor,
      direction       = "horizontal",
      side            = "after",
      ratio           = 0.3,
      layout          = rex.layout.block{ flavor = shell },
    }
    if r == nil then return end
    local mid = r.block_ids[1]
    -- middle 50% of the window = 0.5/0.7 of the 70% region; right gets 20%
    rex.session.new_split{
      anchor_block_id = mid,
      direction       = "horizontal",
      side            = "after",
      ratio           = 0.5 / 0.7,
      layout          = rex.layout.block{ flavor = shell },
    }
  end,
}

rb(p .. "3", "three_columns")

-- == Floating shells =========================================================
-- Like the tmux popups: Ctrl+f belongs to the session, prefix+f to the tab.
-- Detaching hides a shell without killing its process or losing scrollback;
-- reattaching it via a split and floating it again restores the same block.
-- Rex blocks cannot move between sessions, so a server-wide popup isn't
-- possible with the current session API (prefix+Ctrl+f remains unbound).
local FLOAT_BOUNDS = { 0.1, 0.1, 0.8, 0.8 }

local function checked(result, err)
  if err then error(err, 0) end
  return result
end

local function floating_shell(scope)
  local view = checked(rex.session.view{})
  local win = active_window(view)
  if not win then return end
  local label = scope == "tab" and "rex.float.tab:" .. win.window_id
                             or "rex.float.session"
  local blocks = checked(rex.session.list_blocks{}).blocks or {}
  local target
  for _, b in ipairs(blocks) do
    if b.label == label then target = b; break end
  end

  if target then
    if target.placement == "placed" then
      -- A second press from inside the popup hides it; from another pane (or
      -- tab) it brings the existing shell here instead of making a new one.
      if target.block_id == win.focused_block_id then
        checked(rex.session.detach_block{ block_id = target.block_id })
        return
      end
      if target.window_id == win.window_id then
        checked(rex.session.focus_block{ block_id = target.block_id })
        return
      end
      checked(rex.session.detach_block{ block_id = target.block_id })
    end
    -- move_block can place a detached block only in a split. Float it right
    -- afterwards; this leaves the tiled layout exactly as it was.
    local anchor
    for _, layer in ipairs(win.layers or {}) do
      if layer.kind == "tiled" and layer.blocks and layer.blocks[1] then
        anchor = layer.blocks[1].block_id
        break
      end
    end
    if not anchor then return end
    checked(rex.session.move_block{
      block_id = target.block_id, anchor_block_id = anchor,
    })
    checked(rex.session.float_block{
      block_id = target.block_id, bounds = FLOAT_BOUNDS,
    })
    checked(rex.session.focus_block{ block_id = target.block_id })
  else
    local created = checked(rex.session.new_layer{
      window_id = win.window_id,
      bounds = FLOAT_BOUNDS,
      layout = rex.layout.block{ flavor = shell },
      focus = true,
    })
    checked(rex.session.set_block_label{
      block_id = created.block_ids[1], label = label,
    })
  end
end

rex.action{
  name = "floating_session_shell",
  title = "Toggle Session Floating Shell",
  category = "Panes",
  run = function() floating_shell("session") end,
}
rex.action{
  name = "floating_tab_shell",
  title = "Toggle Tab Floating Shell",
  category = "Panes",
  run = function() floating_shell("tab") end,
}
rb("ctrl+f", "floating_session_shell")
rb(p .. "f", "floating_tab_shell")
