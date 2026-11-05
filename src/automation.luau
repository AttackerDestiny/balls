state.SetAutoSwing(restore.AutoSwing)
state.SetEnabled(restore.Enabled)
if restore.AutoFarm then state.SetAutoFarm(true); if not restore.Enabled then state.SetEnabled(false) end end
state.SetSkillAura(restore.SkillAura)
configReady = true
state.SaveNow()
do
    local create=(function()
-- BEGIN BUNDLED MODERATOR WATCH
-- END BUNDLED MODERATOR WATCH
    end)()
    local makeRejoin=(function()
-- BEGIN BUNDLED MODERATOR REJOIN
-- END BUNDLED MODERATOR REJOIN
    end)()
    local teleportService=game:GetService("TeleportService")
    local rejoin=makeRejoin({State=state,Spawn=task.spawn,Sleep=task.wait,
        Queue=function()
            local queue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
            assert(type(queue)=="function","Executor has no teleport queue")
            queue('loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()')
        end,
        Teleport=function()teleportService:Teleport(game.PlaceId,player)end,
        Kick=function(message)player:Kick(message)end})
    state.ModeratorRejoin=rejoin
    bind(player.OnTeleport,function(phase)
        if phase==Enum.TeleportState.Started or phase==Enum.TeleportState.InProgress then rejoin.MarkStarted()end
    end)
    state.ModeratorWatch=create({State=state,Players=Players,Save=state.SaveNow,
        Pause=function()
            if state.SoloServerSearch and state.SoloServerSearch.Active then pcall(state.SoloServerSearch.Stop,"Moderator detection has priority")end
            state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false;state.AutomationTeleporting=false
            finishAttackBurst("Moderator detected");stopSword(true)
            if state.CancelSkillAura then state.CancelSkillAura("Moderator detected")end
            if state.CancelMiscSkill then state.CancelMiscSkill()end
            stopMovement("Moderator detected · blocking before disconnect",true)
            if state.FarmNoclip then state.FarmNoclip.Update()end
            if state.PanicToSpawn then state.PanicToSpawn()end
        end,
        Block=function(target,active)
            local deadline=os.clock()+8
            while active()and not state.BlockPlayerNative and os.clock()<deadline do task.wait(.04)end
            if not active()then return false end
            assert(state.BlockPlayerNative,"Native block handler did not initialize")
            return state.BlockPlayerNative(target,active)
        end,
        Notify=function(message)
            state.SafeModeStatus=message;state.MultiSpotStatus=message;state.ProgressionStatus=message
            movementStatus(message)
        end,
        Kick=rejoin.Kick})
end
bind(player.OnTeleport, function(teleportState)
    if teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress then state.SaveNow() end
end)

-- Player utilities use the same replicated profile and character paths as the supplied source.
do
    local ui=state.UI
    local tools
    local savedSelection=restore.SelectedPlayerId
    local savedView,savedInventory=restore.ViewingPlayer,restore.ViewingPlayerInventory
    local function message(text)
        if not state.Running then return end
        state.PlayerStatus=text or ""
        ui.PlayerMessage.Text=state.PlayerStatus
        ui.PlayerMessage.Visible=state.PlayerStatus~=""
    end
    local function render()
        if not tools or not state.Running then return end
        local selected=tools.GetSelected()
        ui.PlayerSelector.Text=selected and (selected.DisplayName==selected.Name and "@"..selected.Name or selected.DisplayName.." (@"..selected.Name..")") or "Select player"
        ui.ViewPlayer.Text=tools.Viewing and "View player · ON" or "View player · OFF"
        ui.ViewInventory.Text=tools.InventoryVisible and "View player inventory · ON" or "View player inventory · OFF"
        ui.ViewPlayer.BackgroundColor3=tools.Viewing and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        ui.ViewInventory.BackgroundColor3=tools.InventoryVisible and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        ui.PlayerInventory.Visible=tools.InventoryVisible
        if savedSelection~=state.SelectedPlayerId or savedView~=tools.Viewing or savedInventory~=tools.InventoryVisible then
            savedSelection,savedView,savedInventory=state.SelectedPlayerId,tools.Viewing,tools.InventoryVisible
            requestSave()
        end
    end
    local function refreshPlayers()
        if not tools or not state.Running or state.StopEverything then return end
        for _,child in ipairs(ui.PlayerOptions:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
        local choices=tools.Choices()
        state.PlayerChoices=choices
        for index,entry in ipairs(choices) do
            local text=entry.DisplayName==entry.Name and "@"..entry.Name or entry.DisplayName.." (@"..entry.Name..")"
            local option=uiButton("Player"..entry.UserId,text,index,28,ui.PlayerOptions)
            option.Font=Enum.Font.Gotham; option.TextSize=10
            option.Activated:Connect(function()
                if state.StopEverything then return end
                local ok,reason=tools.Select(entry.UserId)
                ui.PlayerOptions.Visible=false
                message(ok and "" or reason)
            end)
        end
        if #choices==0 then
            create("TextLabel",{Name="Empty",Text="No other players in this server",Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,
                Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.fromRGB(153,161,187)},ui.PlayerOptions)
        end
    end
    local makePlayerTools=(function()
-- BEGIN BUNDLED PLAYER TOOLS
-- END BUNDLED PLAYER TOOLS
    end)()
    local makeInventoryView=(function()
-- BEGIN BUNDLED INVENTORY VIEW
-- END BUNDLED INVENTORY VIEW
    end)()
    local inventoryView=makeInventoryView({OwnProfile=ReplicatedStorage.Profiles:FindFirstChild(player.Name),
        Function=function()return require(services.UI.Inventory).GetInventoryData end,
        Read=function(fn,index)
            assert(type(debug.getupvalue)=="function","Executor cannot read inventory renderer upvalues")
            local first,second=debug.getupvalue(fn,index)
            return second~=nil and second or first
        end,
        Write=function(fn,index,value)
            assert(type(debug.setupvalue)=="function","Executor cannot change inventory renderer upvalues")
            debug.setupvalue(fn,index,value)
        end})
    tools=makePlayerTools({State=state,Players=Players,LocalPlayer=player,Workspace=workspace,Profiles=ReplicatedStorage:FindFirstChild("Profiles"),
        NativeInventory=function(target)
            local profile=target and ReplicatedStorage.Profiles:FindFirstChild(target.Name)
            if target and not profile then return false,"Selected player's inventory profile is not loaded"end
            return inventoryView.Set(profile)
        end,
        Changed=render,RosterChanged=function() if ui.PlayerOptions.Visible then refreshPlayers() end end,
        Inventory=function(rows,reason,target)
            if not state.Running then return end
            state.PlayerInventoryRows=rows;state.PlayerInventoryMessage=reason
            for _,child in ipairs(ui.PlayerInventory:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
            local function row(text,index)
                create("TextLabel",{Name="Item"..index,Text=text,LayoutOrder=index,Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
                    Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,
                    TextColor3=Color3.fromRGB(219,223,238)},ui.PlayerInventory)
            end
            if reason or #rows==0 then row(reason or "No inventory items",1)
            else for index,item in ipairs(rows) do
                row(item.Name..(item.Upgrade>0 and " +"..item.Upgrade or "")..(item.Count>1 and " ×"..item.Count or ""),index)
            end end
            state.ViewedInventoryCount=#rows
        end,
        Teleport=function(target)
            if state.TravelBusy then return false,"Another teleport is still running" end
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local targetRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if not root or not humanoid or humanoid.Health<=0 or not targetRoot or root.Anchored then return false,"Player character is not loaded or ready" end
            state.TravelBusy=true
            ui.PlayerOptions.Visible=false
            task.spawn(function()
                local moved=false
                local ok,reason=pcall(function()
                    local deadline=os.clock()+4
                    repeat task.wait(.05) until (not state.Recovering and not state.SkillCastRunning) or os.clock()>deadline or not state.Running or state.StopEverything
                    if not state.Running or state.StopEverything then return end
                    assert(not state.SkillCastRunning and not state.Recovering,"Wait for the current skill to finish")
                    assert(target.Parent==Players and target.Character and player.Character==character,"Player left or respawned")
                    local otherRoot=target.Character:FindFirstChild("HumanoidRootPart")
                    local otherHumanoid=target.Character:FindFirstChildOfClass("Humanoid")
                    assert(otherRoot and otherHumanoid and otherHumanoid.Health>0,"Target character is unavailable")
                    local destination=otherRoot.Position+Vector3.new(0,5,0)
                    assert(finitePoint(destination) and destination.Y>workspace.FallenPartsDestroyHeight+40,"Target position is too low")
                    stopMovement("Travelling to player",true)
                    ensureMovementController(character,root,humanoid,destination)
                    positionAlign.Position=destination; pivotRoot(root,destination)
                    moved=true
                    lastSurfaceY=otherRoot.Position.Y+3
                    state.TeleportsSent+=1
                    state.LastPlayerTeleport={UserId=target.UserId,Name=target.Name,Requested=destination,Actual=root.Position,At=os.clock()}
                    task.wait(.75)
                    if not state.Running or state.StopEverything then return end
                    assert(root.Parent and (root.Position-destination).Magnitude<18,"The game corrected this teleport")
                    state.TravelHold=not (state.AutoFarm and state.Enabled)
                    state.TravelHoldPosition=state.TravelHold and destination or nil
                end)
                state.TravelBusy=false
                if not state.Running or state.StopEverything then return end
                if not ok then
                    if moved then stopMovement("Player teleport stopped") end
                    message(tostring(reason))
                else message("") end
            end)
            return true
        end,
    })
    state.PlayerTools=tools
    if savedSelection then tools.Select(savedSelection) end
    if restore.ViewingPlayer then tools.SetViewing(true) end
    if restore.ViewingPlayerInventory then tools.SetInventoryVisible(true) end
    render(); refreshPlayers()
    bind(ui.PlayerSelector.Activated,function()
        if state.StopEverything then return end
        if not ui.PlayerOptions.Visible then refreshPlayers() end
        ui.PlayerOptions.Visible=not ui.PlayerOptions.Visible
        if ui.PlayerOptions.Visible then revealOptions(ui.PlayerOptions) end
    end)
    bind(ui.TeleportPlayer.Activated,function() local ok,reason=tools.Teleport(); message(ok and "" or reason) end)
    bind(ui.ViewPlayer.Activated,function() local ok,reason=tools.SetViewing(not tools.Viewing); message(ok and "" or reason) end)
    bind(ui.ViewInventory.Activated,function()
        local ok,reason=tools.SetInventoryVisible(not tools.InventoryVisible)
        message(ok and "" or reason)
        if ok and tools.InventoryVisible then revealOptions(ui.PlayerInventory) end
    end)
end

-- Support skills from the provided source, with native cooldown and stamina checks.
do
    local miscThread
    local catalog={"Cursed Enhancement","Heal","Mending Spirit","Summon Tree"}
    local function definition(name) return ReplicatedStorage.Database.Skills:FindFirstChild(name) end
    local function usable(name)
        local value=definition(name)
        return value and type(Skills.skillHandlers[name])=="function" and GameUI.IsSkillValid(value)==true
    end
    local function refreshMisc()
        local list=state.UI.MiscSkillOptions
        for _,child in ipairs(list:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
        state.MiscSkillChoices={}
        for index,name in ipairs(catalog) do
            if definition(name) and Skills.skillHandlers[name] then
                local allowed=usable(name)
                state.MiscSkillChoices[#state.MiscSkillChoices+1]={Name=name,Usable=allowed}
                local option=uiButton("MiscOption"..index,name..(allowed and "" or " (locked)"),index,28,list)
                option.Font=Enum.Font.Gotham; option.TextSize=11; option.Active=allowed
                option.TextColor3=allowed and Color3.fromRGB(226,229,243) or Color3.fromRGB(117,124,146)
                option.Activated:Connect(function() if allowed then state.SetMiscSkill(name) end end)
            end
        end
    end
    function state.SetMiscSkill(name)
        if not table.find(catalog,name) or not usable(name) then return false end
        state.SelectedMiscSkill=name
        state.MiscReserveStamina=false
        state.UI.MiscSkillDropdown.Text=name.."  v"
        state.UI.MiscSkillOptions.Visible=false
        requestSave()
        return true
    end
    function state.SetMiscSkillEnabled(enabled)
        if enabled and state.StopEverything then return false end
        state.MiscSkillEnabled=enabled==true
        if not enabled then state.MiscReserveStamina=false end
        state.UI.MiscSkillToggle.Text=state.MiscSkillEnabled and "Misc Skill · ON" or "Misc Skill · OFF"
        state.UI.MiscSkillToggle.BackgroundColor3=state.MiscSkillEnabled and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        requestSave()
    end
    function state.CancelMiscSkill()
        if miscThread then pcall(task.cancel,miscThread); miscThread=nil end
        state.MiscCastRunning=false; state.MiscReserveStamina=false
    end
    local makeMisc=(function()
-- BEGIN BUNDLED MISC SKILL
-- END BUNDLED MISC SKILL
    end)()
    state.MiscController=makeMisc({State=state,
        Read=function(name)
            local value=definition(name)
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local entity=character and character:FindFirstChild("Entity")
            local health=entity and entity:FindFirstChild("Health")
            local stamina=entity and entity:FindFirstChild("Stamina")
            if not value or not root or not health or not stamina then return end
            local maximum=entity:FindFirstChild("MaxHealth")
            local constrained=health:IsA("IntConstrainedValue") or health:IsA("DoubleConstrainedValue")
            local maxHealth=constrained and health.MaxValue or maximum and maximum.Value or math.max(1,health.Value)
            return {Definition=value,Character=character,Entity=entity,Root=root,HealthValue=health,StaminaValue=stamina,
                Health=health.Value,MaxHealth=maxHealth,Stamina=stamina.Value,Cost=value.Cost.Value,
                Cooldown=Skills.GetCooldown(name),Usable=usable(name),BuffActive=name=="Cursed Enhancement" and character:GetAttribute("CursedEnhancement")==true,
                Attacking=state.IsAttackingEnemy(),
                Busy=state.SkillCastRunning or Skills.usingSkill~="none",
                Blocked=state.SafeModePanic or state.TravelBusy or state.Dodging or state.Recovering or state.ProtectionRetreating
                    or os.clock()<state.LagPauseUntil or (state.PingMs and state.PingMs>500)
                    or GameUI.IsMenuOpen() or not CanRunSkill(player,name)}
        end,
        Cast=function(name,snapshot)
            if state.StopEverything or not state.MiscSkillEnabled or state.MiscCastRunning then return false end
            state.MiscCastRunning=true
            miscThread=task.defer(function()
                local ok,message=pcall(function()
                    if state.StopEverything or not state.Running or not state.MiscSkillEnabled or player.Character~=snapshot.Character then return end
                    if name=="Cursed Enhancement" and not state.IsAttackingEnemy() then return end
                    local buffs=snapshot.Entity:FindFirstChild("Buffs")
                    local reduction=buffs and buffs:FindFirstChild("SkillReduction")
                    local cooldown=snapshot.Definition.Cooldown.Value*math.clamp(1-(reduction and reduction.Value or 0),0,1)
                    Skills.SetCooldown(name,cooldown)
                    pcall(GameUI.SkillUsed,name,cooldown)
                    ReplicatedStorage.Event:FireServer("Skills",{"UseSkill",name,{Direction=snapshot.Root.CFrame.LookVector}})
                    state.MiscSkillRequests+=1
                    local record={Name=name,At=os.clock(),Acknowledged=false}
                    state.LastMiscSkillCast=record
                    local deadline=os.clock()+math.clamp((state.PingMs or 100)/1000+.6,.8,1.5)
                    repeat
                        local curse=name=="Cursed Enhancement" and snapshot.Character:GetAttribute("CursedEnhancement")
                        if curse or snapshot.Stamina-snapshot.StaminaValue.Value>=math.max(1,snapshot.Cost*.5) then
                            record.Acknowledged=true
                            state.MiscSkillCasts+=1
                            break
                        end
                        task.wait(.04)
                    until os.clock()>=deadline or state.StopEverything or not state.Running or not snapshot.Root.Parent
                    if not record.Acknowledged and state.Running and not state.StopEverything then state.LastMiscSkillError="Support skill was not acknowledged" end
                end)
                if not ok then state.LastMiscSkillError=tostring(message) end
                state.MiscCastRunning=false; state.MiscReserveStamina=false; miscThread=nil
            end)
            return true
        end,
    })
    if not table.find(catalog,state.SelectedMiscSkill) then state.SelectedMiscSkill="Cursed Enhancement" end
    state.UI.MiscSkillDropdown.Text=state.SelectedMiscSkill.."  v"
    bind(state.UI.MiscSkillToggle.Activated,function() state.SetMiscSkillEnabled(not state.MiscSkillEnabled) end)
    bind(state.UI.MiscSkillDropdown.Activated,function()
        if state.StopEverything then return end
        skillList.Visible=false
        if not state.UI.MiscSkillOptions.Visible then refreshMisc() end
        state.UI.MiscSkillOptions.Visible=not state.UI.MiscSkillOptions.Visible
        if state.UI.MiscSkillOptions.Visible then revealOptions(state.UI.MiscSkillOptions) end
    end)
    refreshMisc()
    state.SetMiscSkillEnabled(restore.MiscSkillEnabled)
end



local padSlot=(function()
-- BEGIN BUNDLED PAD SLOT
-- END BUNDLED PAD SLOT
end)()
function state.PanicToSpawn(inPlace)
    local holdHere=inPlace==true
    if state.SafePanicHoldHere~=holdHere then state.SafePanicHerePosition=nil;state.SafePanicHereRoot=nil end
    state.SafePanicHoldHere=holdHere
    local first=not state.SafeModePanic
    state.SafeModePanic=true
    if first then
        state.SafePanicStartedAt=os.clock()
        state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false
        finishAttackBurst("Safe Mode panic");stopSword(true)
        if state.CancelSkillAura then state.CancelSkillAura("Safe Mode panic") end
        if state.CancelMiscSkill then state.CancelMiscSkill() end
        if state.MultiSpotController then state.MultiSpotController.Reset() end
        stopMovement(holdHere and "Safe Mode · holding current position"or "Holding at teleport pad",true)
        state.FollowTarget=nil;state.TravelFocus=nil
    end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return false end
    local position
    if not position and holdHere then
        if state.SafePanicHereRoot~=root or not state.SafePanicHerePosition then
            state.SafePanicHereRoot=root;state.SafePanicHerePosition=root.Position
        end
        position=state.SafePanicHerePosition
    end
    if not position then
        local pad=state.SafePanicSpawnPart
        if not pad or not pad.Parent then
            local reference=destinations.spawn and destinations.spawn.Position or root.Position
            local bestDistance
            for _,candidate in ipairs(workspace:QueryDescendants("SpawnLocation"))do
                local distance=(candidate.Position-reference).Magnitude
                if not bestDistance or distance<bestDistance then pad,bestDistance=candidate,distance end
            end
            state.SafePanicSpawnPart=pad
        end
        if pad then
            local height=pad.Size.Y/2+humanoid.HipHeight+root.Size.Y/2+.5
            if state.AutoJoinFriendHolding then
                local ids={}
                for _,person in ipairs(Players:GetPlayers())do ids[#ids+1]=person.UserId end
                local x,z=padSlot(player.UserId,ids,pad.Size.X,pad.Size.Z,root.Size.X,root.Size.Z)
                position=pad.CFrame:PointToWorldSpace(Vector3.new(x,height,z))
            else position=pad.Position+Vector3.new(0,height,0)end
        elseif destinations.spawn then position=destinations.spawn.Position+Vector3.new(0,4,0)end
    end
    if not position then return false end
    if root~=movementRoot then stopMovement(nil,true) end
    ensureMovementController(character,root,humanoid,position)
    if positionAlign and positionAlign.Position~=position then positionAlign.Position=position end
    if first or (root.Position-position).Magnitude>3 then pivotRoot(root,position) end
    state.TravelHold=true;state.TravelHoldPosition=position;state.SafePanicPosition=position
    return true
end
function state.PanicInPlace()return state.PanicToSpawn(true)end
function state.ReleaseSafePanic()
    state.SafeRejoinRequested=false;state.SafeRejoinAway=nil;state.SafeRejoinDispatch=nil
    if not state.SafeModePanic then return end
    state.SafeModePanic=false;state.SafePanicPosition=nil;state.SafePanicHoldHere=nil;state.SafePanicHerePosition=nil;state.SafePanicHereRoot=nil
    stopMovement("Safe Mode · server protected",true)
    state.FollowTarget=nil
end

do
    local make=(function()
-- BEGIN BUNDLED SERVER ISOLATION
-- END BUNDLED SERVER ISOLATION
    end)()
    local makeSafe=(function()
-- BEGIN BUNDLED SAFE MODE
-- END BUNDLED SAFE MODE
    end)()
    local makeMulti=(function()
-- BEGIN BUNDLED MULTI SPOT
-- END BUNDLED MULTI SPOT
    end)()
    local makeCatalog=(function()
-- BEGIN BUNDLED FLOOR CATALOG
-- END BUNDLED FLOOR CATALOG
    end)()
    local makeUI=(function()
-- BEGIN BUNDLED AUTOMATION UI
-- END BUNDLED AUTOMATION UI
    end)()
    local attach=(function()
-- BEGIN BUNDLED SERVER ISOLATION CLIENT
-- END BUNDLED SERVER ISOLATION CLIENT
    end)()
    local blockPoint=(function()
-- BEGIN BUNDLED BLOCK INPUT
-- END BUNDLED BLOCK INPUT
    end)()
    local makeBlockConfirm=(function()
-- BEGIN BUNDLED BLOCK CONFIRM
-- END BUNDLED BLOCK CONFIRM
    end)()
    local makeBlockMask=(function()
-- BEGIN BUNDLED BLOCK UI MASK
-- END BUNDLED BLOCK UI MASK
    end)()
    local makeFriend=(function()
-- BEGIN BUNDLED AUTO JOIN FRIEND
-- END BUNDLED AUTO JOIN FRIEND
    end)()
    local makeKickFallback=(function()
-- BEGIN BUNDLED SAFE KICK FALLBACK
-- END BUNDLED SAFE KICK FALLBACK
    end)()
    attach({MakeBlockMask=makeBlockMask,MakeKickFallback=makeKickFallback,Make=make,MakeSafe=makeSafe,MakeMulti=makeMulti,MakeCatalog=makeCatalog,MakeUI=makeUI,MakeFriend=makeFriend,BlockPoint=blockPoint,MakeBlockConfirm=makeBlockConfirm,
        State=state,Player=player,Players=Players,Bind=bind,Button=uiButton,Label=uiLabel,Create=create,
        Corner=corner,Reveal=revealOptions,Parent=content})
end

-- Account Progression owns only boss selection and cross-floor sequencing.
do
    local makeController=(function()
-- BEGIN BUNDLED ACCOUNT PROGRESSION
-- END BUNDLED ACCOUNT PROGRESSION
    end)()
    local makeGear=(function()
-- BEGIN BUNDLED PROGRESSION GEAR
-- END BUNDLED PROGRESSION GEAR
    end)()
    local attach=(function()
-- BEGIN BUNDLED PROGRESSION CLIENT
-- END BUNDLED PROGRESSION CLIENT
    end)()
    attach({State=state,Player=player,MakeController=makeController,MakeGear=makeGear,
        Parent=state.UI.Pages.Speacial,Button=uiButton,Label=uiLabel,Bind=bind,
        Mobs=function()refreshMobIndex();return trackedMobs end,Data=getMobData,
        Rank=targetPriority.Rank,OwnDamage=state.ReadOwnDamage,
        SkillsBusy=function()return Skills.usingSkill~="none"end,
        StopCombat=function(reason)
            finishAttackBurst(reason);stopSword(true)
            if state.CancelSkillAura then state.CancelSkillAura(reason)end
            state.FollowTarget=nil
        end})
end

runtimeOwner.Ready()
