--[[pod_format="raw",created="2025-11-07 21:17:13",modified="2025-11-07 21:48:06",revision=1]]
-- procedural dungeon generation

-- generation state
gen_rects={}
gen_nodes={}
gen_edges={}
gen_inventory={}
gen_objects={}
gen_locked_edges={}

local themes_mod  = require("procgen.dungeon.themes")
local geometry    = require("procgen.dungeon.geometry")
local spacing     = require("procgen.dungeon.spacing")
local rooms       = require("procgen.dungeon.rooms")
local corridors   = require("procgen.dungeon.corridors")
local progression = require("procgen.dungeon.progression")
local population  = require("procgen.dungeon.population")

local observability = spacing.observability
local adaptive_settings = spacing.adaptive_settings

local gen_log = spacing.gen_log
local register_room_failure = spacing.register_room_failure
local register_room_success = spacing.register_room_success
local clear_protected = spacing.clear_protected
local protect_tile = spacing.protect_tile
local is_tile_protected = spacing.is_tile_protected

-- theme-specific floor id used during carving/eroding; initialized to stone_tile (1)
local gen_floor_id=1

local function rect_area(rect)
 return (rect[3]-rect[1]+1)*(rect[4]-rect[2]+1)
end

local function classify_room_style(rect)
 local w=rect[3]-rect[1]+1
 local h=rect[4]-rect[2]+1
 local ratio=w/h
 if ratio>=1.8 then
  return "hall_horizontal"
 elseif ratio<=0.55 then
  return "hall_vertical"
 elseif w*h>=120 then
  return "grand"
 elseif w<=6 and h<=6 then
  return "compact"
 else
  return "square"
 end
end

local function choose_weighted(weights,default_key)
 if not weights then return default_key end
 local total=0
 for _,v in pairs(weights) do
  total+=v
 end
 if total<=0 then return default_key end
 local roll=rnd(total)
 local acc=0
 for key,v in pairs(weights) do
  acc+=v
  if roll<=acc then return key end
 end
 return default_key
end

local function get_edge_between(a,b)
	return progression.get_edge_between(a,b)
end

local function locate_room_for_position(x,y)
	return progression.locate_room_for_position(x,y)
end

local function relocate_key_to_room(keynum,target_node)
	return progression.relocate_key_to_room(keynum,target_node)
end

local function validate_and_repair_progression(start_node,locked_edges)
	return progression.validate_and_repair_progression(start_node,locked_edges)
end

local function ensure_theme_rules(theme)
 active_theme_rules = themes_mod.ensure_theme_rules(theme, themes, adaptive_settings)
end

-- helper: check if tile is a wall
function is_wall(val)
 return val>0 and val<door_normal
end

-- helper: check if tile is a door
function is_door(val)
 return val>=door_normal and val<=door_stay_open
end

-- helper: check if tile is an exit
function is_exit(val)
 return val>=exit_start and val<=exit_end
end

-- helper: boundary cell is reserved if it has a door/exit in either layer
function is_reserved_boundary(x,y)
 local w=get_wall(x,y)
 if is_door(w) or is_exit(w) then return true end
 -- defensive: should always be 0 if walls layer is authoritative
 if get_door(x,y)>0 then return true end
 if doorgrid[x] and doorgrid[x][y] then return true end
 return false
end

-- helper: check if rectangles overlap
function rect_overlaps(rect)
	return geometry.rect_overlaps(rect, gen_rects, spacing.get_dynamic_spacing(), map_size)
end

local function rect_conflicts(rect,ignore_nodes,spacing_override)
	return geometry.rect_conflicts(rect, gen_rects, map_size, ignore_nodes, spacing_override, spacing.get_dynamic_spacing())
end

-- helper: fill rectangle using set_wall
-- Note: Uses Lua loops with userdata:set() calls; potential optimization:
-- batch userdata operations or memset() if available per Picotron guidelines
function fill_rect(rect,val)
 geometry.fill_rect(rect, val, set_wall, map_size)
end

-- helper: try place door with fallback positions
function try_place_door_with_fallback(x,y,dtype)
 dtype=dtype or door_normal
 local attempts={{0,0},{-1,0},{1,0},{0,-1},{0,1},{-2,0},{2,0},{0,-2},{0,2}}
 local should_place=rnd(1)<gen_params.room_door_prob
 if not should_place then
  gen_log("door","skipped optional door at "..x..","..y)
  return false
 end
 for i=1,#attempts do
  local off=attempts[i]
  local ax,ay=x+off[1],y+off[2]
  if ax>=0 and ax<map_size and ay>=0 and ay<map_size then
   local existing=get_wall(ax,ay)
   if is_wall(existing) then
    set_wall(ax,ay,dtype)
    create_door(ax,ay,dtype)
    protect_tile(ax,ay)
    if observability.log_corridors then
     gen_log("door","placed door at "..ax..","..ay.." after "..i.." attempts")
    end
    return true
   end
  end
 end
 if observability.log_repairs then
  gen_log("door","failed to place door near "..x..","..y)
 end
 return false
end

-- helper: generate random room
function random_room(base_node,is_special)
	return rooms.random_room(base_node, is_special)
end

-- helper: add room to generation state
function add_room(rect,is_junction)
	return rooms.add_room(rect, is_junction)
end

-- helper: determine corridor type between two rooms
function get_corridor_type(r1,r2)
 return corridors.get_corridor_type(r1, r2)
end

-- helper: place door at exact boundary wall tile with retry
function place_boundary_door_with_retry(bx,by,dtype,max_attempts)
 return corridors.place_boundary_door_with_retry(bx, by, dtype, max_attempts)
end

-- helper: place door at exact boundary wall tile
function place_boundary_door(bx,by,dtype)
 -- bx,by = boundary wall tile (between corridor and room)
 return corridors.place_boundary_door(bx, by, dtype)
end

-- helper: ensure boundary passage (fallback for failed door placement)
function ensure_boundary_passage(bx,by)
 -- delegate to corridor module; uses current theme floor id
 return corridors.ensure_boundary_passage(bx, by, gen_floor_id)
end

function create_corridor(n1,n2)
 -- delegate full corridor creation logic to corridor module
 return corridors.create_corridor(n1, n2, gen_floor_id)
end

-- helper: try to generate and connect a room
function try_generate_room()
 if #gen_nodes==0 then return false end
 local base=gen_nodes[flr(rnd(#gen_nodes))+1]
 if not base then return false end
 local rect=random_room(base,false)
 
 if rect[1]<2 or rect[3]>map_size-3 or rect[2]<2 or rect[4]>map_size-3 then
  register_room_failure("bounds")
  return false
 end
 
 if rect_overlaps(rect) then
  register_room_failure("overlap")
  return false
 end
 
 local node=add_room(rect)
 fill_rect(rect,0)
 for x=max(0,rect[1]),min(map_size-1,rect[3]) do
  for y=max(0,rect[2]),min(map_size-1,rect[4]) do
   set_floor(x, y, gen_floor_id)
  end
 end
 local corridor_ok=create_corridor(base,node)
 if not corridor_ok and observability.log_corridors then
  gen_log("corridor","degenerate corridor between nodes "..base.index.." and "..node.index)
 end
 register_room_success()
 return true
end

-- helper: apply wall textures to room perimeter
function apply_room_walls(rect,tex)
 -- ensure tex is never 0
 if tex==0 then tex=1 end
 
 for x=rect[1],rect[3] do
  if rect[2]-1>=0 and rect[2]-1<128 and x>=0 and x<128 then
   -- skip reserved cells (doors/exits in any layer)
		if not is_reserved_boundary(x,rect[2]-1) then
     set_wall(x,rect[2]-1,tex)
   end
  end
  if rect[4]+1>=0 and rect[4]+1<128 and x>=0 and x<128 then
   -- skip reserved cells (doors/exits in any layer)
		if not is_reserved_boundary(x,rect[4]+1) then
     set_wall(x,rect[4]+1,tex)
   end
  end
 end
 for y=rect[2],rect[4] do
  if rect[1]-1>=0 and rect[1]-1<128 and y>=0 and y<128 then
   -- skip reserved cells (doors/exits in any layer)
		if not is_reserved_boundary(rect[1]-1,y) then
     set_wall(rect[1]-1,y,tex)
   end
  end
  if rect[3]+1>=0 and rect[3]+1<128 and y>=0 and y<128 then
   -- skip reserved cells (doors/exits in any layer)
		if not is_reserved_boundary(rect[3]+1,y) then
     set_wall(rect[3]+1,y,tex)
   end
  end
 end
end

-- repair step: ensure door tiles exist on walls layer for all logical doors
function enforce_door_tiles()
 for door in all(doors) do
  if not is_door(get_wall(door.x,door.y)) then
   set_wall(door.x,door.y,door.dtype or door_normal)
  end
 end
 
 -- also check doorgrid consistency
 for x=0,map_size-1 do
  if doorgrid[x] then
   for y=0,map_size-1 do
    if doorgrid[x][y] then
     local tile=get_wall(x,y)
     if not is_door(tile) then
      -- restore door tile from doorgrid or use default
      local correct_tile=doorgrid[x][y].tile or door_normal
      set_wall(x,y,correct_tile)
      if observability.log_repairs then
       gen_log("door","restored door tile at ("..x..","..y..")")
      end
     end
    end
   end
  end
 end
end

-- border ring enforcement: set outermost ring to walls while preserving doors/exits
function enforce_border_ring()
 -- top and bottom edges (y=0 and y=map_size-1)
 for x=0,map_size-1 do
  -- top edge
  local top_tile=get_wall(x,0)
  if not is_door(top_tile) and not is_exit(top_tile) then
  set_wall(x,0,wall_fill_tile)
  end
  
  -- bottom edge
  local bottom_tile=get_wall(x,map_size-1)
  if not is_door(bottom_tile) and not is_exit(bottom_tile) then
  set_wall(x,map_size-1,wall_fill_tile)
  end
 end
 
 -- left and right edges (x=0 and x=map_size-1)
 for y=0,map_size-1 do
  -- left edge
  local left_tile=get_wall(0,y)
  if not is_door(left_tile) and not is_exit(left_tile) then
  set_wall(0,y,wall_fill_tile)
  end
  
  -- right edge
  local right_tile=get_wall(map_size-1,y)
  if not is_door(right_tile) and not is_exit(right_tile) then
  set_wall(map_size-1,y,wall_fill_tile)
  end
 end
end

-- helper: random wall texture (never returns 0)
function random_wall_texture()
 return themes_mod.random_wall_texture(texsets)
end

-- helper: get theme-appropriate wall texture set
function theme_wall_texture(theme)
 return themes_mod.theme_wall_texture(theme, texsets)
end

-- helper: find accessible rooms from start via edges
function find_accessible_rooms(start_node,locked_edges)
 local accessible={}
 local queue={start_node}
 local visited={}
 visited[start_node]=true
 
 while #queue>0 do
  local node=queue[1]
  deli(queue,1)
  add(accessible,node)
  
  for edge_node in all(node.edges) do
   if not visited[edge_node] then
    local is_locked=false
    if locked_edges then
     for le in all(locked_edges) do
					if (le.n1==node and le.n2==edge_node) or (le.n1==edge_node and le.n2==node) then
       is_locked=true
       break
      end
     end
    end
    
    if not is_locked then
     visited[edge_node]=true
     add(queue,edge_node)
    end
   end
  end
 end
 
 return accessible
end

-- helper: find spawn point in room
function find_spawn_point(rect)
 for attempt=1,max_spawn_attempts do
  local x=rect[1]+1+flr(rnd(rect[3]-rect[1]-1))
  local y=rect[2]+1+flr(rnd(rect[4]-rect[2]-1))
  
  if x>=0 and x<128 and y>=0 and y<128 and get_wall(x,y)==0 then
   local valid=true
   for obj in all(gen_objects) do
    local ox=obj.pos and obj.pos[1] or obj.x
    local oy=obj.pos and obj.pos[2] or obj.y
    if ox and oy then
     local dx,dy=abs(ox-x),abs(oy-y)
     if dx<1 and dy<1 then
      valid=false
      break
     end
    end
   end
   
   if valid then
    return x+0.5,y+0.5
   end
  end
 end
 return nil,nil
end

-- helper: erode map for organic feel (generalized for all wall types)
function erode_map(amount)
 local intensity=(active_theme_rules and active_theme_rules.erosion_intensity) or 1
 local target=flr(amount*intensity)
 local removed=0
 for i=1,target do
  local x,y=flr(rnd(map_size)),flr(rnd(map_size))
  if is_tile_protected(x,y) then goto continue end
  if is_wall(get_wall(x,y)) then
   local neighbors=0
   local near_protected=false
   for dx=-1,1 do
    for dy=-1,1 do
     local nx,ny=x+dx,y+dy
     if nx>=0 and nx<map_size and ny>=0 and ny<map_size then
      if is_tile_protected(nx,ny) then
       near_protected=true
      end
      if get_wall(nx,ny)==0 then
       neighbors+=1
      end
     end
    end
   end
   if not near_protected and neighbors>=3 then
    set_wall(x,y,0)
    set_floor(x,y,gen_floor_id)
    removed+=1
   end
  end
 ::continue::
 end
 if observability.log_corridors and removed>target*0.7 then
  gen_log("erosion","high erosion count "..removed.."/"..target)
 end
end

-- helper: generate exit portal on wall
function generate_exit(rect,exit_type)
	return population.generate_exit(rect, exit_type)
end

-- gameplay generation: enemies, items, decorations, npcs
function generate_gameplay()
	return population.generate_gameplay()
end

-- generate progression: items and locked doors
function generate_progression_loop(start_node)
	-- delegate full progression logic (locking, keys, item placement, repair)
	-- to the progression module to keep this pipeline focused on orchestration.
	progression.generate_progression_loop(start_node)
end

-- generate npcs (hostile and non-hostile) in rooms
function generate_npcs()
	return population.generate_npcs()
end

-- generate items (pickups and interactables) in rooms
function generate_items()
	return population.generate_items()
end

-- generate decorations in rooms
function generate_decorations()
	return population.generate_decorations()
end

-- generate a complete dungeon
function generate_dungeon(opts)
 opts=opts or {}
 local seed=opts.seed or flr(rnd(1000000))
 srand(seed)
 spacing.clear_history()
 clear_protected()
 spacing.reset_adaptive_spacing()
 if gen_params.spacing==nil then gen_params.spacing=0 end
 if observability.log_seed then
  gen_log("seed","generation seed "..seed)
 end
 
 -- initialize state
 gen_rects={}
 gen_nodes={}
 gen_edges={}
 gen_inventory={}
 gen_objects={}
 doors={}
 animated_objects={}
 -- clear doorgrid
 for x=0,map_size-1 do
  if doorgrid[x] then
   for y=0,map_size-1 do
    doorgrid[x][y]=nil
   end
  end
 end
 
 -- fill with walls (non-zero tile)
 fill_rect({0,0,map_size-1,map_size-1},wall_fill_tile)
 
 -- assign global theme before carving (ensures theme floor id is available)
 local selected_theme=opts.theme or "dng"
 if not opts.theme then
  local theme_roll=rnd(1)
  if theme_roll<0.7 then
   selected_theme="dng"
  elseif theme_roll<0.9 then
   selected_theme="out"
  else
   selected_theme="dem"
  end
 end
 gen_params.theme=selected_theme
 ensure_theme_rules(selected_theme)
 local theme_config=themes[selected_theme] or themes.dng
 
 -- set floor and ceiling types based on theme
 local floor_idx=1
 local roof_idx=3
 if theme_config.floor=="stone_tile" then floor_idx=1
 elseif theme_config.floor=="dirt" then floor_idx=2
 end
 if theme_config.roof=="stone_ceiling" then roof_idx=3
 elseif theme_config.roof=="sky" then roof_idx=4
 elseif theme_config.roof=="night_sky" then roof_idx=5
 end
 floor.typ=planetyps[floor_idx]
 roof.typ=planetyps[roof_idx]
 floor.x,floor.y=0,0
 roof.x,roof.y=0,0
 -- theme-specific floor id used by generator when carving/eroding
 gen_floor_id=floor_idx
 
 -- generate first room
 local first_rect=random_room(nil,false)
 local first_node=add_room(first_rect)
 fill_rect(first_rect,0)
 for x=max(0,first_rect[1]),min(map_size-1,first_rect[3]) do
  for y=max(0,first_rect[2]),min(map_size-1,first_rect[4]) do
   set_floor(x, y, gen_floor_id)
  end
 end
 register_room_success()
 
 -- generate additional rooms
 local target_rooms=flr(rnd(gen_params.max_rooms-gen_params.min_rooms+1))+gen_params.min_rooms
 for i=2,target_rooms do
  local placed=false
  for attempt=1,max_room_attempts do
   if try_generate_room() then
    placed=true
    break
   end
  end
  if not placed and observability.log_room_attempts then
   gen_log("room","failed to place room "..i.." after "..max_room_attempts.." attempts")
  end
 end
 
 -- apply wall textures based on theme
 for node in all(gen_nodes) do
  if not node.is_junction then
   local texset=theme_wall_texture(selected_theme)
   local tex=texset.variants[flr(rnd(#texset.variants))+1]
   apply_room_walls(node.rect,tex)
  end
 end
 
 -- ensure any doors placed earlier remain doors on the walls layer
 enforce_door_tiles()
 
 -- generate gameplay content (now aware of theme)
 generate_gameplay()
 -- gameplay may lock doors; re-assert tiles
 enforce_door_tiles()
 
 -- enforce border ring while preserving doors/exits
 enforce_border_ring()
 -- re-assert door tiles after border enforcement
 enforce_door_tiles()
 if observability.enable_console then
  gen_log("summary","border ring enforced")
 end
 
 -- export objects to global arrays (flat iteration, no spatial grid)
 objects=gen_objects
 
 -- populate animated_objects list for frame updates
 animated_objects={}
 for ob in all(objects) do
  if ob.autoanim then
   add(animated_objects, ob)
  end
 end
 
 -- set player start
 player.x=first_node.midx+0.5
 player.y=first_node.midy+0.5
 
 if observability.enable_console then
  gen_log("summary","rooms="..#gen_nodes.." objects="..#gen_objects)
 end
 
 return {x=player.x,y=player.y},{rooms=#gen_nodes,objects=#gen_objects,seed=seed,history=spacing.get_history()}
end
