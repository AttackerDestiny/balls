-- Group admission, per-enemy acknowledgment leases, and action planning share one gate.
return function(ctx)
    local state=ctx.State
    local api={}
    local flights=setmetatable({}, {__mode="k"})
    local group={}
    local function status(text)state.CreditCheckStatus=text end
    local function contribution(data,person)
        local value=ctx.Damage(data,person)
        if type(value)~="number"or value~=value or math.abs(value)==math.huge then return nil end
        return value
    end
    local function roster()
        local members=ctx.Members()
        if group.Members==members then return group.Ready,members,group.Missing end
        local missing,ids={},{}
        for _,person in ipairs(members)do
            local absent=type(person)=="table"and person.CreditMissing==true
            ids[#ids+1]=tostring(person.UserId or person.Name)..":"..tostring(absent)
            if absent then missing[#missing+1]=person.Name end
        end
        table.sort(ids)
        local signature=table.concat(ids,"|")
        if signature~=group.Signature then table.clear(flights)end
        group={Members=members,Missing=missing,Ready=#members>1 and #missing==0,Signature=signature}
        return group.Ready,members,missing
    end
    function api.Reset()table.clear(flights);group={};state.CreditDamagePlan=nil end
    function api.Observe(target,data)
        local pending=flights[target]
        local value=contribution(data,ctx.Self())
        if not pending or not value or value<=pending.Before then return end
        if ctx.Planner and pending.Key then ctx.Planner.Learn(pending.Key,value-pending.Before)end
        flights[target]=nil
    end
    function api.FarmTarget(locked,candidates,valid,less)
        if not state.CreditCheck or not roster()then return locked end
        local best
        for candidate in pairs(candidates)do
            if ctx.Rank(candidate)<=2 and valid(candidate)and (not best or less(candidate,best))then best=candidate end
        end
        return best or locked
    end
    local function maximum(data)
        local value=ctx.MaxHealth(data)
        if type(value)=="number"and value==value and value>0 and value<math.huge then return value end
    end
    local function progress(data,members,required)
        local result={Waiting=0,Unknown={},Partial={}}
        for _,person in ipairs(members)do
            local value=contribution(data,person)
            if value==nil then result.Unknown[#result.Unknown+1]=person.Name end
            if (type(person)=="table"and person.CreditMissing)or (value or 0)<required then
                result.Waiting+=1
                if value~=nil and not(type(person)=="table"and person.CreditMissing)then
                    result.Partial[#result.Partial+1]=person.Name.." "..math.floor(value).."/"..math.ceil(required)
                end
            end
        end
        return result
    end
    function api.Allow(target,data)
        api.Bypass=false
        if not state.CreditCheck or ctx.Rank(target)>2 then return true end
        local ready,members,missing=roster()
        if not ready then
            api.Bypass=true;flights[target]=nil
            status(#missing>0 and "Credit Check inactive · missing from server: "..table.concat(missing,", ")or "Credit Check inactive · no other accounts in whitelist")
            return true
        end
        local max=maximum(data)
        if not max then status("Credit Check · waiting for maximum HP");return false end
        local required=max*.05
        api.Observe(target,data)
        local own=contribution(data,ctx.Self())or 0
        local observed=progress(data,members,required)
        if observed.Waiting==0 then flights[target]=nil;status("Credit Check · everyone qualified · finishing");return true end
        if #members>20 then status("Credit Check · more than 20 accounts cannot each receive 5% of one HP pool");return false end
        local detail=#observed.Unknown>0 and "no replicated damage counter on "..tostring(target.Name or "this enemy")..": "..table.concat(observed.Unknown,", ")
            or "below required: "..table.concat(observed.Partial,", ")
        if own>=required then
            flights[target]=nil
            status("Credit Check · you qualified · group "..(#members-observed.Waiting).."/"..#members.." ready · "..detail)
            return false
        end
        local pending=flights[target]
        if pending then
            if own==pending.Before and ctx.Now()<pending.Deadline then status("Credit Check · waiting for damage acknowledgment");return false end
            flights[target]=nil
        end
        status("Credit Check · "..math.floor(own).." / "..math.ceil(required).." · "..detail)
        return true
    end
    function api.AllowAction(target,data,kind)
        api.ActionReason=nil
        if not api.Allow(target,data)then
            local max=maximum(data)
            api.ActionReason=max and (contribution(data,ctx.Self())or 0)>=max*.05 and "Qualified"or "Waiting"
            return false
        end
        if api.Bypass or not state.CreditCheck or ctx.Rank(target)>2 or not ctx.Planner or not ctx.Options then return true end
        local own=contribution(data,ctx.Self())
        if own==nil and kind=="Normal"then return true end
        local remaining=ctx.MaxHealth(data)*.05-(own or 0)
        if remaining<=0 then return true end
        local options=ctx.Options(target,data,kind)
        local normal=ctx.Planner.Estimate(options.NormalKey)
        local skill=ctx.Planner.Estimate(options.CastKey or options.SkillKey)
        normal=normal>0 and normal or options.NormalEstimate or 0
        skill=skill>0 and skill or options.SkillEstimate or 0
        if kind=="Skill"and options.ActiveSkill then
            api.ActionReason=options.CanNormal and normal>0 and remaining<=normal and "Normal"or "Skill"
            return api.ActionReason=="Skill"
        end
        local chosen,plan=ctx.Planner.Choose(remaining,normal,skill,options.CanNormal,options.CanSkill)
        state.CreditDamagePlan=plan;api.ActionReason=chosen
        if chosen then
            status(plan.Calibrating and "Credit Check · learning "..chosen.." damage"or "Credit Check · remaining "..math.ceil(remaining).." · plan "..plan.Skill.." skill hit(s) + "..plan.Normal.." normal hit(s)")
        end
        return chosen==(kind=="SkillStart"and "Skill"or kind)
    end
    function api.Sent(target,data,kind)
        if not state.CreditCheck or ctx.Rank(target)>2 then return end
        if not roster()then flights[target]=nil;return end
        local max=maximum(data);local own=contribution(data,ctx.Self())or 0
        if not max or own>=max*.05 then return end
        local options=ctx.Options and ctx.Options(target,data,kind or "Normal")
        local key=options and (kind=="Skill"and options.SkillKey or options.NormalKey)
        flights[target]={Key=key,Before=own,Deadline=ctx.Now()+math.clamp((state.PingMs or 100)/1000+.25,.4,1.5)}
    end
    return api
end
