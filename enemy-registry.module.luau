-- One streamed-enemy index and data cache shared by every controller.
return function(ctx)
    local api={Models={},Revision=0,Count=0}
    local cache=setmetatable({}, {__mode="k"})
    local missing={}
    local folder,added,removed
    local disposed,nextReconcile=false,0
    local function forgetMissing(mob)
        local record=missing[mob]
        if not record then return end
        missing[mob]=nil
        for _,connection in ipairs(record.Connections)do connection:Disconnect()end
    end
    local function changed(mob,present)
        if present then
            if not mob:IsA("Model")or api.Models[mob]then return end
            api.Models[mob]=true;api.Count+=1
        else
            if not api.Models[mob]then return end
            api.Models[mob]=nil;cache[mob]=nil;forgetMissing(mob);api.Count-=1
        end
        api.Revision+=1
        if ctx.Changed then ctx.Changed(mob,present)end
    end
    function api.Refresh()
        if disposed then return nil end
        local current=ctx.Folder()
        if current~=folder then
            if added then added:Disconnect();added=nil end
            if removed then removed:Disconnect();removed=nil end
            for mob in pairs(missing)do forgetMissing(mob)end
            table.clear(api.Models);table.clear(cache);api.Count=0;api.Revision+=1
            folder=current;api.Folder=folder;nextReconcile=0
            if folder then
                added=folder.ChildAdded:Connect(function(mob)changed(mob,true)end)
                removed=folder.ChildRemoved:Connect(function(mob)changed(mob,false)end)
            end
        end
        local now=ctx.Now()
        if folder and now>=nextReconcile then
            nextReconcile=now+10
            for mob in pairs(api.Models)do if mob.Parent~=folder then changed(mob,false)end end
            for _,mob in ipairs(folder:GetChildren())do changed(mob,true)end
        end
        return folder
    end
    function api.Data(mob)
        if disposed or not mob then return nil end
        if not mob.Parent then forgetMissing(mob);cache[mob]=nil;return nil end
        local data=cache[mob]
        local now=ctx.Now()
        if data and data.Root and data.Root.Parent and data.Entity.Parent==mob and data.Health.Parent==data.Entity then
            -- HitLives can replicate independently, including during a fight.
            data.HitLives=data.Entity:FindFirstChild("HitLives")
            if now>=(data.MetaAt or 0)then
                data.Motion=data.Root:FindFirstChild("BodyVelocity")or (data.Root.FindFirstChildOfClass and data.Root:FindFirstChildOfClass("LinearVelocity"))
                data.MetaAt=now+.5
            end
            return data
        end
        local incomplete=missing[mob]
        if incomplete and now<incomplete.RetryAt then return nil end
        local root=mob:FindFirstChild("HumanoidRootPart")or mob.PrimaryPart or mob:FindFirstChild("RootPart")
        local entity=mob:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if not root or not root:IsA("BasePart")or not health then
            cache[mob]=nil
            if not incomplete and mob.DescendantAdded and mob.DescendantRemoving then
                incomplete={RetryAt=0,Connections={}}
                missing[mob]=incomplete
                local function invalidate()incomplete.RetryAt=0 end
                incomplete.Connections[1]=mob.DescendantAdded:Connect(invalidate)
                incomplete.Connections[2]=mob.DescendantRemoving:Connect(invalidate)
            end
            if incomplete then incomplete.RetryAt=now+.1 end
            return nil
        end
        forgetMissing(mob)
        data={Root=root,Entity=entity,Health=health,HitLives=entity:FindFirstChild("HitLives"),
            Motion=root:FindFirstChild("BodyVelocity")or (root.FindFirstChildOfClass and root:FindFirstChildOfClass("LinearVelocity")),MetaAt=now+.5}
        cache[mob]=data
        return data
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        if added then added:Disconnect();added=nil end
        if removed then removed:Disconnect();removed=nil end
        for mob in pairs(missing)do forgetMissing(mob)end
        table.clear(api.Models);table.clear(cache);api.Count=0;folder=nil;api.Folder=nil
    end
    return api
end
