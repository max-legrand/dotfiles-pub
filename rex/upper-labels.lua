-- ~/.config/rex/upper-labels.lua
-- Uppercase explicitly entered session/tab names. A tab reset to Rex's
-- generated "Window <id>" label follows its focused terminal's title exactly.

local terminal = "com.superlogical.terminal"
local following = {}
local pending_label = {}

local function default_window_label(label, window_id)
  local suffix = window_id and window_id:match("%-([^%-]+)$")
  if suffix then suffix = suffix:sub(-8) end
  return suffix ~= nil and label ~= nil
     and label:lower() == ("window " .. suffix):lower()
end

local function find_window(view, window_id)
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == window_id then return window end
  end
end

local function terminal_blocks(window)
  local blocks = {}
  for _, layer in ipairs(window.layers or {}) do
    for _, block in ipairs(layer.blocks or {}) do
      if block.creator_name == terminal then
        blocks[#blocks + 1] = block
      end
    end
  end
  table.sort(blocks, function(a, b)
    return a.block_id == window.focused_block_id
       and b.block_id ~= window.focused_block_id
  end)
  return blocks
end

local function title_for_block(block_id)
  local result = rex.block.call(terminal, "title", { block_id = block_id })
  if result and result.title and result.title ~= "" then return result.title end
end

local function set_title_label(window_id, title)
  if not title or title == "" then return end
  local label = title
  following[window_id] = true
  pending_label[window_id] = label
  rex.session.set_window_label{ window_id = window_id, label = label }
end

local function refresh_window_title(window_id)
  local view = rex.session.view{}
  local window = find_window(view, window_id)
  if not window then return end
  for _, block in ipairs(terminal_blocks(window)) do
    local title = title_for_block(block.block_id)
    if title then
      set_title_label(window_id, title)
      return
    end
  end
end

local function update_title_for_block(ctx, block_id, event_title)
  local view = rex.session.view{}
  for _, window in ipairs(view.windows or {}) do
    if following[window.window_id] then
      for _, layer in ipairs(window.layers or {}) do
        for _, block in ipairs(layer.blocks or {}) do
          if block.block_id == block_id then
            local title = event_title or title_for_block(block_id)
            set_title_label(window.window_id, title)
            return
          end
        end
      end
    end
  end
end

-- Seed follow mode for tabs already showing their terminal's title.
local sessions = rex.call("session.list")
for _, session in ipairs((sessions and sessions.sessions) or {}) do
  local view = rex.session.view{ session_id = session.session_id }
  for _, window in ipairs((view and view.windows) or {}) do
    for _, block in ipairs(terminal_blocks(window)) do
      local title = title_for_block(block.block_id)
      if title and (window.label == title or window.label == title:upper()) then
        following[window.window_id] = true
        break
      end
    end
  end
end

rex.on("window_label_changed", function(ctx, ev)
  if not ev.label or ev.label == "" or default_window_label(ev.label, ev.window_id) then
    following[ev.window_id] = true
    pending_label[ev.window_id] = nil
    refresh_window_title(ev.window_id)
    return
  end
  if pending_label[ev.window_id] == ev.label then
    pending_label[ev.window_id] = nil
    return
  end
  following[ev.window_id] = false
  local upper = ev.label:upper()
  if upper ~= ev.label then
    pending_label[ev.window_id] = upper
    rex.session.set_window_label{ window_id = ev.window_id, label = upper }
  end
end)

rex.on("terminal.title_changed", function(ctx, ev)
  update_title_for_block(ctx, ctx.block_id, ev.title)
end)

rex.on("terminal.pwd_changed", function(ctx, ev)
  update_title_for_block(ctx, ctx.block_id)
end)

rex.on("session_label_changed", function(ctx, ev)
  local upper = ev.label and ev.label:upper()
  if upper and upper ~= ev.label then
    rex.session.set_label{ label = upper }
  end
end)
