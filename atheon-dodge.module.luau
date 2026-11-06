-- Bounded evasion uses native cast lifecycles, flame assets, and geyser markers.
return function(ctx)
    local api={Moves=0,Seen={},Completed={},ThreatCount=0,MaxStep=112,MaxBossDistance=128,SmashRadius=90}
    local state=ctx.State
    local clock=ctx.Now or os.clock
    local casts,markers={},{}
    local closed=false
    local route={Point=nil,Due=0}
    local flat=Vector3.new(1,0,1)
    local supported={FireDash=true,LavaSmash=true,LavaGyzer=true}
    local function margin()return math.clamp(.1+(state.PingMs or 0)/1000,.15,.35)end
    local function registry(boss)
        local rig=(ctx.Native.RiggedEnemies or {})[boss]
        return rig and rig.ActiveSkills
    end
    local function collectAssets(entry,ended)
        if entry.Name~="FireDash"then return end
        entry.Assets=entry.Assets or {}
        for _,part in pairs(entry.Skill.CreatedAssets or {})do
            if part.Parent and part:IsA("BasePart")then entry.Assets[part]=true;entry.AssetsKnown=true end
        end
        if not ended or entry.AssetQueryDone or not ctx.FireAssets then return end
        entry.AssetQueryDone=true
        local ok,parts=pcall(ctx.FireAssets,entry.Skill)
        if ok and type(parts)=="table"then
            entry.AssetsKnown=true
            for _,part in ipairs(parts)do entry.Assets[part]=true end
        end
    end
    local function airborne(entry,time)
        if entry.Name~="LavaSmash"then return false end
        if time-entry.Started>=14 then return true end
        local position=ctx.Position(entry.Boss)
        local ground=entry.Skill.LastCFrame and entry.Skill.LastCFrame.Position or entry.Skill.SurfacePosition
        if not position or not ground then return true end
        local grounded=ctx.Grounded and ctx.Grounded(entry.Boss)or (not ctx.Grounded and math.abs(position.Y-ground.Y)<=6)
        if not grounded and position.Y>ground.Y+6 then
            entry.WasAirborne=true;entry.CompletedAt=nil;entry.Until=math.max(entry.Until,time+1.2)
        elseif grounded and entry.WasAirborne and not entry.LandedAt then
            entry.LandedAt=time;entry.Until=math.max(entry.Until,time+1.2+(state.PingMs or 0)/1000)
        end
        return not grounded
    end
    local function settle(entry,time)
        local active=registry(entry.Boss)
        local ended=entry.Skill.Destroyed==true or (active and active[entry.Name]~=entry.Skill)
        collectAssets(entry,ended)
        if not ended or airborne(entry,time)then return end
        if not entry.CompletedAt then
            entry.CompletedAt=time;entry.ReturnMargin=margin()
            api.LastSkillEndAt=time;api.LastSkillEndName=entry.Name;api.LastReturnMargin=entry.ReturnMargin
            api.Completed[entry.Name]={At=time,Margin=entry.ReturnMargin}
        end
        local ready=entry.CompletedAt+entry.ReturnMargin
        if entry.Name~="FireDash"then entry.Until=math.min(entry.Until,ready);return end
        if not entry.AssetsKnown then return end
        local hasFlames=false
        for part in pairs(entry.Assets)do if part.Parent then hasFlames=true else entry.Assets[part]=nil end end
        entry.Until=hasFlames and math.min(entry.CompletedAt+3.2,math.max(ready,time+.2))or ready
    end
    local function discover(point,time)
        local nearest,gap
        for _,boss in ipairs(ctx.Bosses())do
            local position=ctx.Position(boss)
            local distance=position and (position-point).Magnitude
            if distance and (not gap or distance<gap)then nearest=position;gap=distance end
            for name,skill in pairs(registry(boss)or {})do
                if supported[name]and not skill.Destroyed then
                    local entry=casts[skill]
                    if not entry then
                        entry={Name=name,Skill=skill,Boss=boss,Started=time}
                        if name=="LavaSmash"then entry.MinimumUntil=time+math.clamp(tonumber(skill.Lifetime)or 3,1,8)+1.2+(state.PingMs or 0)/1000 end
                        casts[skill]=entry;api.Seen[name]=(api.Seen[name]or 0)+1
                    end
                    local tail=name=="FireDash"and 3.2 or name=="LavaGyzer"and 1 or .8
                    entry.Until=math.max(entry.MinimumUntil or 0,time+tail)
                end
            end
        end
        return nearest
    end
    local function sampleMarkers(time)
        for index,part in ipairs(ctx.Collection:GetTagged("LavaGyzer Point"))do
            if index>48 then break end
            if part.Parent and part:IsA("BasePart")then
                local entry=markers[part]
                if not entry then
                    entry={Started=time}
                    local duration=part.GetAttribute and part:GetAttribute("Lifetime")
                    if type(duration)=="number"and duration>=0 and duration<=15 then entry.Lifetime=duration end
                    markers[part]=entry
                end
                entry.Position=part.Position;entry.Radius=math.max(part.Size.X,part.Size.Z)*.5
                entry.Until=time+1;entry.SeenAt=time;entry.RemovedAt=nil
            end
        end
        local count=0
        for part,entry in pairs(markers)do
            if entry.SeenAt~=time and entry.Lifetime then
                entry.RemovedAt=entry.RemovedAt or time
                local padding=.15+margin()
                entry.Until=math.max(entry.Started+entry.Lifetime+padding,entry.RemovedAt+padding)
            end
            if time>entry.Until then markers[part]=nil else count+=1 end
        end
        return count
    end
    local function refresh(point,time)
        local nearest=discover(point,time)
        local count=sampleMarkers(time)
        local impact
        for skill,entry in pairs(casts)do
            -- Grounded state must be tracked even while the skill remains active.
            if entry.Name=="LavaSmash"then airborne(entry,time)end
            settle(entry,time)
            if time>entry.Until then casts[skill]=nil
            else count+=1;if entry.Name=="LavaSmash"then impact=entry.Skill.SurfacePosition or impact end end
        end
        api.Anchor=impact or nearest;api.ThreatCount=count
        api.NearBoss=api.Anchor~=nil and (api.Anchor-point).Magnitude<=api.MaxBossDistance
    end
    local function flameThreat(entry,point,padding)
        for part in pairs(entry.Assets)do
            if part.Parent then
                local localPoint=part.CFrame:PointToObjectSpace(Vector3.new(point.X,part.Position.Y,point.Z))
                if math.abs(localPoint.X)<part.Size.X*.5+padding and math.abs(localPoint.Z)<part.Size.Z*.5+padding then return true end
            end
        end
        return false
    end
    local function castThreat(entry,point,padding)
        local skill=entry.Skill
        if entry.Name=="LavaSmash"and skill.SurfacePosition then
            local delta=(point-skill.SurfacePosition)*flat
            return delta:Dot(delta)<(api.SmashRadius+padding)^2,"LavaSmash"
        end
        if entry.Name~="FireDash"or not skill.SurfacePosition or not skill.FocusPosition then return false end
        if entry.CompletedAt and entry.AssetsKnown and clock()>=entry.CompletedAt+entry.ReturnMargin then return flameThreat(entry,point,padding),"FireDash flames"end
        local segment=(skill.FocusPosition-skill.SurfacePosition)*flat
        local delta=(point-skill.SurfacePosition)*flat
        local length=segment:Dot(segment)
        local alpha=length>.01 and math.clamp(delta:Dot(segment)/length,0,1)or 0
        local offset=delta-segment*alpha
        local width=(tonumber(skill.Width)or 0)*.5+10+padding
        return offset:Dot(offset)<width*width,"FireDash"
    end
    local function threatened(point)
        local padding=8+math.min(4,(state.PingMs or 0)/100)
        for _,entry in pairs(casts)do local hit,reason=castThreat(entry,point,padding);if hit then return true,reason end end
        for _,entry in pairs(markers)do
            local delta=(point-entry.Position)*flat
            if delta:Dot(delta)<(entry.Radius+padding)^2 then return true,"LavaGyzer"end
        end
        if api.ThreatCount>0 and ctx.Warnings then return ctx.Warnings.IsThreatened(point)end
        return false
    end
    function api.Reset()
        table.clear(casts);table.clear(markers);route.Point=nil;route.Due=0
        api.ThreatCount=0;api.Active=false;api.NearBoss=false
    end
    function api.Plan(point,desired,floorY)
        if closed or not state.Running or not state.AtheonDodge or state.SafeModePanic or state.TravelBusy or state.Recovering then api.Reset();return nil end
        local time=clock();refresh(point,time)
        if api.ThreatCount==0 then api.Active=false;route.Point=nil;return nil end
        if ctx.Warnings then ctx.Warnings.RefreshThreats()end
        local danger,reason=threatened(point)
        local targetDanger,targetReason=threatened(desired or point)
        if not danger and not targetDanger then api.Active=false;route.Point=nil;return nil end
        local function valid(candidate)
            return candidate and api.Anchor and ctx.Valid(candidate)and (candidate-point).Magnitude<=api.MaxStep
                and (candidate-api.Anchor).Magnitude<=api.MaxBossDistance
        end
        local function safe(candidate)return valid(candidate)and not threatened(candidate)end
        if route.Point and safe(route.Point)then api.Active=true;return route.Point,api.LastReason end
        if time<route.Due then return nil end
        route.Due=time+.1
        local chosen
        if not danger and valid(point)then chosen=point
        elseif reason=="LavaSmash"and api.Anchor then
            local ground=floorY and floorY(point)
            local y=type(ground)=="number"and ground-20 or point.Y
            local radius=api.SmashRadius+14+math.min(4,(state.PingMs or 0)/100)
            if state.FarmAbove then
                local vertical=math.sqrt(math.max(0,api.MaxBossDistance^2-radius^2))-1
                y=math.clamp(point.Y,api.Anchor.Y-vertical,api.Anchor.Y+vertical)
            end
            local best
            for direction=1,16 do
                local angle=direction*math.pi/8
                local candidate=Vector3.new(api.Anchor.X+math.cos(angle)*radius,y,api.Anchor.Z+math.sin(angle)*radius)
                local distance=(candidate-point).Magnitude
                if safe(candidate)and (not best or distance<best)then chosen=candidate;best=distance end
            end
        else
            local smash=reason=="LavaSmash"or targetReason=="LavaSmash"
            local ground=smash and floorY and floorY(point)
            for radius=8,api.MaxStep,8 do
                if chosen then break end
                for direction=1,16 do
                    local angle=direction*math.pi/8
                    local candidate=point+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                    if type(ground)=="number"then candidate=Vector3.new(candidate.X,ground-20,candidate.Z)end
                    if safe(candidate)then chosen=candidate;break end
                end
            end
        end
        if not chosen then
            local floor=floorY and floorY(point)
            local shallow=type(floor)=="number"and Vector3.new(point.X,floor-20,point.Z)
            if safe(shallow)then chosen=shallow end
        end
        route.Point=chosen;api.Active=chosen~=nil
        if chosen then api.LastReason=reason or targetReason or "Atheon warning";api.Moves+=1;return chosen,api.LastReason end
    end
    function api.Destroy()closed=true;api.Reset()end
    return api
end
