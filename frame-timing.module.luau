-- Exponential timing baseline with a separate, bounded hitch hold.
return function(state)
    local smoothing, ceiling = .08, .2
    local function finitePositive(value)
        return type(value)=="number" and value>0 and value<math.huge and value==value
    end
    return {Sample=function(elapsed,stamp)
        if not finitePositive(elapsed)then return nil end
        local baseline=state.AverageFrameTime or 1/60
        local hitch=elapsed>math.max(.35,baseline*4)
        state.AverageFrameTime=baseline*(1-smoothing)+math.min(ceiling,elapsed)*smoothing
        if hitch and (state.Enabled or state.SkillAura)then
            local hold=stamp+.5
            if hold>(state.LagPauseUntil or 0)then state.LagPauseUntil=hold end
        end
        return hitch
    end}
end
