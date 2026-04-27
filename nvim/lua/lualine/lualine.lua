vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })
local uv = vim.uv or vim.loop

-- cache for the change id
local jj_cache_val, jj_cache_at

local function get_jj_change_id()
	-- return cached value if it’s fresh (<2s old)
	local now = uv.now()
	if jj_cache_val and jj_cache_at and (now - jj_cache_at < 2000) then
		return jj_cache_val
	end

	-- check for .jj dir
	local st = uv.fs_stat(".jj")
	if not (st and st.type == "directory") then
		jj_cache_val = nil
		return ""
	end

	-- spawn jj asynchronously (no shell)
	local argv = {
		"jj",
		"log",
		"-r",
		"@",
		"--no-graph",
		"-T",
		'if(bookmarks, bookmarks.map(|r| r.name()).join(" "), change_id.short())',
	}

	if vim.system then
		vim.system(argv, { text = true, env = { PAGER = "" } }, function(res)
			if res.code == 0 and res.stdout then
				local out = res.stdout:gsub("%s+$", "")
				jj_cache_val, jj_cache_at = out, uv.now()
				-- force a redraw so lualine picks it up
				vim.schedule(function()
					vim.cmd("redrawstatus")
				end)
			end
		end)
	end

	-- while waiting, return old cached val or empty
	return jj_cache_val or ""
end

require("lualine").setup({
	options = {
		theme = "auto",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { get_jj_change_id, "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
})
