local opt = vim.opt
opt.encoding = "utf-8"

opt.listchars = {
	eol = "↲",
	tab = "» ",
	trail = "·",
	extends = "<",
	precedes = ">",
	conceal = "┊",
	nbsp = "␣",
}
opt.list = true
-- 2 spaces for each indentation
opt.shiftwidth = 4
-- insert 2 spaces for tab while editing
opt.tabstop = 4
opt.softtabstop = 4
opt.timeoutlen = 1000 -- time to wait for a mapped sequence to complete in milliseconds
opt.completeopt = "menuone,noselect" -- for autocomplete which we'll be doing in the future
opt.splitbelow = true -- force all horizontal splits to go below current window
opt.splitright = true -- force all vertical splits to go to the right of current window
opt.termguicolors = true -- enable 2 bit RGB colors, most modern terminal emulators support this
opt.autoindent = true -- auto indent when using `o` or `O`
opt.smartindent = true -- smart indenting
opt.wrap = false -- wrap lines
opt.cmdheight = 2 -- height of command bar
opt.fileencoding = "utf-8" -- encoding of files
opt.mouse = "a" -- enable mouse in all modes, for more options see :help 'mouse'
opt.ignorecase = true -- ignore case while searching
opt.smartcase = true -- ovveride ignore case if search pattern contains upper case characters
opt.number = true -- numbered lines
opt.relativenumber = true -- relative line numbers
opt.numberwidth = 4 -- number column width
opt.pumheight = 10 -- height of pop up menu
opt.scrolloff = 8 -- minimium number of lines above and below the cursor
opt.sidescrolloff = 8 -- minimum number of columns on the left and right of the cursor
opt.whichwrap:append("b,s,<,>,[,],h,l") -- see :help 'whichwrap'
opt.shortmess:append("c") -- see :help 'shortmess'
opt.showmode = false -- won't show the mode in the command bar

-- sync with system clipboard on focus
vim.api.nvim_create_autocmd({ "FocusGained" }, {
	pattern = { "*" },
	command = [[call setreg("@", getreg("+"))]],
})

-- sync with system clipboard on focus
vim.api.nvim_create_autocmd({ "FocusLost" }, {
	pattern = { "*" },
	command = [[call setreg("+", getreg("@"))]],
})
-- opt.clipboard = ""

opt.swapfile = false -- creates a swap file
opt.cursorline = true -- highlights the current line
-- opt.conceallevel = 0 -- to show text normally
vim.opt_local.conceallevel = 2
opt.signcolumn = "yes" -- always show the sign column
opt.undofile = true -- persistent undo

opt.expandtab = true -- use tabs
vim.cmd("set expandtab")

function ReplaceVisualSelectionInFile()
	-- Get the visual selection
	local _, start_line, start_col, _ = unpack(vim.fn.getpos("'<"))
	local _, end_line, end_col, _ = unpack(vim.fn.getpos("'>"))
	local selection = vim.fn.getline(start_line, end_line)

	-- Handle single line and multi-line selections
	if #selection == 1 then
		selection[1] = selection[1]:sub(start_col, end_col)
	else
		selection[1] = selection[1]:sub(start_col)
		selection[#selection] = selection[#selection]:sub(1, end_col)
	end

	-- Join the selection into a single string
	local search_text = table.concat(selection, "\n")

	-- Ask for the replacement text
	local replacement_text = vim.fn.input("Replace with: ")

	-- Escape special characters in the search text
	search_text = vim.fn.escape(search_text, "\\/")

	-- Perform the substitution in the entire file
	vim.cmd(string.format("%%s/%s/%s/gc", search_text, replacement_text))
end

-- Create a command to call the function
vim.api.nvim_create_user_command("ReplaceVisual", ReplaceVisualSelectionInFile, { range = true })

vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("custom-term", { clear = true }),
	callback = function()
		vim.opt.number = false
		vim.opt.relativenumber = false
	end,
})

vim.env.TERM = "tmux-256color"
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	command = "startinsert",
})
