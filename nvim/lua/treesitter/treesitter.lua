-- Treesitter highlight/indent are built-in on nvim 0.12, enabled by default.
-- No need to call vim.treesitter.start() — it runs automatically per buffer.

-- Parsers are installed per-machine into stdpath('data')/site/parser/
-- so we don't ship unsigned .so binaries (Gatekeeper on macOS, wrong format on Windows).
-- install() is async and skips already-installed parsers, so it's cheap on every startup.
require("nvim-treesitter").install({
	"bash",
	"c",
	"css",
	"go",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"rust",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
	"zig",
})

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
