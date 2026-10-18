-- Project-wide file finding and grepping as Unix pipelines: a lister piped
-- into a menu. fzf when installed, vis' own vis-menu otherwise.
-- (Inside the current directory, vis already does this: `:e .`, `:e src/*.c`
-- and `:o` run vis-open, a vis-menu file browser.)
--
--   :find [query]    rg --files | fzf          <Space>f
--   :grep pattern    rg --vimgrep | fzf        <Space>g  (prompt is prefilled)
--   :grep            ...word under the cursor
--
-- With fzf and bat the highlighted entry is previewed; <C-/> toggles the
-- preview. bat honours $BAT_THEME ("ansi" in config.fish), so previews use the
-- terminal palette. vis-menu has no preview support.
local M = {}

local function have(bin)
	return os.execute("command -v " .. bin .. " >/dev/null 2>&1") == true
end

local q = function(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local MENU = have("fzf") and "fzf --layout=reverse --info=inline" or "vis-menu -l 20"
local FILES = have("rg") and "rg --files --hidden --glob '!.git' --glob '!.jj'"
	or "find . -type f -not -path '*/.git/*' | sed 's|^\\./||'"

-- fzf starts preview commands with $SHELL (fish here) and escapes {} for that
-- shell; force sh so the commands below mean what they say. <C-/> is
-- toggle-wrap-word by default, so bind it to the preview.
local FZF = MENU:find("^fzf")
		and (MENU .. " --with-shell='/bin/sh -c' --bind='ctrl-/:toggle-preview'")
	or MENU
local BAT = have("bat") and "bat --style=numbers --color=always --paging=never"

--- Preview options for fzf, or "" when there is nothing to preview with.
local function preview(cmd, window)
	if not BAT then
		return ""
	end
	return " --preview " .. q(cmd) .. " --preview-window " .. q(window)
end

--- Run a fullscreen picker pipeline, return its first output line.
local function pick(cmd)
	local status, out = vis:pipe(cmd, true)
	vis:redraw()
	if status ~= 0 or not out then
		return nil
	end
	return out:match("[^\n]+")
end

--- Open `path` (optionally at line/col): focus a window already showing it,
--- else replace the current window like `:e` when it has no unsaved changes,
--- else (or when `new_window`) open a new window.
function M.open(path, line, col, new_window)
	for win in vis:windows() do
		local p = win.file.path
		if p and (p == path or p:sub(-#path - 1) == "/" .. path) then
			vis.win = win
			path = nil
			break
		end
	end
	if path then
		local win = vis.win
		local open = new_window or (win and win.file.modified)
		vis:command((open and "open " or "e ") .. q(path))
	end
	if line then
		vis.win.selection:to(tonumber(line), tonumber(col) or 1)
	end
end

vis:command_register("find", function(argv)
	local query = #argv > 0 and (" --query " .. q(table.concat(argv, " "))) or ""
	local menu = MENU:find("^fzf")
			and (FZF .. query .. preview(BAT .. " --line-range=:500 -- {}", "right:55%:border-left"))
		or MENU
	local path = pick(FILES .. " | " .. menu)
	if path then
		M.open(path)
	end
	return true
end, "Pick a file in the project (rg --files | fzf)")

vis:command_register("grep", function(argv, _, win)
	local pattern = table.concat(argv, " ")
	if pattern == "" then
		local sel = win.selection
		local range = win.file:text_object_word(sel.pos)
		pattern = range and win.file:content(range) or ""
		if not pattern:match("%w") then
			vis:info("grep: no pattern")
			return false
		end
	end
	local rg = have("rg") and "rg --vimgrep --smart-case -- " or "grep -rnI -- "
	-- rg --vimgrep prints path:line:col:text; --delimiter lets the preview pick
	-- the path and line out of it, and scroll to the match.
	local menu = MENU:find("^fzf")
			and (FZF
				.. " --delimiter=':'"
				.. preview(BAT .. " --highlight-line {2} -- {1}", "right:55%:border-left:+{2}-5"))
		or MENU
	local hit = pick(rg .. q(pattern) .. " . | " .. menu)
	local path, line, col = (hit or ""):match("^%.?/?([^:]+):(%d+):?(%d*)")
	if path then
		M.open(path, line, col ~= "" and col or nil)
	end
	return true
end, "Grep the project and jump to a match (rg | fzf)")

vis:map(vis.modes.NORMAL, " f", function()
	vis:command("find")
end, "Find file (:find)")
vis:map(vis.modes.NORMAL, " g", ":grep ", "Grep project (:grep)")

return M
