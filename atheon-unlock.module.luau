-- One portal placement per enable/character/portal; no permanent movement hold.
return function(ctx)
    local api={}
    local completedRoot,completedPortal
    local pendingRoot,pendingPortal,pendingPosition,verifyAt
    local nextAttempt=0
    function api.Reset()
        completedRoot=nil;completedPortal=nil;nextAttempt=0
        pendingRoot=nil;pendingPortal=nil;pendingPosition=nil;verifyAt=nil
    end
    function api.Update(now)
        if not ctx.State.Running or not ctx.State.AtheonUnlock or ctx.Busy()or now<nextAttempt then return end
        nextAttempt=now+.5
        if ctx.Unlocked()then ctx.State.AtheonUnlockStatus="Atheon is already unlocked";return end
        local portal=ctx.Find()
        if not portal then ctx.State.AtheonUnlockStatus="Waiting for workspace.AtheonPortal";return end
        local root=ctx.Root()
        if not root then ctx.State.AtheonUnlockStatus="Waiting for a living character";return end
        if completedRoot==root and completedPortal==portal then return end
        if pendingRoot==root and pendingPortal==portal then
            if now<verifyAt then return end
            if ctx.Arrived(root,pendingPosition)then
                completedRoot,completedPortal=root,portal
                pendingRoot,pendingPortal,pendingPosition=nil,nil,nil
                ctx.State.AtheonUnlockStatus="Moved to AtheonPortal"
                return
            end
            pendingRoot,pendingPortal,pendingPosition=nil,nil,nil
            ctx.State.AtheonUnlockStatus="Portal position corrected · retrying"
        end
        local destination=ctx.Position(portal)
        if not destination then ctx.State.AtheonUnlockStatus="AtheonPortal has no supported position";return end
        local ok,reason=pcall(ctx.Move,root,destination,now)
        if ok then
            pendingRoot,pendingPortal,pendingPosition=root,portal,destination
            verifyAt=now+1
            ctx.State.AtheonUnlockStatus="Verifying arrival at AtheonPortal"
        else nextAttempt=now+2;ctx.State.AtheonUnlockStatus="Portal teleport retry · "..tostring(reason)end
    end
    return api
end
