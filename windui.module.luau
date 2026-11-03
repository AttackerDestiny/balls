-- WindUI presentation; existing controllers remain the owners of gameplay/settings.
return function(ctx)
    local s=ctx.State
    local api={Controls={},Tabs={},Ready=false,Visible=true}
    local disposed=false
    local toggles,dropdowns,paragraphs={},{},{}
    local nextUpdate,nextChoices=0,0
    local tabs={"Main","Combat","Challenge Floors","Auto Skill","Misc","Player","Utility","Speacial"}
    local icons={"house","swords","shield","sparkles","menu","users","settings","trending-up"}
    local function report(reason)s.WindUIError=tostring(reason)end
    local function guard(fn)
        return function(...)
            if disposed or s.Running==false then return end
            local ok,reason=pcall(fn,...)
            if not ok then report(reason)end
        end
    end
    local function signature(value)
        if type(value)~="table"then return tostring(value)end
        local values={};for _,v in ipairs(value)do values[#values+1]=tostring(v)end
        table.sort(values);return table.concat(values,"\0")
    end
    local function bool(key)return function()return s[key]==true end end
    local function invoke(name,...)
        assert(type(s[name])=="function","Control unavailable: "..name)
        return s[name](...)
    end
    local window=ctx.WindUI:CreateWindow({Title="Feather",Author="Swordburst 2 · v"..s.Version,
        Folder="SB2Codex/WindUI",Size=ctx.Size,MinSize=ctx.MinSize,Theme="Dark",Transparent=false,
        Acrylic=false,Resizable=true,AutoScale=true,SideBarWidth=ctx.SideBarWidth or 155,HideSearchBar=false,ScrollBarEnabled=true,
        User={Enabled=false},OpenButton={Title="Feather"}})
    assert(window,"WindUI window was not created")
    api.Window=window
    -- Use the existing mobile Show UI button so the HUD remains independent.
    window.IsOpenButtonEnabled=false
    if window.OpenButtonMain then window.OpenButtonMain:Visible(false)end
    for i,name in ipairs(tabs)do api.Tabs[name]=window:Tab({Title=name,Icon=icons[i]})end
    local function button(key,tab,title,fn,desc)
        api.Controls[key]=api.Tabs[tab]:Button({Title=title,Desc=desc,Callback=guard(fn)})
    end
    local function paragraph(key,tab,title,get)
        local text=tostring(get()or "")
        local control=api.Tabs[tab]:Paragraph({Title=title,Desc=text})
        api.Controls[key]=control;paragraphs[#paragraphs+1]={Control=control,Get=get,Text=text}
    end
    local function toggle(key,tab,title,get,set,desc)
        local entry={Get=get,Value=get()}
        local control=api.Tabs[tab]:Toggle({Title=title,Desc=desc,Value=get(),Callback=guard(function(value)
            if api.Ready and value~=get()then
                set(value);entry.Value=get();entry.Control:Set(entry.Value,false)
            end
        end)})
        entry.Control=control;api.Controls[key]=control;toggles[#toggles+1]=entry
    end
    local function stateToggle(key,tab,title,setter,desc)
        toggle(key,tab,title,bool(key),function(value)invoke(setter,value)end,desc)
    end
    local function dropdown(key,tab,title,build,choose,multi,desc)
        local entry={Build=build,Choose=choose,Multi=multi,Syncing=true}
        local view=build();entry.Map=view.Map or {};entry.Current=signature(view.Value);entry.Value=entry.Current
        entry.Options=signature(view.Options)
        entry.Control=api.Tabs[tab]:Dropdown({Title=title,Desc=desc,Values=view.Options,Value=view.Value,
            Multi=multi==true,AllowNone=multi==true,SearchBarEnabled=true,Callback=guard(function(value)
                if not api.Ready or entry.Syncing or signature(value)==entry.Current then return end
                entry.Current=signature(value)
                entry.Value=nil;entry.Choose(value,entry.Map)
                nextChoices=0
            end)})
        entry.Syncing=false
        api.Controls[key]=entry.Control;dropdowns[#dropdowns+1]=entry
    end
    local function input(key,tab,title,value,set,desc)
        api.Controls[key]=api.Tabs[tab]:Input({Title=title,Desc=desc,Value=value or "",Type="Input",
            Placeholder="Enter here...",Callback=guard(function(text)
                if api.Ready then set(text)end
            end)})
    end
    local function selected(options,map,predicate)
        local result={};for _,label in ipairs(options)do if predicate(map[label])then result[#result+1]=label end end
        return result
    end
    local function option(options,map,label,id)
        local base,index=label,2
        while map[label]~=nil do label=base.." ("..index..")";index+=1 end
        options[#options+1]=label;map[label]=id
        return label
    end
    local function status(key,fallback)
        local item=s.UI and s.UI[key]
        return item and item.Text or s[key]or fallback or ""
    end

    api.Controls.TeleportSection=api.Tabs.Main:Section({Title="Teleport",TextSize=17})
    local destination
    dropdown("TeleportDestination","Main","Spot",function()
        local list={};for _,area in pairs(s.FloorDestinations or {})do list[#list+1]=area end
        table.sort(list,function(a,b)
            if a.Kind~=b.Kind then return a.Kind<b.Kind end
            if a.Name~=b.Name then return a.Name<b.Name end
            return a.Id<b.Id
        end)
        local options,map,value={},{},nil
        for _,area in ipairs(list)do
            local label=option(options,map,area.Kind.." · "..area.Name,area.Id)
            if destination==area.Id then value=label end
        end
        return {Options=options,Map=map,Value=value}
    end,function(label,map)
        destination=map[label]
        if destination then invoke("TeleportToDestination",destination)end
    end)
    button("RefreshDestinations","Main","Refresh List",function()invoke("RefreshTeleportDestinations");nextChoices=0 end)
    api.Controls.SafeModeSection=api.Tabs.Main:Section({Title="Safe Mode",TextSize=17})
    stateToggle("SafeMode","Main","Safe Mode","SetSafeMode")
    dropdown("SafeFloor","Main","Safe floor",function()
        local options,map,value={},{},nil
        local catalog=s.AutomationCatalog
        for _,floor in ipairs(catalog and catalog.Floors or {})do
            local unlocked=invoke("IsAutomationFloorUnlocked",floor.Id)
            local label=floor.Label..(unlocked and ""or " · locked")
            options[#options+1]=label;map[label]=floor.Id
            if floor.Id==s.SafeFloorId then value=label end
        end
        return {Options=options,Map=map,Value=value}
    end,function(label,map)local id=map[label];if id and id~=s.SafeFloorId then invoke("SetSafeFloor",id)end end,
        false)
    input("SafeWhitelist","Main","Whitelist",s.SafeWhitelistText,function(text)
        if text~=s.SafeWhitelistText then invoke("SetSafeWhitelist",text)end
    end,"Input A List Of User")
    paragraph("SafeModeStatus","Main","Safe Mode status",function()return s.SafeModeStatus end)
    api.Controls.MultiSpotSection=api.Tabs.Main:Section({Title="Multi Spot",TextSize=17})
    stateToggle("MultiSpot","Main","Multi Spot","SetMultiSpot")
    button("SaveSpot","Main","Save Spot",function()invoke("SaveMultiSpot");nextChoices=0 end)
    dropdown("MultiSpotAreas","Main","Saved Spot",function()
        local options,map={},{ }
        local catalog=s.AutomationCatalog
        if catalog then catalog.AddCurrent(s.FloorDestinations,ctx.PlaceId);catalog.Sort()end
        for _,spot in ipairs(catalog and catalog.Spots or {})do
            if spot.PlaceId==ctx.PlaceId then
                option(options,map,spot.Kind.." · "..spot.Name,spot.Id)
            end
        end
        return {Options=options,Map=map,Value=selected(options,map,function(id)return s.MultiSpotSelected[id]==true end)}
    end,function(values,map)
        local chosen={};for _,label in ipairs(values or {})do if map[label]then chosen[map[label]]=true end end
        invoke("SetMultiSpotSelections",chosen)
    end,true)
    api.Controls.FriendJoinerSection=api.Tabs.Main:Section({Title="Friend Joiner",TextSize=17})
    input("JoinFriendUsername","Main","Friend username",s.JoinFriendUsername,function(text)
        if text~=s.JoinFriendUsername then invoke("SetJoinFriendUsername",text)end
    end)
    stateToggle("AutoJoinFriend","Main","Auto Join Friend","SetAutoJoinFriend")
    paragraph("AutoJoinFriendStatus","Main","Status",function()
        local name=tostring(s.JoinFriendUsername or ""):match("^%s*(.-)%s*$"):gsub("^@","")
        return ctx.FriendPresent and ctx.FriendPresent(name)and "Friend Appeared"or "Friend Unappeared"
    end)
    local restart=guard(function()invoke("RestartScript")end)
    api.Controls.RestartScript=window:CreateTopbarButton("Restart script","rotate-cw",restart,996)
    api.Controls.AutoHideUI=window:CreateTopbarButton("Auto-hide UI on execute","eye-off",guard(function()
        invoke("SetAutoHideUI",not s.AutoHideUI)
        if ctx.MarkAutoHide then ctx.MarkAutoHide(api.Controls.AutoHideUI,s.AutoHideUI)end
    end),995)
    if ctx.MarkAutoHide then ctx.MarkAutoHide(api.Controls.AutoHideUI,s.AutoHideUI)end


    stateToggle("Enabled","Combat","Kill Aura","SetEnabled")
    stateToggle("AutoFarm","Combat","Auto Farm","SetAutoFarm")
    stateToggle("AutoEquipBestSword","Combat","Auto Equip Best Weapon","SetAutoEquipBestSword")
    stateToggle("AtheonDodge","Combat","Atheon Dodge","SetAtheonDodge")
    stateToggle("AutoSwing","Combat","Swing animation","SetAutoSwing")
    stateToggle("AutoDodge","Challenge Floors","Auto Dodge","SetAutoDodge")
    api.Controls.SkillAuraSection=api.Tabs["Auto Skill"]:Section({Title="Skill Aura",TextSize=17})
    stateToggle("SkillAura","Auto Skill","Skill Aura","SetSkillAura")
    dropdown("SelectedSkill","Auto Skill","Skill",function()
        return {Options=s.SkillChoices or {},Value=s.SelectedSkill}
    end,function(name)if name and name~=s.SelectedSkill then invoke("SetSelectedSkill",name)end end)
    api.Controls.MiscSkillSection=api.Tabs["Auto Skill"]:Section({Title="Misc Skill",TextSize=17})
    stateToggle("MiscSkillEnabled","Auto Skill","Misc Skill","SetMiscSkillEnabled")
    dropdown("SelectedMiscSkill","Auto Skill","Skill",function()
        local options={};for _,item in ipairs(s.MiscSkillChoices or {})do if item.Usable then options[#options+1]=item.Name end end
        return {Options=options,Value=s.SelectedMiscSkill}
    end,function(name)if name and name~=s.SelectedMiscSkill then invoke("SetMiscSkill",name)end end)
    for _,name in ipairs({"Dismantle","Upgrade","The Forge"})do
        button("Open"..name,"Misc",name,function()invoke("OpenGameMenu",name)end)
    end

    dropdown("SelectedPlayer","Player","Select player",function()
        local options,map,value={},{},nil
        for _,person in ipairs(s.PlayerTools.Choices())do
            local label=person.DisplayName.." (@"..person.Name..")";options[#options+1]=label;map[label]=person.UserId
            if person.UserId==s.SelectedPlayerId then value=label end
        end
        return {Options=options,Map=map,Value=value}
    end,function(label,map)if map[label]then s.PlayerTools.Select(map[label])end end)
    button("TeleportPlayer","Player","TP to player",function()s.PlayerTools.Teleport()end)
    toggle("ViewingPlayer","Player","View player",bool("ViewingPlayer"),function(value)s.PlayerTools.SetViewing(value)end)
    toggle("ViewingPlayerInventory","Player","View player inventory",bool("ViewingPlayerInventory"),function(value)s.PlayerTools.SetInventoryVisible(value)end)

    local boostNames={"No damage text","No damage particles","Delete dead mobs","No vel obtained in chat","Hide players","Hide effects","Disable rendering","Limit FPS"}
    local function applyBoost(values)
        local picked={};for _,name in ipairs(values or {})do picked[name]=true end
        for _,name in ipairs(boostNames)do if (s.PerformanceBoosters[name]==true)~=(picked[name]==true)then invoke("SetPerformanceBoost",name,picked[name]==true)end end
    end
    api.Controls.PerformanceBoosterSection=api.Tabs.Utility:Section({Title="Perfromance Booster",TextSize=17})
    dropdown("PerformanceBoosters","Utility","Performance boosters",function()
        local value={};for _,name in ipairs(boostNames)do if s.PerformanceBoosters[name]then value[#value+1]=name end end
        return {Options=boostNames,Value=value}
    end,applyBoost,true)
    local rarities={"Common","Uncommon","Rare"}
    api.Controls.AutoDismantleSection=api.Tabs.Utility:Section({Title="Auto Dismantle",TextSize=17})
    dropdown("AutoDismantle","Utility","Auto Dismantle rarities",function()
        local value={};for _,name in ipairs(rarities)do if s.AutoDismantle[name]then value[#value+1]=name end end
        return {Options=rarities,Value=value}
    end,function(values)
        local picked={};for _,name in ipairs(values or {})do picked[name]=true end
        for _,name in ipairs(rarities)do if (s.AutoDismantle[name]==true)~=(picked[name]==true)then invoke("SetAutoDismantle",name,picked[name]==true)end end
    end,true,"Equipped, locked and favorited items are preserved.")
    api.Controls.AutoTradeSection=api.Tabs.Utility:Section({Title="Auto Trade",TextSize=17})
    stateToggle("AutoTrade","Utility","Auto Trade","SetAutoTrade","Accept requests only from whitelisted players; final acceptance is automatic.")
    dropdown("TradeMode","Utility","Trade offer mode",function()
        return {Options={"Selected items","Legendary+"},Value=s.TradeMode=="Legendary"and "Legendary+"or "Selected items"}
    end,function(value)invoke("SetTradeMode",value=="Legendary+"and "Legendary"or "Selected")end)
    dropdown("TradeItems","Utility","Trade inventory items",function()
        local options,map={},{ }
        for _,item in ipairs(s.GetTradeItemChoices())do local label=item.Name.." x"..item.Count;options[#options+1]=label;map[label]=item.Name end
        return {Options=options,Map=map,Value=selected(options,map,function(name)return s.TradeItems[name]==true end)}
    end,function(values,map)
        local picked={};for _,label in ipairs(values or {})do if map[label]then picked[map[label]]=true end end
        invoke("SetTradeItems",picked)
    end,true,"All selected copies. Upgrade Protection Scroll and Resurrection Crystal are always included.")
    stateToggle("AccountProgression","Speacial","Account Progression","SetAccountProgression")

    function api.SetVisible(value)
        if disposed then return end
        api.Visible=value==true;s.UIHidden=not api.Visible
        ctx.Visibility(api.Visible)
        if api.Visible then window:Open();nextChoices=0 else window:Close()end
    end
    window:OnOpen(function()if not disposed then api.Visible=true;s.UIHidden=false;ctx.Visibility(true)end end)
    window:OnClose(function()if not disposed then api.Visible=false;s.UIHidden=true;ctx.Visibility(false)end end)
    window:OnDestroy(function()if not disposed and s.Running~=false then invoke("Destroy")end end)
    function api.Update(now)
        if disposed or s.Running==false or now<nextUpdate then return end
        nextUpdate=now+.25
        local tab=window.CurrentTab and tabs[window.CurrentTab]
        if tab then s.UI.ActiveTab=tab end
        if not api.Visible then return end
        for _,entry in ipairs(toggles)do
            local value=entry.Get()
            if value~=entry.Value then entry.Value=value;entry.Control:Set(value,false)end
        end
        for _,entry in ipairs(paragraphs)do
            local text=tostring(entry.Get()or "")
            if text~=entry.Text then entry.Text=text;entry.Control:SetDesc(text)end
        end
        if now>=nextChoices then
            nextChoices=now+1
            for _,entry in ipairs(dropdowns)do
                local view=entry.Build();entry.Syncing=true;entry.Map=view.Map or {}
                local options=signature(view.Options);local value=signature(view.Value)
                local changed=options~=entry.Options
                entry.Current=value
                if changed then entry.Options=options;entry.Control:Refresh(view.Options)end
                if changed or value~=entry.Value then entry.Value=value;entry.Control:Select(view.Value)end
                entry.Syncing=false
            end
        end
    end
    function api.Destroy()
        if disposed then return end
        disposed=true;api.Ready=false
        ctx.Visibility(false)
        window:Destroy()
    end
    -- Restore values after all controls exist; initialization never runs actions.
    api.Ready=true
    local activeTab=api.Tabs[s.UI.ActiveTab or "Main"]or api.Tabs.Main
    activeTab:Select()
    api.Update(0)
    return api
end
