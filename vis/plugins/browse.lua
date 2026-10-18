-- Yazi as vis' file browser. vis hands the terminal to yazi; whatever you
-- open there (<Enter>, or select several with <Space> first) comes back and
-- is opened in vis -- the first file in the current window, the rest in new
-- windows. q in yazi cancels.
--
--   :browse [dir|file]   default: hovering the current file    <Space>b
--   vis <dir>            (fish wrapper) starts in :browse
--
-- Without yazi, falls back to vis' own `:e dir` (vis-open / vis-menu).
local pick = require("plugins/pick")

local have_yazi = os.execute("command -v yazi >/dev/null 2>&1") == true

local function q(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

vis:command_register("browse", function(argv, _, win)
	local target = argv[1] or (win and win.file.path) or "."
	if not have_yazi then
		local dir = target:match("^(.*)/[^/]*$") or target
		return vis:command("e " .. q(dir))
	end
	-- yazi needs a real terminal: give it /dev/tty, collect picks from the
	-- chooser file on stdout.
	local cmd = 't=$(mktemp); yazi --chooser-file="$t" '
		.. q(target)
		.. ' </dev/tty >/dev/tty 2>/dev/null; cat "$t"; rm -f "$t"'
	local status, out = vis:pipe(cmd, true)
	vis:redraw()
	if status ~= 0 or not out then
		return false
	end
	local first = true
	for path in out:gmatch("[^\n]+") do
		pick.open(path, nil, nil, not first)
		first = false
	end
	return true
end, "Browse files with yazi; opens the chosen file(s)")

vis:map(vis.modes.NORMAL, " b", function()
	vis:command("browse")
end, "Browse files (:browse)")
