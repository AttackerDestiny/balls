return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Current=nil,Visits=0,LastVisits={}}
    local clearedSince
    local retryAt,retries=0,0
    local function travelFailed(now,message)
        ctx.Release()
        retries=retries+1
        api.LastError=message
        api.Phase="Retrying travel"
        local delay=retries<3 and 2*retries or math.min(60,5*2^math.min(4,retries-3))
        retryAt=now+delay;api.RetryAt=retryAt
        ctx.Status("Retrying arena in "..delay.."s · "..message)
        -- Runtime failures must never overwrite the user's saved ON preference.
        ctx.Save()
    end
    local function choices()
        local result={}
        for _,spot in ipairs(ctx.Spots()) do
            if spot.PlaceId==ctx.CurrentFloor() and state.MultiSpotSelected[spot.Id]
                and (not state.SafeMode or spot.PlaceId==state.SafeFloorId) then
                result[#result+1]=spot
            end
        end
        local order={};for i,id in ipairs(state.MultiSpotOrder or {})do order[id]=i end
        table.sort(result,function(a,b)
            local ar,br=order[a.Id]or math.huge,order[b.Id]or math.huge
            if ar~=br then return ar<br end
            return a.Id<b.Id
        end)
        return result
    end
    local function timedChoice(selected,now,exclude)
        local unknown,nextSpot,nextAt
        for _,spot in ipairs(selected)do
            local record=ctx.Respawns.Get(spot)
            if spot~=exclude then
                if record and (record.HasLive or (record.DueAt and record.DueAt<=now))then return spot end
                if not record or not record.DueAt then
                    if not unknown or (api.LastVisits[spot.Id]or -math.huge)<(api.LastVisits[unknown.Id]or -math.huge)then unknown=spot end
                end
            end
            if record and record.DueAt and record.DueAt>now and (not nextAt or record.DueAt<nextAt)then nextSpot,nextAt=spot,record.DueAt end
        end
        return unknown,nextSpot,nextAt
    end
    function api.UpdateTimed(now,selected)
        if api.Current then
            local alive,seen=ctx.Encounter(api.Current)
            api.Remaining=alive
            if seen or alive>0 then api.EncounterSeen=true end
            if alive>0 then
                api.CurrentCleared=false;api.WaitingSince=nil;clearedSince=nil;api.Phase="Clearing arena"
                ctx.Status(api.Current.Name.." · "..alive.." mobs remaining");return
            end
            if api.EncounterSeen and not api.CurrentCleared then
                clearedSince=clearedSince or now
                if now-clearedSince<.6 then return end
                api.CurrentCleared=true;api.ClearedRounds=(api.ClearedRounds or 0)+1
                state.MultiSpotPending=nil;api.EncounterSeen=false;clearedSince=nil
                if ctx.ClearEncounter then ctx.ClearEncounter()end
            end
        end
        local spot,nextSpot,nextAt=timedChoice(selected,now)
        if spot and spot==api.Current then
            api.WaitingSince=api.WaitingSince or now
            if now-api.WaitingSince>=5 then
                local alternative=timedChoice(selected,now,api.Current)
                if alternative then spot=alternative end
            end
        end
        if not spot then
            api.Phase="Waiting for respawn"
            ctx.Status(nextSpot and ("Next spawn · "..nextSpot.Name.." · "..math.max(0,math.ceil(nextAt-now)).."s")or "Waiting for selected arena spawns")
            return
        end
        if spot==api.Current then
            api.Phase="Waiting for spawn"
            local record=ctx.Respawns.Get(spot)
            ctx.Status((record and record.DueAt and "Spawn due · waiting for "or "Waiting for arena mobs to spawn · ")..spot.Name)
            return
        end
        if ctx.DepartureReady and not ctx.DepartureReady()then return end
        ctx.Release();api.Current=spot;api.CurrentCleared=false;api.EncounterSeen=false;api.WaitingSince=nil
        api.LastVisits[spot.Id]=now
        state.MultiSpotCursor=spot.Id;state.MultiSpotPending=spot.Id
        api.Phase="Moving";api.MoveDeadline=now+15;ctx.Save()
        local ok,message=ctx.Go(spot)
        if not ok then travelFailed(now,message or "Arena is unavailable")end
    end
    function api.Reset()
        api.Phase="Idle";api.Current=nil;clearedSince=nil;api.EncounterSeen=false;api.CurrentCleared=false;api.WaitingSince=nil;api.LastVisits={}
        retryAt,retries=0,0;api.LastError=nil;api.MoveDeadline=nil;api.PrioritySuspended=false;api.RetryAt=nil;ctx.Release()
    end
    function api.Update(now)
        if not state.MultiSpot or not state.Running then return end
        if api.Phase=="Paused" then return end
        if ctx.Respawns then ctx.Respawns.Update(now,ctx.Spots())end
        local priority=ctx.PriorityTarget and ctx.PriorityTarget(now)
        if priority then
            if not api.PrioritySuspended then
                if api.Current then
                    local alive,seen=ctx.Encounter(api.Current)
                    api.EncounterSeen=api.EncounterSeen or seen or alive>0
                end
                if ctx.Suspend then ctx.Suspend()end
                api.PrioritySuspended=true;clearedSince=nil
            end
            ctx.Status("Priority enemy · "..priority.Name.." · selected arenas will resume")
            return
        end
        if api.PrioritySuspended then
            if not ctx.CanMove()or (ctx.DepartureReady and not ctx.DepartureReady())then return end
            api.PrioritySuspended=false
            if ctx.Resume then ctx.Resume()end
            local selected=choices()
            local resume
            for _,spot in ipairs(selected)do if api.Current and spot.Id==api.Current.Id then resume=spot;break end end
            if resume and ctx.Respawns then
                local record=ctx.Respawns.Get(resume)
                if record and record.DueAt and record.DueAt>now and ctx.Encounter(resume)==0 then resume=nil end
            end
            if resume then
                api.Phase="Moving";api.MoveDeadline=now+15
                local ok,message=ctx.Go(resume,true)
                if not ok then travelFailed(now,message or "Arena is unavailable");return end
                ctx.Status("Returning to selected arena · "..resume.Name)
                return
            end
            api.Phase="Idle";api.Current=nil
        end
        if api.Phase=="Retrying travel" then
            if now<retryAt then
                ctx.Status("Retrying arena in "..math.max(1,math.ceil(retryAt-now)).."s · "..tostring(api.LastError))
                return
            end
            if not ctx.CanMove()then return end
            api.Phase="Idle";api.Current=nil
        end
        -- Observe an in-progress trip even if casting or TravelBusy prevents a new one.
        if api.Phase=="Moving" then
            if ctx.Moving() then
                if now>(api.MoveDeadline or math.huge) then travelFailed(now,"Travel timed out") end
                return
            end
            if not ctx.Arrived(api.Current) then travelFailed(now,"Arrival was not confirmed");return end
            api.MoveDeadline=nil;retries=0;api.LastError=nil;api.RetryAt=nil
            local alive,seen=ctx.Encounter(api.Current)
            api.Phase="Waiting for spawn";api.EncounterSeen=api.EncounterSeen or seen or alive>0;clearedSince=nil;api.Visits=api.Visits+1
            ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name)
        end
        if not ctx.CanMove() then return end
        local selected=choices()
        if #selected==0 then ctx.Status(state.SafeMode and "Select arenas on the Safe Mode floor" or "Select at least one arena");return end
        if ctx.Respawns then api.UpdateTimed(now,selected);return end
        if api.Current then
            local alive,seen=ctx.Encounter(api.Current)
            api.Remaining=alive
            if seen or alive>0 then api.EncounterSeen=true end
            if alive>0 then
                clearedSince=nil;api.Phase="Clearing arena"
                ctx.Status(api.Current.Name.." · "..alive.." mobs remaining")
                return
            end
            if not api.EncounterSeen then
                api.Phase="Waiting for spawn"
                ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name)
                return
            end
            clearedSince=clearedSince or now
            if now-clearedSince<.6 then return end
            api.Phase="Cleared";ctx.Status("Arena cleared · moving to next spot")
            api.ClearedRounds=(api.ClearedRounds or 0)+1
            state.MultiSpotPending=nil
            if #selected==1 and selected[1].Id==api.Current.Id then
                state.MultiSpotPending=api.Current.Id
                api.EncounterSeen=false;clearedSince=nil;api.Phase="Waiting for spawn"
                if ctx.ClearEncounter then ctx.ClearEncounter() end
                ctx.Status("Arena cleared · waiting for the next spawn")
                return
            end
        end
        local spot
        if state.MultiSpotPending then
            for _,item in ipairs(selected) do if item.Id==state.MultiSpotPending then spot=item;break end end
        end
        if not spot then
            local index=0
            for i,item in ipairs(selected) do if item.Id==state.MultiSpotCursor then index=i;break end end
            spot=selected[index%#selected+1]
        end
        if ctx.CurrentFloor()~=spot.PlaceId then
            state.MultiSpotPending=spot.Id
            ctx.Status("Travelling to "..spot.Floor.Name)
            ctx.ChangeFloor(spot.PlaceId);return
        end
        if ctx.DepartureReady and not ctx.DepartureReady()then return end
        ctx.Release()
        api.Current=spot
        api.EncounterSeen=false
        state.MultiSpotCursor=spot.Id;state.MultiSpotPending=spot.Id
        -- Keep the same destination across stream/retry failures.
        api.Phase="Moving";api.MoveDeadline=now+15;ctx.Save()
        local ok,message=ctx.Go(spot)
        if not ok then travelFailed(now,message or "Arena is unavailable") end
    end
    function api.Pause(message)
        ctx.Release();api.Phase="Paused";api.LastError=tostring(message)
        ctx.Status("Multi Spot paused · "..api.LastError.." · toggle off/on to retry")
    end
    function api.Destroy() api.Reset() end
    return api
end
