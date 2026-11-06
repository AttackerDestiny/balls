-- Roblox geometry fixture, detached from native remotes and player movement.
return function(source)
    local factory=assert(loadstring(source))()
    local callback,disconnected
    local at=0
    local state={AeganatosDodge=true}
    local boss={}
    local api=factory({State=state,Now=function()return at end,
        Replicate={Connect=function(_,fn)callback=fn;return {Disconnect=function()disconnected=true end}end},
        IsBoss=function(value)return value==boss end,Frame=function()return CFrame.new()end,
        WaveSize=Vector3.new(95,38,101),GyzerRadius=62,Valid=function(p)return p.Y>-400 end})
    local origin=Vector3.new(0,0,-50)
    callback(boss,"RunPhase","OmegaWave","FireWave",Vector3.zero,200)
    local point,kind=api.Plan(origin,origin)
    assert(point and kind=="OmegaWave"and (point-origin).Magnitude<180,"Escape the complete moving plane envelope")
    assert(not api.Plan(point,point),"Safe geometry must not repeatedly displace the player")
    at=5;assert(not api.Plan(origin,origin),"Native wave timing expires bounded geometry")
    callback(boss,"RunPhase","OceanGyzer","CreateGyzer",Vector3.zero,2)
    point,kind=api.Plan(Vector3.new(0,-20,0),Vector3.new(0,-20,0))
    assert(point and kind=="OceanGyzer"and (point*Vector3.new(1,0,1)).Magnitude>=70,"Move clear of the geyser footprint")
    state.SafeModePanic=true;assert(not api.Plan(Vector3.zero,Vector3.zero),"Safety owns movement")
    state.SafeModePanic=false;api.Reset();assert(not api.Plan(Vector3.zero,Vector3.zero))
    callback({},"RunPhase","OmegaWave","FireWave",Vector3.zero,200);assert(api.Seen==2,"Unrelated enemies are excluded")
    api.Destroy();assert(disconnected)
    return {Passed=true,Wave=true,Gyzer=true,Expiry=true,Safety=true,Cleanup=true}
end
