-- Pressure tiers have independent release times to prevent budget oscillation.
return function(state)
    local deadline={Poll=0,Limited=0,Severe=0}
    local budgets={{4,48},{2,24},{1,12}}
    local api={}
    function api.Update(stamp)
        stamp=stamp or os.clock()
        if stamp<deadline.Poll then return end
        deadline.Poll=stamp+1
        local loop=state.AverageLoopCost or 0
        local ping=state.PingMs or 0
        local tier=((state.AverageFrameTime or 1/60)>1/45 or ping>300 or loop>.002)and 2 or 1
        if ping>500 or loop>.006 then tier=3 end
        if tier>=2 then deadline.Limited=stamp+3 end
        if tier==3 then deadline.Severe=stamp+3 end
        local active=stamp<deadline.Severe and 3 or (stamp<deadline.Limited and 2 or 1)
        state.FrameRequestCap=budgets[active][1]
        state.MaxRequestsPerSecond=budgets[active][2]
        state.NetworkPressureLimited=active>1
    end
    api.Update()
    return api
end
