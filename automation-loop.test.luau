return function(helpers,source)
    local function fixture(overrides)
        local f={Now=1000,Ticks=0,Limit=4,SafeUpdates=0,MultiUpdates=0,Paints=0,Failures=0,Workers={},Queues=0,Menus=0}
        local state={Running=true,SafeMode=true,MultiSpot=true,AutoFarm=true,Enabled=true,
            SafeFloorId=134019705603409,AutoJoinFriend=false,AccountProgression=false}
        for key,value in pairs(overrides or {})do state[key]=value end
        state.SaveNow=function()return true end
        state.QueueAutomation=function()f.Queues+=1;if f.QueueFail then error("Queue unavailable")end end
        local fallback={Armed=false,Update=function()end}
        local environment={state=state,kickFallback=fallback,game={JobId="fixture"},
            TeleportService={Teleport=function(_,id)
                assert(id==659222129 and f.Queues>0);f.Menus+=1
                if f.MenuFail then error("Menu unavailable")end
            end},
            os={clock=function()return f.Now end,time=function()return f.Now end},
            getgenv=function()return {}end,workerIdentity=function()end,readTicket=function()end,
            api={Active=false},farmClock=function()return f.Now end,
            friend={Update=function()end},
            safe={Update=function()f.SafeUpdates+=1;if f.OnSafe then f.OnSafe()end end},
            multi={Update=function()f.MultiUpdates+=1 end},
            fail=function()
                f.Failures+=1;state.AutomationTeleporting=false
                if f.FailHandler then error("Failure handler unavailable")end
            end,
            refresh=function()f.Paints+=1;if f.Paints==1 and f.FailPaint then error("UI unavailable")end end,
            task={spawn=function(fn)f.Workers[#f.Workers+1]=fn end,
                wait=function(dt)f.Now+=dt;f.Ticks+=1;if f.Ticks>=f.Limit then state.Running=false end end}}
        local chunk=assert(loadstring(helpers.."\n"..source))
        setfenv(chunk,setmetatable(environment,{__index=getfenv()}));chunk()
        function f.Run()f.Workers[1]()end
        f.State=state;f.Fallback=fallback
        return f
    end
    local rest=fixture({AntiSuspiciousRestUntil=1060})
    rest.Run()
    assert(rest.SafeUpdates==0 and rest.MultiUpdates==0 and rest.State.AntiSuspiciousRestUntil==1060,
        "Saved account rest must keep both protection and farming suspended")
    assert(rest.Menus==1 and rest.Queues==1,"A rest restored inside a floor must return to the Start menu")
    assert(rest.State.SafeModeStatus:find("Anti Suspicious rest",1,true)
        and rest.State.MultiSpotStatus==rest.State.SafeModeStatus and rest.State.MultiSpotStatus:find("1:00",1,true),
        "A saved rest must publish its countdown instead of leaving the starting-arena placeholder")
    local unavailable=fixture({AntiSuspiciousRestUntil=2000});unavailable.MenuFail=true;unavailable.Limit=1000
    unavailable.Run()
    assert(unavailable.Menus==3 and unavailable.SafeUpdates==0 and unavailable.MultiUpdates==0
        and unavailable.State.MultiSpotStatus:find("Start menu unavailable",1,true),
        "A restored rest retries a failed menu entry at most three times and retains its hold")
    local expires=fixture({AntiSuspiciousRestUntil=1000.15})
    expires.OnSafe=function()assert(expires.Now>=1000.15)end
    expires.Run()
    assert(not expires.State.AntiSuspiciousRestUntil and expires.SafeUpdates>0 and expires.MultiUpdates>0,
        "An expired rest resumes both controllers without changing saved feature intent")
    local pending=fixture({AntiSuspiciousRestUntil=999,SafeKickFallbackStatus="Fallback rejoin unavailable · rejoin manually"})
    pending.Fallback.Armed=true;pending.Run()
    assert(pending.SafeUpdates==0 and pending.MultiUpdates==0 and pending.State.AntiSuspiciousRestUntil==999
        and pending.State.MultiSpotStatus==pending.State.SafeKickFallbackStatus,
        "An armed rejoin keeps its hold and preserves the useful failure message after rest ends")
    local paint=fixture();paint.FailPaint=true;paint.Run()
    assert(paint.SafeUpdates==4 and paint.MultiUpdates==4 and not paint.State.LastAutomationUIError,
        "A temporary status-UI exception cannot kill the shared automation worker")
    local failure=fixture();failure.FailHandler=true
    failure.OnSafe=function()if failure.SafeUpdates==1 then error("Temporary controller error")end end
    failure.Run()
    assert(failure.SafeUpdates==4 and failure.MultiUpdates==3 and failure.State.LastAutomationError,
        "A secondary failure while reporting an update error cannot permanently stop automation")
    local teleport=fixture({AutomationTeleporting=true})
    teleport.Run()
    assert(teleport.Failures==1 and teleport.SafeUpdates==4 and teleport.MultiUpdates==4,
        "A missing teleport deadline must enter controlled recovery instead of killing the worker")
    local regroup=fixture({AutoRegroupHolding=true})
    regroup.Run()
    assert(regroup.SafeUpdates==0 and regroup.MultiUpdates==0 and regroup.State.MultiSpotStatus:find("Auto Regroup",1,true))
    print("PASS Automation loop: visible saved-rest countdown, automatic expiry, protected rejoin holds, UI/controller failures and teleport recovery")
end
