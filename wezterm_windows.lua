local wezterm = require("wezterm")

-- ─── Theme persistence ────────────────────────────────────────────────────────

local function get_theme_state_path()
	return wezterm.config_dir .. "/theme_state.json"
end

local function load_theme_state()
	local ok, file = pcall(io.open, get_theme_state_path(), "r")
	if ok and file then
		local content = file:read("*a")
		file:close()
		local state = wezterm.json_parse(content)
		if state and state.theme then
			return state.theme
		end
	end
	return "dark"
end

local function save_theme_state(theme)
	local ok, file = pcall(io.open, get_theme_state_path(), "w")
	if ok and file then
		file:write(wezterm.json_encode({ theme = theme }))
		file:close()
	end
end

-- ─── Colors ───────────────────────────────────────────────────────────────────

local custom_colors = {
	background = "#22212C",
	foreground = "#DDDDDD",

	cursor_bg = "#CDC1FF",
	cursor_fg = "#1C1917",
	cursor_border = "#CDC1FF",

	compose_cursor = "#00FFAA",

	selection_bg = "#EC8FB0",
	selection_fg = "#1C1917",

	ansi = {
		"#000000", -- black
		"#EC8FB0", -- red
		"#00FFAA", -- green
		"#D6C5A5", -- yellow
		"#33AACC", -- blue
		"#CDC1FF", -- magenta
		"#656EA4", -- cyan
		"#DDDDDD", -- white
	},

	brights = {
		"#403833", -- bright black
		"#E8838F", -- bright red
		"#00FFAA", -- bright green
		"#D6C5A5", -- bright yellow
		"#5CBCD6", -- bright blue
		"#AD99FF", -- bright magenta
		"#7E86B4", -- bright cyan
		"#A8A8A8", -- bright white
	},

	scrollbar_thumb = "#898989",
	split = "#898989",

	tab_bar = {
		background = "#22212C",

		active_tab = {
			bg_color = "#CDC1FF",
			fg_color = "#1C1917",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},

		inactive_tab = {
			bg_color = "#22212C",
			fg_color = "#DDDDDD",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},

		inactive_tab_hover = {
			bg_color = "#898989",
			fg_color = "#DDDDDD",
			intensity = "Normal",
			italic = true,
			strikethrough = false,
			underline = "None",
		},

		new_tab = {
			bg_color = "#22212C",
			fg_color = "#DDDDDD",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},

		new_tab_hover = {
			bg_color = "#EC8FB0",
			fg_color = "#DDDDDD",
			intensity = "Normal",
			italic = true,
			strikethrough = false,
			underline = "None",
		},
	},
}

local custom_colors_light = {
	background = "#ece7f6",
	foreground = "#22223b",

	cursor_bg = "#a18fff",
	cursor_fg = "#ece7f6",
	cursor_border = "#a18fff",

	compose_cursor = "#00b894",

	selection_bg = "#bfa05a",
	selection_fg = "#22223b",

	ansi = {
		"#22223b", -- black
		"#e57373", -- red
		"#00b894", -- green
		"#bfa05a", -- yellow
		"#65B8C1", -- blue
		"#a18fff", -- magenta
		"#61ABDA", -- cyan
		"#bdbdbd", -- white
	},

	brights = {
		"#6c6f93", -- bright black
		"#e57373", -- bright red
		"#00b894", -- bright green
		"#bfa05a", -- bright yellow
		"#65B8C1", -- bright blue
		"#a18fff", -- bright magenta
		"#61ABDA", -- bright cyan
		"#ece7f6", -- bright white
	},

	scrollbar_thumb = "#bdbdbd",
	split = "#bdbdbd",

	tab_bar = {
		background = "#ece7f6",

		active_tab = {
			bg_color = "#a18fff",
			fg_color = "#22223b",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},

		inactive_tab = {
			bg_color = "#ece7f6",
			fg_color = "#22223b",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},

		inactive_tab_hover = {
			bg_color = "#bdbdbd",
			fg_color = "#22223b",
			intensity = "Normal",
			italic = true,
			strikethrough = false,
			underline = "None",
		},

		new_tab = {
			bg_color = "#ece7f6",
			fg_color = "#22223b",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},

		new_tab_hover = {
			bg_color = "#bfa05a",
			fg_color = "#22223b",
			intensity = "Normal",
			italic = true,
			strikethrough = false,
			underline = "None",
		},
	},
}

-- ─── Config ───────────────────────────────────────────────────────────────────

local theme = load_theme_state()
local theme_name = theme == "light" and "Custom Theme Light" or "Custom Theme"

local config = wezterm.config_builder and wezterm.config_builder() or {}
local act = wezterm.action

config.color_schemes = {
	["Custom Theme"] = custom_colors,
	["Custom Theme Light"] = custom_colors_light,
}
config.color_scheme = theme_name

-- Tab bar (mirrors existing wezterm config)
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Window chrome
config.win32_system_backdrop = "Mica"
config.window_decorations = "RESIZE"
config.window_background_opacity = 1.0
config.max_fps = 160

-- Renderer
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.webgpu_force_fallback_adapter = true
local gpus = wezterm.gui.enumerate_gpus()
config.webgpu_preferred_adapter = gpus[1]

config.freetype_load_flags = "NO_HINTING"
config.freetype_load_target = "Light"
config.freetype_render_target = "Light"
config.cell_width = 0.9

-- Font
config.font = wezterm.font_with_fallback({
	{ family = "M+CodeLat50 Nerd Font", weight = "Regular" },
	{ family = "PragmataProLiga Nerd Font", weight = "Regular" },
	{ family = "JuliaMono", weight = "Regular" },
	{ family = "Pragmasevka Nerd Font", weight = "Regular" },
	{ family = "Berkeley Mono", weight = "Regular" },
	{ family = "PragmataPro", weight = "Regular" },
	{ family = "mononoki", weight = "Regular" },
	"Rec Mono Semicasual",
	"CommitMono Nerd Font",
	"Monaspace Neon",
	"Comic Code Ligatures",
})
config.font_size = 11

-- WSL default domain (NixOS)
config.default_domain = "WSL:NixOS"
config.launch_menu = {
	{ label = "Powershell", domain = { DomainName = "local" }, args = { "powershell.exe" } },
}

-- ─── Leader (mirrors tmux C-Space prefix) ────────────────────────────────────

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

-- ─── Keybindings ─────────────────────────────────────────────────────────────

config.keys = {
	-- ── Pane splits (leader + " / % / s / v) ─────────────────────────────────
	-- mirrors: bind '"' split-window -v  /  bind s split-window -v
	{ key = '"', mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	-- mirrors: bind '%' split-window -h  /  bind v split-window -h
	{ key = "%", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	-- ── Pane navigation (C-h/j/k/l, no leader) ───────────────────────────────
	-- mirrors: bind-key -n C-h/j/k/l select-pane -L/D/U/R
	{ key = "h", mods = "CTRL", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CTRL", action = act.ActivatePaneDirection("Right") },

	-- ── Pane resize (M-C-h/j/k/l) ────────────────────────────────────────────
	-- mirrors: bind-key -n M-C-h/j/k/l resize-pane -L/D/U/R
	{ key = "h", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "j", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "k", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "l", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- ── Pane rotate (leader + h/l) ───────────────────────────────────────────
	-- WezTerm has no directional pane swap; RotatePanes is the closest equivalent
	{ key = "h", mods = "LEADER", action = act.RotatePanes("CounterClockwise") },
	{ key = "l", mods = "LEADER", action = act.RotatePanes("Clockwise") },

	-- ── Kill pane (leader + x / w) ────────────────────────────────────────────
	-- mirrors: bind x kill-pane  /  bind-key w kill-pane
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "w", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },

	-- ── Zoom pane (leader + z) ────────────────────────────────────────────────
	-- mirrors: tmux default prefix + z
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	-- ── Tab navigation (C-q / C-e, no leader) ────────────────────────────────
	-- mirrors: bind -n C-q previous-window  /  bind -n C-e next-window
	{ key = "q", mods = "CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "e", mods = "CTRL", action = act.ActivateTabRelative(1) },

	-- ── New tab (leader + t) ──────────────────────────────────────────────────
	-- mirrors: bind-key t new-window
	{ key = "t", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },

	-- ── Move tab left / right (leader + < / >) ───────────────────────────────
	-- mirrors: bind-key -r < swap-window -t -1  /  bind-key -r > swap-window -t +1
	{ key = "<", mods = "LEADER", action = act.MoveTabRelative(-1) },
	{ key = ">", mods = "LEADER", action = act.MoveTabRelative(1) },

	-- ── Rename tab (leader + r) ───────────────────────────────────────────────
	-- mirrors: bind-key r command-prompt "rename-window %%"
	{
		key = "r",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename tab:",
			action = wezterm.action_callback(function(window, _, line)
				if line and line ~= "" then
					window:active_tab():set_title(line:upper())
				end
			end),
		}),
	},

	-- ── Session / workspace management ──────────────────────────────────────
	-- mirrors: bind S (session picker)
	{ key = "S", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

	-- mirrors: bind R rename-session
	{
		key = "R",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, _)
			local current = window:active_workspace()
			window:perform_action(
				act.PromptInputLine({
					description = "Rename workspace (current: " .. current .. "):",
					action = wezterm.action_callback(function(inner_window, _, line)
						if line and line ~= "" then
							wezterm.mux.rename_workspace(inner_window:active_workspace(), line:upper())
						end
					end),
				}),
				window:active_pane()
			)
		end),
	},

	-- switch to or create a named workspace
	{
		key = "N",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Switch to or create workspace:",
			action = wezterm.action_callback(function(window, pane, line)
				if line and line ~= "" then
					window:perform_action(act.SwitchToWorkspace({ name = line:upper() }), pane)
				end
			end),
		}),
	},

	-- ── Clear screen (C-; → send C-l) ────────────────────────────────────────
	-- mirrors: bind-key -n C-\; send-keys C-l
	{ key = ";", mods = "CTRL", action = act.SendKey({ key = "l", mods = "CTRL" }) },

	-- ── Copy / paste ──────────────────────────────────────────────────────────
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("ClipboardAndPrimarySelection") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- ── Theme toggle (CTRL+SHIFT+ALT+l) ──────────────────────────────────────
	{
		key = "l",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			local current = overrides.color_scheme or theme_name
			local new_theme, new_name
			if current == "Custom Theme" then
				new_theme, new_name = "light", "Custom Theme Light"
			else
				new_theme, new_name = "dark", "Custom Theme"
			end
			overrides.color_scheme = new_name
			window:set_config_overrides(overrides)
			save_theme_state(new_theme)
		end),
	},

	-- ── Toggle title bar (CTRL+ALT+t) ────────────────────────────────────────
	{
		key = "t",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			if overrides.window_decorations then
				window:set_config_overrides(nil)
			else
				overrides.window_decorations = "TITLE|RESIZE"
				window:set_config_overrides(overrides)
			end
		end),
	},

	-- ── Toggle ligatures (CTRL+ALT+a) ────────────────────────────────────────
	{
		key = "a",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			if not overrides.harfbuzz_features then
				overrides.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
			else
				overrides.harfbuzz_features = nil
			end
			window:set_config_overrides(overrides)
		end),
	},

	-- ── Rename window title (CTRL+SHIFT+r) ───────────────────────────────────
	{
		key = "r",
		mods = "CTRL|SHIFT",
		action = act.PromptInputLine({
			description = "Enter new window name (empty to reset):",
			action = wezterm.action_callback(function(_, pane, line)
				if line ~= nil then
					pane:inject_output("\033]1337;SetUserVar=window_title=" .. wezterm.base64_encode(line) .. "\007")
				end
			end),
		}),
	},
}

-- ─── Mouse bindings ───────────────────────────────────────────────────────────
-- right-click: copy if selection active, else paste

config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

-- ─── Leader indicator ────────────────────────────────────────────────────────

wezterm.on("update-right-status", function(window, _)
	if window:leader_is_active() then
		window:set_right_status(wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Background = { Color = "#CDC1FF" } },
			{ Foreground = { Color = "#1C1917" } },
			{ Text = "  LEADER  " },
		}))
	else
		window:set_right_status("")
	end
end)

-- ─── Window title ─────────────────────────────────────────────────────────────

wezterm.on("format-window-title", function(_, pane)
	local user_vars = pane.user_vars
	if user_vars and user_vars.window_title and user_vars.window_title ~= "" then
		return user_vars.window_title
	end
	return "Term"
end)

return config
