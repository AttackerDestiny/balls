return function(scheduleSource,multiSource)
    local makeSchedule=assert(loadstring(scheduleSource))()
    local makeMulti=assert(loadstring(multiSource))()
    local function point(x)return {X=x,Y=0,Z=0}end
    local a={Id="a",Name="Boss A",PlaceId=1,Position=point(0),RespawnSeconds=90,EncounterNames={["Boss A"]=true}}
    local b={Id="b",Name="Boss B",PlaceId=1,Position=point(1000),RespawnSeconds=90,EncounterNames={["Boss B"]=true}}
    local samples={}
    local schedule=makeSchedule({Samples=function()return samples end,CurrentFloor=function()return 1 end})
    local am={Model={},Name="Boss A",Health=100,Position=point(0)}
    samples={am};schedule.Update(0,{a,b});assert(schedule.Get(a).HasLive)
    am.Health=0;schedule.Update(10,{a,b});assert(schedule.Get(a).KilledAt==10 and schedule.Get(a).DueAt==100)
    schedule.Update(30,{a,b});assert(schedule.Get(a).DueAt==100,"Dead corpses cannot restart their timer")
    samples={};schedule.Update(40,{a,b});assert(schedule.Get(a).DueAt==100,"A disappeared corpse retains its confirmed timer")
    local fresh=makeSchedule({Samples=function()return samples end,CurrentFloor=function()return 1 end})
    fresh.Update(40,{a,b});assert(not fresh.Get(a).DueAt,"A new server/runtime cannot inherit old timers")
    samples={{Model={},Name="Boss B",Health=0,Position=point(1000)}}
    fresh.Update(41,{a,b});assert(not fresh.Get(b).DueAt,"An already-dead body is not a newly observed kill")
    samples[1].Health=100;fresh.Update(42,{a,b});samples={};fresh.Update(43,{a,b})
    assert(not fresh.Get(b).DueAt,"Streaming loss is not a confirmed kill")
    local group={Id="group",Name="DA, RA, KA",PlaceId=1,Position=point(5000),RespawnSeconds=45,EncounterNames={Da=true,Ra=true,Ka=true}}
    local groupSamples={}
    for _,name in ipairs({"Da","Ra","Ka"})do groupSamples[#groupSamples+1]={Model={},Name=name,Health=100,Position=point(5000)}end
    samples=groupSamples;schedule.Update(44,{group})
    groupSamples[1].Health=0;schedule.Update(45,{group});assert(schedule.Get(group).DueAt==90 and schedule.Get(group).HasLive)
    groupSamples[2].Health=0;schedule.Update(46,{group});groupSamples[3].Health=0;schedule.Update(47,{group})
    assert(schedule.Get(group).DueAt==90,"Grouped bosses return at the earliest member's respawn")
    groupSamples[1].Health=100;schedule.Update(48,{group})
    assert(schedule.Get(group).HasLive and schedule.Get(group).DueAt==91,"A living spawn clears its old predicted deadline")

    -- Full rotation: A dies at 10, adds finish at 50, B dies at 60, return to A at 100.
    samples={am};am.Health=100
    schedule=makeSchedule({Samples=function()return samples end,CurrentFloor=function()return 1 end})
    local state={Running=true,MultiSpot=true,MultiSpotSelected={a=true,b=true},MultiSpotOrder={"a","b"}}
    local current,goes,adds=nil,{},{}
    local bm={Model={},Name="Boss B",Health=100,Position=point(1000)}
    local function encounter(spot)
        local n=adds[spot.Id]or 0
        local seen=false
        for _,sample in ipairs(samples)do
            if sample.Name==spot.Name then seen=true;if sample.Health>0 then n+=1 end end
        end
        return n,seen
    end
    local api=makeMulti({State=state,Respawns=schedule,Spots=function()return {a,b}end,CurrentFloor=function()return 1 end,
        CanMove=function()return true end,Moving=function()return false end,Arrived=function()return true end,
        Encounter=encounter,ClearEncounter=function()end,Release=function()end,Save=function()end,
        Go=function(spot)current=spot;goes[#goes+1]=spot.Id;return true end,Status=function(text)state.Status=text end})
    api.Update(0);api.Update(1);assert(goes[1]=="a")
    am.Health=0;adds.a=1;api.Update(10);api.Update(11)
    assert(#goes==1 and schedule.Get(a).DueAt==100,"Start boss timer at death while clearing remaining adds")
    adds.a=0;api.Update(50);api.Update(50.7);assert(goes[2]=="b")
    samples={am,bm};api.Update(51);bm.Health=0;api.Update(60);api.Update(60.7)
    assert(#goes==2 and schedule.Get(b).DueAt==150 and api.Phase=="Waiting for respawn")
    api.Update(99.9);assert(#goes==2,"Do not teleport to cooldown arenas early")
    api.Update(100);assert(goes[3]=="a","Return when A's kill-plus-90 timer expires")

    -- Click order outranks catalog order when both spots are due.
    state={Running=true,MultiSpot=true,MultiSpotSelected={a=true,b=true},MultiSpotOrder={"b","a"}}
    local picked
    api=makeMulti({State=state,Respawns={Update=function()end,Get=function()return {DueAt=0}end},
        Spots=function()return {a,b}end,CurrentFloor=function()return 1 end,CanMove=function()return true end,
        Go=function(spot)picked=spot.Id;return true end,Release=function()end,Save=function()end,Status=function()end})
    api.Update(1);assert(picked=="b","Ready spots use saved click order rather than catalog order")
    local checks=0
    local cached=makeSchedule({Samples=function()checks+=1;return {{Model=am.Model,Name="Boss A",Health=100,Position=point(0)}}end,CurrentFloor=function()return 1 end})
    cached.Update(0,{a,b});local builds=cached.NameNormalizations
    for tick=1,100 do cached.Update(tick*.11,{a,b})end
    assert(cached.NameNormalizations==builds,"Repeated checks must reuse normalized boss/arena names")
    local replacement={Id="a",Name="Renamed boss",PlaceId=1,Position=point(0),RespawnSeconds=45,EncounterNames={["Renamed boss"]=true}}
    cached.Update(12,{replacement});assert(cached.NameNormalizations>builds,"Catalog replacement invalidates cached names")
    local before=checks
    cached.Update(13,{{Id="custom",Name="Custom",PlaceId=1}})
    assert(checks==before,"Floors without known respawn timers must skip the boss sample scan")
    print("PASS Respawn rotation: confirmed kill clocks, 90/45 seconds, corpses, streaming, grouped bosses, adds, cooldown waits, due return and click-order priority")
end
