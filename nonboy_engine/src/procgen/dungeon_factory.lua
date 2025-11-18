--[[pod_format="raw",created="2025-11-18 11:37:00",modified="2025-11-18 11:37:00",revision=1]]
-- DungeonFactory: orchestrates world bootstrap and dungeon generation

local log = require("log")
local map_bootstrap = require("procgen.map_bootstrap")
local map_state = require("procgen.map_state")

include("src/procgen/dungeon/doors.lua")
include("src/procgen/dungeon/pipeline.lua")

local DungeonFactory = {
	current_state = nil
}

function DungeonFactory.init(opts)
	opts = opts or {}
	log.info("[DungeonFactory] init")
	map_bootstrap.init_world(opts)
	return DungeonFactory
end

function DungeonFactory.generate(opts)
	opts = opts or {}
	log.info("[DungeonFactory] generate start")
	local ok, err = pcall(function()
		start_pos, gen_stats = generate_dungeon(opts)
		DungeonFactory.current_state = map_state.build(map_bootstrap.get_context())
	end)
	if not ok then
		log.error("[DungeonFactory] generation failed: %s", tostring(err))
		wtf(tostring(err))
	end
	log.info("[DungeonFactory] generate done (rooms=%s, objects=%s)",
		tostring(gen_stats and gen_stats.rooms), tostring(gen_stats and gen_stats.objects))
	return DungeonFactory.current_state
end

function DungeonFactory.current()
	return DungeonFactory.current_state
end

return DungeonFactory
