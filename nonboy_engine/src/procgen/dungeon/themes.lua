--[[pod_format="raw",created="2025-11-18 12:30:00",modified="2025-11-18 12:30:00",revision=1]]
-- Theme helpers for dungeon generation

local themes_mod = {}

-- Compute active theme rules for a given theme name.
-- Does not mutate global state; caller owns storage.
function themes_mod.ensure_theme_rules(theme_name, themes, adaptive_settings)
	local rules = (themes[theme_name] and themes[theme_name].rules) or nil
	local active = rules or {
		room_aspect_bias = 0.35,
		room_extra_size = 0,
		spacing_floor = 0,
		corridor_width = 1,
		corridor_jog_chance = adaptive_settings.corridor_jog_chance or 0.25
	}
	return active
end

-- Random wall texture (never returns 0). Uses texsets from configuration.
function themes_mod.random_wall_texture(texsets)
	local set = texsets[flr(rnd(#texsets - 1)) + 2] -- skip texsets[1] which is floor
	return set.variants[flr(rnd(#set.variants)) + 1]
end

-- Get theme-appropriate wall texture set from texsets.
function themes_mod.theme_wall_texture(theme_name, texsets)
	if theme_name == "out" then
		-- outdoor: grass or earth variants (indices 5=grass, 6=earth)
		local idx = rnd(1) < 0.5 and 5 or 6
		return texsets[idx] or texsets[1]
	elseif theme_name == "dem" then
		-- demon: stone or cobblestone (4=stone, 2=cobblestone)
		local idx = rnd(1) < 0.5 and 4 or 2
		return texsets[idx] or texsets[1]
	elseif theme_name == "house" then
		-- house: wood plank (3=wood_plank)
		return texsets[3] or texsets[1]
	else
		-- default dungeon: brick or cobblestone (1=brick, 2=cobblestone)
		local idx = rnd(1) < 0.5 and 1 or 2
		return texsets[idx] or texsets[1]
	end
end

return themes_mod
