return function()
    local api={}
    local cache=setmetatable({}, {__mode="k"})
    local function clean(value) return string.lower((string.gsub(tostring(value or ""),"[^%w]",""))) end
    function api.Rank(mob)
        if not mob then return 3 end
        local entity=mob:FindFirstChild("Entity")
        local difficulty=entity and entity:FindFirstChild("Difficulty")
        local modelRank=mob:GetAttribute("Rank")
        local entityRank=entity and entity:GetAttribute("Rank")
        local difficultyRank=difficulty and difficulty.Value
        local cached=cache[mob]
        if cached and os.clock()<cached.Until and cached.Entity==entity and cached.ModelRank==modelRank
            and cached.EntityRank==entityRank and cached.Difficulty==difficultyRank then return cached.Rank end
        local main,boss,mini=false,false,false
        local function mark(value)
            local key=clean(value)
            if string.find(key,"mainboss",1,true)or string.find(key,"floorboss",1,true)then main=true
            elseif string.find(key,"mini",1,true)and string.find(key,"boss",1,true)then mini=true
            elseif string.find(key,"boss",1,true)then boss=true end
        end
        -- Read every native rank source: an unrelated model Rank must not
        -- mask the boss Difficulty or rank stored on its Entity.
        mark(modelRank);mark(entityRank);mark(difficultyRank)
        for _,instance in ipairs(entity and {mob,entity} or {mob}) do
            for _,tag in ipairs(instance:GetTags()) do mark(tag)end
        end
        local priority=3
        if main then priority=1
        elseif mini or clean(mob.Name)=="frogazoid" then priority=2
        elseif boss then priority=1 end
        cache[mob]={Rank=priority,Until=os.clock()+.15,Entity=entity,ModelRank=modelRank,EntityRank=entityRank,Difficulty=difficultyRank}
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
