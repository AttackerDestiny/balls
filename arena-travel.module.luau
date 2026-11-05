-- Stream from near the destination, then confirm an actual stable landing.
-- Engine operations are injected for offline delayed-stream/cancellation tests.
return function(ctx)
    local api={}
    function api.Move(point,_automatic,active)
        local character,root,humanoid=ctx.Character()
        assert(character and root and humanoid and humanoid.Health>0 and not root.Anchored,"Character is not ready")
        local function current()
            local latest=ctx.Character()
            return active() and latest==character and root.Parent~=nil and humanoid.Health>0
        end
        local function check()assert(current(),"Travel cancelled")end
        check()
        local stage=point-Vector3.new(0,20,0)
        assert(ctx.Valid(stage),"Invalid arena position")
        ctx.Hold(character,root,humanoid,stage)
        local surface
        -- Moving nearby also triggers streaming when RequestStreamAroundAsync is
        -- unavailable in a mobile executor. Never raycast an unloaded remote map.
        for attempt=1,4 do
            check()
            if ctx.Stream then pcall(ctx.Stream,point,attempt==1 and 2 or .5) end
            check()
            surface=ctx.Surface(point)
            if not surface and ctx.MapDeleted and ctx.MapDeleted()then surface=point end
            if surface then break end
            ctx.Wait(.15)
        end
        assert(surface,"Arena collision has not streamed in yet")
        check()
        local destination=stage
        assert(ctx.Valid(destination),"Landing surface is too low")
        local stableSince
        local deadline=ctx.Clock()+2
        repeat
            check()
            ctx.Hold(character,root,humanoid,destination)
            ctx.Wait(.1)
            check()
            if (root.Position-destination).Magnitude<=3 then
                stableSince=stableSince or ctx.Clock()
                if ctx.Clock()-stableSince>=.3 then
                    return {Position=destination,SurfaceY=surface.Y,Character=character}
                end
            else stableSince=nil end
        until ctx.Clock()>=deadline
        error("The game corrected this teleport; retrying the same arena")
    end
    return api
end
