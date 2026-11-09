-- Exercise the encounter scanner and targeting functions from the runnable bundle.
return function(encounterSource,validSource,policySource)
    local passed=0
    local function test(name,fn)fn();passed+=1;print("PASS "..name)end
    local mt={}
    local function vector(x)return setmetatable({X=x,Y=0,Z=0},mt)end
    mt.__sub=function(a,b)return vector(a.X-b.X)end
    mt.__index=function(v,k)if k=="Magnitude" then return math.abs(v.X)end end
    local function fixture()
        local now=0
        local folder={}
        local state={MultiSpotAnchor=vector(0)}
        local mobs,data={},{}
        local environment=setmetatable({state=state,game={PlaceId=1},selectedFarmSpot=assert(loadstring(policySource))(),targetPriority={IsChest=function()return false end,Rank=function(mob)return mob.Name=="Boss"and 1 or mob.Name=="MiniBoss"and 2 or 3 end},trackedMobs=mobs,
            getMobData=function(mob)return data[mob]end,
            os={clock=function()return now end}}, {__index=getfenv()})
        local scan=assert(loadstring(encounterSource));setfenv(scan,environment);scan()
        local valid=assert(loadstring(validSource));setfenv(valid,environment);valid=valid()
        local f={State=state,Spot={Position=vector(0)}}
        function f.Add(x,hp,rank)
            local root={Position=vector(x)}
            local mob={Parent=folder,Name=rank or "Regular",PrimaryPart=root}
            function mob:FindFirstChild(name)if name=="HumanoidRootPart"then return root end end
            mobs[mob]=true
            data[mob]={Root=root,Health={Value=hp},Entity={FindFirstChild=function(self,key)return self[key]end}}
            return mob,data[mob]
        end
        function f.Read(t)now=t;return state.ReadAutomationEncounter(f.Spot)end
        function f.Valid(mob)return valid(mob,folder)end
        function f.HideData(mob)data[mob]=nil end
        function f.EnableMulti()
            f.Spot.Id="1/Miniboss";f.Spot.PlaceId=1
            state.AutoFarm=true;state.MultiSpot=true;state.MultiSpotSelected={[f.Spot.Id]=true}
            state.MultiSpotAnchor=f.Spot.Position;state.AutomationCatalog={SpotById={[f.Spot.Id]=f.Spot}}
        end
        return f
    end
    test("dead boss does not clear an arena with living regular mobs",function()
        local f=fixture();local _,boss=f.Add(10,100,"Boss");local regular,trash=f.Add(20,50)
        assert(f.Read(0)==2)
        boss.Health.Value=0
        assert(f.Read(.1)==1 and f.Valid(regular)==trash.Root)
        trash.Health.Value=0
        local alive,seen=f.Read(.2);assert(alive==0 and seen)
    end)
    test("Boss Only ignores normal targets and normal adds in arena completion",function()
        local f=fixture();local boss,data=f.Add(10,100,"Boss");local regular=f.Add(20,50)
        f.State.AutoFarm=true;f.State.BossOnly=true
        assert(f.Read(0)==1 and f.Valid(boss)and not f.Valid(regular))
        data.Health.Value=0;assert(f.Read(.1)==0,"Normal adds cannot stall Boss Only rotation")
        f.State.AutoFarm=false;assert(f.Valid(regular),"Boss Only does not restrict manual damage-only Kill Aura")
    end)
    test("regular targets stay confined to the selected arena",function()
        local f=fixture();local near=f.Add(219,10);local far=f.Add(221,10)
        assert(f.Read(0)==1 and f.Valid(near) and not f.Valid(far))
    end)
    test("Account Progression permits only its observed main boss during a fight",function()
        local f=fixture();local boss=f.Add(10,100,"Boss");local regular=f.Add(20,50)
        f.State.AccountProgression=true;f.State.ProgressionBossMob=boss;f.State.ProgressionPhase="Fighting"
        assert(f.Valid(boss) and not f.Valid(regular))
        f.State.ProgressionEquipping=true;assert(not f.Valid(boss))
        f.State.ProgressionEquipping=false;f.State.ProgressionPhase="Changing floor";assert(not f.Valid(boss))
        f.State.ProgressionPhase="Complete";assert(not f.Valid(boss))
        f.State.AccountProgression=false;f.State.ModeratorBlocking=true;assert(not f.Valid(boss)and not f.Valid(regular))
    end)
    test("zero count rescans for adds before cached scan expires",function()
        local f=fixture();local _,boss=f.Add(0,100,"Boss")
        assert(f.Read(0)==1);boss.Health.Value=0
        assert(f.Read(.1)==0)
        local _,add=f.Add(20,40)
        assert(f.Read(.2)==1,"A fresh add must cancel arena-clear confirmation")
        add.Health.Value=0;assert(f.Read(.3)==0)
    end)
    test("observed arena mobs remain tracked when they chase outside the radius",function()
        local f=fixture();local mob,data=f.Add(10,10)
        assert(f.Read(0)==1);data.Root.Position=vector(400)
        assert(f.Read(2)==1 and f.Valid(mob)==data.Root)
        mob.Parent=nil;assert(f.Read(2.1)==0)
    end)
    test("Multi Spot must target remembered living adds that chase outside the selected arena radius",function()
        local f=fixture();f.EnableMulti()
        f.Spot.EncounterNames={MiniBoss=true}
        local mob,data=f.Add(10,100)
        assert(f.Read(0)==1 and f.Valid(mob))
        data.Root.Position=vector(400)
        assert(f.Read(2)==1 and f.Valid(mob)==data.Root,
            "A counted living add must remain farmable after leaving the radius")
        f.State.MultiSpotSelected={}
        assert(not f.Valid(mob),"A remembered add cannot bypass deselecting its encounter")
    end)
    test("A named miniboss arena must not count an unselected nearby main boss",function()
        local f=fixture();f.EnableMulti();f.Spot.EncounterNames={MiniBoss=true}
        local selected=f.Add(10,100,"MiniBoss")
        local unselected=f.Add(20,100,"Boss")
        assert(f.Read(0)==1 and f.Valid(selected)and not f.Valid(unselected),
            "Counter and target admission must agree about unselected bosses")
    end)
    test("Encounter binding prevents old regular mobs leaking into a different selected spot",function()
        local f=fixture();f.EnableMulti()
        local mob,data=f.Add(10,100)
        assert(f.Read(0)==1);data.Root.Position=vector(400)
        assert(f.Valid(mob))
        f.Spot={Id="1/Other",PlaceId=1,Position=vector(1000),EncounterNames={Boss=true}}
        f.State.MultiSpotSelected={[f.Spot.Id]=true};f.State.AutomationCatalog.SpotById[f.Spot.Id]=f.Spot
        f.State.MultiSpotAnchor=f.Spot.Position
        assert(f.Read(2)==0 and not f.Valid(mob),"Encounter transition must retire the prior add membership")
    end)
    test("Remaining-mob readiness distinguishes incomplete, immortal and temporarily skipped mobs",function()
        local f=fixture();f.EnableMulti()
        local loading=f.Add(10,100);f.HideData(loading)
        local immortal,invul=f.Add(20,100);invul.Entity.Immortal={}
        local skipped,retry=f.Add(30,100);retry.SkipUntil=10
        local alive,seen,pending=f.Read(1)
        assert(alive==3 and seen and pending.Loading==1 and pending.Invulnerable==1 and pending.Retry==1)
        assert(not f.Valid(loading)and not f.Valid(immortal)and not f.Valid(skipped),
            "Readiness feedback must not bypass native validation or invent kills")
    end)
    test("incomplete streamed mob data cannot prove arena clear",function()
        local f=fixture();local mob=f.Add(10,10);f.HideData(mob)
        assert(f.Read(0)==1)
        mob.Parent=nil;local alive,seen=f.Read(.2);assert(alive==0 and seen)
        local f2=fixture();local other=f2.Add(20,10);assert(f2.Read(0)==1)
        f2.HideData(other);assert(f2.Read(.1)==1)
    end)
    test("empty arenas wait and exhausted hit-life mobs count as cleared",function()
        local f=fixture();local alive,seen=f.Read(0);assert(alive==0 and not seen)
        local _,data=f.Add(0,50);data.HitLives={Value=1};assert(f.Read(.1)==1)
        data.HitLives.Value=0;assert(f.Read(.2)==0)
    end)
    test("Atheon remains part of its selected arena after a long native dash",function()
        local f=fixture();local mob=f.Add(340,100,"Atheon")
        f.Spot.EncounterNames={Atheon=true}
        assert(f.Read(0)==1 and f.Valid(mob))
    end)
    test("repeated spawns cannot retain removed arena models during a long hold",function()
        local f=fixture()
        for i=1,300 do
            local mob=f.Add(10,100,"Boss")
            assert(f.Read(i*2)==1)
            mob.Parent=nil
            local alive,seen=f.Read(i*2+.1)
            assert(alive==0 and seen and next(f.State.MultiSpotEncounter)==nil,"Arena tracking releases removed models after observing their departure")
        end
    end)
    print("All "..passed.." arena-clear scenarios passed")
end
