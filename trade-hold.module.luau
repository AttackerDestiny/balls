return function(ctx)
    local api={}
    local lease
    function api.Update()
        if ctx.Blocked() then lease=nil;return end
        if not ctx.Active() then
            local release=lease~=nil
            lease=nil
            if release then ctx.Release()end
            return
        end
        local root=ctx.Root()
        if not lease or lease.root~=root then
            lease={root=root,point=root and ctx.Anchor(root)}
            ctx.Pause()
        end
        if lease.root and lease.point then ctx.Hold(lease.point)end
    end
    return api
end
