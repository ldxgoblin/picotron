--[[pod_format="raw",created="2024-09-08 09:49:37",modified="2025-03-07 13:16:47",revision=5]]
--[[
	globals.lua - global utility functions
	(c) 2025 Andrew Vasilyev. All rights reserved.

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <https://www.gnu.org/licenses/>.
]]

local wm_pid = 3 -- Process ID of Picotron's window manager and info bar

-- screen and world sizing
SCREEN_W, SCREEN_H = 480, 270
MAP_W, MAP_H       = 16, 16 -- logical dungeon size in tiles (must match current map resource)
SHOW_FOG           = true   -- debug flag to toggle fog rendering

-- global tile sizing (src tiles are 8x8, drawn as 32x32 on screen by default)
TILE_SRC_SIZE = 8
TILE_SIZE     = 32

-- Reports a fatal error, logs the message and traceback, and exits the program.
-- @param message: The format string for the error message
-- @param exit_code: Optional custom exit code (default is 1)
-- @param ...: Additional arguments to format the message
function wtf(message, exit_code, ...)
	local error_report = debug.traceback(string.format(message, ...), 2)

	send_message(wm_pid, { event = "report_error", content = "*wtf?!" })
	send_message(wm_pid, { event = "report_error", content = error_report })

	exit(exit_code or 1)
end

-- Retrieves the process ID (PID) by process name.
-- @param name: The name of the process to search for.
-- @return: The process ID if found, or -1 if not found.
function get_pid_by_name(name)
	local processes = fetch("/ram/system/processes.pod")

	for i = 1, #processes do
		local process = processes[i]
		if (process.name == name) then
			-- Return the process ID if found
			return process.id
		end
	end

	return -1
end

function getframe(ani)
	return ani[flr(t/15)%#ani+1]
end

function drawspr(_spr,_x,_y,_c,_flip)
	palt(0,false)
	pal(6,_c)
	-- sspr can take a sprite index directly; sx,sy are inside that sprite
	sspr(_spr, 0, 0, TILE_SRC_SIZE, TILE_SRC_SIZE,
	     _x, _y, TILE_SIZE, TILE_SIZE, _flip, false)
	pal()
end

function rectfill2(_x,_y,_w,_h,_c)
	rectfill(_x,_y,_x+max(_w-1,0),_y+max(_h-1,0),_c)
end

function oprint8(_t,_x,_y,_c,_c2)
	for i=1,8 do
		print(_t,_x+dirx[i],_y+diry[i],_c2)
	end
	print(_t,_x,_y,_c)
end

function dist(fx,fy,tx,ty)
	local dx,dy=fx-tx,fy-ty
	return sqrt(dx*dx+dy*dy)
end

function dofade()
	local p,kmax,col,k=flr(mid(0,fadeperc,1)*100)
	for j=1,15 do
		col = j
		kmax=flr((p+j*1.46)/22)
		for k=1,kmax do
			col=dpal[col]
		end
		pal(j,col,1)
	end
end

function checkfade()
	if fadeperc>0 then
		fadeperc=max(fadeperc-0.04,0)
		dofade()
	end
end

function wait(_wait)
	repeat
		_wait-=1
		flip()
	until _wait<0
end

function fadeout(spd,_wait)
	if (spd==nil) spd=0.04
	if (_wait==nil) _wait=0
	repeat
		fadeperc=min(fadeperc+spd,1)
		dofade()
		flip()
	until fadeperc==1
	wait(_wait)
end

function blankmap(_dflt)
	local ret={}
	if (_dflt==nil) _dflt=0

	for x=0,MAP_W-1 do
		ret[x]={}
		for y=0,MAP_H-1 do
			ret[x][y]=_dflt
		end
	end
	return ret
end

function getrnd(arr)
	return arr[1+flr(rnd(#arr))]
end

function copymap(x,y)
	local tle
	for _x=0,15 do
		for _y=0,15 do
			the_tle=mget(_x+x,_y+y)
			mset(_x,_y,the_tle)
			if the_tle==15 then
				p_mob.x,p_mob.y=_x,_y
			end
		end
	end
end

function explode(s)
	local retval,lastpos={},1
	for i=1,#s do
		if sub(s,i,i)=="," then
			add(retval,sub(s, lastpos, i-1))
			i+=1
			lastpos=i
		end
	end
	add(retval,sub(s,lastpos,#s))
	return retval
end

function explodeval(_arr)
	return toval(explode(_arr))
end

function toval(_arr)
	local _retarr={}
	for _i in all(_arr) do
		add(_retarr,flr(tonum(_i)))
	end
	return _retarr
end

shake_x, shake_y = 0, 0

function doshake()
	if shake>0 then
		local sx,shy = 16-rnd(32),16-rnd(32)
		shake_x = sx*shake
		shake_y = shy*shake
		shake*=0.95
		if shake<0.05 then
			shake=0
			shake_x,shake_y = 0,0
		end
	else
		shake_x,shake_y = 0,0
	end
end
