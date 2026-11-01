-- Uses the game's native friend-teleport route; never guesses server IDs.
return function(ctx)
    local s=ctx.State
    local api={}
    local nextTry,busy,serial=0,false,0
    local resolvedName,resolvedId
    function api.Reset()serial+=1;nextTry=0;resolvedName=nil;resolvedId=nil end
    function api.Update(now)
        if not s.AutoJoinFriend then s.AutoJoinFriendStatus="Auto Join Friend is off";return end
        if not s.Running or s.StopEverything or busy or now<nextTry then return end
        local name=tostring(s.JoinFriendUsername or ""):match("^%s*(.-)%s*$"):gsub("^@", "")
        if name==""then s.AutoJoinFriendStatus="Enter a Roblox username";return end
        if not name:match("^[%w_]+$")or #name>20 then s.AutoJoinFriendStatus="Enter a username, not a display name";return end
        if s.ModeratorBlocking or s.SafeModePanic or s.TravelBusy or s.AutomationTeleporting then return end
        if s.AccountProgression then s.AutoJoinFriendStatus="Waiting · Account Progression owns floor travel";return end
        nextTry=now+20;busy=true
        local token=serial
        local function active()return token==serial and s.Running and not s.StopEverything and s.AutoJoinFriend end
        local function ready()return active()and not(s.ModeratorBlocking or s.SafeModePanic or s.TravelBusy or s.AutomationTeleporting or s.AccountProgression)end
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                if resolvedName~=name:lower()then
                    local id=ctx.Resolve(name)
                    if not active()then return end
                    assert(type(id)=="number"and id>0,"Username was not found")
                    resolvedName,resolvedId=name:lower(),id
                end
                if not ready()then return end
                if resolvedId==ctx.LocalUserId then s.AutoJoinFriendStatus="Choose another player";return end
                if ctx.Present(resolvedId)then s.AutoJoinFriendStatus="Joined @"..name.." · staying in this server";return end
                if s.SafeMode and not(s.SafeWhitelistIds and s.SafeWhitelistIds[tostring(resolvedId)])then
                    s.AutoJoinFriendStatus="Add @"..name.." to the Safe Mode whitelist first";return
                end
                ctx.Queue()
                if not ready()then return end
                s.AutoJoinFriendStatus="Joining @"..name
                local message=ctx.Join(resolvedId)
                if active()then s.AutoJoinFriendStatus=type(message)=="string"and message~=""and message or "Join requested · waiting for teleport"end
            end)
            busy=false
            if not ok and active()then s.AutoJoinFriendStatus="Retrying · "..tostring(reason)end
        end)
    end
    return api
end
