-- `gc` as a real vis operator (vis:operator_new), so it composes like d/c/y:
-- gc{motion}, gc{textobject}, counts, visual selections and every cursor of
-- a multi-selection. `gcc` comments the current line(s): `3gcc`.
-- Toggles: if every non-blank line in the range is commented, uncomment.
--
-- For anything fancier, structural regex is the vis way, e.g.
--   :x/^/ i/-- /            comment every line of the selection
--   :x/^-- / c//            uncomment them
local prefixes = {
	ansi_c = "//", c = "//", cpp = "//", csharp = "//", dart = "//", go = "//", java = "//",
	javascript = "//", typescript = "//", kotlin = "//", rust = "//", scala = "//", swift = "//",
	zig = "//", glsl = "//", protobuf = "//", scss = "//", less = "//", odin = "//", gleam = "//",
	bash = "#", fish = "#", python = "#", ruby = "#", perl = "#", toml = "#", yaml = "#",
	makefile = "#", nix = "#", cmake = "#", dockerfile = "#", ini = "#", elixir = "#",
	julia = "#", r = "#", jq = "#", text = "#",
	lua = "--", sql = "--", haskell = "--", elm = "--", ada = "--",
	lisp = ";", scheme = ";", clojure = ";", fennel = ";", asm = ";",
	latex = "%", tex = "%", erlang = "%", matlab = "%",
	vim = '"',
}

local function escape(s)
	return (s:gsub("%p", "%%%0"))
end

--- Expand [s, e) to whole lines.
local function lines_of(file, s, e)
	while s > 0 and file:content(s - 1, 1) ~= "\n" do
		s = s - 1
	end
	if e > s and file:content(e - 1, 1) == "\n" then
		e = e - 1
	end
	while e < file.size and file:content(e, 1) ~= "\n" do
		e = e + 1
	end
	return s, e
end

vis:operator_new("gc", function(file, range, pos)
	local prefix = prefixes[vis.win.syntax or ""] or "#"
	local s, e = lines_of(file, range.start, range.finish)
	local text = file:content(s, e - s)
	local p = escape(prefix)

	local indent, all = nil, true
	for l in (text .. "\n"):gmatch("(.-)\n") do
		if l:match("%S") then
			local ws = l:match("^%s*")
			if not indent or #ws < #indent then
				indent = ws
			end
			all = all and l:match("^%s*" .. p) ~= nil
		end
	end
	if not indent then
		return pos
	end

	local out = {}
	for l in (text .. "\n"):gmatch("(.-)\n") do
		if not l:match("%S") then
			out[#out + 1] = l
		elseif all then
			out[#out + 1] = (l:gsub("^(%s*)" .. p .. " ?", "%1", 1))
		else
			out[#out + 1] = indent .. prefix .. " " .. l:sub(#indent + 1)
		end
	end
	local new = table.concat(out, "\n")
	if new ~= text then
		file:delete(s, e - s)
		file:insert(s, new)
	end
	return s
end, "Toggle line comments")

-- gcc = gc over the current line; vis applies the count to the text object.
vis:map(vis.modes.NORMAL, "gcc", "gcal", "Toggle comment on line(s)")
