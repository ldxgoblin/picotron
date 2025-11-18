--[[pod_format="raw",created="2025-11-18 11:35:00",modified="2025-11-18 11:35:00",revision=1]]
-- Map bootstrap: allocates userdata layers and establishes world globals

local log = require("log")

local map_bootstrap = {
	context = nil
}

local function init_doorgrid(size)
	local grid = {}
	for i = 0, size - 1 do
		grid[i] = {}
	end
	return grid
end

--- Initializes map userdata, helper accessors, and core gameplay tables.
--- Returns a context table aliasing the live globals so downstream systems can
--- reuse the references without searching the global namespace.
function map_bootstrap.init_world(opts)
	opts = opts or {}

	log.info("[MapBootstrap] initializing world (size=%d)", map_size)

	map = {}
	map.walls = userdata("i16", map_size, map_size)
	map.doors = userdata("i16", map_size, map_size)
	map.floors = userdata("i16", map_size, map_size)

	function get_wall(x, y)
		if x >= 0 and x < map_size and y >= 0 and y < map_size then
			return map.walls:get(x, y) or 0
		end
		return 0
	end

	function set_wall(x, y, val)
		if x >= 0 and x < map_size and y >= 0 and y < map_size then
			map.walls:set(x, y, val or 0)
		end
	end

	function get_door(x, y)
		if x >= 0 and x < map_size and y >= 0 and y < map_size then
			return map.doors:get(x, y) or 0
		end
		return 0
	end

	function set_door(x, y, val)
		if x >= 0 and x < map_size and y >= 0 and y < map_size then
			map.doors:set(x, y, val or 0)
		end
	end

	function get_floor(x, y)
		if x >= 0 and x < map_size and y >= 0 and y < map_size then
			return map.floors:get(x, y) or 0
		end
		return 0
	end

	function set_floor(x, y, val)
		if x >= 0 and x < map_size and y >= 0 and y < map_size then
			map.floors:set(x, y, val or 0)
		end
	end

	doorgrid = init_doorgrid(map_size)
	doors = {}
	objects = {}
	animated_objects = {}

	player = {
		x = 64,
		y = 64,
		a = 0,
		spd = player_move_speed,
		keys = {},
		hp = 100
	}

	floor = { typ = planetyps[1], x = 0, y = 0 }
	roof = { typ = planetyps[3], x = 0, y = 0 }

	gen_stats = { rooms = 0, objects = 0, seed = 0, history = {} }
	start_pos = { x = player.x, y = player.y }

	local ctx = {
		map = map,
		doorgrid = doorgrid,
		doors = doors,
		objects = objects,
		animated_objects = animated_objects,
		player = player,
		floor = floor,
		roof = roof,
		gen_stats = gen_stats,
		start_pos = start_pos
	}

	map_bootstrap.context = ctx
	return ctx
end

function map_bootstrap.get_context()
	return map_bootstrap.context
end

return map_bootstrap
