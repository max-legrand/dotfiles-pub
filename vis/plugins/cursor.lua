-- Cursor shape per mode: block in normal/visual, bar in insert,
-- underline in replace.
--
-- vis normally hides the terminal cursor (curs_set(0)) and paints the
-- primary cursor as a styled cell, so cursor-shape escapes alone do nothing.
-- But the curses backend still moves the (hidden) terminal cursor onto the
-- primary selection every frame, so we:
--   * re-show the terminal cursor and set its shape (DECSCUSR, CSI n SP q),
--   * make vis's painted primary cursor a no-op, so only the real one shows
--     (secondary multi-cursors keep their painted style).
-- vis has no mode-change event; UI_DRAW runs right before every blit.
-- Output goes to stderr: that's the stream vis's curses UI is attached to.

local M = {}

local BLOCK, BAR, UNDERLINE = 2, 6, 4 -- steady variants (nvim: blinkon0)

local shapes = {
	[vis.modes.INSERT] = BAR,
	[vis.modes.REPLACE] = UNDERLINE,
}

local current

local function write(s)
	io.stderr:write(s)
	io.stderr:flush()
end

local function hide_painted_cursor()
	vis.ui:style_define(vis.ui.style_ids.CURSOR_PRIMARY, "keep_attribute")
end

local function update()
	-- Cheap, and survives `:set theme ...` re-defining the style.
	hide_painted_cursor()
	local shape = shapes[vis.mode] or BLOCK
	-- Show the cursor every frame: curses re-hides it after a suspend or
	-- shell-out (:!, fzf, lazygit).
	local seq = "\27[?25h"
	if shape ~= current then
		current = shape
		seq = seq .. "\27[" .. shape .. " q"
	end
	write(seq)
end

--- Restore the terminal's default cursor shape (before quitting / shelling
--- out). The next redraw re-applies the mode's shape.
function M.reset()
	write("\27[0 q")
	current = nil
end

-- Runs after config/options' INIT handler has loaded the theme, so the
-- first frame is already right.
vis.events.subscribe(vis.events.INIT, hide_painted_cursor)
vis.events.subscribe(vis.events.UI_DRAW, update)
vis.events.subscribe(vis.events.QUIT, M.reset)

return M
