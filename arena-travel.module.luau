-- Arena travel is a cancellable staging/probe/settle transaction.
return function(ctx)
    local api={}
    function api.Move(point,_automatic,active)
        local character,root,humanoid=ctx.Character()
        assert(character and root and humanoid and humanoid.Health>0 and not root.Anchored,"Character is not ready")
        local function validate()
            local current=ctx.Character()
            assert(active()and current==character and root.Parent~=nil and humanoid.Health>0,"Travel cancelled")
        end
        local destination=point-Vector3.new(0,20,0)
        validate();assert(ctx.Valid(destination),"Invalid arena position")
        ctx.Hold(character,root,humanoid,destination)
        local ground
        for attempt=1,4 do
            validate()
            if ctx.Stream then pcall(ctx.Stream,point,attempt==1 and 2 or .5)end
            validate();ground=ctx.Surface(point)
            if not ground and ctx.MapDeleted and ctx.MapDeleted()then ground=point end
            if ground then break end
            ctx.Wait(.15)
        end
        assert(ground,"Arena collision has not streamed in yet")
        validate();assert(ctx.Valid(destination),"Landing surface is too low")
        local expires,settled=ctx.Clock()+2,nil
        while true do
            validate();ctx.Hold(character,root,humanoid,destination);ctx.Wait(.1);validate()
            local now=ctx.Clock()
            if (root.Position-destination).Magnitude<=3 then
                settled=settled or now
                if now-settled>=.3 then return {Position=destination,SurfaceY=ground.Y,Character=character}end
            else settled=nil end
            if now>=expires then break end
        end
        error("The game corrected this teleport; retrying the same arena")
    end
    return api
end
