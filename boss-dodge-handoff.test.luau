return function(source)
    local mt={}
    local function v(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    function mt.__sub(a,b)return v(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    function mt.__index(a,key)if key=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
    local function child(a,key)return a[key]end
    local root={Position=v(100,-20,0)}
    local target={HumanoidRootPart={Position=v(0,0,0)},FindFirstChild=child}
    local attrs={Wave=100,WaveDefenseEnvironment="Default"}
    local world={FallenPartsDestroyHeight=-500,FindFirstChild=child,GetAttribute=function(_,key)return attrs[key]end}
    local character={HumanoidRootPart=root,Humanoid={},Entity={Health={Value=100},FindFirstChild=child},
        FindFirstChild=child,FindFirstChildOfClass=child}
    local state={Running=true,AutoFarm=true,AutoDodge=true,FollowTarget=target,AutoOffsetTarget=target,
        AutoOffsetDestination=v(0,5,0),SkillCastRunning=true,ActiveSkillCast={}}
    local cancelled,released,holds=0,0,0
    function state.CancelSkillAura()
        assert(state.Dodging,"Dodge ownership must be set before releasing a moving cast")
        cancelled+=1;state.ActiveSkillCast=nil;state.SkillCastRunning=false
    end
    local at,planned,status=1,nil,nil
    local boss={Plan=function(point,desired)
        assert(desired==state.AutoOffsetDestination,"Check the real farm return position, including its height")
        return planned,"Slam"
    end}
    local chunk=assert(loadstring(source))
    setfenv(chunk,setmetatable({Vector3={new=v},workspace=world,game={JobId="test",Players={LocalPlayer={Character=character,UserId=1}}},
        getgenv=function()return {}end,os={clock=function()return at end}},{__index=getfenv()}))
    local api=chunk()({State=state,BossDodge=boss,Hold=function(point)
        assert(not state.SkillCastRunning and not state.ActiveSkillCast,"Owned casts cannot drag the player out of shelter")
        root.Position=point;holds+=1
    end,Release=function()released+=1 end,Status=function(value)status=value end})
    planned=v(50,5,0);boss.Blocked=true
    api.Update()
    assert(cancelled==1 and state.Dodging and api.Active and holds==1,"A destination hazard holds the farm even when the current position is safe")
    at+=.1;api.Update()
    assert(cancelled==1 and released==0,"Keep shelter ownership for the whole hazard, without repeatedly cancelling")
    planned=nil;boss.RequiresCover=true;boss.LastReason="Nuke · waiting for clear pillar cover"
    function api.BlackoutPoint()error("A Nuke requires pillar cover, never a fabricated below-map escape")end
    at+=.1;api.Update()
    assert(state.Dodging and api.Active and status==boss.LastReason,"A pending Nuke shelter cannot release Auto Farm")
    boss.Blocked=false;boss.RequiresCover=false;at+=.1;api.Update()
    assert(not state.Dodging and not api.Active and released==1,"Resume immediately once danger expires")
    state.AutoDodge=false;state.SkillCastRunning=true;state.ActiveSkillCast={};planned=v(50,5,0)
    at+=.1;api.Update()
    assert(cancelled==1 and not api.Active,"A disabled dodge cannot cancel skills or move a client")
    print("PASS Boss dodge handoff: actual farm destination, owned cast cancellation, pending cover and clean resume")
end
