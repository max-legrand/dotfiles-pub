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
-- Keep cursor in same spot / centered
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- format
vim.keymap.set("n", "<leader>fm", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>fw", [[:noautocmd w<CR>]])

-- Remap H and L to move to the start and end of the line. Mapped in both
-- normal and visual/select mode so movement feels the same whether or not
-- there's an active selection (Helix's selection-first model doesn't
-- distinguish the two -- movement keys always behave the same). Not doing
-- the same for J/K: visual mode already claims those for moving the
-- selected lines up/down (see "move command" above); use <leader>j/<leader>k
-- there for centered half-page scrolling instead.
vim.keymap.set({ "n", "x" }, "H", "g^")
vim.keymap.set({ "n", "x" }, "L", "g$")

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

-- More Helix `g`oto-mode-flavored motions. Helix's own goto table (gh/gl/gs/
-- gd/gr/gy/... for line-start, line-end, definition, references, etc.)
-- mostly collides with the LSP peek/jump keys this config already had on
-- `g` before Helix was ever a consideration, so it isn't worth re-shuffling
-- those. These three are the ones that were still free and where the key
-- AND the meaning line up with Helix exactly:
--   g.  Helix "goto last modification" -> jump to the last change (`.)
--   ga  Helix "goto last accessed file" -> alternate file (<C-^>)
--   gm  bridges Helix's match-mode `mm` (jump to matching bracket/pair) --
--       plain `m` can't be repurposed in Vim, it's the builtin mark-setter,
--       so this reuses the `g` trigger instead of Helix's literal key.
vim.keymap.set("n", "g.", "`.", { desc = "Goto last modification" })
vim.keymap.set("n", "ga", "<C-^>", { desc = "Goto alternate file" })
vim.keymap.set({ "n", "x" }, "gm", "%", { desc = "Goto matching bracket/pair" })

-- Go to type definition
vim.keymap.set("n", "gy", function()
	vim.lsp.buf.type_definition()
end, { desc = "Goto Type Definition" })

vim.keymap.set("n", "gd", function()
	vim.lsp.buf.definition()
end, { desc = "Goto Definition" })

vim.keymap.set("n", "gh", function()
	vim.lsp.buf.hover()
end, { desc = "Hover" })

vim.keymap.set("n", "<leader>o", function()
	vim.lsp.buf.workspace_symbol()
end, { desc = "Workspace Symbol" })

vim.keymap.set("n", "<leader>p", function()
	vim.diagnostic.open_float()
end, { desc = "Line Diagnostics" })

vim.diagnostic.config({
	jump = { float = true },
	float = { border = "rounded" },
})
vim.keymap.set("n", "gn", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next Diagnostic" })
vim.keymap.set("n", "gN", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev Diagnostic" })

vim.keymap.set("n", "<leader>ca", function()
	vim.lsp.buf.code_action()
end, { desc = "Code Action" })

vim.keymap.set("n", "<leader>rr", function()
	vim.lsp.buf.references()
end, { desc = "References" })

vim.keymap.set("n", "<leader>rn", function()
	vim.lsp.buf.rename()
end, { desc = "Rename" })

vim.keymap.set("i", "<C-h>", function()
	vim.lsp.buf.signature_help()
end, { desc = "Signature Help" })

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

-- Note: <leader>gs is bound to the (more useful) Snacks git-status picker in
-- lua/snacks/snacks.lua. Fugitive's `:Git` / `:Git status` are still just a
-- command away if you want the interactive stage/unstage buffer.
