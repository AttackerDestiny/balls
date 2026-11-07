return function(source)
    local vec={}
    local function v(x,y,z)return setmetatable({X=x,Y=y,Z=z},vec)end
    function vec.__add(a,b)return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    function vec.__sub(a,b)return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    function vec.__mul(a,b)return v(a.X*b,a.Y*b,a.Z*b)end
    function vec.__div(a,b)return a*(1/b)end
    local function dot(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
    function vec.__index(a,k)
        if k=="Dot"then return dot end
        if k=="Magnitude"then return math.sqrt(dot(a,a))end
        if k=="Unit"then return a/a.Magnitude end
    end
    local function frame(pos)
        return {Position=pos,PointToObjectSpace=function(_,point)return point-pos end,
            RightVector=v(1,0,0),UpVector=v(0,1,0),LookVector=v(0,0,-1)}
    end
    local function signal()
        return {Connect=function(s,fn)
            s.Fire=function(_,...)fn(...)end
            return {Disconnect=function()s.Fire=nil end}
        end}
    end
    local tags={}
    local collection={GetTagged=function()return {}end,GetInstanceAddedSignal=function(_,name)
        tags[name]=signal();return tags[name]
    end}
    local function child(parent,name)return parent[name]end
    local world={DescendantAdded=signal(),QueryDescendants=function()return {}end,FindFirstChild=child}
    local replicate=signal()
    local at,final=1,false
    local chunk=assert(loadstring(source))
    setfenv(chunk,setmetatable({os={clock=function()return at end},Vector3={new=v,zero=v(0,0,0)},
        Enum={PartType={Cylinder="Cylinder"}},Color3={fromRGB=function()return "Red"end},
        typeof=function(x)return getmetatable(x)==vec and "Vector3"or type(x)end},{__index=getfenv()}))
    local api=chunk()({State={AutoDodge=true},Workspace=world,Collection=collection,Replicate=replicate,
        FinalWave=function()return final end,RubricatusOrigin=function()return v(0,0,0)end})
    local discs={Name="RedLightningDiscEffects"}
    local function disc(number,position)
        local o={Name="LightningDisc"..number,Parent=discs,IsA=function(_,kind)return kind=="Model"end,
            PrimaryPart={CFrame=frame(position),Size=v(1,1,1)},GetAttribute=child}
        world.DescendantAdded:Fire(o);return o
    end
    local first=disc(1,v(-20,0,0));first.LockedTarget=v(30,0,0)
    api.RefreshThreats();assert(not api.IsThreatened(v(30,0,0)),"Wave 100 effects are ignored before Wave 100")
    final=true
    first=disc(1,v(-20,0,0))
    api.RefreshThreats();assert(not api.IsThreatened(v(-20,0,0)),"Unlaunched discs are harmless")
    first.LockedTarget=v(30,0,0)
    api.RefreshThreats();assert(api.IsThreatened(v(30,0,0)) and not api.IsThreatened(v(30,-20,0)))
    first.LockedTarget=nil;api.RefreshThreats()
    assert(not api.IsThreatened(v(30,0,0)),"An invalid or reset projectile must discard its old locked position")
    first.LockedTarget=v(30,0,0);api.RefreshThreats()
    at+=.2;first.PrimaryPart.CFrame=frame(v(-10,0,0));api.RefreshThreats()
    assert(api.IsThreatened(v(3,0,0)),"Predict the moving hitbox along its current path")
    local nextDisc=disc(2,v(-20,0,0));nextDisc.LockedTarget=v(42,0,20)
    api.RefreshThreats();assert(api.IsThreatened(v(42,0,20)),"Each shot can lock onto a different position")
    assert(api.Plan(v(42,0,20),v(42,0,20)),"Leave the latest landing point")
    first.Parent=nil;nextDisc.Parent=nil;api.RefreshThreats();at+=1

    local laser={Name="RedBeam",Parent={Name="RedLightningLaserEffects"},CFrame=frame(v(0,12,0)),
        Size=v(50,10,10),Shape="Cylinder",IsA=function(_,kind)return kind=="BasePart"end}
    world.DescendantAdded:Fire(laser);api.RefreshThreats()
    assert(api.IsThreatened(v(20,12,0)) and not api.IsThreatened(v(20,-12,0)),"Use the laser's actual axis and elevation")
    local charge={Name="LockedAimWarning",Parent=laser.Parent,CFrame=frame(v(0,12,0)),Size=v(100,1,10),IsA=laser.IsA}
    world.DescendantAdded:Fire(charge);api.RefreshThreats()
    assert(api.IsThreatened(v(45,12,0)),"Evade during the one-second laser charge before the cylinder appears")
    charge.Parent=nil
    laser.Parent=nil;api.RefreshThreats();at+=1
    replicate:Fire(1,"Initial","RedLightningWave",1.7,v(50,0,0));api.RefreshThreats()
    assert(api.IsThreatened(v(25,2,0)) and not api.IsThreatened(v(-25,2,0)),"Use the cone's replicated direction")
    assert(api.IsThreatened(v(65,2,60))and not api.IsThreatened(v(115,2,0)),"Use the native 100-stud range and 120-degree cone when attributes are absent")
    at+=1.5;api.RefreshThreats();assert(not api.IsThreatened(v(25,2,0)),"Use the native short charge/expansion/fade to release farming")
    local hitbox={Name="Box",Parent=world,CFrame=frame(v(0,0,0)),Size=v(16,8,6),IsA=laser.IsA,GetAttribute=child,Lifetime=.3}
    tags["RubricatusSlam Slam"]:Fire(hitbox);api.RefreshThreats()
    assert(api.IsThreatened(v(5,0,0)) and not api.IsThreatened(v(5,-20,0)),"Use the tagged melee hitbox")
    at+=.6;api.RefreshThreats()
    assert(not api.IsThreatened(v(5,0,0)),"A finished melee warning cannot stall farming while its part is retained")
    for index=1,1000 do disc(index,v(0,0,0)).LockedTarget=v(30,0,0)end
    api.RefreshThreats();assert(api.ThreatCount<=48,"Burst effects have bounded storage")
    final=false;api.RefreshThreats()
    assert(api.ThreatCount==0 and not api.IsThreatened(v(30,0,0)),"Final-wave hazards cannot leak into a new room or retry")
    api.Destroy()
    assert(not world.DescendantAdded.Fire and not replicate.Fire,"Cleanup disconnects world and skill listeners")
    print("PASS Rubricatus: wave scope, disc resets and prediction, laser charge, native cone defaults, melee expiry and cleanup")
end
