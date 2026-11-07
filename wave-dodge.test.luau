return function(source)
    local vector={}
    local function v(x,y,z)return setmetatable({X=x,Y=y,Z=z},vector)end
    function vector.__index(a,key)
        if key=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end
    end
    function vector.__sub(a,b)return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    local function child(a,key)return a[key]end
    local state={Running=true,AutoFarm=true,Enabled=true,AutoDodge=true,SkillAura=true,FollowTarget={FindFirstChild=child}}
    local attrs={Wave=58,WaveDefenseEnvironment="Blackout",CountdownNote="Survive for"}
    local world={FallenPartsDestroyHeight=-500,FindFirstChild=child,GetAttribute=function(_,key)return attrs[key]end}
    local root={Position=v(100,73,0),Size=v(2,2,2)}
    local character={HumanoidRootPart=root,Humanoid={HipHeight=2},Entity={Health={Value=100},FindFirstChild=child},
        FindFirstChild=child,FindFirstChildOfClass=child}
    local at=1
    local pending,placed,releases=nil,false,0
    local env=setmetatable({Vector3={new=v},workspace=world,game={JobId="test",Players={LocalPlayer={Character=character,UserId=1}}},
        getgenv=function()return {}end,os={clock=function()return at end}},{__index=getfenv()})
    local chunk=assert(loadstring(source));setfenv(chunk,env)
    local api=chunk()({State=state,MobData=function()error("Darkness must not look up enemies")end,
        Hold=function(point,_,force)
            if force or (root.Position-point).Magnitude>1.25 then pending=point end
            if placed and pending then root.Position=pending;pending=nil end
        end,Release=function()releases+=1 end,Status=function()end})
    api.Update()
    assert(state.BlackoutHolding and state.Dodging and not state.FollowTarget,"Pause combat while placement is pending")
    assert(pending.X==12 and pending.Y==37 and pending.Z==3,"Use the exact supplied position")
    placed=true;at+=.2;api.Update()
    assert(api.Active and state.BlackoutHolding and state.SkillAura and not state.Dodging,
        "Allow Skill Aura after placement even at 5 FPS")
    local shelter=root.Position
    attrs.WaveProgressLeft=15;at+=.2;api.Update()
    assert(root.Position==shelter and pending==nil and api.Moves==1 and not state.FollowTarget,
        "Enemies and wave objectives cannot move the player off the shelter")
    attrs.WaveDefenseEnvironment="Default";at+=.2;api.Update()
    assert(not api.Active and not state.BlackoutHolding and not state.Dodging and releases==1,
        "Resume regular movement after Darkness")
    print("PASS Darkness: fixed XYZ, delayed placement at 5 FPS, skill availability, no enemy following and clean release")
end
