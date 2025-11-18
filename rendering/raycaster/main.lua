--[[pod_format="raw",created="2025-01-07 23:51:35",modified="2025-01-09 03:23:21",revision=445]]
-- Simple raycaster in picotron
-- @eigenbom 2025

-- DEV-MODE
-- cd("/w3d")
-- include("src/main.lua")

local math_floor = math.floor
local math_sqrt = math.sqrt
local math_abs = math.abs
local math_sin = math.sin
local math_cos = math.cos
local math_atan = math.atan
local math_pi = math.pi
local math_huge = math.huge

local MAP_WIDTH, MAP_HEIGHT = 32, 32
local MAP_WIDTH_DIV_2, MAP_HEIGHT_DIV_2 = MAP_WIDTH // 2, MAP_HEIGHT // 2
local MAP

local WALL_RED = 1
local WALL_GREEN = 2
local WALL_BLUE = 3
local WALL_WHITE = 4

local WIDTH, HEIGHT = 480, 270
local WIDTH_DIV_2, HEIGHT_DIV_2 = WIDTH // 2, HEIGHT // 2

local RAY_PIXEL_SIZE = 2
local RAY_PIXEL_SIZE_DIV_2 = RAY_PIXEL_SIZE // 2
local RAY_WIDTH, RAY_HEIGHT = WIDTH // RAY_PIXEL_SIZE, HEIGHT // RAY_PIXEL_SIZE
local RAY_WIDTH_DIV_2, RAY_HEIGHT_DIV_2 = RAY_WIDTH // 2, RAY_HEIGHT // 2

---2D array of vertical columns with (wall height, color, texcoord)
---@type userdata
local columns

---@param x number
---@param y number
local function length(x, y)
	return math_sqrt(x * x + y * y)
end

local function update_player_vectors(player)
	local s = math_sin(player.angle)
	local c = math_cos(player.angle)
	player.face_x, player.face_y = c, s
	player.left_x, player.left_y = -s, c
end

-- Store player info
local player

function _init()
	player = { x = 0, y = 0, angle = math_pi/2 }
	update_player_vectors(player)

	-- columns to store the raycast results
	columns = userdata("f64", RAY_WIDTH, 3)

	-- Create [y][x] indexable map, centered at (0,0)
	MAP = {}
	for i=1, MAP_HEIGHT do
		local y = i - 1 - MAP_HEIGHT_DIV_2
		local row = {}
		for j=1, MAP_WIDTH do
			local t = mget(j-1,i-1)
			local x = MAP_WIDTH_DIV_2 - j
			if t == 1 then
				row[x] = WALL_WHITE
			elseif t == 2 then
				row[x] = WALL_BLUE
			elseif t == 3 then
				row[x] = WALL_RED
			elseif t == 4 then
				row[x] = WALL_GREEN
			end
		end
		MAP[y] = row
	end
end

local function get_wall(x, y)
	local row = MAP[y]
	return row and row[x]
end

local function get_nearby_wall(x, y, radius, step)
	for i=-radius,radius,step do
		for j=-radius,radius,step do
			local xi, yj = math_floor(x + i), math_floor(y + j)
			local wall = get_wall(xi, yj)
			if wall then
				return wall
			end
		end
	end
end

---@return integer, number, number, number, number
---@overload fun(x0: number, y0: number, x1: number, y1: number): nil
local function raytrace(x0, y0, x1, y1)
	local dx = math_abs(x1 - x0)
	local dy = math_abs(y1 - y0)

	local x = math_floor(x0)
	local y = math_floor(y0)

	local dt_dx = 1.0 / dx
	local dt_dy = 1.0 / dy

	local t = 0

	local n = 1
	local x_inc, y_inc
	local t_next_vertical, t_next_horizontal

	if dx == 0 then
		x_inc = 0
		t_next_horizontal = dt_dx
	elseif x1 > x0 then
		x_inc = 1
		n = n + math_floor(x1) - x
		t_next_horizontal = (x + 1 - x0) * dt_dx
	else
		x_inc = -1
		n = n + x - math_floor(x1)
		t_next_horizontal = (x0 - x) * dt_dx
	end

	if dy == 0 then
		y_inc = 0
		t_next_vertical = dt_dy
	elseif y1 > y0 then
		y_inc = 1
		n = n + math_floor(y1) - y
		t_next_vertical = (y + 1 - y0) * dt_dy
	else
		y_inc = -1
		n = n + y - math_floor(y1)
		t_next_vertical = (y0 - y) * dt_dy
	end

	for _ = 1, n do
		local wall = get_wall(x, y)
		if wall then
			local rxi = (x_inc > 0) and 1 or -1
			local ryi = (y_inc > 0) and 1 or -1
			local rx = x0 + rxi * t / dt_dx
			local ry = y0 + ryi * t / dt_dy
			return wall, rx, ry, rxi, ryi
		end

		if t_next_vertical < t_next_horizontal then
			y = y + y_inc
			t = t_next_vertical
			t_next_vertical = t_next_vertical + dt_dy
		else
			x = x + x_inc
			t = t_next_horizontal
			t_next_horizontal = t_next_horizontal + dt_dx
		end
	end
end


local function trace_columns(camera, columns)
	local CAMERA_PLANE_DIST = 0.75
	local CAMERA_PLANE_WIDTH = 1.5
	local CAMERA_PLANE_WIDTH_MULT = CAMERA_PLANE_WIDTH / RAY_WIDTH
	local RAYCAST_DIST = 20
	local camera_x, camera_y = camera.x, camera.y
	local camera_left_x, camera_left_y = camera.left_x, camera.left_y
	local camera_fx, camera_fy = camera.face_x * CAMERA_PLANE_DIST, camera.face_y * CAMERA_PLANE_DIST
	local camera_angle = camera.angle
	local wall_height_num = 1.5 * (RAY_HEIGHT * CAMERA_PLANE_DIST) * RAY_PIXEL_SIZE_DIV_2

	for i=0,RAY_WIDTH-1 do
		local x = i + RAY_PIXEL_SIZE_DIV_2
		local camera_plane_left = (RAY_WIDTH_DIV_2 - x) * CAMERA_PLANE_WIDTH_MULT
		local camera_pixel_x = camera_fx + camera_left_x * camera_plane_left
		local camera_pixel_y = camera_fy + camera_left_y * camera_plane_left
		local ox, oy = camera_x + camera_pixel_x, camera_y + camera_pixel_y
		local ray_length = length(camera_pixel_x, camera_pixel_y)
		local ray_x, ray_y = camera_pixel_x / ray_length, camera_pixel_y / ray_length
		local wall, rx, ry, rxi, ryi = raytrace(ox, oy, ox + ray_x * RAYCAST_DIST, oy + ray_y * RAYCAST_DIST)
		if wall then
			local ray_angle = math_atan(ray_y, ray_x)
			local dist = length(rx - ox, ry - oy) * math_cos(ray_angle - camera_angle)
			local wall_height = wall_height_num / (CAMERA_PLANE_DIST + dist)
			local rdx, rdy = rx - math_floor(rx), ry - math_floor(ry)
			local uv = (abs(rdx)<0.001 or abs(rdx-1)<0.001) and rdy or rdx
			columns:set(i, 0, wall_height)
			columns:set(i, 1, wall)
			columns:set(i, 2, uv)
		else
			columns:set(i, 0, 0)
		end
	end
end

function _update()
	local rotate_speed = 0.04
	if btn(0) then
		player.angle = player.angle + rotate_speed
	elseif btn(1) then
		player.angle = player.angle - rotate_speed
	end
	update_player_vectors(player)

	local speed = btn(5) and 0.12 or 0.06 -- 'x' to run
	local move_forward = btn(2)
	local move_backward = btn(3)

	if move_forward or move_backward then
		local dir_x, dir_y
		if move_forward then
			dir_x = player.face_x * speed
			dir_y = player.face_y * speed
		elseif move_backward then
			dir_x = -player.face_x * speed
			dir_y = -player.face_y * speed
		end

		-- find a suitable position to move to
		local new_x, new_y = player.x + dir_x, player.y + dir_y
		if not get_nearby_wall(new_x, new_y, .2, .05) then
			player.x, player.y = new_x, new_y
		end
	end
end

function _draw()
	cls(28)
	rectfill(0, HEIGHT/2, WIDTH, HEIGHT, 22)

	-- Draw the columns
	trace_columns(player, columns)
	local wall_sprites = { get_spr(16), get_spr(17), get_spr(18), get_spr(19) }
	for i = 0, RAY_WIDTH - 1 do
		local hwh = columns:get(i, 0)
		if hwh ~= 0 then
			local x = RAY_PIXEL_SIZE * i
			local wall = columns:get(i, 1)
			local uv = columns:get(i, 2)
			local y0 = HEIGHT_DIV_2 - hwh
			local spr = wall_sprites[wall]
			local sx = math_floor(uv*15.99)
			fillp(0b1010010110100101)
			sspr(spr, sx, 0, 1, 16, x, HEIGHT_DIV_2 + hwh, RAY_PIXEL_SIZE, 2*hwh, false, true)
			fillp()
			sspr(spr, sx, 0, 1, 16, x, y0, RAY_PIXEL_SIZE, hwh*2 + 1)
		end
	end
end
