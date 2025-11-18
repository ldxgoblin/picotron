--[[pod_format="raw",created="2024-03-19 09:34:40",modified="2024-05-04 11:28:16",revision=592]]
local _compat_seen = {}
function compat(msg)
	-- this function runs every time the translation layer notices possible compatibility issues
	-- currently, it prints to the host console, but you could do something else here if you want
	if not _compat_seen[msg] then
		_compat_seen[msg] = true --only show once
		msg = "COMPAT: "..msg
		printh(msg)
--		notify(msg)
	end
--	assert(false,msg)
end



-- to run fullscreen with a border, set "fullscreen = true" instead.
local fullscreen = true
-- to draw a border image, create a new spritesheet in the gfx editor,
--   save it as gfx/border.gfx, and store a 480x270 sprite in sprite 1
-- this tool can help you convert PNG files to picotron:
--   https://www.lexaloffle.com/bbs/?pid=importpng#p

local pause_when_unfocused = true



has_focus = true --used by p8env.btn/btnp
if pause_when_unfocused then
	on_event("lost_focus", function() has_focus = false end)
	on_event("gained_focus", function() has_focus = true end)
end

-- set pico8 font as default
-- the alternate font is already set to p8.font (see /system/lib/head.lua)
poke(0x4000,get(fetch"/system/fonts/p8.font"))



--------------------------------
-- load game modules
--------------------------------

-- load root modules
local root_modules = {
	"./configuration.lua",
	"./globals.lua",
}

local src_tabs = {
	"./src/core.lua",
	"./src/update.lua",
	"./src/draw.lua",
	"./src/gameplay.lua",
	"./src/ui_windows.lua",
	"./src/mobs.lua",
	"./src/inventory.lua",
	"./src/items.lua",
	"./src/mapGenerator.lua",
}

for _, relpath in ipairs(root_modules) do
	local filename = fullpath(relpath)
	local src = fetch(filename)
	local func,err = load(src, "@"..filename, "t", _ENV)
	if err then
		send_message(3, {event="report_error", content = "*syntax error"})
		send_message(3, {event="report_error", content = tostr(err)})
		stop()
		return
	end
	func()
end

for _, relpath in ipairs(src_tabs) do
	local filename = fullpath(relpath)
	local src = fetch(filename)
	-- @ is a special character that tells debugger the string is a filename
	local func,err = load(src, "@"..filename, "t", _ENV)
	if err then
		-- syntax error while loading
		send_message(3, {event="report_error", content = "*syntax error"})
		send_message(3, {event="report_error", content = tostr(err)})
	
		stop()
		return
	end
	func()
end

-- capture game callbacks defined by p8code before we override _init/_update/_draw
local game_init   = _init
local game_update = _update
local game_update60 = _update60
local game_draw   = _draw


--------------------------------
-- init/update/draw
--------------------------------

function p8x8_init()
	-- https://lospec.com/palette-list/pico-8-secret-palette
	poke4(0x5000+48*4, --set pal 48-63 to the p8 "secret colors"
		0x291814, 0x111d35, 0x422136, 0x125359,
		0x742f29, 0x49333b, 0xa28879, 0xf3ef7d,
		0xbe1250, 0xff6c24, 0xa8e72e, 0x00b543,
		0x065ab5, 0x754665, 0xff6e59, 0xff9d81)

	if game_init then game_init() end
end

local p8x8_draw
if fullscreen then
	vid(0)
	local winw,winh = 480,270

	p8x8_draw = function()
		if not has_focus then return end
		if game_draw then game_draw() end
	end
else
	-- windowed
	local title = fetch("./window_title.txt")
	window {
		title = title,
		width = 128,
		height = 128,
		resizeable = false,
		autoclose = true, -- esc=quit
	}

	function p8x8_draw()
		if not has_focus then return end

		-- can't set directly b/c cart might change _draw midgame
		if game_draw then game_draw() end
	end
end

_init = p8x8_init
function _update()
	if not has_focus then return end

	-- Prefer 60fps update when available
	if game_update60 then
		game_update60()
	elseif game_update then
		game_update()
	end
end
function _draw()
	if not has_focus then return end

	p8x8_draw()
end
