return function(source)
    local make=assert(loadstring(source))()
    local now,cancelled,recovered,ran=0,0,0,0
    local allowCancel=true
    local state={Running=true}
    local api=make({State=state,Now=function()return now end,Thread=coroutine.running,
        Cancel=function()cancelled+=1;return allowCancel end,
        RecoverFrame=function()recovered+=1 end,
        RecoverTravel=function(serial)assert(serial==state.TravelSerial);state.TravelSerial+=1;state.TravelBusy=false;state.TravelStartedAt=nil end,
        RecoverSkill=function()state.ActiveSkillCast=nil;state.SkillCastRunning=false end})
    local function blocked()
        local co=coroutine.create(function()api.Run(function()coroutine.yield()end)end)
        assert(coroutine.resume(co));return co
    end
    blocked();now=7;assert(api.Run(function()ran+=1 end)==nil and ran==0,"A pending frame cannot overlap another update")
    now=9;state.SafeModePanic=true;api.Run(function()ran+=1 end)
    assert(cancelled==0,"Protection waits must not be mistaken for a recoverable stall")
    state.SafeModePanic=false
    assert(api.Run(function()ran+=1 end)and ran==1 and recovered==1 and cancelled==1,"An expired frame is cancelled before normal work resumes")
    assert(state.FrameCompletedAt==now and state.CoordinatorRecoveries==1)
    blocked();now=18;allowCancel=false;assert(api.Run(function()ran+=1 end)==nil and ran==1,"Failed cancellation cannot start duplicate sends")
    now=19;api.Run(function()ran+=1 end);assert(cancelled==2,"Cancellation failures have bounded retry pacing")
    allowCancel=true;now=24;assert(api.Run(function()ran+=1 end)and ran==2)
    state.TravelBusy=true;state.TravelStartedAt=25;state.TravelSerial=1
    api.CheckPending(44);assert(state.TravelBusy,"Ordinary streaming trips retain their deadline")
    state.StopEverything=true;api.CheckPending(50);assert(state.TravelBusy,"User pause cannot trigger recovery")
    state.StopEverything=false;api.CheckPending(50);assert(not state.TravelBusy and state.TravelSerial==2 and state.TravelRecoveries==1)
    state.ActiveSkillCast={RecoveryDeadline=60};state.SkillCastRunning=true
    api.CheckPending(59);assert(state.SkillCastRunning,"Valid native skill windows must finish normally")
    api.CheckPending(60);assert(not state.SkillCastRunning and state.SkillRecoveries==1,"A hung skill worker must release its movement gate")
    now=61;blocked();api.Destroy();api.Destroy()
    assert(api.Run(function()ran+=1 end)==nil and ran==2,"Disposed runtimes cannot restart work")
    print("PASS Runtime recovery: suspended frames, exclusive cancellation, retry bounds, travel expiry, skill expiry, pause protection and cleanup")
end
