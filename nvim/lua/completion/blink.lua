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

require("blink.cmp").setup({
	-- Pure-Lua matcher: skip the prebuilt Rust binary entirely so the vendored
	-- tree stays cross-platform. The matcher is per-keystroke hot, so cap the
	-- expensive bits: 1 typo of tolerance, no frecency/proximity scoring.
	fuzzy = {
		implementation = "lua",
		max_typos = function() return 1 end,
		frecency = { enabled = false },
		use_proximity = false,
	},
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
		list = { max_items = 25 },
		menu = {
			max_height = 25,
			border = nil,
		},
		documentation = { auto_show = true, auto_show_delay_ms = 500 },
		ghost_text = { enabled = true },
	},
	signature = { enabled = true },
	sources = {
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
