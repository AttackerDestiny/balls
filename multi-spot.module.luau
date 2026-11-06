-- Arena rotation has explicit interruption, travel, clear-confirmation and cooldown stages.
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Visits=0,LastVisits={}}
    local clearingAt
    local retry={count=0,due=0}
    local function selected()
        local priority={}
        for index,id in ipairs(state.MultiSpotOrder or {})do priority[id]=index end
        local result={}
        for _,spot in ipairs(ctx.Spots())do
            if spot.PlaceId==ctx.CurrentFloor()and state.MultiSpotSelected[spot.Id]
                and (not state.SafeMode or spot.PlaceId==state.SafeFloorId)then result[#result+1]=spot end
        end
        table.sort(result,function(a,b)
            local x,y=priority[a.Id]or math.huge,priority[b.Id]or math.huge
            return x==y and a.Id<b.Id or x<y
        end)
        return result
    end
    local function fail(now,reason)
        ctx.Release();retry.count=retry.count+1
        local delay=retry.count<3 and retry.count*2 or math.min(60,5*2^math.min(4,retry.count-3))
        retry.due=now+delay;api.RetryAt=retry.due;api.LastError=reason;api.Phase="Retrying travel"
        ctx.Status("Retrying arena in "..delay.."s · "..reason);ctx.Save()
    end
    local function departureReady()
        return not ctx.DepartureReady or ctx.DepartureReady()
    end
    local function go(spot,now,resume)
        if not resume then
            ctx.Release();api.Current=spot;api.CurrentCleared=false;api.EncounterSeen=false;api.WaitingSince=nil
            api.LastVisits[spot.Id]=now;state.MultiSpotCursor=spot.Id;state.MultiSpotPending=spot.Id
        end
        api.Phase="Moving";api.MoveDeadline=now+15
        if not resume then ctx.Save()end
        local sent,reason=ctx.Go(spot,resume)
        if not sent then fail(now,reason or "Arena is unavailable");return false end
        return true
    end
    local function observe()
        local alive,seen=ctx.Encounter(api.Current)
        api.Remaining=alive
        api.EncounterSeen=api.EncounterSeen or seen or alive>0
        return alive
    end
    local function holdLiving()
        clearingAt=nil;api.WaitingSince=nil;api.CurrentCleared=false;api.Phase="Clearing arena"
        ctx.Status(api.Current.Name.." · "..api.Remaining.." mobs remaining")
    end
    local function finishRound(now)
        clearingAt=clearingAt or now
        if now-clearingAt<.6 then return false end
        api.ClearedRounds=(api.ClearedRounds or 0)+1;state.MultiSpotPending=nil
        return true
    end
    local function pickTimed(options,now,exclude)
        local unknown,nextSpot,nextTime
        for _,spot in ipairs(options)do
            local record=ctx.Respawns.Get(spot)
            if spot~=exclude then
                if record and (record.HasLive or record.DueAt and record.DueAt<=now)then return spot end
                if not record or not record.DueAt then
                    if not unknown or (api.LastVisits[spot.Id]or -math.huge)<(api.LastVisits[unknown.Id]or -math.huge)then unknown=spot end
                end
            end
            if record and record.DueAt and record.DueAt>now and (not nextTime or record.DueAt<nextTime)then
                nextSpot,nextTime=spot,record.DueAt
            end
        end
        return unknown,nextSpot,nextTime
    end
    function api.UpdateTimed(now,options)
        if api.Current then
            if observe()>0 then holdLiving();return end
            if api.EncounterSeen and not api.CurrentCleared then
                if not finishRound(now)then return end
                api.CurrentCleared=true;api.EncounterSeen=false;clearingAt=nil
                if ctx.ClearEncounter then ctx.ClearEncounter()end
            end
        end
        local spot,nextSpot,nextTime=pickTimed(options,now)
        if spot==api.Current and spot then
            api.WaitingSince=api.WaitingSince or now
            if now-api.WaitingSince>=5 then spot=pickTimed(options,now,api.Current)or spot end
        end
        if not spot then
            api.Phase="Waiting for respawn"
            ctx.Status(nextSpot and ("Next spawn · "..nextSpot.Name.." · "..math.max(0,math.ceil(nextTime-now)).."s")or "Waiting for selected arena spawns")
            return
        end
        if spot==api.Current then
            local record=ctx.Respawns.Get(spot)
            api.Phase="Waiting for spawn"
            ctx.Status((record and record.DueAt and "Spawn due · waiting for "or "Waiting for arena mobs to spawn · ")..spot.Name)
            return
        end
        if departureReady()then go(spot,now,false)end
    end
    local function completeTravel(now)
        if api.Phase~="Moving"then return true end
        if ctx.Moving()then
            if now>(api.MoveDeadline or math.huge)then fail(now,"Travel timed out")end
            return false
        end
        if not ctx.Arrived(api.Current)then fail(now,"Arrival was not confirmed");return false end
        api.MoveDeadline=nil;api.LastError=nil;api.RetryAt=nil;retry.count=0
        observe();api.Phase="Waiting for spawn";clearingAt=nil;api.Visits=api.Visits+1
        ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name)
        return true
    end
    local function priority(now)
        local target=ctx.PriorityTarget and ctx.PriorityTarget(now)
        if target then
            if not api.PrioritySuspended then
                if api.Current then observe()end
                if ctx.Suspend then ctx.Suspend()end
                api.PrioritySuspended=true;clearingAt=nil
            end
            ctx.Status("Priority enemy · "..target.Name.." · selected arenas will resume")
            return true
        end
        if not api.PrioritySuspended then return false end
        if not ctx.CanMove()or not departureReady()then return true end
        api.PrioritySuspended=false
        if ctx.Resume then ctx.Resume()end
        local resume
        for _,spot in ipairs(selected())do if api.Current and spot.Id==api.Current.Id then resume=spot;break end end
        if resume and ctx.Respawns then
            local record=ctx.Respawns.Get(resume)
            if record and record.DueAt and record.DueAt>now and ctx.Encounter(resume)==0 then resume=nil end
        end
        if resume then
            if go(resume,now,true)then ctx.Status("Returning to selected arena · "..resume.Name)end
            return true
        end
        api.Current=nil;api.Phase="Idle"
        return false
    end
    local function nextUntimed(options,now)
        if api.Current then
            if observe()>0 then holdLiving();return end
            if not api.EncounterSeen then api.Phase="Waiting for spawn";ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name);return end
            if not finishRound(now)then return end
            api.Phase="Cleared";ctx.Status("Arena cleared · moving to next spot")
            if #options==1 and options[1].Id==api.Current.Id then
                state.MultiSpotPending=api.Current.Id;api.EncounterSeen=false;clearingAt=nil;api.Phase="Waiting for spawn"
                if ctx.ClearEncounter then ctx.ClearEncounter()end
                ctx.Status("Arena cleared · waiting for the next spawn");return
            end
        end
        local nextSpot
        local cursor=0
        for index,spot in ipairs(options)do
            if spot.Id==state.MultiSpotPending then nextSpot=spot end
            if spot.Id==state.MultiSpotCursor then cursor=index end
        end
        nextSpot=nextSpot or options[cursor%#options+1]
        if ctx.CurrentFloor()~=nextSpot.PlaceId then
            state.MultiSpotPending=nextSpot.Id;ctx.Status("Travelling to "..nextSpot.Floor.Name);ctx.ChangeFloor(nextSpot.PlaceId);return
        end
        if departureReady()then go(nextSpot,now,false)end
    end
    function api.Update(now)
        if not state.MultiSpot or not state.Running or api.Phase=="Paused"then return end
        if ctx.Respawns then ctx.Respawns.Update(now,ctx.Spots())end
        if priority(now)then return end
        if api.Phase=="Retrying travel"then
            if now<retry.due then ctx.Status("Retrying arena in "..math.max(1,math.ceil(retry.due-now)).."s · "..tostring(api.LastError));return end
            if not ctx.CanMove()then return end
            api.Current=nil;api.Phase="Idle"
        end
        if not completeTravel(now)or not ctx.CanMove()then return end
        local options=selected()
        if #options==0 then ctx.Status(state.SafeMode and "Select arenas on the Safe Mode floor"or "Select at least one arena");return end
        if ctx.Respawns then api.UpdateTimed(now,options)else nextUntimed(options,now)end
    end
    function api.Reset()
        api.Current=nil;api.Phase="Idle";api.EncounterSeen=false;api.CurrentCleared=false;api.WaitingSince=nil
        api.LastVisits={};api.LastError=nil;api.MoveDeadline=nil;api.PrioritySuspended=false;api.RetryAt=nil
        retry={count=0,due=0};clearingAt=nil;ctx.Release()
    end
    function api.Pause(reason)
        ctx.Release();api.Phase="Paused";api.LastError=tostring(reason)
        ctx.Status("Multi Spot paused · "..api.LastError.." · toggle off/on to retry")
    end
    function api.Destroy()api.Reset()end
    return api
end
