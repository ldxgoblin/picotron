--[[pod_format="raw",created="2025-07-04 05:21:03",modified="2025-07-07 20:49:46",revision=54]]
if (_loaded.Player) return _loaded.Player

local Player = {
	__name = "Player",
	__type = "Player",
}
Player.__index = Player

-- construct a new player instance
function Player:new(obj)
	return setmetatable({
		pos = obj.pos or vec(0, 0, 0),
		angle = obj.angle or 0,
		fov = obj.fov or 90,
	}, self)
end

-- move the player relative to its facing direction
function Player:move(x, y)
	local pos, angle = self.pos, self.angle
	pos.x += cos(angle) * x  pos.z += sin(angle) * x
	pos.z += cos(angle) * y  pos.x -= sin(angle) * y
end

_loaded.Player = Player
return Player