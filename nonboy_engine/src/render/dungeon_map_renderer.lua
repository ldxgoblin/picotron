--[[pod_format="raw",created="2025-11-18 15:45:00",modified="2025-11-18 15:45:00",revision=1]]
-- Dungeon map renderer (2D top-down) built on MapState contract

local renderer = {}

local colors = {
	void = 0,
	floor = 1,
	wall = 5,
	door = 10,
	exit = 8,
	player = 12,
	object = 9
}

local function draw_cell(px, py, scale, col)
	rectfill(px, py, px + scale - 1, py + scale - 1, col)
end

local function choose_tile_color(state, tile)
	if not tile or tile == 0 then
		return colors.floor
	end
	if state.is_exit and state.is_exit(tile) then
		return colors.exit
	end
	if state.is_door and state.is_door(tile) then
		return colors.door
	end
	return colors.wall
end

function renderer.draw(state, opts)
	if not state or not state.get_wall then return end
	opts = opts or {}
	local origin_x = opts.x or 4
	local origin_y = opts.y or 4
	local max_w = opts.max_width or 256
	local max_h = opts.max_height or 256

	local map_size = state.map_size or 0
	if map_size <= 0 then return end

	-- determine occupied region from gen_nodes if available
	local view_x0, view_y0, view_x1, view_y1 = 0, 0, map_size - 1, map_size - 1
	if state.gen_nodes and #state.gen_nodes > 0 then
		local minx, miny = map_size - 1, map_size - 1
		local maxx, maxy = 0, 0
		for node in all(state.gen_nodes) do
			local r = node.rect
			if r and r[1] and r[2] and r[3] and r[4] then
				if r[1] < minx then minx = r[1] end
				if r[2] < miny then miny = r[2] end
				if r[3] > maxx then maxx = r[3] end
				if r[4] > maxy then maxy = r[4] end
			end
		end
		view_x0 = math.max(0, minx - 2)
		view_y0 = math.max(0, miny - 2)
		view_x1 = math.min(map_size - 1, maxx + 2)
		view_y1 = math.min(map_size - 1, maxy + 2)
	end

	local view_w = view_x1 - view_x0 + 1
	local view_h = view_y1 - view_y0 + 1
	local scale = math.max(1, math.floor(math.min(max_w / view_w, max_h / view_h)))
	local clipped_w = view_w * scale
	local clipped_h = view_h * scale
	clip(origin_x, origin_y, origin_x + clipped_w, origin_y + clipped_h)

	for y = view_y0, view_y1 do
		local py = origin_y + (y - view_y0) * scale
		for x = view_x0, view_x1 do
			local px = origin_x + (x - view_x0) * scale
			local tile = state.get_wall(x, y)
			local color = choose_tile_color(state, tile)
			if tile == 0 then
				local floor_tile = state.get_floor and state.get_floor(x, y) or 0
				color = floor_tile > 0 and colors.floor or colors.void
			end
			draw_cell(px, py, scale, color)
		end
	end

	clip()

	local function draw_marker(world_x, world_y, col)
		if not world_x or not world_y then return end
		local gx = math.floor(world_x)
		local gy = math.floor(world_y)
		if gx < view_x0 or gx > view_x1 or gy < view_y0 or gy > view_y1 then return end
		local px = origin_x + (world_x - view_x0) * scale
		local py = origin_y + (world_y - view_y0) * scale
		rectfill(px - 1, py - 1, px + 1, py + 1, col)
	end

	if state.player_start then
		draw_marker(state.player_start.x or 0, state.player_start.y or 0, colors.player)
	end

	if state.objects then
		for obj in all(state.objects) do
			local pos = obj.pos
			local ox = pos and (pos[1] or pos.x) or obj.x
			local oy = pos and (pos[2] or pos.y) or obj.y
			draw_marker(ox or 0, oy or 0, colors.object)
		end
	end

	if state.gen_nodes then
		for node in all(state.gen_nodes) do
			local r = node.rect
			if r and r[1] and r[2] and r[3] and r[4] then
				local x0 = origin_x + (r[1] - view_x0) * scale
				local y0 = origin_y + (r[2] - view_y0) * scale
				local x1 = origin_x + (r[3] - view_x0) * scale
				local y1 = origin_y + (r[4] - view_y0) * scale
				rect(x0, y0, x1, y1, 13)
			end
		end
	end
end

return renderer
