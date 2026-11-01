-- All deadlines remain wall-clock based. Steady 10 FPS is not a freeze.
return function(state)
    local api={}
    function api.Sample(delta,now)
        if type(delta)~="number" or delta~=delta or delta<=0 or delta==math.huge then return end
        local previous=state.AverageFrameTime or 1/60
        local stalled=delta>math.max(.35,previous*4)
        -- Ignore a single long hitch in the baseline so it cannot poison pacing.
        state.AverageFrameTime=previous+(math.min(delta,.2)-previous)*.08
        if stalled and (state.Enabled or state.SkillAura) then
            state.LagPauseUntil=math.max(state.LagPauseUntil or 0,now+.5)
        end
        return stalled
    end
    return api
end
