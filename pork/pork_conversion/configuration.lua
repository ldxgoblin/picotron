--[[pod_format="raw",created="2024-09-08 09:49:19",modified="2025-03-07 13:16:06",revision=6]]
--[[
	configuration.lua - configuration settings for the program
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

configuration = {
	-- If true, logging will be initialized and messages will be sent to the "logview" process
	log = {
		-- If true, logging will be enabled
		enabled = true,
		-- The logging level to use
		level = "DEBUG"
	}
}

configuration.data = {
	dpal      = "0,1,1,2,1,13,6,4,4,9,3,13,1,13,14",
	dirx      = "-1,1,0,0,1,1,-1,-1",
	diry      = "0,0,-1,1,-1,1,1,-1",

	itm_name  = "butter knife,cheese knife,paring knife,utility knife,chef's knife,meat cleaver,paper apron,cotton apron,rubber apron,leather apron,chef's apron,butcher's apron,food 1,food 2,food 3,food 4,food 5,food 6,spork,salad fork,fish fork,dinner fork",
	itm_type  = "wep,wep,wep,wep,wep,wep,arm,arm,arm,arm,arm,arm,fud,fud,fud,fud,fud,fud,thr,thr,thr,thr",
	itm_stat1 = "1,2,3,4,5,6,0,0,0,0,1,2,1,2,3,4,5,6,1,2,3,4",
	itm_stat2 = "0,0,0,0,0,0,1,2,3,4,3,3,0,0,0,0,0,0,0,0,0,0",
	itm_minf  = "1,2,3,4,5,6,1,2,3,4,5,6,1,1,1,1,1,1,1,2,3,4",
	itm_maxf  = "3,4,5,6,7,8,3,4,5,6,7,8,8,8,8,8,8,8,4,6,7,8",
	itm_desc  = ",,,,,,,,,,,, heals, heals a lot, increases hp, stuns, is cursed, is blessed,,,,",

	mob_name = "player,slime,melt,shoggoth,mantis-man,giant scorpion,ghost,golem,drake",
	mob_ani  = "240,192,196,200,204,208,212,216,220",
	mob_atk  = "1,1,2,1,2,3,3,5,5",
	mob_hp   = "5,1,2,3,3,4,5,14,8",
	mob_los  = "4,4,4,4,4,4,4,4,4",
	mob_minf = "0,1,2,3,4,5,6,7,8",
	mob_maxf = "0,3,4,5,6,7,8,8,8",
	mob_spec = ",,,spawn?,fast?,stun,ghost,slow,",

	crv_sig  = "255,214,124,179,233",
	crv_msk  = "0,9,3,12,6",

	free_sig = "0,0,0,0,16,64,32,128,161,104,84,146",
	free_msk = "8,4,2,1,6,12,9,3,10,5,10,5",

	wall_sig = "251,233,253,84,146,80,16,144,112,208,241,248,210,177,225,120,179,0,124,104,161,64,240,128,224,176,242,244,116,232,178,212,247,214,254,192,48,96,32,160,245,250,243,249,246,252",
	wall_msk = "0,6,0,11,13,11,15,13,3,9,0,0,9,12,6,3,12,15,3,7,14,15,0,15,6,12,0,0,3,6,12,9,0,9,0,15,15,7,15,14,0,0,0,0,0,0",
}
