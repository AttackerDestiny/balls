-- Coordinate only replicated damage contribution; never mutate enemy HP/counters.
return function(ctx)
    local api={}
    local pending=setmetatable({}, {__mode="k"})
    local state=ctx.State
    local function status(text)state.CreditCheckStatus=text end
    function api.Reset()table.clear(pending)end
    function api.Observe(mob,data)
        local flight=pending[mob]
        local own=ctx.Damage(data,ctx.Self())
        if flight and own and own>flight.Before then
            if ctx.Planner and flight.Key then ctx.Planner.Learn(flight.Key,own-flight.Before)end
            pending[mob]=nil
        end
    end
    local groupWasReady
    local function groupReady()
        local members=ctx.Members()
        local missing={}
        for _,person in ipairs(members)do
            if type(person)=="table"and person.CreditMissing then missing[#missing+1]=person.Name end
        end
        local ready=#missing==0 and #members>1
        if ready~=groupWasReady then table.clear(pending);groupWasReady=ready end
        return ready,members,missing
    end
    function api.Allow(mob,data)
        api.Bypass=false
        if not state.CreditCheck or ctx.Rank(mob)>2 then return true end
        local ready,members,missing=groupReady()
        if not ready then
            api.Bypass=true;pending[mob]=nil
            status(#missing>0 and ("Credit Check inactive · missing from server: "..table.concat(missing,", "))or "Credit Check inactive · no other accounts in whitelist")
            return true
        end
        local maximum=ctx.MaxHealth(data)
        if type(maximum)~="number"or maximum~=maximum or maximum<=0 or maximum==math.huge then
            status("Credit Check · waiting for maximum HP");return false
        end
        local required=maximum*.05
        api.Observe(mob,data)
        local own=ctx.Damage(data,ctx.Self())or 0
        local waiting,total,noCounter,below=0,0,{},{}
        for _,person in ipairs(members)do
            total+=1
            local damage=ctx.Damage(data,person)
            if damage==nil then noCounter[#noCounter+1]=person.Name end
            if (type(person)=="table"and person.CreditMissing)or (damage or 0)<required then
                waiting+=1
                if damage~=nil and not(type(person)=="table"and person.CreditMissing)then
                    below[#below+1]=person.Name.." "..math.floor(damage).."/"..math.ceil(required)
                end
            end
        end
        if waiting==0 then pending[mob]=nil;status("Credit Check · everyone qualified · finishing");return true end
        if total>20 then status("Credit Check · more than 20 accounts cannot each receive 5% of one HP pool");return false end
        local detail
        if #noCounter>0 then detail="no replicated damage counter: "..table.concat(noCounter,", ")
        else detail="below required: "..table.concat(below,", ")end
        if own>=required then
            pending[mob]=nil
            status("Credit Check · qualified · "..detail)
            return false
        end
        local flight=pending[mob]
        if flight then
            if own<flight.Before then pending[mob]=nil
            elseif own>flight.Before then pending[mob]=nil
            elseif ctx.Now()<flight.Deadline then status("Credit Check · waiting for damage acknowledgment");return false
            else pending[mob]=nil end
        end
        status("Credit Check · "..math.floor(own).." / "..math.ceil(required).." · "..detail)
        return true
    end
    function api.AllowAction(mob,data,kind)
        api.ActionReason=nil
        if not api.Allow(mob,data)then
            local maximum=ctx.MaxHealth(data)
            api.ActionReason=type(maximum)=="number"and (ctx.Damage(data,ctx.Self())or 0)>=maximum*.05 and "Qualified"or "Waiting"
            return false
        end
        if api.Bypass or not state.CreditCheck or ctx.Rank(mob)>2 or not ctx.Planner or not ctx.Options then return true end
        local own=ctx.Damage(data,ctx.Self())
        if own==nil and kind=="Normal"then return true end -- Native skill registration.
        local remaining=ctx.MaxHealth(data)*.05-(own or 0)
        if remaining<=0 then return true end -- Everyone qualifies; unrestricted damage.
        local options=ctx.Options(mob,data,kind)
        local normal=ctx.Planner.Estimate(options.NormalKey)
        local skill=ctx.Planner.Estimate(options.CastKey or options.SkillKey)
        if normal<=0 then normal=options.NormalEstimate or 0 end
        if skill<=0 then skill=options.SkillEstimate or 0 end
        -- During a running skill, allow its individual hits until one normal
        -- hit is enough. Activation planning uses the observed whole-cast total.
        if kind=="Skill"and options.ActiveSkill then
            if options.CanNormal and normal>0 and remaining<=normal then api.ActionReason="Normal";return false end
            api.ActionReason="Skill";return true
        end
        local chosen,plan=ctx.Planner.Choose(remaining,normal,skill,options.CanNormal,options.CanSkill)
        state.CreditDamagePlan=plan
        if chosen then
            status(plan.Calibrating and ("Credit Check · learning "..chosen.." damage")
                or ("Credit Check · remaining "..math.ceil(remaining).." · plan "..plan.Skill.." skill hit(s) + "..plan.Normal.." normal hit(s)"))
        end
        api.ActionReason=chosen
        return chosen==(kind=="SkillStart"and "Skill"or kind)
    end
    function api.Sent(mob,data,kind)
        if not state.CreditCheck or ctx.Rank(mob)>2 then return end
        if not groupReady()then pending[mob]=nil;return end
        local maximum=ctx.MaxHealth(data)
        local own=ctx.Damage(data,ctx.Self())or 0
        if type(maximum)=="number"and maximum>0 and own<maximum*.05 then
            local options=ctx.Options and ctx.Options(mob,data,kind or "Normal")
            pending[mob]={Key=options and ((kind=="Skill")and options.SkillKey or options.NormalKey),Before=own,Deadline=ctx.Now()+math.clamp((state.PingMs or 100)/1000+.25,.4,1.5)}
        end
    end
    return api
end
