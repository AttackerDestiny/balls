return function(source)
    local count=0
    local function test(name,fn)fn();count+=1;print("PASS "..name)end
    local function vec(x,y,z)return {X=x,Y=y,Z=z}end
    local function fixture()
        local floor,hint=0,nil
        local probes=0
        local mob={FindFirstChildOfClass=function()return {HipHeight=2}end}
        local data={Root={Position=vec(0,5,0),Size=vec(2,2,2),AssemblyLinearVelocity=vec(0,0,0)},BodyBelow=5}
        local load=assert(loadstring(source));setfenv(load,setmetatable({Vector3={new=vec}},{__index=getfenv()}))
        local api=load()({Floor=function()probes+=1;return floor end,GroundHint=function()return hint end})
        return {API=api,Mob=mob,Data=data,Floor=function(y)floor=y end,Hint=function(p)hint=p end,Probes=function()return probes end}
    end
    test("ground following tracks ordinary walking",function()
        local f=fixture();local p,air=f.API.Resolve(f.Mob,f.Data,0);assert(p.Y==5 and not air)
        f.Data.Root.Position=vec(5,5,4);p,air=f.API.Resolve(f.Mob,f.Data,.1);assert(p.X==5 and p.Z==4 and not air)
        assert(f.Probes()==1,"Cache probes during fast movement updates")
    end)
    test("ground following freezes enemy jumps even when tween velocity is zero",function()
        local f=fixture();f.API.Resolve(f.Mob,f.Data,0)
        f.Data.Root.Position=vec(20,105,20)
        local p,air=f.API.Resolve(f.Mob,f.Data,.3);assert(air and p.X==0 and p.Y==5 and p.Z==0)
        f.Data.Root.Position=vec(20,5,20);p,air=f.API.Resolve(f.Mob,f.Data,.6);assert(not air and p.X==20 and p.Y==5)
    end)
    test("ground following recognizes a native smash before vertical motion begins",function()
        local f=fixture();f.Hint(vec(0,5,0));f.Data.Root.Position=vec(20,105,20)
        local p,air=f.API.Resolve(f.Mob,f.Data,0);assert(air and p.X==0 and p.Y==5)
    end)
    test("ground following reconstructs the floor if first seen in midair",function()
        local f=fixture();f.Data.Root.Position=vec(10,105,4)
        local p,air=f.API.Resolve(f.Mob,f.Data,0);assert(air and p.Y==5)
    end)
    test("ground following does not chase an unknown rising target",function()
        local f=fixture();f.Floor(nil);f.Data.Root.AssemblyLinearVelocity=vec(0,20,0)
        local p,air=f.API.Resolve(f.Mob,f.Data,0);assert(air and p==nil)
    end)
    test("ground following adapts to walking onto higher terrain",function()
        local f=fixture();f.API.Resolve(f.Mob,f.Data,0);f.Floor(20);f.Data.Root.Position=vec(5,25,5)
        local p,air=f.API.Resolve(f.Mob,f.Data,.3);assert(not air and p.Y==25)
    end)
    print("All "..count.." ground-follow scenarios passed")
end
