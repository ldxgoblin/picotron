--[[pod_format="raw",created="2025-11-18 12:50:00",modified="2025-11-18 12:50:00",revision=1]]
-- Room generation helpers for the dungeon pipeline

local spacing = require("procgen.dungeon.spacing")

local rooms = {}

local observability     = spacing.observability
local adaptive_settings = spacing.adaptive_settings
local gen_log           = spacing.gen_log

local function rect_area(rect)
	return (rect[3] - rect[1] + 1) * (rect[4] - rect[2] + 1)
end

local function classify_room_style(rect)
	local w = rect[3] - rect[1] + 1
	local h = rect[4] - rect[2] + 1
	local ratio = w / h
	if ratio >= 1.8 then
		return "hall_horizontal"
	elseif ratio <= 0.55 then
		return "hall_vertical"
	elseif w * h >= 120 then
		return "grand"
	elseif w <= 6 and h <= 6 then
		return "compact"
	else
		return "square"
	end
end

local function choose_weighted(weights, default_key)
	if not weights then return default_key end
	local total = 0
	for _, v in pairs(weights) do
		total += v
	end
	if total <= 0 then return default_key end
	local roll = rnd(total)
	local acc = 0
	for key, v in pairs(weights) do
		acc += v
		if roll <= acc then return key end
	end
	return default_key
end

function rooms.random_room(base_node, is_special)
	local min_size = gen_params.min_size or 4
	local max_size = gen_params.max_size or 12
	if active_theme_rules and active_theme_rules.room_extra_size then
		max_size += active_theme_rules.room_extra_size
	end
	if max_size < min_size then max_size = min_size end
	local shape_weights = active_theme_rules and active_theme_rules.room_shape_weights
	local shape = choose_weighted(shape_weights, "square")
	local w, h
	if is_special then
		w, h = 12, 12
	else
		if shape == "hall_horizontal" then
			w = flr(rnd(max_size - min_size + 1)) + min_size
			h = max(min_size, flr(w * 0.5))
		elseif shape == "hall_vertical" then
			h = flr(rnd(max_size - min_size + 1)) + min_size
			w = max(min_size, flr(h * 0.5))
		elseif shape == "grand" then
			w = max_size
			h = max(min_size, max_size - 2)
		else
			w = flr(rnd(max_size - min_size + 1)) + min_size
			h = flr(rnd(max_size - min_size + 1)) + min_size
		end
	end
	w = min(w, max_size)
	h = min(h, max_size)
	w = max(w, min_size)
	h = max(h, min_size)

	local function sample_offset(range)
		local bias = (active_theme_rules and active_theme_rules.center_bias) or adaptive_settings.offcenter_bias or 0.65
		local magnitude = flr(range * (rnd() ^ bias))
		if rnd(1) < 0.5 then magnitude = -magnitude end
		return magnitude
	end

	local x, y
	if base_node then
		local radius = (active_theme_rules and active_theme_rules.bias_radius) or adaptive_settings.bias_radius or 12
		local dx = sample_offset(radius)
		local dy = sample_offset(radius)
		x = base_node.midx + dx - flr(w / 2)
		y = base_node.midy + dy - flr(h / 2)
	else
		local margin = 4
		x = flr(rnd(map_size - w - margin * 2)) + margin
		y = flr(rnd(map_size - h - margin * 2)) + margin
	end

	x = max(1, min(map_size - w - 2, x))
	y = max(1, min(map_size - h - 2, y))

	return { x, y, x + w - 1, y + h - 1 }
end

function rooms.add_room(rect, is_junction)
	local index = #gen_nodes + 1
	gen_rects[index] = rect
	local style = classify_room_style(rect)
	local node = {
		rect = rect,
		midx = flr((rect[1] + rect[3]) / 2),
		midy = flr((rect[2] + rect[4]) / 2),
		edges = {},
		is_junction = is_junction or false,
		style = style,
		area = rect_area(rect),
		theme = gen_params.theme,
		metadata = {},
		index = index
	}
	if observability.log_room_attempts then
		gen_log("room", "added room " .. (#gen_nodes + 1) .. " style=" .. style .. " rect=(" .. rect[1] .. "," .. rect[2] .. ")-(" .. rect[3] .. "," .. rect[4] .. ")")
	end
	add(gen_nodes, node)
	return node
end

return rooms
