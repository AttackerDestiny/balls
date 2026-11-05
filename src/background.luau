-- Independent status overlay; hiding WindUI leaves this under the runtime root.
do
    local make=(function()
-- BEGIN BUNDLED MULTI SPOT HUD
-- END BUNDLED MULTI SPOT HUD
    end)()
    local root=create("Frame",{Name="MultiSpotHUD",Visible=false,Size=UDim2.fromOffset(280,70),
        Position=UDim2.new(.5,0,.5,0),AnchorPoint=Vector2.new(.5,.5),Active=true,BackgroundColor3=Color3.fromRGB(42,42,44),BorderSizePixel=0},gui)
    corner(root,14)
    create("UIStroke",{Color=Color3.new(1,1,1),Transparency=.92,Thickness=1},root)
    create("TextLabel",{Name="Heading",Text="Multi Spot",BackgroundTransparency=1,Position=UDim2.fromOffset(12,8),
        Size=UDim2.new(1,-24,0,18),Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left},root)
    local label=create("TextLabel",{Name="Status",Text="",BackgroundTransparency=1,Position=UDim2.fromOffset(12,28),
        Size=UDim2.new(1,-24,0,34),TextWrapped=true,Font=Enum.Font.Gotham,TextSize=11,
        TextColor3=Color3.fromRGB(161,161,170),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},root)
    local drag,startPoint,startPosition
    bind(root.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            drag=input;startPoint=input.Position;startPosition=root.Position
        end
    end)
    bind(UserInputService.InputChanged,function(input)
        if not drag or not root.Visible then return end
        if input~=drag and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local delta=input.Position-startPoint
        local size=gui.AbsoluteSize
        local x=startPosition.X.Scale*size.X+startPosition.X.Offset+delta.X
        local y=startPosition.Y.Scale*size.Y+startPosition.Y.Offset+delta.Y
        root.Position=UDim2.fromOffset(math.clamp(x,140,math.max(140,size.X-140)),math.clamp(y,35,math.max(35,size.Y-35)))
    end)
    bind(UserInputService.InputEnded,function(input)
        if input==drag or input.UserInputType==Enum.UserInputType.MouseButton1 then drag=nil end
    end)
    state.MultiSpotHUD=make({State=state,Pulse=RunService.Heartbeat,Now=os.clock,
        Visible=function(value)if root.Visible~=value then root.Visible=value end end,
        Text=function(value)if label.Text~=value then label.Text=value end end,
        Destroy=function()root:Destroy()end})
end

-- Synchronize the user's selected Safe floor, separately from progression's floor.
if sharedSettings then
    task.spawn(function()
        while state.Running do
            local ok,id=pcall(sharedSettings.ReadSafeFloor)
            if ok and id and id~=state.SharedSafeFloorId then
                if state.AccountProgression then
                    state.SharedSafeFloorId=id
                    if state.ProgressionRestore then state.ProgressionRestore.SafeFloorId=id end
                elseif state.AutomationCatalog and state.AutomationCatalog.FloorById[id]and state.IsAutomationFloorUnlocked(id)then
                    state.SetSafeFloor(id)
                else
                    state.SharedSafeFloorId=id
                    state.SafeModeStatus="Shared Safe floor is locked on this account"
                    if state.RefreshAutomationUI then state.RefreshAutomationUI()end
                end
            end
            task.wait(1)
        end
    end)
end

-- Built-in quest reward collection, independent of farming and menu visibility.
do
    local make=(function()
-- BEGIN BUNDLED AUTO QUEST
-- END BUNDLED AUTO QUEST
    end)()
    local quests=require(services.UI.Quests)
    local own=ReplicatedStorage.Profiles[player.Name]:FindFirstChild("Quests")
    local worker=make({Active=function()return state.Running end,
        Busy=function()return state.StopEverything or state.ModeratorBlocking or state.SafeModePanic
            or state.AutomationTeleporting or state.AutoTradeBusy end,
        Ready=function()
            local result={}
            for object,entry in pairs(quests.Active or {})do
                if own and object.Parent==own and quests.ToClaim and quests.ToClaim[entry.Entry]==true then result[#result+1]=object end
            end
            table.sort(result,function(a,b)return a.Name<b.Name end)
            return result
        end,
        Valid=function(object)
            local entry=quests.Active and quests.Active[object]
            return own and object.Parent==own and entry and quests.ToClaim and quests.ToClaim[entry.Entry]==true
        end,
        Claim=function(object)ReplicatedStorage.Event:FireServer("SystemQuests",{"ClaimQuest",object})end})
    state.AutoQuest=worker
    task.spawn(function()
        while state.Running do
            local ok,reason=pcall(worker.Update,os.clock())
            if not ok then state.AutoQuestError=tostring(reason)end
            task.wait(.5)
        end
    end)
end

state.StartupComplete=true
