-- Linting on save and on open: run a project checker in the background when a file is
-- written, parse its `path:line:col: severity: message` output, underline the
-- problems and keep a list you can jump through.
--
--   (on :w, :e) run the checker for this file type, asynchronously
--   :lint        run it now
--   :lintlist    pick a problem with fzf and jump to it        <Space>l
--   :lintshow    full compiler output for the cursor line      <Space>e
--   :lintnext / :lintprev  jump through problems in this file  ]l  [l
--   :set lintonsave off    stop linting on save
--
-- Each entry in M.linters is `function(path) -> root, cmd` (or nil when the
-- checker doesn't apply). `cmd` runs in `root` with stdout+stderr merged and
-- must print gcc-style locations. Keyed by vis syntax name.
--
-- Underlines are only drawn while the buffer is unmodified: the positions come
-- from the saved file and would be wrong after an edit. Saving re-lints.
local M = {}

local function exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function read(path)
	local f = io.open(path, "r")
	local s = f and f:read("a")
	if f then
		f:close()
	end
	return s
end

local function dirname(path)
	return path:match("^(.*)/[^/]*$") or "."
end

--- Walk up from `path` looking for any of `names`; return the directory.
local function find_root(path, names)
	local dir = dirname(path)
	while true do
		for _, name in ipairs(names) do
			if exists(dir .. "/" .. name) then
				return dir
			end
		end
		if dir == "/" or dir == "." or dir == "" then
			return nil
		end
		dir = dirname(dir)
	end
end

local q = function(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

M.linters = {
	-- `zig build check` when the project defines a "check" step (the usual way
	-- to get compile errors without producing/ running anything); otherwise a
	-- syntax-only `zig ast-check` of this file.
	zig = function(path)
		local root = find_root(path, { "build.zig" })
		local build = root and read(root .. "/build.zig")
		if build and build:find('step%("check"') then
			return root, "zig build check 2>&1"
		end
		return dirname(path), "zig ast-check " .. q(path) .. " 2>&1"
	end,

	rust = function(path)
		local root = find_root(path, { "Cargo.toml" })
		return root, root and "cargo check --message-format short --quiet 2>&1"
	end,
}

M.on_save = true
vis:option_register("lintonsave", "bool", function(value)
	M.on_save = value
	return true
end, "Run the file type's linter when writing")

-- State ----------------------------------------------------------------------

-- diags[abs_path] = { {line=, col=, severity="error"|"warning", msg=, pos=}, ... }
M.diags = {}
local run_id = 0
local styles = {}

local function absolute(path)
	if path:sub(1, 1) ~= "/" then
		path = (os.getenv("PWD") or ".") .. "/" .. path
	end
	return (path:gsub("/%./", "/"))
end

local function file_path(file)
	return file.path and absolute(file.path)
end

-- Parsing ---------------------------------------------------------------------

local function parse(output, root)
	local by_file, current = {}, nil
	for line in output:gmatch("[^\n]*") do
		-- path:line:col: error: msg   |   path:line:col: error[E0425]: msg
		local path, l, c, sev, msg = line:match("^(%S-):(%d+):(%d+): (%a+)[%w%[%]]*: (.*)$")
		if path and (sev == "error" or sev == "warning") then
			local abs = path:sub(1, 1) == "/" and path or (root .. "/" .. path)
			abs = abs:gsub("/%./", "/")
			by_file[abs] = by_file[abs] or {}
			current = { line = tonumber(l), col = tonumber(c), severity = sev, msg = msg, detail = { line } }
			table.insert(by_file[abs], current)
		elseif current and (line:match("^%s+%S") or (path and sev == "note")) then
			-- source line, caret, note: ... belongs to the diagnostic above
			table.insert(current.detail, line)
		else
			current = nil
		end
	end
	return by_file
end

--- Byte offsets for the diagnostics of a saved, unmodified file.
local function resolve_positions(file, list)
	local lines = file.lines
	table.sort(list, function(a, b)
		return a.line < b.line or (a.line == b.line and a.col < b.col)
	end)
	local offset, n = 0, 0
	for _, d in ipairs(list) do
		while n < d.line - 1 and n < #lines do
			n = n + 1
			offset = offset + #lines[n] + 1
		end
		d.pos = offset + math.max(d.col - 1, 0)
	end
end

-- Display ----------------------------------------------------------------------

local function summary(by_file, current)
	local errors, warnings, first = 0, 0, nil
	local function better(path, d)
		if not first then
			return true
		end
		local function rank(p, x)
			return (p == current and 2 or 0) + (x.severity == "error" and 1 or 0)
		end
		return rank(path, d) > rank(first.path, first.d)
	end
	for path, list in pairs(by_file) do
		for _, d in ipairs(list) do
			if d.severity == "error" then
				errors = errors + 1
			else
				warnings = warnings + 1
			end
			if better(path, d) then
				first = { path = path, d = d }
			end
		end
	end
	return errors, warnings, first
end

local function report(by_file, run, code)
	local errors, warnings, first = summary(by_file, run.path)
	if not first then
		if code ~= 0 then
			-- The checker failed without printing a location we understand
			-- (e.g. build.zig itself doesn't compile): show why.
			local out = table.concat(run.chunks)
			local why = out:match("[^\n]*[Ee]rror[^\n]*") or out:match("[^\n]+") or ("exit " .. tostring(code))
			vis:info("lint: checker failed — " .. why)
		else
			vis:info("lint: clean")
		end
		return
	end
	local counts = {}
	if errors > 0 then
		table.insert(counts, errors .. (errors == 1 and " error" or " errors"))
	end
	if warnings > 0 then
		table.insert(counts, warnings .. (warnings == 1 and " warning" or " warnings"))
	end
	local name = first.path:match("[^/]+$")
	vis:info(
		("lint: %s — %s:%d: %s"):format(table.concat(counts, ", "), name, first.d.line, first.d.msg)
	)
end

vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
	local path = file_path(win.file)
	local list = path and M.diags[path]
	if not list or win.file.modified then
		return
	end
	if list[1] and not list[1].pos then
		resolve_positions(win.file, list) -- results for a file that wasn't the saved one
	end
	if not styles.error then
		styles.error = vis.ui:style_push()
		styles.warning = vis.ui:style_push()
	end
	vis.ui:style_define(styles.error, M.styles.error)
	vis.ui:style_define(styles.warning, M.styles.warning)
	for _, d in ipairs(list) do
		if d.pos then
			local range = win.file:text_object_word(d.pos)
			local finish = range and range.finish > d.pos and range.finish or d.pos + 1
			win:style(styles[d.severity], d.pos, finish - 1)
		end
	end
end)

M.styles = {
	error = "fore:#ED91B1,underlined",
	warning = "fore:#f6b40e,underlined",
}

-- Running -----------------------------------------------------------------------

local function window_for(file)
	for win in vis:windows() do
		if win.file == file then
			return win
		end
	end
end

local pending = {}

local function finish(run, code)
	if run.id ~= run_id then
		return -- a newer lint run superseded this one
	end
	local by_file = parse(table.concat(run.chunks), run.root)
	M.diags = by_file
	if not run.file.modified and by_file[run.path] then
		resolve_positions(run.file, by_file[run.path])
	end
	report(by_file, run, code)
	local w = window_for(run.file)
	if w then
		w:draw()
	end
end

vis.events.subscribe(vis.events.PROCESS_RESPONSE, function(name, event, code, msg)
	local run = pending[name]
	if not run then
		return
	end
	if event == "STDOUT" or event == "STDERR" then
		table.insert(run.chunks, msg)
	elseif event == "EXIT" or event == "SIGNAL" then
		pending[name] = nil
		finish(run, event == "EXIT" and code or -1)
	end
end)

function M.run(win)
	local path = file_path(win.file)
	local linter = path and M.linters[win.syntax or ""]
	if not linter then
		return false
	end
	local root, cmd = linter(path)
	if not (root and cmd) then
		return false
	end

	run_id = run_id + 1
	local name = "lint:" .. run_id
	pending[name] = { id = run_id, chunks = {}, root = root, file = win.file, path = path }
	-- stdin must be closed: vis:communicate gives the process an open pipe, and
	-- `zig build` waits on it forever when build.zig itself fails to compile.
	vis:communicate(name, "cd " .. q(root) .. " && { " .. cmd .. "; } </dev/null")
	vis:info("lint: running…")
	return true
end

vis:command_register("lint", function(_, _, win)
	if not M.run(win) then
		vis:info("lint: no linter for " .. tostring(win.syntax))
		return false
	end
	return true
end, "Run the linter for this file type")

vis.events.subscribe(vis.events.FILE_SAVE_POST, function(file)
	if not M.on_save then
		return
	end
	local win = window_for(file)
	if win then
		M.run(win)
	end
end)

-- Also lint when a file is opened, so problems show up before the first save.
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	if M.on_save and win.file.path then
		M.run(win)
	end
end)

-- Navigation ----------------------------------------------------------------------

local function sorted_current(win)
	local list = M.diags[file_path(win.file) or ""]
	if not list or win.file.modified then
		return nil
	end
	return list
end

local function jump(win, dir)
	local list = sorted_current(win)
	if not list or #list == 0 then
		vis:info("lint: no problems in this file")
		return false
	end
	local cur = win.selection.pos
	local target
	if dir > 0 then
		for _, d in ipairs(list) do
			if d.pos and d.pos > cur then
				target = d
				break
			end
		end
		target = target or list[1]
	else
		for i = #list, 1, -1 do
			if list[i].pos and list[i].pos < cur then
				target = list[i]
				break
			end
		end
		target = target or list[#list]
	end
	win.selection.pos = target.pos
	vis:info(("lint: %s: %s"):format(target.severity, target.msg))
	return true
end

--- Show the full compiler output for the problems on the cursor line.
function M.show(win)
	local list = M.diags[file_path(win.file) or ""]
	if not list then
		return false
	end
	local line = win.selection.line
	local text = {}
	for _, d in ipairs(list) do
		if d.line == line then
			table.insert(text, table.concat(d.detail, "\n"))
		end
	end
	if #text == 0 then
		return false
	end
	vis:message(table.concat(text, "\n\n"))
	return true
end

vis:command_register("lintshow", function(_, _, win)
	if not M.show(win) then
		vis:info("lint: no problem on this line")
		return false
	end
	return true
end, "Show the lint problem(s) on the current line")

vis:command_register("lintnext", function(_, _, win)
	return jump(win, 1)
end, "Jump to the next lint problem")
vis:command_register("lintprev", function(_, _, win)
	return jump(win, -1)
end, "Jump to the previous lint problem")

vis:command_register("lintlist", function()
	local rows = {}
	for path, list in pairs(M.diags) do
		for _, d in ipairs(list) do
			table.insert(rows, ("%s:%d:%d: %s: %s"):format(path, d.line, d.col, d.severity, d.msg))
		end
	end
	if #rows == 0 then
		vis:info("lint: no problems")
		return true
	end
	table.sort(rows)
	local tmp = os.tmpname()
	local f = io.open(tmp, "w")
	f:write(table.concat(rows, "\n"), "\n")
	f:close()
	local status, out = vis:pipe("fzf --layout=reverse --info=inline < " .. q(tmp), true)
	os.remove(tmp)
	vis:redraw()
	local hit = status == 0 and out and out:match("[^\n]+")
	local path, line, col = (hit or ""):match("^(.-):(%d+):(%d+):")
	if path then
		require("plugins/pick").open(path, line, col)
	end
	return true
end, "Pick a lint problem and jump to it")

vis:map(vis.modes.NORMAL, " l", function()
	vis:command("lintlist")
end, "Lint problems (:lintlist)")
vis:map(vis.modes.NORMAL, "]l", function()
	vis:command("lintnext")
end, "Next lint problem")
vis:map(vis.modes.NORMAL, "[l", function()
	vis:command("lintprev")
end, "Previous lint problem")

return M
