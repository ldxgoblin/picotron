-- core bootstrap (from 0.lua)
function _init()
 t=0
 shake=0
 
 dpal=explodeval(configuration.data.dpal)
 
 dirx=explodeval(configuration.data.dirx)
 diry=explodeval(configuration.data.diry)
 
 itm_name=explode(configuration.data.itm_name)
 itm_type=explode(configuration.data.itm_type)
 itm_stat1=explodeval(configuration.data.itm_stat1)
 itm_stat2=explodeval(configuration.data.itm_stat2)
 itm_minf=explodeval(configuration.data.itm_minf)
 itm_maxf=explodeval(configuration.data.itm_maxf)
 itm_desc=explode(configuration.data.itm_desc)
 
 mob_name=explode(configuration.data.mob_name)
 mob_ani=explodeval(configuration.data.mob_ani)
 mob_atk=explodeval(configuration.data.mob_atk)
 mob_hp=explodeval(configuration.data.mob_hp)
 mob_los=explodeval(configuration.data.mob_los)
 mob_minf=explodeval(configuration.data.mob_minf)
 mob_maxf=explodeval(configuration.data.mob_maxf)
 mob_spec=explode(configuration.data.mob_spec)
 
 crv_sig=explodeval(configuration.data.crv_sig)
 crv_msk=explodeval(configuration.data.crv_msk)
 
 free_sig=explodeval(configuration.data.free_sig)
 free_msk=explodeval(configuration.data.free_msk)
 
 wall_sig=explodeval(configuration.data.wall_sig)
 wall_msk=explodeval(configuration.data.wall_msk)

 debug={}
 startgame()
end

function _update60()
 t+=1
 _upd()
 dofloats()
 dohpwind()
end

function _draw()
 doshake()
 _drw()
 drawind()
 drawlogo()
 --fadeperc=0
 checkfade()
 --★
 cursor(4,4)
 color(8)
 for txt in all(debug) do
  print(txt)
 end
end

function startgame()
 music(0)
 tani=0
 fadeperc=1
 buttbuff=-1
 
 logo_t=240
 logo_y=35
 
 skipai=false
 win=false
 winfloor=9
 --★
 mob={}
 dmob={}
 p_mob=addmob(1,1,1)
 
 p_t=0
 
 inv,eqp={},{}
 makeipool()
 foodnames()
 --takeitem(17)
 
 wind={}
 float={}

 talkwind=nil
 
 hpwind=addwind(5,5,28,13,{})

 thrdx,thrdy=0,-1
 
 _upd=update_game
 _drw=draw_game
 
 st_steps,st_kills,st_meals,st_killer=0,0,0,""
 
 genfloor(0)
 
end
