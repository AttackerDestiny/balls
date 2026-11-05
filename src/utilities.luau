-- Manual restart intentionally retires the same-build singleton before reloading.
do
    local make=(function()
-- BEGIN BUNDLED RESTART SCRIPT
-- END BUNDLED RESTART SCRIPT
    end)()
    local button=uiButton("RestartScript","restart script",390,34)
    state.UI.RestartScript=button
    state.RestartScript=make({Spawn=task.spawn,
        Save=state.SaveNow,
        Fetch=function()return game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau")end,
        Compile=function(source)return assert(loadstring(source,"SB2 restart loader"))end,
        Destroy=function()state.Destroy(true)end,
        Status=function(text)if button.Parent then button.Text=text end end,
        Error=function(reason)state.LastRestartError=reason;warn("[SB2 Restart] "..reason)end})
    bind(button.Activated,state.RestartScript)
end

-- Inventory and new-drop dismantling, separately opt-in for each rarity.
do
    local make=(function()
-- BEGIN BUNDLED AUTO DISMANTLE
-- END BUNDLED AUTO DISMANTLE
    end)()
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local profile=ReplicatedStorage.Profiles[player.Name]
    local nativeRestrictions=require(ReplicatedStorage.Shared.Util.ItemRestrictions)
    local inventory=profile.Inventory
    local equip=ReplicatedStorage.Profiles[player.Name].Equip
    local definitions=ReplicatedStorage.Database.Items
    local buttons={}
    local status=uiLabel("AutoDismantleStatus","Inventory + drops · equipped, locked and favorited items are kept",140,42)
    state.UI.AutoDismantleStatus=status
    status.Parent=state.UI.Pages.Utility
    local function rarity(item)
        if item.Parent~=inventory or not item:IsA("IntValue")then return nil end
        local definition=definitions:FindFirstChild(item.Name)
        local value=definition and definition:FindFirstChild("Rarity")
        return value and value.Value
    end
    local function protected(item)
        if item.Parent~=inventory then return true end
        if nativeRestrictions.CanOfferDismantle(profile,item)~=true then return true end
        if item.Name:find("Novice",1,true)or item.Name:find("Aura",1,true)then return true end
        for _,slot in ipairs(equip:GetChildren())do
            if slot:IsA("IntValue")and slot.Value==item.Value then return true end
        end
        local function marked(object)
            for _,key in ipairs({"Locked","Lock","Favorite","Favorited","Favourite","Favourited","Skin"})do
                local attr=object:GetAttribute(key)
                if attr~=nil and attr~=false and attr~=0 and attr~=""then return true end
                local flag=object:FindFirstChild(key)
                if flag then
                    if not flag:IsA("ValueBase")then return true end
                    if flag.Value~=false and flag.Value~=0 and flag.Value~=""then return true end
                end
            end
            return false
        end
        local definition=definitions:FindFirstChild(item.Name)
        if marked(item)or (definition and marked(definition))then return true end
        if state.IsAutoEquipmentCandidate and state.IsAutoEquipmentCandidate(item)then return true end
        return false
    end
    local worker=make({Rarity=rarity,Protected=protected,
        Selected=function(name)return state.AutoDismantle[name]==true end,
        Active=function()return state.Running and not state.StopEverything and not state.ModeratorBlocking end,
        Busy=function()return state.AutoTradeBusy or state.ProgressionEquipping or state.TravelBusy or state.AutomationTeleporting or state.SafeModePanic end,
        Send=function(item)ReplicatedStorage.Event:FireServer("Equipment",{"Dismantle",{item}})end,
        Status=function(text)if status.Parent then status.Text=text end end})
    local dropdown=uiButton("AutoDismantleDropdown","Auto Dismantle  v",100,34,state.UI.Pages.Utility)
    local options=create("Frame",{Name="AutoDismantleOptions",Visible=false,LayoutOrder=105,Size=UDim2.new(1,0,0,114),BackgroundTransparency=1},state.UI.Pages.Utility)
    create("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},options)
    bind(dropdown.Activated,function()options.Visible=not options.Visible end)
    local renders={}
    function state.SetAutoDismantle(name,on)
        if not buttons[name]or state.StopEverything then return false end
        state.AutoDismantle[name]=on==true;renders[name]();requestSave()
        if state.AutoDismantle[name]then worker.Scan(inventory:GetChildren(),os.clock())end
        return true
    end
    for index,name in ipairs({"Common","Uncommon","Rare"})do
        local button=uiButton("AutoDismantle"..name,"",index,34,options)
        buttons[name]=button
        local function refresh()
            button.Text="Auto Dismantle "..name..(state.AutoDismantle[name]and " · ON"or " · OFF")
            button.BackgroundColor3=state.AutoDismantle[name]and Color3.fromRGB(91,72,164)or Color3.fromRGB(38,41,56)
        end
        renders[name]=refresh
        bind(button.Activated,function()state.SetAutoDismantle(name,not state.AutoDismantle[name])end)
        refresh()
    end
    if state.AutoDismantle.Common or state.AutoDismantle.Uncommon or state.AutoDismantle.Rare then
        worker.Scan(inventory:GetChildren(),os.clock())
    end
    bind(inventory.ChildAdded,function(item)
        if state.Running and not state.StopEverything then worker.Add(item,os.clock())end
    end)
    bind(gui.Destroying,worker.Clear)
    task.spawn(function()
        while state.Running do
            local ok,reason=pcall(worker.Update,os.clock())
            if not ok and status.Parent then status.Text="Dismantle paused · "..tostring(reason)end
            task.wait((state.AutoDismantle.Common or state.AutoDismantle.Uncommon or state.AutoDismantle.Rare)and .25 or 1)
        end
        worker.Clear()
    end)
end

-- Native trade automation. Final acceptance is built in and whitelist-gated.
do
    local make=(function()
-- BEGIN BUNDLED AUTO TRADE
-- END BUNDLED AUTO TRADE
    end)()
    local rs=game:GetService("ReplicatedStorage")
    local profile=rs.Profiles[player.Name]
    local inventory,equip=profile.Inventory,profile.Equip
    local restrictions=require(rs.Shared.Util.ItemRestrictions)
    local parent=state.UI.Pages.Utility
    local status=uiLabel("TradeStatus","Uses Safe Mode whitelist · final acceptance is automatic",250,48);status.Parent=parent
    state.UI.TradeStatus=status
    if state.TradeMode=="Tribute"then state.TradeMode="Legendary";requestSave()end
    local toggle=uiButton("AutoTrade","",200,34,parent)
    local mode=uiButton("TradeMode","",210,34,parent)
    local items=uiButton("TradeItems","Select inventory items  v",220,34,parent)
    local list=create("ScrollingFrame",{Name="TradeItemOptions",Visible=false,LayoutOrder=225,Size=UDim2.new(1,0,0,200),BackgroundTransparency=1,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},parent)
    create("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},list)
    local velInfo=uiLabel("TradeVelInfo","Vel: maximum affordable · includes 10% tax",240,34);velInfo.Parent=parent
    local function refresh()
        toggle.Text=state.AutoTrade and "Auto Trade · ON"or "Auto Trade · OFF"
        toggle.BackgroundColor3=state.AutoTrade and Color3.fromRGB(91,72,164)or Color3.fromRGB(38,41,56)
        mode.Text="Offer mode · "..(state.TradeMode=="Legendary"and "Legendary+"or "Selected")
    end
    function state.SetAutoTrade(on)
        if on and state.StopEverything then return false end
        state.AutoTrade=on==true;refresh();requestSave();return true
    end
    function state.SetTradeMode(value)
        if value~="Selected"and value~="Legendary"then return false end
        state.TradeMode=value;refresh();requestSave();return true
    end
    function state.SetTradeItems(selected)
        local result={}
        for name,on in pairs(selected or {})do if type(name)=="string"and on==true then result[name]=true end end
        state.TradeItems=result;requestSave()
    end
    function state.GetTradeItemChoices()
        local groups={}
        for _,item in ipairs(inventory:GetChildren())do
            local count=item:FindFirstChild("Count");groups[item.Name]=(groups[item.Name]or 0)+(count and count.Value or 1)
        end
        for name,on in pairs(state.TradeItems)do if on and groups[name]==nil then groups[name]=0 end end
        local result={};for name,count in pairs(groups)do result[#result+1]={Name=name,Count=count}end
        table.sort(result,function(a,b)return a.Name<b.Name end);return result
    end
    bind(toggle.Activated,function()state.SetAutoTrade(not state.AutoTrade)end)
    bind(mode.Activated,function()state.SetTradeMode(state.TradeMode=="Selected"and "Legendary"or "Selected")end)
    bind(items.Activated,function()
        list.Visible=not list.Visible
        if not list.Visible then return end
        for _,child in ipairs(list:GetChildren())do if child:IsA("GuiButton")then child:Destroy()end end
        local groups={};for _,item in ipairs(inventory:GetChildren())do local count=item:FindFirstChild("Count");groups[item.Name]=(groups[item.Name]or 0)+(count and count.Value or 1)end
        local names={};for name in pairs(groups)do names[#names+1]=name end;table.sort(names)
        for index,name in ipairs(names)do
            local button=uiButton("TradeItem"..index,"",index,30,list)
            local function label()button.Text=(state.TradeItems[name]and "[x] "or "[ ] ")..name.." x"..groups[name]end
            label();bind(button.Activated,function()state.TradeItems[name]=not state.TradeItems[name];label();requestSave()end)
        end
    end)
    local worker
    local function plan()
        local result={}
        for _,item in ipairs(inventory:GetChildren())do
            local definition=rs.Database.Items:FindFirstChild(item.Name)
            local rarity=definition and definition:FindFirstChild("Rarity")
            local chosen=worker.AlwaysInclude(item.Name)or state.TradeMode=="Selected"and state.TradeItems[item.Name]or rarity and worker.IncludesRarity(state.TradeMode,rarity.Value)
            if chosen and item:IsA("IntValue")and not item:GetAttribute("Locked")and not item:GetAttribute("Favorited")and restrictions.CanOfferTrading(profile,item)==true then
                local equipped=false
                for _,slot in ipairs(equip:GetChildren())do if slot:IsA("ValueBase")and slot.Value==item.Value then equipped=true;break end end
                if not equipped then result[#result+1]=item end
            end
        end
        table.sort(result,function(a,b)return a.Value<b.Value end)
        local balance=profile.Stats:FindFirstChild("Vel")
        return result,worker.MaxVel(balance and balance.Value or 0)
    end
    local nativeTrade=require(rs.CardinalClient.MainModule.Services.UI.Trade)
    local function pendingRequest()
        local root=player:FindFirstChildOfClass("PlayerGui")
        local cardinal=root and root:FindFirstChild("CardinalUI")
        local pui=cardinal and cardinal:FindFirstChild("PlayerUI")
        local hud=pui and pui:FindFirstChild("HUD")
        local prompt=hud and hud:FindFirstChild("TradeRequest")
        local label=prompt and prompt:FindFirstChild("PlayerText")
        if not prompt or not prompt.Visible or not label then return nil end
        local name=label.Text:match("^([%w_]+) wants to trade with you$")
        return name and Players:FindFirstChild(name)or nil
    end
    worker=make({Player=player,Plan=plan,Pending=pendingRequest,
        Count=function(item)local count=item:FindFirstChild("Count");return count and count.Value or 1 end,
        Active=function()return state.AutoTrade and state.Running and not state.StopEverything and not state.ModeratorBlocking end,
        Allowed=function(person)return typeof(person)=="Instance"and person:IsA("Player")and state.SafeWhitelistIds[tostring(person.UserId)]==true end,
        Send=function(action,args)
            if action=="RequestAccept"then
                local person=pendingRequest()
                if person and state.SafeWhitelistIds[tostring(person.UserId)]==true then nativeTrade.AcceptRequest()end
            else rs.Event:FireServer("Trade",action,args)end
        end,
        Status=function(text)status.Text=text end})
    bind(rs.Event.OnClientEvent,function(route,args)
        if route=="UI"and type(args)=="table"and args[1]=="Trade"then
            worker.Event(args[2],args[3])
            if (args[2]=="TradeChanged"or args[2]=="RequestAccept")and state.AutoTrade then state.AutoTradeBusy=true end
            if args[2]=="TradeCancel"or args[2]=="TradeCompleted"then state.AutoTradeBusy=false end
        end
    end)
    refresh()
    task.spawn(function()
        while state.Running do
            local ok,value=pcall(worker.Update,os.clock());state.AutoTradeBusy=ok and value==true
            if not ok then status.Text="Trade paused · "..tostring(value)end
            task.wait(state.AutoTrade and .3 or 1)
        end
        state.AutoTradeBusy=false
    end)
end

-- Native forge action and five-to-one recipes inspected through connected MCP.
do
    local make=(function()
-- BEGIN BUNDLED AUTO CRAFT
-- END BUNDLED AUTO CRAFT
    end)()
    local profile=ReplicatedStorage.Profiles[player.Name]
    local restrictions=require(ReplicatedStorage.Shared.Util.ItemRestrictions)
    local function count(name)
        local total=0
        for _,item in ipairs(profile.Inventory:GetChildren())do
            if item.Name==name and item:IsA("IntValue")and restrictions.CanOfferCrafting(profile,item)==true then
                local stack=item:FindFirstChild("Count")
                total+=stack and math.max(0,stack.Value)or 1
            end
        end
        return total
    end
    local worker=make({Active=function()return state.Running end,
        Busy=function()return state.StopEverything or state.ModeratorBlocking or state.SafeModePanic or state.AutoTradeBusy
            or state.TravelBusy or state.AutomationTeleporting end,
        Selected=function(name)return state.AutoCraft[name]==true end,Count=count,
        Recipe=function(output,input)
            local definition=ReplicatedStorage.Database.Items:FindFirstChild(output)
            local recipe=definition and definition:FindFirstChild("Recipe")
            if not recipe then return end
            local amount
            for _,part in ipairs(recipe:GetChildren())do
                if part.Name==input and part:IsA("ValueBase")then amount=part.Value
                else return end -- Do not spend currency or additional materials for changed recipes.
            end
            return amount
        end,
        Send=function(name)ReplicatedStorage.Event:FireServer("Item",{"Craft",name})end,
        Status=function(text)state.AutoCraftStatus=text end})
    function state.SetAutoCraft(selected)
        local result={}
        for _,name in ipairs({"Rare Upgrade Crystal","Legendary Upgrade Crystal"})do if selected and selected[name]==true then result[name]=true end end
        state.AutoCraft=result;worker.Reset();requestSave()
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
    local transfer=make({Settings=settingsPayload,Encode=function(v)return HttpService:JSONEncode(v)end,
        Decode=function(v)return HttpService:JSONDecode(v)end,Copy=setclipboard or toclipboard,
        Spots=function()
            local result={}
            if filePersistence and type(listfiles)=="function"then
                for _,file in ipairs(listfiles(configFolder))do
                    local id=file:match("custom%-spots_(%d+)%.json$")
                    if id then
                        local raw=readfile(file)
                        assert(#raw<=32768,"Custom spots file too large")
                        local value=HttpService:JSONDecode(raw)
                        assert(value.Version==1 and type(value.Areas)=="table","Invalid custom spots file")
                        result[id]=value.Areas
                    end
                end
            end
            local current={}
            for id,area in pairs(destinations)do
                if id:sub(1,16)=="saved:multispot:"then
                    local point=area.Position
                    current[#current+1]={Id=id,Name=area.Name,Position={point.X,point.Y,point.Z}}
                end
            end
            result[tostring(game.PlaceId)]=current
            return result
        end,
        Apply=function(value)
            assert(filePersistence or next(value.CustomSpots)==nil,"Importing saved spots requires executor file access")
            -- Compile first; the imported JSON is data, never executable text.
            local run=assert(loadstring(embeddedSource,"Feather config reload"))
            env.SB2ConfigImport={UserId=player.UserId,Settings=value.Settings,CustomSpots=value.CustomSpots}
            state.AutoSaveSuspended=true
            state.Destroy(true)
            run(embeddedSource)
        end})
    state.ExportConfig=transfer.Export
    state.ImportConfig=transfer.Import
end
