-- Port of nvim/colors/usgc-polyminimal2.lua (the active nvim colorscheme).
-- Transparent background, like `Normal { bg = NONE }` in nvim.
local lexers = vis.lexers

local foreground = "#DDDDDD"
local background = "#22212C"
local lavender = "#CDC1FF"
local gray = "#888888"
local green = "#00FFAA"
local yellow = "#f6b40e"
local str = "#FFDCCC"
local red = "#ED91B1"
local cursor_line = "#454057"
local blue = "#74acdf"

local function fg(c, extra)
	return "fore:" .. c .. (extra and ("," .. extra) or "")
end

lexers.STYLE_DEFAULT = fg(foreground)
lexers.STYLE_NOTHING = ""
lexers.STYLE_WHITESPACE = fg(gray)

-- Syntax (nvim group -> vis token)
lexers.STYLE_COMMENT = fg(gray) -- Comment
lexers.STYLE_STRING = fg(str) -- String
lexers.STYLE_REGEX = fg(str)
lexers.STYLE_NUMBER = fg(yellow) -- Number / Float
lexers.STYLE_CONSTANT = fg(yellow) -- Constant / Boolean
lexers.STYLE_CONSTANT_BUILTIN = fg(yellow)
lexers.STYLE_KEYWORD = fg(blue) -- @keyword
lexers.STYLE_FUNCTION = fg(blue) -- Function
lexers.STYLE_FUNCTION_BUILTIN = fg(blue)
lexers.STYLE_FUNCTION_METHOD = fg(blue)
lexers.STYLE_TYPE = fg(lavender, "italics") -- Type
lexers.STYLE_CLASS = fg(lavender, "italics")
lexers.STYLE_IDENTIFIER = fg(foreground) -- Identifier
lexers.STYLE_VARIABLE = fg(foreground)
lexers.STYLE_VARIABLE_BUILTIN = fg(lavender) -- Special
lexers.STYLE_OPERATOR = fg(gray) -- Operator
lexers.STYLE_PREPROCESSOR = fg(gray) -- PreProc
lexers.STYLE_LABEL = fg(lavender) -- Special
lexers.STYLE_ANNOTATION = fg(lavender)
lexers.STYLE_ATTRIBUTE = fg(blue) -- @property
lexers.STYLE_DEFINITION = fg(blue)
lexers.STYLE_EMBEDDED = fg(lavender)
lexers.STYLE_TAG = fg(lavender)
lexers.STYLE_ERROR = fg(red)

-- Markup
lexers.STYLE_HEADING = fg(lavender, "bold")
for i = 1, 6 do
	lexers["STYLE_HEADING_H" .. i] = lexers.STYLE_HEADING
end
lexers.STYLE_BOLD = "bold"
lexers.STYLE_ITALIC = "italics"
lexers.STYLE_UNDERLINE = "underlined"
lexers.STYLE_LINK = fg(lavender, "underlined") -- Underlined
lexers.STYLE_REFERENCE = fg(lavender)
lexers.STYLE_LIST = fg(blue)
lexers.STYLE_CODE = fg(str)

-- Diff (Added / Changed / Removed)
lexers.STYLE_ADDITION = fg(green)
lexers.STYLE_CHANGE = fg(yellow)
lexers.STYLE_DELETION = fg(red)

-- CSS
lexers.STYLE_PROPERTY = fg(blue)

-- UI
lexers.STYLE_LINENUMBER = fg(gray) -- LineNr
lexers.STYLE_LINENUMBER_CURSOR = fg(lavender, "back:" .. cursor_line .. ",bold") -- CursorLineNr
lexers.STYLE_CURSOR = "reverse" -- MultiCursorCursor
lexers.STYLE_CURSOR_PRIMARY = fg(background, "back:" .. blue) -- Cursor
lexers.STYLE_CURSOR_LINE = "back:" .. cursor_line -- CursorLine
lexers.STYLE_COLOR_COLUMN = "back:" .. cursor_line
lexers.STYLE_SELECTION = fg(lavender, "back:" .. cursor_line) -- Visual
lexers.STYLE_STATUS = fg(gray, "back:" .. background) -- StatusLineNC
lexers.STYLE_STATUS_FOCUSED = fg(lavender, "back:" .. cursor_line .. ",bold") -- StatusLine
lexers.STYLE_SEPARATOR = fg(gray)
lexers.STYLE_INFO = fg(foreground)
lexers.STYLE_EOF = fg(gray)
