local kind_icons = {
	Text = " ",
	Method = "󰆧 ",
	Function = "󰊕 ",
	Constructor = " ",
	Field = "󰇽 ",
	Variable = "󰂡 ",
	Class = "󰠱 ",
	Interface = " ",
	Module = " ",
	Property = "󰜢 ",
	Unit = " ",
	Value = "󰎠 ",
	Enum = "",
	Keyword = "󰌋 ",
	Snippet = " ",
	Color = "󰏘 ",
	File = "󰈙 ",
	Reference = " ",
	Folder = "󰉋 ",
	EnumMember = " ",
	Constant = "󰏿 ",
	Struct = " ",
	Event = " ",
	Operator = "󰆕 ",
	TypeParameter = "󰅲 ",
}

vim.pack.add({ "https://github.com/saghen/blink.compat" })
require("blink.compat").setup()

vim.pack.add({ {
	src = "https://github.com/L3MON4D3/LuaSnip",
	version = vim.version.range("2.*"),
} })
require("luasnip").setup()

vim.pack.add({ "https://github.com/fang2hou/blink-copilot" })
require("blink-copilot").setup({
	max_completions = 1, -- Global default for max completions
	max_attempts = 2, -- Global default for max attempts
})

vim.pack.add({
	{
		src = "https://github.com/saghen/blink.cmp",
		dependencies = {
			"saghen/blink.compat",
			"L3MON4D3/LuaSnip",
		},
		version = "1.*",
		opts = {
			opts_extend = {
				"sources.completion.enabled_providers",
				"sources.compat",
				"sources.default",
			},
		},
	},
})
local types = require("blink.cmp.types")
require("blink.cmp").setup({
	keymap = {
		["<Tab>"] = {
			"snippet_forward",
			function(cmp)
				if vim.b[vim.api.nvim_get_current_buf()].nes_state then
					cmp.hide()
					return require("sidekick").new_jump_or_apply()
				end
				if cmp.snippet_active() then
					return cmp.accept()
				else
					return cmp.select_and_accept()
				end
			end,
			"fallback",
		},
	},
	snippets = { preset = "luasnip" },
	appearance = {
		kind_icons = kind_icons,
		-- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
		-- adjusts spacing to ensure icons are aligned
		nerd_font_variant = "normal",
	},
	cmdline = {
		enabled = true,
		completion = {
			menu = { auto_show = true },
			ghost_text = { enabled = true },
		},
	},
	completion = {
		menu = {
			--     draw = {
			--         columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
			--         treesitter = { "lsp" },
			--     },
			-- border = "rounded",
			max_height = 25,
			border = nil,
			--     winhighlight =
			--     "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
			--     scrollbar = true,
		},

		documentation = { auto_show = true, auto_show_delay_ms = 500 },
		ghost_text = { enabled = true },
	},

	-- experimental signature help support
	signature = { enabled = true },
	sources = {
		-- default = { "supermaven", "copilot", "snippets", "lsp", "path", "buffer", "avante_commands", "avante_mentions", "avante_files", },
		default = { "snippets", "lsp", "path", "buffer" },
		per_filetype = {
			sql = { "snippets", "dadbod", "buffer" },
			mysql = { "snippets", "dadbod", "buffer" },
			plsql = { "snippets", "dadbod", "buffer" },
		},
		providers = {
			dadbod = {
				name = "Dadbod",
				module = "vim_dadbod_completion.blink",
			},
		},
	},
})
