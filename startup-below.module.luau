-- One startup placement, then release movement entirely to the normal controllers.
return function(ctx)
    local deadline=ctx.Now()+8
    repeat
        if not ctx.Alive()then return false,"Startup cancelled"end
        local root=ctx.Root()
        if root then
            local point=ctx.Position(root)
            local floor=ctx.Surface(root,point)
            assert(type(floor)=="number"and floor==floor and math.abs(floor)<1e8,"Startup ground height is unavailable")
            if not ctx.Alive()or ctx.Root()~=root then return false,"Character changed during startup"end
            ctx.Move(root,point.X,floor-20,point.Z)
            return true
        end
        if ctx.Now()>=deadline then return false,"Waiting for a living character timed out"end
        ctx.Sleep(.05)
    until false
end
