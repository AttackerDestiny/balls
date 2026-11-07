return function(source)
    local make=assert(loadstring(source))()
    local paused=true
    local operations=0
    local state={SafeMode=true,Running=true,SafeFloorId=1}
    local outsider={UserId=2}
    local function operation()operations+=1 end
    local search={Active=false,Outcome="Safe",Status="ready",Start=function()operations+=1;return true end,Update=operation,Stop=operation}
    local api=make({State=state,Search=search,Suspended=function()return paused end,
        CurrentFloor=function()return 1 end,Players=function()return {outsider}end,Allowed=function()return false end,
        Travelling=function()return false end,Panic=operation,ReleasePanic=operation,Status=operation,Save=operation})
    api.Update();api.Joined(outsider);api.ObserveProtected()
    assert(operations==0 and not api.Seeking and state.SafePendingUserId==nil,"A suspended floor cannot start protection, block or native travel")
    paused=false;api.Update()
    assert(operations>0 and api.Seeking,"Safe Mode resumes ordinary behavior when the adapter no longer suspends it")
    print("PASS Safe Mode suspension: entry waits never dispatch protection or travel")
end
