-- Choose a small-hit combination from confirmed, weapon-specific damage estimates.
return function()
    local api={}
    local samples,keys={},{}
    function api.Learn(key,amount)
        if type(key)~="string"or type(amount)~="number"or amount<=0 or amount~=amount or amount==math.huge then return end
        if not samples[key]then
            if #keys>=128 then samples[table.remove(keys,1)]=nil end
            keys[#keys+1]=key
        end
        -- Use the lower observed damage so a critical hit cannot under-budget credit.
        samples[key]=samples[key]and math.min(samples[key],amount)or amount
    end
    function api.Estimate(key)return samples[key]or 0 end
    function api.Choose(remaining,normal,skill,canNormal,canSkill)
        if remaining<=0 then return nil end
        normal,skill=normal or 0,skill or 0
        if canNormal and normal<=0 then return "Normal",{Calibrating=true}end
        if canSkill and skill<=0 then return "Skill",{Calibrating=true}end
        if not canNormal and not canSkill then return nil end
        local best
        local function consider(n,s)
            local amount=n*normal+s*skill
            if amount<remaining then return end
            local option={Normal=n,Skill=s,Damage=amount,Excess=amount-remaining,Actions=n+s}
            if not best or option.Excess<best.Excess or (option.Excess==best.Excess and option.Actions<best.Actions)
                or (option.Excess==best.Excess and option.Actions==best.Actions and s<best.Skill)then best=option end
        end
        if canNormal and normal>0 then consider(math.ceil(remaining/normal),0)end
        if canSkill and skill>0 then
            local count=math.ceil(remaining/skill)
            consider(0,count)
            if canNormal and normal>0 then
                for s=1,math.min(64,count)do consider(math.max(0,math.ceil((remaining-s*skill)/normal)),s)end
            end
        end
        if not best then return nil end
        return best.Skill>0 and "Skill"or "Normal",best
    end
    return api
end
