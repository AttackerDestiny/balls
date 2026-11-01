-- Armed only by the confirmed moderator-block path, never by arbitrary kicks.
return function(ctx)
    local api={Armed=false,Attempts=0}
    function api.Kick(message)
        if api.Armed then return end
        api.Armed=true
        local active=function()return ctx.State.Running~=false and not ctx.State.StopEverything end
        local ok,err=pcall(ctx.Queue)
        if not ok then ctx.State.ModeratorRejoinError="Resume queue: "..tostring(err)end
        -- Start the worker before Kick: some executors throw when Kick returns.
        ctx.Spawn(function()
            ctx.Sleep(1)
            for attempt=1,3 do
                if not active()or api.Started then return end
                api.Attempts=attempt
                ctx.State.ModeratorRejoinStatus="Rejoining current floor · attempt "..attempt
                local sent,reason=pcall(ctx.Teleport)
                if not sent then ctx.State.ModeratorRejoinError=tostring(reason)end
                ctx.Sleep(8)
            end
            if active()and not api.Started then
                ctx.State.ModeratorRejoinStatus="Automatic rejoin did not start · rejoin manually"
            end
        end)
        ctx.Kick(message)
    end
    function api.MarkStarted()api.Started=true end
    return api
end
