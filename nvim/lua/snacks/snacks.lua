-- ---------------------------------------------------------------------------
-- instantgrep integration
-- ---------------------------------------------------------------------------
local ig_bin = vim.fn.expand("~/.local/bin/instantgrep")

-- Default configuration
local ig_config = {
	default_ignore_case = true,
	smartcase = true, -- if true, automatically enable case-sensitivity when pattern has uppercase
}

-- Per-cwd daemon state: cwd -> { job_id, sock_path, ready }
local ig_daemons = {}

--- Ask instantgrep for the canonical socket path for a given cwd.
--- Must only be called from normal (non-fast-event) context.
local function ig_resolve_sock(cwd)
	local result = vim.fn.system({ ig_bin, "--socket-path", cwd })
	return vim.trim(result)
end

--- Ensure the daemon is running for `cwd`. Returns true when it's ready.
--- Safe to call from any context — never touches vim.fn.system.
--- Requires ig_daemons[cwd].sock_path to already be set (done by ig_setup_cwd).
local function ig_ensure_daemon(cwd)
	local state = ig_daemons[cwd]
	if not state then
		return false
	end
	if state.ready then
		return true
	end
	if state.job_id then
		if vim.uv.fs_stat(state.sock_path) then
			state.ready = true
			return true
		end
		return false
	end
	-- Spawn daemon — sock_path already resolved in normal context
	local job_id = vim.fn.jobstart({ ig_bin, "--daemon", cwd }, {
		cwd = cwd,
		detach = true,
		on_stderr = function() end, -- suppress all output
		on_exit = function()
			if ig_daemons[cwd] then
				ig_daemons[cwd].ready = false
				ig_daemons[cwd].job_id = nil
			end
		end,
	})
	if job_id <= 0 then
		return false
	end
	state.job_id = job_id
	return false
end

--- Stop the daemon for `cwd` and clear job state (preserves sock_path for restart).
local function ig_stop_daemon(cwd)
	local state = ig_daemons[cwd]
	if not state then
		return
	end
	if state.job_id then
		vim.fn.jobstop(state.job_id)
	end
	ig_daemons[cwd] = { sock_path = state.sock_path }
end

--- Build or rebuild the index for `cwd` asynchronously.
local function ig_build_index(cwd)
	local state = ig_daemons[cwd]
	if state and state.indexing then
		return
	end
	if state then
		state.indexing = true
	end
	vim.fn.jobstart({ ig_bin, "--build", cwd }, {
		cwd = cwd,
		detach = true,
		on_stderr = function() end,
		on_exit = function(_, code)
			if state then
				state.indexing = false
			end
			if code == 0 then
				ig_stop_daemon(cwd)
				ig_ensure_daemon(cwd)
			end
		end,
	})
end

--- Parse a raw "file:line:col:text" output line into a finder item.
local function ig_parse_line(line, search_pattern)
	local file, ln, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
	if not file then
		return nil
	end
	local col_num = tonumber(col)
	local line_num = tonumber(ln)

	local item = {
		text = line,
		file = file,
		line = text,
		ft = "",
		pos = { line_num, col_num - 1 },
	}

	item.resolve = function()
		if search_pattern and search_pattern ~= "" then
			local positions = {}
			local search_lower = search_pattern:lower()
			local text_lower = text:lower()
			local start = 1
			while start <= #text_lower do
				local idx = text_lower:find(search_lower, start, true)
				if not idx then
					break
				end
				for i = idx, idx + #search_pattern - 1 do
					table.insert(positions, i)
				end
				start = idx + #search_pattern
			end
			if #positions > 0 then
				item.positions = positions
				item.end_pos = { line_num, positions[#positions] }
			end
		end
	end

	return item
end

--- Parse search string like ripgrep: "pattern -- -g *.rb -i"
local function parse_search(search)
	if not search or search == "" then
		return "", "", nil, {}
	end

	local pattern, args_str = search:match("^(.-)%s+%-%-%s+(.*)$")
	if not pattern then
		pattern = search
		args_str = ""
	end

	pattern = vim.trim(pattern)

	local flags = ""
	local glob = nil
	local extra_args = {}

	if args_str ~= "" then
		local i = 1
		local args = {}
		while i <= #args_str do
			local char = args_str:sub(i, i)
			if char == '"' or char == "'" then
				local quote = char
				local j = i + 1
				while j <= #args_str and args_str:sub(j, j) ~= quote do
					j = j + 1
				end
				table.insert(args, args_str:sub(i + 1, j - 1))
				i = j + 1
			elseif char:match("%s") then
				i = i + 1
			else
				local j = i
				while j <= #args_str and not args_str:sub(j, j):match("%s") do
					j = j + 1
				end
				table.insert(args, args_str:sub(i, j - 1))
				i = j
			end
		end

		local j = 1
		while j <= #args do
			local arg = args[j]
			if arg == "-i" or arg == "--ignore-case" then
				flags = flags .. "i"
			elseif arg == "-g" or arg == "--glob" then
				j = j + 1
				if j <= #args then
					glob = args[j]
				end
			else
				table.insert(extra_args, arg)
			end
			j = j + 1
		end
	end

	return pattern, flags, glob, extra_args
end

--- Custom snacks finder that queries the daemon via Unix socket.
--- Falls back to spawning instantgrep directly if the daemon isn't ready yet.
local function ig_finder(opts, ctx)
	local search = ctx.filter.search
	if not search or search == "" then
		return function() end
	end

	local cwd = vim.fn.fnamemodify(opts.cwd or vim.uv.cwd() or ".", ":p"):gsub("/$", "")

	local pattern, flags, glob, extra_args = parse_search(search)

	local has_case_flag = search:find("%-%-ignore%-case") or search:find("%-i[^%-]") or search:find("%-i$")

	local should_ignore_case = not has_case_flag and ig_config.default_ignore_case
	if should_ignore_case and ig_config.smartcase then
		if pattern:find("%u") then
			should_ignore_case = false
		end
	end

	if should_ignore_case then
		flags = flags .. "i"
	end

	if pattern == "" then
		return function() end
	end

	local ready = ig_ensure_daemon(cwd)

	if ready then
		local sock_path = ig_daemons[cwd].sock_path
		return function(cb)
			local Async = require("snacks.picker.util.async")
			local Queue = require("snacks.picker.util.queue")
			local async = Async.running()
			local queue = Queue.new()
			local pipe = vim.uv.new_pipe(false)
			local pipe_closed = false
			local EOF = {}

			local function close_pipe()
				if not pipe_closed then
					pipe_closed = true
					pipe:read_stop()
					if not pipe:is_closing() then
						pipe:close()
					end
				end
			end

			local function signal_eof()
				close_pipe()
				queue:push(EOF)
				if async then
					async:resume()
				end
			end

			local opts_parts = {}
			if flags ~= "" then
				table.insert(opts_parts, "flags=" .. flags)
			end
			if glob then
				table.insert(opts_parts, "glob=" .. glob)
			end
			local opts_line = #opts_parts > 0 and ("opts:" .. table.concat(opts_parts, ",")) or nil

			pipe:connect(sock_path, function(connect_err)
				if connect_err then
					if ig_daemons[cwd] then
						ig_daemons[cwd].ready = false
					end
					signal_eof()
					return
				end

				if opts_line then
					pipe:write(opts_line .. "\n")
				end
				pipe:write(pattern .. "\n")

				local buf = ""
				pipe:read_start(function(read_err, data)
					if read_err or not data then
						signal_eof()
						return
					end

					buf = buf .. data
					local pushed = false
					while true do
						local nl = buf:find("\n", 1, true)
						if not nl then
							break
						end
						local line = buf:sub(1, nl - 1)
						buf = buf:sub(nl + 1)

						if line == "\0" then
							signal_eof()
							return
						end

						if line ~= "" then
							queue:push(line)
							pushed = true
						end
					end
					if pushed and async then
						async:resume()
					end
				end)
			end)

			while true do
				if queue:empty() then
					if async then
						async:suspend()
					end
				end
				local line = queue:pop()
				if line == EOF then
					break
				end
				if line ~= nil then
					local item = ig_parse_line(line, pattern)
					if item then
						cb(item)
					end
				end
			end
		end
	else
		local proc_args = { "--no-index", pattern }
		if glob then
			table.insert(proc_args, "-g")
			table.insert(proc_args, glob)
		end
		if flags:find("i") then
			table.insert(proc_args, "-i")
		end
		for _, arg in ipairs(extra_args) do
			table.insert(proc_args, arg)
		end
		table.insert(proc_args, cwd)

		return require("snacks.picker.source.proc").proc(
			vim.tbl_extend("force", opts, {
				notify = false,
				cmd = ig_bin,
				args = proc_args,
				cwd = cwd,
				transform = function(item)
					local file, ln, col, text = item.text:match("^(.+):(%d+):(%d+):(.*)$")
					if not file then
						return false
					end
					item.file = file
					item.line = text
					item.ft = ""
					item.pos = { tonumber(ln), tonumber(col) - 1 }
				end,
			}),
			ctx
		)
	end
end

-- ---------------------------------------------------------------------------
-- instantgrep daemon lifecycle
-- ---------------------------------------------------------------------------

-- Returns true if the current buffer looks like a temporary scratch file
-- that should not trigger indexing (e.g. jujutsu/git commit messages).
local function ig_is_scratch_buf()
	local bufname = vim.api.nvim_buf_get_name(0)
	local scratch_patterns = {
		"jj%-[^/]+$",
		"COMMIT_EDITMSG$",
		"MERGE_MSG$",
		"SQUASH_MSG$",
		"git%-rebase%-todo$",
	}
	for _, pat in ipairs(scratch_patterns) do
		if bufname:find(pat) then
			return true
		end
	end
	return false
end

local function ig_setup_cwd(cwd)
	cwd = vim.fn.fnamemodify(cwd, ":p"):gsub("/$", "")
	if ig_is_scratch_buf() then
		return
	end
	local sock_path = ig_resolve_sock(cwd)
	ig_daemons[cwd] = ig_daemons[cwd] or {}
	ig_daemons[cwd].sock_path = sock_path
	local cache_dir = vim.fn.fnamemodify(sock_path, ":h")
	if vim.uv.fs_stat(cache_dir .. "/postings.dat") then
		ig_ensure_daemon(cwd)
	else
		ig_build_index(cwd)
	end
end

vim.schedule(function()
	ig_setup_cwd(vim.fn.getcwd())
end)

vim.api.nvim_create_autocmd("DirChanged", {
	callback = function(ev)
		local new_cwd = ev.file ~= "" and ev.file or vim.fn.getcwd()
		ig_setup_cwd(new_cwd)
	end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*",
	callback = function()
		local cwd = vim.fn.getcwd()
		local state = ig_daemons[cwd]
		if state then
			ig_build_index(cwd)
		end
	end,
})

-- ---------------------------------------------------------------------------
-- snacks.nvim setup (using fork with instantgrep support)
-- ---------------------------------------------------------------------------

vim.pack.add({ "https://github.com/max-legrand/snacks.nvim" })
require("snacks").setup({
	bigfile = { enabled = true },
	dashboard = { enabled = false },
	indent = { enabled = true },
	input = { enabled = true },
	notifier = {
		enabled = true,
		timeout = 3000,
	},
	picker = {
		enabled = true,
		sources = {
			instantgrep = {
				finder = ig_finder,
				format = "file",
				live = true,
				supports_live = true,
				show_empty = true,
				need_search = true,
				title = "instantgrep",
				matcher = {
					ignorecase = true,
					smartcase = false,
				},
			},
		},
	},
	quickfile = { enabled = true },
	scroll = {
		enabled = false,
		animate = {
			duration = { step = 10, total = 90 },
			easing = "outCubic",
			fps = 240,
		},
		animate_repeat = {
			delay = 0,
			duration = { step = 5, total = 50 },
			easing = "outCubic",
		},
		filter = function(buf)
			return vim.g.snacks_scroll ~= false
				and vim.b[buf].snacks_scroll ~= false
				and vim.bo[buf].buftype ~= "terminal"
		end,
	},
	statuscolumn = { enabled = false },
	words = { enabled = false },
	styles = {
		notification = {},
	},
})

-- Manually register all keymaps
local keymaps = {
	{
		"<leader><space>",
		function()
			Snacks.picker.smart()
		end,
		desc = "Smart Find Files",
	},
	{
		"<leader>,",
		function()
			Snacks.picker.buffers()
		end,
		desc = "Buffers",
	},
	{
		"<leader>/",
		function()
			Snacks.picker.pick("instantgrep", { cwd = vim.fn.getcwd() })
		end,
		desc = "Grep (instantgrep)",
	},
	{
		"<leader>:",
		function()
			Snacks.picker.command_history()
		end,
		desc = "Command History",
	},
	{
		"<leader>n",
		function()
			Snacks.picker.notifications()
		end,
		desc = "Notification History",
	},
	{
		"<leader>e",
		function()
			Snacks.explorer()
		end,
		desc = "File Explorer",
	},
	-- find
	{
		"<leader>fb",
		function()
			Snacks.picker.buffers()
		end,
		desc = "Buffers",
	},
	{
		"<leader>fc",
		function()
			Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
		end,
		desc = "Find Config File",
	},
	{
		"<leader>ff",
		function()
			Snacks.picker.files()
		end,
		desc = "Find Files",
	},
	{
		"<leader>fg",
		function()
			Snacks.picker.git_files()
		end,
		desc = "Find Git Files",
	},
	{
		"<leader>fp",
		function()
			Snacks.picker.projects()
		end,
		desc = "Projects",
	},
	{
		"<leader>fr",
		function()
			Snacks.picker.recent()
		end,
		desc = "Recent",
	},
	-- git
	{
		"<leader>gl",
		function()
			Snacks.picker.git_log()
		end,
		desc = "Git Log",
	},
	{
		"<leader>gL",
		function()
			Snacks.picker.git_log_line()
		end,
		desc = "Git Log Line",
	},
	{
		"<leader>gs",
		function()
			Snacks.picker.git_status()
		end,
		desc = "Git Status",
	},
	{
		"<leader>gd",
		function()
			Snacks.picker.git_diff()
		end,
		desc = "Git Diff (Hunks)",
	},
	{
		"<leader>gf",
		function()
			Snacks.picker.git_log_file()
		end,
		desc = "Git Log File",
	},
	-- Grep
	{
		"<leader>sb",
		function()
			Snacks.picker.lines()
		end,
		desc = "Buffer Lines",
	},
	{
		"<leader>sB",
		function()
			Snacks.picker.grep_buffers()
		end,
		desc = "Grep Open Buffers",
	},
	{
		"<leader>sg",
		function()
			Snacks.picker.pick("instantgrep", { cwd = vim.fn.getcwd() })
		end,
		desc = "Grep (instantgrep)",
	},
	{
		"<leader>sw",
		function()
			Snacks.picker.pick("instantgrep", {
				cwd = vim.fn.getcwd(),
				search = vim.fn.expand("<cword>"),
			})
		end,
		desc = "Word under cursor (instantgrep)",
		mode = { "n", "x" },
	},
	-- search
	{
		'<leader>s"',
		function()
			Snacks.picker.registers()
		end,
		desc = "Registers",
	},
	{
		"<leader>s/",
		function()
			Snacks.picker.search_history()
		end,
		desc = "Search History",
	},
	{
		"<leader>sa",
		function()
			Snacks.picker.autocmds()
		end,
		desc = "Autocmds",
	},
	{
		"<leader>sc",
		function()
			Snacks.picker.command_history()
		end,
		desc = "Command History",
	},
	{
		"<leader>sC",
		function()
			Snacks.picker.commands()
		end,
		desc = "Commands",
	},
	{
		"<leader>sd",
		function()
			Snacks.picker.diagnostics()
		end,
		desc = "Diagnostics",
	},
	{
		"<leader>sh",
		function()
			Snacks.picker.help()
		end,
		desc = "Help Pages",
	},
	{
		"<leader>sH",
		function()
			Snacks.picker.highlights()
		end,
		desc = "Highlights",
	},
	{
		"<leader>si",
		function()
			Snacks.picker.icons()
		end,
		desc = "Icons",
	},
	{
		"<leader>sj",
		function()
			Snacks.picker.jumps()
		end,
		desc = "Jumps",
	},
	{
		"<leader>sk",
		function()
			Snacks.picker.keymaps()
		end,
		desc = "Keymaps",
	},
	{
		"<leader>sl",
		function()
			Snacks.picker.loclist()
		end,
		desc = "Location List",
	},
	{
		"<leader>sm",
		function()
			Snacks.picker.marks()
		end,
		desc = "Marks",
	},
	{
		"<leader>sM",
		function()
			Snacks.picker.man()
		end,
		desc = "Man Pages",
	},
	{
		"<leader>sp",
		function()
			Snacks.picker.lazy()
		end,
		desc = "Search for Plugin Spec",
	},
	{
		"<leader>sq",
		function()
			Snacks.picker.qflist()
		end,
		desc = "Quickfix List",
	},
	{
		"<leader>sR",
		function()
			Snacks.picker.resume()
		end,
		desc = "Resume",
	},
	{
		"<leader>su",
		function()
			Snacks.picker.undo()
		end,
		desc = "Undo History",
	},
	{
		"<leader>uC",
		function()
			Snacks.picker.colorschemes()
		end,
		desc = "Colorschemes",
	},
	-- LSP
	{
		"gd",
		function()
			Snacks.picker.lsp_definitions()
		end,
		desc = "Goto Definition",
	},
	{
		"gC",
		function()
			Snacks.picker.lsp_declarations()
		end,
		desc = "Goto Declaration",
	},
	{
		"gr",
		function()
			Snacks.picker.lsp_references()
		end,
		nowait = true,
		desc = "References",
	},
	{
		"gI",
		function()
			Snacks.picker.lsp_implementations()
		end,
		desc = "Goto Implementation",
	},
	{
		"gy",
		function()
			Snacks.picker.lsp_type_definitions()
		end,
		desc = "Goto T[y]pe Definition",
	},
	{
		"<leader>ss",
		function()
			Snacks.picker.lsp_symbols({
				finder = "lsp_symbols",
				format = "lsp_symbol",
				tree = true,
				filter = {
					default = true,
				},
			})
		end,
		desc = "LSP Symbols",
	},
	{
		"<leader>st",
		function()
			Snacks.picker.lsp_type_definitions()
		end,
		desc = "LSP Type Definitions",
	},
	{
		"<leader>sS",
		function()
			Snacks.picker.lsp_workspace_symbols()
		end,
		desc = "LSP Workspace Symbols",
	},
	{
		"<leader>.",
		function()
			Snacks.scratch()
		end,
		desc = "Toggle Scratch Buffer",
	},
	{
		"<leader>S",
		function()
			Snacks.scratch.select()
		end,
		desc = "Select Scratch Buffer",
	},
	{
		"<leader>n",
		function()
			Snacks.notifier.show_history()
		end,
		desc = "Notification History",
	},
	{
		"<leader>bd",
		function()
			Snacks.bufdelete()
		end,
		desc = "Delete Buffer",
	},
	{
		"<leader>cR",
		function()
			Snacks.rename.rename_file()
		end,
		desc = "Rename File",
	},
	{
		"<leader>gB",
		function()
			Snacks.gitbrowse()
		end,
		desc = "Git Browse",
		mode = { "n", "v" },
	},
	{
		"<leader>gb",
		function()
			Snacks.git.blame_line()
		end,
		desc = "Git Blame Line",
	},
	{
		"<leader>gf",
		function()
			Snacks.lazygit.log_file()
		end,
		desc = "Lazygit Current File History",
	},
	{
		"<leader>gg",
		function()
			Snacks.lazygit()
		end,
		desc = "Lazygit",
	},
	{
		"<leader>gl",
		function()
			Snacks.lazygit.log()
		end,
		desc = "Lazygit Log (cwd)",
	},
	{
		"<leader>un",
		function()
			Snacks.notifier.hide()
		end,
		desc = "Dismiss All Notifications",
	},
	{
		"<c-/>",
		function()
			Snacks.terminal()
		end,
		desc = "Toggle Terminal",
	},
	{
		"<c-_>",
		function()
			Snacks.terminal()
		end,
		desc = "which_key_ignore",
	},
	{
		"]]",
		function()
			Snacks.words.jump(vim.v.count1)
		end,
		desc = "Next Reference",
		mode = { "n", "t" },
	},
	{
		"[[",
		function()
			Snacks.words.jump(-vim.v.count1)
		end,
		desc = "Prev Reference",
		mode = { "n", "t" },
	},
}

for _, keymap in ipairs(keymaps) do
	local lhs = keymap[1]
	local rhs = keymap[2]
	local mode = keymap.mode or "n"
	local opts = { desc = keymap.desc or "", silent = true }
	if keymap.nowait then
		opts.nowait = keymap.nowait
	end
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- Debug globals and toggle mappings
_G.dd = function(...)
	Snacks.debug.inspect(...)
end
_G.bt = function()
	Snacks.debug.backtrace()
end
vim.print = _G.dd

Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle
	.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
	:map("<leader>uc")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.inlay_hints():map("<leader>uh")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.dim():map("<leader>uD")
