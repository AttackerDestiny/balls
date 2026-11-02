-- Engine adapter for the opt-in Account Progression coordinator.
return function(ctx)
    local state,player=ctx.State,ctx.Player
    local profile=game.ReplicatedStorage.Profiles:FindFirstChild(player.Name)
    local inventory,equip=profile.Inventory,profile.Equip
    local definitions=game.ReplicatedStorage.Database.Items
    local disposed,gearThread=false,nil
    local boss,health,lives,death,baseline,maxOwn,deathAt=nil,nil,nil,false,0,0,nil
    local bossConnections={}
    local function matchesBoss(spot,mob)
        if not spot.EncounterNames then return true end
        local name=mob.Name:lower():gsub("[^%w]","")
        for expected in pairs(spot.EncounterNames)do
            if expected:lower():gsub("[^%w]","")==name then return true end
        end
        return false
    end
    local function clearBoss()
        for _,connection in ipairs(bossConnections)do connection:Disconnect()end
        bossConnections={};boss,health,lives,death,baseline,maxOwn,deathAt=nil,nil,nil,false,0,0,nil
        state.ProgressionBossMob=nil
    end
    local function contribution()
        if not health then return end
        local value=ctx.OwnDamage(health)
        maxOwn=math.max(maxOwn,value or 0)
    end
    local function observe(mob,data)
        clearBoss();boss,health,lives=mob,data.Health,data.HitLives
        baseline=ctx.OwnDamage(health)or 0;maxOwn=baseline
        local function changed()
            contribution()
            if health.Value<=0 and (not lives or lives.Value<=0)then death=true;deathAt=deathAt or os.clock()end
        end
        bossConnections[#bossConnections+1]=health:GetPropertyChangedSignal("Value"):Connect(changed)
        if lives then bossConnections[#bossConnections+1]=lives.Changed:Connect(changed)end
        bossConnections[#bossConnections+1]=health.ChildAdded:Connect(function(child)
            if child.Name==player.Name and child:IsA("ValueBase")then
                contribution()
                bossConnections[#bossConnections+1]=child.Changed:Connect(contribution)
            end
        end)
        local counter=health:FindFirstChild(player.Name)
        if counter then bossConnections[#bossConnections+1]=counter.Changed:Connect(contribution)end
        state.ProgressionBossMob=mob
    end
    local ui=state.UI
    ui.ProgressionToggle=ctx.Button("AccountProgression","Account Progression · OFF",10,34,ctx.Parent)
    ui.ProgressionStatus=ctx.Label("ProgressionStatus","Account Progression is off",20,64)
    ui.ProgressionStatus.Parent=ctx.Parent;ui.ProgressionStatus.TextWrapped=true
    ui.ProgressionGear=ctx.Label("ProgressionGear","Owned usable swords, armor and accessories",30,48)
    ui.ProgressionGear.Parent=ctx.Parent;ui.ProgressionGear.TextWrapped=true
    local hint=ctx.Label("ProgressionHint","F1 → F12 · resumes after joins. F6 is skipped. Safe Mode protects the current floor; Multi Spot waits. Toggle OFF to restore your farm settings.",40,96)
    hint.Parent=ctx.Parent;hint.TextWrapped=true
    local function text(label,value)if label.Text~=value then label.Text=value end end
    local function field(instance,name,fallback)
        local child=instance and instance:FindFirstChild(name)
        return child and child:IsA("ValueBase") and child.Value or fallback
    end
    local function gearActive()
        return not disposed and state.Running and not state.StopEverything and not state.ModeratorBlocking
            and ((state.AccountProgression and not state.ProgressionComplete)or (not state.AccountProgression and state.AutoEquipBestSword))
    end
    local function readGear()
            local result={Level=math.floor(profile.Stats.Exp.Value^(1/3)),Items={},Equip={},
                Highest={Damage=player:GetAttribute("HighestDamage")or 0,Defense=player:GetAttribute("HighestDefense")or 0}}
            for _,slot in ipairs(equip:GetChildren())do if slot:IsA("IntValue")then result.Equip[slot.Name]=slot.Value end end
            for _,item in ipairs(inventory:GetChildren())do
                local definition=definitions:FindFirstChild(item.Name)
                local stats=definition and definition:FindFirstChild("Stats")
                if item:IsA("IntValue") and stats then
                    local values={};for _,value in ipairs(stats:GetChildren())do
                        if value:IsA("ValueBase")then values[value.Name]=value.Value end
                    end
                    local match=definition:FindFirstChild("MatchBest")
                    result.Items[#result.Items+1]={Native=item,Id=item.Value,Name=item.Name,
                        Type=field(definition,"Type",""),Class=field(definition,"Class",""),
                        Level=field(definition,"Level",0),Rarity=field(definition,"Rarity","Common"),
                        Upgrade=field(item,"Upgrade",0),Skin=field(definition,"Type","")=="Accessory"and item:FindFirstChild("Skin")~=nil,
                        Scale=field(definition,"ScaleByLevel",nil),
                        MatchBest=match and (match:IsA("ValueBase")and tonumber(match.Value)or 1)or nil,Stats=values}
                end
            end
            return result
    end
    local gear=ctx.MakeGear({SkipWeapons=function()return state.AutoEquipBestSword==false end,WeaponsOnly=function()return not state.AccountProgression end,Rarity=require(game.ReplicatedStorage.Shared.Library.RarityData),
        Active=gearActive,
        Busy=function()return state.AutoTradeBusy or state.SafeModePanic or state.TravelBusy or state.AutomationTeleporting
            or state.Dodging or state.Recovering or state.SkillCastRunning or state.MiscCastRunning or ctx.SkillsBusy()end,
        Read=readGear,
        Equip=function(op)
            if not gearActive() or op.Item.Native.Parent~=inventory then return false,"Equipment changed"end
            ctx.StopCombat("Equipping best usable weapon / gear")
            local args={op.Action,op.Item.Native}
            if op.Action=="EquipWeapon"then args[3]=op.Slot end
            local reply=game.ReplicatedStorage.Function:InvokeServer("Equipment",args)
            if reply==false then return false,"Equipment request was rejected"end
            return true
        end,
        Status=function(value)state.ProgressionGearStatus=value;text(ui.ProgressionGear,value)end})
    state.ProgressionGearController=gear
    function state.IsAutoEquipmentCandidate(item)
        if not gearActive()then return false end
        for _,op in ipairs(gear.Plan(readGear()))do
            if op.Action~="Unequip"and op.Item.Native==item then return true end
        end
        return false
    end

    local function invalidate()if not disposed then gear.Invalidate()end end
    ctx.Bind(inventory.DescendantAdded,function(child)
        invalidate()
        if child.Name=="Upgrade" and child:IsA("ValueBase")then ctx.Bind(child.Changed,invalidate)end
    end)
    ctx.Bind(inventory.DescendantRemoving,invalidate)
    for _,upgrade in ipairs(inventory:QueryDescendants("#Upgrade"))do
        if upgrade:IsA("ValueBase")then ctx.Bind(upgrade.Changed,invalidate)end
    end
    ctx.Bind(equip.DescendantAdded,function(slot)
        invalidate();if slot:IsA("ValueBase")then ctx.Bind(slot.Changed,invalidate)end
    end)
    ctx.Bind(equip.DescendantRemoving,invalidate)
    for _,slot in ipairs(equip:GetChildren())do if slot:IsA("ValueBase")then ctx.Bind(slot.Changed,invalidate)end end
    ctx.Bind(profile.Stats.Exp.Changed,invalidate)
    ctx.Bind(player:GetAttributeChangedSignal("HighestDamage"),invalidate)
    ctx.Bind(player:GetAttributeChangedSignal("HighestDefense"),invalidate)
    local function release()
        clearBoss();state.ProgressionAnchor=nil
        if state.ProgressionTravelOwned and state.TravelBusy then
            state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false
        end
        state.ProgressionTravelOwned=false;state.TravelHold=false;state.TravelHoldPosition=nil
        ctx.StopCombat("Progression movement released")
    end
    local function complete()
        ctx.StopCombat("Account progression complete")
        state.SetAutoFarm(false,"Account progression complete");state.SetEnabled(false)
    end
    local function syncFloor()
        if not state.AccountProgression or state.SafeFloorId==game.PlaceId then return end
        for _,floor in ipairs(state.AutomationCatalog.Floors)do
            if floor.Id==game.PlaceId then
                state.SafeFloorId=game.PlaceId
                state.SaveNow()
                if state.RefreshAutomationUI then state.RefreshAutomationUI()end
                break
            end
        end
    end
    local function updateEquipment(now)
            if gearThread or gear.Paused or not gear.HasWork() then return end
            gearThread=task.spawn(function()
                state.ProgressionEquipping=true
                local ok,message=pcall(gear.Update,now)
                state.ProgressionEquipping=false;gearThread=nil
                if not ok then gear.Paused=true;gear.Error=tostring(message);text(ui.ProgressionGear,gear.Error)end
            end)
            -- task.spawn can finish synchronously, before its return assigns the handle.
            if coroutine.status(gearThread)=="dead"then gearThread=nil end
            if gearThread then
                local pendingThread=gearThread
                task.delay(8,function()
                    if disposed or gearThread~=pendingThread then return end
                    pcall(task.cancel,pendingThread);gearThread=nil;state.ProgressionEquipping=false
                    gear.Paused=true;gear.Error="Equipment request timed out · toggle Auto Farm or progression OFF/ON to retry"
                    text(ui.ProgressionGear,gear.Error)
                end)
            end
    end
    local swordWasActive=false
    function state.UpdateBestSword(now)
        local active=not state.AccountProgression and state.AutoEquipBestSword
        if active~=swordWasActive then swordWasActive=active;gear.Reset()end
        if active then updateEquipment(now)end
    end
    local controller=ctx.MakeController({State=state,SyncFloor=syncFloor,
        Floor=function(number)
            for _,floor in ipairs(state.AutomationCatalog.Floors)do if floor.Number==number then return floor end end
        end,
        Unlocked=function(floor)return state.IsAutomationFloorUnlocked(floor.Id)end,
        CurrentFloor=function()return game.PlaceId end,
        Ready=function()
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            return root and not root.Anchored and humanoid and humanoid.Health>0
                and not state.SafeModePanic and not state.AutomationTeleporting and not state.Dodging
                and not state.Recovering and not state.ProgressionEquipping and not (state.SafeController and state.SafeController.Seeking)
                and (not state.TravelBusy or state.ProgressionTravelOwned)
        end,
        CombatReady=function()return state.Enabled and state.AutoFarm end,
        NearBossSpot=function(spot)
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not root then return false end
            if (root.Position-spot.Position).Magnitude<=350 then return true end
            local data=boss and boss.Parent and ctx.Data(boss)
            return data and (root.Position-data.Root.Position).Magnitude<=500 or false
        end,
        ChangeFloor=function(floor)return state.ChangeAutomationFloor(floor.Id)end,
        BossSpot=function(floor,index)
            state.AutomationCatalog.AddCurrent(state.FloorDestinations,game.PlaceId)
            local key=tostring(floor.Id).."/Boss"
            local primary=state.AutomationCatalog.SpotById and state.AutomationCatalog.SpotById[key]
            if primary then return primary end
            for _,spot in ipairs(state.AutomationCatalog.Spots)do
                if spot.PlaceId==floor.Id and spot.MainBoss then return spot end
            end
            local candidates={}
            for _,spot in ipairs(state.AutomationCatalog.Spots)do
                if spot.PlaceId==floor.Id then
                    if spot.Kind=="Boss"then return spot end
                    if floor.Number==12 and spot.Kind=="Arena"then candidates[#candidates+1]=spot end
                end
            end
            table.sort(candidates,function(a,b)return a.Id<b.Id end)
            local spot=candidates[(index-1)%math.max(1,#candidates)+1]
            if spot then return {Id=spot.Id,PlaceId=spot.PlaceId,Name=spot.Name,Kind=spot.Kind,
                DestinationId=spot.DestinationId,Position=spot.Position,Scout=true}end
        end,
        Go=function(spot)
            if state.TravelBusy then return false,"Another movement is active"end
            clearBoss();ctx.StopCombat("Moving to the progression boss")
            state.RegisterAutomationDestination(spot);state.ProgressionAnchor=spot.Position
            state.ProgressionTravelOwned=true
            return state.TeleportToDestination(spot.DestinationId,false,false)
        end,
        Moving=function()return state.TravelBusy end,
        Arrived=function(spot)
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            return spot and root and state.LastTravelPosition and state.LastTravelDestination==spot.DestinationId
                and (root.Position-state.LastTravelPosition).Magnitude<=25
        end,
        Arrival=function()state.ProgressionTravelOwned=false;state.TravelHold=false;state.TravelHoldPosition=nil end,
        Boss=function(spot)
            if boss and not matchesBoss(spot,boss)then clearBoss()end
            contribution()
            if boss then
                if death or (health.Value<=0 and (not lives or lives.Value<=0)) then
                    deathAt=deathAt or os.clock()
                    if maxOwn>baseline or os.clock()-deathAt<1 or boss.Parent then
                        return {Defeated=true,Credited=maxOwn>baseline,Name=boss.Name}
                    end
                    clearBoss();return
                end
                if boss.Parent and health.Parent then return {Alive=true,Name=boss.Name}end
                clearBoss()
            end
            for mob in pairs(ctx.Mobs())do
                if mob.Parent and ctx.Rank(mob)==1 and matchesBoss(spot,mob)then
                    local data=ctx.Data(mob)
                    if data and data.Health.Value>0 and (data.Root.Position-spot.Position).Magnitude<=220 then
                        observe(mob,data);return {Alive=true,Name=mob.Name}
                    end
                end
            end
        end,
        Equipment=updateEquipment,
        Complete=complete,Release=release,Save=state.SaveNow,
        Status=function(value)state.ProgressionStatus=value;text(ui.ProgressionStatus,value)end})
    state.ProgressionController=controller
    function state.SetAccountProgression(on,restoring)
        if on and state.StopEverything then return false end
        if gearThread then pcall(task.cancel,gearThread);gearThread=nil end
        state.ProgressionEquipping=false;gear.Reset()
        if on then
            for _,floor in ipairs(state.AutomationCatalog.Floors)do
                if floor.Number==state.ProgressionFloor then
                    local primary=state.AutomationCatalog.SpotById and state.AutomationCatalog.SpotById[tostring(floor.Id).."/Boss"]
                    if state.ProgressionBossCleared and primary and primary.EncounterNames
                        and not matchesBoss(primary,{Name=state.ProgressionBossClearedName or ""})then
                        -- Older builds could persist a side boss as the floor clear.
                        state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
                    end
                    break
                end
            end
            if not state.ProgressionRestore then state.ProgressionRestore={Enabled=state.Enabled,AutoFarm=state.AutoFarm,AutoSwing=state.AutoSwing,SafeFloorId=state.SafeFloorId}end
            if state.ProgressionRestore.SafeFloorId==nil then state.ProgressionRestore.SafeFloorId=state.SafeFloorId end
            if state.ProgressionComplete and not restoring then
                state.ProgressionFloor=1;state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil;state.ProgressionComplete=false
            end
        end
        state.AccountProgression=on==true
        if state.AccountProgression then syncFloor()
        elseif state.ProgressionRestore and state.ProgressionRestore.SafeFloorId then state.SafeFloorId=state.ProgressionRestore.SafeFloorId end
        if state.MultiSpotController then state.MultiSpotController.Reset()end
        -- A queued startup may already be resuming an active block/rejoin ticket.
        -- Preserve its attempt budget and phase across progression-owned joins.
        if not restoring and state.SafeController then state.SafeController.Reset()end
        controller.Reset()
        if state.AccountProgression then
            if state.ProgressionComplete then complete()
            else state.SetAutoFarm(true,"Account progression");state.SetEnabled(true)end
        elseif state.ProgressionRestore then
            local previous=state.ProgressionRestore;state.ProgressionRestore=nil
            state.SetAutoFarm(previous.AutoFarm==true,"Account progression stopped");state.SetEnabled(previous.Enabled==true)
            if type(previous.AutoSwing)=="boolean"and state.SetAutoSwing then state.SetAutoSwing(previous.AutoSwing)end
        end
        ui.ProgressionToggle.Text=state.AccountProgression and "Account Progression · ON"or"Account Progression · OFF"
        ui.ProgressionToggle.BackgroundColor3=state.AccountProgression and Color3.fromRGB(91,72,164)or Color3.fromRGB(38,41,56)
        state.SaveNow();if state.RefreshAutomationUI then state.RefreshAutomationUI()end;return true
    end
    ctx.Bind(ui.ProgressionToggle.Activated,function()state.SetAccountProgression(not state.AccountProgression)end)
    function state.ProgressionDestroy()
        disposed=true
        if gearThread then pcall(task.cancel,gearThread);gearThread=nil end
        state.ProgressionEquipping=false;controller.Destroy()
    end
    if state.AccountProgression then state.SetAccountProgression(true,true)end
    return controller
end
