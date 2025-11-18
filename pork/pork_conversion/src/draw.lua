-- drawing (from 2.lua)
--draws

function draw_game()
 cls(0)
 if fadeperc==1 then return end
 animap()

 -- center camera on player in world pixels
 local px = p_mob.x*TILE_SIZE + TILE_SIZE/2
 local py = p_mob.y*TILE_SIZE + TILE_SIZE/2
 local camx = px - SCREEN_W/2
 local camy = py - SCREEN_H/2
 camera(camx + shake_x, camy + shake_y)

 -- draw whole dungeon map scaled to TILE_SIZE
 map(0,0, 0,0, MAP_W,MAP_H, nil, TILE_SIZE,TILE_SIZE)
 for m in all(dmob) do
  if sin(time()*8)>0 or m==p_mob then
   drawmob(m)
  end
  m.dur-=1
  if m.dur<=0 and m!=p_mob then
   del(dmob,m)
  end
 end
 
 for i=#mob,1,-1 do
  drawmob(mob[i])
 end
 
 if _upd==update_throw then
  --★ throw preview in world space
  local tx,ty=throwtile()
  local lx1,ly1=p_mob.x*TILE_SIZE+TILE_SIZE/2+thrdx*(TILE_SIZE/2),
               p_mob.y*TILE_SIZE+TILE_SIZE/2+thrdy*(TILE_SIZE/2)
  local lx2,ly2=tx*TILE_SIZE+TILE_SIZE/2, ty*TILE_SIZE+TILE_SIZE/2
  rectfill(lx1+thrdy,ly1+thrdx,lx2-thrdy,ly2-thrdx,0)
  
  local thrani,mb=flr(t/7)%2==0,getmob(tx,ty)
  if thrani then
   fillp(0b1010010110100101)
  else
   fillp(0b0101101001011010)
  end
  line(lx1,ly1,lx2,ly2,7)
  fillp()
  oprint8("+",lx2-1,ly2-2,7,0)
  
  if mb and thrani then
   mb.flash=1
  end
 end 
 
 for x=0,MAP_W-1 do
  for y=0,MAP_H-1 do
   if fog[x][y]==1 then
    rectfill2(x*TILE_SIZE,y*TILE_SIZE,TILE_SIZE,TILE_SIZE,0)
   end
  end
 end
  
 for f in all(float) do
  oprint8(f.txt,f.x,f.y,f.c,0)
 end

 -- reset camera before HUD / logo drawing
 camera()

end

function drawlogo()
 if logo_y>-24 then
  logo_t-=1
  if logo_t<=0 then
   logo_y+=logo_t/20
  end
  palt(12,true)
  palt(0,false)
  spr(128,7,logo_y)
  palt()
  oprint8("the quest for kielbasa",19,logo_y+20,7,0)
 end
end

function drawmob(m)
 local col=10
 if m.flash>0 then
  m.flash-=1
  col=7
 end
 drawspr(getframe(m.ani),m.x*TILE_SIZE+m.ox,m.y*TILE_SIZE+m.oy,col,m.flp)
end

function draw_gover()
 cls()
 palt(12,true)
 spr(gover_spr,gover_x,30)
 if not win then
  print("killed by a "..st_killer,28,43,6)
 end
 palt()
 color(5)
 cursor(40,56)
 if not win then
  print("floor: "..floor)
 end
 print("steps: "..st_steps)
 print("kills: "..st_kills)
 print("meals: "..st_meals) 

 print("press ❎",46,90,5+abs(sin(time()/3)*2))
end

function animap()
 tani+=1
 if (tani<15) return
 tani=0
 -- tile animation still bound to the original 16x16 sprite region
 for x=0,15 do
  for y=0,15 do
   local tle=mget(x,y)
   if tle==64 or tle==66 then
    tle+=1
   elseif tle==65 or tle==67 then
    tle-=1
   end
   mset(x,y,tle)
  end
 end
end
