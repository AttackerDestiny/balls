return function(source)
    local time,calls,listener,connected=0,0,nil,false
    local state={Running=true}
    local signal={}
    function signal:Connect(fn)
        assert(not connected,"Only one idle listener per runtime")
        listener=fn;connected=true
        return {Disconnect=function()connected=false end}
    end
    local fail,reenter,rejected=false,false,false
    local make=assert(loadstring(source))()
    local function create()
        return make({State=state,Player={Idled=signal},Clock=function()return time end,Pulse=function()
            calls+=1
            if reenter then listener()end
            if fail then error("Executor input denied")end
            if rejected then return false end
        end})
    end
    local api=create()
    assert(api.Enabled and calls==0,"Startup creates no synthetic input")
    listener();assert(calls==1 and api.Pulses==1)
    for _=1,50 do listener()end
    assert(calls==1,"Repeated idle callbacks cannot flood input")
    time=21;reenter=true;listener();assert(calls==2,"A reentrant callback cannot pulse twice")
    reenter=false;time=42;fail=true;listener()
    assert(calls==3 and api.Pulses==2 and state.LastAntiAfkError,"Permission errors must not crash the runtime")
    fail=false;time=63;listener();assert(calls==4 and api.Pulses==3 and not state.LastAntiAfkError)
    state.StopEverything=true;time=84;listener()
    assert(calls==5,"Built-in idle protection remains active while farming is paused")
    api.Destroy();api.Destroy();assert(not connected and not api.Enabled)
    time=105;listener();assert(calls==5,"A stale callback cannot send input after cleanup")
    api=create();state.Running=false;listener();assert(calls==5,"A stopped runtime cannot pulse")
    api.Destroy()
    state.Running=true;time=126;api=create();rejected=true;listener()
    assert(api.Pulses==0 and state.LastAntiAfkError=="Executor rejected idle input",
        "An explicit input rejection must not count as successful idle protection")
    api.Destroy()
    print("PASS Anti-AFK: idle-only input, pacing, reentrancy, mobile permission failure/recovery, paused farming, replacement and cleanup")
end
