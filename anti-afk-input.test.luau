return function(source,idleSource)
    local make=assert(loadstring(source))()
    local function fixture()
        local f={Calls={},Inputs=0,Frames=0}
        local function record(method)f.Calls[#f.Calls+1]=method end
        local point,frame={},{}
        f.Input={
            CaptureController=function()record("Capture");if f.CaptureFails then error("Capture denied")end end,
            ClickButton2=function(_,p,c)
                assert(p==point and c==frame);record("Click")
                if f.ClickFails then error("Click denied")end
            end,
            Button2Down=function(_,p,c)
                assert(p==point and c==frame);record("Down")
                if f.PressFails then error("Press denied")end
            end,
            Button2Up=function(_,p,c)
                assert(p==point and c==frame);record("Up")
                if f.ReleaseFails then error("Release denied")end
            end}
        f.Pulse=make({Input=function()f.Inputs+=1;return f.Input end,Point=function()return point end,
            Frame=function()f.Frames+=1;return frame end,
            Wait=function(duration)assert(duration==.05);record("Wait");if f.OnWait then f.OnWait()end end})
        return f
    end
    local f=fixture()
    assert(f.Inputs==0 and #f.Calls==0,"Built-in setup must not send input or acquire services before idle")
    assert(f.Pulse()=="VirtualUser ClickButton2"and table.concat(f.Calls,",")=="Capture,Click")
    f=fixture();f.ClickFails=true;f.CaptureFails=true
    assert(f.Pulse()=="VirtualUser Button2Down/Up"and table.concat(f.Calls,",")=="Capture,Click,Down,Wait,Up"
        and f.Frames==1,"One idle pulse snapshots the camera once and releases the fallback press")
    f=fixture();f.ClickFails=true;f.PressFails=true
    assert(not pcall(f.Pulse)and table.concat(f.Calls,",")=="Capture,Click,Down,Up",
        "An errored partial press still sends release and cannot report success")
    f=fixture();f.ClickFails=true;f.ReleaseFails=true
    local ok,reason=pcall(f.Pulse)
    assert(not ok and tostring(reason):find("Release denied",1,true),"Release failure stays visible to idle protection")

    local connectCount,disconnectCount,listener=0,0,nil
    local state={Running=true}
    local at=0
    local idleMake=assert(loadstring(idleSource))()
    f=fixture();f.ClickFails=true
    local api=idleMake({State=state,Player={Idled={Connect=function(_,callback)
        connectCount+=1;listener=callback;return {Disconnect=function()disconnectCount+=1 end}
    end}},Clock=function()return at end,Pulse=f.Pulse})
    f.OnWait=function()coroutine.yield()end
    local thread=coroutine.create(listener)
    assert(coroutine.resume(thread))
    assert(coroutine.status(thread)=="suspended")
    listener()
    assert(#f.Calls==4,"A repeated event cannot overlap a held input")
    api.Destroy();assert(coroutine.resume(thread))
    assert(f.Calls[#f.Calls]=="Up"and api.Pulses==0 and state.AntiAfkStatus=="Stopped"
        and connectCount==1 and disconnectCount==1,
        "Reload during a pulse still releases input without reviving old bookkeeping or listeners")
    print("PASS Built-in Anti AFK input: lazy services, executor fallback, paired release, errors and reload cleanup")
end
