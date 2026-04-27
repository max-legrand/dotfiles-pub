require("treesitter.treesitter")

-- Shared dependencies needed by noice, avante, 99, etc.
vim.pack.add({ "https://github.com/MunifTanjim/nui.nvim" })
vim.pack.add({ "https://github.com/saghen/blink.compat" })
require("blink.compat").setup()

vim.api.nvim_create_autocmd("InsertEnter", {
	once = true,
	callback = function()
		require("completion.blink")
	end,
})
vim.defer_fn(function()
	require("copilot.copilots")
end, 100)
require("formatting.formatting")
require("lint.lint")
require("mini")
require("noice.noice")
require("snacks.snacks")
require("sql.sql")

vim.pack.add({ "https://github.com/stevearc/oil.nvim" })
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

vim.pack.add({ "https://github.com/windwp/nvim-autopairs" })
require("nvim-autopairs").setup()

vim.pack.add({ "https://github.com/laytan/cloak.nvim" })
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

vim.pack.add({ "https://github.com/rktjmp/lush.nvim" })
vim.pack.add({ "https://github.com/zenbones-theme/zenbones.nvim" })

vim.pack.add({ "https://github.com/tpope/vim-fugitive" })

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

vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
require("gitsigns").setup({
	current_line_blame = true,
	numhl = true,
})

vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })
vim.pack.add({ {
	src = "https://github.com/ThePrimeagen/harpoon",
	version = "harpoon2",
} })
local harpoon = require("harpoon")
harpoon.setup({})
vim.keymap.set("n", "<leader>a", function()
	harpoon:list():add()
end)
vim.keymap.set("n", "<leader>v", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end)
vim.keymap.set("n", "<leader>q", function()
	harpoon:list():select(1)
end)
vim.keymap.set("n", "<leader>w", function()
	harpoon:list():select(2)
end)
vim.keymap.set("n", "<leader>e", function()
	harpoon:list():select(3)
end)
vim.keymap.set("n", "<leader>r", function()
	harpoon:list():select(4)
end)

vim.pack.add({ "https://github.com/folke/flash.nvim" })
require("flash").setup({})
vim.keymap.set({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "o", "x" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash Treesitter" })
vim.keymap.set({ "o", "x" }, "R", function()
	require("flash").treesitter_search()
end, { desc = "Treesitter Search" })
vim.keymap.set("c", "<c-s>", function()
	require("flash").toggle()
end, { desc = "Toggle Flash Search" })

vim.pack.add({ "https://github.com/tjdevries/overlength.vim" })
vim.cmd("call overlength#disable()")
vim.cmd("call overlength#set_highlight('NONE', 'NONE')")
vim.keymap.set("n", "<leader>to", function()
	vim.cmd("call overlength#toggle()")
end)

vim.pack.add({ "https://github.com/folke/trouble.nvim" })
require("trouble").setup({})
vim.keymap.set("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>")

vim.pack.add({ "https://github.com/mbbill/undotree" })
vim.keymap.set("n", "<leader>uu", "<cmd>UndotreeToggle<cr>")

vim.pack.add({ "https://github.com/tpope/vim-surround" })

vim.pack.add({ "https://github.com/chentoast/marks.nvim" })
require("marks").setup({})

require("fff")
require("plugins.glance")
