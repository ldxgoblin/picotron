--[[pod_format="raw",created="2025-11-18 13:35:00",modified="2025-11-18 13:35:00",revision=1]]

local spacing = require("procgen.dungeon.spacing")

local progression = {}

local observability = spacing.observability
local gen_log       = spacing.gen_log
local protect_tile  = spacing.protect_tile

local function get_edge_between(a,b)
 for e in all(gen_edges) do
  if (e.n1==a and e.n2==b) or (e.n1==b and e.n2==a) then
   return e
  end
 end
 return nil
end

local function locate_room_for_position(x,y)
 for node in all(gen_nodes) do
  local r=node.rect
  if x>=r[1] and x<=r[3] and y>=r[2] and y<=r[4] then
   return node
  end
 end
 return nil
end

local function relocate_key_to_room(keynum,target_node)
 if not target_node then return false end
 local sx,sy=find_spawn_point(target_node.rect)
 if not sx then
  sx=target_node.midx+0.5
  sy=target_node.midy+0.5
 end
 for ob in all(gen_objects) do
  if ob.typ==obj_types.key and ob.keynum==keynum then
   ob.pos={sx,sy}
   ob.room_index=target_node.index
   if observability.log_progression then
    gen_log("progression","relocated key#"..keynum.." to room "..target_node.index)
   end
   return true
  end
 end
 return false
end

local function validate_and_repair_progression(start_node,locked_edges)
 if not locked_edges or #locked_edges==0 then return end
 local key_rooms={}
 for ob in all(gen_objects) do
  if ob.typ==obj_types.key and ob.keynum then
   if not ob.room_index then
    local node=locate_room_for_position(ob.pos[1],ob.pos[2])
    ob.room_index=node and node.index or nil
   end
   key_rooms[ob.keynum]=ob.room_index
  end
 end

 local acquired={}
 local visited={}
 local queue={start_node}
 visited[start_node]=true
 local function collect_keys(node)
  for ob in all(gen_objects) do
   if ob.typ==obj_types.key and ob.keynum and ob.room_index==node.index then
    acquired[ob.keynum]=true
   end
  end
 end
 collect_keys(start_node)
 local progressed=true
 while progressed do
  progressed=false
  for edge in all(gen_edges) do
   local a,b=edge.n1,edge.n2
   local a_vis=visited[a]
   local b_vis=visited[b]
   if a_vis and not b_vis then
    local can_traverse=true
    if edge.locked and edge.keynum and not acquired[edge.keynum] then
     can_traverse=false
    end
    if can_traverse then
     visited[b]=true
     collect_keys(b)
     progressed=true
    end
   elseif b_vis and not a_vis then
    local can_traverse=true
    if edge.locked and edge.keynum and not acquired[edge.keynum] then
     can_traverse=false
    end
    if can_traverse then
     visited[a]=true
     collect_keys(a)
     progressed=true
    end
   end
  end
 end

 local relocated=false
 for edge in all(locked_edges) do
  if edge.locked and edge.keynum then
   local n1_vis=visited[edge.n1]
   local n2_vis=visited[edge.n2]
   if not (n1_vis and n2_vis) then
    if relocate_key_to_room(edge.keynum,start_node) then
     relocated=true
     acquired[edge.keynum]=true
     visited[edge.n1]=true
     visited[edge.n2]=true
    end
   end
  end
 end
 if relocated then
  validate_and_repair_progression(start_node,locked_edges)
 end
end

local function find_accessible_rooms(start_node,locked_edges)
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

local function generate_progression_loop(start_node)
 local locked_edges={}
 local key_counter=1
 
 local full_accessible=find_accessible_rooms(start_node,locked_edges)
 
 local edges_shuffled={}
 for e in all(gen_edges) do add(edges_shuffled,e) end
 for i=#edges_shuffled,2,-1 do
  local j=flr(rnd(i))+1
  edges_shuffled[i],edges_shuffled[j]=edges_shuffled[j],edges_shuffled[i]
 end
 
 for gate_idx=1,#edges_shuffled do
  if key_counter>3 then break end
  
  local edge=edges_shuffled[gate_idx]
  local n1,n2=edge.n1,edge.n2
  
  local combined_locked={}
  for le in all(locked_edges) do add(combined_locked,le) end
  add(combined_locked,edge)
  local test_accessible=find_accessible_rooms(start_node,combined_locked)
  
  if #test_accessible<#full_accessible then
   local candidates={edge.b1,edge.b2}
   local chosen=nil
   for c in all(candidates) do
    if c and c.x and c.y then
     local wt=get_wall(c.x,c.y)
     if is_door(wt) then
      chosen=c
      break
     end
    end
   end
   if chosen then
    local x,y=chosen.x,chosen.y
    local door=doorgrid[x] and doorgrid[x][y] or nil
    if door then
     set_wall(x,y,door_locked)
     door.dtype=door_locked
     door.keynum=key_counter
     door.locked=true
    else
     set_wall(x,y,door_locked)
     create_door(x,y,door_locked,key_counter)
    end
    protect_tile(x,y)
    edge.locked=true
    edge.keynum=key_counter
    edge.lock_tile={x=x,y=y}
    add(locked_edges,edge)
    full_accessible=find_accessible_rooms(start_node,locked_edges)
    add(gen_inventory,{type="key",keynum=key_counter})
    if observability.log_progression then
     gen_log("progression","locked edge "..n1.index.." <-> "..n2.index.." key#"..key_counter)
    end
    key_counter+=1
   else
    if observability.log_progression then
     gen_log("progression","edge "..n1.index.." <-> "..n2.index.." missing door; skipped")
    end
   end
  end
 end
 
 local failed_placements=0
 local accessible=find_accessible_rooms(start_node,locked_edges)
 while #gen_inventory>0 do
  if #accessible>0 then
   local room=accessible[flr(rnd(#accessible))+1]
   local item=gen_inventory[1]
   deli(gen_inventory,1)
   
   local x,y=find_spawn_point(room.rect)
   if x then
    failed_placements=0
    if item.type=="key" then
     local ob={pos={x,y},typ=obj_types.key,rel={0,0},frame=0,animloop=true,autoanim=true,keynum=item.keynum,room_index=room.index}
     add(gen_objects,ob)
    else
     local ob={pos={x,y},typ=obj_types[item.type],rel={0,0},frame=0,animloop=true,autoanim=true}
     add(gen_objects,ob)
    end
   else
    if item.type=="key" then
     local attempts=0
     local placed=false
     while attempts<15 and not placed do
      local rr=accessible[flr(rnd(#accessible))+1]
      local kx,ky=find_spawn_point(rr.rect)
      if kx then
       local ob={pos={kx,ky},typ=obj_types.key,rel={0,0},frame=0,animloop=true,autoanim=true,keynum=item.keynum,room_index=rr.index}
       add(gen_objects,ob)
       placed=true
       break
      end
      attempts+=1
     end
     if not placed then
      local sx,sy=find_spawn_point(start_node.rect)
      if not sx then
       sx=start_node.midx+0.5
       sy=start_node.midy+0.5
      end
      local ob={pos={sx,sy},typ=obj_types.key,rel={0,0},frame=0,animloop=true,autoanim=true,keynum=item.keynum,room_index=start_node.index}
      add(gen_objects,ob)
     end
    else
     failed_placements+=1
     if failed_placements>10 then
      gen_log("items","failed to place items after multiple attempts; stopping")
      break
     end
    end
   end
  else
   break
  end
 end

 validate_and_repair_progression(start_node,locked_edges)
 gen_locked_edges=locked_edges
end

function progression.get_edge_between(a,b)
 return get_edge_between(a,b)
end

function progression.locate_room_for_position(x,y)
 return locate_room_for_position(x,y)
end

function progression.relocate_key_to_room(keynum,target_node)
 return relocate_key_to_room(keynum,target_node)
end

function progression.validate_and_repair_progression(start_node,locked_edges)
 return validate_and_repair_progression(start_node,locked_edges)
end

function progression.find_accessible_rooms(start_node,locked_edges)
 return find_accessible_rooms(start_node,locked_edges)
end

function progression.generate_progression_loop(start_node)
 return generate_progression_loop(start_node)
end

return progression
