--[[pod_format="raw",created="2025-11-18 12:32:00",modified="2025-11-18 12:32:00",revision=1]]
local geometry = {}

function geometry.rect_overlaps(rect, gen_rects, dynamic_spacing, map_size)
	if rect[1] < 0 or rect[3] >= map_size or rect[2] < 0 or rect[4] >= map_size then
		return true
	end
	local spacing = dynamic_spacing or 0
	for _, r in ipairs(gen_rects) do
		if r then
			if not (rect[3] + spacing < r[1]
				or rect[1] > r[3] + spacing
				or rect[4] + spacing < r[2]
				or rect[2] > r[4] + spacing) then
				return true
			end
		end
	end
	return false
end

function geometry.rect_conflicts(rect, gen_rects, map_size, ignore_nodes, spacing_override, dynamic_spacing)
	if rect[1] < 0 or rect[3] >= map_size or rect[2] < 0 or rect[4] >= map_size then
		return true
	end
	local ignore = {}
	if ignore_nodes then
		for _, n in ipairs(ignore_nodes) do
			if n and n.index then
				ignore[n.index] = true
			end
		end
	end
	local spacing = (spacing_override ~= nil) and spacing_override or (dynamic_spacing or 0)
	for idx = 1, #gen_rects do
		if not ignore[idx] then
			local r = gen_rects[idx]
			if r and not (rect[3] + spacing < r[1]
				or rect[1] > r[3] + spacing
				or rect[4] + spacing < r[2]
				or rect[2] > r[4] + spacing) then
				return true
			end
		end
	end
	return false
end

function geometry.fill_rect(rect, val, set_wall, map_size)
	local max_index = map_size - 1
	local x0 = max(0, rect[1])
	local x1 = min(max_index, rect[3])
	local y0 = max(0, rect[2])
	local y1 = min(max_index, rect[4])
	local fill_val = val or 0
	for x = x0, x1 do
		for y = y0, y1 do
			set_wall(x, y, fill_val)
		end
	end
end

return geometry
