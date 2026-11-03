return function(ctx)
    local s,catalog=ctx.State,ctx.Catalog
    local safe=ctx.Button("SafeMode","Safe Mode · OFF",200,34)
    local floor=ctx.Button("SafeFloor","Safe Mode floor",210,32)
    local lists={}
    local function list(name,order,height)
        local frame=ctx.Create("ScrollingFrame",{Name=name,Visible=false,LayoutOrder=order,Size=UDim2.new(1,0,0,height),
            BackgroundColor3=Color3.fromRGB(31,33,46),BorderSizePixel=0,ScrollBarThickness=3,
            CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true},ctx.Parent)
        ctx.Corner(frame,8)
        ctx.Create("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},frame)
        lists[#lists+1]=frame;return frame
    end
    local floors=list("SafeFloorOptions",211,170)
    local whiteLabel=ctx.Label("SafeWhitelistHeading","WHITELIST · USERNAMES OR USER IDS",220,16,true)
    local white=ctx.Create("TextBox",{Name="SafeWhitelist",LayoutOrder=230,Size=UDim2.new(1,0,0,40),
        Text=s.SafeWhitelistText,PlaceholderText="username, another_username, 123456",
        ClearTextOnFocus=false,MultiLine=true,TextWrapped=true,Font=Enum.Font.Gotham,TextSize=11,
        TextColor3=Color3.fromRGB(225,228,241),PlaceholderColor3=Color3.fromRGB(125,132,153),
        BackgroundColor3=Color3.fromRGB(38,41,56),BorderSizePixel=0},ctx.Parent)
    ctx.Corner(white,8)
    local safeStatus=ctx.Label("SafeModeStatus","Safe Mode is off",240,40)
    safeStatus.TextWrapped=true;safeStatus.TextTruncate=Enum.TextTruncate.None
    local multi=ctx.Button("MultiSpot","Multi Spot · OFF",300,34)
    local spots=ctx.Button("MultiSpotDropdown","Select boss / mini-boss arenas",310,32)
    local arenas=list("MultiSpotOptions",311,200)
    local multiStatus=ctx.Label("MultiSpotStatus","Multi Spot is off",320,38)
    multiStatus.TextWrapped=true;multiStatus.TextTruncate=Enum.TextTruncate.None
    local hint=ctx.Label("AutomationHint","Multi Spot moves after every mob in the arena is cleared, including regular mobs. Safe Mode limits it to the selected safe floor. Other players may be blocked unless whitelisted.",330,70)
    hint.TextWrapped=true;hint.TextTruncate=Enum.TextTruncate.None
    s.UI.SafeMode=safe;s.UI.SafeFloor=floor;s.UI.SafeFloorOptions=floors;s.UI.SafeWhitelist=white
    s.UI.SafeModeStatus=safeStatus;s.UI.MultiSpot=multi;s.UI.MultiSpotDropdown=spots;s.UI.MultiSpotOptions=arenas
    s.UI.MultiSpotStatus=multiStatus
    local join=ctx.Button("AutoJoinFriend","Auto Join Friend · OFF",340,34)
    local username=ctx.Create("TextBox",{Name="JoinFriendUsername",LayoutOrder=350,Size=UDim2.new(1,0,0,34),
        Text=s.JoinFriendUsername or "",PlaceholderText="Friend's Roblox username",ClearTextOnFocus=false,
        Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.fromRGB(225,228,241),
        PlaceholderColor3=Color3.fromRGB(125,132,153),BackgroundColor3=Color3.fromRGB(38,41,56),BorderSizePixel=0},ctx.Parent)
    ctx.Corner(username,8)
    local joinStatus=ctx.Label("AutoJoinFriendStatus","Auto Join Friend is off",360,48)
    joinStatus.TextWrapped=true;joinStatus.TextTruncate=Enum.TextTruncate.None
    s.UI.AutoJoinFriend=join;s.UI.JoinFriendUsername=username;s.UI.AutoJoinFriendStatus=joinStatus
    ctx.Bind(join.Activated,function()s.SetJoinFriendUsername(username.Text);s.SetAutoJoinFriend(not s.AutoJoinFriend)end)
    ctx.Bind(username.FocusLost,function()s.SetJoinFriendUsername(username.Text)end)
    local api={}
    local lastView
    local floorButtons={}
    local function floorLabel(item)
        return (item.Id==s.SafeFloorId and "[x] " or "")..item.Label..(item.Unlocked and "" or " · locked")
    end
    function s.CloseAutomationMenus(except)
        for _,item in ipairs(lists) do if item~=except then item.Visible=false end end
    end
    local function open(frame)
        local nextOpen=not frame.Visible
        s.CloseAutomationMenus(frame)
        if s.SetTravelOpen then s.SetTravelOpen(false) end
        if s.UI.SkillOptions then s.UI.SkillOptions.Visible=false end
        frame.Visible=nextOpen
        if nextOpen then ctx.Reveal(frame) end
    end
    function api.Refresh()
        local count=0;for id,on in pairs(s.MultiSpotSelected) do if on and catalog.SpotById[id] and catalog.SpotById[id].PlaceId==game.PlaceId then count=count+1 end end
        local view=table.concat({tostring(s.SafeMode),tostring(s.MultiSpot),tostring(s.SafeFloorId),
            tostring(s.AutoJoinFriend),tostring(s.AutoJoinFriendStatus),tostring(s.SafeModeStatus),tostring(s.MultiSpotStatus),tostring(count),
            tostring(s.AutomationFloorUnlockVersion)},"|")
        if view==lastView then return end
        lastView=view
        join.Text=s.AutoJoinFriend and "Auto Join Friend · ON" or "Auto Join Friend · OFF"
        join.BackgroundColor3=s.AutoJoinFriend and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        joinStatus.Text=s.AutoJoinFriendStatus or "Auto Join Friend is off"
        safe.Text=s.SafeMode and "Safe Mode · ON" or "Safe Mode · OFF"
        multi.Text=s.MultiSpot and "Multi Spot · ON" or "Multi Spot · OFF"
        safe.BackgroundColor3=s.SafeMode and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        multi.BackgroundColor3=s.MultiSpot and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        local selected=catalog.FloorById[s.SafeFloorId]
        floor.Text="Safe floor · "..(selected and selected.Label or "Select floor")
        safeStatus.Text=s.SafeModeStatus or (s.SafeMode and "Checking server..." or "Safe Mode is off")
        multiStatus.Text=s.MultiSpotStatus or (s.MultiSpot and "Starting arena rotation..." or "Multi Spot is off")
        spots.Text=count>0 and ("Arenas · "..count.." selected") or "Select boss / mini-boss arenas"
        for _,item in ipairs(catalog.Floors)do
            local button=floorButtons[item.Id]
            if button then
                local text=floorLabel(item)
                if button.Text~=text then button.Text=text end
            end
        end
    end
    local function refreshFloors()
        for _,child in ipairs(floors:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
        floorButtons={}
        for i,item in ipairs(catalog.Floors) do
            s.IsAutomationFloorUnlocked(item.Id)
            local button=ctx.Button("SafeFloor"..i,floorLabel(item),i,30,floors)
            floorButtons[item.Id]=button
            button.Font=Enum.Font.Gotham;button.TextSize=11
            ctx.Bind(button.Activated,function() s.SetSafeFloor(item.Id);floors.Visible=false;api.Refresh() end)
        end
    end
    local function refreshSpots()
        catalog.AddCurrent(s.FloorDestinations,game.PlaceId);catalog.Sort()
        s.MultiSpotSelected=catalog.NormalizeSelection(s.MultiSpotSelected)
        for _,child in ipairs(arenas:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
        for i,item in ipairs(catalog.Spots) do
            if item.PlaceId==game.PlaceId then
            local label=item.Kind.." · "..item.Name
            local button=ctx.Button("MultiSpot"..i,(s.MultiSpotSelected[item.Id] and "[x] " or "[ ] ")..label,i,30,arenas)
            button.Font=Enum.Font.Gotham;button.TextSize=11
            ctx.Bind(button.Activated,function()
                s.SetMultiSpotSelection(item.Id,not s.MultiSpotSelected[item.Id])
                button.Text=(s.MultiSpotSelected[item.Id] and "[x] " or "[ ] ")..label;api.Refresh()
            end)
            end
        end
    end
    ctx.Bind(safe.Activated,function()s.SetSafeMode(not s.SafeMode)end)
    ctx.Bind(multi.Activated,function()s.SetMultiSpot(not s.MultiSpot)end)
    ctx.Bind(floor.Activated,function()refreshFloors();open(floors)end)
    ctx.Bind(spots.Activated,function()refreshSpots();open(arenas)end)
    ctx.Bind(white.FocusLost,function()s.SetSafeWhitelist(white.Text)end)
    api.Refresh()
    return api
end
