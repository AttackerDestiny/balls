return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Current=nil,Visits=0}
    local clearedSince
    local retryAt,retries=0,0
    local function travelFailed(now,message)
        ctx.Release()
        retries=retries+1
        api.LastError=message
        api.Phase=retries>=3 and "Paused" or "Retrying travel"
        retryAt=now+math.min(8,2*retries)
        ctx.Status(retries>=3 and ("Multi Spot paused · "..message.." · toggle off/on to retry")
            or ("Retrying arena travel · "..message))
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
        return result
    end
    function api.Reset()
        api.Phase="Idle";api.Current=nil;clearedSince=nil;api.EncounterSeen=false
        retryAt,retries=0,0;api.LastError=nil;api.MoveDeadline=nil;ctx.Release()
    end
    function api.Update(now)
        if not state.MultiSpot or not state.Running then return end
        if api.Phase=="Paused" then return end
        if api.Phase=="Retrying travel" then
            if now<retryAt then return end
            api.Phase="Idle";api.Current=nil
        end
        -- Observe an in-progress trip even if casting or TravelBusy prevents a new one.
        if api.Phase=="Moving" then
            if ctx.Moving() then
                if now>(api.MoveDeadline or math.huge) then travelFailed(now,"Travel timed out") end
                return
            end
            if not ctx.Arrived(api.Current) then travelFailed(now,"Arrival was not confirmed");return end
            api.MoveDeadline=nil;retries=0;api.LastError=nil
            local alive,seen=ctx.Encounter(api.Current)
            api.Phase="Waiting for spawn";api.EncounterSeen=api.EncounterSeen or seen or alive>0;clearedSince=nil;api.Visits=api.Visits+1
            ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name)
        end
        if not ctx.CanMove() then return end
        local selected=choices()
        if #selected==0 then ctx.Status(state.SafeMode and "Select arenas on the Safe Mode floor" or "Select at least one arena");return end
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
