-- Player/character/profile data paths adapted from the supplied source.
return function(ctx)
    local state,players,localPlayer=ctx.State,ctx.Players,ctx.LocalPlayer
    local api={Viewing=false,InventoryVisible=false}
    local connections,inventoryConnections,targetConnection={},{},nil
    local selected,priorSubject,priorType
    local disposed,inventoryQueued=false,false
    local function connect(signal,callback,list)
        local value=signal:Connect(callback)
        table.insert(list or connections,value)
        return value
    end
    local function clearInventoryConnections()
        for _,connection in ipairs(inventoryConnections) do connection:Disconnect() end
        table.clear(inventoryConnections)
    end
    function api.GetSelected() return selected and selected.Parent==players and selected or nil end
    function api.Choices()
        local result={}
        for _,p in ipairs(players:GetPlayers()) do
            if p~=localPlayer then result[#result+1]={UserId=p.UserId,Name=p.Name,DisplayName=p.DisplayName} end
        end
        table.sort(result,function(a,b) return string.lower(a.Name)<string.lower(b.Name) end)
        return result
    end
    local function attachCamera()
        local target=api.GetSelected()
        local character=target and target.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local camera=ctx.Workspace.CurrentCamera
        if api.Viewing and not disposed and not state.StopEverything and humanoid and humanoid.Health>0 and camera then
            camera.CameraType=Enum.CameraType.Custom
            camera.CameraSubject=humanoid
        end
    end
    function api.SetViewing(enabled)
        if enabled and state.StopEverything then return false,"Stop Everything is on" end
        if enabled and not api.GetSelected() then return false,"Select a player first" end
        local camera=ctx.Workspace.CurrentCamera
        local wasViewing=api.Viewing
        if enabled and not api.Viewing and camera then priorSubject,priorType=camera.CameraSubject,camera.CameraType end
        api.Viewing=enabled==true
        state.ViewingPlayer=api.Viewing
        if api.Viewing then attachCamera()
        elseif camera and wasViewing then
            local character=localPlayer.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local subject=humanoid or (priorSubject and priorSubject.Parent and priorSubject)
            if subject then camera.CameraSubject=subject end
            camera.CameraType=priorType or Enum.CameraType.Custom
            priorSubject,priorType=nil,nil
        end
        if ctx.Changed then ctx.Changed() end
        return true
    end
    function api.InventoryRows()
        local target=api.GetSelected()
        local profile=target and ctx.Profiles and ctx.Profiles:FindFirstChild(target.Name)
        local inventory=profile and profile:FindFirstChild("Inventory")
        if not inventory then return {},"Inventory is not loaded for this player" end
        local grouped={}
        for _,item in ipairs(inventory:GetChildren()) do
            local upgrade=item:FindFirstChild("Upgrade")
            local level=upgrade and upgrade:IsA("ValueBase") and tonumber(upgrade.Value) or 0
            local key=item.Name..":"..tostring(level)
            local row=grouped[key]
            if not row then row={Name=item.Name,Upgrade=level,Count=0}; grouped[key]=row end
            row.Count+=1
        end
        local rows={}
        for _,row in pairs(grouped) do rows[#rows+1]=row end
        table.sort(rows,function(a,b) if a.Name~=b.Name then return a.Name<b.Name end; return a.Upgrade<b.Upgrade end)
        return rows,nil,inventory
    end
    function api.RefreshInventory()
        if not api.InventoryVisible or disposed or state.StopEverything then return end
        local rows,message=api.InventoryRows()
        ctx.Inventory(rows,message,api.GetSelected())
    end
    local function queueInventory()
        if inventoryQueued or not api.InventoryVisible or disposed then return end
        inventoryQueued=true
        task.defer(function()
            inventoryQueued=false
            if not disposed then api.RefreshInventory() end
        end)
    end
    local function watchInventory()
        clearInventoryConnections()
        if not api.InventoryVisible then return end
        local _,_,inventory=api.InventoryRows()
        if inventory then
            connect(inventory.ChildAdded,queueInventory,inventoryConnections)
            connect(inventory.ChildRemoved,queueInventory,inventoryConnections)
            connect(inventory.DescendantAdded,queueInventory,inventoryConnections)
            connect(inventory.DescendantRemoving,queueInventory,inventoryConnections)
            for _,item in ipairs(inventory:GetChildren()) do
                connect(item:GetPropertyChangedSignal("Name"),queueInventory,inventoryConnections)
                local upgrade=item:FindFirstChild("Upgrade")
                if upgrade and upgrade:IsA("ValueBase") then connect(upgrade.Changed,queueInventory,inventoryConnections) end
            end
        end
        api.RefreshInventory()
    end
    function api.SetInventoryVisible(enabled)
        if enabled and state.StopEverything then return false,"Stop Everything is on" end
        if enabled and not api.GetSelected() then return false,"Select a player first" end
        if ctx.NativeInventory then
            local ok,reason=ctx.NativeInventory(enabled and api.GetSelected()or nil)
            if not ok then return false,reason end
        end
        api.InventoryVisible=enabled==true
        state.ViewingPlayerInventory=api.InventoryVisible
        watchInventory()
        if ctx.Changed then ctx.Changed() end
        return true
    end
    function api.Select(userId)
        local target=players:GetPlayerByUserId(tonumber(userId) or 0)
        if not target or target==localPlayer then return false,"Player is no longer in this server" end
        if api.InventoryVisible and ctx.NativeInventory then
            local ok,reason=ctx.NativeInventory(target)
            if not ok then return false,reason end
        end
        if targetConnection then targetConnection:Disconnect(); targetConnection=nil end
        selected=target
        state.SelectedPlayerId=target.UserId
        targetConnection=target.CharacterAdded:Connect(function(character)
            task.defer(function()
                local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",3)
                if humanoid and selected==target and not disposed then attachCamera() end
            end)
        end)
        attachCamera(); watchInventory()
        if ctx.Changed then ctx.Changed() end
        return true
    end
    function api.Teleport()
        if state.StopEverything then return false,"Stop Everything is on" end
        local target=api.GetSelected()
        if not target then return false,"Select a player first" end
        return ctx.Teleport(target)
    end
    connect(players.PlayerAdded,function() if ctx.RosterChanged then ctx.RosterChanged() end end)
    connect(players.PlayerRemoving,function(target)
        if selected and target.UserId==selected.UserId then
            api.SetViewing(false); api.SetInventoryVisible(false)
            if targetConnection then targetConnection:Disconnect(); targetConnection=nil end
            selected=nil; state.SelectedPlayerId=nil
            if ctx.Changed then ctx.Changed() end
        end
        if ctx.RosterChanged then task.defer(function() if not disposed then ctx.RosterChanged() end end) end
    end)
    connect(ctx.Workspace:GetPropertyChangedSignal("CurrentCamera"),attachCamera)
    connect(localPlayer.CharacterAdded,function()
        if api.Viewing then task.defer(attachCamera) end
    end)
    function api.Destroy()
        if disposed then return end
        api.SetViewing(false); api.SetInventoryVisible(false)
        disposed=true
        if targetConnection then targetConnection:Disconnect() end
        clearInventoryConnections()
        for _,connection in ipairs(connections) do connection:Disconnect() end
    end
    return api
end
