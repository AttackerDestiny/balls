-- Supplied-source rule: one damage call per target, then a 0.3s cooldown.
-- Timestamps replace a delayed coroutine per hit; skills share these timers.
return function(state)
    local api={}
    local nextHit=setmetatable({}, {__mode="k"})
    local tokens,refill=4,os.clock()
    local nextReserveHit=0
    local ctx
    function api.Bind(value)ctx=value end
    function api.Ready(mob,now)return now>=(nextHit[mob] or 0)end
    function api.Next(mob)return nextHit[mob] or 0 end
    function api.Mark(mob,now,gap)nextHit[mob]=now+math.max(.3,gap or 0)end
    function api.Cancel(reason)
        state.AttackBurstActive=false
        state.ThreatReason=reason or "Paused"
    end
    function api.Destroy()api.Cancel("Script closed");table.clear(nextHit)end
    function api.Update(now,candidates,root,folder)
        state.AttackBurstActive=false
        if state.StopEverything or state.SafeModePanic or state.ModeratorBlocking or state.AutoTradeBusy then return end
        local reserve=state.ReserveGunStamina==true
        if state.SkillWantsWindow and not reserve then return "Skill aura owns damage" end
        if reserve and now<nextReserveHit then return end
        local batch=reserve and 1 or math.clamp(state.FrameRequestCap or 4,1,4)
        tokens=math.min(batch,tokens+math.max(0,now-refill)*(state.MaxRequestsPerSecond or 48))
        refill=now
        local gap=math.max(.3,state.AttackInterval or 0)
        state.EffectiveInterval=gap
        state.CurrentThreat=1;state.ThreatReason="Source per-target cooldown"
        local sent=0
        for _,mob in ipairs(candidates)do
            if sent>=batch or tokens<1 then break end
            if state.SkillRegistrationTarget and not state.Enabled and mob~=state.SkillRegistrationTarget then continue end
            if not api.Ready(mob,now)then continue end
            local data=mob.Parent==folder and ctx.GetData(mob)
            if not data or data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0)
                or data.Entity:FindFirstChild("Immortal")then continue end
            local delta=ctx.Delta and ctx.Delta(data,root)or data.Root.Position-root.Position
            local range=ctx.Radius(mob)
            if delta:Dot(delta)>range*range then continue end
            ctx.Damage(mob)
            api.Mark(mob,now,gap*math.max(1,data.AttackBackoff or 1))
            ctx.Sent(mob,data,now)
            sent+=1;tokens-=1
            if reserve then nextReserveHit=now+.5 end
        end
        if sent>0 then
            state.LastBurstSize=1
            state.BurstsSent=(state.BurstsSent or 0)+sent
            ctx.Visual()
        end
        return #candidates>0 and string.format("Active · %d targets · %d requests",#candidates,state.HitsSent or 0)or "Active · waiting for mobs"
    end
    return api
end
