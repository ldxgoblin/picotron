--[[pod_format="raw",created="2025-06-21 18:08:16",modified="2025-07-09 18:53:22",revision=6483]]
if (_loaded.render) return _loaded.render

local pi = math.pi
local tan = math.tan
local atan = math.atan

local utils = include "utils.lua"
local remap = utils.remap
local ilerp = utils.ilerp
local lerp = utils.lerp
local log = utils.log
local xy = utils.xy
local xz = utils.xz
local uv = utils.uv

local render = {
	fov = 90,
	pos = userdata("f64", 3, 4),
	cam = userdata("f64", 3, 4), -- camera space transform
	view = userdata("f64", 2, 3), -- viewport space transform
	basis = userdata("f64", 2, 2), -- top-down basis matrix
	model = userdata("f64", 3, 4), -- model transform matrix
	size = {
		 w = 0,  h = 0,
		wx = 0, wh = 0,
	},
	near = 1 / (1 << 8), -- near plane
	bcull = true, -- whether to cull backfaces
}

-- init to identity
render.pos:set(0, 0,
	1, 0, 0,
	0, 1, 0,
	0, 0, 1,
	0, 0, 0
)

-- init to identity
render.model:set(0, 0,
	1, 0, 0,
	0, 1, 0,
	0, 0, 1,
	0, 0, 0
)

local flipy = vec(1, -1) -- to flip floor & ceiling UVs

-- to rotate 2D vectors by 90 degrees
local rot90 = userdata("f64", 2, 3)
rot90:set(0, 0,
	 0, 1,
	-1, 0,
	 0, 0
)

-- get the winding order of the given vertices
local function getwind(p1, p2, p3)
	p1, p2, p3 = p1:take(xy), p2:take(xy), p3:take(xy)
	local normal = (p2 - p1):matmul2d(rot90, true)
	return -normal:dot(p3 - p1)
end

-- set the size of the render target
function render:setsize(w, h)
	local size = self.size
	local wx, hx = w / 2, h / 2
	-- store size & extents
	size.w, size.h = w, h
	size.wx, size.hx = wx, hx
	-- update viewport transform
	self.view:set(0, 0,
		hx, 0,
		0, -hx,
		wx, hx
	)
end

-- set the render camera state
function render:setcam(pos, angle, fov)
	-- unpack position vector
	local x, y, z = -pos.x, -pos.y, -pos.z
	-- store FOV
	self.fov = fov
	-- scale based on angle of FOV
	local s = 1 / tan(fov * pi / 360)
	-- update camera transform
	self.cam:set(0, 0,
		cos(angle) * s, 0, -sin(angle),
		0, s, 0,
		sin(angle) * s, 0, cos(angle),
		0, 0, 0
	)
	self.pos:set(0, 3,
		x, y, z
	)
	self.pos:matmul3d(self.cam, self.cam)
	-- update top-down basis matrix
	render.basis:set(0, 0,
		 cos(angle), sin(angle),
		-sin(angle), cos(angle)
	)
end

-- set the model transform matrix
function render:setmodel(...)
	self.model:set(0, 0, ...)
end

-- transform a vertex through camera space to viewport space
function render:transform(vert)
	return vert:matmul3d(self.cam, true)
		:div(vert.z, true, 0, 0, 2)
		:matmul2d(self.view, true)
end

-- transform a vertex to camera space
function render:transcam(vert)
	return vert:matmul3d(self.cam, true)
end

-- transform a vertex to viewport space
function render:transview(vert)
	return vert:div(vert.z, true, 0, 0, 2)
		:matmul2d(self.view, true)
end

-- transform a vertex by the model matrix
function render:transmodel(vert)
	return vert:matmul3d(self.model, true)
end

-- draw a dot in 3D space
function render:dot3d(pos, c)
	-- transform to camera, then viewport space
	pos = self:transform(pos:copy())
	local x, y, z = pos:get(0, 3)
	-- cull dots behind camera
	if (z <= self.near) return
	-- draw 3d dot
	pset(x, y, c)
end

-- draw a bar in 3D space
function render:bar3d(pos, h, c)
	-- transform to camera space
	pos = self:transform(pos:copy())
	local x, y, z = pos:get(0, 3)
	-- cull bars behind camera
	if (z <= 0) return
	-- transform height
	local scale = 1 / tan(self.fov * pi / 360)
	h *= (1 / z) * self.size.hx * scale
	-- draw 3d bar
	rect(x, y - h, x, y - 1, c)
end

-- draw triangle from vertices already in viewport space
function render:viewtri3d(p1, p2, p3, s)
	-- cull points outside viewport
	if (max(max(p1.x, p2.x), p3.x) < 0) return
	if (min(min(p1.x, p2.x), p3.x) >= self.size.w) return
	-- sort horizontally
	if (p3.x < p2.x) p2, p3 = p3, p2
	if (p2.x < p1.x) p1, p2 = p2, p1
	if (p3.x < p2.x) p2, p3 = p3, p2
	-- find midpoint
	local n1 = ilerp(p2.x, p1.x, p3.x)
	local m1 = lerp(p1, p3, n1) m1.x = p2.x
	-- find trapezoid dimensions
	local x1, x2, x3 = p1.x\1, p2.x\1, p3.x\1
	local i1, i2, i3 = 0, x2 - x1, x3 - x1
	local y1, y2 = p1.y, p1.y
	local y3, y4 = p2.y, m1.y
	local y5, y6 = p3.y, p3.y
	local uv1, uv2 = p1:take(uv), p1:take(uv)
	local uv3, uv4 = p2:take(uv), m1:take(uv)
	local uv5, uv6 = p3:take(uv), p3:take(uv)
	local w1, w2 = 1/p1.z, 1/p1.z
	local w3, w4 = 1/p2.z, lerp(1/p1.z, 1/p3.z, n1)
	local w5, w6 = 1/p3.z, 1/p3.z
	-- clip left trapezoid edge
	local left = 0
	if x2 < left then
		n = ilerp(left, x2, x3)
		x1, x2 = left, left
		i1, i2, i3 = 0, x2 - x1, x3 - x1
		y3, y4 = lerp(y3, y5, n), lerp(y4, y6, n)
		uv3, uv4 = lerp(uv3, uv5, n), lerp(uv4, uv6, n)
		w3, w4 = lerp(w3, w5, n), lerp(w4, w6, n)
		-- cancel out left half
		y1, y2 = y3, y4
		uv1, uv2 = uv3, uv4
		w1, w2 = w3, w4
	elseif x1 < left then
		n = ilerp(left, x1, x2)
		x1 = left  i1, i2, i3 = 0, x2 - x1, x3 - x1
		y1, y2 = lerp(y1, y3, n), lerp(y2, y4, n)
		uv1, uv2 = lerp(uv1, uv3, n), lerp(uv2, uv4, n)
		w1, w2 = lerp(w1, w3, n), lerp(w2, w4, n)
	end
	-- clip right trapezoid edge
	local right = self.size.w
	if x2 >= right then
		n = ilerp(right, x2, x1)
		x3, x2 = right, right
		i1, i2, i3 = 0, x2 - x1, x3 - x1
		y3, y4 = lerp(y3, y1, n), lerp(y4, y2, n)
		uv3, uv4 = lerp(uv3, uv1, n), lerp(uv4, uv2, n)
		w3, w4 = lerp(w3, w1, n), lerp(w4, w2, n)
		-- cancel out right half
		y5, y6 = y3, y4
		uv5, uv6 = uv3, uv4
		w5, w6 = w3, w4
	elseif x3 >= right then
		n = ilerp(right, x3, x2)
		x3 = right  i1, i2, i3 = 0, x2 - x1, x3 - x1
		y5, y6 = lerp(y5, y3, n), lerp(y6, y4, n)
		uv5, uv6 = lerp(uv5, uv3, n), lerp(uv6, uv4, n)
		w5, w6 = lerp(w5, w3, n), lerp(w6, w4, n)
	end
	-- batch arguments
	local length = i3 - i1 + 1
	if length <= self.size.w + 1 then
		local args = userdata("f64", 12, length)
		args:set(0, i1,  s, x1, y1 + 0.001, x1, y2 + 0.001,  uv1.x, uv1.y, uv2.x, uv2.y, w1, w2,  0x300)
		args:set(0, i3,  s, x3, y5 + 0.001, x3, y6 + 0.001,  uv5.x, uv5.y, uv6.x, uv6.y, w5, w6,  0x300)
		args:set(0, i2,  s, x2, y3 + 0.001, x2, y4 + 0.001,  uv3.x, uv3.y, uv4.x, uv4.y, w3, w4,  0x300)
		args:lerp(i1 * 12, i2 - i1, 12,  12, 1)
		args:lerp(i2 * 12, i3 - i2, 12,  12, 1)
		tline3d(args, i1 * 12, length - 1)
	else
		log(length..": "..x1..", "..x2..", "..x3)
	end
end

--[[
	Draw a triangle composed of the given vertices and faces.
	 p1, p2, p3 - Three [xyz uv] vectors forming a triangle.
	 s - The sprite index to use as a texture.
--]]
function render:tri3d(p1, p2, p3, s)
	-- transform to camera space
	self:transcam(p1)
	self:transcam(p2)
	self:transcam(p3)
	-- find clipped vertices
	local clipped = {}
	if (p1.z < self.near) add(clipped, 1)
	if (p2.z < self.near) add(clipped, 2)
	if (p3.z < self.near) add(clipped, 3)
	-- all vertices in front
	if #clipped == 0 then
		-- transform to viewport space
		self:transview(p1)
		self:transview(p2)
		self:transview(p3)
		-- cull backward faces
		if not self.bcull or getwind(p1, p2, p3) > 0 then
			-- convert UVs to 1/z space
			p1:div(p1.z, true, 3, 3, 2)
			p2:div(p2.z, true, 3, 3, 2)
			p3:div(p3.z, true, 3, 3, 2)
			-- draw triangle
			self:viewtri3d(p1, p2, p3, s)
		end
	-- one vertex behind
	elseif #clipped == 1 then
		-- find index of clipped vertex
		local clippedi = clipped[1]
		-- cache old order of vertices
		local old1, old2, old3 = p1, p2, p3
		-- determine which vertices are where
		local p4 = nil
		if clippedi == 1 then
			local old = p1
			p3, p4 = p2, p3
			local n1 = ilerp(self.near, old.z, p3.z)
			local n2 = ilerp(self.near, old.z, p4.z)
			p1, p2 = lerp(old, p3, n1), lerp(old, p4, n2)
		elseif clippedi == 2 then
			local old = p2
			p1, p4 = p1, p3
			local n1 = ilerp(self.near, old.z, p1.z)
			local n2 = ilerp(self.near, old.z, p4.z)
			p2, p3 = lerp(old, p1, n1), lerp(old, p4, n2)
		elseif clippedi == 3 then
			local old = p3
			--p1, p2 = p1, p2
			local n1 = ilerp(self.near, old.z, p1.z)
			local n2 = ilerp(self.near, old.z, p2.z)
			p3, p4 = lerp(old, p1, n1), lerp(old, p2, n2)
		end
		-- transform to viewport space
		self:transview(p1)
		self:transview(p2)
		self:transview(p3)
		self:transview(p4)
		-- convert UVs to 1/z space
		p1:div(p1.z, true, 3, 3, 2)
		p2:div(p2.z, true, 3, 3, 2)
		p3:div(p3.z, true, 3, 3, 2)
		p4:div(p4.z, true, 3, 3, 2)
		-- draw triangles
		if clippedi == 1 then
			if not self.bcull or getwind(p1, p3, p4) > 1 then
				self:viewtri3d(p1, p3, p4, s)
				self:viewtri3d(p4, p1, p2, s)
			end
		elseif clippedi == 2 then
			if not self.bcull or getwind(p1, p2, p3) > 1 then
				self:viewtri3d(p1, p2, p3, s)
				self:viewtri3d(p3, p4, p1, s)
			end
		elseif clippedi == 3 then
			if not self.bcull or getwind(p4, p1, p2) > 1 then
				self:viewtri3d(p1, p3, p4, s)
				self:viewtri3d(p4, p1, p2, s)
			end
		end
	-- two vertices behind
	elseif #clipped == 2 then
		-- determine which vertices are where
		if clipped[1] == 1 and clipped[2] == 2 then
			local n1 = ilerp(self.near, p1.z, p3.z)
			local n2 = ilerp(self.near, p2.z, p3.z)
			p1 = lerp(p1, p3, n1)
			p2 = lerp(p2, p3, n2)
		elseif clipped[1] == 1 and clipped[2] == 3 then
			local n1 = ilerp(self.near, p1.z, p2.z)
			local n2 = ilerp(self.near, p3.z, p2.z)
			p1 = lerp(p1, p2, n1)
			p3 = lerp(p3, p2, n2)
		elseif clipped[1] == 2 and clipped[2] == 3 then
			local n1 = ilerp(self.near, p2.z, p1.z)
			local n2 = ilerp(self.near, p3.z, p1.z)
			p2 = lerp(p2, p1, n1)
			p3 = lerp(p3, p1, n2)
		end
		-- transform to viewport space
		self:transview(p1)
		self:transview(p2)
		self:transview(p3)
		-- convert UVs to 1/z space
		p1:div(p1.z, true, 3, 3, 2)
		p2:div(p2.z, true, 3, 3, 2)
		p3:div(p3.z, true, 3, 3, 2)
		-- cull backward faces
		if not self.bcull or getwind(p1, p2, p3) > 0 then
			self:viewtri3d(p1, p2, p3, s)
		end
	end
end

--[[
	Draw a model composed of the given vertices and indices.
	 verts - Table of vertices used by the faces table.
	 faces - Table of groups of 3 indices to draw faces.
	 s - Sprite index to use for the whole model.
--]]
function render:model3d(verts, faces, s)
	assert(#faces % 3 == 0, "length of faces array must be multiple of 3")
	-- iterate over faces & draw them
	for i = 1, #faces, 3 do
		-- find vertices by face index
		local i1, i2, i3 = faces[i], faces[i+1], faces[i+2]
		local p1 = self:transmodel(verts[i1]:copy())
		local p2 = self:transmodel(verts[i2]:copy())
		local p3 = self:transmodel(verts[i3]:copy())
		self:tri3d(p1, p2, p3, s)
	end
end

-- draw a wall in 3D space
function render:wall3d(pos1, pos2, ws, fs, cs)
	local size = render.size
	-- get floor & ceiling height
	local floor, ceiling = pos1.y, pos2.y
	-- get texture coords for floor & ceiling
	local tc1 = pos1:take(xz):mul(flipy, true)
	local tc2 = pos2:take(xz):mul(flipy, true)
	-- transform to camera space
	pos1 = self:transcam(pos1:copy())
	pos2 = self:transcam(pos2:copy())
	local u1, u2 = pos1.u, pos2.u
	local z1, z2 = pos1.z, pos2.z
	-- get camera space metrics
	local y = pos1.y
	local h = pos2.y - y
	-- cull walls behind camera
	if (max(z1, z2) <= self.near) return
	-- clip either point if behind camera
	if z1 <= self.near then
		local t = remap(self.near, z1, z2)
		pos1 = lerp(pos1, pos2, t)
		tc1 = lerp(tc1, tc2, t)
		u1 = lerp(u1, u2, t)
		z1 = self.near
	elseif z2 <= self.near then
		local t = remap(self.near, z1, z2)
		pos2 = lerp(pos1, pos2, t)
		tc2 = lerp(tc1, tc2, t)
		u2 = lerp(u1, u2, t)
		z2 = self.near
	end
	-- find inverse of distance
	local w1, w2 = 1 / z1, 1 / z2
	-- transform to viewport space
	self:transview(pos1)
	self:transview(pos2)
	-- prepare for clipping
	local x1, x2 = pos1.x, pos2.x
	-- clip left edge of screen
	if x1 < 0 then
		local n = remap(0, x1, x2)
		local w = lerp(w1, w2, n)
		pos1 = lerp(pos1 * w1, pos2 * w2, n) / w
		tc1 = lerp(tc1 * w1, tc2 * w2, n) / w
		u1 = lerp(u1 * w1, u2 * w2, n) / w
		z1 = lerp(z1 * w1, z2 * w2, n) / w
		w1 = w  x1 = 0
	end
	-- clip right edge of screen
	if x2 >= self.size.w then
		local n = remap(self.size.w, x1, x2)
		local w = lerp(w1, w2, n)
		pos2 = lerp(pos1 * w1, pos2 * w2, n) / w
		tc2 = lerp(tc1 * w1, tc2 * w2, n) / w
		u2 = lerp(u1 * w1, u2 * w2, n) / w
		z2 = lerp(z1 * w1, z2 * w2, n) / w
		w2 = w  x2 = self.size.w
	end
	-- find heights
	local p1, p2 = w1 * size.hx, w2 * size.hx
	local y1, y2 = size.hx - y * p1, size.hx - y * p2
	local h1, h2 = h * p1, h * p2
	-- convert texture coords to 1/z space
	u1, u2 = u1 * w1, u2 * w2
	-- draw each line of the wall
	local xlo, xhi = x1 // 1, x2 // 1
	local pxlo, pxhi = max(0, xlo), min(size.w, xhi) - 1
	local len = pxhi - pxlo
	-- cull invisible walls
	if (len <= 0) return
	-- create batch arguments
	local args = userdata("f64", 12, len + 1)
	-- draw wall
	do
		-- find texture dimensions
		local tw, th = get_spr(ws):attribs()
		-- set arguments
		args:set(
			0, 0, ws,
			pxlo, y1 - h1 + 0.001, pxlo, y1 + 0.001,
			u1 * tw, 0, u1 * tw, (ceiling - floor) * w1 * th,
			w1, w1, 0x300
		)
		args:set(
			0, len, ws,
			pxhi, y2 - h2 + 0.001, pxhi, y2 + 0.001,
			u2 * tw, 0, u2 * tw, (ceiling - floor) * w2 * th,
			w2, w2, 0x300
		)
		-- interpolate arguments
		args:lerp(0, len, 12,  12, 1)
		-- draw wall batch
		tline3d(args)
	end
	-- draw planes
	local scale = 1 / tan(render.fov * pi / 360)
	local tanlo = tan(atan(pxlo - size.wx + 0.5, size.hx))
	local tanhi = tan(atan(pxhi - size.wx + 0.5, size.hx))
	local camx, camy, camz = render.pos:get(0, 3, 3)
	local camtd = vec(-camx, -camz)
	-- draw floor
	do
		-- find texture dimensions
		local tw, th = get_spr(fs):attribs()
		local tsize = vec(tw, th)
		-- find distance to floor & w
		local dist = abs(floor + camy)
		local w = 1 / dist / scale
		-- find texture coordinates
		local tc1, tc2 = tc1 * w1 * tsize, tc2 * w2 * tsize
		local uv1 = vec(tanlo * dist, dist * scale)
			uv1:matmul(render.basis, true)
			uv1:add(camtd, true)
			uv1:mul(flipy * tsize * w, true)
		local uv2 = vec(tanhi * dist, dist * scale)
			uv2:matmul(render.basis, true)
			uv2:add(camtd, true)
			uv2:mul(flipy * tsize * w, true)
		-- set arguments
		args:set(
			0, 0, fs,
			pxlo, y1, pxlo, render.size.h,
			tc1.x, tc1.y, uv1.x, uv1.y,
			w1, w, 0x300
		)
		args:set(
			0, len, fs,
			pxhi, y2, pxhi, render.size.h,
			tc2.x, tc2.y, uv2.x, uv2.y,
			w2, w, 0x300
		)
		-- interpolate arguments
		args:lerp(0, len, 12,  12, 1)
		-- draw floor batch
		tline3d(args)
	end
	-- draw ceiling
	do
		-- find texture dimensions
		local tw, th = get_spr(cs):attribs()
		local tsize = vec(tw, th)
		-- find distance to ceiling & w
		local dist = abs(ceiling + camy)
		local w = 1 / dist / scale
		-- find texture coordinates
		local tc1, tc2 = tc1 * w1 * tsize, tc2 * w2 * tsize
		local uv1 = vec(tanlo * dist, dist * scale)
			uv1:matmul(render.basis, true)
			uv1:add(camtd, true)
			uv1:mul(flipy * tsize * w, true)
		local uv2 = vec(tanhi * dist, dist * scale)
			uv2:matmul(render.basis, true)
			uv2:add(camtd, true)
			uv2:mul(flipy * tsize * w, true)
		-- set arguments
		args:set(
			0, 0, cs,
			pxlo, 0, pxlo, y1 - h1,
			uv1.x, uv1.y, tc1.x, tc1.y,
			w, w1, 0x300
		)
		args:set(
			0, len, cs,
			pxhi, 0, pxhi, y2 - h2,
			uv2.x, uv2.y, tc2.x, tc2.y,
			w, w2, 0x300
		)
		-- interpolate arguments
		args:lerp(0, len, 12,  12, 1)
		-- draw ceiling batch
		tline3d(args)
	end
end

_loaded.render = render
return render