-- ~/.config/rex/tab-zoom.lua
--
-- Prepends a mark to a window's tab while one of its panes is zoomed, keeping
-- the title it already shows.
--
-- Why a watchdog: zoom is cleared by any focus change - including a mouse
-- click, which no keybinding can observe - so the mark has to be re-synced on
-- session_view_changed rather than from init.lua. It only writes when the mark
-- is wrong, so the view change its own write causes settles immediately.
--
--   rex do --all ~/.config/rex/tab-zoom.lua      (keep it running)
--
-- Change MARK to taste.
local MARK = "[Z] "
local TERM = "com.superlogical.terminal"

-- A window with no explicit label reports the app's generated name, but what
-- the tab actually shows is the title the program reported (the terminal's
-- OSC title). So when the label is generated, mark the program's title; when
-- the label is the user's own, mark that.
local function is_generated(label)
  return label:match("^Window %x+$") ~= nil
end

local function program_title(window)
  if not window.focused_block_id then return nil end
  local r = rex.block.call(TERM, "title", { block_id = window.focused_block_id })
  local t = r and r.title
  if t == nil or t == "" then return nil end
  return t
end

-- Is `text` some pane's program title? Asked of every pane in the window, not
-- just the focused one: un-zooming may also move focus to another pane, and the
-- pane that was zoomed is still there to answer for itself.
local function is_program_title(window, text)
  for _, l in ipairs(window.layers or {}) do
    for _, b in ipairs(l.blocks or {}) do
      local r = rex.block.call(TERM, "title", { block_id = b.block_id })
      if r and r.title == text then return true end
    end
  end
  return false
end

local function sync()
  local view = rex.session.view{}
  for _, w in ipairs((view and view.windows) or {}) do
    if w.label then
      local marked = w.label:sub(1, #MARK) == MARK
      local zoomed = w.zoomed_block_id ~= nil
      local title  = program_title(w)

      if zoomed and not marked then
        local base = is_generated(w.label) and (title or w.label) or w.label
        rex.session.set_window_label{ window_id = w.window_id, label = MARK .. base }

      elseif (not zoomed) and marked then
        local base = w.label:sub(#MARK + 1)
        -- If the base was a program title or the generated name, clearing the
        -- label hands the tab back to the app, which keeps it dynamic. Only a
        -- real custom label is written back.
        local keep = (not is_generated(base)) and (not is_program_title(w, base))
        rex.session.set_window_label{
          window_id = w.window_id,
          label     = keep and base or "",
        }
      end
    end
  end
end

rex.on("session_view_changed", sync)
sync()
return "watching"
