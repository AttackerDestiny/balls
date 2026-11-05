return function(source)
    local retired=false
    local previous={Running=true,Destroy=function()error("partial old HUD cleanup failed")end}
    local env={}
    local fn=assert(loadstring(source))
    setfenv(fn,setmetatable({previousRuntime=previous,env=env,warn=function()end,
        runtimeOwner={Retire=function()retired=true end}},{__index=getfenv()}))
    fn()
    assert(retired and not previous.Running and env.SB2LastReplacementError:find("partial old HUD",1,true),"A failing old destructor must not strand the replacement in Loading")
    print("PASS Runtime replacement survives an old HUD cleanup exception and retires stale GUI ownership")
end
