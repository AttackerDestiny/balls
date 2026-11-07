-- Wave 100 Nuke shelter. Only measured, raised pillars can supply cover.
return function(ctx)
    local api={Active=false,Waiting=false}
    local now=ctx.Now or os.clock
    local expires,emptySince,scanAt=0,nil,0
    local raised,closed=false,false
    local pillars={}
    local shelter,source,connection
    local flat=Vector3.new(1,0,1)
    local function reset()
        expires=0;emptySince=nil;shelter=nil;source=nil
        api.Active=false;api.Waiting=false
    end
    if ctx.Replicate then connection=ctx.Replicate:Connect(function(_,operation,skill,surface)
        if closed or not ctx.FinalWave()or operation~="Initial"or skill~="RubricatusNuke"then return end
        source=typeof(surface)=="Vector3"and surface or ctx.Origin()
        expires=now()+12;emptySince=nil;shelter=nil;scanAt=0
    end)end
    local function refresh(time,origin)
        if time<scanAt then return end
        scanAt=time+.1;table.clear(pillars)
        for _,pillar in ipairs(ctx.Pillars())do
            if #pillars==32 then break end
            if origin and pillar.Parent and pillar.CanCollide then
                local frame,size=pillar.CFrame,pillar.Size
                local height=math.abs(frame.RightVector.Y)*size.X+math.abs(frame.UpVector.Y)*size.Y+math.abs(frame.LookVector.Y)*size.Z
                local radius=((pillar.Position-origin)*flat).Magnitude
                -- Spawn markers and pillars still underground do not block the blast.
                if height>=12 and radius>=70 and radius<=170 and pillar.Position.Y+height*.5>origin.Y+6
                    and pillar.Position.Y-height*.5<origin.Y+8 then
                    pillars[#pillars+1]=pillar
                end
            end
        end
        local any=#pillars>0
        if any and not raised then
            source=source or origin;expires=math.max(expires,time+12);emptySince=nil
        elseif not any and raised then emptySince=time end
        raised=any
    end
    local function covered(pillar,origin,point)
        if not pillar.Parent or not pillar.CanCollide then return false end
        -- Require a ray through the interior of the actual pillar, between boss and player.
        local a=pillar.CFrame:PointToObjectSpace(origin+Vector3.new(0,3,0))
        local b=pillar.CFrame:PointToObjectSpace(point)
        local half=pillar.Size*.5-Vector3.new(1,1,1)
        if math.min(half.X,half.Y,half.Z)<=0 then return false end
        local lo,hi=0,1
        for _,axis in ipairs({"X","Y","Z"})do
            local direction=b[axis]-a[axis]
            if math.abs(direction)<.001 then
                if math.abs(a[axis])>half[axis]then return false end
            else
                local first,last=(-half[axis]-a[axis])/direction,(half[axis]-a[axis])/direction
                if first>last then first,last=last,first end
                lo=math.max(lo,first);hi=math.min(hi,last)
                if lo>hi then return false end
            end
        end
        return lo>0 and hi<1 and (not ctx.Covered or ctx.Covered(pillar,origin+Vector3.new(0,3,0),point))
    end
    function api.Plan(point,safe)
        api.Active=false;api.Waiting=false
        if closed then return end
        if not ctx.FinalWave()then reset();raised=false;table.clear(pillars);return end
        local time=now();local origin=ctx.Origin()or source
        refresh(time,source or origin)
        if time>=expires or (emptySince and time-emptySince>=.2)then reset();return end
        if not ctx.State.AutoDodge then return end
        api.Active=true
        origin=source or origin
        if not origin then api.Waiting=true;return nil,"Nuke · waiting for pillar geometry"end
        if shelter then
            for _,pillar in ipairs(pillars)do
                if covered(pillar,origin,shelter)and safe(shelter)then return shelter,"Nuke · pillar cover"end
            end
            shelter=nil
        end
        local best,cost
        for _,pillar in ipairs(pillars)do
            local direction=(pillar.Position-origin)*flat
            if direction.Magnitude<1 then continue end
            direction=direction.Unit
            -- Use the horizontal extent in world space, including rotated rectangular pillars.
            local frame,size=pillar.CFrame,pillar.Size
            local x=math.abs(frame.RightVector.X)*size.X+math.abs(frame.UpVector.X)*size.Y+math.abs(frame.LookVector.X)*size.Z
            local z=math.abs(frame.RightVector.Z)*size.X+math.abs(frame.UpVector.Z)*size.Y+math.abs(frame.LookVector.Z)*size.Z
            local distance=math.sqrt(x*x+z*z)*.5+6
            local candidate=pillar.Position+direction*distance
            candidate=Vector3.new(candidate.X,origin.Y+3,candidate.Z)
            if covered(pillar,origin,candidate)and safe(candidate)then
                local travel=(candidate-point).Magnitude
                if not cost or travel<cost then best=candidate;cost=travel end
            end
        end
        shelter=best;api.Waiting=best==nil
        return best,best and "Nuke · pillar cover"or "Nuke · waiting for clear pillar cover"
    end
    function api.Destroy()
        if closed then return end
        closed=true;if connection then connection:Disconnect();connection=nil end
        reset();table.clear(pillars)
    end
    return api
end
