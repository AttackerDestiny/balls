return function(moduleSource)
    local state={AverageFrameTime=1/60,PingMs=70,AverageLoopCost=.0002}
    local api=assert(loadstring(moduleSource))()(state)
    local now=os.clock()+2
    api.Update(now)
    assert(state.FrameRequestCap==4 and state.MaxRequestsPerSecond==48,"Normal frames must spread requests across four-request batches")
    state.PingMs=350; api.Update(now+1)
    assert(state.FrameRequestCap==2 and state.MaxRequestsPerSecond==24,"High latency must reduce outgoing pressure")
    state.PingMs=70; api.Update(now+2)
    assert(state.NetworkPressureLimited,"Retain a recovery interval instead of oscillating budgets")
    api.Update(now+5)
    assert(not state.NetworkPressureLimited and state.FrameRequestCap==4,"Restore normal throughput after recovery")
    state.AverageFrameTime=1/30; api.Update(now+6)
    assert(state.FrameRequestCap==2,"Frame pressure must also spread the load")
    return {Passed=true,LatencyBackoff=true,RecoveryHysteresis=true,FrameBackoff=true}
end
