-- Compact overlay and independent background projections.
do
    local attach=(function()
-- BEGIN BUNDLED MULTI SPOT HUD
-- END BUNDLED MULTI SPOT HUD
    end)()
    local frame=create("Frame",{Name="MultiSpotHUD",Size=UDim2.fromOffset(280,70),Visible=false,
        Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),Active=true,
        BackgroundColor3=Color3.fromRGB(42,42,44),BorderSizePixel=0},gui)
    corner(frame,14)
    create("UIStroke",{Color=Color3.new(1,1,1),Transparency=.92,Thickness=1},frame)
    local common={BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left}
    local heading=table.clone(common)
    heading.Name="Heading";heading.Text="Multi Spot";heading.Position=UDim2.fromOffset(12,8)
    heading.Size=UDim2.new(1,-24,0,18);heading.Font=Enum.Font.GothamBold;heading.TextSize=12;heading.TextColor3=Color3.new(1,1,1)
    create("TextLabel",heading,frame)
    local description=table.clone(common)
    description.Name="Status";description.Text="";description.Position=UDim2.fromOffset(12,28)
    description.Size=UDim2.new(1,-24,0,34);description.Font=Enum.Font.Gotham;description.TextSize=11
    description.TextWrapped=true;description.TextColor3=Color3.fromRGB(161,161,170);description.TextYAlignment=Enum.TextYAlignment.Top
    local label=create("TextLabel",description,frame)
    local drag
    bind(frame.InputBegan,function(input)
        local kind=input.UserInputType
        if kind==Enum.UserInputType.Touch or kind==Enum.UserInputType.MouseButton1 then drag={Input=input,Start=input.Position,Position=frame.Position}end
    end)
    bind(UserInputService.InputChanged,function(input)
        if not drag or not frame.Visible then return end
        if input~=drag.Input and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local delta=input.Position-drag.Start;local extent=gui.AbsoluteSize;local origin=drag.Position
        local x=origin.X.Scale*extent.X+origin.X.Offset+delta.X
        local y=origin.Y.Scale*extent.Y+origin.Y.Offset+delta.Y
        frame.Position=UDim2.fromOffset(math.clamp(x,140,math.max(140,extent.X-140)),math.clamp(y,35,math.max(35,extent.Y-35)))
    end)
    bind(UserInputService.InputEnded,function(input)
        if drag and (input==drag.Input or input.UserInputType==Enum.UserInputType.MouseButton1)then drag=nil end
    end)
    state.MultiSpotHUD=attach({State=state,Pulse=RunService.Heartbeat,Now=os.clock,
        Visible=function(value)if frame.Visible~=value then frame.Visible=value end end,
        Text=function(text)if label.Text~=text then label.Text=text end end,
        Destroy=function()drag=nil;frame:Destroy()end})
end
local function refreshSharedFloor()
    if not sharedSettings then return end
    local ok,id=pcall(sharedSettings.ReadSafeFloor)
    if not ok or not id or id==state.SharedSafeFloorId then return end
    if state.AccountProgression then
        state.SharedSafeFloorId=id
        if state.ProgressionRestore then state.ProgressionRestore.SafeFloorId=id end
    elseif state.AutomationCatalog and state.AutomationCatalog.FloorById[id]and state.IsAutomationFloorUnlocked(id)then state.SetSafeFloor(id)
    else
        state.SharedSafeFloorId=id;state.SafeModeStatus="Shared Safe floor is locked on this account"
        if state.RefreshAutomationUI then state.RefreshAutomationUI()end
    end
end
if sharedSettings then task.spawn(function()
    while state.Running do refreshSharedFloor();task.wait(1)end
end)end
do
    local factory=(function()
-- BEGIN BUNDLED AUTO QUEST
-- END BUNDLED AUTO QUEST
    end)()
    local quests=require(services.UI.Quests)
    local function ownFolder()
        local profile=ReplicatedStorage.Profiles:FindFirstChild(player.Name)
        return profile and profile:FindFirstChild("Quests")
    end
    local function valid(object)
        local entry=quests.Active and quests.Active[object]
        return object.Parent==ownFolder()and entry and quests.ToClaim and quests.ToClaim[entry.Entry]==true
    end
    local worker=factory({Active=function()return state.Running end,
        Busy=function()return state.StopEverything or state.SafeModePanic or state.ModeratorBlocking or state.AutomationTeleporting or state.AutoTradeBusy end,
        Ready=function()
            local list={}
            for object in pairs(quests.Active or {})do if valid(object)then list[#list+1]=object end end
            table.sort(list,function(a,b)return a.Name<b.Name end)
            return list
        end,Valid=valid,Claim=function(object)ReplicatedStorage.Event:FireServer("SystemQuests",{"ClaimQuest",object})end})
    state.AutoQuest=worker
    task.spawn(function()
        while state.Running do
            local ok,reason=pcall(worker.Update,os.clock())
            if not ok then state.AutoQuestError=tostring(reason)end
            task.wait(.5)
        end
    end)
end
do
    local function installFarmDesync()
        local make=(function()
-- BEGIN BUNDLED FARM DESYNC
-- END BUNDLED FARM DESYNC
        end)()
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
        local controller=make({Render=RunService.PreRender,Camera=function()return workspace.CurrentCamera end,
            Allowed=function(now)
                return state.Running and state.FarmDesync and state.AutoFarm and not state.ViewingPlayer
                    and not state.AntiSuspiciousRestUntil and not state.PerformanceBoosters["Delete map"]
                    and not state.PerformanceBoosters["Remove everything"] and state.MovementOwnership.Resolve(now)=="Farm"
            end,
            Character=function()
                local character=player.Character
                local humanoid=character and character:FindFirstChildOfClass("Humanoid")
                local root=character and character:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health>0 and not humanoid.SeatPart and root and not root.Anchored then return root,humanoid end
                return nil,humanoid
            end,
            Surface=function(root,point)
                if point.Y<=workspace.FallenPartsDestroyHeight+30 then return nil end
                local excluded={root.Parent}
                for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","WaveDefenseStuff"})do
                    local folder=workspace:FindFirstChild(name);if folder then excluded[#excluded+1]=folder end
                end
                params.FilterDescendantsInstances=excluded
                local hit=workspace:Raycast(point+Vector3.new(0,45,0),Vector3.new(0,-41,0),params)
                return hit and hit.Normal.Y>.6 and hit.Position.Y or nil
            end,
            CameraHeight=function(humanoid,root)
                return humanoid.RigType==Enum.HumanoidRigType.R6 and 3 or humanoid.HipHeight+root.Size.Y/2
            end,
            CreateProxy=function()
                return create("Part",{Name="FeatherDesyncCamera",Anchored=true,Transparency=1,CanCollide=false,
                    CanTouch=false,CanQuery=false,CastShadow=false,Size=Vector3.one},workspace)
            end,
            MoveProxy=function(proxy,position,y)
                local point=Vector3.new(position.X,y,position.Z)
                if (proxy.Position-point).Magnitude>.02 then proxy.Position=point end
            end})
        local heartbeat,nextUpdate
        local function stop()
            if heartbeat then heartbeat:Disconnect();heartbeat=nil end
            controller.Release()
        end
        local function apply(value)
            state.FarmDesync=value==true
            if not state.FarmDesync then stop();return end
            if heartbeat then return end
            nextUpdate=0
            heartbeat=RunService.Heartbeat:Connect(function()
                local now=os.clock()
                if now>=nextUpdate then nextUpdate=now+.1;controller.Update(now)end
            end)
        end
        state.FarmDesyncController=controller
        controller.Destroy=stop
        function state.SetFarmDesync(value)apply(value);requestSave()end
        apply(restore.FarmDesync)
    end
    installFarmDesync()
end
state.StartupComplete=true
