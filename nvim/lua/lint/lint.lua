vim.pack.add({ "https://github.com/mfussenegger/nvim-lint" })
local lint = require("lint")
global_diagnostics = {}
lint.linters_by_ft = {
	python = { "ruff" },
	go = {
		"golangcilint",
	},
	json = { "jq" },
	typescriptreact = { "oxlint" },
	svelte = { "biomejs" },
	-- cpp = { "cpplint", "cppcheck" },
	ruby = { "rubocop" },
}
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	callback = function()
		lint.try_lint()
	end,
})
