-- Lazy load SQL plugins on FileType sql/mysql/plsql
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "sql", "mysql", "plsql" },
	once = true,
	callback = function()
		vim.pack.add({ "https://github.com/tpope/vim-dadbod" })
		vim.pack.add({ "https://github.com/kristijanhusak/vim-dadbod-completion" })
		vim.pack.add({ "https://github.com/kristijanhusak/vim-dadbod-ui" })
		vim.g.db_ui_use_nerd_fonts = 1
	end,
})

-- Also load on DBUI command
vim.api.nvim_create_user_command("DBUI", function()
	vim.pack.add({ "https://github.com/tpope/vim-dadbod" })
	vim.pack.add({ "https://github.com/kristijanhusak/vim-dadbod-completion" })
	vim.pack.add({ "https://github.com/kristijanhusak/vim-dadbod-ui" })
	vim.g.db_ui_use_nerd_fonts = 1
	vim.cmd("DBUI")
end, {})
