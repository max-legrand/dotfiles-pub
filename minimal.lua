-- Minimal colorscheme (no external dependencies)

local colors_name = "minimal"
vim.g.colors_name = colors_name

-- Read theme mode from fish config
local theme_file = os.getenv("HOME") .. "/.config/fish/theme_mode"
local theme_mode = "dark"
do
    local file = io.open(theme_file, "r")
    if file then
        theme_mode = file:read("*l") or "dark"
        file:close()
    end
end
vim.o.background = theme_mode

-- ToggleTheme command
vim.api.nvim_create_user_command("ToggleTheme", function()
    local new_bg = vim.o.background == "light" and "dark" or "light"
    vim.o.background = new_bg
    vim.cmd("hi clear")
    vim.cmd("colorscheme minimal")
    local file = io.open(theme_file, "w")
    if file then
        file:write(new_bg)
        file:close()
    end
end, {})

local bg = vim.o.background

----------------------------------------------------------------------
-- Palette (hex strings, no HSLuv conversion needed)
----------------------------------------------------------------------
local palette
if bg == "light" then
    palette = {
        fg        = "#22223b",
        pink      = "#a18fff",
        gray      = "#6c6f93",
        green     = "#00b894",
        darkgreen = "#00997a",
        yellow    = "#bfa05a",
        string    = "#3b5998",
        red       = "#e57373",
        inlay     = "#8e7cc3",
        bg        = "#ece7f6",
        -- Derived shades for UI surfaces
        bg_alt    = "#dcd5ec",
        bg_dim    = "#c8c0db",
        sel       = "#cdc0e8",
    }
else
    palette = {
        fg        = "#dddddd",
        pink      = os.getenv("HIGHLIGHT") or "#CDC1FF",
        gray      = "#888888",
        green     = "#00ffaa",
        darkgreen = "#00e699",
        yellow    = "#d6c5a5",
        string    = "#FFDCCC",
        red       = "#ed91b1",
        inlay     = "#e0d4ef",
        bg        = "#22212C",
        bg_alt    = "#2c2b38",
        bg_dim    = "#3a3947",
        sel       = "#454057",
    }
end

local p = palette
local set_hl = vim.api.nvim_set_hl

-- Helper: set highlight, treating "none" string as NONE
local function hl(name, opts)
    -- Allow {bg="none"} shorthand
    for _, k in ipairs({ "bg", "fg", "sp" }) do
        if opts[k] == "none" then opts[k] = "NONE" end
    end
    set_hl(0, name, opts)
end

----------------------------------------------------------------------
-- Base / editor UI
----------------------------------------------------------------------
local normal_bg = (bg == "light") and p.bg or "NONE"

hl("Normal",        { fg = p.fg, bg = normal_bg })
hl("NormalNC",      { fg = p.fg, bg = normal_bg })
hl("NormalFloat",   { fg = p.fg, bg = "NONE" })
hl("FloatBorder",   { fg = (bg == "dark") and "#ffffff" or p.gray, bg = "NONE" })
hl("FloatTitle",    { fg = p.pink, bg = "NONE", bold = true })
hl("Float",         { bg = "NONE" })

hl("LineNr",        { fg = p.gray, bg = "NONE" })
hl("CursorLineNr",  { fg = p.pink, bg = "NONE", bold = true })
hl("CursorLine",    { bg = p.sel })
hl("CursorColumn",  { bg = p.sel })
hl("ColorColumn",   { bg = p.bg_alt })
hl("SignColumn",    { bg = "NONE" })
hl("FoldColumn",    { fg = p.gray, bg = "NONE" })
hl("Folded",        { fg = p.gray, bg = p.bg_alt })

hl("StatusLine",    { fg = p.fg, bg = p.bg_alt })
hl("StatusLineNC",  { fg = p.gray, bg = p.bg_alt })
hl("WinSeparator",  { fg = p.gray, bg = "NONE" })
hl("VertSplit",     { fg = p.gray, bg = "NONE" })

hl("TabLine",       { fg = p.gray, bg = p.bg_alt })
hl("TabLineFill",   { bg = p.bg_alt })
hl("TabLineSel",    { fg = p.fg, bg = p.bg, bold = true })

hl("Pmenu",         { fg = p.fg, bg = p.bg_alt })
hl("PmenuSel",      { fg = p.fg, bg = p.sel, bold = true })
hl("PmenuSbar",     { bg = p.bg_dim })
hl("PmenuThumb",    { bg = p.gray })

hl("Visual",        { bg = p.sel })
hl("VisualNOS",     { bg = p.sel })
hl("Search",        { fg = p.bg, bg = p.pink })
hl("IncSearch",     { fg = p.bg, bg = p.pink, bold = true })
hl("CurSearch",     { fg = p.bg, bg = p.pink, bold = true })
hl("MatchParen",    { fg = p.bg, bg = p.pink, bold = true })

hl("Cursor",        { fg = p.bg, bg = p.fg })
hl("lCursor",       { fg = p.bg, bg = p.fg })
hl("TermCursor",    { fg = p.bg, bg = p.fg })

hl("NonText",       { fg = p.gray })
hl("Whitespace",    { fg = p.gray })
hl("Conceal",       { fg = p.gray })
hl("EndOfBuffer",   { fg = p.bg })
hl("Directory",     { fg = p.pink })
hl("Title",         { fg = p.pink, bold = true })
hl("ErrorMsg",      { fg = p.red, bold = true })
hl("WarningMsg",    { fg = p.yellow })
hl("MoreMsg",       { fg = p.yellow })
hl("Question",      { fg = p.yellow })
hl("ModeMsg",       { fg = p.fg, bold = true })
hl("MsgArea",       { fg = p.fg })
hl("WildMenu",      { fg = p.fg, bg = p.sel })
hl("SpecialKey",    { fg = p.gray })
hl("Underlined",    { fg = p.pink, underline = true })

hl("DiffAdd",       { fg = p.green, bg = "NONE" })
hl("DiffChange",    { fg = p.yellow, bg = "NONE" })
hl("DiffDelete",    { fg = p.red, bg = "NONE" })
hl("DiffText",      { fg = p.yellow, bg = "NONE", bold = true })

hl("SpellBad",      { sp = p.red, undercurl = true })
hl("SpellCap",      { sp = p.yellow, undercurl = true })
hl("SpellLocal",    { sp = p.green, undercurl = true })
hl("SpellRare",     { sp = p.pink, undercurl = true })

----------------------------------------------------------------------
-- Syntax
----------------------------------------------------------------------
hl("Comment",       { fg = p.gray, italic = true })
hl("Constant",      { fg = p.gray })
hl("String",        { fg = p.string })
hl("Character",     { fg = p.string })
hl("Number",        { fg = p.yellow })
hl("Float",         { fg = p.yellow })  -- syntax (overrides UI Float above is OK; UI uses NormalFloat anyway)
hl("Boolean",       { fg = p.yellow })

hl("Identifier",    { fg = p.fg })
hl("Function",      { fg = p.pink })

hl("Statement",     { fg = p.pink })
hl("Conditional",   { fg = p.pink })
hl("Repeat",        { fg = p.pink })
hl("Label",         { fg = p.pink })
hl("Operator",      { fg = p.gray })
hl("Keyword",       { fg = p.pink, bold = true })
hl("Exception",     { fg = p.pink })

hl("PreProc",       { fg = p.gray })
hl("Include",       { fg = p.gray })
hl("Define",        { fg = p.gray })
hl("Macro",         { fg = p.gray })
hl("PreCondit",     { fg = p.gray })

hl("Type",          { fg = p.pink, italic = true })
hl("StorageClass",  { fg = p.pink, italic = true })
hl("Structure",     { fg = p.pink, italic = true })
hl("Typedef",       { fg = p.pink, italic = true })

hl("Special",       { fg = p.pink })
hl("SpecialChar",   { fg = p.pink })
hl("Tag",           { fg = p.pink })
hl("Delimiter",     { fg = p.fg })
hl("SpecialComment",{ fg = p.gray, italic = true })
hl("Debug",         { fg = p.red })

hl("Error",         { fg = p.red, bold = true })
hl("Todo",          { fg = p.yellow, bold = true })

----------------------------------------------------------------------
-- Treesitter (modern @-style groups)
----------------------------------------------------------------------
hl("@variable",             { fg = p.fg })
hl("@variable.builtin",     { fg = p.pink, italic = true })
hl("@variable.parameter",   { fg = p.fg })
hl("@variable.member",      { fg = p.fg })
hl("@constant",             { fg = p.gray })
hl("@constant.builtin",     { fg = p.yellow })
hl("@constant.macro",       { fg = p.gray })
hl("@string",               { fg = p.string })
hl("@string.escape",        { fg = p.pink })
hl("@string.special",       { fg = p.pink })
hl("@number",               { fg = p.yellow })
hl("@boolean",              { fg = p.yellow })
hl("@float",                { fg = p.yellow })
hl("@function",             { fg = p.pink })
hl("@function.builtin",     { fg = p.pink })
hl("@function.call",        { fg = p.pink })
hl("@function.macro",       { fg = p.pink })
hl("@method",               { fg = p.pink })
hl("@method.call",          { fg = p.pink })
hl("@constructor",          { fg = p.pink })
hl("@parameter",            { fg = p.fg })
hl("@keyword",              { fg = p.pink, bold = true })
hl("@keyword.function",     { fg = p.pink, bold = true })
hl("@keyword.return",       { fg = p.pink, bold = true })
hl("@keyword.operator",     { fg = p.pink })
hl("@conditional",          { fg = p.pink })
hl("@repeat",               { fg = p.pink })
hl("@label",                { fg = p.pink })
hl("@operator",             { fg = p.gray })
hl("@exception",            { fg = p.pink })
hl("@type",                 { fg = p.pink, italic = true })
hl("@type.builtin",         { fg = p.pink, italic = true })
hl("@type.definition",      { fg = p.pink, italic = true })
hl("@type.qualifier",       { fg = p.pink, italic = true })
hl("@namespace",            { fg = p.fg })
hl("@module",               { fg = p.fg })
hl("@property",             { fg = p.fg })
hl("@field",                { fg = p.fg })
hl("@punctuation",          { fg = p.fg })
hl("@punctuation.delimiter",{ fg = p.fg })
hl("@punctuation.bracket",  { fg = p.fg })
hl("@punctuation.special",  { fg = p.pink })
hl("@comment",              { fg = p.gray, italic = true })
hl("@tag",                  { fg = p.pink })
hl("@tag.attribute",        { fg = p.fg })
hl("@tag.delimiter",        { fg = p.gray })

----------------------------------------------------------------------
-- LSP
----------------------------------------------------------------------
hl("LspReferenceText",   { fg = p.bg, bg = "#FCC0E0" })
hl("LspReferenceRead",   { fg = p.bg, bg = "#FCC0E0" })
hl("LspReferenceWrite",  { fg = p.bg, bg = "#FCC0E0" })
hl("LspReferenceTarget", { fg = p.bg, bg = "#FCC0E0" })
hl("LspInlayHint",       { fg = p.inlay, italic = true })
hl("LspSignatureActiveParameter", { fg = p.pink, bold = true })

hl("DiagnosticError",            { fg = p.red })
hl("DiagnosticWarn",             { fg = p.yellow })
hl("DiagnosticInfo",             { fg = p.fg })
hl("DiagnosticHint",             { fg = p.gray })
hl("DiagnosticOk",               { fg = p.green, bg = "NONE" })
hl("DiagnosticSignError",        { fg = p.red, bg = "NONE" })
hl("DiagnosticSignWarn",         { fg = p.yellow, bg = "NONE" })
hl("DiagnosticSignInfo",         { fg = p.fg, bg = "NONE" })
hl("DiagnosticSignHint",         { fg = p.gray, bg = "NONE" })
hl("DiagnosticSignOk",           { fg = p.green, bg = "NONE" })
hl("DiagnosticVirtualTextError", { fg = p.red })
hl("DiagnosticVirtualTextWarn",  { fg = p.yellow })
hl("DiagnosticVirtualTextInfo",  { fg = p.fg })
hl("DiagnosticVirtualTextHint",  { fg = p.gray })
hl("DiagnosticVirtualTextOk",    { fg = p.green, bg = "NONE" })
hl("DiagnosticFloatingError",    { fg = p.red, bg = "NONE" })
hl("DiagnosticFloatingWarn",     { fg = p.yellow, bg = "NONE" })
hl("DiagnosticFloatingInfo",     { fg = p.fg, bg = "NONE" })
hl("DiagnosticFloatingHint",     { fg = p.gray, bg = "NONE" })
hl("DiagnosticFloatingOk",       { fg = p.green, bg = "NONE" })
hl("DiagnosticUnderlineError",   { sp = p.red, undercurl = true })
hl("DiagnosticUnderlineWarn",    { sp = p.yellow, undercurl = true })
hl("DiagnosticUnderlineInfo",    { sp = p.fg, undercurl = true })
hl("DiagnosticUnderlineHint",    { sp = p.gray, undercurl = true })
hl("DiagnosticUnderlineOk",      { sp = p.green, undercurl = true })

----------------------------------------------------------------------
-- Plugin highlights (kept from original)
----------------------------------------------------------------------
-- GitSigns
hl("GitSignsAdd",         { fg = p.green })
hl("GitSignsChange",      { fg = p.yellow })
hl("GitSignsDelete",      { fg = p.red })
hl("GitSignsStagedAdd",   { fg = p.darkgreen })
hl("GitSignsStagedAddNr", { fg = p.darkgreen })
hl("GitSignsStagedAddCul",{ fg = p.darkgreen })
if bg == "dark" then
    hl("GitSignsCurrentLineBlame", { fg = "#FF80BF", blend = 69 })
end

-- Flash
hl("FlashLabel", { fg = p.bg, bg = p.pink })
hl("FlashMatch", { fg = p.bg, bg = p.red })

-- Snacks picker
hl("SnacksPickerSearchMatch", { fg = p.bg, bg = p.pink })
hl("SnacksPickerMatch",       { fg = p.red })

-- Avante
hl("AvanteTitle",              { fg = "#000000", bg = p.pink })
hl("AvanteButtonDefaultHover", { fg = "#000000", bg = p.pink })

-- NvimTree
hl("NvimTreeWinSeparator", { fg = p.gray, bg = "NONE" })
hl("NvimTreeNormal",       { fg = p.fg, bg = "NONE" })
hl("NvimTreeFolderName",   { fg = p.pink })
hl("NvimTreeOpenedFolderName", { fg = p.pink, bold = true })

-- Oil
hl("OilDir",        { fg = p.pink, bold = true })
hl("OilFile",       { fg = p.fg })
hl("OilLink",       { fg = p.green })
hl("OilOrphanLink", { fg = p.red })
hl("OilSocket",     { fg = p.yellow })
hl("OilCreate",     { fg = p.green })
hl("OilDelete",     { fg = p.red })
hl("OilMove",       { fg = p.yellow })
hl("OilCopy",       { fg = p.pink })
hl("OilChange",     { fg = p.yellow })

-- Render-markdown
hl("RenderMarkdownH2Bg", { bg = "#57af92" })

-- Misc
hl("OverLength", { bg = "#5a2e3e" })

-- Lualine inactive (from original dark-only block)
if bg == "dark" then
    hl("lualine_a_inactive", { fg = "NONE", bg = "NONE" })
    hl("lualine_b_inactive", { fg = "NONE", bg = "NONE" })
end

----------------------------------------------------------------------
-- Terminal colors (replaces zenbones.term.apply_colors)
----------------------------------------------------------------------
vim.g.terminal_color_0  = p.bg
vim.g.terminal_color_1  = p.red
vim.g.terminal_color_2  = p.green
vim.g.terminal_color_3  = p.yellow
vim.g.terminal_color_4  = p.pink
vim.g.terminal_color_5  = p.pink
vim.g.terminal_color_6  = p.string
vim.g.terminal_color_7  = p.fg
vim.g.terminal_color_8  = p.gray
vim.g.terminal_color_9  = p.red
vim.g.terminal_color_10 = p.green
vim.g.terminal_color_11 = p.yellow
vim.g.terminal_color_12 = p.pink
vim.g.terminal_color_13 = p.pink
vim.g.terminal_color_14 = p.string
vim.g.terminal_color_15 = p.fg
