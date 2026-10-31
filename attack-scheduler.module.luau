return function(state)
    local nextReserveHit,reserving=0,false
    local api={}
    local active=setmetatable({}, {__mode="k"})
    local nextHit=setmetatable({}, {__mode="k"})
    local observers={}
    local tokens,refill=6,os.clock()
    local ctx
    function api.Bind(value) ctx=value end
    function api.SelectThreat(data,distance,range,hasCredit)
        if state.ReserveGunStamina then state.CurrentThreat=1; state.ThreatReason="Recovering gun stamina"; return 1,state.ThreatReason end
        local maximum=math.clamp(math.floor(state.Threat),1,3)
        local cap,reason=maximum,"Stable target"
        if maximum==3 then
            if not hasCredit and not data.RegisteredDamage then cap=1; reason="Registering target"
            elseif (data.AttackBackoff or 1)>1 or (data.AttackMisses or 0)>0 then cap=1; reason="Checking missed hits"
            elseif (state.PingMs or 0)>450 or (state.AverageFrameTime or 0)>1/35 then cap=1; reason="Network/frame pressure"
            elseif (state.PingMs or 0)>380 then cap=2; reason="High latency"
            end
            if distance>range-1.5 then cap=1; reason="Edge of reach"
            elseif distance>range-4 then cap=math.min(cap,2); reason="Near reach boundary" end
        end
        if data.HitLives then cap=math.min(cap,math.max(1,math.floor(data.HitLives.Value))) end
        if data.NormalDamagePerHit and data.NormalDamagePerHit>0 then
            cap=math.min(cap,math.max(1,math.ceil(data.Health.Value/data.NormalDamagePerHit)))
        end
        local desired=cap
        if maximum==3 and cap>1 then
            local roll=(ctx.RandomInteger or math.random)(1,100)
            desired=math.min(cap,roll<=15 and 1 or roll<=45 and 2 or 3)
            reason=reason.." · varied burst"
        end
        state.CurrentThreat, state.ThreatReason=desired,reason
        return desired,reason
    end
    local function snapshot(record,reason)
        if record.Finished then return end
        record.Finished=true
        record.Status=reason
        record.After=record.Health.Value
        record.HealthDamage=math.max(0,record.Before-record.After)
        local credited=ctx.Contribution and ctx.Contribution(record.Health,record.Counter)
        record.Damage=credited~=nil and math.max(0,credited-(record.BeforeContribution or 0)) or record.HealthDamage
        record.FinishedAt=os.clock()
        if record.Connection then record.Connection:Disconnect(); observers[record.Connection]=nil end
        state.LastBurstSize=record.Requested
        if record.Requested==record.Desired then state.BurstsSent+=1 end
        state.AttackBurstHistory[#state.AttackBurstHistory+1]=record
        if #state.AttackBurstHistory>8 then table.remove(state.AttackBurstHistory,1) end
    end
    function api.Cancel(reason)
        for mob,record in pairs(active) do snapshot(record,reason or "Paused"); active[mob]=nil end
        state.AttackBurstActive=false
    end
    function api.Destroy()
        api.Cancel("Script closed")
        for connection in pairs(observers) do connection:Disconnect() end
        observers={}
    end
    function api.Update(now,candidates,root,folder)
        local reserve=state.ReserveGunStamina==true
        if reserve~=reserving then
            api.Cancel("Switching gun stamina pacing"); reserving=reserve; nextReserveHit=0
        end
        if reserve and now<nextReserveHit then return end
        local batch=math.clamp(state.FrameRequestCap or 4,1,4)
        if reserve then batch=1 end
        local gap=math.max(0.24,state.AttackInterval or 0,0.24+math.min(0.04,(state.PingMs or 0)/10000))
        state.EffectiveInterval=gap
        tokens=math.min(batch,tokens+math.max(0,now-refill)*(state.MaxRequestsPerSecond or 48))
        refill=now
        local activeCount=0
        for mob,record in pairs(active) do
            if mob.Parent~=folder or record.Health.Value<=0 then snapshot(record,"Target defeated or removed"); active[mob]=nil
            else
                if now<(record.NextRangeCheck or 0) then activeCount+=1; continue end
                record.NextRangeCheck=now+.1
                local data=ctx.GetData(mob)
                local range=ctx.Radius(mob)
                local delta=data and (ctx.Delta and ctx.Delta(data,root) or data.Root.Position-root.Position)
                if not delta or delta:Dot(delta)>range*range then
                    record.OutOfReachAt=record.OutOfReachAt or now
                    if now-record.OutOfReachAt>0.4 then snapshot(record,"Target moved out of reach"); active[mob]=nil
                    else activeCount+=1 end
                else activeCount+=1 end
            end
        end
        local sent,visual=0,false
        for _,mob in ipairs(candidates) do
            if sent>=batch or tokens<1 then break end
            if now<(nextHit[mob] or 0) then continue end
            if not active[mob] and ((state.SkillWantsWindow and not reserve) or activeCount>=8) then continue end
            local data=mob.Parent==folder and ctx.GetData(mob)
            local record=active[mob]
            if data and data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0) and not data.Entity:FindFirstChild("Immortal") then
                local delta=ctx.Delta and ctx.Delta(data,root) or data.Root.Position-root.Position
                local range=ctx.Radius(mob)
                if delta:Dot(delta)<=range*range then
                    if now>=(nextHit[mob] or 0) and tokens>=1 and sent<batch
                        and (record or ((not state.SkillWantsWindow or reserve) and activeCount<8)) then
                        if not record then
                            record={Target=mob,TargetName=mob.Name,Requested=0,Health=data.Health,Before=data.Health.Value,HealthDrops=0,Values={},Status="Sending burst"}
                            if ctx.Contribution then record.BeforeContribution,record.Counter=ctx.Contribution(data.Health) end
                            record.Desired,record.ThreatReason=api.SelectThreat(data,delta.Magnitude,range,record.BeforeContribution~=nil)
                            local before=data.Health.Value
                            record.Connection=data.Health:GetPropertyChangedSignal("Value"):Connect(function()
                                local hp=data.Health.Value
                                if hp<before then record.HealthDrops+=1; if #record.Values<8 then record.Values[#record.Values+1]=hp end end
                                before=hp
                            end)
                            observers[record.Connection]=true
                            active[mob]=record; activeCount+=1
                        end
                        record.OutOfReachAt=nil
                        ctx.Damage(mob)
                        nextHit[mob]=now+gap*math.max(1,data.AttackBackoff or 1)
                        record.Requested+=1
                        state.LastAttackBurst=record
                        ctx.Sent(mob,data,now)
                        if reserve then nextReserveHit=now+.5 end
                        if not visual then ctx.Visual(); visual=true end
                        sent+=1; tokens-=1
                        if record.Requested>=record.Desired then
                            active[mob]=nil; activeCount-=1
                            local complete=record
                            task.delay(math.clamp((state.PingMs or 150)/1000+0.05,0.2,0.6),function() snapshot(complete,"Burst complete") end)
                        end
                    end
                elseif record then
                    record.OutOfReachAt=record.OutOfReachAt or now
                    if now-record.OutOfReachAt>0.4 then snapshot(record,"Target moved out of reach"); active[mob]=nil; activeCount-=1 end
                end
            elseif record then snapshot(record,"Target unavailable"); active[mob]=nil; activeCount-=1 end
        end
        state.AttackBurstActive=activeCount>0
        return #candidates>0 and string.format("Active · %d targets · %d requests",#candidates,state.HitsSent) or "Active · waiting for mobs"
    end
    return api
end
