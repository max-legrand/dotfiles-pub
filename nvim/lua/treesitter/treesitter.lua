vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
vim.pack.add({
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		version = "main",
	},
})
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter-context" })

-- Treesitter highlight/indent are built-in on nvim 0.12, enabled by default.
-- No need to call vim.treesitter.start() — it runs automatically per buffer.

-- Incremental selection
vim.keymap.set("n", "<C-space>", function()
	vim.treesitter.incremental_selection.init()
end)
vim.keymap.set("x", "<C-space>", function()
	vim.treesitter.incremental_selection.node_incremental()
end)
vim.keymap.set("x", "<bs>", function()
	vim.treesitter.incremental_selection.node_decremental()
end)

-- Treesitter context
local tc_context = require("treesitter-context")
tc_context.setup({
	enable = false,
})
vim.keymap.set("n", "[c", function()
	tc_context.go_to_context()
end)
vim.keymap.set("n", "<leader>tc", function()
	tc_context.toggle()
end)
