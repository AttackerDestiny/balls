-- Range learning is isolated by enemy data, attack mode, skill, and farming side.
return function(ctx)
    local api={Cap=120,Profiles=setmetatable({}, {__mode="k"})}
    local state=ctx.State
    local clock=ctx.Clock or os.clock
    local due=0
    state.AutoRangeCap=api.Cap
    function api.BodyRange(data)return math.min(api.Cap,math.max(data.Root.Size.X,data.Root.Size.Z)*.5+20)end
    function api.Delta(data,root)
        local center=data.Root.Position+Vector3.new(0,(root.Size.Y-data.Root.Size.Y)*.5,0)
        local mover=data.Motion
        if mover and mover.Parent==data.Root then
            local velocity=mover:IsA("LinearVelocity")and mover.VectorVelocity or mover:IsA("BodyVelocity")and mover.Velocity
            if velocity and velocity.Magnitude>1 then center+=velocity.Unit end
        end
        return center-root.Position
    end
    local function entry(kind,data,skill)
        local group=api.Profiles[data]
        if not group then group={};api.Profiles[data]=group end
        local key=kind=="Skill"and "Skill:"..tostring(skill or state.SelectedSkill)or "Kill"
        if state.AutoFarm and state.FarmAbove then key="Above:"..key end
        local value=group[key]
        if not value or value.Size~=data.Root.Size then
            value={Size=data.Root.Size,Limit=api.BodyRange(data),Samples={},NextProbe=0};group[key]=value
        end
        return value
    end
    function api.Range(kind,data,skill)
        local profile=entry(kind,data,skill)
        local time=clock();local maximum=api.BodyRange(data)
        if profile.Limit<maximum and time>=profile.NextProbe then
            if time-(profile.LastSample or 0)>12 then profile.Limit=maximum
            elseif profile.LastHit and time-profile.LastHit<6 then profile.Limit=math.min(maximum,profile.Limit+1)end
            profile.NextProbe=time+6
        end
        return math.min(maximum,profile.Limit)
    end
    local function statistics(samples,time)
        local hits,misses,farthest,nearest=0,0,0,math.huge
        for i=#samples,1,-1 do
            local sample=samples[i]
            if time-sample.At>12 then table.remove(samples,i)
            elseif sample.Damage>0 then hits+=1;farthest=math.max(farthest,sample.Distance)
            else misses+=1;nearest=math.min(nearest,sample.Distance)end
        end
        return hits,misses,farthest,nearest
    end
    function api.Record(kind,distance,damage,data,skill)
        if not data or (kind~="Kill"and kind~="Skill")or type(distance)~="number"or distance~=distance or distance<0 or distance>api.Cap then return end
        local profile=entry(kind,data,skill);local time=clock()
        profile.LastSample=time
        if type(damage)=="number"and damage>0 then profile.LastHit=time end
        local samples=profile.Samples
        if #samples==12 then table.remove(samples,1)end
        samples[#samples+1]={At=time,Distance=distance,Damage=damage or 0}
        local hits,misses,farthest,nearest=statistics(samples,time)
        local limit=api.Range(kind,data,skill)
        if hits>0 then limit=math.min(api.BodyRange(data),math.max(limit,farthest+1))end
        if nearest>=limit-3 then
            if hits>0 and misses>=2 and nearest>farthest+2 then limit=math.min(limit,math.max(20,math.ceil(farthest+2)))
            elseif hits==0 and misses>=3 then limit=math.max(20,limit-2)end
        end
        if profile.Limit~=limit then profile.Limit=limit;profile.NextProbe=time+6 end
    end
    local function present(kind,data)
        local current=kind=="Kill"and state.Radius or state.SkillRange
        local effective=data and api.Range(kind,data,state.SelectedSkill)or math.clamp(current,20,api.Cap)
        local value=math.ceil(effective)
        if value~=current then if kind=="Kill"then ctx.SetKill(value)else ctx.SetSkill(value)end end
        state[kind=="Kill"and "KillRangeStatus"or "SkillRangeStatus"]=string.format("Auto · %.1f / %d studs",effective,api.Cap)
    end
    function api.Update(now)
        now=now or clock()
        if now<due then return end
        due=now+.5
        local data=ctx.PrimaryData and ctx.PrimaryData()
        present("Kill",data);present("Skill",data)
    end
    return api
end
