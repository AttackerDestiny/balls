return function(ctx)
    local api={Started=false}
    local state,record=ctx.State,ctx.Record
    local observers={}
    local cancelled=false
    local rounds=math.clamp(ctx.Rounds or 3,1,ctx.RepeatWindow and 12 or 3)
    local seen={}
    record.Desired=ctx.SourceWindow and "Active window" or rounds
    record.Targets={}
    record.TotalRequests=0
    local function captureTargets(first)
        local current={}
        local included={}
        for _,mob in ipairs(ctx.Targets(first)) do
            local data=ctx.Valid(mob)
            local item=seen[mob]
            if data and not item and (ctx.SourceWindow or #record.Targets<(ctx.RefreshTargets and 16 or 8)) then
                item={Target=mob,TargetName=mob.Name,Health=data.Health,Before=data.Health.Value,Requested=0,HealthDrops=0}
                seen[mob]=item
                item.Distance=ctx.Distance and ctx.Distance(mob,data) or nil
                item.RangeDistance=ctx.RangeDistance and ctx.RangeDistance(mob,data) or item.Distance
                item.Distances={}
                if ctx.Contribution then item.BeforeContribution,item.Counter=ctx.Contribution(data.Health) end
                local previous=data.Health.Value
                observers[#observers+1]=data.Health:GetPropertyChangedSignal("Value"):Connect(function()
                    local hp=data.Health.Value
                    if hp<previous then
                        local drop=previous-hp
                        item.MinimumHealthDrop=item.MinimumHealthDrop and math.min(item.MinimumHealthDrop,drop) or drop
                        item.HealthDrops+=1; record.HealthDrops+=1
                    end
                    previous=hp
                end)
                record.Targets[#record.Targets+1]=item
                record.Before=(record.Before or 0)+item.Before
            end
            if data and item and not included[mob] then
                included[mob]=true
                current[#current+1]=item
                if not ctx.SourceWindow and #current>=8 then break end
            end
        end
        record.TargetCount=#record.Targets
        return current
    end
    local function runSourceWindow(extra)
        local nextScan=0
        local targets={}
        local tokens,refill=math.clamp(state.FrameRequestCap or 4,1,4),os.clock()
        local nextHit=setmetatable({}, {__mode="k"})
        record.Status="Source skill window"
        while not cancelled and not state.StopEverything and ctx.CanRun() and os.clock()<ctx.ExpiresAt do
            local now=os.clock()
            if now>=nextScan then targets=captureTargets();nextScan=now+.08 end
            local batch=math.clamp(state.FrameRequestCap or 4,1,4)
            tokens=math.min(batch,tokens+math.max(0,now-refill)*(state.MaxRequestsPerSecond or 48));refill=now
            local sent=0
            for _,item in ipairs(targets)do
                if sent>=batch or tokens<1 then break end
                if cancelled or state.StopEverything or not ctx.CanRun() or os.clock()>=ctx.ExpiresAt then break end
                now=os.clock()
                if ctx.Pacing and not ctx.Pacing.Ready(item.Target,now)or now<(nextHit[item.Target]or 0)then continue end
                local data=ctx.Valid(item.Target)
                if not data then continue end
                if ctx.Budget and ctx.Budget.Remaining(item,data.Health.Value,now)<=0 then
                    record.SkippedOverkill=(record.SkippedOverkill or 0)+1;continue
                end
                local hp=data.Health.Value
                if ctx.Send(item.Target,data,extra)==false then continue end
                local gap=math.max(.3,ctx.Spacing or 0)
                if ctx.Pacing then ctx.Pacing.Mark(item.Target,now,gap)end
                nextHit[item.Target]=now+gap
                if ctx.Budget then
                    local estimate=ctx.EstimateDamage and ctx.EstimateDamage(item.Target,data)or 0
                    ctx.Budget.Reserve(item,hp,estimate,now,math.max(.35,(state.PingMs or 100)/1000+.15))
                end
                if record.LastTarget and record.LastTarget~=item.Target then record.Retargets=(record.Retargets or 0)+1 end
                record.LastTarget=item.Target;record.LastRequestAt=now
                item.Requested+=1;record.TotalRequests+=1
                state.SkillHitRequests=(state.SkillHitRequests or 0)+1
                record.Requested=record.TotalRequests;state.LastSkillBurstSize=record.TotalRequests
                sent+=1;tokens-=1
            end
            task.wait(.03)
        end
        record.Status=cancelled and record.Status or "Source skill window completed"
    end
    function api.Start(first,extra)
        if cancelled or state.StopEverything or api.Started or (not ctx.RefreshTargets and not ctx.Valid(first)) then return false end
        captureTargets(first)
        if #record.Targets==0 then return false end
        api.Started=true
        api.Deadline=ctx.ExpiresAt and ctx.ExpiresAt+.15 or os.clock()+3*(ctx.Spacing+0.4)+0.5
        record.Status="Sending area skill burst"
        task.spawn(function()
            local ok,message=pcall(function()
                local delay=math.max(0,(ctx.FirstHitAt or 0)-os.clock())
                if delay>0 then task.wait(delay) end
                if ctx.SourceWindow then runSourceWindow(extra);return end
                for round=1,rounds do
                    if round>1 then
                        local due=(record.LastRequestAt or os.clock())+ctx.Spacing
                        local remaining=due-os.clock()
                        if remaining>0 then task.wait(remaining) end
                    end
                    if ctx.ExpiresAt and os.clock()>=ctx.ExpiresAt then record.Status="Skill firing window completed"; break end
                    if cancelled or state.StopEverything or not ctx.CanRun() then record.Status="Paused for movement, dodge or network"; break end
                    local targets=(ctx.RefreshTargets or ctx.FocusBudget) and captureTargets(first) or record.Targets
                    local sent=0
                    for _,item in ipairs(targets) do
                        local data=ctx.Valid(item.Target)
                        if data and ctx.FocusBudget and ctx.Budget and ctx.Budget.Remaining(item,data.Health.Value,os.clock())<=0 then
                            record.SkippedOverkill=(record.SkippedOverkill or 0)+1
                            data=nil
                        end
                        if data then
                            local batch=math.clamp(state.FrameRequestCap or 4,1,4)
                            if sent>0 and sent%batch==0 then task.wait(0.015) end
                            if cancelled or state.StopEverything or not ctx.CanRun() then break end
                            if ctx.Distance then item.Distances[#item.Distances+1]=ctx.Distance(item.Target,data) end
                            local healthBefore=data.Health.Value
                            ctx.Send(item.Target,data,extra)
                            if ctx.FocusBudget and ctx.Budget then
                                local estimate=ctx.EstimateDamage and ctx.EstimateDamage(item.Target,data) or 0
                                ctx.Budget.Reserve(item,healthBefore,estimate,os.clock(),math.max(.35,(state.PingMs or 100)/1000+.15))
                            end
                            if record.LastTarget and record.LastTarget~=item.Target then record.Retargets=(record.Retargets or 0)+1 end
                            record.LastTarget=item.Target
                            record.LastRequestAt=os.clock()
                            item.Requested+=1
                            record.TotalRequests+=1
                            state.SkillHitRequests+=1
                            sent+=1
                            if ctx.FocusBudget then break end
                        end
                    end
                    if sent==0 and not ctx.RefreshTargets then record.Status="Targets defeated or out of skill range"; break end
                    record.Requested=round
                    state.LastSkillBurstSize=round
                end
                if record.Requested==rounds then
                    record.Status=ctx.RepeatWindow and "Rifle firing sequence completed" or rounds==1 and "Skill shot sent" or "Three skill rounds sent"
                end
            end)
            if not ok then record.Status="Skill burst error"; state.LastSkillError=tostring(message) end
            record.FinishedAt=record.FinishedAt or os.clock()
        end)
        return true
    end
    function api.Finish()
        if record.ObservationFinished then return end
        record.ObservationFinished=true
        record.After,record.Damage=0,0
        for _,item in ipairs(record.Targets) do
            item.After=item.Health.Value
            item.HealthDamage=math.max(0,item.Before-item.After)
            local credited=ctx.Contribution and ctx.Contribution(item.Health,item.Counter)
            item.Damage=credited~=nil and math.max(0,credited-(item.BeforeContribution or 0)) or item.HealthDamage
            record.After+=item.After
            record.Damage+=item.Damage
        end
        for _,connection in ipairs(observers) do connection:Disconnect() end
        table.clear(observers)
    end
    function api.Cancel(reason)
        cancelled=true
        record.Status=reason or "Cast cancelled"
        record.FinishedAt=record.FinishedAt or os.clock()
        api.Finish()
    end
    return api
end
