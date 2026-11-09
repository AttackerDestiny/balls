-- Every enabled client independently checks the same roster; no cross-client commands.
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle"}
    local signature,armedAt,missingAt
    local resetAt,returnAt,returns=0,0,0
    local teleportDeadline
    local closed=false
    local function status(message)state.AutoRegroupStatus=message end
    local function release()
        if state.AutoRegroupHolding then ctx.Release()end
        state.AutoRegroupHolding=false
    end
    function api.Reset()
        release();signature=nil;armedAt=nil;missingAt=nil
        resetAt=0;returnAt=0;returns=0;api.Phase="Idle";teleportDeadline=nil
        api.ReturnAttempts=0;api.LastReturnError=nil;api.PrepareError=nil;api.ResetError=nil;api.PauseError=nil
        state.AutoRegroupPrepareError=nil;state.AutoRegroupReturnError=nil
        status(state.AutoRegroup and "Waiting for room users"or "Auto Regroup is off")
    end
    function api.MarkTeleportStarted(now)
        if closed or api.Phase~="Returning"or returns==0 then return end
        teleportDeadline=(now or (ctx.Now or os.clock)())+25
    end
    function api.TeleportFailed(reason)
        if closed or api.Phase~="Returning"or returns==0 then return end
        teleportDeadline=nil
        api.LastReturnError=tostring(reason or "Lobby teleport failed")
        state.AutoRegroupReturnError=api.LastReturnError
        status("Lobby return failed · retrying")
    end
    function api.Update(now)
        if closed then return end
        if not state.Running or not state.AutoRegroup or not ctx.InBetween()then api.Reset();return end
        if state.StopEverything or state.ModeratorBlocking then missingAt=nil;return end
        -- Once reset is committed, finish the exit even if combat/roster/safety state changes.
        if api.Phase=="Returning"then
            if teleportDeadline then
                if now<teleportDeadline then status("Returning to lobby · waiting for teleport");return end
                teleportDeadline=nil
                if ctx.ClearTeleportWait then ctx.ClearTeleportWait()end
                api.TeleportFailed("Lobby teleport timed out")
            elseif state.ServerTeleportStarted or state.AutomationTeleporting then return end
            if now<returnAt then return end
            if returns>=3 then api.Phase="Failed";status("Return was not confirmed · toggle Auto Regroup OFF/ON to retry");return end
            returnAt=now+10
            local prepared,problem=pcall(ctx.PrepareReturn)
            api.PrepareError=not prepared and tostring(problem)or problem==false and "Reload preparation was not confirmed"or nil
            state.AutoRegroupPrepareError=api.PrepareError
            if closed or not state.Running or not state.AutoRegroup or state.StopEverything or state.ModeratorBlocking then return end
            returns+=1;api.ReturnAttempts=returns
            local sent,reason=pcall(ctx.Return)
            api.LastReturnError=not sent and tostring(reason)or reason==false and "Lobby return was rejected"or nil
            state.AutoRegroupReturnError=api.LastReturnError
            status(api.LastReturnError and "Lobby return failed · retrying"or
                api.PrepareError and "Returning to lobby · automatic reload unavailable"or "Returning to lobby · regrouping")
            return
        end
        if api.Phase=="Failed"then return end
        if api.Phase=="Resetting"then
            if state.AutomationTeleporting or state.ServerTeleportStarted then return end
            if not ctx.Dead()and now-resetAt<5 then return end
            -- Local Humanoid death can precede the server's revive/return UI.
            if ctx.ReturnReady and not ctx.ReturnReady()and now-resetAt<8 then
                status("Reset complete · waiting for lobby return to become ready");return
            end
            api.Phase="Returning";returnAt=now
            return
        end
        if state.SafeModePanic or state.AutomationTeleporting or state.ServerTeleportStarted or state.AutoJoinFriendHolding or state.AutoTradeBusy
            or (state.SafeMode and state.SafeController and state.SafeController.Seeking)then missingAt=nil;return end
        local names=ctx.Users()
        if #names==0 then api.Reset();status("Add room Host + Alts or Regroup Users");return end
        local key=table.concat(names,"\0"):lower()
        if signature~=key then api.Reset();signature=key;armedAt=now end
        if now-armedAt<15 then status("Waiting for server users to load");return end
        local present=ctx.Present()
        local missing={}
        for _,name in ipairs(names)do if not present[name:lower()]then missing[#missing+1]=name end end
        if #missing==0 then missingAt=nil;status("All regroup users are in this server");return end
        missingAt=missingAt or now
        status("Missing: "..table.concat(missing,", "))
        if now-missingAt<5 then return end
        state.AutoRegroupHolding=true;api.Phase="Resetting";resetAt=now
        local paused,pauseError=pcall(ctx.Pause)
        if not paused then api.PauseError=tostring(pauseError)end
        local reset,resetError=pcall(ctx.ResetCharacter)
        if not reset then api.ResetError=tostring(resetError)end
        status("Resetting to regroup · missing "..table.concat(missing,", "))
    end
    function api.Destroy()
        if closed then return end
        closed=true;release();signature=nil
    end
    api.Reset()
    return api
end
