-- A cast owns a bounded observation ledger and one paced sender.
return function(ctx)
    local api={Started=false}
    local state,record=ctx.State,ctx.Record
    local entries,listeners={},{}
    local cancelled=false
    local rounds=math.clamp(ctx.Rounds or 3,1,ctx.RepeatWindow and 12 or 3)
    local perTarget=setmetatable({}, {__mode="k"})
    record.Desired=ctx.SourceWindow and "Active window"or rounds
    record.Targets={};record.TotalRequests=0
    local function observe(target,data)
        local entry={Target=target,TargetName=target.Name,Health=data.Health,Before=data.Health.Value,Requested=0,HealthDrops=0,Distances={}}
        entry.Distance=ctx.Distance and ctx.Distance(target,data)
        entry.RangeDistance=ctx.RangeDistance and ctx.RangeDistance(target,data)or entry.Distance
        if ctx.Contribution then entry.BeforeContribution,entry.Counter=ctx.Contribution(data.Health)end
        local last=data.Health.Value
        listeners[#listeners+1]=data.Health:GetPropertyChangedSignal("Value"):Connect(function()
            local hp=data.Health.Value
            if hp<last then
                local delta=last-hp
                entry.MinimumHealthDrop=entry.MinimumHealthDrop and math.min(entry.MinimumHealthDrop,delta)or delta
                entry.HealthDrops+=1;record.HealthDrops=(record.HealthDrops or 0)+1
            end
            last=hp
        end)
        entries[target]=entry;record.Targets[#record.Targets+1]=entry;record.Before=(record.Before or 0)+entry.Before
        return entry
    end
    local function targets(first)
        local result,visited={},{}
        for _,target in ipairs(ctx.Targets(first))do
            local data=ctx.Valid(target)
            local entry=entries[target]
            local capacity=ctx.SourceWindow or #record.Targets<(ctx.RefreshTargets and 16 or 8)
            if data and not entry and capacity then entry=observe(target,data)end
            if data and entry and not visited[target]then
                visited[target]=true;result[#result+1]=entry
                if not ctx.SourceWindow and #result==8 then break end
            end
        end
        record.TargetCount=#record.Targets
        return result
    end
    local function permitted()
        return not cancelled and not state.StopEverything and ctx.CanRun()and (not ctx.ExpiresAt or os.clock()<ctx.ExpiresAt)
    end
    local function reserve(entry,data,before,now)
        if not ctx.Budget then return end
        local estimate=ctx.EstimateDamage and ctx.EstimateDamage(entry.Target,data)or 0
        ctx.Budget.Reserve(entry,before,estimate,now,math.max(.35,(state.PingMs or 100)/1000+.15))
    end
    local function recordSend(entry,now)
        if record.LastTarget and record.LastTarget~=entry.Target then record.Retargets=(record.Retargets or 0)+1 end
        record.LastTarget=entry.Target;record.LastRequestAt=now
        entry.Requested+=1;record.TotalRequests+=1;state.SkillHitRequests=(state.SkillHitRequests or 0)+1
    end
    local function remaining(entry,data,now)
        return not ctx.Budget or ctx.Budget.Remaining(entry,data.Health.Value,now)>0
    end
    local function window(extra)
        local active,nextRefresh={},0
        local credits=math.clamp(state.FrameRequestCap or 4,1,4)
        local refill=os.clock()
        record.Status="Source skill window"
        while permitted()do
            local now=os.clock()
            if now>=nextRefresh then active=targets();nextRefresh=now+.08 end
            local cap=math.clamp(state.FrameRequestCap or 4,1,4)
            credits=math.min(cap,credits+math.max(0,now-refill)*(state.MaxRequestsPerSecond or 48));refill=now
            local sent=0
            for _,entry in ipairs(active)do
                if credits<1 or sent==cap or not permitted()then break end
                now=os.clock()
                local target=entry.Target
                if now<(perTarget[target]or 0)or (ctx.Pacing and not ctx.Pacing.Ready(target,now))then continue end
                local data=ctx.Valid(target)
                if not data then continue end
                if not remaining(entry,data,now)then record.SkippedOverkill=(record.SkippedOverkill or 0)+1;continue end
                local before=data.Health.Value
                if ctx.Send(target,data,extra)==false then continue end
                local delay=math.max(.3,ctx.Spacing or 0)
                perTarget[target]=now+delay
                if ctx.Pacing then ctx.Pacing.Mark(target,now,delay)end
                reserve(entry,data,before,now);recordSend(entry,now)
                record.Requested=record.TotalRequests;state.LastSkillBurstSize=record.TotalRequests
                sent+=1;credits-=1
            end
            task.wait(.03)
        end
        if not cancelled then record.Status="Source skill window completed"end
    end
    local function sequence(first,extra)
        for round=1,rounds do
            if round>1 then
                local waitFor=(record.LastRequestAt or os.clock())+ctx.Spacing-os.clock()
                if waitFor>0 then task.wait(waitFor)end
            end
            if ctx.ExpiresAt and os.clock()>=ctx.ExpiresAt then record.Status="Skill firing window completed";break end
            if not permitted()then record.Status="Paused for movement, dodge or network";break end
            local active=(ctx.RefreshTargets or ctx.FocusBudget)and targets(first)or record.Targets
            local sent=0
            for _,entry in ipairs(active)do
                local data=ctx.Valid(entry.Target)
                if data and ctx.FocusBudget and not remaining(entry,data,os.clock())then record.SkippedOverkill=(record.SkippedOverkill or 0)+1;data=nil end
                if not data then continue end
                if sent>0 and sent%math.clamp(state.FrameRequestCap or 4,1,4)==0 then task.wait(.015)end
                if not permitted()then break end
                if ctx.Distance then entry.Distances[#entry.Distances+1]=ctx.Distance(entry.Target,data)end
                local before=data.Health.Value
                ctx.Send(entry.Target,data,extra)
                if ctx.FocusBudget then reserve(entry,data,before,os.clock())end
                recordSend(entry,os.clock());sent+=1
                if ctx.FocusBudget then break end
            end
            if sent==0 and not ctx.RefreshTargets then record.Status="Targets defeated or out of skill range";break end
            record.Requested=round;state.LastSkillBurstSize=round
        end
        if record.Requested==rounds then record.Status=ctx.RepeatWindow and "Rifle firing sequence completed"or rounds==1 and "Skill shot sent"or "Three skill rounds sent"end
    end
    function api.Start(first,extra)
        if cancelled or api.Started or state.StopEverything or (not ctx.RefreshTargets and not ctx.Valid(first))then return false end
        targets(first)
        if #record.Targets==0 then return false end
        api.Started=true
        api.Deadline=ctx.ExpiresAt and ctx.ExpiresAt+.15 or os.clock()+3*(ctx.Spacing+.4)+.5
        record.Status="Sending area skill burst"
        task.spawn(function()
            local ok,reason=pcall(function()
                local windup=(ctx.FirstHitAt or 0)-os.clock()
                if windup>0 then task.wait(windup)end
                if ctx.SourceWindow then window(extra)else sequence(first,extra)end
            end)
            if not ok then record.Status="Skill burst error";state.LastSkillError=tostring(reason)end
            record.FinishedAt=record.FinishedAt or os.clock()
        end)
        return true
    end
    function api.Finish()
        if record.ObservationFinished then return end
        record.ObservationFinished=true
        for _,connection in ipairs(listeners)do pcall(function()connection:Disconnect()end)end
        table.clear(listeners)
        record.After=0;record.Damage=0
        for _,entry in ipairs(record.Targets)do
            local ok,reason=pcall(function()
                entry.After=entry.Health.Value;entry.HealthDamage=math.max(0,entry.Before-entry.After)
                local credited=ctx.Contribution and ctx.Contribution(entry.Health,entry.Counter)
                entry.Damage=credited~=nil and math.max(0,credited-(entry.BeforeContribution or 0))or entry.HealthDamage
                record.After+=entry.After;record.Damage+=entry.Damage
            end)
            if not ok then record.ObservationError=tostring(reason)end
        end
    end
    function api.Cancel(reason)
        cancelled=true;record.Status=reason or "Cast cancelled";record.FinishedAt=record.FinishedAt or os.clock();api.Finish()
    end
    return api
end
