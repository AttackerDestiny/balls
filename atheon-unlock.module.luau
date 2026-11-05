-- One portal placement per enable/character/portal; no permanent movement hold.
return function(ctx)
    local api={}
    local completedRoot,completedPortal
    local nextAttempt=0
    function api.Reset()completedRoot=nil;completedPortal=nil;nextAttempt=0 end
    function api.Update(now)
        if not ctx.State.Running or not ctx.State.AtheonUnlock or ctx.Busy()or now<nextAttempt then return end
        nextAttempt=now+.5
        local portal=ctx.Find()
        if not portal then ctx.State.AtheonUnlockStatus="Waiting for workspace.AtheonPortal";return end
        local root=ctx.Root()
        if not root then ctx.State.AtheonUnlockStatus="Waiting for a living character";return end
        if completedRoot==root and completedPortal==portal then return end
        local destination=ctx.Position(portal)
        if not destination then ctx.State.AtheonUnlockStatus="AtheonPortal has no supported position";return end
        local ok,reason=pcall(ctx.Move,root,destination,now)
        if ok then
            completedRoot,completedPortal=root,portal
            ctx.State.AtheonUnlockStatus="Moved to AtheonPortal"
        else nextAttempt=now+2;ctx.State.AtheonUnlockStatus="Portal teleport retry · "..tostring(reason)end
    end
    return api
end
