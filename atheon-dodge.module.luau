-- Native Atheon cast data and LavaGyzer Point geometry; no damage/cooldown edits.
return function(ctx)
    local state=ctx.State
    local api={Moves=0,Seen={},Completed={},ThreatCount=0,MaxStep=112,MaxBossDistance=128,SmashRadius=90}
    local casts={}
    local points={}
    local disposed=false
    local now=ctx.Now or os.clock
    local flat=Vector3.new(1,0,1)
    local known={FireDash=true,LavaSmash=true,LavaGyzer=true}
    local lastPoint,nextPlan=nil,0
    local function update(point)
        local time=now()
        local closest,distance
        for _,boss in ipairs(ctx.Bosses()) do
            local position=ctx.Position(boss)
            local gap=position and (position-point).Magnitude
            if gap and (not distance or gap<distance) then closest,distance=position,gap end
            local rig=(ctx.Native.RiggedEnemies or {})[boss]
            for name,skill in pairs(rig and rig.ActiveSkills or {}) do
                if known[name] and not skill.Destroyed then
                    local record=casts[skill]
                    if not record then
                        record={Name=name,Skill=skill,Boss=boss,Started=time}
                        if name=="LavaSmash" then
                            record.MinimumUntil=time+math.clamp(tonumber(skill.Lifetime) or 3,1,8)+1.2+(state.PingMs or 0)/1000
                        end
                        casts[skill]=record;api.Seen[name]=(api.Seen[name] or 0)+1
                    end
                    record.Until=math.max(record.MinimumUntil or 0,time+(name=="FireDash" and 3.2 or name=="LavaGyzer" and 1 or .8))
                end
            end
        end
        local count=0
        for skill,record in pairs(casts) do
            local rig=(ctx.Native.RiggedEnemies or {})[record.Boss]
            local ended=skill.Destroyed==true or (rig and rig.ActiveSkills and rig.ActiveSkills[record.Name]~=skill)
            if record.Name=="FireDash" then
                record.Assets=record.Assets or {}
                for _,part in pairs(skill.CreatedAssets or {}) do
                    if part.Parent and part:IsA("BasePart") then record.Assets[part]=true;record.AssetsKnown=true end
                end
                if ended and not record.AssetQueryDone and ctx.FireAssets then
                    record.AssetQueryDone=true
                    local ok,assets=pcall(ctx.FireAssets,skill)
                    if ok and type(assets)=="table" then
                        record.AssetsKnown=true
                        for _,part in ipairs(assets) do record.Assets[part]=true end
                    end
                end
            end
            local grounded=record.Name~="LavaSmash"
            if record.Name=="LavaSmash" and time-record.Started<14 then
                local root=ctx.Position(record.Boss)
                local ground=skill.LastCFrame and skill.LastCFrame.Position or skill.SurfacePosition
                if root and ground then
                    if ctx.Grounded then grounded=ctx.Grounded(record.Boss)
                    else grounded=math.abs(root.Y-ground.Y)<=6 end
                    if not grounded and root.Y>ground.Y+6 then
                        record.WasAirborne=true;record.CompletedAt=nil;record.Until=math.max(record.Until,time+1.2)
                    elseif grounded and record.WasAirborne and not record.LandedAt then
                        record.LandedAt=time;record.Until=math.max(record.Until,time+1.2+(state.PingMs or 0)/1000)
                    end
                    -- A native Destroy plus the grounded root confirms completion;
                    -- do not spend the conservative fallback timer after that.
                end
            end
            if ended and grounded then
                if not record.CompletedAt then
                    record.CompletedAt=time
                    record.ReturnMargin=math.clamp(.1+(state.PingMs or 0)/1000,.15,.35)
                    api.LastSkillEndAt=time;api.LastSkillEndName=record.Name;api.LastReturnMargin=record.ReturnMargin
                    api.Completed[record.Name]={At=time,Margin=record.ReturnMargin}
                end
                local due=record.CompletedAt+record.ReturnMargin
                if record.Name=="FireDash" then
                    if record.AssetsKnown then
                        local alive=false
                        for part in pairs(record.Assets) do if part.Parent then alive=true else record.Assets[part]=nil end end
                        record.Until=alive and math.min(record.CompletedAt+3.2,math.max(due,time+.2)) or due
                    end
                else record.Until=math.min(record.Until,due) end
            end
            if time>record.Until then casts[skill]=nil else count+=1 end
        end
        local added=0
        for _,part in ipairs(ctx.Collection:GetTagged("LavaGyzer Point")) do
            added+=1;if added>48 then break end
            if part.Parent and part:IsA("BasePart") then
                local record=points[part]
                if not record then
                    record={Started=time}
                    local lifetime=part.GetAttribute and part:GetAttribute("Lifetime")
                    if type(lifetime)=="number" and lifetime>=0 and lifetime<=15 then record.Lifetime=lifetime end
                end
                record.Position=part.Position;record.Radius=math.max(part.Size.X,part.Size.Z)*.5;record.Until=time+1
                record.SeenAt=time;record.RemovedAt=nil
                points[part]=record
            end
        end
        for part,record in pairs(points) do
            if record.SeenAt~=time and record.Lifetime then
                record.RemovedAt=record.RemovedAt or time
                local margin=math.clamp(.1+(state.PingMs or 0)/1000,.15,.35)
                record.Until=math.max(record.Started+record.Lifetime+.15+margin,record.RemovedAt+.15+margin)
            end
            if time>record.Until then points[part]=nil else count+=1 end
        end
        api.ThreatCount=count
        local smashCenter
        for _,record in pairs(casts) do
            if record.Name=="LavaSmash" then smashCenter=record.Skill.SurfacePosition or smashCenter end
        end
        api.Anchor=smashCenter or closest
        api.NearBoss=api.Anchor~=nil and (api.Anchor-point).Magnitude<=api.MaxBossDistance
        return time
    end
    local function danger(point)
        local margin=8+math.min(4,(state.PingMs or 0)/100)
        for _,record in pairs(casts) do
            local skill=record.Skill
            if record.Name=="LavaSmash" and skill.SurfacePosition then
                local delta=(point-skill.SurfacePosition)*flat
                local radius=api.SmashRadius+margin
                if delta:Dot(delta)<radius*radius then return true,"LavaSmash" end
            end
            if record.Name=="FireDash" and skill.SurfacePosition and skill.FocusPosition then
                if record.CompletedAt and record.AssetsKnown and now()>=record.CompletedAt+record.ReturnMargin then
                    for part in pairs(record.Assets) do
                        if part.Parent then
                            local p=part.CFrame:PointToObjectSpace(Vector3.new(point.X,part.Position.Y,point.Z))
                            if math.abs(p.X)<part.Size.X*.5+margin and math.abs(p.Z)<part.Size.Z*.5+margin then return true,"FireDash flames" end
                        end
                    end
                    continue
                end
                local a=skill.SurfacePosition*flat
                local line=(skill.FocusPosition-skill.SurfacePosition)*flat
                local delta=point*flat-a
                local length=line:Dot(line)
                local alpha=length>.01 and math.clamp(delta:Dot(line)/length,0,1) or 0
                local width=(tonumber(skill.Width) or 0)*.5+10+margin
                local offset=delta-line*alpha
                if offset:Dot(offset)<width*width then return true,"FireDash" end
            end
        end
        for _,record in pairs(points) do
            local delta=(point-record.Position)*flat
            local radius=record.Radius+margin
            if delta:Dot(delta)<radius*radius then return true,"LavaGyzer" end
        end
        if api.ThreatCount>0 and ctx.Warnings then
            local unsafe,reason=ctx.Warnings.IsThreatened(point)
            if unsafe then return true,reason end
        end
        return false
    end
    function api.Reset()table.clear(casts);table.clear(points);lastPoint=nil;nextPlan=0;api.ThreatCount=0;api.Active=false;api.NearBoss=false end
    function api.Plan(point,desired,floorY)
        if disposed or not state.AtheonDodge or not state.Running or state.SafeModePanic or state.TravelBusy or state.Recovering then
            api.Reset();return nil
        end
        local time=update(point)
        if api.ThreatCount==0 then
            api.Active=false;lastPoint=nil
            return nil
        end
        local function valid(candidate)
            return candidate and ctx.Valid(candidate) and (candidate-point).Magnitude<=api.MaxStep
                and api.Anchor and (candidate-api.Anchor).Magnitude<=api.MaxBossDistance
        end
        local function shallow()
            local floor=floorY and floorY(point)
            local candidate=type(floor)=="number" and Vector3.new(point.X,floor-20,point.Z) or nil
            return valid(candidate) and candidate or nil
        end
        if ctx.Warnings and api.ThreatCount>0 then ctx.Warnings.RefreshThreats() end
        -- Evade the impact laterally; going only 20 below its center still gets hit.
        local unsafe,reason=danger(point)
        local wanted,wantedReason=danger(desired or point)
        if not unsafe and not wanted then api.Active=false;lastPoint=nil;return nil end
        if lastPoint and valid(lastPoint) and not danger(lastPoint) then api.Active=true;return lastPoint,api.LastReason end
        if time<nextPlan then return nil end
        nextPlan=time+.1
        lastPoint=nil
        if not unsafe and valid(point) then lastPoint=point
        elseif reason=="LavaSmash" and api.Anchor then
            -- Search one ring around the impact, not hundreds of floor raycasts.
            local floor=floorY and floorY(point)
            local y=type(floor)=="number" and floor-20 or point.Y
            local radius=api.SmashRadius+8+math.min(4,(state.PingMs or 0)/100)+6
            if state.FarmAbove then
                local vertical=math.sqrt(math.max(0,api.MaxBossDistance^2-radius^2))-1
                y=math.clamp(point.Y,api.Anchor.Y-vertical,api.Anchor.Y+vertical)
            end
            local best
            for i=1,16 do
                local angle=i*math.pi/8
                local candidate=Vector3.new(api.Anchor.X+math.cos(angle)*radius,y,api.Anchor.Z+math.sin(angle)*radius)
                local distance=(candidate-point).Magnitude
                if valid(candidate) and not danger(candidate) and (not best or distance<best) then lastPoint,best=candidate,distance end
            end
        else
            local floor
            if reason=="LavaSmash" or wantedReason=="LavaSmash" then floor=floorY and floorY(point) end
            for radius=8,api.MaxStep,8 do
                for i=1,16 do
                    local angle=i*math.pi/8
                    local candidate=point+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                    if reason=="LavaSmash" or wantedReason=="LavaSmash" then
                        if type(floor)=="number" then candidate=Vector3.new(candidate.X,floor-20,candidate.Z) end
                    end
                    if valid(candidate) and not danger(candidate) then lastPoint=candidate;break end
                end
                if lastPoint then break end
            end
        end
        if not lastPoint then
            local fallback=shallow()
            if fallback and not danger(fallback) then lastPoint=fallback end
        end
        if lastPoint then
            api.Active=true;api.LastReason=reason or wantedReason or "Atheon warning"
            api.Moves+=1
            return lastPoint,api.LastReason
        end
        api.Active=false;return nil
    end
    function api.Destroy()disposed=true;api.Reset()end
    return api
end
