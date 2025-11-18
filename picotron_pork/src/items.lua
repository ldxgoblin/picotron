function makeipool()
 ipool_rar={}
 ipool_com={}
 
 for i=1,#itm_name do
  local t=itm_type[i]
  if t=="wep" or t=="arm" then
   add(ipool_rar,i)
  else
   add(ipool_com,i)  
  end
 end
end

function makefipool()
 fipool_rar={}
 fipool_com={}
 
 for i in all(ipool_rar) do
  if itm_minf[i]<=floor 
   and itm_maxf[i]>=floor then
   add(fipool_rar,i)
  end
 end
 for i in all(ipool_com) do
  if itm_minf[i]<=floor 
   and itm_maxf[i]>=floor then
   add(fipool_com,i)
  end
 end
end

function getitm_rar()
 if #fipool_rar>0 then
  local itm=getrnd(fipool_rar)
  del(fipool_rar,itm)
  del(ipool_rar,itm)
  return itm
 else
  return getrnd(fipool_com)
 end
end

function foodnames()
 local fud,fu=explode("jerky,schnitzel,steak,gyros,fricassee,haggis,mett,kebab,burger,meatball,pizza,calzone,pasticio,chops,hams,ribs,roast,meatloaf,chili,stew,pie,wrap,taco,burrito,rolls,filet,salami,sandwich,casserole,spam,souvlaki")
 local adj,ad=explode("yellow,green,blue,purple,black,sweet,salty,spicy,strange,old,dry,wet,smooth,soft,crusty,pickled,sour,leftover,mom's,steamed,hairy,smoked,mini,stuffed,classic,marinated,bbq,savory,baked,juicy,sloppy,cheesy,hot,cold,zesty") 

 itm_known={}
 for i=1,#itm_name do
  if itm_type[i]=="fud" then
   fu,ad=getrnd(fud),getrnd(adj)
   del(fud,fu)
   del(adj,ad)
   itm_name[i]=ad.." "..fu
   itm_known[i]=false
  end
 end
end
