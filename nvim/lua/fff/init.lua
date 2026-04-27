vim.pack.add({ "https://github.com/dmtrKovalenko/fff.nvim.git" })

-- Check if binary exists
local function binary_exists()
	local download = require("fff.download")
	local path = download.get_binary_path()
	local stat = vim.uv.fs_stat(path)
	return stat and stat.type == "file"
end

-- Setup fff.nvim and keys after UIEnter
vim.api.nvim_create_autocmd("UIEnter", {
	callback = function()
		-- Download or build binary if needed
		if not binary_exists() then
			local ok, err = pcall(function()
				local download = require("fff.download")
				download.download_or_build_binary()
			end)
			if not ok then
				vim.notify("Failed to download/build fff.nvim binary: " .. tostring(err), vim.log.levels.ERROR)
				return
			end
		end

		-- Load fff.main
		local fff = require("fff.main")

		-- Setup fff
		fff.setup({
			debug = {
				enabled = true,
				show_scores = true,
			},
		})

		-- Set up keybindings
		local opts = { noremap = true, silent = true }
		vim.keymap.set("n", "fF", "<cmd>lua require('fff.main').find_files()<CR>", opts)
		vim.keymap.set("n", "fG", "<cmd>lua require('fff.main').live_grep()<CR>", opts)
		vim.keymap.set(
			"n",
			"fZ",
			"<cmd>lua require('fff.main').live_grep({ grep = { modes = { 'fuzzy', 'plain' } } })<CR>",
			opts
		)
		vim.keymap.set(
			"n",
			"fC",
			"<cmd>lua require('fff.main').live_grep({ query = vim.fn.expand('<cword>') })<CR>",
			opts
		)
	end,
})
