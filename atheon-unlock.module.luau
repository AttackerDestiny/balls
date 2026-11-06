-- Portal requests require physical receipts and retry without retaining old roots.
return function(ctx)
    local api={}
    local receipt,pending
    local pollAt=0
    local function status(message)ctx.State.AtheonUnlockStatus=message end
    function api.Reset()receipt=nil;pending=nil;pollAt=0 end
    function api.Update(now)
        local state=ctx.State
        if not(state.Running and state.AtheonUnlock)or ctx.Busy()or now<pollAt then return end
        pollAt=now+.5
        if ctx.Unlocked()then status("Atheon is already unlocked");pending=nil;return end
        local portal=ctx.Find()
        if not portal then status("Waiting for workspace.AtheonPortal");pending=nil;return end
        local root=ctx.Root()
        if not root then status("Waiting for a living character");pending=nil;return end
        if receipt and receipt.Root==root and receipt.Portal==portal then return end
        if pending and pending.Root==root and pending.Portal==portal then
            if now<pending.VerifyAt then return end
            if ctx.Arrived(root,pending.Point)then
                receipt={Root=root,Portal=portal};pending=nil;status("Moved to AtheonPortal");return
            end
            pending=nil;status("Portal position corrected · retrying")
        else pending=nil end
        local destination=ctx.Position(portal)
        if not destination then status("AtheonPortal has no supported position");return end
        local ok,reason=pcall(ctx.Move,root,destination,now)
        if not ok then pollAt=now+2;status("Portal teleport retry · "..tostring(reason));return end
        pending={Root=root,Portal=portal,Point=destination,VerifyAt=now+1}
        status("Verifying arrival at AtheonPortal")
    end
    function api.Destroy()api.Reset();pollAt=math.huge end
    return api
end
