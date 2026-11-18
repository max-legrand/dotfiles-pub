-- rex-worker.lua - a long-running `rex [-S HOST] do rex-worker.lua` that
-- rex-prefix.ahk feeds one command per line on stdin:
--
--   <action>[ key=value ...]<TAB><pane title>
--
-- Starting rex.exe for every key press costs ~0.1s locally and ~0.3s on a
-- remote host, and quick presses ran in parallel and out of order. One worker
-- per host keeps its connection open and runs commands in order (~5ms local,
-- ~20ms remote).
--
-- The Windows app doesn't tell the server which session it is showing, so the
-- pane title from the app's window title picks it: the session used last is
-- checked first, then the others. With no match (a stale or shared title such
-- as "nvim"), the last session is used again.
--
-- Nothing is printed: AHK never reads stdout, and a full pipe would block.
-- Errors go to %TEMP%\rex-worker.log (or $TMPDIR).

local LOG = (os.getenv("TEMP") or os.getenv("TMPDIR") or "/tmp") .. "/rex-worker.log"

local function log(msg)
  local f = io.open(LOG, "a")
  if f then
    f:write(os.date("%H:%M:%S "), tostring(msg), "\n")
    f:close()
  end
end

local attached = {}
local last_sid

local function sessions()
  local list = (rex.call("session.list") or {}).sessions or {}
  for _, s in ipairs(list) do
    if not attached[s.session_id] then
      rex.session.attach{ session_id = s.session_id }
      attached[s.session_id] = true
    end
  end
  return list
end

local function focused_title(sid)
  local view = rex.session.view{ session_id = sid }
  for _, w in ipairs(view and view.windows or {}) do
    if w.window_id == view.active_window_id and w.focused_block_id then
      local t = rex.call("com.superlogical.terminal.title", {
        session_id = sid, block_id = w.focused_block_id,
      })
      return t and t.title
    end
  end
end

local function resolve(title)
  if last_sid and focused_title(last_sid) == title then return last_sid end
  local list = sessions()
  if #list == 1 then return list[1].session_id end
  for _, s in ipairs(list) do
    if s.session_id ~= last_sid and focused_title(s.session_id) == title then
      return s.session_id
    end
  end
  return last_sid or (list[1] and list[1].session_id)
end

-- "srv_split direction=right" -> "srv_split", { direction = "right" }
local function parse(spec)
  local name, args = nil, nil
  for word in spec:gmatch("%S+") do
    if not name then
      name = word
    else
      local k, v = word:match("^([^=]+)=(.*)$")
      if k then
        args = args or {}
        args[k] = tonumber(v) or v
      end
    end
  end
  return name, args
end

local function handle(line)
  local spec, title = line:match("^([^\t]*)\t?(.*)$")
  local action, args = parse(spec or "")
  if not action then return end
  local sid = resolve(title)
  if not sid then error("no session to act on", 0) end
  last_sid = sid
  local _, err = rex.call("client.action", {
    action = action, args = args, session_id = sid, origin = "key",
  })
  if err then log(action .. ": " .. tostring(err)) end
end

sessions()
while true do
  local line = io.read("*l")
  if not line then break end
  local ok, err = pcall(handle, line)
  if not ok then
    log("error: " .. tostring(err))
    -- If the connection is gone, exit so AHK starts a fresh worker.
    local ok_call, status = pcall(rex.call, "server.status")
    if not (ok_call and status) then
      log("connection lost, exiting")
      rex.stop(1)
    end
  end
end
