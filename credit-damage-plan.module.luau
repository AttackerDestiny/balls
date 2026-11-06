-- Bounded conservative estimates plus a lexicographic minimum-overkill search.
return function()
    local api={}
    local estimates,ring={},{}
    local cursor=1
    local function valid(value)return type(value)=="number"and value==value and value>0 and value<math.huge end
    function api.Learn(key,amount)
        if type(key)~="string"or not valid(amount)then return end
        if estimates[key]then estimates[key]=math.min(estimates[key],amount);return end
        local expired=ring[cursor]
        if expired then estimates[expired]=nil end
        ring[cursor]=key;cursor=cursor%128+1;estimates[key]=amount
    end
    function api.Estimate(key)return estimates[key]or 0 end
    function api.Choose(remaining,normal,skill,canNormal,canSkill)
        if remaining<=0 then return nil end
        normal=normal or 0;skill=skill or 0
        if canNormal and normal<=0 then return "Normal",{Calibrating=true}end
        if canSkill and skill<=0 then return "Skill",{Calibrating=true}end
        local result
        local function offer(normals,skills)
            local total=normals*normal+skills*skill
            if total<remaining then return end
            local excess,actions=total-remaining,normals+skills
            if result and (result.Excess<excess or (result.Excess==excess and (result.Actions<actions or (result.Actions==actions and result.Skill<=skills))))then return end
            result={Normal=normals,Skill=skills,Damage=total,Excess=excess,Actions=actions}
        end
        if canNormal and normal>0 then offer(math.ceil(remaining/normal),0)end
        if canSkill and skill>0 then
            local allSkill=math.ceil(remaining/skill)
            offer(0,allSkill)
            if canNormal and normal>0 then
                for skills=1,math.min(64,allSkill)do offer(math.max(0,math.ceil((remaining-skills*skill)/normal)),skills)end
            end
        end
        if result then return result.Skill>0 and "Skill"or "Normal",result end
    end
    return api
end
