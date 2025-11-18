--[[pod_format="raw",created="2025-11-18 14:10:00",modified="2025-11-18 14:10:00",revision=1]]

local spacing = require("procgen.dungeon.spacing")

local population = {}

local observability = spacing.observability
local gen_log       = spacing.gen_log

function population.generate_exit(rect,exit_type)
 local walls={}
 for x=rect[1],rect[3] do
		if rect[2]-1>=0 and is_wall(get_wall(x,rect[2]-1)) then
   add(walls,{x,rect[2]})
  end
		if rect[4]+1<128 and is_wall(get_wall(x,rect[4]+1)) then
   add(walls,{x,rect[4]})
  end
 end
 for y=rect[2],rect[4] do
		if rect[1]-1>=0 and is_wall(get_wall(rect[1]-1,y)) then
   add(walls,{rect[1],y})
  end
		if rect[3]+1<128 and is_wall(get_wall(rect[3]+1,y)) then
   add(walls,{rect[3],y})
  end
 end
 
 if #walls>0 then
  local pos=walls[flr(rnd(#walls))+1]
  local exit_tile=exit_type==3 and exit_start or exit_end
  set_wall(pos[1],pos[2],exit_tile or 0)
  local ob={
   pos={pos[1]+0.5,pos[2]+0.5},
   typ=obj_types.interactable_exit,
   rel={0,0},
   frame=0,
   animloop=true,
   autoanim=false,
   exit_type=exit_type
  }
  add(gen_objects,ob)
 end
end

function population.generate_gameplay()
 if not gen_nodes or #gen_nodes==0 then
  gen_log("error","generate_gameplay() called with no rooms")
  printh("error: generate_gameplay() called with no rooms")
  return
 end
 local start_node=gen_nodes[1]
 local exit_node=gen_nodes[#gen_nodes]
 
 population.generate_exit(start_node.rect,3)
 population.generate_exit(exit_node.rect,4)
 
 erode_map(gen_params.erode_amount)
 
 for i=1,3 do
  add(gen_inventory,{type="heart"})
 end
 
 generate_progression_loop(start_node)
 
 population.generate_npcs()
 population.generate_items()
 population.generate_decorations()
end

function population.generate_npcs()
 for node in all(gen_nodes) do
  local rect=node.rect
  local num_npcs=flr(rnd(3))+1
  
  for i=1,num_npcs do
   local x,y=find_spawn_point(rect)
   if x then
    if rnd(1)<gen_params.npc_hostile_ratio then
     local available_enemies = {}
     for enemy in all(enemy_types) do
      if enemy.difficulty <= gen_params.difficulty then
       add(available_enemies, enemy)
      end
     end
     if #available_enemies == 0 then
      available_enemies = {enemy_types[1]}
     end
     local enemy_type = available_enemies[flr(rnd(#available_enemies))+1]
     local ai_type=rnd(1)<0.5 and "patrol" or "follow"
     local ob={
      pos={x,y},
      typ=obj_types.hostile_npc,
      rel={0,0},
      frame=0,
      animloop=true,
      autoanim=true,
      ai_type=ai_type,
      patrol_index=0,
      patrol_points={},
      sprite_index=enemy_type.sprite
     }
     if ai_type=="patrol" then
      for j=1,4 do
       local px,py=find_spawn_point(rect)
       if px then
        add(ob.patrol_points,{x=px,y=py})
       end
      end
      if #ob.patrol_points==0 then
       add(ob.patrol_points,{x=x,y=y})
      end
     end
     add(gen_objects,ob)
    else
     local ob={
      pos={x,y},
      typ=obj_types.non_hostile_npc,
      rel={0,0},
      frame=0,
      animloop=true,
      autoanim=false,
      sprite_index=obj_types.non_hostile_npc.mx
     }
     add(gen_objects,ob)
    end
   end
  end
 end
end

function population.generate_items()
 for node in all(gen_nodes) do
  local rect=node.rect
  local num_items=flr(rnd(gen_params.items_per_room))+1
  
  for i=1,num_items do
   local x,y=find_spawn_point(rect)
   if x then
    if rnd(1)<0.6 then
     local pickup_type=rnd(1)<0.5 and "heart" or "direct_pickup"
     local obj_type=pickup_type=="heart" and obj_types.heart or obj_types.direct_pickup
     local ob={
      pos={x,y},
      typ=obj_type,
      rel={0,0},
      frame=0,
      animloop=true,
      autoanim=true
     }
     add(gen_objects,ob)
    else
     local subtypes={"chest","shrine","trap","note"}
     local subtype=subtypes[flr(rnd(#subtypes))+1]
     local obj_type
     if subtype=="chest" then
      obj_type=obj_types.interactable_chest
     elseif subtype=="shrine" then
      obj_type=obj_types.interactable_shrine
     elseif subtype=="trap" then
      obj_type=obj_types.interactable_trap
     else
      obj_type=obj_types.interactable_note
     end
     local ob={
      pos={x,y},
      typ=obj_type,
      rel={0,0},
      frame=0,
      animloop=true,
      autoanim=false,
      subtype=subtype
     }
     add(gen_objects,ob)
    end
   end
  end
 end
end

function population.generate_decorations()
 local current_theme=gen_params.theme or "dng"
 local theme_config=themes[current_theme] or themes.dng
 local decor_prob=theme_config.decor_prob or 0.8
 
 for node in all(gen_nodes) do
  local rect=node.rect
  local w,h=rect[3]-rect[1]+1,rect[4]-rect[2]+1
  local room_decor_count=0
  local max_decor=gen_params.max_decorations_per_room or 12
  
  for dec in all(decoration_types) do
   if room_decor_count>=max_decor then break end
   
   local theme_match=false
   if dec.theme_tags then
    for tag in all(dec.theme_tags) do
     if tag==current_theme then
      theme_match=true
      break
     end
    end
   else
    theme_match=true
   end
   
   if theme_match and dec.gen_tags then
    for tag in all(dec.gen_tags) do
     if room_decor_count>=max_decor then break end
     
     if tag=="uni" and rnd(1)<0.3*decor_prob then
      for dx=2,w-2,3 do
       for dy=2,h-2,3 do
        if room_decor_count>=max_decor then break end
        if rnd(1)<0.5 then
         local x,y=rect[1]+dx+0.5,rect[2]+dy+0.5
         local ob={pos={x,y},typ=dec.obj_type,rel={0,0},frame=0,animloop=true,autoanim=true,sprite_index=dec.sprite}
         add(gen_objects,ob)
         room_decor_count+=1
        end
       end
       if room_decor_count>=max_decor then break end
      end
      
     elseif tag=="uni2" and rnd(1)<0.4*decor_prob then
      for dx=1,w-1,2 do
       for dy=1,h-1,2 do
        if room_decor_count>=max_decor then break end
        if rnd(1)<0.6 then
         local x,y=rect[1]+dx+0.5,rect[2]+dy+0.5
         local ob={pos={x,y},typ=dec.obj_type,rel={0,0},frame=0,animloop=true,autoanim=true,sprite_index=dec.sprite}
         add(gen_objects,ob)
         room_decor_count+=1
        end
       end
       if room_decor_count>=max_decor then break end
      end
      
     elseif tag=="scatter" and rnd(1)<0.2*decor_prob then
      local count=flr(rnd(3))+1
      for i=1,count do
       if room_decor_count>=max_decor then break end
       local x,y=find_spawn_point(rect)
       if x then
        local ob={pos={x,y},typ=dec.obj_type,rel={0,0},frame=0,animloop=true,autoanim=true,sprite_index=dec.sprite}
        add(gen_objects,ob)
        room_decor_count+=1
       end
      end
      
     elseif tag=="big" and rnd(1)<0.15*decor_prob then
      if room_decor_count>=max_decor then break end
      local cx,cy=flr((rect[1]+rect[3])/2)+0.5,flr((rect[2]+rect[4])/2)+0.5
      if rnd(1)<0.5 then
       local ob={pos={cx,cy},typ=dec.obj_type,rel={0,0},frame=0,animloop=true,autoanim=true,sprite_index=dec.sprite}
       add(gen_objects,ob)
       room_decor_count+=1
      else
       local corners={{rect[1]+1.5,rect[2]+1.5},{rect[3]-0.5,rect[2]+1.5},{rect[1]+1.5,rect[4]-0.5},{rect[3]-0.5,rect[4]-0.5}}
       local corner=corners[flr(rnd(#corners))+1]
       local ob={pos={corner[1],corner[2]},typ=dec.obj_type,rel={0,0},frame=0,animloop=true,autoanim=true,sprite_index=dec.sprite}
       add(gen_objects,ob)
       room_decor_count+=1
      end
      
     elseif tag=="rare" and rnd(1)<0.05*decor_prob then
      if room_decor_count>=max_decor then break end
      local x,y=find_spawn_point(rect)
      if x then
       local ob={pos={x,y},typ=dec.obj_type,rel={0,0},frame=0,animloop=true,autoanim=true,sprite_index=dec.sprite}
       add(gen_objects,ob)
       room_decor_count+=1
      end
      
     elseif tag=="lit" and rnd(1)<0.25*decor_prob then
      if room_decor_count>=max_decor then break end
      local walls={}
      for x=rect[1]+1,rect[3]-1 do
       if get_wall(x,rect[2])>0 then add(walls,{x+0.5,rect[2]+1.5}) end
       if get_wall(x,rect[4])>0 then add(walls,{x+0.5,rect[4]-0.5}) end
      end
      for y=rect[2]+1,rect[4]-1 do
       if get_wall(rect[1],y)>0 then add(walls,{rect[1]+1.5,y+0.5}) end
       if get_wall(rect[3],y)>0 then add(walls,{rect[3]-0.5,y+0.5}) end
      end
      if #walls>0 then
       local pos=walls[flr(rnd(#walls))+1]
       local ob={pos={pos[1],pos[2]},typ=dec.obj_type,rel={0,0},frame=0,animloop=true,autoanim=true,sprite_index=dec.sprite}
       add(gen_objects,ob)
       room_decor_count+=1
      end
     end
    end
   end
  end
 end
end

return population
