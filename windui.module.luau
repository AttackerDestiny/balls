-- Declarative modern UI: construction, value projection, and user actions are separate.
return function(ctx)
    local state=ctx.State
    local api={Controls={},Tabs={},Ready=false,BackgroundReady=false,Visible=true}
    local lifetime={Closed=false,VisibilityApplied=false}
    local wavesTab="Waves Defense"
    local order={"Main","Combat",wavesTab,"Auto Skill","Misc","Player","Utility","Speacial","Dodge","Settings"}
    local icons={"house","swords","shield","sparkles","menu","users","settings","trending-up","shield","sliders-horizontal"}
    local projections={}
    local cadence={Next=0,Choices=0,Cursor=1,Tab=nil,Build=os.clock()}
    local memory=ctx.Memory or {Pruned=0,Update=function()end}
    api.Memory=memory
    local function valid()return not lifetime.Closed and state.Running~=false end
    local function fail(reason)
        state.WindUIError=tostring(reason)
        if ctx.WindUI.Notify then ctx.WindUI:Notify({Title="Feather",Content=state.WindUIError,Duration=5})end
    end
    local function safe(fn)
        return function(...)
            if not valid()then return end
            local ok,reason=pcall(fn,...)
            if not ok then fail(reason)end
        end
    end
    local function action(name,...)
        assert(type(state[name])=="function","Control unavailable: "..name)
        return state[name](...)
    end
    local function constructionPoint()
        assert(valid(),"UI initialization cancelled")
        if ctx.Yield then ctx.Yield()
        elseif ctx.Defer and os.clock()-cadence.Build>=.002 then task.wait();cadence.Build=os.clock()end
        assert(valid(),"UI initialization cancelled")
    end
    local function signature(value,ordered)
        if type(value)~="table"then return tostring(value)end
        local items={};for _,item in ipairs(value)do items[#items+1]=tostring(item)end
        if not ordered then table.sort(items)end
        return table.concat(items,"\0")
    end
    local function mapping(options,label,id,map)
        local base,suffix=label,2
        while map[label]~=nil do label=base.." ("..suffix..")";suffix+=1 end
        options[#options+1]=label;map[label]=id
        return label
    end
    local function chosen(options,map,enabled)
        local result={}
        for _,label in ipairs(options)do if enabled(map[label])then result[#result+1]=label end end
        return result
    end
    local function selection(values)
        local result={};for _,name in ipairs(values or {})do result[name]=true end;return result
    end
    if not ctx.WindUI:GetThemes()[state.Theme or "Dark"]then state.Theme="Dark"end
    local window=ctx.WindUI:CreateWindow({Title="Feather",Author="Swordburst 2 · v"..state.Version,
        Folder="SB2Codex/WindUI",Size=ctx.Size,MinSize=ctx.MinSize,Theme=state.Theme or "Dark",Transparent=false,
        Acrylic=false,Resizable=true,AutoScale=true,SideBarWidth=ctx.SideBarWidth or 155,
        HideSearchBar=false,ScrollBarEnabled=true,User={Enabled=false},OpenButton={Title="Feather"}})
    assert(window,"WindUI window was not created")
    api.Window=window;window.IsOpenButtonEnabled=false
    if window.OpenButtonMain then window.OpenButtonMain:Visible(false)end
    local frame=window.UIElements and window.UIElements.Main
    if frame then
        local nativeClose=window.Close
        local function present(show)
            if lifetime.Closed or window.Destroyed then return end
            window.Closed=not show;window.CanDropdown=show;window.CanResize=show and window.Resizable~=false
            if frame.Size~=window.Size then frame.Size=window.Size end
            frame.Background.ImageTransparency=0;frame.Main.Visible=show;frame.Visible=show
            local callback=show and window.OnOpenCallback or window.OnCloseCallback
            if callback then callback()end
        end
        window.Open=function()present(true)end
        window.Close=function()
            present(false)
            return {Destroy=function()return nativeClose(window):Destroy()end}
        end
    end
    local function publish(show)
        api.Visible=show==true;state.UIHidden=not api.Visible;ctx.Visibility(api.Visible)
    end
    function api.SetVisible(show)
        if lifetime.Closed then return end
        show=show==true
        if lifetime.VisibilityApplied and api.Visible==show and window.Closed==not show then return end
        lifetime.VisibilityApplied=true;publish(show)
        if show then window:Open()else window:Close()end
    end
    window:OnOpen(function()if valid()then publish(true)end end)
    window:OnClose(function()if valid()then publish(false)end end)
    window:OnDestroy(function()if valid()then action("Destroy")end end)
    local function mountRange(control,definition,tabObject)
        local elements=control.ParagraphFrame and control.ParagraphFrame.UIElements
        if not elements then return end
        local inputService=ctx.InputService
        local scroller=tabObject.UIElements and tabObject.UIElements.ContainerFrame
        local function gui(class,parent,properties)
            local object=Instance.new(class)
            for key,value in pairs(properties)do object[key]=value end
            object.Parent=parent
            return object
        end
        local function rounded(object)
            gui("UICorner",object,{CornerRadius=UDim.new(1,0)})
            return object
        end
        local row=gui("Frame",elements.Container,{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1})
        local hit=gui("TextButton",row,{Size=UDim2.new(1,0,0,22),Text="",AutoButtonColor=false,BackgroundTransparency=1})
        local track=rounded(gui("Frame",hit,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
            Size=UDim2.new(1,-16,0,4),BorderSizePixel=0,BackgroundTransparency=.75}))
        local fill=rounded(gui("Frame",track,{BorderSizePixel=0}))
        local function thumb()
            return rounded(gui("Frame",track,{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(13,13),BorderSizePixel=0}))
        end
        local low,high=thumb(),thumb()
        local label=gui("TextLabel",row,{Position=UDim2.fromOffset(0,20),Size=UDim2.new(1,0,0,12),
            BackgroundTransparency=1,TextSize=12,FontFace=elements.Title.FontFace,TextXAlignment=Enum.TextXAlignment.Right})
        local minimum,maximum=definition.Value.Min,definition.Value.Max
        local first,last=definition.Minimum or 0,definition.Maximum or 100
        local span=last-first
        local function draw()
            local color=elements.Title.TextColor3
            low.BackgroundColor3=color;high.BackgroundColor3=color
            fill.BackgroundColor3=color;track.BackgroundColor3=color;label.TextColor3=color
            low.Position=UDim2.fromScale((minimum-first)/span,.5);high.Position=UDim2.fromScale((maximum-first)/span,.5)
            fill.Position=UDim2.fromScale((minimum-first)/span,0);fill.Size=UDim2.fromScale((maximum-minimum)/span,1)
            label.Text=maximum==0 and "Off" or string.format("%d – %d min",minimum,maximum)
        end
        draw()
        local changed,ended,scrolling
        local function stopDrag()
            if not changed then return end
            changed:Disconnect();ended:Disconnect();changed=nil;ended=nil
            if scroller then scroller.ScrollingEnabled=scrolling end
        end
        hit.InputBegan:Connect(safe(function(inputObject)
            local touch=inputObject.UserInputType==Enum.UserInputType.Touch
            if not api.Ready or changed or (not touch and inputObject.UserInputType~=Enum.UserInputType.MouseButton1) then return end
            local function position(input)
                local ratio=(input.Position.X-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X)
                return first+math.clamp(ratio,0,1)*span
            end
            local point=position(inputObject)
            local lower=point<(minimum+maximum)/2
            local function move(input)
                local value=math.round(position(input))
                if lower then minimum=math.min(value,maximum) else maximum=math.max(value,minimum) end
                draw()
            end
            if scroller then scrolling=scroller.ScrollingEnabled;scroller.ScrollingEnabled=false end
            changed=inputService.InputChanged:Connect(safe(function(input)
                if input==inputObject or (not touch and input.UserInputType==Enum.UserInputType.MouseMovement) then move(input) end
            end))
            ended=inputService.InputEnded:Connect(safe(function(input)
                if input==inputObject or (not touch and input.UserInputType==Enum.UserInputType.MouseButton1) then
                    stopDrag();definition.Write(minimum,maximum)
                end
            end))
            move(inputObject)
        end))
        return stopDrag
    end
    local function register(tab,definition)
        constructionPoint()
        local key=definition.Key
        local tabObject=api.Tabs[tab]
        local kind=definition.Kind
        if kind=="Section"then api.Controls[key]=tabObject:Section({Title=definition.Title,TextSize=17});return end
        local projection={Definition=definition,Tab=tab}
        local options={Title=definition.Title,Desc=definition.Desc}
        if kind=="Button"then options.Callback=safe(definition.Action)
        elseif kind=="Paragraph"then projection.Text=tostring(definition.Read()or "");options.Desc=projection.Text
        elseif kind=="Toggle"then
            projection.Value=definition.Read();options.Value=projection.Value
            options.Callback=safe(function(value)
                if api.Ready and value~=definition.Read()then
                    definition.Write(value);projection.Value=definition.Read();projection.Control:Set(projection.Value,false)
                end
            end)
        elseif kind=="Input"then
            options.Type="Input";options.Value=definition.Value or "";options.Placeholder="Enter here..."
            options.Callback=safe(function(text)if api.Ready and not projection.Syncing then definition.Write(text)end end)
        elseif kind=="Slider"then
            options.Value={Min=1,Max=definition.Maximum,Default=definition.Read()};options.Step=1
            options.Callback=safe(function(value)
                if api.Ready and value~=definition.Read()then definition.Write(value)end
            end)
        elseif kind=="Dropdown"then
            local view=definition.Read()
            projection.Map=view.Map or {};projection.Options=signature(view.Options)
            projection.Value=signature(view.Value,definition.Ordered);projection.Current=projection.Value
            projection.Syncing=true
            options.Values=view.Options;options.Value=view.Value;options.Multi=definition.Multi==true
            options.AllowNone=definition.Multi==true;options.SearchBarEnabled=true
            options.Callback=safe(function(value)
                local keyValue=signature(value,definition.Ordered)
                if not api.Ready or projection.Syncing or keyValue==projection.Current then return end
                projection.Current=keyValue;projection.Value=nil
                definition.Write(value,projection.Map);cadence.Choices=0;cadence.Cursor=1
            end)
        end
        local factory=kind=="RangeSlider" and "Paragraph" or kind
        projection.Control=tabObject[factory](tabObject,options)
        if kind=="RangeSlider"then projection.Cleanup=mountRange(projection.Control,definition,tabObject) end
        projection.Syncing=false;api.Controls[key]=projection.Control
        projections[#projections+1]=projection
        return projection
    end
    local function section(tab,key,title)return register(tab,{Kind="Section",Key=key,Title=title})end
    local function toggle(tab,key,title,setter,desc)
        return register(tab,{Kind="Toggle",Key=key,Title=title,Desc=desc,Read=function()return state[key]==true end,Write=function(value)action(setter,value)end})
    end
    local function dropdown(tab,key,title,read,write,multi,desc)
        return register(tab,{Kind="Dropdown",Key=key,Title=title,Read=read,Write=write,Multi=multi,Desc=desc,Ordered=key=="MultiSpotAreas"})
    end
    local function input(tab,key,title,value,write,desc)return register(tab,{Kind="Input",Key=key,Title=title,Value=value,Write=write,Desc=desc})end
    local function button(tab,key,title,fn,desc)return register(tab,{Kind="Button",Key=key,Title=title,Action=fn,Desc=desc})end
    local function paragraph(tab,key,title,read)return register(tab,{Kind="Paragraph",Key=key,Title=title,Read=read})end
    local function tab(index)
        constructionPoint();local title=order[index]
        api.Tabs[title]=window:Tab({Title=title,Icon=icons[index]})
    end
    local function destinations()
        local list={};for _,area in pairs(state.FloorDestinations or {})do list[#list+1]=area end
        table.sort(list,function(a,b)return a.Kind==b.Kind and (a.Name==b.Name and a.Id<b.Id or a.Name<b.Name)or a.Kind<b.Kind end)
        local options,map={},{}
        for _,area in ipairs(list)do mapping(options,area.Kind.." · "..area.Name,area.Id,map)end
        return {Options=options,Map=map}
    end
    local function floors()
        local options,map,value={},{},nil
        for _,floor in ipairs(state.AutomationCatalog and state.AutomationCatalog.Floors or {})do
            local label=floor.Label..(action("IsAutomationFloorUnlocked",floor.Id)and ""or " · locked")
            options[#options+1]=label;map[label]=floor.Id
            if floor.Id==state.SafeFloorId then value=label end
        end
        return {Options=options,Map=map,Value=value}
    end
    local function arenas()
        local catalog=state.AutomationCatalog
        if catalog then catalog.AddCurrent(state.FloorDestinations,ctx.PlaceId);catalog.Sort()end
        local eligible={}
        for _,spot in ipairs(catalog and catalog.Spots or {})do if spot.PlaceId==ctx.PlaceId then eligible[spot.Id]=spot end end
        local priority,rank={},{}
        local function append(id)
            if eligible[id]and state.MultiSpotSelected[id]and not rank[id]then priority[#priority+1]=id;rank[id]=#priority end
        end
        for _,id in ipairs(state.MultiSpotOrder or {})do append(id)end
        for _,spot in ipairs(catalog and catalog.Spots or {})do append(spot.Id)end
        local options,map,labels={},{},{}
        for _,spot in ipairs(catalog and catalog.Spots or {})do if eligible[spot.Id]then
            local label=(rank[spot.Id]and rank[spot.Id].." · "or "")..spot.Kind.." · "..spot.Name
            labels[spot.Id]=mapping(options,label,spot.Id,map)
        end end
        local values={};for _,id in ipairs(priority)do values[#values+1]=labels[id]end
        return {Options=options,Map=map,Value=values}
    end
    local function main()
        section("Main","TeleportSection","Teleport")
        dropdown("Main","TeleportDestination","Spot",destinations,function(label,map)if map[label]then action("TeleportToDestination",map[label])end end)
        button("Main","RefreshDestinations","Refresh List",function()action("RefreshTeleportDestinations");cadence.Choices=0 end)
        section("Main","SafeModeSection","Safe Mode");toggle("Main","SafeMode","Safe Mode","SetSafeMode")
        dropdown("Main","SafeFloor","Safe floor",floors,function(label,map)if map[label]and map[label]~=state.SafeFloorId then action("SetSafeFloor",map[label])end end)
        local editor=input("Main","SafeWhitelist","Whitelist",state.SafeWhitelistText,function(text)
            if text:match("[%w_]")and text~=state.SafeWhitelistText then action("SetSafeWhitelist",text)end
        end,"Input A List Of User")
        api.ClearWhitelist=safe(function()
            editor.Syncing=true;local ok,reason=pcall(editor.Control.Set,editor.Control,"");editor.Syncing=false
            if not ok then error(reason)end
        end)
        if ctx.AddWhitelistClear then api.Controls.ClearWhitelist=ctx.AddWhitelistClear(editor.Control,api.ClearWhitelist)end
        paragraph("Main","SafeModeStatus","Status",function()return state.SafeModeStatus end)
        section("Main","MultiSpotSection","Multi Spot");toggle("Main","MultiSpot","Multi Spot","SetMultiSpot")
        button("Main","SaveSpot","Save Spot",function()action("SaveMultiSpot");cadence.Choices=0 end)
        dropdown("Main","MultiSpotAreas","Saved Spot",arenas,function(values,map)
            local selected,priority={},{}
            for _,label in ipairs(values or {})do local id=map[label];if id and not selected[id]then selected[id]=true;priority[#priority+1]=id end end
            action("SetMultiSpotSelections",selected,priority)
        end,true)
        section("Main","FriendJoinerSection","Friend Joiner")
        input("Main","JoinFriendUsername","Friend username",state.JoinFriendUsername,function(text)if text~=state.JoinFriendUsername then action("SetJoinFriendUsername",text)end end)
        toggle("Main","AutoJoinFriend","Auto Join Friend","SetAutoJoinFriend")
        paragraph("Main","AutoJoinFriendStatus","Status",function()
            local username=tostring(state.JoinFriendUsername or ""):match("^%s*(.-)%s*$"):gsub("^@","")
            return ctx.FriendPresent and ctx.FriendPresent(username)and "Friend Appeared"or "Friend Unappeared"
        end)
        api.Controls.RestartScript=window:CreateTopbarButton("Restart script","rotate-cw",safe(function()action("RestartScript")end),996)
        api.Controls.AutoHideUI=window:CreateTopbarButton("Auto-hide UI on execute","eye-off",safe(function()
            action("SetAutoHideUI",not state.AutoHideUI)
            if ctx.MarkAutoHide then ctx.MarkAutoHide(api.Controls.AutoHideUI,state.AutoHideUI)end
        end),995)
        if ctx.MarkAutoHide then ctx.MarkAutoHide(api.Controls.AutoHideUI,state.AutoHideUI)end
    end
    local boostNames={"No damage text","No damage particles","Delete dead mobs","No vel obtained in chat","Hide players","Hide effects","Delete map","Remove animations","Disable rendering","Limit FPS","Remove everything"}
    local synchronize
    local function rest()
        for _,row in ipairs({{"Enabled","Kill Aura","SetEnabled"},{"AutoFarm","Auto Farm","SetAutoFarm"},{"BossOnly","Boss Only","SetBossOnly"},{"CreditCheck","Credit Check","SetCreditCheck"}})do toggle("Combat",row[1],row[2],row[3])end
        input("Combat","CreditWhitelist","Credit Whitelist",state.CreditWhitelistText,function(text)if text~=state.CreditWhitelistText then action("SetCreditWhitelist",text)end end,"Input A List Of User")
        paragraph("Combat","CreditCheckStatus","Credit Status",function()return not state.CreditCheck and "Credit Check is off"or state.CreditCheckStatus or "Waiting for a boss or mini-boss"end)
        for _,row in ipairs({{"AutoEquipBestSword","Auto Equip Best Gear","SetAutoEquipBestSword"},{"AutoSwing","Swing animation","SetAutoSwing"}})do toggle("Combat",row[1],row[2],row[3])end
        toggle(wavesTab,"AutoDodge","Auto Dodge","SetAutoDodge")
        toggle(wavesTab,"AutoRegroup","Auto Regroup","SetAutoRegroup")
        input(wavesTab,"AutoRegroupUsers","Regroup Users",state.AutoRegroupUsers or "",function(text)
            if text~=state.AutoRegroupUsers then action("SetAutoRegroupUsers",text)end
        end,"Blank uses room Host + Alts")
        paragraph(wavesTab,"AutoRegroupStatus","Regroup Status",function()return state.AutoRegroupStatus or "Auto Regroup is off"end)
        section(wavesTab,"BetweenPaceSection","Completion Time")
        local difficulties={"Normal","Hard","Elite"}
        for _,mode in ipairs(difficulties)do
            register(wavesTab,{Kind="RangeSlider",Key="BetweenPace"..mode,Title=mode.." (minutes)",
                Value=state.BetweenPace and state.BetweenPace[mode] or {Min=0,Max=0},
                Write=function(minimum,maximum)action("SetBetweenPace",mode,minimum,maximum)end})
        end
        local roomViews={}
        local function refreshRoom(index)
            local view=roomViews[index]
            if not view then return end
            local entry=state.BetweenRooms[index]
            local frame=view.Heading.ElementFrame
            if frame then frame.Visible=entry~=nil end
            for field,projection in pairs(view.Fields)do
                local control=projection.Control
                if control.ElementFrame then
                    control.ElementFrame.Visible=entry~=nil and (field~="AutoRetry" or state.IsBetweenRoomHost(index))
                end
                if entry then
                    if field=="Host" or field=="Alt"then
                        if control.Value~=entry[field]then
                            projection.Syncing=true;control:Set(entry[field]);projection.Syncing=false
                        end
                    else
                        synchronize(projection,true)
                    end
                end
            end
        end
        local function room(index)
            if roomViews[index]then refreshRoom(index);return end
            local key="BetweenRoom"..index
            local function entry()return state.BetweenRooms[index] or {}end
            local fields={}
            local function refreshRetry()
                local frame=fields.AutoRetry and fields.AutoRetry.Control.ElementFrame
                if frame then frame.Visible=state.IsBetweenRoomHost(index)end
            end
            section(wavesTab,key,"Room "..index)
            local heading=api.Controls[key]
            fields.Host=input(wavesTab,key.."Host","Host",entry().Host,function(text)
                if text==entry().Host then return end
                action("SetBetweenRoomField",index,"Host",text)
                refreshRetry()
            end,"Roblox username or user ID")
            fields.Alt=input(wavesTab,key.."Alt","Alt",entry().Alt,function(text)
                if text==entry().Alt then return end
                local formatted=action("SetBetweenRoomField",index,"Alt",text)
                if formatted and formatted~=text then
                    local alt=fields.Alt
                    alt.Syncing=true;alt.Control:Set(formatted);alt.Syncing=false
                end
            end,"Up to seven usernames or IDs")
            fields.Difficulty=dropdown(wavesTab,key.."Difficulty","Difficulty",function()
                return {Options=difficulties,Value=entry().Difficulty}
            end,function(value)action("SetBetweenRoomField",index,"Difficulty",value)end)
            fields.Mode=dropdown(wavesTab,key.."Mode","Mode",function()
                return {Options={"Private","Friends","Game Party"},Value=entry().Mode}
            end,function(value)action("SetBetweenRoomField",index,"Mode",value)end)
            fields.Start=register(wavesTab,{Kind="Toggle",Key=key.."Start",Title="Start",
                Read=function()return entry().Start==true end,
                Write=function(value)action("SetBetweenRoomField",index,"Start",value)end})
            fields.AutoRetry=register(wavesTab,{Kind="Toggle",Key=key.."AutoRetry",Title="Auto Retry",
                Read=function()return entry().AutoRetry==true end,
                Write=function(value)action("SetBetweenRoomField",index,"AutoRetry",value)end})
            roomViews[index]={Heading=heading,Fields=fields}
            if ctx.AddRoomDelete then
                api.Controls[key.."Delete"]=ctx.AddRoomDelete(heading,safe(function()
                    if action("RemoveBetweenRoom",index)then
                        for slot=index,#state.BetweenRooms+1 do refreshRoom(slot)end
                    end
                end))
            end
            refreshRoom(index)
        end
        button(wavesTab,"CreateBetweenRoom","Create Room",function()
            local index=action("AddBetweenRoom")
            if index then room(index)end
        end)
        for index in ipairs(state.BetweenRooms or {})do room(index)end
        section("Auto Skill","SkillAuraSection","Skill Aura");toggle("Auto Skill","SkillAura","Skill Aura","SetSkillAura")
        dropdown("Auto Skill","SelectedSkill","Skill",function()return {Options=state.SkillChoices or {},Value=state.SelectedSkill}end,function(name)if name and name~=state.SelectedSkill then action("SetSelectedSkill",name)end end)
        section("Auto Skill","MiscSkillSection","Misc Skill");toggle("Auto Skill","MiscSkillEnabled","Misc Skill","SetMiscSkillEnabled")
        dropdown("Auto Skill","SelectedMiscSkill","Skill",function()
            local options={};for _,skill in ipairs(state.MiscSkillChoices or {})do if skill.Usable then options[#options+1]=skill.Name end end
            return {Options=options,Value=state.SelectedMiscSkill}
        end,function(name)if name and name~=state.SelectedMiscSkill then action("SetMiscSkill",name)end end)
        for _,name in ipairs({"Dismantle","Upgrade","The Forge"})do button("Misc","Open"..name,name,function()action("OpenGameMenu",name)end)end
        dropdown("Player","SelectedPlayer","Select player",function()
            local options,map,value={},{},nil
            for _,person in ipairs(state.PlayerTools.Choices())do local label=person.DisplayName.." (@"..person.Name..")";options[#options+1]=label;map[label]=person.UserId;if person.UserId==state.SelectedPlayerId then value=label end end
            return {Options=options,Map=map,Value=value}
        end,function(label,map)if map[label]then state.PlayerTools.Select(map[label])end end)
        button("Player","TeleportPlayer","TP to player",function()state.PlayerTools.Teleport()end)
        register("Player",{Kind="Toggle",Key="ViewingPlayer",Title="View player",Read=function()return state.ViewingPlayer==true end,Write=function(on)state.PlayerTools.SetViewing(on)end})
        register("Player",{Kind="Toggle",Key="ViewingPlayerInventory",Title="View player inventory",Read=function()return state.ViewingPlayerInventory==true end,Write=function(on)state.PlayerTools.SetInventoryVisible(on)end})
        toggle("Utility","AtheonUnlock","Atheon Unlock","SetAtheonUnlock")
        section("Utility","PerformanceBoosterSection","Perfromance Booster")
        dropdown("Utility","PerformanceBoosters","Performance boosters",function()
            local values={};for _,name in ipairs(boostNames)do if state.PerformanceBoosters[name]then values[#values+1]=name end end
            return {Options=boostNames,Value=values}
        end,function(values)
            local picked=selection(values)
            for _,name in ipairs(boostNames)do if (state.PerformanceBoosters[name]==true)~=(picked[name]==true)then action("SetPerformanceBoost",name,picked[name]==true)end end
        end,true)
        section("Utility","AutoDismantleSection","Auto Dismantle")
        local rarities={"Common","Uncommon","Rare"}
        dropdown("Utility","AutoDismantle","Auto Dismantle",function()
            local values={};for _,name in ipairs(rarities)do if state.AutoDismantle[name]then values[#values+1]=name end end
            return {Options=rarities,Value=values}
        end,function(values)local picked=selection(values);for _,name in ipairs(rarities)do if (state.AutoDismantle[name]==true)~=(picked[name]==true)then action("SetAutoDismantle",name,picked[name]==true)end end end,true)
        section("Utility","AutoCraftSection","Auto Craft")
        local recipes={"Uncommon → Rare","Rare → Legendary"};local recipeMap={[recipes[1]]="Rare Upgrade Crystal",[recipes[2]]="Legendary Upgrade Crystal"}
        dropdown("Utility","AutoCraft","Auto Craft",function()return {Options=recipes,Map=recipeMap,Value=chosen(recipes,recipeMap,function(name)return state.AutoCraft and state.AutoCraft[name]==true end)}end,
            function(values,map)local picked={};for _,label in ipairs(values or {})do if map[label]then picked[map[label]]=true end end;action("SetAutoCraft",picked)end,true)
        section("Utility","AutoTradeSection","Auto Trade");toggle("Utility","AutoTrade","Auto Trade","SetAutoTrade","Only Accept Trade From Safe Mod Whitelist List")
        dropdown("Utility","TradeMode","Mode",function()return {Options={"Selected items","Legendary+"},Value=state.TradeMode=="Legendary"and "Legendary+"or "Selected items"}end,function(label)action("SetTradeMode",label=="Legendary+"and "Legendary"or "Selected")end)
        dropdown("Utility","TradeItems","Inventory",function()
            local options,map={},{}
            for _,item in ipairs(state.GetTradeItemChoices())do local label=item.Name.." x"..item.Count;options[#options+1]=label;map[label]=item.Name end
            return {Options=options,Map=map,Value=chosen(options,map,function(name)return state.TradeItems[name]==true end)}
        end,function(values,map)local picked={};for _,label in ipairs(values or {})do if map[label]then picked[map[label]]=true end end;action("SetTradeItems",picked)end,true)
        toggle("Speacial","AccountProgression","Account Progression","SetAccountProgression")
        button("Speacial","ResetSavedProgression","Reset Saved Progression",function()action("ResetSavedProgression")end)
        section("Speacial","AntiSuspiciousSection","Anti Suspicious")
        toggle("Speacial","AntiSuspicious","Anti Suspicious","SetAntiSuspicious")
        local limits=state.AntiSuspiciousLimits or {Hops=10,Window=10,Min=40,Max=60}
        for _,setting in ipairs({{"Hops","Rejoin Limit",100},{"Window","Track (min)",200}})do
            local key,title,maximum=table.unpack(setting)
            register("Speacial",{Kind="Slider",Key="AntiSuspicious"..key,Title=title,Maximum=maximum,
                Read=function()return limits[key]end,
                Write=function(value)action("SetAntiSuspiciousLimit",key,value)end})
        end
        register("Speacial",{Kind="RangeSlider",Key="AntiSuspiciousRest",Title="Rest Time (min)",Minimum=1,Maximum=200,
            Value=limits,Write=function(minimum,maximum)action("SetAntiSuspiciousLimit","Rest",minimum,maximum)end})
        paragraph("Speacial","AntiSuspiciousStatus","Rest Status",function()
            local untilAt=state.AntiSuspiciousRestUntil
            if not untilAt then return state.AntiSuspicious and "Watching Safe Mode departures"or "Off"end
            local seconds=math.max(0,untilAt-os.time())
            return seconds>0 and string.format("%d:%02d remaining",math.floor(seconds/60),seconds%60)or "Rest finished · waiting for rejoin"
        end)
        toggle("Dodge","NoSelfDamage","No Self Damage (enemy skills)","SetNoSelfDamage","Blocks the native client-reported enemy-skill DamageSelf path. Server-applied damage can still occur.")
        toggle("Dodge","AeganatosDodge","Aeganatos Dodge","SetAeganatosDodge")
        toggle("Dodge","AtheonDodge","Atheon Dodge","SetAtheonDodge")
        dropdown("Settings","Theme","Theme",function()
            local options={};for name in pairs(ctx.WindUI:GetThemes())do options[#options+1]=name end;table.sort(options)
            return {Options=options,Value=state.Theme or "Dark"}
        end,function(name)if ctx.WindUI:SetTheme(name)then state.Theme=name;if state.SaveNow then state.SaveNow()end end end)
        local prefs=state.PresetPreferences or {Count=0,Manual=0,Outside=0,Between=0}
        local pickedPreset=state.PresetId or 0
        local function presetView(id,empty)
            local options,map={empty},{[empty]=0}
            for index=1,prefs.Count do
                local label="Preset "..index
                options[#options+1]=label;map[label]=index
            end
            return {Options=options,Map=map,Value=id>0 and "Preset "..id or empty}
        end
        local configImport
        configImport=input("Settings","ConfigImport","Config Import","",function(bytes)
            if not bytes:match("%S")then return end
            local id=action("ImportConfig",bytes)
            if type(id)=="number"then
                pickedPreset=id
                state.PresetStatus="Saved as Preset "..id
                cadence.Choices=0;cadence.Cursor=1
                configImport.Syncing=true;configImport.Control:Set("");configImport.Syncing=false
            end
        end)
        button("Settings","ConfigExport","Config Export",function()
            action("ExportConfig")
            if ctx.WindUI.Notify then ctx.WindUI:Notify({Title="Config Export",Content="Copied settings, saved spots, and presets to clipboard",Duration=3})end
        end)
        section("Settings","PresetSection","Presets")
        dropdown("Settings","PresetSelection","Preset",function()return presetView(pickedPreset,"Default")end,
            function(label,map)if map[label]~=nil then pickedPreset=map[label]end end)
        button("Settings","LoadPreset","Load Preset",function()action("LoadPreset",pickedPreset)end)
        toggle("Settings","AutoPreset","Auto Preset","SetAutoPreset")
        for _,option in ipairs({{"Outside","Outside The Between"},{"Between","Inside The Between"}})do
            local route,title=table.unpack(option)
            dropdown("Settings","Preset"..route,title,function()return presetView(prefs[route],"None")end,
                function(label,map)if map[label]~=nil then action("SetPresetRoute",route,map[label])end end)
        end
        paragraph("Settings","PresetStatus","Preset Status",function()
            return state.PresetStatus or (state.PresetId and "Active · Preset "..state.PresetId or "Active · Default")
        end)
        section("Settings","WebhookSection","Webhook")
        local urlInput
        urlInput=input("Settings","WebhookUrl","Discord Webhook URL","",function(url)
            if not url:match("%S")then return end
            urlInput.Syncing=true;urlInput.Control:Set("");urlInput.Syncing=false
            action("SetWebhookUrl",url)
        end)
        toggle("Settings","WebhookEnabled","Reward Webhook","SetWebhookEnabled")
        dropdown("Settings","WebhookRarities","Reward Rarities",function()
            local options,picked=state.GetWebhookRarities()
            local values={}
            for _,rarity in ipairs(options)do if picked[rarity]then values[#values+1]=rarity end end
            return {Options=options,Value=values}
        end,function(values)action("SetWebhookRarities",selection(values))end,true)
        toggle("Settings","WebhookHidePlayer","Hide Player Name","SetWebhookHidePlayer")
        button("Settings","TestWebhook","Send Test",function()action("TestWebhook")end)
        button("Settings","ClearWebhookUrl","Clear URL",function()action("ClearWebhookUrl")end)
        paragraph("Settings","WebhookStatus","Webhook Status",function()return state.GetWebhookStatus()end)
    end
    function synchronize(projection,choices)
        local definition=projection.Definition
        if definition.Kind=="Toggle"then
            local value=definition.Read();if value~=projection.Value then projection.Value=value;projection.Control:Set(value,false)end
        elseif definition.Kind=="Paragraph"then
            local text=tostring(definition.Read()or "");if text~=projection.Text then projection.Text=text;projection.Control:SetDesc(text)end
        elseif definition.Kind=="Dropdown"and choices then
            local view=definition.Read();local options=signature(view.Options);local value=signature(view.Value,definition.Ordered)
            local changed=projection.Options~=options
            projection.Syncing=true;projection.Map=view.Map or {};projection.Current=value
            if changed then projection.Options=options;projection.Control:Refresh(view.Options)end
            if changed or projection.Value~=value then projection.Value=value;projection.Control:Select(view.Value)end
            projection.Syncing=false
        end
    end
    function api.Update(stamp)
        if not valid()or stamp<cadence.Next then return end
        cadence.Next=stamp+.25;memory.Update();state.UIReferencesPruned=memory.Pruned
        local current=window.CurrentTab and order[window.CurrentTab]
        if current then state.UI.ActiveTab=current end
        if current~=cadence.Tab then cadence.Tab=current;cadence.Choices=0;cadence.Cursor=1 end
        if not api.Visible then return end
        if current=="Settings" and stamp>=(cadence.Presets or 0) and state.RefreshPresetPreferences then
            cadence.Presets=stamp+1
            state.RefreshPresetPreferences()
        end
        for _,projection in ipairs(projections)do if projection.Tab==current and projection.Definition.Kind~="Dropdown"then synchronize(projection,false)end end
        if stamp<cadence.Choices then return end
        while cadence.Cursor<=#projections do
            local projection=projections[cadence.Cursor];cadence.Cursor+=1
            if projection.Tab==current and projection.Definition.Kind=="Dropdown"then
                synchronize(projection,true)
                if ctx.Defer then break end
            end
        end
        if cadence.Cursor>#projections then cadence.Cursor=1;cadence.Choices=stamp+1 else cadence.Choices=stamp+.25 end
    end
    function api.Destroy()
        if lifetime.Closed then return end
        lifetime.Closed=true;api.Ready=false;api.BackgroundReady=false
        local errors={}
        local function attempt(fn,...)
            local ok,reason=pcall(fn,...);if not ok then errors[#errors+1]=tostring(reason)end
        end
        for _,projection in ipairs(projections)do if projection.Cleanup then attempt(projection.Cleanup)end end
        attempt(ctx.Visibility,false);attempt(function()window:Destroy()end)
        if memory.Destroy then attempt(memory.Destroy)end
        if ctx.DestroyRoots then attempt(ctx.DestroyRoots)end
        if #errors>0 then state.UICleanupErrors=errors end
        table.clear(projections)
    end
    local savedTab=state.UI.ActiveTab or "Main"
    if savedTab=="Challenge Floors"then savedTab=wavesTab end
    tab(1);main()
    local function background()
        if not valid()then return end
        local ok,reason=pcall(function()
            for index=2,#order do tab(index)end
            rest();api.BackgroundReady=true
            state.WindUIReadySeconds=state.WindUIStartedAt and os.clock()-state.WindUIStartedAt or nil
            if window.CurrentTab==1 and api.Tabs[savedTab]then api.Tabs[savedTab]:Select()end
        end)
        if not ok and valid()then fail(reason)end
    end
    if ctx.Defer then ctx.Defer(background)else background()end
    api.Ready=true
    local active=api.Tabs[savedTab]or api.Tabs.Main;active:Select()
    api.Update(0)
    return api
end
