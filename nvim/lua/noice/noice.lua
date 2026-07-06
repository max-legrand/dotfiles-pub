require("notify").setup({
	background_colour = "#111111",
	timeout = 1500,
	fps = 10,
	stages = "static",
	render = "compact",
	-- stages = vim.list_extend({
	-- 	function(state)
	-- 		if #state.open_windows >= 3 then
	-- 			return nil
	-- 		end
	-- 		return stages[1](state)
	-- 	end,
	-- }, vim.list_slice(stages, 2, #stages)),
})

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
