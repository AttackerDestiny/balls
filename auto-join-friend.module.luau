-- Resolve identities lazily and protect every yielding step with a generation token.
return function(ctx)
    local state=ctx.State
    local api={Failures=0}
    local generation,due=0,0
    local operation
    local pending
    local identity={}
    local clock=ctx.Now or os.clock
    local function status(message)state.AutoJoinFriendStatus=message end
    local function clearFailures()
        api.Failures=0;api.CooldownUntil=nil;due=0
    end
    local function failed(reason)
        api.Failures+=1
        if api.Failures>=2 then
            api.CooldownUntil=clock()+600;due=api.CooldownUntil
            status("Join failed twice · waiting 10 minutes before retrying")
        else status(reason)end
    end
    local function cancelled(reason)
        local text=tostring(reason):lower()
        return text:find("friend join cancelled",1,true)or text:find("wait for a living character",1,true)
            or text:find("teleport pad is unavailable",1,true)
    end
    function api.Reset()
        generation=generation+1;due=0;identity={};pending=nil
        clearFailures()
        status(state.AutoJoinFriend and "Checking friend..."or "Auto Join Friend is off")
    end
    local function blocked()
        local gates={{state.ModeratorBlocking,"moderator protection"},{state.SafeModePanic,"Safe Mode protection"},
            {state.AutoRegroupHolding,"Auto Regroup"},
            {state.TravelBusy,"current movement"},{state.AutomationTeleporting,"teleport in progress"},
            {state.AccountProgression,"Account Progression owns floor travel"}}
        for _,gate in ipairs(gates)do if gate[1]then return gate[2]end end
    end
    function api.TeleportFailed(reason)
        local ticket=pending;pending=nil
        if not ticket or ticket.generation~=generation or not state.Running or not state.AutoJoinFriend
            or state.StopEverything or blocked()then return end
        failed("Retrying · "..tostring(reason or "Friend teleport failed"))
    end
    function api.Update(now)
        if not state.AutoJoinFriend then status("Auto Join Friend is off");return end
        if not state.Running then return end
        if state.StopEverything then status("Paused · Stop Everything is on");return end
        if operation then return end
        local name=tostring(state.JoinFriendUsername or ""):match("^%s*(.-)%s*$"):gsub("^@","")
        if name==""then status("Enter a Roblox username");return end
        if #name>20 or not name:match("^[%w_]+$")then status("Enter a username, not a display name");return end
        if identity.name and identity.name~=name:lower()then api.Reset()end
        local gate=blocked()
        if gate then status("Waiting · "..gate);return end
        if identity.id and identity.id~=ctx.LocalUserId and ctx.Present(identity.id)then
            pending=nil;clearFailures();status("Joined @"..name.." · staying in this server");return
        end
        if pending then
            if now>=pending.deadline then
                if ctx.PendingTimedOut then ctx.PendingTimedOut()end
                api.TeleportFailed("Friend teleport did not finish")
            elseif not state.ServerTeleportStarted then api.TeleportFailed("Friend teleport failed")
            else status("Join requested · waiting for teleport");return end
        end
        if api.CooldownUntil then
            if now<api.CooldownUntil then
                local remaining=math.ceil(api.CooldownUntil-now)
                status(string.format("Join cooldown · %d:%02d remaining",math.floor(remaining/60),remaining%60))
                return
            end
            clearFailures()
        end
        if now<due then return end
        due=now+20
        local ticket={generation=generation};operation=ticket
        local function current()
            return generation==ticket.generation and state.Running and not state.StopEverything and state.AutoJoinFriend
                and not state.AutoRegroupHolding
        end
        local function ready()
            return current()and not(state.ModeratorBlocking or (state.SafeModePanic and not state.AutoJoinFriendHolding)
                or state.AutoRegroupHolding or state.TravelBusy or state.AutomationTeleporting or state.AccountProgression)
        end
        status("Checking @"..name)
        ctx.Spawn(function()
            local dispatched=false
            local ok,reason=pcall(function()
                local canonical=name:lower()
                if identity.name~=canonical then
                    local id=ctx.Resolve(name)
                    if not current()then return end
                    assert(type(id)=="number"and id>0,"Username was not found")
                    identity={name=canonical,id=id}
                end
                if not ready()then return end
                if identity.id==ctx.LocalUserId then status("Choose another player");return end
                if ctx.Present(identity.id)then clearFailures();status("Joined @"..name.." · staying in this server");return end
                if state.SafeMode and not(state.SafeWhitelistIds and state.SafeWhitelistIds[tostring(identity.id)])then
                    status("Add @"..name.." to the Safe Mode whitelist first");return
                end
                ctx.Queue()
                if not ready()then return end
                status("Joining @"..name)
                dispatched=true
                local result=ctx.Join(identity.id,ready)
                if not current()then return end
                if ctx.Present(identity.id)then
                    pending=nil;clearFailures();status("Joined @"..name.." · staying in this server")
                elseif state.ServerTeleportStarted then
                    pending={generation=generation,deadline=clock()+30}
                    status("Join requested · waiting for teleport")
                elseif cancelled(result)then status(tostring(result))
                elseif ready()then
                    -- The native adapter waits for teleport after an empty accepted reply.
                    -- Returning here without a start receipt means that attempt timed out.
                    failed(type(result)=="string"and result~=""and result or "Join did not start · retrying")
                end
            end)
            if operation==ticket then operation=nil end
            if not ok and current()then
                local message="Retrying · "..tostring(reason)
                if dispatched and ready()and not cancelled(reason)then failed(message)else status(message)end
            end
        end)
    end
    api.Reset()
    return api
end
