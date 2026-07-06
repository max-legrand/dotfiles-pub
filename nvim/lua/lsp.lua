require("fidget").setup({
	notification = {
		poll_rate = 100,
		window = {
			winblend = 0,
		},
	},
})

-- Deduplicate diagnostics (workaround for ZLS sending duplicates)
local orig_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
	if result and result.diagnostics then
		local seen = {}
		local deduped = {}
		for _, d in ipairs(result.diagnostics) do
			local key = string.format(
				"%d:%d:%d:%d:%s",
				d.range.start.line,
				d.range.start.character,
				d.range["end"].line,
				d.range["end"].character,
				d.message
			)
			if not seen[key] then
				seen[key] = true
				table.insert(deduped, d)
			end
		end
		result.diagnostics = deduped
	end
	return orig_handler(err, result, ctx, config)
end

-- Suppress "No information available" notification on empty hover responses
local orig_hover = vim.lsp.handlers["textDocument/hover"]
vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
	if not (result and result.contents) then
		return
	end
	local c = result.contents
	if
		(type(c) == "string" and c == "")
		or (type(c) == "table" and vim.tbl_isempty(c))
		or (type(c) == "table" and c.value == "")
	then
		return
	end
	return orig_hover(err, result, ctx, config)
end

local lspconfig = require("lspconfig")
local util = require("lspconfig.util")
local capabilities = vim.lsp.protocol.make_client_capabilities()

vim.lsp.config["luals"] = {}
vim.lsp.enable("luals")

vim.lsp.enable("rust_analyzer")

-- vim.lsp.config["ocamllsp"] = {
-- 	cmd = { "ocamllsp" },
-- 	filetypes = {
-- 		"ocaml",
-- 		"ocaml.menhir",
-- 		"ocaml.interface",
-- 		"ocaml.ocamllex",
-- 		"reason",
-- 		"dune",
-- 	},
-- 	root_dir = lspconfig.util.root_pattern(
-- 		"*.opam",
-- 		"esy.json",
-- 		"package.json",
-- 		".git",
-- 		"dune-project",
-- 		"dune-workspace"
-- 	),
-- 	capabilities = capabilities,
-- }
-- vim.lsp.enable("ocamllsp")

require("lspconfig.configs").ty = {
	default_config = {
		cmd = { "uvx", "ty", "server" },
		filetypes = {
			"python",
		},
		capabilities = vim.tbl_deep_extend("force", capabilities, {
			textDocument = { inlayHint = { dynamicRegistration = false } },
		}),
	},
}
vim.lsp.config["ty"] = {}
vim.lsp.enable("ty")

vim.lsp.config("pyrefly", {
	cmd = { "uvx", "pyrefly", "lsp" },
	filetypes = {
		"python",
	},
	capabilities = {
		textDocument = { inlayHint = { dynamicRegistration = false } },
	},
})
vim.lsp.enable("pyrefly")

-- Monkey-patch nvim_buf_set_extmark to silently skip out-of-range inlay hints
local orig_set_extmark = vim.api.nvim_buf_set_extmark
vim.api.nvim_buf_set_extmark = function(bufnr, ns_id, line, col, opts)
	if opts and opts.virt_text_pos == "inline" then
		local ok, line_text = pcall(vim.api.nvim_buf_get_lines, bufnr, line, line + 1, false)
		if ok and line_text[1] and col > #line_text[1] then
			return 0
		end
	end
	return orig_set_extmark(bufnr, ns_id, line, col, opts)
end

require("lspconfig.configs").tsgo = {
	default_config = {
		cmd = { "tsgo", "--lsp", "-stdio" },
		filetypes = {
			"javascript",
			"javascriptreact",
			"javascript.jsx",
			"typescript",
			"typescriptreact",
			"typescript.tsx",
		},
		root_markers = {
			"tsconfig.json",
			"jsconfig.json",
			"package.json",
			".git",
			"tsconfig.base.json",
		},
		-- root_dir = function(bufnr, on_dir)
		-- 	local fname = vim.api.nvim_buf_get_name(bufnr)
		-- 	local found = util.root_pattern("package.json")(fname)
		-- 		or util.root_pattern("tsconfig.json")(fname)
		-- 		or util.root_pattern("bun.lock")(fname)
		-- 	if found then
		-- 		on_dir(found)
		-- 	end
		-- end,
	},
}
vim.lsp.config["tsgo"] = {}
vim.lsp.enable("tsgo")

vim.lsp.config["tailwindcss"] = {
	-- root_dir = lspconfig.util.root_pattern("package.json"),
	filetypes = {
		"html",
		"javascriptreact",
		"typescriptreact",
		"svelte",
		"ripple",
	},
	capabilities = capabilities,
	settings = {
		tailwindCSS = {
			includeLanguages = {
				ripple = "typescriptreact",
			},
		},
	},
}
vim.lsp.enable("tailwindcss")

-- Configure zls
-- local zls_bin = vim.fn.expand("~") .. "/bin/zls"
-- local zls_config = vim.fn.expand("~") .. "/.config/zls.json"
--
-- vim.lsp.config["zls"] = {
-- 	cmd = { zls_bin, "--config-path", zls_config },
-- }
vim.lsp.enable("zls")

-- -- Specify clang++ path
-- local clang_path = "/run/current-system/sw/bin/clang++"
-- if jit.os == "OSX" then
-- 	clang_path = "/usr/bin/clang++"
-- end
-- local query_driver = "--query-driver=" .. clang_path
--
-- local command_path = "/run/current-system/sw/bin/clangd"
-- if jit.os == "OSX" then
-- 	command_path = "/usr/bin/clangd"
-- end
--
-- vim.lsp.config["clangd"] = {
-- 	cmd = { command_path },
-- 	filetypes = {
-- 		"c",
-- 		"cpp",
-- 		"objc",
-- 		"objcpp",
-- 	},
-- 	settings = {
-- 		clangd = {
-- 			arguments = {
-- 				-- "--query-driver=/run/current-system/sw/bin/clang++",
-- 				query_driver,
-- 				"--background-index",
-- 			},
-- 		},
-- 	},
-- 	capabilities = capabilities,
-- }
-- vim.lsp.enable("clangd")
--
-- local function ruby_project_pattern(...)
-- 	local patterns = { "Gemfile" }
-- 	return require("lspconfig.util").root_pattern(table.unpack(patterns))(...)
-- end
-- local function steep_root_pattern(...)
-- 	local patterns = { "Steepfile" }
-- 	return require("lspconfig.util").root_pattern(table.unpack(patterns))(...)
-- end
--
-- vim.lsp.config["steep"] = {
-- 	cmd = { "steep", "langserver" },
-- 	filetypes = { "ruby" },
-- 	root_dir = function(fname)
-- 		return steep_root_pattern(fname)
-- 	end,
-- }
-- vim.lsp.enable("steep")
--
-- vim.lsp.config["ruby_lsp"] = {
-- 	filetypes = { "ruby" },
-- 	root_dir = function(fname)
-- 		return ruby_project_pattern(fname)
-- 	end,
-- }
-- vim.lsp.enable("ruby_lsp")

-- Wrap the default handler to suppress -32603 (InternalError) from
-- ocamllsp on unparseable buffers.
local make_silent_handler = function(method)
	local default_handler = vim.lsp.handlers[method]
	return function(err, result, ctx, config)
		if err and err.code == -32603 then
			return
		end
		if default_handler then
			return default_handler(err, result, ctx, config)
		end
	end
end
