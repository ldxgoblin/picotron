--[[pod_format="raw",created="2025-11-18 13:10:00",modified="2025-11-18 13:10:00",revision=1]]

local spacing  = require("procgen.dungeon.spacing")
local geometry = require("procgen.dungeon.geometry")

local corridors = {}

local observability      = spacing.observability
local adaptive_settings  = spacing.adaptive_settings
local gen_log            = spacing.gen_log
local protect_tile       = spacing.protect_tile

local function rect_conflicts(rect, ignore_nodes, spacing_override)
	return geometry.rect_conflicts(rect, gen_rects, map_size, ignore_nodes, spacing_override, spacing.get_dynamic_spacing())
end

local function get_corridor_type_internal(r1, r2)
	local ox = not (r1[3] < r2[1] or r1[1] > r2[3])
	local oy = not (r1[4] < r2[2] or r1[2] > r2[4])
	if ox and not oy then return "vert" end
	if oy and not ox then return "horiz" end
	return "l_shape"
end

local function place_boundary_door_with_retry_internal(bx, by, dtype, max_attempts)
	dtype = dtype or door_normal
	local offsets = {{0,0},{-1,0},{1,0},{0,-1},{0,1},{-2,0},{2,0},{0,-2},{0,2}}
	local attempts = max_attempts or #offsets
	for i = 1, attempts do
		local off = offsets[i] or offsets[#offsets]
		local ax, ay = bx + off[1], by + off[2]
		if ax >= 0 and ax < map_size and ay >= 0 and ay < map_size then
			local tile = get_wall(ax, ay)
			if is_wall(tile) then
				set_wall(ax, ay, dtype)
				create_door(ax, ay, dtype)
				protect_tile(ax, ay)
				if observability.log_corridors then
					gen_log("door", "boundary door placed at "..ax..","..ay.." (from "..bx..","..by..")")
				end
				return true
			end
		end
	end
	return false
end

local function place_boundary_door_internal(bx, by, dtype)
	if bx >= 0 and bx < 128 and by >= 0 and by < 128 then
		if is_wall(get_wall(bx, by)) then
			set_wall(bx, by, dtype or door_normal)
			create_door(bx, by, dtype)
			protect_tile(bx, by)
			return true
		end
	end
	return false
end

local function ensure_boundary_passage_internal(bx, by, floor_id)
	if not floor_id then return false end
	if bx >= 0 and bx < 128 and by >= 0 and by < 128 then
		local tile = get_wall(bx, by)
		if tile > 0 and not is_door(tile) and not is_exit(tile) then
			set_wall(bx, by, 0)
			set_floor(bx, by, floor_id)
			protect_tile(bx, by)
			if observability.log_repairs then
				gen_log("door", "fallback cleared wall at ("..bx..","..by..")")
			end
			return true
		end
	end
	return false
end

local function verify_boundary_door_internal(bx, by, dtype, floor_id)
	if not bx or not by then return end
	dtype = dtype or door_normal
	if bx < 0 or bx >= map_size or by < 0 or by >= map_size then return end
	local tile = get_wall(bx, by)
	if is_door(tile) then
		protect_tile(bx, by)
		return
	end
	if tile == 0 then
		set_wall(bx, by, dtype)
		create_door(bx, by, dtype)
		protect_tile(bx, by)
		if observability.log_repairs then
			gen_log("door", "repaired missing door at "..bx..","..by)
		end
	else
		local ok = place_boundary_door_with_retry_internal(bx, by, dtype, 6)
		if not ok then
			ensure_boundary_passage_internal(bx, by, floor_id)
		end
	end
end

local function carve_horizontal_span(y, x_start, x_end, floor_id)
	if not floor_id then return end
	if y < 0 or y >= map_size then return end
	local a = min(x_start, x_end)
	local b = max(x_start, x_end)
	a = max(0, a)
	b = min(map_size - 1, b)
	for x = a, b do
		set_wall(x, y, 0)
		set_floor(x, y, floor_id)
	end
end

local function carve_vertical_span(x, y_start, y_end, floor_id)
	if not floor_id then return end
	if x < 0 or x >= map_size then return end
	local a = min(y_start, y_end)
	local b = max(y_start, y_end)
	a = max(0, a)
	b = min(map_size - 1, b)
	for y = a, b do
		set_wall(x, y, 0)
		set_floor(x, y, floor_id)
	end
end

local function create_horizontal_corridor(n1, n2, edge, floor_id)
	local left, right = n1, n2
	if n1.midx > n2.midx then left, right = n2, n1 end
	local r_left, r_right = left.rect, right.rect
	local y_start = max(r_left[2], r_right[2])
	local y_end   = min(r_left[4], r_right[4])
	local y
	if y_start <= y_end then
		y = flr((y_start + y_end) / 2)
	else
		y = flr((n1.midy + n2.midy) / 2)
	end
	local jog_offset = 0
	local jog_chance = (active_theme_rules and active_theme_rules.corridor_jog_chance) or adaptive_settings.corridor_jog_chance or 0.25
	if rnd(1) < jog_chance then
		local offset = (rnd(1) < 0.5) and -1 or 1
		local candidate = y + offset
		if candidate > 1 and candidate < map_size - 2 then
			y = candidate
			jog_offset = offset
		end
	end
	local bx_left  = r_left[3] + 1
	local bx_right = r_right[1] - 1
	local success  = true
	if not place_boundary_door_with_retry_internal(bx_left, y, door_normal, 5) then
		success = false
		ensure_boundary_passage_internal(bx_left, y, floor_id)
	end
	if not place_boundary_door_with_retry_internal(bx_right, y, door_normal, 5) then
		success = false
		ensure_boundary_passage_internal(bx_right, y, floor_id)
	end
	carve_horizontal_span(y, bx_left + 1, bx_right - 1, floor_id)
	verify_boundary_door_internal(bx_left,  y, door_normal, floor_id)
	verify_boundary_door_internal(bx_right, y, door_normal, floor_id)
	edge.b1 = {x = bx_left,  y = y}
	edge.b2 = {x = bx_right, y = y}
	edge.shape = jog_offset ~= 0 and "jog" or "straight"
	edge.metadata.corridor_y = y
	edge.metadata.jog_offset = jog_offset
	return success
end

local function create_vertical_corridor(n1, n2, edge, floor_id)
	local top, bottom = n1, n2
	if n1.midy > n2.midy then top, bottom = n2, n1 end
	local r_top, r_bottom = top.rect, bottom.rect
	local x_start = max(r_top[1], r_bottom[1])
	local x_end   = min(r_top[3], r_bottom[3])
	local x
	if x_start <= x_end then
		x = flr((x_start + x_end) / 2)
	else
		x = flr((n1.midx + n2.midx) / 2)
	end
	local jog_offset = 0
	local jog_chance = (active_theme_rules and active_theme_rules.corridor_jog_chance) or adaptive_settings.corridor_jog_chance or 0.25
	if rnd(1) < jog_chance then
		local offset = (rnd(1) < 0.5) and -1 or 1
		local candidate = x + offset
		if candidate > 1 and candidate < map_size - 2 then
			x = candidate
			jog_offset = offset
		end
	end
	local by_top    = r_top[4]    + 1
	local by_bottom = r_bottom[2] - 1
	local success   = true
	if not place_boundary_door_with_retry_internal(x, by_top, door_normal, 5) then
		success = false
		ensure_boundary_passage_internal(x, by_top, floor_id)
	end
	if not place_boundary_door_with_retry_internal(x, by_bottom, door_normal, 5) then
		success = false
		ensure_boundary_passage_internal(x, by_bottom, floor_id)
	end
	carve_vertical_span(x, by_top + 1, by_bottom - 1, floor_id)
	verify_boundary_door_internal(x, by_top,    door_normal, floor_id)
	verify_boundary_door_internal(x, by_bottom, door_normal, floor_id)
	edge.b1 = {x = x, y = by_top}
	edge.b2 = {x = x, y = by_bottom}
	edge.shape = jog_offset ~= 0 and "jog" or "straight"
	edge.metadata.corridor_x = x
	edge.metadata.jog_offset = jog_offset
	return success
end

local function create_l_shaped_corridor(n1, n2, edge, floor_id)
	local orient_horizontal_first = rnd(1) < 0.5
	local anchor_x = orient_horizontal_first and n2.midx or n1.midx
	local anchor_y = orient_horizontal_first and n1.midy or n2.midy
	local jrect
	local offsets = {{0,0},{1,0},{-1,0},{0,1},{0,-1},{2,0},{-2,0},{0,2},{0,-2}}
	local attempt_limit = adaptive_settings.junction_retry_limit or 4
	for i = 1, #offsets do
		local off = offsets[i]
		local cx = max(1, min(map_size - 2, anchor_x + off[1]))
		local cy = max(1, min(map_size - 2, anchor_y + off[2]))
		local candidate = {cx - 1, cy - 1, cx + 1, cy + 1}
		if not rect_conflicts(candidate, {n1, n2}, 0) then
			jrect = candidate
			anchor_x = cx
			anchor_y = cy
			break
		end
		if i >= attempt_limit then break end
	end
	local success = true
	if not jrect then
		orient_horizontal_first = true
		anchor_x = n2.midx
		anchor_y = n1.midy
		jrect = nil
		success = false
		if observability.log_corridors then
			gen_log("corridor", "fallback L-shape without junction between rooms")
		end
	else
		fill_rect(jrect, 0)
		for x = jrect[1], jrect[3] do
			for y = jrect[2], jrect[4] do
				set_floor(x, y, floor_id)
			end
		end
		local jnode = add_room(jrect, true)
		edge.metadata.junction_node = jnode
	end

	local function connect_horizontal(from_node, target_x, y)
		local rect = from_node.rect
		local side = target_x > from_node.midx and 1 or -1
		local boundary_from = (side == 1) and rect[3] + 1 or rect[1] - 1
		local boundary_to = side == 1 and target_x - 1 or target_x + 1
		local door_pos = boundary_from
		if not place_boundary_door_with_retry_internal(door_pos, y, door_normal, 5) then
			success = false
			ensure_boundary_passage_internal(door_pos, y, floor_id)
		end
		carve_horizontal_span(y, boundary_from + side, boundary_to, floor_id)
		verify_boundary_door_internal(door_pos, y, door_normal, floor_id)
		return {x = door_pos, y = y}
	end

	local function connect_vertical(from_node, x, target_y)
		local rect = from_node.rect
		local side = target_y > from_node.midy and 1 or -1
		local boundary_from = (side == 1) and rect[4] + 1 or rect[2] - 1
		local boundary_to = side == 1 and target_y - 1 or target_y + 1
		local door_pos = boundary_from
		if not place_boundary_door_with_retry_internal(x, door_pos, door_normal, 5) then
			success = false
			ensure_boundary_passage_internal(x, door_pos, floor_id)
		end
		carve_vertical_span(x, boundary_from + side, boundary_to, floor_id)
		verify_boundary_door_internal(x, door_pos, door_normal, floor_id)
		return {x = x, y = door_pos}
	end

	local b1, b2
	if orient_horizontal_first then
		local horizontal_y = n1.midy
		b1 = connect_horizontal(n1, anchor_x, horizontal_y)
		local vertical_x = jrect and anchor_x or b1.x + (anchor_x > b1.x and 1 or -1)
		b2 = connect_vertical(n2, vertical_x, anchor_y)
	else
		local vertical_x = n1.midx
		b1 = connect_vertical(n1, vertical_x, anchor_y)
		local horizontal_y = jrect and anchor_y or b1.y + (anchor_y > b1.y and 1 or -1)
		b2 = connect_horizontal(n2, anchor_x, horizontal_y)
	end

	edge.b1 = b1
	edge.b2 = b2
	edge.shape = "l_shape"
	edge.metadata.anchor = {x = anchor_x, y = anchor_y}
	edge.metadata.orientation = orient_horizontal_first and "hv" or "vh"
	return success
end

function corridors.get_corridor_type(r1, r2)
	return get_corridor_type_internal(r1, r2)
end

function corridors.place_boundary_door_with_retry(bx, by, dtype, max_attempts)
	return place_boundary_door_with_retry_internal(bx, by, dtype, max_attempts)
end

function corridors.place_boundary_door(bx, by, dtype)
	return place_boundary_door_internal(bx, by, dtype)
end

function corridors.ensure_boundary_passage(bx, by, floor_id)
	return ensure_boundary_passage_internal(bx, by, floor_id)
end

function corridors.create_corridor(n1, n2, floor_id)
	local edge = { n1 = n1, n2 = n2, metadata = {} }
	local ctype = get_corridor_type_internal(n1.rect, n2.rect)
	local success
	if ctype == "horiz" then
		success = create_horizontal_corridor(n1, n2, edge, floor_id)
	elseif ctype == "vert" then
		success = create_vertical_corridor(n1, n2, edge, floor_id)
	else
		success = create_l_shaped_corridor(n1, n2, edge, floor_id)
	end
	edge.success = success
	add(gen_edges, edge)
	add(n1.edges, n2)
	add(n2.edges, n1)
	if observability.log_corridors then
		local status = success and "ok" or "fallback"
		gen_log("corridor", "linked nodes "..n1.index.." <-> "..n2.index.." ("..ctype..","..status..")")
	end
	return success
end

return corridors
