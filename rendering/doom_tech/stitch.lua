--[[pod_format="raw",created="2025-06-21 16:49:57",modified="2025-07-09 18:53:22",revision=5469]]
if (_loaded.Stitch) return _loaded.Stitch

local render = include "render.lua"

-- describe a line from pos1 to pos2
local Stitch = {
	__name = "Stitch",
	__type = "Stitch",
}
Stitch.__index = Stitch

--[[
	Coordinate system:
		Stitch normals are 90 degrees clockwise
]]--

-- construct a new Stitch
function Stitch:new(obj)
	return setmetatable({
		s = obj.s or 1,
		pos1 = obj.pos1 or vec(0, 0),
		pos2 = obj.pos2 or vec(0, 0),
	}, Stitch)
end

-- get our tangent vector (not normalized)
function Stitch:tangent()
	return self.pos2 - self.pos1
end

-- get our normal vector (not normalized)
function Stitch:normal()
	local tangent = self.pos2 - self.pos1
	return vec(tangent.y, -tangent.x)
end

-- get the vector from our pos1 to a given point
function Stitch:to(pos)
	return pos - self.pos1
end

-- get which side of our stitch a given point falls on
function Stitch:side(pos)
	local normal = self:normal()
	return normal:dot(pos - self.pos1)
end

-- draw our stitch's wall
function Stitch:draw(lo, hi)
	local len = self:tangent():magnitude()
	local pos1 = vec(self.pos1.x, lo, self.pos1.y, 0)
	local pos2 = vec(self.pos2.x, hi, self.pos2.y, len)
	render:wall3d(pos1, pos2, self.s, 32, 32)
end

_loaded.Stitch = Stitch
return Stitch