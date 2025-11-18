--[[pod_format="raw",created="2024-09-08 09:50:07",modified="2025-03-07 13:16:33",revision=5]]
--[[
	main.lua - program entry point
]]

include("lib/require.lua")
include("lib/ui.lua")

add_module_path("lib/")
add_module_path("src/")

include("src/globals.lua")
include("src/configuration.lua")

local log = require("log")
local dungeon_factory = require("procgen.dungeon_factory")
local dungeon_map_renderer = require("render.dungeon_map_renderer")

-- simple UI button built on ConcreteViewClass
local ButtonClass = {}
ButtonClass.__index = ButtonClass
setmetatable(ButtonClass, { __index = ConcreteViewClass })

local SCREEN_W, SCREEN_H = 480, 270

local ui_state = {
	buttons = {},
	root = nil,
	root_position = { x = 258, y = 8 },
	mouse_down = false,
	status_text = Observable:new("Ready"),
	seed_text = Observable:new("-"),
	rooms_text = Observable:new("-"),
	objects_text = Observable:new("-"),
	log_status = Observable:new("log target: console (start logview manually)"),
	theme_text = Observable:new("random"),
	theme_names = {},
	theme_index = 1
}

local function register_button(button)
	table.insert(ui_state.buttons, button)
end

function ButtonClass:new(props)
	props = props or {}
	local label = props.text or props.label or "Button"
	local on_click = props.on_click
	props.on_click = nil
	props.padding_x = props.padding_x or 4
	props.padding_y = props.padding_y or 4
	props.background_color = props.background_color or 1
	props.border_color = props.border_color or 6
	props.color = props.color or 7
	local o = ConcreteViewClass:new(props)
	setmetatable(o, self)
	o._pressed = false
	o:bindProperty("text", label)
	o:bindProperty("color", props.color)
	o:on_click(on_click)
	register_button(o)
	o:update()
	return o
end

function ButtonClass:on_click(handler)
	self._click_handler = handler
end

function ButtonClass:update()
	local label = tostring(self.text or "")
	local label_width = #label * 5
	self._width = math.max(40, label_width + 10)
	self._height = 14
end

function ButtonClass:draw()
	local draw_fn = ConcreteViewClass.draw(self)
	return function(x, y)
		self._last_x = x
		self._last_y = y
		self._last_w = self:width()
		self._last_h = self:height()
		draw_fn(x, y)
	end
end

function ButtonClass:drawContent()
	return function(x, y)
		local label = tostring(self.text or "")
		local label_width = #label * 5
		local text_x = x + math.floor((self._width - label_width) / 2)
		local text_y = y + math.floor((self._height - 6) / 2)
		clip(x, y, x + self._width, y + self._height)
		print(label, text_x, text_y, self.color or 7)
		clip()
	end
end

function ButtonClass:hit_test(mx, my)
	if not self._last_x then return false end
	return mx >= self._last_x and mx <= self._last_x + self._last_w and my >= self._last_y and my <= self._last_y + self._last_h
end

function ButtonClass:trigger()
	if self._click_handler then
		self._click_handler()
	end
end

local function Button(props)
	return ButtonClass:new(props)
end

local function build_theme_list()
	local names = { "random" }
	for name in pairs(themes) do
		table.insert(names, name)
	end
	return names
end

local function set_theme_index(idx)
	if #ui_state.theme_names == 0 then return end
	if idx < 1 then idx = #ui_state.theme_names end
	if idx > #ui_state.theme_names then idx = 1 end
	ui_state.theme_index = idx
	ui_state.theme_text:set(ui_state.theme_names[idx])
end

local function cycle_theme()
	set_theme_index(ui_state.theme_index + 1)
end

local function current_theme_selection()
	local name = ui_state.theme_names[ui_state.theme_index]
	if name == "random" then return nil end
	return name
end

local function refresh_world_snapshot()
	local world = dungeon_factory.current()
	if world and world.gen_stats then
		local stats = world.gen_stats
		ui_state.seed_text:set(tostring(stats.seed or "-"))
		ui_state.rooms_text:set(tostring(stats.rooms or "-"))
		ui_state.objects_text:set(tostring(stats.objects or "-"))
	else
		ui_state.seed_text:set("-")
		ui_state.rooms_text:set("-")
		ui_state.objects_text:set("-")
	end
end

local function attempt_generate()
	ui_state.status_text:set("Generating...")
	local selected_theme = current_theme_selection()
	local ok, err = pcall(function()
		local opts = {}
		if selected_theme then
			opts.theme = selected_theme
		end
		dungeon_factory.generate(opts)
	end)
	if not ok then
		local message = tostring(err)
		ui_state.status_text:set("Error: " .. message)
		log.error("Generation failed: %s", message)
		return
	end
	refresh_world_snapshot()
	ui_state.status_text:set(string.format("Generated (%s)", selected_theme or "random"))
end

local function build_stats_row(label, observable)
	return HStack({
		Text({ label })({ color = 6 }),
		Text({ observable })({ color = 7 })
	})({ spacing = 4, align = "left" })
end

local function build_ui()
	local header = Text({ "Dungeon Generation Harness" })({ color = 11 })
	local status_row = HStack({
		Text({ "Status:" })({ color = 6 }),
		Text({ ui_state.status_text })({ color = 7 })
	})({ spacing = 4 })

	local stats_stack = VStack({
		build_stats_row("Seed", ui_state.seed_text),
		build_stats_row("Rooms", ui_state.rooms_text),
		build_stats_row("Objects", ui_state.objects_text)
	})({ spacing = 2 })

	local theme_row = HStack({
		Text({ "Theme:" })({ color = 6 }),
		Text({ ui_state.theme_text })({ color = 7 }),
		Button({ text = "Next" , on_click = cycle_theme, background_color = 2, border_color = 12 })
	})({ spacing = 6, align = "center" })

	local control_buttons = HStack({
		Button({ text = "Generate", on_click = attempt_generate, background_color = 3, border_color = 12 })
	})({ spacing = 6, align = "top" })

	local log_row = Text({ ui_state.log_status })({ color = 5 })
	local instructions1 = Text({ "Use mouse to click buttons." })({ color = 5 })
	local instructions2 = Text({ "Generate will build a new dungeon." })({ color = 5 })

	ui_state.root = VStack({ header, status_row, stats_stack, theme_row, control_buttons, log_row, instructions1, instructions2 })({
		spacing = 6,
		padding_x = 6,
		padding_y = 6,
		border_color = 1,
		background_color = 0
	})
end

local function handle_mouse_input()
	local mx, my, buttons = mouse()
	mx, my, buttons = mx or 0, my or 0, buttons or 0
	local left_down = (buttons & 0x1) ~= 0
	for _, button in ipairs(ui_state.buttons) do
		local inside = button:hit_test(mx, my)
		if left_down then
			if inside and not button._pressed then
				button._pressed = true
				button:trigger()
			end
		else
			button._pressed = false
		end
	end
	ui_state.mouse_down = left_down
end

if configuration.log.enabled then
	log.set_level(configuration.log.level)
	log.set_target(log.targets.CONSOLE)
	log.init()
	ui_state.log_status:set("log target: console (start src/logview.lua manually)")
end

-- Main initialization function
-- Called once when the program starts
function _init()
	log.info("Initializing application...")

	ui_state.theme_names = build_theme_list()
	set_theme_index(1)
	build_ui()
	refresh_world_snapshot()

	local success, err = pcall(function()
		dungeon_factory.init()
		dungeon_factory.generate({ theme = current_theme_selection() })
	end)

	if not success then
		wtf(tostring(err))
	end

	refresh_world_snapshot()
	ui_state.status_text:set("Ready")
	log.info("Application initialized successfully.")
end

-- Main update function
-- Called every frame to update the program's state
function _update()
	log.trace("> Entering _update()")

	local success, err = pcall(function()
		handle_mouse_input()
		if ui_state.root and ui_state.root.update then
			ui_state.root:update()
		end
	end)

	if not success then
		log.error("Error during update: " .. tostring(err))
	end

	log.trace("< Exiting _update()")
end

-- Main draw function
-- Called every frame to render visuals to the screen
function _draw()
	log.trace("> Entering _draw()")

	local success, err = pcall(function()
		cls(0)
		local world = dungeon_factory.current()
		if world then
			local map_margin = 8
			local gap = 8
			local map_width = 256
			local map_height = 256
			dungeon_map_renderer.draw(world, {
				x = map_margin,
				y = map_margin,
				max_width = map_width,
				max_height = map_height
			})
		else
			print("no dungeon generated", 8, 8, 8)
		end

		if ui_state.root then
			local draw_fn = ui_state.root:draw()
			local map_margin = 8
			local gap = 8
			local map_width = 256
			local panel_x = map_margin + map_width + gap
			local panel_y = map_margin
			draw_fn(panel_x, panel_y)
		end
	end)

	if not success then
		log.error("Error during draw: " .. tostring(err))
	end

	log.trace("< Exiting _draw()")
end
