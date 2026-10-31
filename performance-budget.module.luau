return function(state)
    local nextUpdate,pressureUntil=0,0
    local api={}
    function api.Update(now)
        now=now or os.clock()
        if now<nextUpdate then return end
        nextUpdate=now+1
        local pressure=(state.AverageFrameTime or 1/60)>1/45 or (state.PingMs or 0)>300
            or (state.AverageLoopCost or 0)>.002
        if pressure then pressureUntil=now+3 end
        local limited=now<pressureUntil
        state.FrameRequestCap=limited and 2 or 4
        state.MaxRequestsPerSecond=limited and 24 or 48
        state.NetworkPressureLimited=limited
    end
    api.Update()
    return api
end
