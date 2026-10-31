-- Exercise the encounter scanner and targeting functions from the runnable bundle.
return function(encounterSource,validSource)
    local passed=0
    local function test(name,fn)fn();passed+=1;print("PASS "..name)end
    local mt={}
    local function vector(x)return setmetatable({X=x},mt)end
    mt.__sub=function(a,b)return vector(a.X-b.X)end
    mt.__index=function(v,k)if k=="Magnitude" then return math.abs(v.X)end end
    local function fixture()
        local now=0
        local folder={}
        local state={MultiSpotAnchor=vector(0)}
        local mobs,data={},{}
        local environment=setmetatable({state=state,trackedMobs=mobs,
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
            data[mob]={Root=root,Health={Value=hp},Entity={FindFirstChild=function()end}}
            return mob,data[mob]
        end
        function f.Read(t)now=t;return state.ReadAutomationEncounter(f.Spot)end
        function f.Valid(mob)return valid(mob,folder)end
        function f.HideData(mob)data[mob]=nil end
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
    print("All "..passed.." arena-clear scenarios passed")
end
