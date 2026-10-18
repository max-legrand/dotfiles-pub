-- Formatting = filtering the file through a program, the same thing `:,|cmd`
-- does by hand. Each entry is just such a filter. vis exports $vis_filepath
-- to filters, so formatters that need the path (config lookup, language
-- detection) can use it -- and so can you: `:,|stylua --stdin-filepath "$vis_filepath" -`.
--
--   :fmt          format the file (also runs on :w; `:set fmtonsave off` to stop)
--   :fmt cmd...   filter the file through an ad-hoc command, keeping the cursor
--
-- Keyed by vis syntax name, or ".ext" for files vis has no lexer for.
local M = {}

M.formatters = {
	go = "gofmt",
	rust = "rustfmt --emit stdout --edition 2021",
	zig = "zig fmt --stdin",
	lua = 'stylua --stdin-filepath "$vis_filepath" -',
	python = 'ruff format --quiet --stdin-filename "$vis_filepath" -',
	c = 'clang-format --assume-filename="$vis_filepath"',
	cpp = 'clang-format --assume-filename="$vis_filepath"',
	javascript = 'biome format --stdin-file-path="$vis_filepath"',
	typescript = 'biome format --stdin-file-path="$vis_filepath"',
	json = "jq .",
	toml = "taplo fmt -",
	markdown = "deno fmt --ext md -",
	swift = "swift-format",
	caml = 'ocamlformat --enable-outside-detected-project --name "$vis_filepath" -',
	-- vx-format only rewrites files in place; wrap it into a filter.
	[".vx"] = 't=$(mktemp -t vx).vx; cat >"$t" && vx-format "$t" >/dev/null && cat "$t"; s=$?; rm -f "$t"; exit $s',
}

local installed = {}
local function available(cmd)
	local bin = cmd:match("^[%w_.-]+")
	if bin == "t" then
		bin = "vx-format" -- the tempfile wrapper above
	end
	if installed[bin] == nil then
		installed[bin] = os.execute("command -v " .. bin .. " >/dev/null 2>&1") == true
	end
	return installed[bin]
end

local function formatter(win)
	local ext = win.file.path and win.file.path:match("(%.[^./]+)$")
	local cmd = M.formatters[win.syntax or ""] or (ext and M.formatters[ext])
	return cmd and available(cmd) and cmd or nil
end

--- Filter the whole file through `cmd`. Only touches the buffer when the
--- output differs, and keeps the cursor on the same line/column.
local function filter(win, cmd)
	local file = win.file
	local status, out, err = vis:pipe(file, { start = 0, finish = file.size }, cmd)
	if status ~= 0 or not out then
		vis:info("fmt: " .. ((err or ""):match("[^\n]+") or ("exit " .. tostring(status))))
		return false
	end
	if out == file:content(0, file.size) then
		return true
	end
	local line, col = win.selection.line, win.selection.col
	file:delete(0, file.size)
	file:insert(0, out)
	win.selection:to(line, col)
	return true
end

vis:option_register("fmtonsave", "bool", function(value)
	M.on_save = value
	return true
end, "Format the file with :fmt when writing")
M.on_save = true

vis:command_register("fmt", function(argv, _, win)
	local cmd = #argv > 0 and table.concat(argv, " ") or formatter(win)
	if not cmd then
		vis:info("fmt: no formatter for " .. tostring(win.syntax))
		return false
	end
	return filter(win, cmd)
end, "Format the file (or filter it through the given command)")

vis.events.subscribe(vis.events.FILE_SAVE_PRE, function(file)
	if not M.on_save or file.size > 2 * 1024 * 1024 then
		return
	end
	for win in vis:windows() do
		if win.file == file then
			local cmd = formatter(win)
			if cmd then
				filter(win, cmd)
			end
			return
		end
	end
end)

return M
