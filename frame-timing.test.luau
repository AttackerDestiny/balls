return function(source)
    local make=assert(loadstring(source))()
    for _,fps in ipairs({10,12,15,60}) do
        local state={Enabled=true,AverageFrameTime=1/60,LagPauseUntil=0}
        local api=make(state)
        local now=0
        for i=1,600 do now+=1/fps;assert(not api.Sample(1/fps,now))end
        assert(state.LagPauseUntil==0,"Steady FPS must not lock combat")
        assert(math.abs(state.AverageFrameTime-1/fps)<.0001)
    end
    local state={SkillAura=true,AverageFrameTime=.1,LagPauseUntil=0}
    local api=make(state)
    assert(api.Sample(.8,1));assert(state.LagPauseUntil==1.5)
    for i=1,20 do assert(not api.Sample(.1,1+i*.1))end
    assert(state.LagPauseUntil<3,"Combat recovers after a hitch at 10 FPS")
    local baseline=state.AverageFrameTime
    api.Sample(0,4);api.Sample(0/0,4);api.Sample(math.huge,4)
    assert(state.AverageFrameTime==baseline)
    state.Enabled=false;state.SkillAura=false
    api.Sample(2,5);assert(state.LagPauseUntil==1.5)
    print("PASS Low FPS: 10/12/15/60 FPS, hitch recovery, invalid deltas, disabled state")
end
