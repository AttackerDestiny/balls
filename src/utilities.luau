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
    local make=(function()
-- BEGIN BUNDLED CONFIG TRANSFER
-- END BUNDLED CONFIG TRANSFER
    end)()
    local function exportSpots()
        local floors={}
        if filePersistence and type(listfiles)=="function"then
            for _,path in ipairs(listfiles(configFolder))do
                local floor=path:match("custom%-spots_(%d+)%.json$")
                if floor then
                    local bytes=readfile(path);assert(#bytes<=32768,"Custom spots file too large")
                    local saved=HttpService:JSONDecode(bytes)
                    assert(saved.Version==1 and type(saved.Areas)=="table","Invalid custom spots file")
                    floors[floor]=saved.Areas
                end
            end
        end
        local current={}
        for id,area in pairs(destinations)do if id:sub(1,16)=="saved:multispot:"then
            local point=area.Position;current[#current+1]={Id=id,Name=area.Name,Position={point.X,point.Y,point.Z}}
        end end
        floors[tostring(game.PlaceId)]=current
        return floors
    end
    local function importPackage(package)
        assert(filePersistence or next(package.CustomSpots)==nil,"Importing saved spots requires executor file access")
        local launch=assert(loadstring(embeddedSource,"Feather imported configuration"))
        env.SB2ConfigImport={UserId=player.UserId,Settings=package.Settings,CustomSpots=package.CustomSpots}
        state.AutoSaveSuspended=true;state.Destroy(true);launch(embeddedSource)
    end
    local transfer=make({Settings=settingsPayload,Spots=exportSpots,Apply=importPackage,
        Encode=function(value)return HttpService:JSONEncode(value)end,
        Decode=function(bytes)return HttpService:JSONDecode(bytes)end,Copy=setclipboard or toclipboard})
    state.ExportConfig=transfer.Export;state.ImportConfig=transfer.Import
end
