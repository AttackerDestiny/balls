return function(source)
    local vector={}
    local function v(x,y,z)
        return setmetatable({X=x,Y=y,Z=z,Magnitude=math.sqrt(x*x+y*y+z*z)},vector)
    end
    vector.__add=function(a,b)return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    vector.__sub=function(a,b)return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    local attributes={WaveDefenseArea="Lava",MobsLeft=15,CountdownNote="Survive for"}
    local root={Position=v(0,0,0),Size=v(2,2,2)}
    local health={Value=100}
    local entity={FindFirstChild=function(_,name)if name=="Health" then return health end end}
    local character={
        FindFirstChild=function(_,name)return name=="Entity" and entity or root end,
        FindFirstChildOfClass=function()return {HipHeight=2}end,
    }
    local light={Range=15,Enabled=true}
    local part={Position=v(14,73,2),FindFirstChildOfClass=function()return light end}
    local orb={FindFirstChild=function()return part end}
    local workspace={
        FallenPartsDestroyHeight=-500,
        GetAttribute=function(_,key)return attributes[key]end,
        FindFirstChild=function(_,key)if key=="DarknerOrb" then return orb end end,
    }
    local now=1
    local chunk=assert(loadstring(source))
    setfenv(chunk,setmetatable({workspace=workspace,Vector3={new=v},os={clock=function()return now end},
        game={Players={LocalPlayer={Character=character,UserId=1}}},getgenv=function()return {}end},{__index=getfenv()}))
    local mob={}
    local mobRoot={Position=v(100,73,2),Size=v(2,2,2)}
    local state={Running=true,AutoDodge=true,AutoFarm=true,Enabled=true}
    local api=chunk()({State=state,Mobs={[mob]=true},MobData=function()return {Root=mobRoot,Health=health,Entity=entity}end,
        Hold=function(point)root.Position=point end,Release=function()end,Status=function()end})
    local function step()now+=.1;api.Update()end
    step()
    assert(state.Dodging and root.Position.X==10 and root.Position.Y==-19 and root.Position.Z==-5)
    attributes.WaveDefenseArea="Darkness";step()
    assert(state.Dodging and not state.BlackoutTarget and root.Position.Y==73)
    attributes.CountdownNote=nil;attributes.WaveProgressLeft=10;step()
    assert(state.Dodging and not state.BlackoutTarget,"Wait for an enemy to enter the white light")
    mobRoot.Position=v(14,70,2);step()
    assert(not state.Dodging and state.BlackoutTarget==mob and root.Position.Y>70)
    attributes.WaveDefenseArea="Horde";step()
    assert(not state.Dodging and not state.BlackoutTarget,"Kill objectives must release the shelter")
    print("PASS Wave shelters: fixed Lava and Darkness positions, native survival note, light-gated combat and kill objectives")
end
