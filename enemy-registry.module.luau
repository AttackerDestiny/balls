-- Registry owns per-model records and temporary streaming observations.
return function(context)
    local api={Models={},Count=0,Revision=0}
    local entries={}
    local observedFolder,folderSignals=nil,{}
    local closed=false
    local reconcileAt=0
    local function detach(record)
        if record.Listeners then
            for _,listener in ipairs(record.Listeners)do listener:Disconnect()end
            record.Listeners=nil
        end
    end
    local function forget(model)
        local record=entries[model]
        if record then detach(record);entries[model]=nil end
    end
    local function notify(model,exists)
        api.Revision+=1
        if context.Changed then context.Changed(model,exists)end
    end
    local function register(model)
        if closed or api.Models[model]or not model:IsA("Model")then return end
        api.Models[model]=true;api.Count+=1;notify(model,true)
    end
    local function unregister(model)
        forget(model)
        if api.Models[model]then api.Models[model]=nil;api.Count-=1;notify(model,false)end
    end
    local function reset()
        for index=#folderSignals,1,-1 do folderSignals[index]:Disconnect();folderSignals[index]=nil end
        for model in pairs(entries)do forget(model)end
        table.clear(api.Models);api.Count=0
    end
    function api.Refresh()
        if closed then return nil end
        local folder=context.Folder()
        if folder~=observedFolder then
            reset();observedFolder=folder;api.Folder=folder;api.Revision+=1;reconcileAt=0
            if folder then
                folderSignals[1]=folder.ChildAdded:Connect(register)
                folderSignals[2]=folder.ChildRemoved:Connect(unregister)
            end
        end
        local at=context.Now()
        if folder and at>=reconcileAt then
            reconcileAt=at+10
            for model in pairs(api.Models)do if model.Parent~=folder then unregister(model)end end
            for _,model in ipairs(folder:GetChildren())do register(model)end
        end
        return observedFolder
    end
    local function motion(root)
        local current=root:FindFirstChild("BodyVelocity")
        if current then return current end
        return root.FindFirstChildOfClass and root:FindFirstChildOfClass("LinearVelocity")or nil
    end
    local function waitForData(model,record,at)
        record.Data=nil;record.NextRead=at+.1
        if record.Listeners or not model.DescendantAdded or not model.DescendantRemoving then return end
        local function invalidate()record.NextRead=0 end
        record.Listeners={model.DescendantAdded:Connect(invalidate),model.DescendantRemoving:Connect(invalidate)}
    end
    function api.Data(model)
        if closed or model==nil then return nil end
        if model.Parent==nil then forget(model);return nil end
        local record=entries[model]
        if record==nil then record={NextRead=0};entries[model]=record end
        local at=context.Now()
        local data=record.Data
        if data and data.Root.Parent and data.Entity.Parent==model and data.Health.Parent==data.Entity then
            data.HitLives=data.Entity:FindFirstChild("HitLives")
            if at>=(data.MetaAt or 0)then data.Motion=motion(data.Root);data.MetaAt=at+.5 end
            return data
        end
        if at<record.NextRead then return nil end
        local root=model:FindFirstChild("HumanoidRootPart")or model.PrimaryPart or model:FindFirstChild("RootPart")
        local entity=model:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if not(root and root:IsA("BasePart")and health)then waitForData(model,record,at);return nil end
        detach(record)
        data={Root=root,Entity=entity,Health=health,HitLives=entity:FindFirstChild("HitLives"),Motion=motion(root),MetaAt=at+.5}
        record.Data=data;record.NextRead=0
        return data
    end
    function api.Destroy()
        if closed then return end
        closed=true;reset();observedFolder=nil;api.Folder=nil
    end
    return api
end
