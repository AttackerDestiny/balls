-- Cache each enemy's standing position; do not chase vertical attack animations.
return function(ctx)
    local records=setmetatable({}, {__mode="k"})
    local api={}
    function api.Resolve(mob,data,now)
        local root=data.Root
        local record=records[mob]
        if not record then record={NextProbe=0};records[mob]=record end
        if now>=record.NextProbe then
            record.NextProbe=now+.2
            local floor=ctx.Floor(mob,data)
            if type(floor)=="number" then record.Floor=floor end
        end
        local hint=ctx.GroundHint and ctx.GroundHint(mob)
        local humanoid=mob:FindFirstChildOfClass("Humanoid")
        local standing=math.max(data.BodyBelow or root.Size.Y*.5,
            root.Size.Y*.5+(humanoid and humanoid.HipHeight or 0))
        local floor=record.Floor
        local position=root.Position
        local elevated=floor and position.Y-floor>standing+7
        local rising=root.AssemblyLinearVelocity.Y>10
        local airborne=hint~=nil or elevated or rising
        if not airborne then
            record.Position=position
            record.Standing=floor and position.Y-floor or record.Standing
        elseif not record.Position then
            record.Position=hint or (floor and Vector3.new(position.X,floor+(record.Standing or standing),position.Z)) or nil
        end
        record.Airborne=airborne==true
        return record.Position or (not airborne and position or nil),record.Airborne
    end
    return api
end
