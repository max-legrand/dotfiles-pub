-- rex-run.lua - run an init.lua action in the session the Windows app is showing.
--
--   rex [-S HOST] do rex-run.lua action=NAME title="PANE TITLE" [KEY=VALUE...]
--
-- rex-prefix.ahk runs this for every init.lua action. On a server with
-- several sessions, `rex do NAME` has no session to act on, and the server
-- can't tell which one the app is looking at. The app's window title starts
-- with the focused pane's title, so pick the session whose focused pane has
-- that title. Any other KEY=VALUE pairs become the action's arguments.

local action = rex.args.action
local title = rex.args.title
if not action then error("rex-run.lua: action= is required", 0) end
local args = {}
for k, v in pairs(rex.args) do
  if k ~= "action" and k ~= "title" then args[k] = v end
end
if next(args) == nil then args = nil end

local sessions = rex.call("session.list").sessions or {}
local session_id
if #sessions == 1 then
  session_id = sessions[1].session_id
else
  for _, s in ipairs(sessions) do
    rex.session.attach{ session_id = s.session_id }
    local view = rex.session.view{ session_id = s.session_id }
    for _, w in ipairs(view and view.windows or {}) do
      if w.window_id == view.active_window_id and w.focused_block_id then
        local t = rex.call("com.superlogical.terminal.title", {
          session_id = s.session_id, block_id = w.focused_block_id,
        })
        if t and t.title == title then
          session_id = s.session_id
        end
      end
    end
    if session_id then break end
  end
end
if not session_id then
  error(("rex-run.lua: no session's focused pane is titled %q"):format(tostring(title)), 0)
end

local function run(name)
  return rex.call("client.action", {
    action = name, args = args, session_id = session_id, origin = "key",
  })
end

local result, err = run(action)
-- A server whose init.lua predates the srv_ scrollback action still has the
-- original one.
if not result and action == "srv_scrollback_nvim" then
  result, err = run("scrollback_nvim")
end
if not result and err then error(err, 0) end
return result
