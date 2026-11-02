return function(ctx)
    local api={}
    local root,anchor,owned
    function api.Update()
        if ctx.Blocked()then root,anchor,owned=nil,nil,false;return end
        if not ctx.Active()then
            if owned then ctx.Release()end
            root,anchor,owned=nil,nil,false;return
        end
        local current=ctx.Root()
        if current~=root or not owned then
            root=current;anchor=nil;owned=true
            if root then anchor=ctx.Anchor(root)end
            ctx.Pause()
        end
        if root and anchor then ctx.Hold(anchor)end
    end
    return api
end
