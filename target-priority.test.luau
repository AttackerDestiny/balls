return function(moduleSource)
    local folder=Instance.new("Folder")
    local function mob(name,x,tag)
        local m=Instance.new("Model",folder); m.Name=name
        local r=Instance.new("Part",m); r.Name="HumanoidRootPart"; r.Position=Vector3.new(x,0,0)
        Instance.new("Folder",m).Name="Entity"
        if tag then m:AddTag(tag) end
        return m
    end
    local regular=mob("Regular",1)
    local mini=mob("Mini",10,"MiniBoss")
    local boss=mob("Main",100,"Boss")
    local api=assert(loadstring(moduleSource))()()
    local ok,result=pcall(function()
        local list={regular,mini,boss}
        table.sort(list,function(a,b)return api.Less(a,b,Vector3.zero,regular)end)
        assert(list[1]==boss and list[2]==mini and list[3]==regular,"Boss rank must override distance and the current target")
        assert(api.Rank(boss)==1 and api.Rank(mini)==2 and api.Rank(regular)==3,"Recognize model-level boss tags")
        local peer=mob("Other boss",90,"Boss")
        assert(api.Less(boss,peer,Vector3.zero,boss),"Keep the current target stable within one rank")
        local chest=mob("Reward Chest",200)
        local live={[boss]=true,[chest]=true}
        assert(api.NextChest(boss,{[chest]=true},function()return true end,function(m)return live[m]end)==boss,
            "Loaded chest waits for the current enemy")
        live[boss]=false
        assert(api.NextChest(boss,{[chest]=true},function()return true end,function(m)return live[m]end)==chest)
        assert(api.NextChest(chest,{},function()return true end,function(m)return live[m]end)==chest,
            "An opened chest remains focused until its live state ends")
        assert(api.Rank(mob("DA",0))==2 and api.Rank(mob("RA",0))==2 and api.Rank(mob("KA",0))==2)
        return {Passed=true,Order={1,2,3},ModelTagsRecognized=true}
    end)
    folder:Destroy()
    if not ok then error(result) end
    return result
end
