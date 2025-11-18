--[[pod_format="raw",created="2025-11-18 12:45:00",modified="2025-11-18 12:45:00",revision=1]]
-- Spacing and observability helpers for dungeon generation.

local spacing = {}

-- observability + diagnostics configuration (defaults if configuration.lua did not define them)
local observability = rawget(_G, "gen_observability") or {
	enable_console = false,
	capture_history = true,
	history_limit = 400,
	log_seed = true,
	log_room_attempts = true,
	log_corridors = true,
	log_progression = true,
	log_repairs = true
}

local adaptive_settings = rawget(_G, "gen_adaptive_settings") or {
	spacing_relax_threshold = 4,
	spacing_relax_step = 1,
	spacing_max_relax = 4,
	spacing_restore_delay = 2,
	spacing_restore_step = 1,
	max_room_failures = 20,
	offcenter_bias = 0.65,
	bias_radius = 12,
	junction_retry_limit = 4,
	corridor_jog_chance = 0.25
}

spacing.observability = observability
spacing.adaptive_settings = adaptive_settings

local gen_params = rawget(_G, "gen_params") or { spacing = 0 }

local gen_history = {}
local protected_tiles = {}
local dynamic_spacing = 0
local base_spacing = 0
local spacing_restore_timer = 0
local spacing_relaxations = 0
local room_failure_streak = 0
local total_room_failures = 0

local function hist_push(entry)
	if not observability.capture_history then return end
	add(gen_history, entry)
	if #gen_history > (observability.history_limit or 400) then
		deli(gen_history, 1)
	end
end

function spacing.gen_log(tag, msg)
	local line = "[" .. tag .. "] " .. msg
	hist_push(line)
	if observability.enable_console then printh(line) end
end

function spacing.clear_protected()
	protected_tiles = {}
end

function spacing.protect_tile(x, y)
	if not x or not y then return end
	protected_tiles[x] = protected_tiles[x] or {}
	protected_tiles[x][y] = true
end

function spacing.is_tile_protected(x, y)
	return protected_tiles[x] and protected_tiles[x][y] or false
end

local function reset_adaptive_spacing_internal()
	base_spacing = gen_params.spacing or 0
	dynamic_spacing = base_spacing
	spacing_restore_timer = 0
	spacing_relaxations = 0
	room_failure_streak = 0
	total_room_failures = 0
end

function spacing.reset_adaptive_spacing()
	reset_adaptive_spacing_internal()
end

local function relax_spacing()
	if spacing_relaxations >= (adaptive_settings.spacing_max_relax or 4) then return end
	dynamic_spacing = max(0, dynamic_spacing - (adaptive_settings.spacing_relax_step or 1))
	spacing_relaxations += 1
	spacing_restore_timer = adaptive_settings.spacing_restore_delay or 2
	spacing.gen_log("spacing", "relaxed spacing to " .. dynamic_spacing)
end

local function tick_spacing(success)
	if success then
		if spacing_restore_timer > 0 then
			spacing_restore_timer -= 1
		elseif dynamic_spacing < base_spacing then
			dynamic_spacing = min(base_spacing, dynamic_spacing + (adaptive_settings.spacing_restore_step or 1))
			if dynamic_spacing == base_spacing then
				spacing_relaxations = 0
			end
			spacing.gen_log("spacing", "restored spacing to " .. dynamic_spacing)
		end
	else
		if spacing_restore_timer > 0 then
			spacing_restore_timer -= 1
		end
	end
end

function spacing.register_room_failure(reason)
	room_failure_streak += 1
	total_room_failures += 1
	tick_spacing(false)
	if observability.log_room_attempts then
		spacing.gen_log("room_fail", reason .. " (streak=" .. room_failure_streak .. ")")
	end
	if room_failure_streak >= (adaptive_settings.spacing_relax_threshold or 4) then
		relax_spacing()
		room_failure_streak = 0
	end
end

function spacing.register_room_success()
	room_failure_streak = 0
	tick_spacing(true)
end

function spacing.get_dynamic_spacing()
	return dynamic_spacing
end

function spacing.clear_history()
	gen_history = {}
end

function spacing.get_history()
	return gen_history
end

return spacing
