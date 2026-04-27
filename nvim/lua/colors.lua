vim.g.dracula_colorterm = 0
vim.opt.shortmess = vim.opt.shortmess + { I = true }
vim.o.background = "dark"

require("colorschemes.minimal")
require("lualine.lualine")
