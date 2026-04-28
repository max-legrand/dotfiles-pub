-- Air-gapped mode: when pack/vendor/start/ exists, plugins are vendored
-- and auto-loaded by Neovim's built-in package mechanism. Stub vim.pack.add
-- so the existing config keeps working without trying to download anything.
-- Set NVIM_NO_VENDOR=1 to bypass (e.g., to refresh nvim-pack-lock.json on the home machine).
local vendor_dir = vim.fn.stdpath("config") .. "/pack/vendor/start"
if vim.env.NVIM_NO_VENDOR ~= "1" and vim.fn.isdirectory(vendor_dir) == 1 then
	vim.pack = vim.pack or {}
	vim.pack.add = function(_) end

	-- macOS Gatekeeper prompts the user the first time it dlopens an unsigned
	-- .dylib/.so that carries com.apple.quarantine (set by Safari downloads or
	-- archive extractors). Strip the xattr from the vendor tree on first run.
	-- The marker file makes this a one-time cost per clone.
	if vim.fn.has("mac") == 1 and vim.fn.executable("xattr") == 1 then
		local marker = vendor_dir .. "/.quarantine-cleared"
		if vim.uv.fs_stat(marker) == nil then
			vim.system({ "xattr", "-dr", "com.apple.quarantine", vendor_dir }):wait()
			local f = io.open(marker, "w")
			if f then f:close() end
		end
	end
end
