-- ---------------------------------------------------------------------------
-- lazy.nvim bootstrap + plugin specs
--
-- Migrated from vim.pack. lazy handles installation and load ordering; the
-- per-plugin configuration still lives in the topic modules under lua/ (noice,
-- snacks, treesitter, lsp, ...). Specs without a `config`/`opts` are just
-- installed + added to the runtimepath by lazy, and the modules required at the
-- bottom of this file call their `.setup()` exactly as before.
-- ---------------------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Failed to clone lazy.nvim:\n" .. out)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Colorscheme + statusline: needed eagerly by lua/colors.lua, which runs
	-- right after this file in init.lua.
	{ "rktjmp/lush.nvim", lazy = false, priority = 1000 },
	{ "zenbones-theme/zenbones.nvim", lazy = false, priority = 1000, dependencies = { "rktjmp/lush.nvim" } },
	{ "nvim-lualine/lualine.nvim", lazy = false },

	-- Treesitter (main branch API; configured in treesitter/treesitter.lua)
	{ "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false },
	{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main", lazy = false },
	{ "nvim-treesitter/nvim-treesitter-context", lazy = false },

	-- UI / messages
	{ "folke/noice.nvim", lazy = false, dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" } },
	{ "max-legrand/snacks.nvim", lazy = false, priority = 900 },
	{ "j-hui/fidget.nvim", lazy = false },
	{ "lewis6991/gitsigns.nvim", lazy = false },

	-- LSP / editing helpers
	{ "neovim/nvim-lspconfig", lazy = false },
	{ "stevearc/conform.nvim", lazy = false },
	{ "mfussenegger/nvim-lint", lazy = false },
	{ "echasnovski/mini.ai", lazy = false },
	{ "echasnovski/mini.icons", lazy = false },
	{ "stevearc/oil.nvim", lazy = false },
	{ "windwp/nvim-autopairs", lazy = false },
	{ "laytan/cloak.nvim", lazy = false },
	{ "tpope/vim-fugitive", lazy = false },
	{ "tpope/vim-surround", lazy = false },
	{ "chentoast/marks.nvim", lazy = false },
	{ "tjdevries/overlength.vim", lazy = false },

	-- Completion stack: loaded on first insert, exactly as the old InsertEnter
	-- autocmd did. Configured in completion/blink.lua.
	{
		"saghen/blink.cmp",
		version = "1.*",
		event = "InsertEnter",
		dependencies = {
			"saghen/blink.compat",
			{ "L3MON4D3/LuaSnip", version = "2.*" },
		},
		config = function()
			require("completion.blink")
		end,
	},

	-- Markdown / image helpers, previously deferred with defer_fn. Configured
	-- together in copilot/copilots.lua.
	{
		"MeanderingProgrammer/render-markdown.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
			"HakonHarnes/img-clip.nvim",
		},
		config = function()
			require("copilot.copilots")
		end,
	},

	-- Harpoon (harpoon2 branch), lazy-loaded on its keymaps.
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
			{ "<leader>v", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
			{ "<leader>q", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
			{ "<leader>w", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
			{ "<leader>e", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
			{ "<leader>r", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
		},
		config = function()
			require("harpoon").setup({})
		end,
	},

	-- Flash motions, lazy-loaded on its keymaps.
	{
		"folke/flash.nvim",
		keys = {
			{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
			{ "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
			{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
			{ "<c-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle Flash Search" },
		},
		config = function()
			require("flash").setup({})
		end,
	},

	-- Trouble diagnostics, lazy-loaded on its keymap / command.
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		keys = {
			{ "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>", desc = "Trouble diagnostics" },
		},
		config = function()
			require("trouble").setup({})
		end,
	},

	-- Undotree, lazy-loaded on its command / keymap.
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		keys = {
			{ "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Undotree" },
		},
	},

	-- Glance (LSP peek), lazy-loaded on its keymaps / command. Configured in
	-- plugins/glance.lua.
	{
		"dnlhc/glance.nvim",
		cmd = "Glance",
		keys = {
			{ "gD", "<CMD>Glance definitions<CR>", desc = "Glance definitions" },
			{ "gR", "<CMD>Glance references<CR>", desc = "Glance references" },
			{ "gY", "<CMD>Glance type_definitions<CR>", desc = "Glance type definitions" },
			{ "gM", "<CMD>Glance implementations<CR>", desc = "Glance implementations" },
		},
		config = function()
			require("plugins.glance")
		end,
	},

	-- SQL: dadbod stack, lazy-loaded on sql filetypes or the DBUI command.
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			"tpope/vim-dadbod",
			"kristijanhusak/vim-dadbod-completion",
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		ft = { "sql", "mysql", "plsql" },
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
}, {
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
	change_detection = { notify = false },
})

-- ---------------------------------------------------------------------------
-- Eager plugin configuration (plugins above are already on the rtp now).
-- ---------------------------------------------------------------------------

require("treesitter.treesitter")
require("mini")
require("noice.noice")
require("snacks.snacks")
require("formatting.formatting")
require("lint.lint")

require("oil").setup({
	keymaps = {
		["g?"] = { "actions.show_help", mode = "n" },
		["<CR>"] = "actions.select",
		["<C-s>"] = { "actions.select", opts = { vertical = true } },
		["<C-h>"] = { "actions.select", opts = { horizontal = true } },
		["<C-t>"] = { "actions.select", opts = { tab = true } },
		["<C-p>"] = "actions.preview",
		["<C-c>"] = { "actions.close", mode = "n" },
		["<C-l>"] = "actions.refresh",
		["-"] = { "actions.parent", mode = "n" },
		["_"] = { "actions.open_cwd", mode = "n" },
		["`"] = { "actions.cd", mode = "n" },
		["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
		["gs"] = { "actions.change_sort", mode = "n" },
		["gx"] = "actions.open_external",
		["g."] = { "actions.toggle_hidden", mode = "n" },
		["g\\"] = { "actions.toggle_trash", mode = "n" },
	},
	view_options = {
		show_hidden = true,
	},
	columns = {
		"icon",
	},
	default_file_explorer = true,
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
})

require("nvim-autopairs").setup()

require("cloak").setup({
	enabled = true,
	cloak_character = "*",
	patterns = {
		{
			file_pattern = {
				".env*",
			},
			cloak_pattern = "=.+",
		},
	},
})

local function git_interactive_rebase_to_merge_base()
	-- Get the current branch name
	local current_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("%s+", "")
	-- Get the merge base commit hash between the current branch and origin/master
	local merge_base = vim.fn.system("git merge-base " .. current_branch .. " origin/main"):gsub("%s+", "")
	-- Perform the interactive rebase
	vim.cmd("Git rebase -i " .. merge_base)
end
-- Expose the function globally so it can be called from Neovim's command-line mode
_G.git_interactive_rebase_to_merge_base = git_interactive_rebase_to_merge_base
vim.api.nvim_create_user_command("IRebase", git_interactive_rebase_to_merge_base, {})

require("gitsigns").setup({
	current_line_blame = true,
	numhl = true,
})

vim.keymap.set("n", "<leader>to", function()
	vim.cmd("call overlength#toggle()")
end)
vim.cmd("call overlength#disable()")
vim.cmd("call overlength#set_highlight('NONE', 'NONE')")

require("marks").setup({})
