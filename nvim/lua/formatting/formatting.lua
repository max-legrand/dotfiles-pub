local config_cache = {}
local uv = vim.loop

--- Walk up directories from a starting path to find `.oxfmtrc.json`
--- Uses caching to avoid redundant filesystem traversal.
--- @return string|nil The found file path, or nil if not found
local function find_oxfmtrc()
	-- Get the real directory of the current buffer
	local bufpath = vim.api.nvim_buf_get_name(0)
	if bufpath == "" then
		return nil
	end

	local dir = uv.fs_realpath(vim.fn.fnamemodify(bufpath, ":p:h"))
	if not dir then
		return nil
	end

	-- Check cache first
	if config_cache[dir] ~= nil then
		return config_cache[dir]
	end

	-- Start walking up directories
	local search_dir = dir
	while search_dir do
		local candidate = search_dir .. "/.oxfmtrc.json"
		local stat = uv.fs_stat(candidate)
		if stat and stat.type == "file" then
			-- Cache result for this directory and all subdirs down to the original dir
			local cache_dir = dir
			while cache_dir ~= search_dir do
				config_cache[cache_dir] = candidate
				local parent = vim.fn.fnamemodify(cache_dir, ":h")
				if parent == cache_dir then
					break
				end
				cache_dir = parent
			end
			config_cache[search_dir] = candidate
			return candidate
		end

		local parent = vim.fn.fnamemodify(search_dir, ":h")
		if parent == search_dir then
			break -- Reached root dir
		end
		search_dir = parent
	end

	-- Cache negative result
	config_cache[dir] = nil
	return nil
end

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		-- Conform will run multiple formatters sequentially
		python = { "ruff_format", "ruff_organize_imports" },
		go = { "goimports" },
		cpp = { "clang-format" },
		ocaml = { "ocamlformat", "ocp-indent" },
		swift = { "swift_format" },
		xml = { "xmlformat" },
		toml = { "taplo" },
		json = { "jq" },
		-- typescript = { "biome" },
		-- typescript = { "prettier" },
		svelte = { "biome", "prettier" },
		html = { "prettier", "prettierd" },
		markdown = { "deno_fmt" },
		-- tsx = { "biome" },
		-- typescriptreact = { "prettier" },
		typescriptreact = { "oxfmt" },
		ruby = { "rubocop" },
		-- markdown = { "mdformat" },
	},
	format_after_save = {
		timeout_ms = 2000,
		lsp_fallback = true,
	},
	formatters = {
		darker = {
			prepend_args = { "-S" },
		},
		-- clang-format settings
		clang_format = {
			-- Set config file path
			prepend_args = { "-style=file:/home/max/.clang-format" },
			config = {
				-- Set the path to the clang-format binary
				cmd = "/usr/bin/clang-format",
			},
		},
		oxfmt = {
			stdin = true,
			command = "oxfmt",
			args = function(ctx)
				local config_file = find_oxfmtrc()
				if config_file then
					return { "-c", config_file, "--stdin-filepath", "$FILENAME" }
				end
				return { "--stdin-filepath", "$FILENAME" }
			end,
		},
	},
})
