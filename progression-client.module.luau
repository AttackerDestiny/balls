-- Native inventory, boss-observation and travel bindings for the progression machine.
return function(ctx)
    local state,player=ctx.State,ctx.Player
    local rs=game.ReplicatedStorage
    local profile=rs.Profiles:FindFirstChild(player.Name)
    local inventory,equip=profile.Inventory,profile.Equip
    local definitions=rs.Database.Items
    local closed=false
    local equipmentWorker
    local observation
    local watched={}
    local ui=state.UI
    ui.ProgressionToggle=ctx.Button("AccountProgression","Account Progression · OFF",10,34,ctx.Parent)
    ui.ProgressionStatus=ctx.Label("ProgressionStatus","Account Progression is off",20,64)
    ui.ProgressionGear=ctx.Label("ProgressionGear","Owned usable swords, armor and accessories",30,48)
    ui.ProgressionStatus.Parent=ctx.Parent;ui.ProgressionGear.Parent=ctx.Parent
    ui.ProgressionStatus.TextWrapped=true;ui.ProgressionGear.TextWrapped=true
    local function text(label,value)if label.Text~=value then label.Text=value end end
    local function field(object,name,default)
        local value=object and object:FindFirstChild(name)
        if value and value:IsA("ValueBase")then return value.Value end
        return default
    end
    local function matches(spot,mob)
        if not spot.EncounterNames then return true end
        local name=mob.Name:lower():gsub("[^%w]","")
        for candidate in pairs(spot.EncounterNames)do if candidate:lower():gsub("[^%w]","")==name then return true end end
        return false
    end
    local function clearBoss()
        local old=observation;observation=nil;state.ProgressionBossMob=nil
        if old then for _,connection in ipairs(old.connections)do connection:Disconnect()end end
    end
    local function credit(record)
        local amount=ctx.OwnDamage(record.health)
        record.high=math.max(record.high,amount or 0)
    end
    local function observe(mob,data)
        clearBoss()
        local own=ctx.OwnDamage(data.Health)or 0
        local record={mob=mob,health=data.Health,lives=data.HitLives,baseline=own,high=own,connections={}}
        observation=record;state.ProgressionBossMob=mob
        local function bind(signal,callback)record.connections[#record.connections+1]=signal:Connect(callback)end
        local function changed()
            credit(record)
            if record.health.Value<=0 and (not record.lives or record.lives.Value<=0)then
                record.dead=true;record.diedAt=record.diedAt or os.clock()
            end
        end
        bind(record.health:GetPropertyChangedSignal("Value"),changed)
        if record.lives then bind(record.lives.Changed,changed)end
        bind(record.health.ChildAdded,function(value)
            if value.Name==player.Name and value:IsA("ValueBase")then credit(record);bind(value.Changed,function()credit(record)end)end
        end)
        local counter=record.health:FindFirstChild(player.Name)
        if counter then bind(counter.Changed,function()credit(record)end)end
    end
    local function gearActive()
        if closed or not state.Running or state.StopEverything or state.ModeratorBlocking then return false end
        if state.AccountProgression then return not state.ProgressionComplete end
        return state.AutoEquipBestSword
    end
    local function gearSnapshot()
        local snapshot={Level=math.floor(profile.Stats.Exp.Value^(1/3)),Items={},Equip={},
            Highest={Damage=player:GetAttribute("HighestDamage")or 0,Defense=player:GetAttribute("HighestDefense")or 0}}
        for _,slot in ipairs(equip:GetChildren())do if slot:IsA("IntValue")then snapshot.Equip[slot.Name]=slot.Value end end
        for _,item in ipairs(inventory:GetChildren())do
            local definition=definitions:FindFirstChild(item.Name)
            local stats=definition and definition:FindFirstChild("Stats")
            if item:IsA("IntValue")and stats then
                local values={}
                for _,stat in ipairs(stats:GetChildren())do if stat:IsA("ValueBase")then values[stat.Name]=stat.Value end end
                local match=definition:FindFirstChild("MatchBest")
                snapshot.Items[#snapshot.Items+1]={Native=item,Id=item.Value,Name=item.Name,
                    Type=field(definition,"Type",""),Class=field(definition,"Class",""),
                    Level=field(definition,"Level",0),Rarity=field(definition,"Rarity","Common"),Upgrade=field(item,"Upgrade",0),
                    Skin=field(definition,"Type","")=="Accessory"and item:FindFirstChild("Skin")~=nil,
                    Scale=field(definition,"ScaleByLevel",nil),
                    MatchBest=match and (match:IsA("ValueBase")and tonumber(match.Value)or 1)or nil,Stats=values}
            end
        end
        return snapshot
    end
    local gear=ctx.MakeGear({
        Active=gearActive,SkipWeapons=function()return state.AutoEquipBestSword==false end,WeaponsOnly=function()return false end,
        Rarity=require(rs.Shared.Library.RarityData),Read=gearSnapshot,
        Busy=function()return state.AutoTradeBusy or state.SafeModePanic or state.TravelBusy or state.AutomationTeleporting
            or state.Dodging or state.Recovering or state.SkillCastRunning or state.MiscCastRunning or ctx.SkillsBusy()end,
        Equip=function(operation)
            if not gearActive()or operation.Item.Native.Parent~=inventory then return false,"Equipment changed"end
            ctx.StopCombat("Equipping best usable weapon / gear")
            local payload={operation.Action,operation.Item.Native}
            if operation.Action=="EquipWeapon"then payload[3]=operation.Slot end
            if rs.Function:InvokeServer("Equipment",payload)==false then return false,"Equipment request was rejected"end
            return true
        end,
        Status=function(message)state.ProgressionGearStatus=message;text(ui.ProgressionGear,message)end})
    state.ProgressionGearController=gear
    function state.IsAutoEquipmentCandidate(item)
        if not gearActive()then return false end
        for _,operation in ipairs(gear.Plan(gearSnapshot()))do
            if operation.Action~="Unequip"and operation.Item.Native==item then return true end
        end
        return false
    end
    local function invalidate()if not closed then gear.Invalidate()end end
    local function watch(value)
        if not watched[value]then watched[value]=value.Changed:Connect(invalidate)end
    end
    local function forget(value)
        local connection=watched[value];watched[value]=nil
        if connection then connection:Disconnect()end
    end
    ctx.Bind(inventory.DescendantAdded,function(value)
        invalidate();if value.Name=="Upgrade"and value:IsA("ValueBase")then watch(value)end
    end)
    ctx.Bind(inventory.DescendantRemoving,function(value)forget(value);invalidate()end)
    ctx.Bind(equip.DescendantAdded,function(value)invalidate();if value:IsA("ValueBase")then watch(value)end end)
    ctx.Bind(equip.DescendantRemoving,function(value)forget(value);invalidate()end)
    for _,value in ipairs(inventory:QueryDescendants("#Upgrade"))do if value:IsA("ValueBase")then watch(value)end end
    for _,value in ipairs(equip:GetChildren())do if value:IsA("ValueBase")then watch(value)end end
    ctx.Bind(profile.Stats.Exp.Changed,invalidate)
    ctx.Bind(player:GetAttributeChangedSignal("HighestDamage"),invalidate)
    ctx.Bind(player:GetAttributeChangedSignal("HighestDefense"),invalidate)
    local function cancelEquipment()
        if equipmentWorker then pcall(task.cancel,equipmentWorker);equipmentWorker=nil end
        state.ProgressionEquipping=false
    end
    local function equipment(now)
        if equipmentWorker or gear.Paused or not gear.HasWork()then return end
        local thread=task.spawn(function()
            state.ProgressionEquipping=true
            local ok,reason=pcall(gear.Update,now)
            state.ProgressionEquipping=false;equipmentWorker=nil
            if not ok then gear.Paused=true;gear.Error=tostring(reason);text(ui.ProgressionGear,gear.Error)end
        end)
        if coroutine.status(thread)=="dead"then return end
        equipmentWorker=thread
        task.delay(8,function()
            if closed or equipmentWorker~=thread then return end
            cancelEquipment();gear.Paused=true
            gear.Error="Equipment request timed out · toggle Auto Farm or progression OFF/ON to retry"
            text(ui.ProgressionGear,gear.Error)
        end)
    end
    local swordActive=false
    function state.UpdateBestSword(now)
        local active=not state.AccountProgression and state.AutoEquipBestSword
        if swordActive~=active then swordActive=active;gear.Reset()end
        if active then equipment(now)end
    end
    local function root()
        return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    end
    local function release()
        clearBoss();state.ProgressionAnchor=nil
        if state.ProgressionTravelOwned and state.TravelBusy then state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false end
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
                state.SafeFloorId=game.PlaceId;state.SaveNow()
                if state.RefreshAutomationUI then state.RefreshAutomationUI()end
                return
            end
        end
    end
    local function bossSpot(floor,index)
        local catalog=state.AutomationCatalog
        catalog.AddCurrent(state.FloorDestinations,game.PlaceId)
        local primary=catalog.SpotById and catalog.SpotById[tostring(floor.Id).."/Boss"]
        if primary then return primary end
        local scouts={}
        for _,spot in ipairs(catalog.Spots)do
            if spot.PlaceId==floor.Id and spot.MainBoss then return spot end
        end
        for _,spot in ipairs(catalog.Spots)do
            if spot.PlaceId==floor.Id then
                if spot.Kind=="Boss"then return spot end
                if floor.Number==12 and spot.Kind=="Arena"then scouts[#scouts+1]=spot end
            end
        end
        table.sort(scouts,function(a,b)return a.Id<b.Id end)
        local spot=scouts[(index-1)%math.max(1,#scouts)+1]
        if spot then return {Id=spot.Id,PlaceId=spot.PlaceId,Name=spot.Name,Kind=spot.Kind,
            DestinationId=spot.DestinationId,Position=spot.Position,Scout=true}end
    end
    local function readBoss(spot)
        if observation and not matches(spot,observation.mob)then clearBoss()end
        local record=observation
        if record then
            credit(record)
            if record.dead or record.health.Value<=0 and (not record.lives or record.lives.Value<=0)then
                record.diedAt=record.diedAt or os.clock()
                if record.high>record.baseline or os.clock()-record.diedAt<1 or record.mob.Parent then
                    return {Defeated=true,Credited=record.high>record.baseline,Name=record.mob.Name}
                end
                clearBoss();return
            end
            if record.mob.Parent and record.health.Parent then return {Alive=true,Name=record.mob.Name}end
            clearBoss()
        end
        for mob in pairs(ctx.Mobs())do
            if mob.Parent and ctx.Rank(mob)==1 and not(ctx.IsChest and ctx.IsChest(mob))and matches(spot,mob)then
                local data=ctx.Data(mob)
                if data and data.Health.Value>0 and (data.Root.Position-spot.Position).Magnitude<=220 then
                    observe(mob,data);return {Alive=true,Name=mob.Name}
                end
            end
        end
    end
    local controller=ctx.MakeController({State=state,SyncFloor=syncFloor,
        Floor=function(number)for _,floor in ipairs(state.AutomationCatalog.Floors)do if floor.Number==number then return floor end end end,
        Unlocked=function(floor)return state.IsAutomationFloorUnlocked(floor.Id)end,CurrentFloor=function()return game.PlaceId end,
        Ready=function()
            local r=root();local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            return not state.AutoTradeBusy and r and not r.Anchored and humanoid and humanoid.Health>0
                and not(state.SafeModePanic or state.AutomationTeleporting or state.Dodging or state.Recovering or state.ProgressionEquipping)
                and not(state.SafeController and state.SafeController.Seeking)and (not state.TravelBusy or state.ProgressionTravelOwned)
        end,
        CombatReady=function()return state.Enabled and state.AutoFarm end,
        ChestTarget=function(now)
            if state.TravelBusy or state.ProgressionTravelOwned or not state.GetFarmChestTarget then return end
            local focus=state.GetFarmChestTarget(now)
            return focus and ctx.IsChest and ctx.IsChest(focus)and focus or nil
        end,
        NearBossSpot=function(spot)
            local r=root();if not r then return false end
            if (r.Position-spot.Position).Magnitude<=350 then return true end
            local data=observation and observation.mob.Parent and ctx.Data(observation.mob)
            return data and (r.Position-data.Root.Position).Magnitude<=500 or false
        end,
        ChangeFloor=function(floor)return state.ChangeAutomationFloor(floor.Id)end,BossSpot=bossSpot,
        Go=function(spot)
            if state.TravelBusy then return false,"Another movement is active"end
            clearBoss();ctx.StopCombat("Moving to the progression boss")
            state.RegisterAutomationDestination(spot);state.ProgressionAnchor=spot.Position;state.ProgressionTravelOwned=true
            return state.TeleportToDestination(spot.DestinationId,false,false)
        end,
        Moving=function()return state.TravelBusy end,
        Arrived=function(spot)
            local r=root()
            return spot and r and state.LastTravelPosition and state.LastTravelDestination==spot.DestinationId
                and (r.Position-state.LastTravelPosition).Magnitude<=25
        end,
        Arrival=function()state.ProgressionTravelOwned=false;state.TravelHold=false;state.TravelHoldPosition=nil end,
        Boss=readBoss,Equipment=equipment,Complete=complete,Release=release,Save=state.SaveNow,
        Status=function(message)state.ProgressionStatus=message;text(ui.ProgressionStatus,message)end})
    state.ProgressionController=controller
    function state.ResetSavedProgression()
        if closed or not state.Running then return false end
        state.ProgressionFloor=1;state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
        state.ProgressionComplete=false
        if state.AccountProgression then
            cancelEquipment();gear.Reset();controller.Reset()
            if not state.StopEverything then
                state.SetAutoFarm(true,"Progression checkpoint reset");state.SetEnabled(true)
            end
        else
            state.ProgressionPhase="Idle";state.ProgressionStatus="Saved progression reset · Floor 1"
            text(ui.ProgressionStatus,state.ProgressionStatus)
        end
        state.SaveNow()
        return true
    end
    function state.SetAccountProgression(on,restoring)
        if on and state.StopEverything then return false end
        cancelEquipment();gear.Reset()
        if on then
            for _,floor in ipairs(state.AutomationCatalog.Floors)do
                if floor.Number==state.ProgressionFloor then
                    local catalog=state.AutomationCatalog
                    local primary=catalog.SpotById and catalog.SpotById[tostring(floor.Id).."/Boss"]
                    if state.ProgressionBossCleared and primary and primary.EncounterNames
                        and not matches(primary,{Name=state.ProgressionBossClearedName or ""})then
                        state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
                    end
                    break
                end
            end
            state.ProgressionRestore=state.ProgressionRestore or {Enabled=state.Enabled,AutoFarm=state.AutoFarm,
                AutoSwing=state.AutoSwing,SafeFloorId=state.SafeFloorId}
            if state.ProgressionRestore.SafeFloorId==nil then state.ProgressionRestore.SafeFloorId=state.SafeFloorId end
            if state.ProgressionComplete and not restoring then
                state.ProgressionFloor=1;state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil;state.ProgressionComplete=false
            end
        end
        state.AccountProgression=on==true
        if state.AccountProgression then syncFloor()
        elseif state.ProgressionRestore and state.ProgressionRestore.SafeFloorId then
            state.SafeFloorId=state.SharedSafeFloorId or state.ProgressionRestore.SafeFloorId
        end
        if state.MultiSpotController then state.MultiSpotController.Reset()end
        if not restoring and state.SafeController then state.SafeController.Reset()end
        controller.Reset()
        if state.AccountProgression then
            if state.ProgressionComplete then complete()else state.SetAutoFarm(true,"Account progression");state.SetEnabled(true)end
        elseif state.ProgressionRestore then
            local saved=state.ProgressionRestore;state.ProgressionRestore=nil
            state.SetAutoFarm(saved.AutoFarm==true,"Account progression stopped");state.SetEnabled(saved.Enabled==true)
            if type(saved.AutoSwing)=="boolean"and state.SetAutoSwing then state.SetAutoSwing(saved.AutoSwing)end
        end
        ui.ProgressionToggle.Text=state.AccountProgression and "Account Progression · ON"or "Account Progression · OFF"
        ui.ProgressionToggle.BackgroundColor3=state.AccountProgression and Color3.fromRGB(91,72,164)or Color3.fromRGB(38,41,56)
        state.SaveNow();if state.RefreshAutomationUI then state.RefreshAutomationUI()end
        return true
    end
    ctx.Bind(ui.ProgressionToggle.Activated,function()state.SetAccountProgression(not state.AccountProgression)end)
    function state.ProgressionDestroy()
        closed=true
        for value in pairs(watched)do forget(value)end
        cancelEquipment();controller.Destroy()
    end
    if state.AccountProgression then state.SetAccountProgression(true,true)end
    return controller
end
