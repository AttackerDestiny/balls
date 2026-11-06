-- Resolve the startup position and its surface before handing off to the hold.
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
            local height=point.Y<floor-2 and point.Y or floor-20
            ctx.Move(root,point.X,height,point.Z,floor)
            return true
        end
        if ctx.Now()>=deadline then return false,"Waiting for a living character timed out"end
        ctx.Sleep(.05)
    until false
end
