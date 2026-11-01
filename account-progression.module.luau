-- Floor orchestration only. Combat, safe matchmaking, equipment and travel keep
-- their existing owners; no health, unlock or inventory values are written.
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Attempts=0}
    local nextTry,arrivalDeadline,waitingSince=0,nil,nil
    local spot,scoutIndex=nil,1
    local unlockWaitSince
    local function status(phase,message)
        api.Phase=phase;state.ProgressionPhase=phase;ctx.Status(message)
    end
    function api.Pause(message)
        api.Paused=true;api.LastError=tostring(message)
        ctx.Release();status("Paused","Paused Â· "..tostring(message).." Â· toggle OFF/ON to retry")
    end
    function api.Reset()
        api.Paused=false;api.LastError=nil;api.Attempts=0
        nextTry,arrivalDeadline,waitingSince,spot,scoutIndex=0,nil,nil,nil,1
        unlockWaitSince=nil
        ctx.Release();status("Idle",state.AccountProgression and "Starting account progression..." or "Account Progression is off")
    end
    local function travelFailed(now,message)
        api.Attempts+=1;ctx.Release();spot=nil;arrivalDeadline=nil
        if api.Attempts>=3 then api.Pause(message);return end
        nextTry=now+api.Attempts*2;status("Retrying","Retrying boss travel Â· "..tostring(message))
    end
    local function advance(now)
        local number=state.ProgressionFloor+1
        if number==6 then number=7 end
        local floor=ctx.Floor(number)
        if not floor then api.Pause("Floor "..number.." is unavailable");return end
        if not ctx.Unlocked(floor) then
            if state.ProgressionFloor~=6 then
                unlockWaitSince=unlockWaitSince or now
                if now-unlockWaitSince>=8 then
                    -- A saved/observed death does not prove the server granted
                    -- progression credit. Reacquire this floor's boss if it did not.
                    state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
                    unlockWaitSince=nil;spot=nil;arrivalDeadline=nil;waitingSince=nil
                    ctx.Release();ctx.Save()
                    status("Rechecking boss","Next floor is still locked Â· returning to the current main boss")
                    return
                end
            end
            status("Waiting for unlock","Boss defeated Â· waiting for F"..number.." unlock")
            return
        end
        ctx.Release();spot=nil;waitingSince=nil;arrivalDeadline=nil;api.Attempts=0
        unlockWaitSince=nil
        state.ProgressionFloor=number;state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
        -- Save the next checkpoint BEFORE queuing a cross-server transition.
        ctx.Save();status("Changing floor","Returning to the teleport pad Â· F"..number)
        nextTry=now+2
        local ok,message=ctx.ChangeFloor(floor)
        if not ok then api.Pause(message or "Floor travel failed") end
    end
    function api.Update(now)
        if not state.AccountProgression or not state.Running or state.StopEverything or api.Paused then return end
        if ctx.SyncFloor then ctx.SyncFloor()end
        if state.ProgressionComplete then
            status("Complete","Complete Â· F12 boss defeated Â· toggle OFF to restore your modes")
            return
        end
        if not ctx.Ready() then unlockWaitSince=nil;status("Waiting","Waiting for protection, character or current movement");return end
        if now<nextTry then return end
        local number=state.ProgressionFloor
        local floor=ctx.Floor(number)
        if not floor then api.Pause("Floor "..tostring(number).." is unavailable");return end
        -- Skip town even when resuming an old F6 checkpoint from another server.
        if number==6 then advance(now);return end
        if ctx.CurrentFloor()~=floor.Id then
            if not ctx.Unlocked(floor) then api.Pause("F"..number.." is locked");return end
            status("Changing floor","Returning to the teleport pad Â· F"..number)
            nextTry=now+2
            local ok,message=ctx.ChangeFloor(floor)
            if not ok then api.Pause(message or "Floor travel failed") end
            return
        end
        if state.ProgressionBossCleared then
            if number==12 then
                state.ProgressionComplete=true;ctx.Complete();ctx.Save()
                status("Complete","Complete Â· F12 boss defeated Â· toggle OFF to restore your modes")
            else advance(now) end
            return
        end
        if not ctx.CombatReady() then status("Waiting for combat","Enable Kill Aura and Auto Farm to continue");return end
        ctx.Equipment(now)
        if spot and not arrivalDeadline and ctx.NearBossSpot and not ctx.NearBossSpot(spot) then
            -- Respawn/panic can return to a pad beyond Auto Farm's detection range.
            -- Re-enter through finite arena travel rather than pinning the old point.
            ctx.Release();spot=nil;waitingSince=nil
        end
        if api.Phase=="Travelling to boss" or arrivalDeadline then
            if ctx.Moving() then
                if now>arrivalDeadline then travelFailed(now,"Boss travel timed out") end
                return
            end
            if not ctx.Arrived(spot) then travelFailed(now,"Boss arrival was not confirmed");return end
            arrivalDeadline=nil;api.Attempts=0;waitingSince=now
            ctx.Arrival();status("Fighting","Waiting for the main boss Â· F"..number)
        end
        if not spot then
            spot=ctx.BossSpot(floor,scoutIndex)
            if not spot then status("Finding boss","Waiting for the main boss arena to load Â· F"..number);return end
            local ok,message=ctx.Go(spot)
            if not ok then travelFailed(now,message or "Boss arena is unavailable");return end
            arrivalDeadline=now+15
            status("Travelling to boss","Moving to the main boss Â· F"..number)
            return
        end
        local boss=ctx.Boss(spot)
        if boss and boss.Defeated and boss.Credited then
            state.ProgressionBossCleared=true
            state.ProgressionBossClearedName=boss.Name
            ctx.Release();spot=nil;ctx.Save()
            status("Boss defeated","Main boss defeated Â· F"..number)
            return
        end
        status("Fighting",boss and boss.Alive and ("Defeating "..boss.Name.." Â· F"..number)
            or ("Waiting for the main boss to spawn Â· F"..number))
        -- F12 source contains several arenas. Scout only unclassified candidates;
        -- never treat a miniboss/regular mob or disappearance as a main-boss kill.
        if spot.Scout and not (boss and boss.Alive) and now-(waitingSince or now)>=20 then
            scoutIndex+=1;ctx.Release();spot=nil;waitingSince=nil
        end
    end
    function api.Destroy()ctx.Release()end
    return api
end
