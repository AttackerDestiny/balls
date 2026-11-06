-- Rejoin scheduling is armed before the confirmed-block kick can disconnect Lua.
return function(ctx)
    local api={Armed=false,Attempts=0,Started=false}
    local function available()
        return ctx.State.Running~=false and not ctx.State.StopEverything and not api.Started
    end
    local function worker()
        ctx.Sleep(1)
        local attempt=1
        while attempt<=3 and available()do
            api.Attempts=attempt
            ctx.State.ModeratorRejoinStatus="Rejoining current floor · attempt "..attempt
            local ok,reason=pcall(ctx.Teleport)
            if not ok then ctx.State.ModeratorRejoinError=tostring(reason)end
            ctx.Sleep(8)
            attempt=attempt+1
        end
        if available()then ctx.State.ModeratorRejoinStatus="Automatic rejoin did not start · rejoin manually"end
    end
    function api.MarkStarted()api.Started=true end
    function api.Kick(message)
        if api.Armed then return end
        api.Armed=true
        local queued,reason=pcall(ctx.Queue)
        if not queued then ctx.State.ModeratorRejoinError="Resume queue: "..tostring(reason)end
        ctx.Spawn(worker)
        ctx.Kick(message)
    end
    return api
end
