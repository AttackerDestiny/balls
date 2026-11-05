return function(state)
    local nextUpdate,pressureUntil,severeUntil=0,0,0
    local api={}
    function api.Update(now)
        now=now or os.clock()
        if now<nextUpdate then return end
        nextUpdate=now+1
        local pressure=(state.AverageFrameTime or 1/60)>1/45 or (state.PingMs or 0)>300
            or (state.AverageLoopCost or 0)>.002
        if pressure then pressureUntil=now+3 end
        if (state.PingMs or 0)>500 or (state.AverageLoopCost or 0)>.006 then severeUntil=now+3 end
        local limited=now<pressureUntil
        local severe=now<severeUntil
        state.FrameRequestCap=severe and 1 or (limited and 2 or 4)
        state.MaxRequestsPerSecond=severe and 12 or (limited and 24 or 48)
        state.NetworkPressureLimited=limited
    end
    api.Update()
    return api
end
