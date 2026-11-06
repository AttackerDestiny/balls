-- Selection owns camera and inventory subscriptions as separate replaceable scopes.
return function(ctx)
    local state,players=ctx.State,ctx.Players
    local api={Viewing=false,InventoryVisible=false}
    local selected,selectedConnection=nil,nil
    local closed,inventoryQueued=false,false
    local inventoryConnections,subscriptions={},{}
    local cameraLease
    local function unsubscribe(list)
        for _,connection in ipairs(list)do connection:Disconnect()end
        table.clear(list)
    end
    local function listen(list,event,fn)list[#list+1]=event:Connect(fn)end
    local function notify()if ctx.Changed then ctx.Changed()end end
    function api.GetSelected()if selected and selected.Parent==players then return selected end end
    function api.Choices()
        local rows={}
        for _,person in ipairs(players:GetPlayers())do if person~=ctx.LocalPlayer then
            rows[#rows+1]={UserId=person.UserId,Name=person.Name,DisplayName=person.DisplayName}
        end end
        table.sort(rows,function(a,b)return a.Name:lower()<b.Name:lower()end)
        return rows
    end
    local function follow()
        local person=api.GetSelected()
        local character=person and person.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local camera=ctx.Workspace.CurrentCamera
        if not closed and api.Viewing and not state.StopEverything and humanoid and humanoid.Health>0 and camera then
            camera.CameraSubject=humanoid;camera.CameraType=Enum.CameraType.Custom
        end
    end
    function api.SetViewing(value)
        value=value==true
        if value and state.StopEverything then return false,"Stop Everything is on"end
        if value and not api.GetSelected()then return false,"Select a player first"end
        local camera=ctx.Workspace.CurrentCamera
        if value and not api.Viewing and camera then cameraLease={Subject=camera.CameraSubject,Type=camera.CameraType}end
        local was=api.Viewing;api.Viewing=value;state.ViewingPlayer=value
        if value then follow()
        elseif was and camera then
            local own=ctx.LocalPlayer.Character
            local humanoid=own and own:FindFirstChildOfClass("Humanoid")
            local subject=humanoid or (cameraLease and cameraLease.Subject and cameraLease.Subject.Parent and cameraLease.Subject)
            if subject then camera.CameraSubject=subject end
            camera.CameraType=cameraLease and cameraLease.Type or Enum.CameraType.Custom
            cameraLease=nil
        end
        notify();return true
    end
    function api.InventoryRows()
        local person=api.GetSelected()
        local profile=person and ctx.Profiles and ctx.Profiles:FindFirstChild(person.Name)
        local inventory=profile and profile:FindFirstChild("Inventory")
        if not inventory then return {},"Inventory is not loaded for this player"end
        local groups={}
        for _,item in ipairs(inventory:GetChildren())do
            local value=item:FindFirstChild("Upgrade")
            local upgrade=value and value:IsA("ValueBase")and tonumber(value.Value)or 0
            local key=item.Name..":"..upgrade
            if not groups[key]then groups[key]={Name=item.Name,Upgrade=upgrade,Count=0}end
            groups[key].Count+=1
        end
        local rows={};for _,row in pairs(groups)do rows[#rows+1]=row end
        table.sort(rows,function(a,b)return a.Name==b.Name and a.Upgrade<b.Upgrade or a.Name<b.Name end)
        return rows,nil,inventory
    end
    function api.RefreshInventory()
        if closed or not api.InventoryVisible or state.StopEverything then return end
        local rows,message=api.InventoryRows();ctx.Inventory(rows,message,api.GetSelected())
    end
    local function invalidateInventory()
        if closed or not api.InventoryVisible or inventoryQueued then return end
        inventoryQueued=true
        task.defer(function()inventoryQueued=false;if not closed then api.RefreshInventory()end end)
    end
    local function observeInventory()
        unsubscribe(inventoryConnections)
        if not api.InventoryVisible then return end
        local _,_,inventory=api.InventoryRows()
        if inventory then
            for _,event in ipairs({inventory.ChildAdded,inventory.ChildRemoved,inventory.DescendantAdded,inventory.DescendantRemoving})do listen(inventoryConnections,event,invalidateInventory)end
            for _,item in ipairs(inventory:GetChildren())do
                listen(inventoryConnections,item:GetPropertyChangedSignal("Name"),invalidateInventory)
                local upgrade=item:FindFirstChild("Upgrade")
                if upgrade and upgrade:IsA("ValueBase")then listen(inventoryConnections,upgrade.Changed,invalidateInventory)end
            end
        end
        api.RefreshInventory()
    end
    function api.SetInventoryVisible(value)
        value=value==true
        if value and state.StopEverything then return false,"Stop Everything is on"end
        if value and not api.GetSelected()then return false,"Select a player first"end
        if ctx.NativeInventory then local ok,reason=ctx.NativeInventory(value and api.GetSelected()or nil);if not ok then return false,reason end end
        api.InventoryVisible=value;state.ViewingPlayerInventory=value
        observeInventory();notify();return true
    end
    function api.Select(id)
        local person=players:GetPlayerByUserId(tonumber(id)or 0)
        if not person or person==ctx.LocalPlayer then return false,"Player is no longer in this server"end
        if api.InventoryVisible and ctx.NativeInventory then local ok,reason=ctx.NativeInventory(person);if not ok then return false,reason end end
        if selectedConnection then selectedConnection:Disconnect()end
        selected=person;state.SelectedPlayerId=person.UserId
        selectedConnection=person.CharacterAdded:Connect(function(character)
            task.defer(function()
                local humanoid=character:FindFirstChildOfClass("Humanoid")or character:WaitForChild("Humanoid",3)
                if humanoid and selected==person and not closed then follow()end
            end)
        end)
        follow();observeInventory();notify();return true
    end
    function api.Teleport()
        if state.StopEverything then return false,"Stop Everything is on"end
        local person=api.GetSelected()
        if not person then return false,"Select a player first"end
        return ctx.Teleport(person)
    end
    listen(subscriptions,players.PlayerAdded,function()if ctx.RosterChanged then ctx.RosterChanged()end end)
    listen(subscriptions,players.PlayerRemoving,function(person)
        if selected and person.UserId==selected.UserId then
            api.SetViewing(false);api.SetInventoryVisible(false)
            if selectedConnection then selectedConnection:Disconnect();selectedConnection=nil end
            selected=nil;state.SelectedPlayerId=nil;notify()
        end
        if ctx.RosterChanged then task.defer(function()if not closed then ctx.RosterChanged()end end)end
    end)
    listen(subscriptions,ctx.Workspace:GetPropertyChangedSignal("CurrentCamera"),follow)
    listen(subscriptions,ctx.LocalPlayer.CharacterAdded,function()if api.Viewing then task.defer(follow)end end)
    function api.Destroy()
        if closed then return end
        api.SetViewing(false);api.SetInventoryVisible(false);closed=true
        if selectedConnection then selectedConnection:Disconnect();selectedConnection=nil end
        unsubscribe(inventoryConnections);unsubscribe(subscriptions);selected=nil;cameraLease=nil
    end
    return api
end
