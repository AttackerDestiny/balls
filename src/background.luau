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
        local function groundRay(root,point,above,depth)
            if point.Y<=workspace.FallenPartsDestroyHeight+30 or state.PerformanceBoosters["Delete map"]
                or state.PerformanceBoosters["Remove everything"]then return nil end
            local excluded={root.Parent}
            for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","WaveDefenseStuff"})do
                local folder=workspace:FindFirstChild(name);if folder then excluded[#excluded+1]=folder end
            end
            params.FilterDescendantsInstances=excluded
            local hit=workspace:Raycast(point+Vector3.new(0,above,0),Vector3.new(0,-depth,0),params)
            return hit and hit.Normal.Y>.6 and hit.Position.Y or nil
        end
        local function cameraHeight(humanoid,root)
            return humanoid.RigType==Enum.HumanoidRigType.R6 and 3 or humanoid.HipHeight+root.Size.Y/2
        end
        local controller=make({Render=RunService.PreRender,Camera=function()return workspace.CurrentCamera end,
            Mode=function(now)
                local owner=state.MovementOwnership.Resolve(now)
                if not state.Running or not state.FarmDesync or state.StopEverything or state.AntiSuspiciousRestUntil then
                    return nil,"Paused",owner=="Stopped" or owner=="Manual"
                end
                if state.TravelHold or state.ProtectionRetreating or (owner~="Manual" and owner~="Farm")then return nil,"Paused · "..owner end
                return owner=="Farm" and "Farm" or "Hold"
            end,
            Character=function()
                local character=player.Character
                local humanoid=character and character:FindFirstChildOfClass("Humanoid")
                local root=character and character:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health>0 and not humanoid.SeatPart and root and not root.Anchored then return root,humanoid end
                return nil,humanoid
            end,
            Surface=function(root,point)return groundRay(root,point,45,41)end,
            Ground=function(root,point)
                local floor=groundRay(root,point,1,10)
                return floor and floor<=point.Y and floor or nil
            end,
            FarmReference=function(point)
                if point.Y<=workspace.FallenPartsDestroyHeight+30 or state.FixedFarmPosition then return nil end
                if state.IdleBelowMap and type(state.IdleFloorY)=="number"then
                    local depth=state.IdleFloorY-point.Y
                    if depth>=6 and depth<=45 then return state.IdleFloorY end
                end
                if state.Moving then return point.Y+20 end
            end,
            BeginHold=function(root,humanoid,floor,fallback)
                local point=root.Position
                local below=Vector3.new(point.X,floor-20,point.Z)
                if below.Y<=workspace.FallenPartsDestroyHeight+35 or movementRoot then return nil end
                local surface=fallback and point or Vector3.new(point.X,floor+cameraHeight(humanoid,root)+.5,point.Z)
                local attachment=create("Attachment",{Name="FeatherDesyncAttachment"},root)
                local align=create("AlignPosition",{Name="FeatherDesyncHold",Mode=Enum.PositionAlignmentMode.OneAttachment,
                    Attachment0=attachment,Position=below,ApplyAtCenterOfMass=true,
                    MaxForce=math.max(1,root.AssemblyMass)*workspace.Gravity*8,MaxVelocity=60,Responsiveness=45},root)
                state.DesyncHolding=true;state.FarmNoclip.Update()
                pivotRoot(root,below)
                return {Root=root,Humanoid=humanoid,Align=align,Attachment=attachment,Position=below,Floor=floor,Surface=surface}
            end,
            HoldValid=function(hold)
                return hold.Align.Parent and (hold.Root.Position-hold.Position).Magnitude<=8
            end,
            EndHold=function(hold,restorePosition)
                hold.Align:Destroy();hold.Attachment:Destroy()
                local root=hold.Root
                if restorePosition and root.Parent==player.Character and not root.Anchored and hold.Humanoid.Health>0
                    and root.Position.Y<hold.Floor then
                    local drift=root.Position-hold.Position
                    if math.abs(drift.Y)<=25 and drift.X*drift.X+drift.Z*drift.Z<=36 then pivotRoot(root,hold.Surface)end
                end
                state.DesyncHolding=false;state.FarmNoclip.Update()
            end,
            CameraOffset=function(root,base,depth)
                return base+root.CFrame:VectorToObjectSpace(Vector3.new(0,depth,0))
            end})
        local heartbeat,nextUpdate
        local function stop()
            if heartbeat then heartbeat:Disconnect();heartbeat=nil end
            controller.Release("Off",not state.AutomationTeleporting and not state.TravelBusy and not state.SafeModePanic and not state.Dodging)
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
