--[[pod_format="raw",created="2025-06-21 04:30:01",modified="2025-07-09 18:53:22",revision=5329]]
if (_loaded.Sector) return _loaded.Sector

local render = include "render.lua"
local wall3d = render.wall3d

local utils = include "utils.lua"
local sign = utils.sign

-- describe a convex polygon of stitches
local Sector = {
	__name = "Sector",
	__type = "Sector",
}
Sector.__index = Sector

-- construct a new Sector
function Sector:new(obj)
	return setmetatable({
		lo = obj.lo or 0, hi = obj.hi or 2,
		los = obj.los or 2, his = obj.his or 2,
		stitches = obj.stitches or {},
	}, Sector)
end

-- calculate our AABB bounding box
function Sector:aabb()
	local ax, ay = nil, nil
	local bx, by = nil, nil
	stop "not implemented"
	return vec(ax, ay), vec(bx, by)
end

-- check whether our sector contains a given point
function Sector:contains(pos)
	local prev = nil
	for stitch in all(self.stitches) do
		if prev == nil then
			prev = sign(stitch:side(pos))
		else
			local curr = sign(stitch:side(pos))
			if (prev != curr) return false
		end
	end
	return true
end

-- draw our sector's walls & floors
function Sector:draw()
	local lo, hi = self.lo, self.hi
	for i, stitch in ipairs(self.stitches) do
		stitch:draw(lo, hi)
	end
end

_loaded.Sector = Sector
return Sector