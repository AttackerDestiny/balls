-- Native utility adapters expose controller actions directly to modern WindUI.
do
    local make=(function()
-- BEGIN BUNDLED RESTART SCRIPT
-- END BUNDLED RESTART SCRIPT
    end)()
    state.RestartScript=make({Spawn=task.spawn,Save=state.SaveNow,
        Fetch=function()return game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau")end,
        Compile=function(source)return assert(loadstring(source,"Feather restart loader"))end,
        Destroy=function()state.Destroy(true)end,
        Status=function(message)state.RestartStatus=message end,
        Error=function(reason)state.LastRestartError=reason;warn("[SB2 Restart] "..reason)end})
end

local function installRewardWebhook()
    local make=(function()
-- BEGIN BUNDLED REWARD WEBHOOK
-- END BUNDLED REWARD WEBHOOK
    end)()
    local path=configFolder.."/reward-webhook.json"
    local saved
    if filePersistence then
        local ok,result=pcall(function()
            if not isfile(path)then return end
            local bytes=readfile(path)
            if #bytes>4096 then return end
            local data=HttpService:JSONDecode(bytes)
            if type(data)=="table"and data.Version==1 then return data end
        end)
        if ok then saved=result end
    end
    local post=request or http_request or (syn and syn.request)or (http and http.request)
    local webhook=make({Saved=saved,PlayerName=player.Name,Alive=function()return state.Running end,
        Paused=function()return state.StopEverything end,Schedule=task.delay,Sleep=task.wait,
        Decode=function(bytes)return HttpService:JSONDecode(bytes)end,
        Save=function(settings)
            if not filePersistence then return false end
            writefile(path,HttpService:JSONEncode(settings));return true
        end,
        Send=type(post)=="function"and function(url,payload)
            return post({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)})
        end or nil})
    local inventory=ReplicatedStorage.Profiles[player.Name].Inventory
    local definitions=ReplicatedStorage.Database.Items
    local rarityCache={}
    local listeners,counts,unstacked={},{},{}
    local revision=0
    local function stopWatching()
        revision+=1
        for _,connection in ipairs(listeners)do connection:Disconnect()end
        for _,connection in pairs(counts)do connection:Disconnect()end
        table.clear(listeners);table.clear(counts);table.clear(unstacked)
    end
    local function itemRarity(item)
        if item.Parent~=inventory or not item:IsA("IntValue")then return nil end
        local name=item.Name
        if rarityCache[name]==nil then
            local definition=definitions:FindFirstChild(name)
            local rarity=definition and definition:FindFirstChild("Rarity")
            if rarity then rarityCache[name]=rarity.Value end
        end
        local rarity=rarityCache[name]
        if rarity and webhook.Watches(rarity)then return rarity end
    end
    local function watchCount(item,count,rarity)
        if not count or not count:IsA("ValueBase")or type(count.Value)~="number"then return nil end
        if not counts[count]then
            local last=count.Value
            counts[count]=count:GetPropertyChangedSignal("Value"):Connect(function()
                local value=count.Value;local increase=value-last;last=value
                if item.Parent==inventory and count.Parent==item then webhook.Add(item.Name,rarity,increase)end
            end)
        end
        return count.Value
    end
    local function refresh()
        state.WebhookEnabled=webhook.Enabled
        state.WebhookHidePlayer=webhook.HidePlayer
        stopWatching()
        if not webhook.Enabled then return end
        listeners[1]=inventory.ChildAdded:Connect(function(item)
            local rarity=itemRarity(item)
            if not rarity then return end
            local amount=watchCount(item,item:FindFirstChild("Count"),rarity)
            if amount==nil then unstacked[item]=true end
            webhook.Add(item.Name,rarity,amount or 1)
        end)
        listeners[2]=inventory.DescendantAdded:Connect(function(count)
            if count.Name~="Count"then return end
            local item=count.Parent
            local rarity=item and itemRarity(item)
            if not rarity then return end
            local amount=watchCount(item,count,rarity)
            if amount and unstacked[item]then unstacked[item]=nil;webhook.Add(item.Name,rarity,amount-1)end
        end)
        listeners[3]=inventory.DescendantRemoving:Connect(function(object)
            if counts[object]then counts[object]:Disconnect();counts[object]=nil end
            unstacked[object]=nil
        end)
        local stamp=revision
        task.defer(function()
            for index,item in ipairs(inventory:GetChildren())do
                if stamp~=revision or not state.Running then return end
                local count=item:FindFirstChild("Count")
                local rarity=count and itemRarity(item)
                if rarity then watchCount(item,count,rarity)end
                if index%40==0 then task.wait()end
            end
        end)
    end
    state.WebhookController={Destroy=stopWatching}
    state.GetWebhookRarities=function()return webhook.RarityChoices,webhook.Rarities end
    state.GetWebhookStatus=function()return webhook.Status end
    function state.SetWebhookUrl(text)if webhook.SetUrl(text)then refresh()end end
    function state.ClearWebhookUrl()webhook.Clear();refresh()end
    function state.SetWebhookEnabled(value)webhook.SetEnabled(value);refresh()end
    function state.SetWebhookRarities(values)webhook.SetRarities(values);refresh()end
    function state.SetWebhookHidePlayer(value)webhook.SetHidePlayer(value);state.WebhookHidePlayer=webhook.HidePlayer end
    state.TestWebhook=webhook.Test
    refresh()
end
installRewardWebhook()

do
    local make=(function()
-- BEGIN BUNDLED AUTO DISMANTLE
-- END BUNDLED AUTO DISMANTLE
    end)()
    local profile=ReplicatedStorage.Profiles[player.Name]
    local nativeRestrictions=require(ReplicatedStorage.Shared.Util.ItemRestrictions)
    local inventory,equip,definitions=profile.Inventory,profile.Equip,ReplicatedStorage.Database.Items
    local selectable={Common=true,Uncommon=true,Rare=true}
    local function rarity(item)
        if item.Parent~=inventory or not item:IsA("IntValue")then return nil end
        local definition=definitions:FindFirstChild(item.Name)
        local value=definition and definition:FindFirstChild("Rarity")
        return value and value.Value
    end
    local function protected(item)
        if item.Parent~=inventory or nativeRestrictions.CanOfferDismantle(profile,item)~=true then return true end
        if item.Name:find("Novice",1,true)or item.Name:find("Aura",1,true)then return true end
        for _,slot in ipairs(equip:GetChildren())do if slot:IsA("IntValue")and slot.Value==item.Value then return true end end
        local function protectedFlag(object)
            for _,name in ipairs({"Locked","Lock","Favorite","Favorited","Favourite","Favourited","Skin"})do
                local value=object:GetAttribute(name)
                if value~=nil and value~=false and value~=0 and value~=""then return true end
                local flag=object:FindFirstChild(name)
                if flag and (not flag:IsA("ValueBase")or flag.Value~=false and flag.Value~=0 and flag.Value~="")then return true end
            end
            return false
        end
        local definition=definitions:FindFirstChild(item.Name)
        return protectedFlag(item)or definition and protectedFlag(definition)or state.IsAutoEquipmentCandidate and state.IsAutoEquipmentCandidate(item)or false
    end
    local worker=make({Rarity=rarity,Protected=protected,Selected=function(name)return state.AutoDismantle[name]==true end,
        Active=function()return state.Running and not state.StopEverything and not state.ModeratorBlocking end,
        Busy=function()return state.AutoTradeBusy or state.ProgressionEquipping or state.TravelBusy or state.AutomationTeleporting or state.SafeModePanic end,
        Send=function(item)ReplicatedStorage.Event:FireServer("Equipment",{"Dismantle",{item}})end,
        Status=function(message)state.AutoDismantleStatus=message end})
    state.AutoDismantleController=worker
    function state.SetAutoDismantle(name,value)
        if not selectable[name]or state.StopEverything then return false end
        state.AutoDismantle[name]=value==true;requestSave()
        if value==true then worker.Scan(inventory:GetChildren(),os.clock())end
        return true
    end
    local function enabled()return state.AutoDismantle.Common or state.AutoDismantle.Uncommon or state.AutoDismantle.Rare end
    if enabled()then worker.Scan(inventory:GetChildren(),os.clock())end
    bind(inventory.ChildAdded,function(item)if state.Running and not state.StopEverything then worker.Add(item,os.clock())end end)
    bind(gui.Destroying,worker.Clear)
    task.spawn(function()
        while state.Running do
            local ok,reason=pcall(worker.Update,os.clock())
            if not ok then state.AutoDismantleStatus="Dismantle paused · "..tostring(reason)end
            task.wait(enabled()and .25 or 1)
        end
        worker.Clear()
    end)
end

do
    local make=(function()
-- BEGIN BUNDLED AUTO TRADE
-- END BUNDLED AUTO TRADE
    end)()
    local rs=ReplicatedStorage
    local profile=rs.Profiles[player.Name]
    local inventory,equip=profile.Inventory,profile.Equip
    local restrictions=require(rs.Shared.Util.ItemRestrictions)
    if state.TradeMode=="Tribute"then state.TradeMode="Legendary";requestSave()end
    function state.SetAutoTrade(value)
        if value and state.StopEverything then return false end
        state.AutoTrade=value==true;requestSave();return true
    end
    function state.SetTradeMode(value)
        if value~="Selected"and value~="Legendary"then return false end
        state.TradeMode=value;requestSave();return true
    end
    function state.SetTradeItems(values)
        local selected={}
        for name,on in pairs(values or {})do if type(name)=="string"and on==true then selected[name]=true end end
        state.TradeItems=selected;requestSave()
    end
    function state.GetTradeItemChoices()
        local quantities={}
        for _,item in ipairs(inventory:GetChildren())do
            local count=item:FindFirstChild("Count");quantities[item.Name]=(quantities[item.Name]or 0)+(count and count.Value or 1)
        end
        for name,on in pairs(state.TradeItems)do if on and quantities[name]==nil then quantities[name]=0 end end
        local rows={};for name,count in pairs(quantities)do rows[#rows+1]={Name=name,Count=count}end
        table.sort(rows,function(a,b)return a.Name<b.Name end)
        return rows
    end
    local worker
    local function plan()
        local offered={}
        for _,item in ipairs(inventory:GetChildren())do
            local definition=rs.Database.Items:FindFirstChild(item.Name)
            local rarity=definition and definition:FindFirstChild("Rarity")
            local selected=worker.AlwaysInclude(item.Name)
                or state.TradeMode=="Selected"and state.TradeItems[item.Name]
                or rarity and worker.IncludesRarity(state.TradeMode,rarity.Value)
            if selected and item:IsA("IntValue")and not item:GetAttribute("Locked")and not item:GetAttribute("Favorited")and restrictions.CanOfferTrading(profile,item)==true then
                local inUse=false
                for _,slot in ipairs(equip:GetChildren())do if slot:IsA("ValueBase")and slot.Value==item.Value then inUse=true;break end end
                if not inUse then offered[#offered+1]=item end
            end
        end
        table.sort(offered,function(a,b)return a.Value<b.Value end)
        local balance=profile.Stats:FindFirstChild("Vel")
        return offered,worker.MaxVel(balance and balance.Value or 0)
    end
    local nativeTrade=require(rs.CardinalClient.MainModule.Services.UI.Trade)
    local function requestOwner()
        local host=player:FindFirstChildOfClass("PlayerGui")
        for _,name in ipairs({"CardinalUI","PlayerUI","HUD","TradeRequest"})do host=host and host:FindFirstChild(name)end
        local label=host and host:FindFirstChild("PlayerText")
        if not host or not host.Visible or not label then return nil end
        local name=label.Text:match("^([%w_]+) wants to trade with you$")
        return name and Players:FindFirstChild(name)or nil
    end
    local function allowed(person)
        return typeof(person)=="Instance"and person:IsA("Player")and state.SafeWhitelistIds[tostring(person.UserId)]==true
    end
    worker=make({Player=player,Plan=plan,Pending=requestOwner,
        Count=function(item)local stack=item:FindFirstChild("Count");return stack and stack.Value or 1 end,
        Active=function()return state.AutoTrade and state.Running and not state.StopEverything and not state.ModeratorBlocking end,
        Allowed=allowed,Send=function(action,args)
            if action=="RequestAccept"then local person=requestOwner();if person and allowed(person)then nativeTrade.AcceptRequest()end
            else rs.Event:FireServer("Trade",action,args)end
        end,Status=function(message)state.TradeStatus=message end})
    state.AutoTradeController=worker
    bind(rs.Event.OnClientEvent,function(route,payload)
        if route~="UI"or type(payload)~="table"or payload[1]~="Trade"then return end
        worker.Event(payload[2],payload[3])
        if state.AutoTrade and (payload[2]=="TradeChanged"or payload[2]=="RequestAccept")then state.AutoTradeBusy=true end
        if payload[2]=="TradeCancel"or payload[2]=="TradeCompleted"then state.AutoTradeBusy=false end
    end)
    task.spawn(function()
        while state.Running do
            local ok,busy=pcall(worker.Update,os.clock())
            state.AutoTradeBusy=ok and busy==true
            if not ok then state.TradeStatus="Trade paused · "..tostring(busy)end
            task.wait(state.AutoTrade and .3 or 1)
        end
        state.AutoTradeBusy=false
    end)
end

do
    local make=(function()
-- BEGIN BUNDLED AUTO CRAFT
-- END BUNDLED AUTO CRAFT
    end)()
    local profile=ReplicatedStorage.Profiles[player.Name]
    local restrictions=require(ReplicatedStorage.Shared.Util.ItemRestrictions)
    local function count(input)
        local total=0
        for _,item in ipairs(profile.Inventory:GetChildren())do
            if item.Name==input and item:IsA("IntValue")and restrictions.CanOfferCrafting(profile,item)==true then
                local stack=item:FindFirstChild("Count");total+=stack and math.max(0,stack.Value)or 1
            end
        end
        return total
    end
    local function recipe(output,input)
        local definition=ReplicatedStorage.Database.Items:FindFirstChild(output)
        local requirements=definition and definition:FindFirstChild("Recipe")
        if not requirements then return nil end
        local amount
        for _,requirement in ipairs(requirements:GetChildren())do
            if requirement.Name~=input or not requirement:IsA("ValueBase")then return nil end
            amount=requirement.Value
        end
        return amount
    end
    local worker=make({Active=function()return state.Running end,
        Busy=function()return state.StopEverything or state.ModeratorBlocking or state.SafeModePanic or state.AutoTradeBusy or state.TravelBusy or state.AutomationTeleporting end,
        Selected=function(name)return state.AutoCraft[name]==true end,Count=count,Recipe=recipe,
        Send=function(output)ReplicatedStorage.Event:FireServer("Item",{"Craft",output})end,
        Status=function(message)state.AutoCraftStatus=message end})
    state.AutoCraftController=worker
    function state.SetAutoCraft(values)
        local selected={}
        for _,output in ipairs({"Rare Upgrade Crystal","Legendary Upgrade Crystal"})do if values and values[output]==true then selected[output]=true end end
        state.AutoCraft=selected;worker.Reset();requestSave()
    end
    task.spawn(function()
        while state.Running do
            local ok,reason=pcall(worker.Update,os.clock())
            if not ok then state.AutoCraftStatus=tostring(reason)end
            task.wait(.25)
        end
    end)
end

do
    local function exportSpots()
        local floors={}
        local function readSpots(floor,path)
            local bytes=readfile(path);assert(#bytes<=32768,"Custom spots file too large")
            local saved=HttpService:JSONDecode(bytes)
            assert(saved.Version==1 and type(saved.Areas)=="table","Invalid custom spots file")
            floors[floor]=saved.Areas
        end
        if presetBook.ActiveId then
            loadCustomSpots()
            if type(listfiles)~="function"then
                floors=table.clone(presetBook.Load(presetBook.ActiveId).CustomSpots)
                for floor in pairs(floors)do
                    local path=configFolder.."/"..customSpotPrefix..floor..".json"
                    if isfile(path)then readSpots(floor,path)end
                end
            end
        end
        if filePersistence and type(listfiles)=="function"then
            for _,path in ipairs(listfiles(configFolder))do
                local name=path:match("[^/\\]+$")
                local floor=name and name:sub(1,#customSpotPrefix)==customSpotPrefix
                    and name:sub(#customSpotPrefix+1):match("^(%d+)%.json$")
                if floor then readSpots(floor,path)end
            end
        end
        local current={}
        for id,area in pairs(destinations)do if id:sub(1,16)=="saved:multispot:"then
            local point=area.Position;current[#current+1]={Id=id,Name=area.Name,Position={point.X,point.Y,point.Z}}
        end end
        floors[tostring(game.PlaceId)]=current
        return floors
    end
    local function loadPreset(id)
        if (state.PresetId or 0)==id then return end
        if id>0 then presetBook.Load(id)end
        local launch=assert(loadstring(embeddedSource,"Feather preset"))
        env.SB2ManualPreset={UserId=player.UserId,Id=id}
        state.Destroy(true);launch(embeddedSource)
    end
    local transfer=presetBook.MakeTransfer({Settings=settingsPayload,Spots=exportSpots,Presets=presetBook.ExportLibrary,Apply=presetBook.Import,
        Encode=function(value)return HttpService:JSONEncode(value)end,
        Decode=function(bytes)return HttpService:JSONDecode(bytes)end,Copy=setclipboard or toclipboard})
    state.ExportConfig=transfer.Export
    function state.ImportConfig(bytes)
        local id=transfer.Import(bytes)
        state.AutoPreset=presetBook.Preferences.Auto
        return id
    end
    state.PresetStatus=presetBook.Error
    function state.RefreshPresetPreferences()
        state.AutoPreset=presetBook.Refresh().Auto
    end
    function state.LoadPreset(id)
        presetBook.Set("Manual",id)
        loadPreset(presetBook.Preferences.Manual)
    end
    function state.SetAutoPreset(value)
        presetBook.Set("Auto",value)
        state.AutoPreset=presetBook.Preferences.Auto
        if state.AutoPreset then loadPreset(presetBook.Resolve())end
    end
    function state.SetPresetRoute(key,id)
        presetBook.Set(key,id)
        state.AutoPreset=presetBook.Preferences.Auto
        if state.AutoPreset then loadPreset(presetBook.Resolve())end
    end
end

-- Native floor utilities share the scheduler but retain independent receipts.
local function livingPlayer(person)
    local character=person.Character
    if not character then return false end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    local entity=character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    return humanoid~=nil and humanoid.Health>0 and(not health or health.Value>0)
end
do
    local create=(function()
-- BEGIN BUNDLED ATHEON UNLOCK
-- END BUNDLED ATHEON UNLOCK
    end)()
    local function portalPoint(portal)
        local handlers={BasePart=function(object)return object.Position end,Model=function(object)return object:GetPivot().Position end,
            Attachment=function(object)return object.WorldPosition end}
        for class,resolve in pairs(handlers)do if portal:IsA(class)then return resolve(portal)end end
        local candidates=portal:QueryDescendants("BasePart")
        for _,part in ipairs(candidates)do if part:FindFirstChildOfClass("TouchTransmitter")then return part.Position end end
        return candidates[1]and candidates[1].Position
    end
    local function busy()
        for _,flag in ipairs({"StopEverything","ModeratorBlocking","SafeModePanic","AutoTradeBusy","AutomationTeleporting",
            "TravelBusy","AutoJoinFriendHolding","Dodging","Recovering"})do if state[flag]then return true end end
        return false
    end
    local controller=create({State=state,Busy=busy,Find=function()return workspace:FindFirstChild("AtheonPortal")end,
        Unlocked=function()return game.PlaceId==13965775911 or(state.IsAutomationFloorUnlocked and state.IsAutomationFloorUnlocked(13965775911))==true end,
        Root=function()
            if not livingPlayer(player)then return nil end
            local root=player.Character:FindFirstChild("HumanoidRootPart")
            return root and not root.Anchored and root or nil
        end,Position=portalPoint,Arrived=function(root,point)return root.Parent~=nil and(root.Position-point).Magnitude<=12 end,
        Move=function(root,point,at)
            if state.CancelSkillAura then state.CancelSkillAura("Atheon portal teleport")end
            stopSword(true);finishAttackBurst("Atheon portal teleport");stopMovement("Atheon portal teleport",true)
            state.FollowTarget=nil;state.FarmTargetLock=nil;state.FarmPauseUntil=at+2;state.AtheonUnlockPauseUntil=at+2
            pivotRoot(root,point)
        end})
    state.AtheonUnlockController=controller
    function state.SetAtheonUnlock(requested)
        state.AtheonUnlock=requested==true;controller.Reset()
        state.AtheonUnlockStatus=state.AtheonUnlock and "Waiting for AtheonPortal"or "Atheon Unlock is off"
        workScheduler.Wake("AtheonUnlock");requestSave()
    end
    taskController("AtheonUnlock",.5,controller.Update)
    table.insert(frameOrder,1,"AtheonUnlock")
end
local function installBetweenAutomation()
    local create=(function()
-- BEGIN BUNDLED BETWEEN ROOM
-- END BUNDLED BETWEEN ROOM
    end)()
    local destination=78945654064532
    local localFloor=game.PlaceId==destination
    local native=localFloor and require(services.UI.WaveDefense.Revive)
    local function prompt()return native and native.Frame and native.Frame.Visible end
    local function partyDefeated()
        for _,person in ipairs(Players:GetPlayers())do
            local lives=person:GetAttribute("Lives")
            if livingPlayer(person)or type(lives)~="number"or lives>0 then return false end
        end
        return true
    end
    local retry
    local function isChest(name)return name:lower():find("%f[%a]chest%f[%A]")~=nil end
    if localFloor then
        local makeRetry=(function()
-- BEGIN BUNDLED BETWEEN RETRY
-- END BUNDLED BETWEEN RETRY
        end)()
        retry=makeRetry({
            Wave=function()return workspace:GetAttribute("Wave"),workspace:GetAttribute("MobsLeft")end,
            PartyDefeated=partyDefeated,
            IsChest=isChest,
            Chests=function()
                local chests,enemies={},0
                local folder=refreshMobIndex()
                if not folder then return chests,1 end
                for mob in pairs(trackedMobs)do
                    local data=getMobData(mob)
                    if isChest(mob.Name) then
                        if data then chests[mob]=data.Health else enemies+=1 end
                    elseif not data or data.Health.Value>0 then enemies+=1 end
                end
                return chests,enemies
            end,
        })
    end
    if localFloor then
        local receipt,busy
        taskController("BetweenRevive",.35,function()
            if livingPlayer(player)then receipt=nil;return end
            local lives=player:GetAttribute("Lives")
            if busy or not prompt()or type(lives)~="number"or lives<=0 or receipt==lives then return end
            receipt=lives;busy=true
            task.spawn(function()
                local permitted=state.Running and not state.StopEverything and prompt()
                    and player:GetAttribute("Lives")==lives and not livingPlayer(player)
                if permitted then
                    local ok,accepted=pcall(ReplicatedStorage.Function.InvokeServer,ReplicatedStorage.Function,
                        "UniqueFloorTypes",{"WaveDefense","Revive"})
                    if ok and accepted and native.Hide then native.Hide()end
                end
                busy=false
            end)
        end)
        frameOrder[#frameOrder+1]="BetweenRevive"
    end
    local allowedAccess={Private=true,Friends=true,["Game Party"]=true}
    local allowedDifficulty={Normal=true,Hard=true,Elite=true}
    if not allowedAccess[state.BetweenAccess]then state.BetweenAccess="Private"end
    if not allowedDifficulty[state.BetweenDifficulty]then state.BetweenDifficulty="Normal"end
    local function minute(value)
        return type(value)=="number" and value==value and math.clamp(math.round(value),0,100) or 0
    end
    local pace={}
    for mode in pairs(allowedDifficulty)do
        local value=type(state.BetweenPace)=="table" and state.BetweenPace[mode]
        local minimum=minute(type(value)=="table" and value.Min or value)
        local maximum=type(value)=="table" and minute(value.Max)
            or math.min(100,minimum+(minimum>0 and 1 or 0))
        pace[mode]={Min=minimum,Max=math.max(minimum,maximum)}
    end
    state.BetweenPace=pace
    function state.SetBetweenPace(mode,minimum,maximum)
        if not allowedDifficulty[mode] then return end
        minimum,maximum=minute(minimum),minute(maximum)
        pace[mode]={Min=minimum,Max=math.max(minimum,maximum)}
        requestSave()
    end
    if localFloor then
        local makePace=(function()
-- BEGIN BUNDLED BETWEEN PACE
-- END BUNDLED BETWEEN PACE
        end)()
        local getPace=makePace(game.JobId)
        taskController("BetweenPace",.2,function()
            local mode=workspace:GetAttribute("WaveDefenseMode")
            local wave=workspace:GetAttribute("Wave")
            local progress=workspace:GetAttribute("WaveProgressLeft")
            local mobs=workspace:GetAttribute("MobsLeft")
            local note=tostring(workspace:GetAttribute("CountdownNote") or ""):lower()
            local environment=workspace:GetAttribute("WaveDefenseEnvironment")
            local finalHealth
            if wave==100 and mobs==1 and state.FollowTarget then
                local data=getMobData(state.FollowTarget)
                if data then
                    local maximum=data.Health:GetAttribute("MaxValue") or data.Entity:GetAttribute("MaxHealth")
                    local value=data.Entity:FindFirstChild("MaxHealth")
                    maximum=tonumber(maximum or (value and value.Value))
                    if maximum and maximum>0 then finalHealth=data.Health.Value/maximum end
                end
            end
            local hold,goal,elapsed,release=getPace(pace[mode],wave,workspace:GetAttribute("WDRunTime"),
                progress or mobs,environment=="Blackout" or environment=="Darkness" or note:find("survive",1,true)~=nil,finalHealth)
            if hold and not state.BetweenPaceHolding then
                finishAttackBurst("Between completion pace")
                state.CancelSkillAura("Between completion pace")
            end
            state.BetweenPaceHolding=hold
            state.BetweenPaceStatus=goal and string.format("Goal %d:%02d · %s",math.floor(goal/60),goal%60,
                hold and ("waiting "..math.ceil(release-elapsed).."s") or "combat ready") or "Completion pacing is off"
        end)
        table.insert(frameOrder,1,"BetweenPace")
    end
    local function normalizeAlts(value)
        local names,seen={},{}
        for name in value:gmatch("[^,%s;.]+")do
            name=name:gsub("^@","")
            local key=name:lower()
            if name~="" and not seen[key] then
                seen[key]=true;names[#names+1]=name
            end
        end
        return table.concat(names,", ")
    end
    local rooms={}
    if type(state.BetweenRooms)=="table" then
        for i,entry in ipairs(state.BetweenRooms)do
            if i>20 then break end
            if type(entry)=="table" then
                rooms[#rooms+1]={
                    Host=type(entry.Host)=="string" and entry.Host:sub(1,64) or "",
                    Alt=type(entry.Alt)=="string" and normalizeAlts(entry.Alt:sub(1,256)) or "",
                    Mode=allowedAccess[entry.Mode] and entry.Mode or state.BetweenAccess,
                    Difficulty=allowedDifficulty[entry.Difficulty] and entry.Difficulty or state.BetweenDifficulty,
                    Start=entry.Start==true,
                    AutoRetry=entry.AutoRetry==true,
                }
            end
        end
    end
    state.BetweenRooms=rooms
    local function matches(person,name)
        return person.Name:lower()==name:lower() or tostring(person.UserId)==name
    end
    local function hostName(entry)
        return entry.Host:match("^%s*@?([%w_]+)%s*$")
    end
    function state.IsBetweenRoomHost(index)
        local entry=rooms[index]
        local name=entry and hostName(entry)
        return name~=nil and matches(player,name)
    end
    local function findPlayer(name)
        for _,person in ipairs(Players:GetPlayers())do
            if matches(person,name) then return person end
        end
    end
    local assignment
    local function updateAssignment()
        assignment=nil
        state.AutoCreateBetween=false
        for _,entry in ipairs(rooms)do
            if not entry.Start then continue end
            local host=hostName(entry)
            local alts,seen={},{}
            local isAlt,invalid=false,false
            for token in entry.Alt:gmatch("[^,%s;]+")do
                local name=token:gsub("^@","")
                local key=name:lower()
                if not name:match("^[%w_]+$") or #name>20 then invalid=true
                elseif not seen[key] then
                    seen[key]=true
                    alts[#alts+1]=name
                    if matches(player,name) then isAlt=true end
                end
            end
            local isHost=host and matches(player,host)
            if isHost or isAlt then
                if assignment or (isHost and isAlt) then
                    assignment={Role="Invalid",Message="This account has conflicting room assignments"}
                    break
                end
                if invalid or not host or #host>20 or #alts>7 then
                    assignment={Role="Invalid",Message="Enter one Host and up to seven Alt usernames or user IDs"}
                else
                    assignment={Role=isHost and "Host" or "Alt",Host=host,Alts=alts,Room=entry}
                end
            end
        end
        assignment=assignment or {Role="Unassigned"}
        state.AutoCreateBetween=assignment.Room~=nil
        state.ObserveBetweenReward=retry and assignment.Role=="Host" and assignment.Room.AutoRetry and retry.Observe or nil
    end
    updateAssignment()
    local index
    local function roomSnapshot(person)
        local id=(person or player):GetAttribute("PartyID")
        if not id then return nil end
        local parties=ReplicatedStorage:FindFirstChild("LobbyParties")
        local party=parties and parties:FindFirstChild(tostring(id))
        -- A finished run can leave PartyID set after the native party has gone.
        if localFloor and not party then return nil end
        local view={Id=tostring(id),Instance=party}
        if party then for _,field in ipairs({"Host","PlaceId","Status","Mode"})do view[field]=party:GetAttribute(field)end end
        return view
    end
    local function nativeRoomMember(room,id)
        if room.Instance and room.Instance:GetAttribute(id)~=nil then return true end
        if localFloor and room.Instance and room.Instance:GetAttribute(tostring(room.Host))~=nil then return false end
        return nil
    end
    local function missingRoomAlts(room,names)
        local missing={}
        if #names==0 then return missing end
        local roster={}
        for _,person in ipairs(Players:GetPlayers())do
            roster[person.Name:lower()]=person
            roster[tostring(person.UserId)]=person
        end
        for _,name in ipairs(names)do
            local alt=roster[name:lower()]
            local id=alt and tostring(alt.UserId) or name:match("^%d+$")
            -- The party roster and the player attribute can replicate independently.
            local member=id and nativeRoomMember(room,id)
            local joined=room.Instance and (member==true
                or (member==nil and alt and tostring(alt:GetAttribute("PartyID"))==room.Id))
            if not joined then missing[#missing+1]=name end
        end
        return missing
    end
    local function send(action,partyId)
        if action=="CreateParty"and index==nil then
            for ordinal,floor in ipairs(require(ReplicatedStorage.Database.Locations).floors)do
                if floor.PlaceId==destination then index=ordinal;break end
            end
            assert(index,"The Between is unavailable")
        end
        ReplicatedStorage.Event:FireServer("UniqueFloorTypes",{"Parties",action,action=="CreateParty"and index or partyId})
    end
    local function findHostRoom(name)
        local host=findPlayer(name)
        local found=host and roomSnapshot(host)
        if found and found.Host==host.UserId and found.PlaceId==destination then return found end
    end
    local altRetryReady=false
    local function queueRoom()if state.QueueAutomation then pcall(state.QueueAutomation)end end
    local controller=create({UserId=player.UserId,PlaceId=destination,Read=roomSnapshot,Send=send,Spawn=task.spawn,
        InBetween=localFloor,Now=os.clock,
        Active=function()
            if not state.Running or not state.AutoCreateBetween or state.StopEverything
                or state.AutomationTeleporting or state.ServerTeleportStarted then return false end
            if not localFloor then return true end
            if assignment.Role=="Alt" then
                altRetryReady=altRetryReady or partyDefeated()
                    or (workspace:GetAttribute("Wave")==100 and workspace:GetAttribute("MobsLeft")==0)
            end
            if state.SafeMode and state.SafeController and state.SafeController.Seeking then return false end
            if assignment.Role=="Alt" then return altRetryReady end
            return assignment.Room.AutoRetry and retry.Update(os.clock())~=nil
        end,
        Assignment=function()return assignment end,
        FindHostRoom=findHostRoom,
        HasJoined=function(room)return nativeRoomMember(room,tostring(player.UserId))~=false end,
        MissingAlts=missingRoomAlts,
        Selection=function()
            local room=assignment.Room
            if room then return room.Mode,room.Difficulty end
        end,
        Status=function(message)state.BetweenRoomStatus=message end,
        PrepareJoin=queueRoom,PrepareStart=queueRoom,
        Start=function()
            return ReplicatedStorage.Function:InvokeServer("UniqueFloorTypes",{"Parties","Start"})
        end})
    state.BetweenRoomController=controller
    function state.AddBetweenRoom()
        if #rooms>=20 then
            state.BetweenRoomStatus="Room setup limit reached"
            return
        end
        rooms[#rooms+1]={Host="",Alt="",Mode="Private",Difficulty="Normal",Start=false,AutoRetry=false}
        requestSave()
        return #rooms
    end
    function state.RemoveBetweenRoom(index)
        if not rooms[index]then return false end
        local previous=assignment.Room
        table.remove(rooms,index)
        updateAssignment()
        if assignment.Room~=previous then controller.Reset()end
        requestSave()
        return true
    end
    function state.SetBetweenRoomField(index,field,value)
        local entry=rooms[index]
        if not entry then return end
        if field=="Host" and type(value)=="string" then value=value:sub(1,64)
        elseif field=="Alt" and type(value)=="string" then
            value=normalizeAlts(value)
            if #value>256 then return entry.Alt end
        elseif field=="Mode" and allowedAccess[value] then
        elseif field=="Difficulty" and allowedDifficulty[value] then
        elseif field=="Start" and type(value)=="boolean" then
        elseif field=="AutoRetry" and type(value)=="boolean" and state.IsBetweenRoomHost(index) then
        else return end
        if entry[field]~=value then
            local previous=assignment.Room
            entry[field]=value
            updateAssignment()
            if previous==entry or assignment.Room~=previous then controller.Reset()end
            requestSave()
        end
        return value
    end
    taskController("BetweenRoom",.35,controller.Update);frameOrder[#frameOrder+1]="BetweenRoom"
end
installBetweenAutomation()
