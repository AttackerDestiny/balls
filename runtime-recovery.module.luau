-- Expired work is cancelled before a replacement is allowed to execute.
return function(context)
    local state=context.State
    local recovery={}
    local current,closed
    local function priorityWait()
        for _,name in ipairs({"StopEverything","SafeModePanic","ModeratorBlocking","AutomationTeleporting","AutoTradeBusy"})do
            if state[name]then return true end
        end
        return false
    end
    local function record(kind,now)
        local count=kind.."Recoveries"
        state[count]=(state[count]or 0)+1
        state["Last"..kind.."RecoveryAt"]=now
    end
    function recovery.CheckTravel(now)
        if closed or priorityWait()then return end
        if state.TravelBusy and state.TravelStartedAt and now>=state.TravelStartedAt+20 then
            context.RecoverTravel(state.TravelSerial);record("Travel",now)
        end
    end
    function recovery.CheckPending(now)
        recovery.CheckTravel(now)
        if closed or priorityWait()then return end
        local cast=state.ActiveSkillCast
        if not(state.SkillCastRunning and cast and cast.RecoveryDeadline)then return end
        if now>=cast.RecoveryDeadline then context.RecoverSkill();record("Skill",now)end
    end
    local function expire(now)
        if current==nil then return true end
        if priorityWait()or now<current.Expires or now<current.Retry then return false end
        current.Retry=now+5
        local ok,answer=pcall(context.Cancel,current.Thread)
        if not ok or answer==false then
            state.LastCoordinatorError="Stalled frame cancellation failed; waiting for its engine call"
            return false
        end
        current=nil;record("Coordinator",now)
        local restored,reason=pcall(context.RecoverFrame)
        if not restored then state.LastCoordinatorError=tostring(reason)end
        return true
    end
    function recovery.Run(callback)
        if closed then return end
        local at=context.Now()
        if not expire(at)then return end
        local token={Thread=context.Thread(),Expires=at+8,Retry=0}
        current=token;state.FrameStartedAt=at
        local ok,result=pcall(callback)
        if current==token then current=nil;state.FrameCompletedAt=context.Now()end
        return ok,result
    end
    function recovery.Destroy()
        if closed then return end
        closed=true
        local caller=context.Thread()
        local workers={current and current.Thread,state.TravelWorker}
        current=nil;state.TravelWorker=nil;state.TravelStartedAt=nil
        for _,worker in pairs(workers)do if worker~=caller then pcall(context.Cancel,worker)end end
    end
    return recovery
end
