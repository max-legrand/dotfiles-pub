local bindings = require "plugin-view.bindings"
local config = require "plugin-view.config"
local utils = require "plugin-view.utils"
local M = {
    plugins = {},
}

M.open = function()
    local float = utils.create_floating_win()
    bindings.setup(float.buf, float.win)
    utils.populate_buf(float.buf, M.plugins)
end

---@param opts plugin-view.options
M.setup = function(opts)
    M.plugins = vim.pack.get()
    config.extend_options(opts)
end

return M
