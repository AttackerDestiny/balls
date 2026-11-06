-- Normal-hit admission combines a global token bucket with target-local deadlines.
return function(state)
    local api={}
    local deadlines=setmetatable({}, {__mode="k"})
    local context,closed
    local bucket={Balance=4,At=os.clock(),ReserveAt=0}
    local function blocked()
        return closed or state.StopEverything or state.SafeModePanic or state.ModeratorBlocking or state.AutoTradeBusy
    end
    function api.Bind(adapter)context=adapter end
    function api.Next(target)return deadlines[target]or 0 end
    function api.Ready(target,now)return now>=api.Next(target)end
    function api.Mark(target,now,delay)deadlines[target]=now+math.max(.3,delay or 0)end
    function api.Cancel(reason)
        state.AttackBurstActive=false
        state.ThreatReason=reason or "Paused"
    end
    function api.Destroy()
        closed=true;api.Cancel("Script closed");table.clear(deadlines);context=nil
    end
    local function admissible(target,now,root,folder)
        if not api.Ready(target,now)or target.Parent~=folder then return nil end
        if state.SkillRegistrationTarget and not state.Enabled and target~=state.SkillRegistrationTarget then return nil end
        local data=context.GetData(target)
        if not data or data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0)then return nil end
        if data.Entity:FindFirstChild("Immortal")then return nil end
        local delta=context.Delta and context.Delta(data,root)or data.Root.Position-root.Position
        local radius=context.Radius(target)
        if delta:Dot(delta)>radius*radius then return nil end
        return data
    end
    function api.Update(now,targets,root,folder)
        state.AttackBurstActive=false
        if blocked()or not context then return end
        local reserving=state.ReserveGunStamina==true
        if state.SkillWantsWindow and not reserving then return "Skill aura owns damage"end
        if reserving and now<bucket.ReserveAt then return end
        local limit=reserving and 1 or math.clamp(state.FrameRequestCap or 4,1,4)
        bucket.Balance=math.min(limit,bucket.Balance+math.max(0,now-bucket.At)*(state.MaxRequestsPerSecond or 48))
        bucket.At=now
        local interval=math.max(.3,state.AttackInterval or 0)
        state.EffectiveInterval=interval;state.CurrentThreat=1;state.ThreatReason="Source per-target cooldown"
        local accepted=0
        for _,target in ipairs(targets)do
            if accepted==limit or bucket.Balance<1 then break end
            local data=admissible(target,now,root,folder)
            if data and context.Damage(target)~=false then
                api.Mark(target,now,interval*math.max(1,data.AttackBackoff or 1))
                context.Sent(target,data,now)
                accepted+=1;bucket.Balance-=1
                if reserving then bucket.ReserveAt=now+.5 end
            end
        end
        if accepted>0 then
            state.LastBurstSize=1;state.BurstsSent=(state.BurstsSent or 0)+accepted;context.Visual()
        end
        if #targets==0 then return "Active · waiting for mobs"end
        return string.format("Active · %d targets · %d requests",#targets,state.HitsSent or 0)
    end
    return api
end
