return function(source)
    local mt={}
    local function v(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    function mt.__sub(a,b)return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    function mt.__index(a,key)if key=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
    local function child(a,key)return a[key]end
    local attrs={Wave=8,WaveDefenseEnvironment="Lava",CountdownNote="Survive for"}
    local origin={Position=v(0,27,0)}
    local container={WaveDefenseOrigin=origin,FindFirstChild=child}
    local root={Position=v(10,-19,-5)}
    local health={Value=100}
    local character={HumanoidRootPart=root,Humanoid={},Entity={Health=health,FindFirstChild=child},
        FindFirstChild=child,FindFirstChildOfClass=child}
    local player={Character=character,UserId=1}
    local floorHit={Position=v(0,27,0),Normal=v(0,1,0)}
    local world={WaveDefenseStuff=container,FallenPartsDestroyHeight=-500,FindFirstChild=child,
        GetAttribute=function(_,key)return attrs[key]end,Raycast=function()return floorHit end}
    local state={Running=true,AutoDodge=true,AutoFarm=true,PerformanceBoosters={}}
    local at=1
    local stored,writes,connected=nil,0,0
    local receive
    local signal={Connect=function(_,fn)receive=fn;connected+=1;return {Disconnect=function()receive=nil;connected-=1 end}end}
    local nativeDanger=true
    local boss={Blocked=false,Destroy=function()end,Plan=function(point,desired)
        assert(desired.Y==-19,"Survival planning must check its below-map shelter")
        if nativeDanger then return v(70,-19,-5)end
    end}
    local chunk=assert(loadstring(source))
    local globals={Vector3={new=v},workspace=world,game={PlaceId=78945654064532,JobId="test",Players={LocalPlayer=player},
        GetService=function()return {JSONEncode=function(_,value)stored=value;return "audit"end}end},
        getgenv=function()return {}end,os={clock=function()return at end},isfile=function()return false end,
        isfolder=function()return true end,writefile=function()writes+=1 end,
        RaycastParams={new=function()return {}end},Enum={RaycastFilterType={Exclude="Exclude"}}}
    setfenv(chunk,setmetatable(globals,{__index=getfenv()}))
    local api=chunk()({State=state,BossDodge=boss,Replicate=signal,
        Hold=function(point)root.Position=point end,Release=function()end,Status=function()end})
    api.Update()
    assert(state.Dodging and root.Position.X==70,"A survival shelter must move out of tracked attack geometry")
    nativeDanger=false;at+=.1;api.Update()
    assert(root.Position.X==10,"Return to the normal survival shelter once clear")
    api.RecordDamage({At=at,Before=100,After=90,Position=root.Position})
    at+=.1;api.Update()
    assert((root.Position-v(10,-19,-5)).Magnitude>35,"Repeated real damage invalidates a fixed survival position even with no local warning")
    at+=4.1;api.Update()
    assert(root.Position.X==10,"A temporary damage avoidance expires without accumulating safe-position guesses")
    assert(api.FloorY(root.Position)==27)
    floorHit=nil
    assert(api.FloorY(root.Position)==27,"Reuse floor only within the same arena generation")
    origin.Position=v(0,80,0)
    assert(api.FloorY(root.Position)==80,"Moving the native origin invalidates old ground")
    floorHit={Position=v(0,20,0),Normal=v(0,1,0)};api.FloorY(root.Position)
    floorHit=nil;attrs.Wave=9
    assert(api.FloorY(root.Position)==80,"A same-environment wave replacement cannot reuse an old altitude")
    state.PerformanceBoosters["Delete map"]=true
    assert(api.FloorY(v(0,-400,0))==80,"Map deletion must use the arena origin instead of locking idle at an arbitrary falling height")
    api.Idle(v(0,-490,0))
    assert(root.Position.Y>=world.FallenPartsDestroyHeight+35 and state.IdleSafetyClamped,
        "Idle cannot bypass the kill-plane clearance guard")

    receive(nil,"Initial","RedLightningLaser",v(0,0,0))
    attrs.Wave=100;attrs.WaveDefenseEnvironment="Rubricatus"
    api.RecordDamage({At=at,Before=100,After=85,Position=root.Position})
    assert(api.RecentDamage[#api.RecentDamage].Wave==100 and api.RecentDamage[#api.RecentDamage].RecentSkill=="RedLightningLaser",
        "Record normal/final-wave damage and nearby cast context without claiming attribution")
    for n=1,100 do api.RecordDamage({At=at,Before=100,After=90,Position=root.Position})end
    assert(#api.RecentDamage==32,"Damage receipts are bounded")
    local before=writes
    api.RecordDamage({At=at,Before=90,After=0,Position=root.Position})
    assert(writes==before+1 and stored.Recent[#stored.Recent].Death,"Persist a lethal health event without waiting for the next poll")
    attrs.WaveDefenseEnvironment="Lava";attrs.Wave=10;attrs.CountdownNote="Survive for"
    at+=.1;api.Update()
    local event=api.Seen.Lava
    local damage=event.Damage
    health={Value=10};character.Entity.Health=health;at+=.1;api.Update()
    assert(event.Damage==damage,"A respawn with lower health cannot count as damage against the previous character")
    api.Destroy();api.Destroy()
    assert(connected==0,"The passive skill observer disconnects on cleanup")
    before=#api.RecentDamage;api.RecordDamage({At=at,Before=100,After=0})
    assert(#api.RecentDamage==before,"A retired runtime cannot add audit data")
    print("PASS Wave safety: survival hazards, arena cache resets, map deletion, kill plane, bounded death receipts and cleanup")
end
