-- Workaround for a vis bug: when its terminal goes away (tab/window closed,
-- tmux server killed, ssh dropped) vis doesn't exit. The dead tty reads as
-- "readable" forever, so the main loop redraws in a tight loop at 100% CPU,
-- reparented to launchd, until killed with -9.
--
-- Interactive use draws a few dozen frames a second at most; the spin draws
-- hundreds of thousands. After a burst of frames, check that the terminal
-- still exists. If it doesn't: save unsaved buffers next to the originals
-- (<file>.vis-recover) and exit.
local BURST, WINDOW = 300, 2 -- frames, seconds

local count, since = 0, os.time()

local function tty_alive()
	local f = io.open("/dev/tty", "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function rescue_and_exit()
	local saved = {}
	for win in vis:windows() do
		local file = win.file
		if file.modified then
			local path = (file.path or ((os.getenv("HOME") or "/tmp") .. "/unnamed")) .. ".vis-recover"
			if not saved[path] then
				local f = io.open(path, "w")
				if f then
					f:write(file:content(0, file.size))
					f:close()
					saved[path] = true
				end
			end
		end
	end
	os.exit(1)
end

vis.events.subscribe(vis.events.UI_DRAW, function()
	count = count + 1
	if count < BURST then
		return
	end
	local now = os.time()
	if now - since <= WINDOW and not tty_alive() then
		rescue_and_exit()
	end
	count, since = 0, now
end)
