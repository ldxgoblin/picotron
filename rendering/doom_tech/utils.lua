--[[pod_format="raw",created="2025-06-21 17:44:18",modified="2025-07-09 18:53:22",revision=1025]]
if (_loaded.utils) return _loaded.utils

local utils = {}
local log = {}

-- used to "take" a 2D top-down vector from a 3D vertex
utils.xz = userdata("i32", 2)
utils.xz:set(0,  0, 2)

-- used to "take" a 2D front-facing vector from a 3D vertex
utils.xy = userdata("i32", 2)
utils.xy:set(0,  0, 1)

-- used tok "take" texture coordinates from a 3D vertex
utils.uv = userdata("i32", 2)
utils.uv:set(0,  3, 4)

-- linearly interpolate two values
function utils.lerp(a, b, n)
	return (1 - n) * a + n * b
end

-- remap a value from one range to [0,1]
function utils.ilerp(v, a, b)
	return (v - a) / (b - a)
end

-- remap a value from one range to another
function utils.remap(v, a, b, t1, t2)
	t1, t2 = t1 or 0, t2 or 1
	return (v - a) / (b - a) * (t2 - t1) + t1
end

-- get the sign of a given number (1, -1, or 0)
function utils.sign(num)
	return num > 0 and 1 or (num == 0 and 0 or -1)
end

-- get the value of a button as a scalar from 0 to 1
function utils.btnv(b, pl)
	return (btn(b, pl) or 0) / 255
end

-- log something to the screen
function utils.log(msg)
	if type(msg) == "string" then
		add(log, msg)
	else
		add(log, tostring(msg))
	end
end

-- show log output and clear it
function utils.flush()
	for msg in all(log) do
		print(msg)
	end
	log = {}
end

_loaded.utils = utils
return utils