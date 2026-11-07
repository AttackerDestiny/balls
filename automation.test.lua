local safeFactory=assert(loadfile("safe-mode.module.luau"))()
local multiFactory=assert(loadfile("multi-spot.module.luau"))()
local budgetFactory=assert(loadfile("skill-damage-budget.module.luau"))()
local passed=0
local function test(name,fn)fn();passed=passed+1;print("PASS "..name)end
local function safeFixture()
    local s={Running=true,SafeMode=true,SafeFloorId=11}
    local search={Active=false,Outcome="Safe",Starts=0,Status="ready"}
    function search.Start()search.Starts=search.Starts+1;search.Active=true;search.Outcome="Searching";return true end
    function search.Update()end
    function search.Stop(_,outcome)search.Active=false;search.Outcome=outcome or "Stopped"end
    local f={State=s,Search=search,People={},White={},Floor=11,FloorChanges=0,Saves=0,Clock=0}
    f.Api=safeFactory({Clock=function()return f.Clock end,State=s,Search=search,CurrentFloor=function()return f.Floor end,
        TargetFloor=function()return f.ProgressionTarget or s.SafeFloorId end,Players=function()return f.People end,
        Allowed=function(p)return f.White[p.UserId]==true end,Travelling=function()return false end,
        ChangeFloor=function()f.FloorChanges=f.FloorChanges+1 end,Status=function(t)f.Status=t end,Save=function()f.Saves=f.Saves+1 end})
    return f
end
test("safe mode stays enabled when protected",function()
    local f=safeFixture();f.Api.Update();assert(f.State.SafeMode and not f.Api.Seeking and f.Search.Starts==0)
end)
test("whitelisted join stays; unknown join starts searching",function()
    local f=safeFixture();local p={UserId=2};f.White[2]=true;f.People={p};f.Api.Joined(p);f.Api.Update()
    assert(f.Search.Starts==0 and not f.State.SafePendingUserId)
    local outsider={UserId=3};f.People[2]=outsider;f.Api.Joined(outsider);f.Api.Update()
    assert(f.Search.Starts==1 and f.State.SafePendingUserId==3)
    f.Api.Update();assert(f.Search.Starts==1)
end)
test("Safe Mode checks the population immediately after starting the search",function()
    local f=safeFixture();f.People={{UserId=2}};local updates=0
    f.Search.Update=function()updates=updates+1 end
    f.Api.Update();assert(f.Search.Starts==1 and updates==1)
end)
test("successful search monitors; failures keep Safe Mode holding",function()
    local f=safeFixture();f.People={{UserId=2}};f.Api.Update();f.Api.Update()
    f.Search.Active=false;f.Search.Outcome="Safe";f.People={};f.Api.Update()
    assert(f.State.SafeMode and not f.Api.Seeking)
    f.People={{UserId=3}};f.Api.Update();f.Search.Active=false;f.Search.Outcome="Stopped";f.Api.Update()
    assert(f.State.SafeMode and f.Api.Paused and f.Saves==1)
    f.People={};f.Api.Update();assert(not f.Api.Paused and not f.Api.Seeking)
end)
test("Safe Mode retries temporary failures three times without restarting fresh searches",function()
    local f=safeFixture();f.People={{UserId=2}};f.Api.Update();f.Api.Update()
    f.Search.Active=false;f.Search.Outcome="Stopped";f.Search.Retryable=true
    local calls=0;f.Search.Retry=function()calls=calls+1;return false end
    f.Api.Update();f.Api.Update();f.Clock=.49;f.Api.Update();assert(calls==0)
    f.Clock=.5;f.Api.Update();assert(calls==1)
    f.Api.Update();f.Clock=1.5;f.Api.Update();assert(calls==2)
    f.Api.Update();f.Clock=3.5;f.Api.Update();assert(calls==3)
    f.Clock=100;f.Api.Update();assert(calls==3 and f.Api.Paused and f.Search.Starts==1)
    f.People={};f.Api.Update();assert(not f.Api.Paused and not f.Api.Seeking)
end)
test("Permanent failures and Stop Everything cannot auto-restart a search",function()
    local f=safeFixture();f.People={{UserId=2}};f.Api.Pause("No queue support")
    local calls=0;f.Search.Retry=function()calls=calls+1;return true end
    f.Clock=100;f.Api.Update();assert(calls==0)
    f.Search.Retryable=true;f.State.StopEverything=true;f.Api.Update();assert(calls==0)
end)
test("panic fires synchronously for an outsider and not for whitelist",function()
    local f=safeFixture();local panics=0
    f.Api=safeFactory({State=f.State,Search=f.Search,CurrentFloor=function()return 11 end,Players=function()return f.People end,
        Allowed=function(p)return f.White[p.UserId]==true end,Panic=function()panics=panics+1 end,
        ReleasePanic=function()panics=0 end,Status=function()end,Save=function()end,Travelling=function()return false end})
    f.White[2]=true;f.Api.Joined({UserId=2});assert(panics==0)
    f.Api.Joined({UserId=3});assert(panics==1,"Do not wait for a polling tick to panic")
    f.People={{UserId=3}};f.Api.Update();assert(panics>=2)
end)
test("safe floor selection has priority",function()
    local f=safeFixture();f.Floor=1;f.Api.Update();assert(f.FloorChanges==1 and f.Search.Starts==0 and f.Api.Seeking)
end)
test("disabled safe mode does nothing",function()
    local f=safeFixture();f.State.SafeMode=false;f.People={{UserId=2}};f.Api.Update();assert(f.Search.Starts==0)
end)
test("Moderator blocking takes priority over Safe Mode's rejoin search",function()
    local f=safeFixture();f.State.ModeratorBlocking=true;f.People={{UserId=2}};f.Floor=1
    f.Api.Update();assert(f.Search.Starts==0 and f.FloorChanges==0)
end)
test("Account Progression protects the current floor without overwriting the Safe Mode choice",function()
    local f=safeFixture();f.State.AccountProgression=true;f.Floor=1;f.ProgressionTarget=1
    f.Api.Update();assert(f.FloorChanges==0 and not f.Api.Seeking and f.State.SafeFloorId==11)
    f.People={{UserId=3}};f.Api.Update();assert(f.Search.Starts==1 and f.Api.Seeking)
    f.State.AccountProgression=false;f.ProgressionTarget=nil;f.People={};f.Search.Active=false
    f.Api.Reset();f.Api.Update();assert(f.FloorChanges==1 and f.State.SafeFloorId==11)
end)
test("Protected population monitor releases a stalled search without another block",function()
    local f=safeFixture();f.People={{UserId=2}};f.Api.Update();assert(f.Search.Active)
    f.People={};f.Api.ObserveProtected();f.Clock=.59;f.Api.ObserveProtected();assert(f.Search.Active)
    f.Clock=.6;f.Api.ObserveProtected();assert(not f.Search.Active and f.Search.Outcome=="Safe"and not f.Api.Seeking)
    f.People={{UserId=3}};f.Api.Update();assert(f.Search.Starts==2)
end)
test("Protected monitoring cannot release an outsider or bypass unresolved whitelist",function()
    local f=safeFixture();f.People={{UserId=2}};f.Api.Joined(f.People[1])
    f.Api.ObserveProtected();f.Clock=10;f.Api.ObserveProtected();assert(f.State.SafePendingUserId==2)
    f.People={};f.State.SafeWhitelistResolving=true;f.Api.ObserveProtected();assert(f.Status==nil)
end)
test("A failed resumed search is adopted rather than silently starting a fresh budget",function()
    local f=safeFixture();f.People={{UserId=2}};f.Search.Outcome="Stopped";f.Search.Status="12-hop search limit reached"
    f.Api.AdoptSearch();f.Api.Update();assert(f.Api.Paused and f.Search.Starts==0)
end)
local function multiFixture()
    local a={Id="a",PlaceId=11,Name="Boss",Floor={Name="11"}}
    local b={Id="b",PlaceId=11,Name="Mini",Floor={Name="11"}}
    local s={Running=true,MultiSpot=true,MultiSpotSelected={a=true,b=true},MultiSpotDwell=20,SafeFloorId=11}
    local f={State=s,Spots={a,b},Floor=11,Allowed=true,Moving=false,Arrived=true,Goes={},Changes={},Alive=2,Seen=true}
    f.Api=multiFactory({State=s,Spots=function()return f.Spots end,CanMove=function()return f.Allowed end,
        CurrentFloor=function()return f.Floor end,Moving=function()return f.Moving end,Arrived=function()return f.Arrived end,
        Go=function(spot,resume)f.Goes[#f.Goes+1]=spot.Id;f.Resuming=resume;return true end,ChangeFloor=function(id)f.Changes[#f.Changes+1]=id end,
        Encounter=function()return f.Alive,f.Seen end,ClearEncounter=function()f.Seen=false end,
        PriorityTarget=function()return f.Priority end,
        Suspend=function()f.Suspends=(f.Suspends or 0)+1;f.Moving=false end,
        Resume=function()f.Resumes=(f.Resumes or 0)+1 end,
        Release=function()end,Status=function(t)f.Status=t end,Save=function()end})
    return f
end
test("Global priority interrupts an arena trip and returns to the same unfinished arena",function()
    local f=multiFixture();f.Api.Update(0);assert(f.Goes[1]=="a")
    f.Moving=true;f.Priority={Name="Main boss"};f.Api.Update(.1)
    assert(f.Suspends==1 and f.Api.PrioritySuspended and not f.Moving)
    f.Priority={Name="Mini boss"};f.Api.Update(.2)
    assert(f.Suspends==1 and #f.Goes==1,"Do not resume while another priority enemy remains")
    f.Priority=nil;f.Allowed=false;f.Api.Update(.3)
    assert(#f.Goes==1,"Protection/movement pauses must prevent the return trip")
    f.Allowed=true;f.Api.Update(.4)
    assert(f.Goes[2]=="a"and f.Resuming and f.Resumes==1 and f.Api.EncounterSeen)
    f.Alive=3;f.Api.Update(.5);assert(f.Api.Remaining==3 and #f.Goes==2)
    f.Alive=0;f.Api.Update(1);f.Api.Update(1.7)
    assert(f.Goes[3]=="b","Resume all-mob clearing before rotating to the next spot")
end)

test("multi spot waits for every boss to clear then rotates on this floor",function()
    local f=multiFixture();f.Api.Update(0);assert(f.Goes[1]=="a")
    f.Api.Update(1);f.Api.Update(20);f.Alive=1;f.Api.Update(100);assert(#f.Goes==1 and #f.Changes==0)
    f.Alive=0;f.Api.Update(101);f.Api.Update(102);assert(f.Goes[2]=="b" and #f.Changes==0)
end)

test("regular adds reset the all-mob clear confirmation before rotation",function()
    local f=multiFixture();f.Api.Update(0);f.Api.Update(1)
    f.Alive=0;f.Api.Update(2)
    f.Alive=3;f.Api.Update(2.5);f.Api.Update(10)
    assert(#f.Goes==1 and f.Api.Remaining==3 and f.Status:find("3 mobs remaining",1,true))
    f.Alive=1;f.Api.Update(11);assert(#f.Goes==1)
    f.Alive=0;f.Api.Update(12);f.Api.Update(12.5);assert(#f.Goes==1)
    f.Api.Update(12.7);assert(f.Goes[2]=="b")
end)
test("safe mode restricts rotation to its selected floor",function()
    local f=multiFixture();f.State.SafeMode=true;f.State.SafeFloorId=1;f.Api.Update(0)
    assert(#f.Goes==0 and #f.Changes==0)
end)
test("empty arena waits for spawn rather than rotating on a timer",function()
    local f=multiFixture();f.Alive=0;f.Seen=false;f.Api.Update(0);f.Api.Update(1);f.Api.Update(1000)
    assert(#f.Goes==1 and #f.Changes==0 and f.Api.Phase=="Waiting for spawn")
    f.Alive=2;f.Api.Update(1001);f.Alive=1;f.Api.Update(1002);assert(#f.Goes==1)
    f.Alive=0;f.Api.Update(1003);f.Api.Update(1004);assert(f.Goes[2]=="b")
end)
test("saved selections from another floor stay inactive",function()
    local f=multiFixture();f.Spots[2].PlaceId=1;f.Api.Update(0);f.Api.Update(1)
    f.Alive=0;f.Api.Update(2);f.Api.Update(3);f.Api.Update(100)
    assert(#f.Goes==1 and #f.Changes==0)
end)
test("unfinished arena remains the resume target until it clears",function()
    local f=multiFixture();f.Api.Update(0);assert(f.State.MultiSpotPending=="a")
    f.Api.Reset();f.Api.Update(1);assert(f.Goes[2]=="a")
    f.Api.Update(2);f.Alive=0;f.Api.Update(3);f.Api.Update(4)
    assert(f.Goes[3]=="b" and f.State.MultiSpotPending=="b")
end)
test("whitelist editing pauses protection while usernames resolve",function()
    local f=safeFixture();f.State.SafeWhitelistResolving=true;f.People={{UserId=2}};f.Api.Update()
    assert(f.Search.Starts==0 and f.Api.Seeking)
end)
test("single arena stays in place for the next spawn",function()
    local f=multiFixture();f.State.MultiSpotSelected={a=true};f.Api.Update(0);f.Api.Update(1)
    f.Alive=0;f.Api.Update(2);f.Api.Update(3);f.Api.Update(100)
    assert(#f.Goes==1 and f.Api.Phase=="Waiting for spawn" and f.Api.ClearedRounds==1)
end)
test("movement pauses for higher-priority actions",function()
    local f=multiFixture();f.Allowed=false;f.Api.Update(0);assert(#f.Goes==0)
end)
test("failed arena travel retries same arena without saving toggle off",function()
    local f=multiFixture();f.Api.Update(0);f.Arrived=false;f.Api.Update(1)
    assert(f.State.MultiSpot and #f.Goes==1 and f.Api.Phase=="Retrying travel")
    f.Api.Update(2);assert(#f.Goes==1)
    f.Api.Update(3);assert(f.Goes[2]=="a")
    f.Api.Update(4);f.Api.Update(8);f.Api.Update(9)
    assert(f.State.MultiSpot and f.Api.Phase=="Retrying travel" and #f.Goes==3)
    f.Api.Update(13);assert(#f.Goes==3,"Cooldown prevents request spam")
    f.Api.Update(14);assert(#f.Goes==4,"Travel retries automatically without a manual toggle")
    f.Arrived=true;f.Api.Update(15);assert(f.Api.RetryAt==nil and f.Api.Phase=="Clearing arena")
end)
test("Repeated Multi Spot travel failures retry with bounded cooldown and stop when disabled",function()
    local f=multiFixture();f.Arrived=false
    f.Api.Update(0)
    local t=1
    for i=1,10 do
        f.Api.Update(t)
        assert(f.Api.Phase=="Retrying travel"and f.Api.RetryAt-t<=60)
        local count=#f.Goes
        f.Api.Update(f.Api.RetryAt-.01);assert(#f.Goes==count)
        f.Api.Update(f.Api.RetryAt);assert(#f.Goes==count+1)
        t=f.Api.RetryAt+1
    end
    f.State.MultiSpot=false;local count=#f.Goes;f.Api.Update(t+1000);assert(#f.Goes==count)
end)

test("travel watchdog runs while no new movement is allowed",function()
    local f=multiFixture();f.Api.Update(0);f.Moving=true;f.Allowed=false
    f.Api.Update(5);assert(f.Api.Phase=="Moving")
    f.Api.Update(16);assert(f.State.MultiSpot and f.Api.Phase=="Retrying travel")
end)
test("finished trip is checked even while casts prevent new movement",function()
    local f=multiFixture();f.Api.Update(0);f.Allowed=false;f.Api.Update(1)
    assert(f.Api.Phase=="Waiting for spawn" and f.Api.Visits==1)
end)
test("empty selection and toggle off do not teleport",function()
    local f=multiFixture();f.State.MultiSpotSelected={};f.Api.Update(0);assert(#f.Goes==0)
    f.State.MultiSpot=false;f.State.MultiSpotSelected={a=true};f.Api.Update(1);assert(#f.Goes==0)
end)
test("damage budget reserves lethal hits through replication delay",function()
    local b=budgetFactory();local item={}
    b.Reserve(item,150000,159000,0,.5);assert(b.Remaining(item,150000,.1)<=0)
    assert(b.Remaining(item,0,.2)<=0)
    assert(b.Remaining(item,150000,.6)==150000)
end)
test("damage estimate learns conservatively per skill and weapon",function()
    local b=budgetFactory();b.Learn("pistol1",477000,3,159000);assert(b.Estimate("pistol1")==159000)
    b.Learn("pistol1",600000,3,200000);assert(b.Estimate("pistol1")==159000)
    assert(b.Estimate("pistol2")==0);b.Learn("pistol1",0,1);assert(b.Estimate("pistol1")==159000)
end)
test("saved/live arenas merge and old duplicate selections migrate",function()
    local mt={}
    local function vector(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    mt.__sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    mt.__index=function(a,k)if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
    local oldVector=Vector3;Vector3={new=vector}
    local factory=assert(loadfile("floor-catalog.module.luau"))()
    local c=factory({Floors={{PlaceId=5287433115,Name="Hypersiddia"}},Unlocked=function()return true end})
    local areas={
        ["mob:Saurus"]={Id="mob:Saurus",Name="Saurus",Kind="Boss",Position=vector(5184,2351,6259)},
        ["mob:Ra"]={Id="mob:Ra",Name="Ra",Kind="Mini boss",Position=vector(5127,1619,2086)},
        ["mob:Da"]={Id="mob:Da",Name="Da",Kind="Mini boss",Position=vector(5119,1619,2070)},
        ["mob:Ka"]={Id="mob:Ka",Name="Ka",Kind="Mini boss",Position=vector(5130,1619,2152)},
        ["mob:Za, the Eldest"]={Id="mob:Za, the Eldest",Name="Za, the Eldest",Kind="Mini boss",Position=vector(1762,930,-6389)}}
    c.AddCurrent(areas,5287433115);c.AddCurrent(areas,5287433115);c.Sort()
    assert(#c.Spots==4,"No saved/live duplicates or three copies of one mini-boss arena")
    local selected=c.NormalizeSelection({["5287433115/mob:Ra"]=true,["5287433115/Miniboss"]=true,["5287433115/mob:Za, the Eldest"]=true})
    local count=0;for _ in pairs(selected)do count=count+1 end
    assert(count==2 and selected["5287433115/Miniboss"] and selected["5287433115/Za, the Eldest"])
    Vector3=oldVector
end)
test("Atlantis featured floor appears in Safe Mode with native unlock status",function()
    local oldVector=Vector3;Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end}
    local factory=assert(loadfile("floor-catalog.module.luau"))()
    for _,unlocked in ipairs({true,false})do
        local c=factory({Floors={{PlaceId=134019705603409,Name="Atlantis",Category="Featured"}},Unlocked=function()return unlocked end})
        local floor=c.FloorById[134019705603409]
        assert(#c.Floors==1 and floor.Label=="Atlantis"and floor.Unlocked==unlocked)
        assert(#c.Spots==3)
        local leviathan=c.SpotById[tostring(134019705603409).."/Leviathan"]
        assert(leviathan.Name=="Leviathan"and leviathan.Kind=="Boss")
        assert(leviathan.Position.Y==1313 and leviathan.RespawnSeconds==45 and leviathan.EncounterNames.Leviathan)
    end
    Vector3=oldVector
end)
test("Atheon appears as F13 and preserves its unlock status",function()
    local mt={}
    local function vector(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    mt.__sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    mt.__index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
    local oldVector=Vector3;Vector3={new=vector}
    local factory=assert(loadfile("floor-catalog.module.luau"))()
    for _,unlocked in ipairs({true,false}) do
        local c=factory({Floors={{PlaceId=13965775911,Name="Atheon"}},Unlocked=function()return unlocked end})
        local floor=c.FloorById[13965775911]
        assert(#c.Floors==1 and floor.Number==13 and floor.Label=="F13 · Atheon" and floor.Unlocked==unlocked)
        local spot=c.SpotById["13965775911/Atheon arena"]
        assert(spot and spot.Position.X==840 and spot.Position.Y==798 and spot.Position.Z==336 and spot.PositionLocked)
        c.AddCurrent({["mob:Atheon"]={Id="mob:Atheon",Name="Atheon",Kind="Boss",Position=vector(840,798,0)}},13965775911)
        assert(#c.Spots==1 and c.Aliases["13965775911/mob:Atheon"]==spot.Id)
        assert(spot.DestinationId=="source:Atheon arena")
    end
    Vector3=oldVector
end)
test("The Between appears by name in Safe Mode without an arena",function()
    local oldVector=Vector3;Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end}
    local factory=assert(loadfile("floor-catalog.module.luau"))()
    local c=factory({Floors={{PlaceId=78945654064532,Name="The Between"}},Unlocked=function()return true end})
    assert(#c.Floors==1 and c.FloorById[78945654064532].Label=="The Between" and #c.Spots==0)
    Vector3=oldVector
end)
test("Only the named floor boss can refine or alias the canonical F1 boss arena",function()
    local mt={}
    local function vector(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    mt.__sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    mt.__index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
    local oldVector=Vector3;Vector3={new=vector}
    local factory=assert(loadfile("floor-catalog.module.luau"))()
    local c=factory({Floors={{PlaceId=542351431,Name="Virhst Woodlands"}},Unlocked=function()return true end})
    local main=c.SpotById["542351431/Boss"];local original=main.Position
    local gorilla={Id="mob:Gorilla Berserker",Name="Gorilla Berserker",Kind="Boss",Position=original}
    c.AddCurrent({[gorilla.Id]=gorilla},542351431)
    local custom={Id="saved:multispot:test",Name="Saved Spot 1",Kind="Arena",Position=original}
    c.AddCurrent({[custom.Id]=custom},542351431)
    local customSpot=c.SpotById["542351431/"..custom.Id]
    assert(customSpot and customSpot.Kind=="Arena"and customSpot.DestinationId==custom.Id)
    local total=#c.Spots
    c.AddCurrent({[custom.Id]=custom},542351431)
    assert(#c.Spots==total and customSpot~=main and not customSpot.MainBoss)
    assert(main.MainBoss and main.EncounterNames["Rahjin the Thief King"]and main.Position==original)
    assert(main.DestinationId=="source:Boss"and c.Aliases["542351431/mob:Gorilla Berserker"]~=main.Id)
    local rahjin={Id="mob:Rahjin the Thief King",Name="Rahjin the Thief King",Kind="Boss",Position=vector(original.X+20,original.Y,original.Z)}
    c.AddCurrent({[gorilla.Id]=gorilla,[rahjin.Id]=rahjin},542351431)
    assert(main.DestinationId=="source:Boss" and main.Position==original,"Live discoveries cannot overwrite supplied positions")
    assert(c.Aliases["542351431/mob:Rahjin the Thief King"]==main.Id)
    Vector3=oldVector
end)
print("All "..passed.." automation/damage scenarios passed")
