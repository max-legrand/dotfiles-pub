-- NOTE: this module is not required from init.lua in the public config, so
-- roslyn.nvim is not declared in lua/plugins.lua. If you want C# support, add
-- "seblj/roslyn.nvim" as a lazy spec and require this module.
require("roslyn").setup({
	filewatching = "off",
	extensions = {
		razor = { enabled = false },
	},
	config = {
		capabilities = vim.lsp.protocol.make_client_capabilities(),
		settings = {
			["csharp|inlay_hints"] = {
				csharp_enable_inlay_hints_for_parameters = true,
				csharp_enable_inlay_hints_for_types = true,
			},
			["csharp|code_lens"] = {
				dotnet_enable_references_code_lens = true,
			},
		},
	},
})
