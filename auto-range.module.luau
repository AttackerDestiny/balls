return function(ctx)
    local state=ctx.State
    local clock=ctx.Clock or os.clock
    local api={Cap=120,Profiles=setmetatable({}, {__mode="k"})}
    local nextUpdate=0
    state.AutoRangeCap=api.Cap
    function api.BodyRange(data)
        local size=data.Root.Size
        return math.min(api.Cap,math.max(size.X,size.Z)*.5+20)
    end
    function api.Delta(data,root)
        local height=(root.Size.Y-data.Root.Size.Y)*.5
        local point=data.Root.Position+Vector3.new(0,height,0)
        local motion=data.Motion
        if motion and motion.Parent==data.Root then
            local velocity=motion:IsA("LinearVelocity") and motion.VectorVelocity
                or motion:IsA("BodyVelocity") and motion.Velocity
            if velocity and velocity.Magnitude>1 then point+=velocity.Unit end
        end
        return point-root.Position
    end
    local function profile(kind,data,skill)
        local entries=api.Profiles[data]
        if not entries then entries={}; api.Profiles[data]=entries end
        local key=kind=="Skill" and "Skill:"..tostring(skill or state.SelectedSkill) or "Kill"
        if state.AutoFarm and state.FarmAbove then key="Above:"..key end
        local value=entries[key]
        if not value or value.Size~=data.Root.Size then
            value={Size=data.Root.Size,Limit=api.BodyRange(data),Samples={},NextProbe=0}
            entries[key]=value
        end
        return value
    end
    function api.Range(kind,data,skill)
        local value=profile(kind,data,skill)
        local now,body=clock(),api.BodyRange(data)
        if value.Limit<body and now>=value.NextProbe then
            if now-(value.LastSample or 0)>12 then value.Limit=body
            elseif value.LastHit and now-value.LastHit<6 then value.Limit=math.min(body,value.Limit+1) end
            value.NextProbe=now+6
        end
        return math.min(body,value.Limit)
    end
    function api.Record(kind,distance,damage,data,skill)
        if not data or (kind~="Kill" and kind~="Skill") or type(distance)~="number"
            or distance~=distance or distance>api.Cap or distance<0 then return end
        local value=profile(kind,data,skill)
        local now=clock()
        value.LastSample=now
        if type(damage)=="number" and damage>0 then value.LastHit=now end
        local samples=value.Samples
        samples[#samples+1]={At=now,Distance=distance,Damage=damage or 0}
        if #samples>12 then table.remove(samples,1) end
        local hits,misses,maxHit,nearestMiss=0,0,0,math.huge
        for i=#samples,1,-1 do
            local sample=samples[i]
            if now-sample.At>12 then table.remove(samples,i)
            elseif sample.Damage>0 then hits+=1; maxHit=math.max(maxHit,sample.Distance)
            else misses+=1; nearestMiss=math.min(nearestMiss,sample.Distance) end
        end
        local limit=api.Range(kind,data,skill)
        if hits>0 then limit=math.min(api.BodyRange(data),math.max(limit,maxHit+1)) end
        -- Close misses can mean cooldown, stamina, or invulnerability. Only
        -- learn a shorter reach from repeated misses at the outer boundary.
        if misses>=2 and hits>0 and nearestMiss>maxHit+2 and nearestMiss>=limit-3 then
            limit=math.min(limit,math.max(20,math.ceil(maxHit+2)))
        elseif hits==0 and misses>=3 and nearestMiss>=limit-3 then
            limit=math.max(20,limit-2)
        end
        if limit~=value.Limit then value.Limit=limit; value.NextProbe=now+6 end
    end
    function api.Update()
        local now=clock()
        if now<nextUpdate then return end
        nextUpdate=now+.5
        local data=ctx.PrimaryData and ctx.PrimaryData()
        for _,kind in ipairs({"Kill","Skill"}) do
            local current=kind=="Kill" and state.Radius or state.SkillRange
            local effective=data and api.Range(kind,data,state.SelectedSkill) or math.clamp(current,20,api.Cap)
            local desired=math.ceil(effective)
            if desired~=current then
                if kind=="Kill" then ctx.SetKill(desired) else ctx.SetSkill(desired) end
            end
            local text=string.format("Auto · %.1f / %d studs",effective,api.Cap)
            if kind=="Kill" then state.KillRangeStatus=text else state.SkillRangeStatus=text end
        end
    end
    return api
end
