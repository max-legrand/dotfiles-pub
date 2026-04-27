-- Minimal colorscheme
local colors_name = "minimal"
vim.g.colors_name = colors_name -- Required when defining a colorscheme

local lush = require("lush")
local hsluv = lush.hsluv -- Human-friendly hsl
local util = require("zenbones.util")

local theme_file = os.getenv("HOME") .. "/.config/fish/theme_mode"
local theme_mode = "dark"
local file = io.open(theme_file, "r")
if file then
	theme_mode = file:read("*l") or "dark"
	file:close()
end
vim.o.background = theme_mode

-- Toggle theme and write to file
vim.api.nvim_create_user_command("ToggleTheme", function()
	local new_bg = vim.o.background == "light" and "dark" or "light"
	vim.o.background = new_bg

	-- Clear highlights
	vim.cmd("hi clear")
	-- Reapply colorscheme
	vim.cmd("colorscheme minimal")

	-- Write to file so Fish can pick it up
	local theme_file = os.getenv("HOME") .. "/.config/fish/theme_mode"
	local file = io.open(theme_file, "w")
	if file then
		file:write(new_bg)
		file:close()
	end
end, {})

local bg = vim.o.background

-- Define a minimalist palette with a less bright pink accent. Use `palette_extend` to fill unspecified colors
local palette
if bg == "light" then
	palette = util.palette_extend({
		fg = hsluv("#22223b"), -- Deep blue-gray foreground
		pink = hsluv("#a18fff"), -- Deeper purple accent
		gray = hsluv("#6c6f93"), -- Darker lavender-gray for comments
		green = hsluv("#00b894"), -- More muted green
		darkgreen = hsluv("#00997a"),
		yellow = hsluv("#bfa05a"), -- Muted yellow
		string = hsluv("#3b5998"),
		red = hsluv("#e57373"), -- Muted red
		inlay = hsluv("#8e7cc3"),
		bg = hsluv("#ece7f6"), -- Slightly deeper lavender
	}, bg)
else
	highlight = os.getenv("HIGHLIGHT")
	palette = util.palette_extend({
		fg = hsluv("#dddddd"), -- Light foreground
		-- pink = hsluv("#CDC1FF"), -- Less bright pink accent
		pink = highlight,
		gray = hsluv("#888888"), -- Gray for secondary elements
		green = hsluv("#00ffaa"), -- Green for added lines
		darkgreen = hsluv("#00e699"),
		yellow = hsluv("#d6c5a5"), -- Yellow for changed lines
		string = hsluv("#FFDCCC"),
		-- red = hsluv("#ff7e7e"), -- Red for deleted lines
		red = hsluv("#ed91b1"),
		inlay = hsluv("#e0d4ef"),
		-- bg = hsluv("#454057"),
		bg = hsluv("#22212C"),
	}, bg)

	-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#ffffff" })
	vim.api.nvim_set_hl(0, "lualine_a_inactive", { fg = "none", bg = "none" })
	vim.api.nvim_set_hl(0, "lualine_b_inactive", { fg = "none", bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
	vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })

	local set_hl = vim.api.nvim_set_hl
	set_hl(0, "GitSignsCurrentLineBlame", { fg = "#FF80BF", blend = 69 }) -- Adjust the blend value as needed
end

-- Generate the lush specs using the generator util
local generator = require("zenbones.specs")
local base_specs = generator.generate(palette, bg, generator.get_global_config(colors_name, bg))

-- Optionally extend specs using Lush

local specs = lush.extends({ base_specs }).with(function()
	local normal_bg = (bg == "light") and palette.bg or "none"
	-- local normal_bg = palette.bg

	return {
		LspReferenceTarget({ bg = "#FCC0E0", fg = palette.bg }),
		LspReferenceText({ bg = "#FCC0E0", fg = palette.bg }),
		LspReferenceRead({ bg = "#FCC0E0", fg = palette.bg }),
		LspReferenceWrite({ bg = "#FCC0E0", fg = palette.bg }),

		FlashLabel({ bg = palette.pink, fg = palette.bg }),
		FlashMatch({ bg = palette.red, fg = palette.bg }),

		Search({ bg = palette.pink, fg = palette.bg }),
		MatchParen({ bg = palette.pink, fg = palette.bg }),
		SnacksPickerSearchMatch({ bg = palette.pink, fg = palette.bg }),
		SnacksPickerMatch({ fg = palette.red }),

		AvanteTitle({ fg = hsluv("#000000"), bg = palette.pink }),
		AvanteButtonDefaultHover({ fg = hsluv("#000000"), bg = palette.pink }),

		Normal({ bg = normal_bg, fg = palette.fg }),
		-- Normal({ bg = "#1C1917", fg = palette.fg }),
		Statement({ base_specs.Statement, fg = palette.pink }),
		Special({ fg = palette.pink }),
		Type({ fg = palette.pink, gui = "italic" }),
		Comment({ fg = palette.gray }),
		Constant({ fg = palette.gray }),
		Identifier({ fg = palette.fg }),
		PreProc({ fg = palette.gray }),
		SpecialKey({ fg = palette.gray }),
		Underlined({ fg = palette.pink, gui = "underline" }),
		NvimTreeWinSeparator({ bg = "none", fg = palette.gray }),

		-- Customize Git sidebar colors
		GitSignsAdd({ fg = palette.green }),

		GitSignsStagedAdd({ fg = palette.darkgreen }),
		GitSignsStagedAddNr({ fg = palette.darkgreen }),
		GitSignsStagedAddCul({ fg = palette.darkgreen }),

		GitSignsChange({ fg = palette.yellow }),
		GitSignsDelete({ fg = palette.red }),
		Float({ bg = "none" }),
		WarningMsg({ fg = palette.yellow }),
		MoreMsg({ fg = palette.yellow }),
		Question({ fg = palette.yellow }),

		DiagnosticFloatingOk({ fg = palette.green, bg = "none" }),
		DiagnosticOk({ fg = palette.green, bg = "none" }),
		DiagnosticSignOk({ fg = palette.green, bg = "none" }),
		DiagnosticVirtualTextOk({ fg = palette.green, bg = "none" }),
		LspInlayHint({ fg = palette.inlay }),

		-- CursorLine({ bg = palette.bg }),
		CursorLine({ bg = "#454057" }),

		-- Added Color
		String({ fg = palette.string }), -- Green for strings
		Number({ fg = palette.yellow }), -- Yellow for numbers
		Keyword({ fg = palette.pink, gui = "bold" }), -- Pink for Keywords
		Function({ fg = palette.pink }), -- Pink for functions
		Operator({ fg = palette.gray }), -- Gray for operators

		RenderMarkdownH2Bg({ bg = "#57af92" }),
		OverLength({ bg = "#5a2e3e" }),

		-- Oil highlights
		OilDir({ fg = palette.pink, gui = "bold" }),
		OilFile({ fg = palette.fg }),
		OilLink({ fg = palette.green }),
		OilOrphanLink({ fg = palette.red }),
		OilSocket({ fg = palette.yellow }),
		OilCreate({ fg = palette.green }),
		OilDelete({ fg = palette.red }),
		OilMove({ fg = palette.yellow }),
		OilCopy({ fg = palette.pink }),
		OilChange({ fg = palette.yellow }),
	}
end)

-- BLAND
-- local specs = lush.extends({ base_specs }).with(function()
--     return {
--         Normal({ bg = "none", fg = palette.fg }),                 -- Transparent background
--         Statement({ base_specs.Statement, fg = palette.pink }),   -- Pink for statements
--         Special({ fg = palette.pink }),                           -- Pink for special characters
--         Type({ fg = palette.pink, gui = "italic" }),              -- Pink for types
--         Comment({ fg = palette.gray }),                           -- Gray for comments
--         Constant({ fg = palette.gray }),                          -- Gray for constants
--         Identifier({ fg = palette.fg }),                          -- Default foreground for identifiers
--         PreProc({ fg = palette.gray }),                           -- Gray for preprocessor
--         SpecialKey({ fg = palette.gray }),                        -- Gray for special keys
--         Underlined({ fg = palette.pink, gui = "underline" }),     -- Pink for underlined text
--         NvimTreeWinSeparator({ bg = "none", fg = palette.gray }), -- Transparent background for NvimTreeWinSeparator
--
--         -- Customize Git sidebar colors
--         GitSignsAdd({ fg = palette.green }),     -- Green for added lines
--         GitSignsChange({ fg = palette.yellow }), -- Yellow for changed lines
--         GitSignsDelete({ fg = palette.red }),    -- Red for deleted lines
--         Float({ bg = "none" }),
--         WarningMsg({ fg = palette.yellow }),
--
--         DiagnosticFloatingOk({ fg = palette.green, bg = "none" }),
--         LspInlayHint({ fg = palette.inlay }),
--     }
-- end)

-- Pass the specs to lush to apply
lush(specs)

local hex_palette = {}
for k, v in pairs(palette) do
	hex_palette[k] = tostring(v) -- Call the color object to get the hex code
end

-- print(vim.inspect(hex_palette))

-- Optionally set term colors
require("zenbones.term").apply_colors(palette)

