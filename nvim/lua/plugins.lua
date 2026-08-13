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

vim.pack.add({ "https://github.com/folke/trouble.nvim" })
require("trouble").setup({})
vim.keymap.set("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>")

-- Undo history: Snacks.picker.undo() (<leader>su, see lua/snacks/snacks.lua)
-- covers this already, so no separate undotree.nvim plugin.

-- mini.surround instead of tpope/vim-surround: same mini.* family as
-- mini.ai/mini.icons (see lua/mini/init.lua), actively maintained, and
-- configured here with the exact ys/cs/ds/yss keys vim-surround users
-- already know (mini's docs call this out explicitly as the "migrate from
-- vim-surround" mapping).
vim.pack.add({ "https://github.com/echasnovski/mini.surround" })
require("mini.surround").setup({
	mappings = {
		add = "ys",
		delete = "ds",
		find = "yf",
		find_left = "yF",
		highlight = "yh",
		replace = "cs",
		update_n_lines = "yn",
	},
})

vim.pack.add({ "https://github.com/chentoast/marks.nvim" })
require("marks").setup({})

require("fff")
require("plugins.glance")

-- mini.clue: which-key-style "next key" popup, same mini.* family as
-- mini.ai/mini.icons/mini.surround. It auto-generates its hints from each
-- keymap's `desc`, so most of this is just labeling the leader-prefix
-- *groups* (the prefixes that aren't a mapping themselves, only their
-- continuations are) -- everything else is already described where the
-- keymap is defined.
vim.pack.add({ "https://github.com/echasnovski/mini.clue" })
do
	local miniclue = require("mini.clue")
	miniclue.setup({
		triggers = {
			-- Leader group
			{ mode = "n", keys = "<Leader>" },
			{ mode = "x", keys = "<Leader>" },

			-- `g` key (LSP goto/peek keys, Glance, plus the Helix-ish
			-- g./ga/gm additions in lua/keymaps.lua)
			{ mode = "n", keys = "g" },
			{ mode = "x", keys = "g" },

			-- Marks
			{ mode = "n", keys = "'" },
			{ mode = "n", keys = "`" },
			{ mode = "x", keys = "'" },
			{ mode = "x", keys = "`" },

			-- Registers
			{ mode = "n", keys = '"' },
			{ mode = "x", keys = '"' },
			{ mode = "i", keys = "<C-r>" },
			{ mode = "c", keys = "<C-r>" },

			-- Window commands
			{ mode = "n", keys = "<C-w>" },

			-- `z` key (folds, scrolling, spelling)
			{ mode = "n", keys = "z" },
			{ mode = "x", keys = "z" },
		},

		clues = {
			-- Built-in generators for the non-leader triggers above.
			miniclue.gen_clues.g(),
			miniclue.gen_clues.marks(),
			miniclue.gen_clues.registers(),
			miniclue.gen_clues.windows(),
			miniclue.gen_clues.z(),

			-- Leader group labels, in the same order they show up in
			-- lua/snacks/snacks.lua / this file's multicursor block / etc.
			{ mode = "n", keys = "<Leader>f", desc = "+find" },
			{ mode = "n", keys = "<Leader>g", desc = "+git" },
			{ mode = "n", keys = "<Leader>s", desc = "+search" },
			{ mode = "n", keys = "<Leader>u", desc = "+ui/toggle" },
			{ mode = "n", keys = "<Leader>c", desc = "+code" },
			{ mode = "n", keys = "<Leader>r", desc = "+refactor (or harpoon 4: r)" },
			{ mode = "n", keys = "<Leader>t", desc = "+trouble/context" },
			{ mode = "n", keys = "<Leader>M", desc = "+multicursor" },
			{ mode = "x", keys = "<Leader>M", desc = "+multicursor" },
		},

		window = {
			delay = 300,
			config = {
				width = "auto",
			},
		},
	})
end

-- Helix-inspired multiple cursors/selections. Helix treats *everything* as a
-- selection and lets you multiply it (`C`/`Alt-C` copy the selection to the
-- next/prev line, `s` selects every regex match inside the current
-- selection, etc). Neovim has no native selection-first model, but
-- multicursor.nvim gets us the closest practical equivalent: real multiple
-- cursors that behave like normal vim once you have them.
--
-- Bindings mirror Helix's *intent* (see ~/dotfiles-pub/helix/config.toml for
-- the equivalent "make helix feel like nvim" mapping in reverse):
--   <C-Down>/<C-Up>  == Helix `C` / `Alt-C`   (copy cursor to next/prev line)
--   <C-n>/<C-p>      == Helix `*` + `n`/`N`   (add cursor at next/prev match)
--   <leader>Mm       == Helix `s`             (select regex matches inside selection)
--   <leader>Ms       == Helix `S`             (split selection by regex)
--   <leader>Ma       == Helix `%` + match-all (add cursor on every match at once)
--   Tab/S-Tab        == Helix `)`/`(`         (rotate primary selection) -- only
--                                                while multiple cursors are active
--   <Esc>            == Helix `,`             (collapse back down to one cursor)
vim.pack.add({ { src = "https://github.com/jake-stewart/multicursor.nvim", version = "1.0" } })
do
	local mc = require("multicursor-nvim")
	mc.setup()

	local set = vim.keymap.set

	-- Add/skip a cursor directly above or below (Helix: C / Alt-C).
	set({ "n", "x" }, "<C-Down>", function()
		mc.lineAddCursor(1)
	end, { desc = "Add cursor below" })
	set({ "n", "x" }, "<C-Up>", function()
		mc.lineAddCursor(-1)
	end, { desc = "Add cursor above" })
	set({ "n", "x" }, "<leader>M<Down>", function()
		mc.lineSkipCursor(1)
	end, { desc = "Skip cursor below" })
	set({ "n", "x" }, "<leader>M<Up>", function()
		mc.lineSkipCursor(-1)
	end, { desc = "Skip cursor above" })

	-- Add/skip a cursor by matching the word or selection under the
	-- cursor (Helix: `*` to set the search register then `n`/`N`).
	set({ "n", "x" }, "<C-n>", function()
		mc.matchAddCursor(1)
	end, { desc = "Add cursor at next match" })
	set({ "n", "x" }, "<C-p>", function()
		mc.matchAddCursor(-1)
	end, { desc = "Add cursor at prev match" })
	set({ "n", "x" }, "<leader>Mx", function()
		mc.matchSkipCursor(1)
	end, { desc = "Skip next match" })
	set({ "n", "x" }, "<leader>MX", function()
		mc.matchSkipCursor(-1)
	end, { desc = "Skip prev match" })

	-- Add a cursor on every match in the buffer at once
	-- (Helix-ish: select word, then act on ALL instances).
	set({ "n", "x" }, "<leader>Ma", mc.matchAllAddCursors, { desc = "Add cursor on all matches" })

	-- Helix `s`: select every regex match inside the current
	-- selection(s). Helix `S`: split the selection by regex.
	set("x", "<leader>Mm", mc.matchCursors, { desc = "Select regex matches in selection" })
	set("x", "<leader>Ms", mc.splitCursors, { desc = "Split selection by regex" })

	-- One cursor per line of a paragraph/visual block (Helix-ish
	-- bulk-select-then-edit workflow): `<leader>Moap`.
	set({ "n", "x" }, "<leader>Mo", mc.addCursorOperator, { desc = "Add cursor per line (operator)" })

	-- Align cursor columns, e.g. after adding cursors on `=` signs.
	set("n", "<leader>M=", mc.alignCursors, { desc = "Align cursor columns" })

	-- Ctrl+click to add/remove a cursor with the mouse.
	set("n", "<C-LeftMouse>", mc.handleMouse)
	set("n", "<C-LeftDrag>", mc.handleMouseDrag)
	set("n", "<C-LeftRelease>", mc.handleMouseRelease)

	-- Disable/enable cursors so only the main one moves.
	set({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "Toggle extra cursors" })

	-- Bring back cursors after clearing them by accident.
	set("n", "<leader>Mv", mc.restoreCursors, { desc = "Restore last cursors" })

	-- Layer mappings only apply while there are multiple cursors, so
	-- they can safely reuse otherwise-common keys.
	mc.addKeymapLayer(function(layerSet)
		-- Rotate the primary cursor (Helix `)` / `(`).
		layerSet({ "n", "x" }, "<Tab>", mc.nextCursor, { desc = "Next cursor" })
		layerSet({ "n", "x" }, "<S-Tab>", mc.prevCursor, { desc = "Prev cursor" })

		-- Drop the primary cursor.
		layerSet({ "n", "x" }, "<leader>Mc", mc.deleteCursor, { desc = "Delete cursor" })

		-- Collapse back to a single cursor (Helix `,`).
		layerSet("n", "<esc>", function()
			if not mc.cursorsEnabled() then
				mc.enableCursors()
			else
				mc.clearCursors()
			end
		end, { desc = "Collapse cursors" })
	end)

	-- Match the minimal colorscheme instead of the plugin defaults.
	local hl = vim.api.nvim_set_hl
	hl(0, "MultiCursorCursor", { reverse = true })
	hl(0, "MultiCursorVisual", { link = "Visual" })
	hl(0, "MultiCursorSign", { link = "SignColumn" })
	hl(0, "MultiCursorMatchPreview", { link = "Search" })
	hl(0, "MultiCursorDisabledCursor", { reverse = true })
	hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
	hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
end
