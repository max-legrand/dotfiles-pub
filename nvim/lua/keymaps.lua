vim.g.mapleader = " "
vim.keymap.set("n", "<leader>lr", ":lsp restart<CR>")
vim.keymap.set("n", "<leader>pv", ":Oil<CR>")
vim.keymap.set("n", "<leader>R", ":edit<CR>") -- Reload buffer from disk

-- jj to escape
vim.keymap.set("i", "jj", "<Esc>")

-- Clear highlight
vim.keymap.set("n", "<leader>cH", ":noh<CR>")

-- move command
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
-- Visual line jump
vim.keymap.set("v", "<leader>j", "<C-d>zz")
vim.keymap.set("v", "<leader>k", "<C-u>zz")
-- Keep cursor in same spot
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- format
vim.keymap.set("n", "<leader>fm", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>fw", [[:noautocmd w<CR>]])

-- Remap H and L to move to the start and end of the line
vim.keymap.set("n", "H", "g^")
vim.keymap.set("n", "L", "g$")

-- map J and K to ctrl+d and ctrl+u
vim.keymap.set("n", "J", "<C-d>zz")
vim.keymap.set("n", "K", "<C-u>zz")

vim.api.nvim_set_keymap(
	"n",
	"<leader>+",
	':exe "resize " . (winheight(0) * 3/2)<CR>',
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>-",
	':exe "resize " . (winheight(0) * 2/3)<CR>',
	{ noremap = true, silent = true }
)

-- Go to type definition
vim.keymap.set("n", "gy", function()
	vim.lsp.buf.type_definition()
end, opts)

vim.keymap.set("n", "gd", function()
	vim.lsp.buf.definition()
end, opts)

vim.keymap.set("n", "gh", function()
	vim.lsp.buf.hover()
end, opts)

vim.keymap.set("n", "<leader>o", function()
	vim.lsp.buf.workspace_symbol()
end, opts)

vim.keymap.set("n", "<leader>p", function()
	vim.diagnostic.open_float()
end, opts)

vim.diagnostic.config({
	float = { border = "rounded" },
})

local function open_diagnostic_float(_, bufnr)
	vim.diagnostic.open_float({
		bufnr = bufnr,
		scope = "cursor",
		focus = false,
	})
end

vim.keymap.set("n", "gn", function()
	vim.diagnostic.jump({ count = 1, on_jump = open_diagnostic_float })
end, opts)
vim.keymap.set("n", "gN", function()
	vim.diagnostic.jump({ count = -1, on_jump = open_diagnostic_float })
end, opts)

vim.keymap.set("n", "<leader>ca", function()
	vim.lsp.buf.code_action()
end, opts)

vim.keymap.set("n", "<leader>rr", function()
	vim.lsp.buf.references()
end, opts)

vim.keymap.set("n", "<leader>rn", function()
	vim.lsp.buf.rename()
end, opts)

vim.keymap.set("i", "<C-h>", function()
	vim.lsp.buf.signature_help()
end, opts)

if vim.lsp.inlay_hint then
	vim.lsp.inlay_hint.enable(true, {})
end

vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y<CR>')
vim.keymap.set({ "n", "v", "x" }, "<leader>d", '"+d<CR>')

vim.keymap.set("n", "<leader>so", ":update<CR> :source<CR>")
vim.keymap.set("n", "<leader>Q", ":quit<CR>")
vim.keymap.set("n", "<leader>m", ":write<CR>")
vim.keymap.set("n", "<leader>X", ":bd<CR>")

vim.keymap.set("n", "<space>gt", function()
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, 15)
end)

vim.keymap.set("t", "<space><Esc>", "<C-\\><C-n>", { silent = true })

vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
