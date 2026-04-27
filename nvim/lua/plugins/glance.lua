vim.pack.add({ "https://github.com/dnlhc/glance.nvim" })

vim.keymap.set("n", "gD", "<CMD>Glance definitions<CR>")
vim.keymap.set("n", "gR", "<CMD>Glance references<CR>")
vim.keymap.set("n", "gY", "<CMD>Glance type_definitions<CR>")
vim.keymap.set("n", "gM", "<CMD>Glance implementations<CR>")

local function set_glance_highlights()
	local bg = "#2a2937"
	local set_hl = vim.api.nvim_set_hl
	set_hl(0, "GlancePreviewNormal", { bg = bg })
	set_hl(0, "GlancePreviewSignColumn", { bg = bg })
	set_hl(0, "GlancePreviewEndOfBuffer", { bg = bg })
	set_hl(0, "GlancePreviewLineNr", { bg = bg })
	set_hl(0, "GlancePreviewBorderBottom", { bg = bg, fg = bg })
	set_hl(0, "GlanceListNormal", { bg = bg })
	set_hl(0, "GlanceListEndOfBuffer", { bg = bg })
	set_hl(0, "GlanceListBorderBottom", { bg = bg, fg = bg })
	set_hl(0, "GlanceBorderTop", { bg = bg, fg = bg })
	set_hl(0, "GlanceWinBarFilename", { bg = bg })
	set_hl(0, "GlanceWinBarFilepath", { bg = bg })
	set_hl(0, "GlanceWinBarTitle", { bg = bg })
	set_hl(0, "GlanceIndent", { bg = bg })
end

local glance = require("glance")
local actions = glance.actions

glance.setup({
	height = 18,
	zindex = 45,
	preserve_win_context = true,

	detached = function(winid)
		return vim.api.nvim_win_get_width(winid) < 100
	end,

	preview_win_opts = {
		cursorline = true,
		number = true,
		wrap = true,
	},

	border = {
		enable = false,
		top_char = "―",
		bottom_char = "―",
	},

	list = {
		position = "right",
		width = 0.33,
	},

	theme = { enable = false },

	mappings = {
		list = {
			["j"] = actions.next,
			["k"] = actions.previous,
			["<Down>"] = actions.next,
			["<Up>"] = actions.previous,
			["<Tab>"] = actions.next_location,
			["<S-Tab>"] = actions.previous_location,
			["<C-u>"] = actions.preview_scroll_win(5),
			["<C-d>"] = actions.preview_scroll_win(-5),
			["v"] = actions.jump_vsplit,
			["s"] = actions.jump_split,
			["t"] = actions.jump_tab,
			["<CR>"] = actions.jump,
			["o"] = actions.jump,
			["l"] = actions.open_fold,
			["h"] = actions.close_fold,
			["<leader>l"] = actions.enter_win("preview"),
			["q"] = actions.close,
			["Q"] = actions.close,
			["<Esc>"] = actions.close,
			["<C-q>"] = actions.quickfix,
		},
		preview = {
			["Q"] = actions.close,
			["<Tab>"] = actions.next_location,
			["<S-Tab>"] = actions.previous_location,
			["<leader>l"] = actions.enter_win("list"),
		},
	},

	hooks = {
		before_open = function(results, open, _jump, _method)
			set_glance_highlights()
			open(results)
		end,
	},

	folds = {
		fold_closed = "",
		fold_open = "",
		folded = true,
	},

	indent_lines = {
		enable = true,
		icon = "│",
	},

	winbar = {
		enable = true,
	},

	use_trouble_qf = false,
})

set_glance_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_glance_highlights })
