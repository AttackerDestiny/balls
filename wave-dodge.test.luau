return function(source)
    local vector={}
    local function v(x,y,z)return setmetatable({X=x,Y=y,Z=z},vector)end
    function vector.__index(a,key)
        local length=math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)
        if key=="Magnitude"then return length end
        if key=="Unit"then return v(a.X/length,a.Y/length,a.Z/length)end
    end
    function vector.__add(a,b)return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    function vector.__sub(a,b)return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    function vector.__mul(a,b)return v(a.X*b,a.Y*b,a.Z*b)end
    local function child(a,key)return a[key]end
    local state={Running=true,AutoFarm=true,Enabled=true,AutoDodge=true}
    local attrs={Wave=58,WaveDefenseEnvironment="Blackout",CountdownNote="Survive for"}
    local light={Enabled=true,Range=30}
    local part={Position=v(40,73,0),PointLight=light,FindFirstChildOfClass=child}
    local orb={Part=part,LightDuration=30,FindFirstChild=child,GetAttribute=child}
    local world={DarknerOrb=orb,FallenPartsDestroyHeight=-500,FindFirstChild=child,GetAttribute=function(_,key)return attrs[key]end}
    local root={Position=v(100,73,0),Size=v(2,2,2)}
    local character={HumanoidRootPart=root,Humanoid={HipHeight=2},Entity={Health={Value=100},FindFirstChild=child},
        FindFirstChild=child,FindFirstChildOfClass=child}
    local near,far={FindFirstChild=child},{FindFirstChild=child}
    local data={
        [near]={Root={Position=v(62,73,0),Size=v(4,4,4)},Health={Value=100},Entity={FindFirstChild=child}},
        [far]={Root={Position=v(85,73,0),Size=v(4,4,4)},Health={Value=100},Entity={FindFirstChild=child}},
    }
    local at=1
    local env=setmetatable({Vector3={new=v},workspace=world,game={JobId="test",Players={LocalPlayer={Character=character,UserId=1}}},
        getgenv=function()return {}end,os={clock=function()return at end}},{__index=getfenv()})
    local chunk=assert(loadstring(source));setfenv(chunk,env)
    local api=chunk()({State=state,Mobs=data,MobData=function(mob)return data[mob]end,
        Hold=function(point,_,force)
            if force or (root.Position-point).Magnitude>1.25 then root.Position=point end
        end,Release=function()end,Status=function()end})
    api.Update()
    assert(state.BlackoutTarget==near and state.FollowTarget==near and not state.Dodging,
        "Survive for still permits attacking near the light")
    assert((root.Position-part.Position).Magnitude<=15.01,"Attack positions stay in the inner half of the light")
    orb.LightDuration=21;at+=.2;api.Update()
    assert(not state.BlackoutTarget and state.Dodging and (root.Position-part.Position).Magnitude==0,
        "Drop enemies just outside the shrinking native radius even before the visual catches up")
    data[near].Root.Position=v(58,73,0);at+=.2;api.Update()
    assert(state.BlackoutTarget==near and (root.Position-part.Position).Magnitude<=10.51,
        "Reacquire only inside the light and stay well inside the new radius")
    orb.LightDuration=3;at+=.2;api.Update()
    assert(not state.BlackoutTarget and state.Dodging and (root.Position-part.Position).Magnitude==0,
        "Wait at the light when the enemy is too far")
    data[near].Root.Position=v(42,73,0);at+=.2;api.Update()
    assert(state.BlackoutTarget==near and not state.Dodging and (root.Position-part.Position).Magnitude==0,
        "Fight at the center to feed a nearly empty light")
    orb.LightDuration=.5;root.Position=v(40.9,73,0);at+=.2;api.Update()
    assert((root.Position-part.Position).Magnitude==0,"Recenter immediately even when only a fraction of a stud outside")
    local previous=root.Position
    light.Enabled=false;at+=.2;api.Update()
    assert(root.Position==previous and not state.BlackoutTarget and state.Dodging,"Do not move toward an unlit gate")
    world.DarknerOrb=nil;at+=.2;api.Update()
    assert(root.Position==previous and state.Dodging,"Do not use an unconfirmed fallback teleport")
    attrs.WaveDefenseEnvironment="Default";at+=.2;api.Update()
    assert(not api.Active and not state.BlackoutTarget and not state.Dodging,"Resume regular movement after Darkness")
    print("PASS Darkness: inside-light targets, inner-radius holds, shrinking light, missing light and clean release")
end
