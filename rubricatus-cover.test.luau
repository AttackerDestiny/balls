return function(source)
    local mt={}
    local function v(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    function mt.__add(a,b)return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    function mt.__sub(a,b)return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    function mt.__mul(a,b)
        if type(b)=="number"then return v(a.X*b,a.Y*b,a.Z*b)end
        return v(a.X*b.X,a.Y*b.Y,a.Z*b.Z)
    end
    function mt.__index(a,key)
        local length=math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)
        if key=="Magnitude"then return length end
        if key=="Unit"then return v(a.X/length,a.Y/length,a.Z/length)end
    end
    local function frame(position,rotated)
        return {Position=position,RightVector=rotated and v(0,0,1)or v(1,0,0),UpVector=v(0,1,0),
            LookVector=rotated and v(-1,0,0)or v(0,0,-1),PointToObjectSpace=function(_,point)
                local d=point-position;return rotated and v(d.Z,d.Y,-d.X)or d
            end}
    end
    local at,final,queries,connected=1,false,0,0
    local bossOrigin=v(0,0,0)
    local receive
    local signal={Connect=function(_,fn)
        receive=fn;connected+=1
        return {Disconnect=function()receive=nil;connected-=1 end}
    end}
    local parts={}
    local function pillar(x,y,z,rotated)
        local point=v(x,y,z)
        return {Parent=true,CanCollide=true,Position=point,CFrame=frame(point,rotated),Size=v(16,30,16)}
    end
    local state={AutoDodge=true}
    local chunk=assert(loadstring(source))
    setfenv(chunk,setmetatable({Vector3={new=v},typeof=function(value)return getmetatable(value)==mt and "Vector3"or type(value)end},{__index=getfenv()}))
    local collision=true
    local api=chunk()({State=state,Now=function()return at end,Replicate=signal,FinalWave=function()return final end,
        Origin=function()return bossOrigin end,Pillars=function()queries+=1;return parts end,
        Covered=function()return collision end})
    local function safe()return true end
    receive(nil,"Initial","RubricatusNuke",v(0,0,0))
    assert(not api.Plan(v(0,-20,0),safe)and not api.Active and queries==0,"Never run Nuke scans outside wave 100")
    final=true
    assert(not api.Plan(v(0,-20,0),safe)and not api.Active,"Ordinary final-wave farming must not wait for a Nuke")
    receive(nil,"Initial","RubricatusNuke",v(0,0,0))
    assert(not api.Plan(v(0,-20,0),safe)and api.Active and api.Waiting,"Keep farm ownership while pillars are still rising")
    local marker=pillar(115,0,0);marker.Size=v(2,1,2)
    local underground=pillar(115,-40,0)
    local ghost=pillar(115,10,0);ghost.CanCollide=false
    local decoration=pillar(350,10,0)
    parts={marker,underground,ghost,decoration};at+=.11
    assert(not api.Plan(v(0,-20,0),safe)and api.Waiting,"Markers, underground and noncollidable pillars cannot shield a Nuke")
    local right,left=pillar(115,10,0,true),pillar(-115,10,0)
    parts={right,left};at+=.11
    bossOrigin=v(500,0,0)
    local point=api.Plan(v(110,3,0),safe)
    assert(point and point.X>123 and point.Y==3 and math.abs(point.Z)<.01,"Use the replicated blast origin even if the boss subsequently moves")
    bossOrigin=v(0,0,0)
    local queriesBefore=queries
    at+=.02
    assert(api.Plan(v(20,3,0),safe)==point and queries==queriesBefore,"Hold cover without scanning on every frame")
    local alternative=api.Plan(point,function(p)return p.X<0 end)
    assert(alternative and alternative.X< -123,"A simultaneous ground warning must invalidate that pillar shelter")
    collision=false
    assert(not api.Plan(point,safe)and api.Waiting,"The actual part must block the blast ray; a bounding box alone is insufficient")
    collision=true
    state.AutoDodge=false
    assert(not api.Plan(point,safe)and not api.Active,"Respect the existing Auto Dodge toggle")
    state.AutoDodge=true
    assert(api.Plan(point,safe),"Enabling during the same Nuke can acquire live cover")
    right.Parent=nil;left.Parent=nil;at+=.11
    assert(not api.Plan(point,safe)and api.Active,"Preserve a short impact tail when pillars disappear")
    at+=.21
    assert(not api.Plan(point,safe)and not api.Active,"Return to farming after the pillar collapse tail")
    receive(nil,"Initial","RubricatusNuke",v(0,0,0));at+=13
    assert(not api.Plan(point,safe)and not api.Active,"A lost cast or missing geometry must never create an indefinite hold")
    right.Parent=true;parts={right};at+=.11
    assert(api.Plan(point,safe),"Discover an already raised pillar when a client missed the initial cast")
    final=false
    assert(not api.Plan(point,safe)and not api.Active,"Round transitions retire cover")
    final=true;parts={};at+=.11
    assert(not api.Plan(point,safe)and not api.Active,"An old Nuke cannot leak into a retry")
    api.Destroy();api.Destroy()
    assert(connected==0,"Cleanup disconnects the observer exactly once")
    queriesBefore=queries
    assert(not api.Plan(point,safe)and queries==queriesBefore,"A retired controller cannot scan or hold movement")
    print("PASS Rubricatus Nuke: real pillar cover, rise/collapse, concurrent hazards, scope, bounded waits and cleanup")
end
