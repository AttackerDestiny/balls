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
    -- A common order for farming: never use a particular account's position
    -- or previous target to break ties between otherwise eligible enemies.
    function api.FarmLess(a,b)
        if a==b then return false end
        local ar,br=api.Rank(a),api.Rank(b)
        if ar~=br then return ar<br end
        if a.Name~=b.Name then return a.Name<b.Name end
        local ap=a:FindFirstChild("HumanoidRootPart")or a.PrimaryPart or a:FindFirstChild("RootPart")
        local bp=b:FindFirstChild("HumanoidRootPart")or b.PrimaryPart or b:FindFirstChild("RootPart")
        if not ap or not bp then return ap~=nil and bp==nil end
        local av,bv=ap.Position,bp.Position
        if av.X~=bv.X then return av.X<bv.X end
        if av.Z~=bv.Z then return av.Z<bv.Z end
        return av.Y<bv.Y
    end
    return api
end
