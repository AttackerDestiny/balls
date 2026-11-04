-- Coordinate only replicated damage contribution; never mutate enemy HP/counters.
return function(ctx)
    local api={}
    local pending=setmetatable({}, {__mode="k"})
    local state=ctx.State
    local function status(text)state.CreditCheckStatus=text end
    function api.Reset()table.clear(pending)end
    function api.Allow(mob,data)
        if not state.CreditCheck or ctx.Rank(mob)>2 then return true end
        local maximum=ctx.MaxHealth(data)
        if type(maximum)~="number"or maximum~=maximum or maximum<=0 or maximum==math.huge then
            status("Credit Check · waiting for maximum HP");return false
        end
        local required=maximum*.05
        local members=ctx.Members()
        local own=ctx.Damage(data,ctx.Self())or 0
        local waiting,total,missing,noCounter,below=0,0,{},{},{}
        for _,person in ipairs(members)do
            total+=1
            local damage=ctx.Damage(data,person)
            if type(person)=="table"and person.CreditMissing then missing[#missing+1]=person.Name
            elseif damage==nil then noCounter[#noCounter+1]=person.Name end
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
        if #missing>0 then detail="not in this server: "..table.concat(missing,", ")
        elseif #noCounter>0 then detail="no replicated damage counter: "..table.concat(noCounter,", ")
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
    function api.Sent(mob,data)
        if not state.CreditCheck or ctx.Rank(mob)>2 then return end
        local maximum=ctx.MaxHealth(data)
        local own=ctx.Damage(data,ctx.Self())or 0
        if type(maximum)=="number"and maximum>0 and own<maximum*.05 then
            pending[mob]={Before=own,Deadline=ctx.Now()+math.clamp((state.PingMs or 100)/1000+.25,.4,1.5)}
        end
    end
    return api
end
