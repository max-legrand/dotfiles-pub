-- vis config, built around how vis works rather than imitating nvim.
-- (The previous nvim-flavoured setup lives in ~/.config/vis.config.bak.)
--
-- The model: vis = vi motions + sam's structural regular expressions +
-- multiple selections + the Unix toolbox. Most "features" are a command
-- line away instead of a plugin:
--
--   :x/re/ cmd        run cmd on every match of re in the range (default: file)
--   :y/re/ cmd        ...on the text *between* matches
--   :g/re/ :v/re/     keep / drop selections that match re
--   :x/re/ c/text/    change every match;  i/text/ a/text/ insert / append
--   :,x/foo/          select every "foo" in the file -> edit them all at once
--   :|cmd  :>cmd  :<cmd  :!cmd   filter / pipe out / read in / run
--                     e.g. :|sort -u   :,|column -t   :<date   :!lazygit
--   ,  .  /re/  'm    addresses: whole file, current line, search, mark
--
--   <C-n>       select word / add next match      <C-x> skip match
--   <C-j> <C-k> new cursor below / above          <C-p> drop last cursor
--   I  A        (visual) cursor at start / end of every selected line
--   <Tab>       align selections                  <Escape> back to one
--   +  -        rotate selection contents
--   g< g> gs    jump list back / forward / save
--   "+y "+p     system clipboard registers
--   <C-n>       (insert) complete word   <C-x><C-f> complete file name
--   :o *.c      glob-pick files with vis-open; Esc Esc or <C-c> cancels
--   :help       every key, command and option, with current bindings
--
-- Additions in plugins/ (each is small and uses vis' own extension points):
--   :fmt  + format on save   plugins/fmt.lua      (filter through a formatter)
--   :find :grep  <Space>f/g  plugins/pick.lua     (rg | fzf, with bat previews; vis-menu fallback)
--   :browse      <Space>b    plugins/browse.lua   (yazi as file chooser; `vis <dir>`)
--   gc{motion} gcc           plugins/comment.lua  (operator: works with counts,
--                                                  text objects, multi-cursor)
--   bar cursor in insert     plugins/cursor.lua
--   no 100%-CPU orphans      plugins/hangup.lua   (vis bug: exits when its terminal dies,
--                                                  saving unsaved work as *.vis-recover)
--   lint on save  <Space>l   plugins/lint.lua     (zig build check / cargo check in the background;
--                                                  underlines problems, :lintlist, ]l [l)
--   LSP                      plugins/vis-lspc     (its own default keys:
--                            gd gD gr gi K, <Space>e/n/N, <C-/> complete)
require("vis")

require("plugins/fmt")
require("plugins/lint")
require("plugins/pick")
require("plugins/browse")
require("plugins/comment")
require("plugins/cursor")
require("plugins/hangup") -- exit instead of spinning at 100% CPU if the terminal dies

-- Options -----------------------------------------------------------------------

vis.events.subscribe(vis.events.INIT, function()
	vis:command("set theme polyminimal2")
	vis:command("set autoindent on")
	vis:command("set ignorecase on")
	-- Filters (:| etc.) and plugins use POSIX sh syntax; $SHELL is fish.
	vis:command("set shell /bin/sh")
end)

-- Hard tabs where the language expects them; 4-space indents elsewhere.
local hard_tabs = { go = true, makefile = true }

-- Keys --------------------------------------------------------------------------

-- `jj` leaves insert mode, like the nvim and helix configs. vis has no mapping
-- timeout, so a single `j` is held until the next key arrives.
vis:map(vis.modes.INSERT, "jj", "<Escape>", "Leave insert mode")

-- <C-z> suspends vis (in normal/visual/insert/operator-pending mode). A
-- suspended vis keeps the terminal, its buffers and any language servers until
-- you `fg` or kill it, which is easy to do by accident and then forget. It also
-- can't be cleaned up by a plugin, because a stopped process runs no Lua.
--
-- Two halves, both needed: the terminal driver turns Ctrl-Z into SIGTSTP before
-- vis sees the key, so unbinding alone changes nothing, and disabling the key
-- alone leaves the keymap binding alive. vis installs its default bindings
-- *after* the INIT event, so this runs on START.
--
-- ncurses restores the suspend key on exit (to whatever it was when vis
-- started); if vis is killed with -9 it can't, so run `stty susp ^Z` in the
-- shell to get it back.
vis.events.subscribe(vis.events.START, function()
	os.execute("stty susp undef < /dev/tty > /dev/null 2>&1")
	for _, mode in ipairs({ vis.modes.NORMAL, vis.modes.VISUAL, vis.modes.OPERATOR_PENDING, vis.modes.INSERT }) do
		pcall(vis.unmap, vis, mode, "<C-z>")
	end
end)

-- (`:set` applies to the focused window, which is the new one here.)
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	vis:command("set tabwidth 4")
	vis:command("set expandtab " .. (hard_tabs[win.syntax] and "off" or "on"))
	vis:command("set numbers on")
	vis:command("set relativenumbers on")
	vis:command("set cursorline on")
	vis:command("set showtabs on")
end)

-- LSP (vis-lspc) ------------------------------------------------------------------

local ok, lspc = pcall(require, "plugins/vis-lspc")
if ok and type(lspc) == "table" and lspc.ls_map then
	local function have(bin)
		return os.execute("command -v " .. bin .. " >/dev/null 2>&1") == true
	end

	lspc.menu_cmd = have("fzf") and "fzf" or lspc.menu_cmd
	lspc.highlight_diagnostics = "range"
	lspc.diagnostic_styles = {
		error = "fore:#ED91B1,underlined",
		warning = "fore:#f6b40e,underlined",
		information = "fore:#E0D4EF,underlined",
		hint = "fore:#E0D4EF,underlined",
	}
	lspc.universal_root_globs = { ".git", ".jj" }
	lspc.fallback_dirname_as_root = true

	local map = lspc.ls_map
	local clangd = { name = "clangd", cmd = "clangd --background-index", roots = { "compile_commands.json", ".clangd" } }
	map.c, map.cpp = clangd, clangd
	map.python = { name = "ty", cmd = "uvx ty server", roots = { "pyproject.toml", "setup.py" } }
	map.rust = { name = "rust-analyzer", cmd = "rust-analyzer", roots = { "Cargo.toml" } }
	map.zig = { name = "zls", cmd = "zls", roots = { "build.zig", "build.zig.zon" } }
	map.swift = { name = "sourcekit-lsp", cmd = "sourcekit-lsp", roots = { "Package.swift" } }
	map.gleam = { name = "gleam", cmd = "gleam lsp", roots = { "gleam.toml" } }
	map.caml = { name = "ocamllsp", cmd = "ocamllsp", roots = { "dune-project", "*.opam" } }

	-- Drop servers that aren't installed so autostart stays quiet.
	for syntax, conf in pairs(map) do
		local bin = conf.cmd and conf.cmd:match("^(%S+)")
		if not bin or not have(bin) then
			map[syntax] = nil
		end
	end
end

-- <Space>e: full text of the problems on this line -- lint (compiler) output if
-- there is any, else the language server's diagnostics.
do
	local lint = require("plugins/lint")
	pcall(vis.unmap, vis, vis.modes.NORMAL, " e")
	vis:map(vis.modes.NORMAL, " e", function()
		if not lint.show(vis.win) then
			vis:command("lspc-show-diagnostics")
		end
	end, "Show diagnostics on this line")

	-- K ("hover"): the problem on this line if there is one, else LSP hover docs.
	pcall(vis.unmap, vis, vis.modes.NORMAL, "K")
	vis:map(vis.modes.NORMAL, "K", function()
		if not lint.show(vis.win) then
			vis:command("lspc-hover")
		end
	end, "Hover: lint problem on this line, else LSP hover")
end

-- Completion on <C-/> instead of vis-lspc's <C-Space>. Terminals send Ctrl-/ as
-- 0x1f (same as Ctrl-_), which vis names <C-_>, so no terminal config is needed.
if ok and type(lspc) == "table" then
	pcall(vis.unmap, vis, vis.modes.NORMAL, "<C- >")
	pcall(vis.unmap, vis, vis.modes.INSERT, "<C- >")
	vis:map(vis.modes.NORMAL, "<C-_>", function()
		vis:command("lspc-completion")
	end, "lspc: completion")
	vis:map(vis.modes.INSERT, "<C-_>", function()
		vis:command("lspc-completion")
		vis.mode = vis.modes.INSERT
	end, "lspc: completion")
end
