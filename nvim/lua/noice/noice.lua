-- Notifications are owned by Snacks' notifier (lua/snacks/snacks.lua), not
-- nvim-notify: noice's "notify" view (used below for msg_showmode) is a
-- thin wrapper around `vim.notify`, so it renders through whatever
-- vim.notify is bound to. Running nvim-notify here too just meant two
-- notification backends fighting over vim.notify.
--
-- The plugin itself is installed by lazy (see lua/plugins.lua).
require("noice").setup({
	routes = {
		{
			view = "notify",
			filter = { event = "msg_showmode" },
		},
	},
	cmdline = {
		view = "cmdline",
	},
	lsp = {
		-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
		},
	},
	-- you can enable a preset for easier configuration
	presets = {
		bottom_search = true, -- use a classic bottom cmdline for search
		command_palette = false, -- position the cmdline and popupmenu together
		long_message_to_split = false, -- long messages will be sent to a split
		inc_rename = false, -- enables an input dialog for inc-rename.nvim
		lsp_doc_border = true, -- add a border to hover docs and signature help
	},
})
