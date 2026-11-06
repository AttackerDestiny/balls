-- The startup transaction owns exactly one checked ground-relative placement.
return function(ctx)
    local expires=ctx.Now()+8
    while ctx.Alive()do
        local characterRoot=ctx.Root()
        if characterRoot then
            local at=ctx.Position(characterRoot)
            local ground=ctx.Surface(characterRoot,at)
            assert(type(ground)=="number"and ground==ground and math.abs(ground)<1e8,"Startup ground height is unavailable")
            if not ctx.Alive()or ctx.Root()~=characterRoot then return false,"Character changed during startup"end
            ctx.Move(characterRoot,at.X,at.Y<ground-2 and at.Y or ground-20,at.Z,ground)
            return true
        end
        if ctx.Now()>=expires then return false,"Waiting for a living character timed out"end
        ctx.Sleep(.05)
    end
    return false,"Startup cancelled"
end
