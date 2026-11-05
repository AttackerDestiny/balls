-- A yielded engine call must not hold the single-frame lease forever.
return function(ctx)
    local api={}
    local state=ctx.State
    local active,disposed=nil,false
    local function protected()
        return state.StopEverything or state.SafeModePanic or state.ModeratorBlocking
            or state.AutomationTeleporting or state.AutoTradeBusy
    end
    function api.CheckTravel(now)
        if disposed or protected()or not state.TravelBusy or not state.TravelStartedAt then return end
        if now-state.TravelStartedAt<20 then return end
        local serial=state.TravelSerial
        ctx.RecoverTravel(serial)
        state.TravelRecoveries=(state.TravelRecoveries or 0)+1
        state.LastTravelRecoveryAt=now
    end
    function api.CheckPending(now)
        api.CheckTravel(now)
        if disposed or protected()then return end
        local cast=state.ActiveSkillCast
        if cast and state.SkillCastRunning and cast.RecoveryDeadline and now>=cast.RecoveryDeadline then
            ctx.RecoverSkill()
            state.SkillRecoveries=(state.SkillRecoveries or 0)+1
            state.LastSkillRecoveryAt=now
        end
    end
    function api.Run(fn)
        if disposed then return end
        local now=ctx.Now()
        if active then
            if protected()or now-active.At<8 or now<(active.RetryAt or 0)then return end
            active.RetryAt=now+5
            local ok,cancelled=pcall(ctx.Cancel,active.Thread)
            if not ok or cancelled==false then
                state.LastCoordinatorError="Stalled frame cancellation failed; waiting for its engine call"
                return -- Never overlap a worker whose cancellation was not confirmed.
            end
            active=nil
            state.CoordinatorRecoveries=(state.CoordinatorRecoveries or 0)+1
            state.LastCoordinatorRecoveryAt=now
            local recovered,reason=pcall(ctx.RecoverFrame)
            if not recovered then state.LastCoordinatorError=tostring(reason)end
        end
        local lease={Thread=ctx.Thread(),At=now}
        active=lease;state.FrameStartedAt=now
        local ok,result=pcall(fn)
        if active==lease then active=nil;state.FrameCompletedAt=ctx.Now()end
        return ok,result
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        if active and active.Thread~=ctx.Thread()then pcall(ctx.Cancel,active.Thread)end
        if state.TravelWorker and state.TravelWorker~=ctx.Thread()then pcall(ctx.Cancel,state.TravelWorker)end
        state.TravelWorker=nil;state.TravelStartedAt=nil
        active=nil
    end
    return api
end
