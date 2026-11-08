-- Progression checkpoints advance only after observed credited boss death and unlocks.
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Attempts=0}
    local travel={spot=nil,deadline=nil,waiting=nil,scout=1,due=0,unlock=nil}
    local function publish(phase,message)
        api.Phase=phase;state.ProgressionPhase=phase;ctx.Status(message)
    end
    local function release()
        ctx.Release();travel.spot=nil;travel.deadline=nil;travel.waiting=nil
    end
    function api.Pause(reason)
        api.Paused=true;api.LastError=tostring(reason)
        ctx.Release();publish("Paused","Paused · "..tostring(reason).." · toggle OFF/ON to retry")
    end
    function api.Reset()
        api.Paused=false;api.LastError=nil;api.Attempts=0
        travel={spot=nil,deadline=nil,waiting=nil,scout=1,due=0,unlock=nil}
        ctx.Release()
        publish("Idle",state.AccountProgression and "Starting account progression..."or "Account Progression is off")
    end
    local function failure(now,reason)
        api.Attempts=api.Attempts+1
        release()
        if api.Attempts>=3 then api.Pause(reason);return end
        travel.due=now+api.Attempts*2
        publish("Retrying","Retrying boss travel · "..tostring(reason))
    end
    local function change(floor,now)
        publish("Changing floor","Returning to the teleport pad · F"..floor.Number)
        travel.due=now+2
        local ok,reason=ctx.ChangeFloor(floor)
        if not ok then api.Pause(reason or "Floor travel failed")end
    end
    local function advance(now)
        local number=state.ProgressionFloor+1
        if number==6 then number=7 end
        local floor=ctx.Floor(number)
        if not floor then api.Pause("Floor "..number.." is unavailable");return end
        if not ctx.Unlocked(floor)then
            if state.ProgressionFloor~=6 then
                travel.unlock=travel.unlock or now
                if now-travel.unlock>=8 then
                    state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
                    travel.unlock=nil;release();ctx.Save()
                    publish("Rechecking boss","Next floor is still locked · returning to the current main boss")
                    return
                end
            end
            publish("Waiting for unlock","Boss defeated · waiting for F"..number.." unlock")
            return
        end
        release();travel.unlock=nil;api.Attempts=0
        state.ProgressionFloor=number;state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
        ctx.Save();change(floor,now)
    end
    local function arrival(now)
        if not travel.deadline then return true end
        if ctx.Moving()then
            if now>travel.deadline then failure(now,"Boss travel timed out")end
            return false
        end
        if not ctx.Arrived(travel.spot)then failure(now,"Boss arrival was not confirmed");return false end
        travel.deadline=nil;api.Attempts=0;travel.waiting=now
        ctx.Arrival();publish("Fighting","Waiting for the main boss · F"..state.ProgressionFloor)
        return true
    end
    local function fight(floor,now)
        if not ctx.CombatReady()then publish("Waiting for combat","Enable Kill Aura and Auto Farm to continue");return end
        ctx.Equipment(now)
        if travel.spot and not travel.deadline and ctx.NearBossSpot and not ctx.NearBossSpot(travel.spot)then release()end
        if not arrival(now)then return end
        if not travel.spot then
            local spot=ctx.BossSpot(floor,travel.scout)
            if not spot then publish("Finding boss","Waiting for the main boss arena to load · F"..floor.Number);return end
            travel.spot=spot
            local sent,reason=ctx.Go(spot)
            if not sent then failure(now,reason or "Boss arena is unavailable");return end
            travel.deadline=now+15
            publish("Travelling to boss","Moving to the main boss · F"..floor.Number)
            return
        end
        local boss=ctx.Boss(travel.spot)
        if boss and boss.Defeated and boss.Credited then
            state.ProgressionBossCleared=true;state.ProgressionBossClearedName=boss.Name
            release();ctx.Save();publish("Boss defeated","Main boss defeated · F"..floor.Number)
            return
        end
        publish("Fighting",boss and boss.Alive and ("Defeating "..boss.Name.." · F"..floor.Number)
            or ("Waiting for the main boss to spawn · F"..floor.Number))
        if travel.spot.Scout and not(boss and boss.Alive)and now-(travel.waiting or now)>=20 then
            travel.scout=travel.scout+1;release()
        end
    end
    function api.Update(now)
        if not state.AccountProgression or not state.Running or state.StopEverything or api.Paused then return end
        if ctx.SyncFloor then ctx.SyncFloor()end
        if state.ProgressionComplete then publish("Complete","Complete · F12 boss defeated · toggle OFF to restore your modes");return end
        if not ctx.Ready()then travel.unlock=nil;publish("Waiting","Waiting for protection, character or current movement");return end
        if now<travel.due then return end
        local chest=ctx.ChestTarget and ctx.CombatReady()and ctx.ChestTarget(now)
        if chest then
            if travel.spot and not state.ProgressionBossCleared then
                local boss=ctx.Boss(travel.spot)
                if boss and boss.Defeated and boss.Credited then
                    state.ProgressionBossCleared=true;state.ProgressionBossClearedName=boss.Name;ctx.Save()
                end
            end
            publish("Collecting chest","Opening "..chest.Name.." before progression continues")
            return
        end
        local number=state.ProgressionFloor
        local floor=ctx.Floor(number)
        if not floor then api.Pause("Floor "..tostring(number).." is unavailable");return end
        if number==6 then advance(now);return end
        if ctx.CurrentFloor()~=floor.Id then
            if ctx.Unlocked(floor)then change(floor,now)else api.Pause("F"..number.." is locked")end
            return
        end
        if not state.ProgressionBossCleared then fight(floor,now);return end
        if number~=12 then advance(now);return end
        state.ProgressionComplete=true;ctx.Complete();ctx.Save()
        publish("Complete","Complete · F12 boss defeated · toggle OFF to restore your modes")
    end
    function api.Destroy()ctx.Release()end
    return api
end
