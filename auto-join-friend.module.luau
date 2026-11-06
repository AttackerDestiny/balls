-- Resolve identities lazily and protect every yielding step with a generation token.
return function(ctx)
    local state=ctx.State
    local api={}
    local generation,due=0,0
    local operation
    local identity={}
    local function status(message)state.AutoJoinFriendStatus=message end
    function api.Reset()
        generation=generation+1;due=0;identity={}
        status(state.AutoJoinFriend and "Checking friend..."or "Auto Join Friend is off")
    end
    local function blocked()
        local gates={{state.ModeratorBlocking,"moderator protection"},{state.SafeModePanic,"Safe Mode protection"},
            {state.TravelBusy,"current movement"},{state.AutomationTeleporting,"teleport in progress"},
            {state.AccountProgression,"Account Progression owns floor travel"}}
        for _,gate in ipairs(gates)do if gate[1]then return gate[2]end end
    end
    function api.Update(now)
        if not state.AutoJoinFriend then status("Auto Join Friend is off");return end
        if not state.Running then return end
        if state.StopEverything then status("Paused · Stop Everything is on");return end
        if operation then return end
        local name=tostring(state.JoinFriendUsername or ""):match("^%s*(.-)%s*$"):gsub("^@","")
        if name==""then status("Enter a Roblox username");return end
        if #name>20 or not name:match("^[%w_]+$")then status("Enter a username, not a display name");return end
        local gate=blocked()
        if gate then status("Waiting · "..gate);return end
        if now<due then return end
        due=now+20
        local ticket={generation=generation};operation=ticket
        local function current()
            return generation==ticket.generation and state.Running and not state.StopEverything and state.AutoJoinFriend
        end
        local function ready()
            return current()and not(state.ModeratorBlocking or (state.SafeModePanic and not state.AutoJoinFriendHolding)
                or state.TravelBusy or state.AutomationTeleporting or state.AccountProgression)
        end
        status("Checking @"..name)
        ctx.Spawn(function()
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
                if ctx.Present(identity.id)then status("Joined @"..name.." · staying in this server");return end
                if state.SafeMode and not(state.SafeWhitelistIds and state.SafeWhitelistIds[tostring(identity.id)])then
                    status("Add @"..name.." to the Safe Mode whitelist first");return
                end
                ctx.Queue()
                if not ready()then return end
                status("Joining @"..name)
                local result=ctx.Join(identity.id,ready)
                if current()then status(type(result)=="string"and result~=""and result or "Join requested · waiting for teleport")end
            end)
            if operation==ticket then operation=nil end
            if not ok and current()then status("Retrying · "..tostring(reason))end
        end)
    end
    api.Reset()
    return api
end
