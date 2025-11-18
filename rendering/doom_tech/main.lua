--[[pod_format="raw",created="2025-01-17 10:35:48",modified="2025-07-09 18:53:23",revision=7004]]
_loaded = {}

local Stitch = include "stitch.lua"
local Sector = include "sector.lua"

local Player = include "player.lua"

local render = include "render.lua"

local utils = include "utils.lua"
local btnv = utils.btnv
local flush = utils.flush

--[[
	Coordinate system:
		Y-up
		Z-forward
		Left-handed/Clockwise
--]]
--[[pod_type="gfx"]]unpod("b64:bHo0AGQAAABjAAAA8QhweHUAQyAgIATw2QvwDhvwDTvwDAsAGwUA8AVQPPAEC4Ac8AQLcAwADPAEC2AMEAcA8AdQDPAIC0AM8AkLMAzwCgsgDPALCxAMMwDwBgxwGPADCwygGPABC9jwDRjwDRjw2g==")
-- Picotron framerate is capped at 60
local delta = 1.0 / 60.0

-- list of video mode IDs
local modes = { 0, 3, 4 }

local player = nil
local y = 0

local dm = 0 -- display mode
local perf = false -- show performance counter

local look = 8 -- button offset for look stick
local move = 0 -- button offset for move stick

local model = {
	verts = {
		-- front face
		vec(-0.5, -0.5, -0.5,   0, 32),
		vec( 0.5, -0.5, -0.5,  32, 32),
		vec( 0.5,  0.5, -0.5,  32,  0),
		vec(-0.5,  0.5, -0.5,   0,  0),
		-- top face
		vec(-0.5, 0.5, -0.5,   0, 32),
		vec( 0.5, 0.5, -0.5,  32, 32),
		vec( 0.5, 0.5,  0.5,  32,  0),
		vec(-0.5, 0.5,  0.5,   0,  0),
		-- left face
		vec(-0.5, -0.5,  0.5,   0, 32),
		vec(-0.5, -0.5, -0.5,  32, 32),
		vec(-0.5,  0.5, -0.5,  32,  0),
		vec(-0.5,  0.5,  0.5,   0,  0),
		-- right face
		vec(0.5, -0.5, -0.5,   0, 32),
		vec(0.5, -0.5,  0.5,  32, 32),
		vec(0.5,  0.5,  0.5,  32,  0),
		vec(0.5,  0.5, -0.5,   0,  0),
		-- back face
		vec( 0.5, -0.5, 0.5,   0, 32),
		vec(-0.5, -0.5, 0.5,  32, 32),
		vec(-0.5,  0.5, 0.5,  32,  0),
		vec( 0.5,  0.5, 0.5,   0,  0),
	},
	faces = {
		1, 2, 3,  3, 4, 1,
		5, 6, 7,  7, 8, 5,
		9, 10, 11,  11, 12, 9,
		13, 14, 15,  15, 16, 13,
		17, 18, 19, 19, 20, 17,
	},
}

local sector = Sector:new{
	stitches = {
		Stitch:new{ pos1 = vec(-3, 3), pos2 = vec(-2, 4) },
		Stitch:new{ pos1 = vec(-2, 4), pos2 = vec(2, 4) },
		Stitch:new{ pos1 = vec(2, 4), pos2 = vec(3, 3) },

		Stitch:new{ pos1 = vec(3, 3), pos2 = vec(3, -3) },
		Stitch:new{ pos1 = vec(3, -3), pos2 = vec(-3, -3) },
		Stitch:new{ pos1 = vec(-3, -3), pos2 = vec(-3, 3) },
	}
}

local function get_display_size()
	local disp = get_display()
	return disp:width(), disp:height()
end

function _init()
	-- initial video mode
	vid(modes[dm + 1])
	-- set render size to display size
	render:setsize(get_display_size())
	-- create player
	player = Player:new{
		pos = vec(0, 1.5, -2.5),
		fov = 85,
	}
end

function _update()
	-- switch video mode
	if btnp(14) then
		dm = max(0, dm - 1)
		vid(modes[dm + 1])
		render:setsize(get_display_size())
	end
	if btnp(15) then
		dm = min(#modes - 1, dm + 1)
		vid(modes[dm + 1])
		render:setsize(get_display_size())
	end
	-- switch performance counter
	if (keyp "p") perf = not perf
	-- look controls
	local lspeed = delta * 0.65
	player.angle += (btnv(look + 1) - btnv(look + 0)) * lspeed
	-- mouselook controls
	player.angle = (player.angle + mouselock(true, 1, 0) / 2048) % 1.0
	-- move controls
	local mspeed = delta * 4
	local movex = (btnv(move + 1) - btnv(move + 0))
	local movey = (btnv(move + 2) - btnv(move + 3))
	player:move(movex * mspeed, movey * mspeed)
	y = 1 - sin(t() / 1.5 % 1) / 3
end

function _draw()
	-- clear screen & color
	cls(0) color(6)
	-- push print cursor down
	if (perf) print("", 0, 4)
	-- update render camera to player view
	render:setcam(player.pos, player.angle, player.fov)
	-- draw scene
	sector:draw()
	-- draw model
	render:setmodel(
		1, 0, 0,
		0, 1, 0,
		0, 0, 1,
		0, y, 0
	)
	render:model3d(model.verts, model.faces, 64)
	-- flush console output
	color(7) flush()
	-- show CPU usage
	if perf then
		local cpu = stat(1)
		print("\^o1ffCPU:"..(cpu * 10000 // 1 / 100).."%", 2, 2)
	end
end