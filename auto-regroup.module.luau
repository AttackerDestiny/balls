-- Every enabled client independently checks the same roster; no cross-client commands.
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle"}
    local signature,armedAt,missingAt
    local resetAt,returnAt,returns=0,0,0
    local closed=false
    local function status(message)state.AutoRegroupStatus=message end
    local function release()
        if state.AutoRegroupHolding then ctx.Release()end
        state.AutoRegroupHolding=false
    end
    function api.Reset()
        release();signature=nil;armedAt=nil;missingAt=nil
        resetAt=0;returnAt=0;returns=0;api.Phase="Idle"
        status(state.AutoRegroup and "Waiting for room users"or "Auto Regroup is off")
    end
    function api.Update(now)
        if closed then return end
        if not state.Running or not state.AutoRegroup or not ctx.InBetween()then api.Reset();return end
        if state.StopEverything or state.ModeratorBlocking or state.SafeModePanic or state.AutomationTeleporting
            or state.ServerTeleportStarted or state.AutoJoinFriendHolding or state.AutoTradeBusy
            or (state.SafeMode and state.SafeController and state.SafeController.Seeking)then missingAt=nil;return end
        local names=ctx.Users()
        if #names==0 then api.Reset();status("Add room Host + Alts or Regroup Users");return end
        local key=table.concat(names,"\0"):lower()
        if signature~=key then api.Reset();signature=key;armedAt=now end
        if api.Phase=="Returning"then
            if now<returnAt then return end
            if returns>=3 then api.Phase="Failed";status("Return was not confirmed · toggle Auto Regroup OFF/ON to retry");return end
            returns+=1;returnAt=now+10
            ctx.PrepareReturn();ctx.Return()
            status("Returning to lobby · regrouping")
            return
        end
        if api.Phase=="Failed"then return end
        if api.Phase=="Resetting"then
            if not ctx.Dead()and now-resetAt<5 then return end
            api.Phase="Returning";returnAt=now
            return
        end
        if now-armedAt<15 then status("Waiting for server users to load");return end
        local present=ctx.Present()
        local missing={}
        for _,name in ipairs(names)do if not present[name:lower()]then missing[#missing+1]=name end end
        if #missing==0 then missingAt=nil;status("All regroup users are in this server");return end
        missingAt=missingAt or now
        status("Missing: "..table.concat(missing,", "))
        if now-missingAt<5 then return end
        state.AutoRegroupHolding=true;api.Phase="Resetting";resetAt=now
        ctx.Pause();ctx.ResetCharacter()
        status("Resetting to regroup · missing "..table.concat(missing,", "))
    end
    function api.Destroy()
        if closed then return end
        closed=true;release();signature=nil
    end
    api.Reset()
    return api
end
