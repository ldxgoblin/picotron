--[[pod_format="raw",created="2025-11-18 11:36:00",modified="2025-11-18 11:36:00",revision=1]]
local map_state = {}

-- MapState snapshot for renderers, tools, and tests
-- Purpose:
--   Return a structured view over the *current* dungeon / gameplay state.
--   The fields in the returned table alias the live globals (map, doors,
--   doorgrid, objects, player, gen_nodes, gen_edges, gen_stats, etc.).
--   It does *not* create a second copy of the world state.
-- Schema (keys on the returned table):
--   map_size           : integer grid size (configuration.map_size)
--   get_wall/set_wall  : functions for walls layer
--   get_floor/set_floor: functions for floor layer
--   doors              : array of door objects
--   doorgrid           : door lookup table [x][y] -> door or nil
--   objects            : array of gameplay objects (npcs, items, decor, exits)
--   animated_objects   : subset of objects with autoanim=true
--   player_start       : { x, y } spawn position from last generation
--   player             : player state table
--   floor, roof        : global floor/ceiling scroll state
--   gen_nodes          : room/junction graph nodes
--   gen_edges          : corridor edges between nodes
--   gen_locked_edges   : edges chosen as progression gates
--   gen_stats          : { rooms, objects, seed, history }
--   planetyps, texsets : configuration tables from configuration.lua
--   door_normal/...    : door and exit tile id constants
--   is_door/is_exit    : helper predicates for tile classification
function map_state.build(context)
	local state = {}

	state.map_size = map_size

	state.get_wall = get_wall
	state.get_floor = get_floor
	state.set_wall = set_wall
	state.set_floor = set_floor

	state.doors = context.doors or doors
	state.doorgrid = context.doorgrid or doorgrid

	state.objects = context.objects or objects
	state.animated_objects = context.animated_objects or animated_objects

	state.player_start = { x = start_pos and start_pos.x or player.x, y = start_pos and start_pos.y or player.y }
	state.player = context.player or player

	state.floor = context.floor or floor
	state.roof = context.roof or roof

	state.gen_nodes = gen_nodes
	state.gen_edges = gen_edges
	state.gen_locked_edges = gen_locked_edges

	state.gen_stats = gen_stats

	state.planetyps = planetyps
	state.texsets = texsets
	state.door_normal = door_normal
	state.door_locked = door_locked
	state.door_stay_open = door_stay_open
	state.exit_start = exit_start
	state.exit_end = exit_end

	state.is_door = is_door
	state.is_exit = is_exit

	return state
end

return map_state
