--[[pod_format="raw",author="bugbard",created="2025-04-28 01:05:23",icon=userdata("u8",16,16,"00010101010101010101010000000000000107070707070707070601000000000001070707070d0d0d07060601000000000107070d070d070d070606060100000001070707070d0d0d07060606060100000107070707070707070707070701000001070707070707070707070707010000010707070707070707070707070100000107070707070707070707070701000001070d0d0d0d0d0d070d070707010000010707070707070707070707070100000107070d0d0d0d0d0d070d070701000001070707070707070707070707010000010707070d0d0d0d0d0d070d0701000001070707070707070707070707010000010101010101010101010101010100"),lowcol_icon=true,modified="2025-07-07 23:45:45",notes="a little library to help you create\nmenus for your games!\n\nsupports submenus, too",revision=615,title="menu.lua",version="v0.1"]]
--[[
	try including this file, and make a new menu like so:
		menu = include "menu.lua"
		
		your_menu = menu.new{}
		
	then, put it in your update loop
		function _update()
			your_menu:update()
		end
		
		function _draw()
			your_menu:draw()
		end
--]]

local menu = {
	root = {
		--[[
			root contains the contents of your menu
			
			each menu entry is an object with a label and a content
			{label = "text of your choice", content =
				{table}     : treat this option like a submenu
				function () : executes this function when selected
				"back"      : exits this submenu when selected
				nil         : cannot be selected. good for putting separators in menus
			}
		]]
		{label="\fa-- menu"},
		{label="submenu",content={
			{label = "go back", content = "back"}
		}},
		{label="exit", content = function () exit() end}
	},
	wrap    = false, -- if true, selection wraps between top and bottom of menu
	
	path    = {},  -- keeps track of where you are when you enter and exit submenus
	current = {},   -- your currently-selected menu
	select  = 1,   -- initial position of selection when this menu is opened
	
}

menu.__index = menu

function menu.new(m)
	setmetatable(m, menu)
	
	m.current = m.root
	m:skip_labels()
	return m
end

function menu.update(self)
	-- move selection
		-- get move intent
		local move = 0
		if keyp("down") then move += 1 end
		if keyp("up")   then move -= 1 end
		
		-- then, move
			if move != 0 then
				repeat
					self.select += move
					-- correct selection position to be within current menu's bounds
					if self.wrap then
						self.select = (self.select - 1) % #self.current + 1
					else
						if self.select == 0 or self.select == #self.current then
							move *= -1
						end
						self.select = mid(1,self.select,#self.current)
					end
				until self.current[self.select].content != nil
			end

	-- activate selection
		local content = self.current[self.select].content
		
		if keyp("z") then
			self:exit_submenu()
		end
		if keyp("x") then
			if     type(content) == "function" then content()
			elseif type(content) == "table"    then self:enter_submenu(content)
			elseif content       == "back"     then self:exit_submenu() end
		end
end

function menu.draw(self)
	for i, v in ipairs(self.current) do
		if i == self.select then	
			?"\#7\f0> "..v.label
		else
			?"\f7"..v.label
		end
	end
end

function menu.enter_submenu(self,menu)
	add(self.path,self.select)
	self.select = 1
	self.current = menu
	
	self:skip_labels()
end

function menu.exit_submenu(self)
	if self.current != self.root then
		self.select = self.path[#self.path]
		deli(self.path,#self.path)
		local menu = self.root
		
		for sel in all(self.path) do
			menu = menu[sel].content
		end
		
		self.current = menu
	else
		-- you cannot exit submenu if you're at the root
		return false
	end
end

function menu.skip_labels(self)
	while self.current[self.select].content == nil do
		self.select += 1
	end
end

return menu