return function(source)
    local make=assert(loadstring(source))()
    local counts={["Uncommon Upgrade Crystal"]=25,["Rare Upgrade Crystal"]=0,["Legendary Upgrade Crystal"]=0}
    local selected={["Rare Upgrade Crystal"]=true,["Legendary Upgrade Crystal"]=true}
    local calls={};local busy=false
    local worker=make({Active=function()return true end,Busy=function()return busy end,
        Selected=function(name)return selected[name]end,Count=function(name)return counts[name]end,
        Recipe=function()return 5 end,Send=function(name)calls[#calls+1]=name end,Status=function()end})
    worker.Update(0);assert(#calls==1 and calls[1]=="Rare Upgrade Crystal")
    worker.Update(1);assert(#calls==1,"Wait for server acknowledgment before another spend")
    worker.Update(11);assert(worker.Paused and #calls==1)
    worker.Reset();worker.Update(12);assert(#calls==1,"Selection edits cannot duplicate an unacknowledged request")
    counts["Uncommon Upgrade Crystal"]=20;counts["Rare Upgrade Crystal"]=1
    worker.Update(13);assert(not worker.Paused)
    local time=14
    for _=1,4 do
        worker.Update(time);assert(calls[#calls]=="Rare Upgrade Crystal")
        counts["Uncommon Upgrade Crystal"]-=5;counts["Rare Upgrade Crystal"]+=1
        worker.Update(time+.1);time+=1
    end
    worker.Update(time);assert(calls[#calls]=="Legendary Upgrade Crystal"and #calls==6,"Chain 25 uncommon through five rare into one legendary")
    counts["Rare Upgrade Crystal"]=0;counts["Legendary Upgrade Crystal"]=1
    worker.Update(time+.1);busy=true;counts["Rare Upgrade Crystal"]=5;worker.Update(time+1);assert(#calls==6)
    busy=false;selected={};worker.Update(time+2);assert(#calls==6,"Empty selection disables crafting")
    print("PASS Auto Craft: two-step recipes, acknowledgment, no blind retry, late acknowledgment, trade pause and empty selections")
end
