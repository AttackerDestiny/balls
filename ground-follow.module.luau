-- Ground observations are independent from attack/root positions during native jumps.
return function(ctx)
    local api={}
    local observations=setmetatable({}, {__mode="k"})
    function api.Resolve(mob,data,now)
        local observation=observations[mob]
        if not observation then observation={ProbeAt=0};observations[mob]=observation end
        local root=data.Root
        local deleted=ctx.MapDeleted and ctx.MapDeleted()
        if now>=observation.ProbeAt then
            observation.ProbeAt=now+.2
            local floor=ctx.Floor(mob,data)
            if type(floor)=="number"then observation.Floor=floor end
        end
        if deleted then observation.Floor=nil end
        local floor=observation.Floor
        local native=ctx.GroundHint and ctx.GroundHint(mob)
        local humanoid=mob:FindFirstChildOfClass("Humanoid")
        local standing=math.max(data.BodyBelow or root.Size.Y*.5,root.Size.Y*.5+(humanoid and humanoid.HipHeight or 0))
        local at=root.Position
        local airborne=native~=nil or (floor~=nil and at.Y-floor>standing+7)or root.AssemblyLinearVelocity.Y>10
        if airborne then
            if not observation.Position then
                observation.Position=native or (floor and Vector3.new(at.X,floor+(observation.Standing or standing),at.Z))
            end
        else
            observation.Position=at
            if floor then observation.Standing=at.Y-floor end
        end
        return observation.Position or (not airborne and at or nil),airborne==true
    end
    return api
end
