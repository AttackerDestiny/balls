return function()
    local api={}
    local cache=setmetatable({}, {__mode="k"})
    local function clean(value) return string.lower((string.gsub(tostring(value or ""),"[^%w]",""))) end
    function api.Rank(mob)
        if not mob then return 3 end
        local cached=cache[mob]
        if cached and os.clock()<cached.Until then return cached.Rank end
        local entity=mob:FindFirstChild("Entity")
        local difficulty=entity and entity:FindFirstChild("Difficulty")
        local rank=clean(mob:GetAttribute("Rank") or (entity and entity:GetAttribute("Rank")) or (difficulty and difficulty.Value))
        local boss,mini=false,false
        for _,instance in ipairs(entity and {mob,entity} or {mob}) do
            for _,tag in ipairs(instance:GetTags()) do
                local key=clean(tag)
                if string.find(key,"mini",1,true) and string.find(key,"boss",1,true) then mini=true
                elseif key=="boss" or key=="bossbar" or key=="mainboss" or key=="floorboss" then boss=true end
            end
        end
        local priority=3
        if mini or string.find(rank,"mini",1,true) or clean(mob.Name)=="frogazoid" then priority=2
        elseif boss or string.find(rank,"boss",1,true) then priority=1 end
        cache[mob]={Rank=priority,Until=os.clock()+.2}
        return priority
    end
    function api.Less(a,b,origin,preferred)
        local ar,br=api.Rank(a),api.Rank(b)
        if ar~=br then return ar<br end
        if a==preferred then return b~=preferred end
        if b==preferred then return false end
        local ap=a:FindFirstChild("HumanoidRootPart")
        local bp=b:FindFirstChild("HumanoidRootPart")
        return (ap and (ap.Position-origin).Magnitude or math.huge)<(bp and (bp.Position-origin).Magnitude or math.huge)
    end
    return api
end
