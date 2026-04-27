-- AI assistants: Avante, Sidekick, Amp
-- Note: Copilot and Supermaven are loaded via completion/blink.lua on InsertEnter

-- Dependencies (loaded eagerly as they're shared)
vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })
vim.pack.add({ "https://github.com/MunifTanjim/nui.nvim" })
vim.pack.add({ "https://github.com/nvim-tree/nvim-web-devicons" })
vim.pack.add({ "https://github.com/HakonHarnes/img-clip.nvim" })
vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })

require("nvim-web-devicons").setup({})
require("img-clip").setup({})
require("render-markdown").setup({
	file_types = { "markdown" },
})
