-- Rank metadata is merged across model/entity markers; tie ordering is deterministic.
return function()
    local api={}
    local namedMiniboss={frogazoid=true,da=true,ra=true,ka=true}
    local memo=setmetatable({}, {__mode="k"})
    local function normalize(value)return tostring(value or ""):lower():gsub("[^%w]","")end
    local function root(mob)return mob:FindFirstChild("HumanoidRootPart")or mob.PrimaryPart or mob:FindFirstChild("RootPart")end
    function api.IsChest(mob)
        if not mob then return false end
        local name=tostring(mob.Name):lower():match("^%s*(.-)%s*$")
        return name:find("%f[%a]chests?%f[%A]")~=nil or name:match("chests?$")~=nil
    end
    local function marker(value)
        local key=normalize(value)
        if key:find("mainboss",1,true)or key:find("floorboss",1,true)then return 8 end
        if key:find("mini",1,true)and key:find("boss",1,true)then return 4 end
        return key:find("boss",1,true)and 2 or 0
    end
    function api.Rank(mob)
        if not mob then return 3 end
        local entity=mob:FindFirstChild("Entity")
        local difficulty=entity and entity:FindFirstChild("Difficulty")
        local modelTag=mob:GetAttribute("Rank")
        local entityTag=entity and entity:GetAttribute("Rank")
        local level=difficulty and difficulty.Value
        local old=memo[mob]
        if old and old.At>os.clock()and old.Entity==entity and old.Model==modelTag and old.EntityRank==entityTag and old.Difficulty==level then return old.Priority end
        local flags={}
        local function include(value)local code=marker(value);if code>0 then flags[code]=true end end
        include(modelTag);include(entityTag);include(level)
        for _,tag in ipairs(mob:GetTags())do include(tag)end
        if entity then for _,tag in ipairs(entity:GetTags())do include(tag)end end
        local priority=flags[8]and 1 or (flags[4]or namedMiniboss[normalize(mob.Name)])and 2 or flags[2]and 1 or 3
        memo[mob]={At=os.clock()+.15,Entity=entity,Model=modelTag,EntityRank=entityTag,Difficulty=level,Priority=priority}
        return priority
    end
    function api.Less(a,b,origin,preferred)
        local ar,br=api.Rank(a),api.Rank(b)
        if ar~=br then return ar<br end
        if a==preferred or b==preferred then return a==preferred and b~=preferred end
        local ap,bp=a:FindFirstChild("HumanoidRootPart"),b:FindFirstChild("HumanoidRootPart")
        local ad=ap and (ap.Position-origin).Magnitude or math.huge
        local bd=bp and (bp.Position-origin).Magnitude or math.huge
        return ad<bd
    end
    function api.FarmLess(a,b)
        if a==b then return false end
        local ar,br=api.Rank(a),api.Rank(b)
        if ar~=br then return ar<br end
        if a.Name~=b.Name then return a.Name<b.Name end
        local ap,bp=root(a),root(b)
        if not ap or not bp then return ap~=nil and bp==nil end
        local av,bv=ap.Position,bp.Position
        if av.X~=bv.X then return av.X<bv.X end
        if av.Z~=bv.Z then return av.Z<bv.Z end
        return av.Y<bv.Y
    end
    function api.NextChest(current,candidates,valid,living)
        if current and api.IsChest(current)and living(current)then return current end
        local best
        for candidate in pairs(candidates)do
            if api.IsChest(candidate)and valid(candidate)and (not best or api.FarmLess(candidate,best))then best=candidate end
        end
        if not best then return nil end
        if current and living(current)then return current end
        return best
    end
    return api
end
