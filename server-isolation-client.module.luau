-- Roblox/executor adapter. No credentials, web sessions, or block-list HTTP calls.
return function(ctx)
    local state, player, Players = ctx.State, ctx.Player, ctx.Players
    if type(state.SafeWhitelistText)~="string" then state.SafeWhitelistText="" end
    if type(state.SafeWhitelistIds)~="table" then state.SafeWhitelistIds={} end
    if type(state.MultiSpotSelected)~="table" then state.MultiSpotSelected={} end
    local HttpService, StarterGui = game:GetService("HttpService"), game:GetService("StarterGui")
    local TeleportService = game:GetService("TeleportService")
    local path = "SB2Codex/solo-search_" .. tostring(player.UserId) .. ".json"
    local queuedResume = getgenv().SB2SoloResumeTicket
    getgenv().SB2SoloResumeTicket = nil
    local queue, savedSource
    local GuiService = game:GetService("GuiService")
    -- Optional desktop input must not prevent Multi Spot / autosave on mobile.
    local virtualInput
    pcall(function()virtualInput=game:GetService("VirtualInputManager")end)
    local blockPoint=ctx.BlockPoint or function(button,inset)
        return button.AbsolutePosition+button.AbsoluteSize/2+inset
    end
    local function workerIdentity()
        -- Some mobile executors expose this function but reject identity changes.
        if type(setthreadidentity)=="function" then pcall(setthreadidentity,8) end
    end
    local ui
    local profile=game.ReplicatedStorage.Profiles:FindFirstChild(player.Name)
    local catalog=ctx.MakeCatalog({Floors=require(game.ReplicatedStorage.Database.Locations).floors,
        Unlocked=function(floor)return floor.Unlocked==true or (profile and profile.Locations:FindFirstChild(tostring(floor.PlaceId)))~=nil end})
    catalog.AddCurrent(state.FloorDestinations,game.PlaceId);catalog.Sort()
    state.MultiSpotSelected=catalog.NormalizeSelection(state.MultiSpotSelected)
    state.MultiSpotCursor=catalog.Aliases[state.MultiSpotCursor] or state.MultiSpotCursor
    state.MultiSpotPending=catalog.Aliases[state.MultiSpotPending] or state.MultiSpotPending
    state.AutomationCatalog=catalog
    function state.IsAutomationFloorUnlocked(id)
        local floor=catalog.FloorById[id]
        if not floor then return false end
        floor.Unlocked=floor.Unlocked==true or (profile and profile.Locations:FindFirstChild(tostring(id)))~=nil
        return floor.Unlocked
    end
    local function refresh() if ui then ui.Refresh() end end
    state.RefreshAutomationUI=refresh
    local function snapshot()return {Enabled=state.Enabled,AutoFarm=state.AutoFarm,SkillAura=state.SkillAura}end
    local function restoreFeatures(features)
        if type(features)~="table" or not state.Running then return end
        if type(features.AutoFarm)=="boolean" then state.SetAutoFarm(features.AutoFarm) end
        if type(features.Enabled)=="boolean" then state.SetEnabled(features.Enabled) end
        if type(features.SkillAura)=="boolean" then state.SetSkillAura(features.SkillAura) end
    end
    local function allowed(person)return person==player or state.SafeWhitelistIds[tostring(person.UserId)]==true end
    local function others()
        local result={};for _,person in ipairs(Players:GetPlayers()) do if person~=player then result[#result+1]=person end end
        return result
    end
    local function save(ticket)
        if state.StorageBootstrap then local ready,reason=state.StorageBootstrap.Ensure();assert(ready,reason)end
        writefile(path, HttpService:JSONEncode(ticket))
        return true
    end
    local function readTicket()
        if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" or not isfile(path) then return end
        local raw = readfile(path)
        assert(#raw < 16384, "Solo-search state exceeds its size limit")
        return HttpService:JSONDecode(raw)
    end
    local nativeBlockedEvents,blockEventsBound={},false
    local function bindBlockEvents()
        if blockEventsBound then return end
        local blockedOK,blockedEvent=pcall(StarterGui.GetCore,StarterGui,"PlayerBlockedEvent")
        local unblockedOK,unblockedEvent=pcall(StarterGui.GetCore,StarterGui,"PlayerUnblockedEvent")
        if not blockedOK or not unblockedOK then return end
        local function id(person)return typeof(person)=="Instance"and person.UserId or tonumber(person)end
        ctx.Bind(blockedEvent.Event,function(person)local userId=id(person);if userId then nativeBlockedEvents[userId]=true end end)
        ctx.Bind(unblockedEvent.Event,function(person)local userId=id(person);if userId then nativeBlockedEvents[userId]=nil end end)
        blockEventsBound=true
    end
    local function getBlocked()
        bindBlockEvents()
        local ids = StarterGui:GetCore("GetBlockedUserIds")
        assert(type(ids) == "table", "Blocked-user list is unavailable")
        local result = {}
        for _, id in ipairs(ids) do result[tonumber(id)] = true end
        for id in pairs(nativeBlockedEvents)do result[id]=true end
        return result
    end
    local function queuePreflight()
        if state.StorageBootstrap then local ready,reason=state.StorageBootstrap.Ensure();assert(ready,reason)end
        assert(typeof(readfile) == "function" and typeof(writefile) == "function" and typeof(isfile) == "function",
            "File access is required to resume after rejoining")
        queue = queue_on_teleport or queueonteleport
            or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        assert(typeof(queue) == "function", "This executor has no queue_on_teleport support")
        assert(isfile(state.SavedScriptPath), "Automatic source installation failed: " .. state.SavedScriptPath)
        savedSource = readfile(state.SavedScriptPath)
        assert(string.find(savedSource, state.Build, 1, true)
            and string.find(savedSource, "-- BEGIN BUNDLED SERVER ISOLATION", 1, true),
            "The executor's saved script could not be refreshed automatically")
        assert(loadstring(savedSource), "The saved script does not compile")
    end
    local function preflight()
        queuePreflight()
        assert(virtualInput and typeof(virtualInput.SendMouseButtonEvent) == "function", "Automatic prompt input is unavailable")
        getBlocked() -- Refuse to add blocks if we cannot verify them afterward.
        if not isfile(path) then save({Version=1, Active=false}) end
    end
    local function findPrompt(target)
        local CoreGui = game:GetService("CoreGui")
        assert(CoreGui, "The search worker cannot access Roblox's block dialog")
        -- FoundationOverlay names can be duplicated. Inspect each actual overlay,
        -- then bind the observed Title/AlertContents/Footer structure to this user.
        for _, overlay in ipairs(CoreGui:GetChildren()) do
            if overlay.Name == "FoundationOverlay" and overlay:IsA("ScreenGui") and overlay.Enabled then
                for _, title in ipairs(overlay:QueryDescendants("TextLabel")) do
                    if title.Name == "Title" and title.Visible then
                        local contents = title.Parent and title.Parent.Parent and title.Parent.Parent.Parent
                        local modal = contents and contents.Parent
                        if contents and contents.Name == "AlertContents" and modal and modal.Name == "AlertModal"
                            and modal.Parent and modal.Parent.Name == "BlockingModal" then
                            local footer = contents:FindFirstChild("Footer")
                            local buttons = footer and footer:FindFirstChild("Buttons")
                            local confirm = buttons and buttons:FindFirstChild("3")
                            local cancel = buttons and buttons:FindFirstChild("1")
                            local report = buttons and buttons:FindFirstChild("2")
                            local matches = string.find(title.Text, target.DisplayName, 1, true)
                                or string.find(title.Text, target.Name, 1, true)
                            if matches and confirm and cancel and report
                                and confirm:IsA("GuiButton") and confirm.LayoutOrder == 0
                                and cancel.LayoutOrder == 2 and report.LayoutOrder == 1 then
                                return confirm, cancel
                            end
                            error("Another or unsupported Roblox block dialog is open")
                        end
                    end
                end
            end
        end
    end
    local function click(button)
        assert(button.Visible and button.Active and button.AbsoluteSize.X > 0, "Block dialog is not ready")
        local point=blockPoint(button,GuiService:GetGuiInset())
        virtualInput:SendMouseMoveEvent(point.X, point.Y, game)
        virtualInput:SendMouseButtonEvent(point.X, point.Y, 0, true, game, 0)
        task.wait(.03)
        virtualInput:SendMouseButtonEvent(point.X, point.Y, 0, false, game, 0)
    end
    local block
    if ctx.MakeBlockConfirm then
        block=ctx.MakeBlockConfirm({Find=findPrompt,Prompt=function(target)StarterGui:SetCore("PromptBlockPlayer",target)end,
            Ready=function(button)return button.Visible and button.Active and button.AbsoluteSize.X>0 end,
            Key=function(button)return tostring(button.AbsolutePosition).."/"..tostring(button.AbsoluteSize)end,
            Click=click,Now=os.clock,Sleep=task.wait,
            Blocked=function(target)return getBlocked()[target.UserId]==true end,
            Settle=function()return math.clamp((state.PingMs or 100)/1000+.05,.15,.75)end})
    else
        block=function(target,active)
        local confirm = findPrompt(target)
        if not active() then return false end
        if not confirm then StarterGui:SetCore("PromptBlockPlayer", target) end
        local deadline = os.clock() + 8
        local cancel
        repeat
            confirm, cancel = findPrompt(target)
            if not active() then if cancel then click(cancel) end; return false end
            if confirm then break end
            task.wait(.05)
        until os.clock() >= deadline
        assert(confirm, "Roblox block dialog did not open; no rejoin attempted")
        if not active() then if cancel then click(cancel) end; return false end
        click(confirm) -- Only the block button; the adjacent report button is excluded.
        local confirmedAt
        deadline = os.clock() + 10
        repeat
            if not active() then return false end
            if getBlocked()[target.UserId] then
                confirmedAt = confirmedAt or os.clock()
                if os.clock() - confirmedAt >= math.clamp((state.PingMs or 100)/1000+.05,.15,.75) then return true end
            else confirmedAt = nil end
            task.wait(.05)
        until os.clock() >= deadline
        error("Roblox did not confirm the block; no rejoin attempted")
    end
    end
    local blockBusy=false
    local function performBlock(target,active)
        local deadline=os.clock()+10
        while blockBusy do
            if not active()then return false end
            assert(os.clock()<deadline,"Another native block confirmation is still active")
            task.wait(.04)
        end
        if not active()then return false end
        blockBusy=true
        local ok,result=pcall(block,target,active)
        blockBusy=false
        if not ok then error(result)end
        return result==true
    end
    function state.BlockPlayerNative(target,active)
        workerIdentity()
        if not active()then return false end
        if getBlocked()[target.UserId]then return true end
        assert(virtualInput and typeof(virtualInput.SendMouseButtonEvent)=="function","Automatic block confirmation input is unavailable")
        return performBlock(target,active)
    end
    local queuedToken
    function state.QueueAutomation()
        queuePreflight()
        if queuedToken and queuedToken==state.AutomationRunId then return end
        state.AutomationRunId=state.AutomationRunId or HttpService:GenerateGUID(false)
        state.AutomationResumeFeatures=snapshot()
        assert(state.SaveNow(),"Could not save automation settings")
        local code=string.format([[
if not game:IsLoaded() then game.Loaded:Wait() end
local p=game:GetService("Players").LocalPlayer
while not p do task.wait();p=game:GetService("Players").LocalPlayer end
local h=game:GetService("HttpService")
local ok,c=pcall(function()return h:JSONDecode(readfile(%q))end)
if ok and type(c)=="table" and c.AutomationRunId==%q and (c.SafeMode==true or c.MultiSpot==true or c.AccountProgression==true)
    and game.GameId==%s then
    local old=getgenv().SB2KillAura
    if not (old and old.Running and old.AutomationLoadedJob==game.JobId and old.AutomationRunId==c.AutomationRunId) then
        local source=readfile(%q)
        if string.find(source,%q,1,true) then
            getgenv().SB2AutomationResumeFeatures=c.AutomationResumeFeatures
            local valid,t=pcall(function()return h:JSONDecode(readfile(%q))end)
            if valid and type(t)=="table" and t.Active==true and t.UserId==p.UserId and t.PlaceId==game.PlaceId then
                getgenv().SB2SoloResumeTicket=t
            end
            assert(loadstring(source))()
        end
    end
end
]],state.ConfigPath,state.AutomationRunId,tostring(game.GameId),state.SavedScriptPath,state.Build,path)
        queue(code);queuedToken=state.AutomationRunId
    end
    local function fail(message)
        state.AutomationTeleporting=false
        if state.SoloServerSearch and state.SoloServerSearch.Active then state.SoloServerSearch.Stop("Automation stopped") end
        if state.MultiSpotController then state.MultiSpotController.Pause(tostring(message)) end
        if state.AccountProgression and state.ProgressionController then state.ProgressionController.Pause(message) end
        if state.SafeMode and state.SafeController then state.SafeController.Pause(message)
        elseif state.ReleaseSafePanic then state.ReleaseSafePanic() end
        state.SafeModeStatus=tostring(message);state.MultiSpotStatus=tostring(message)
        state.SaveNow();refresh()
    end
    function state.ChangeAutomationFloor(placeId)
        if state.AutomationTeleporting then return true end
        local floor=catalog.FloorById[placeId]
        if not floor or not state.IsAutomationFloorUnlocked(placeId) then
            local reason="Selected floor is locked or unavailable"
            state.LastFloorTravelError=reason;fail(reason);return false,reason
        end
        local ownedByProgression=state.AccountProgression==true
        state.FloorTravelAttempt=0
        local ok,message=pcall(function()
            assert(state.PanicToSpawn(),"Wait for a living character at the teleport pad")
            state.QueueAutomation()
            state.AutomationTeleporting=true;state.AutomationTeleportDeadline=os.clock()+45
            -- Give the pad position time to replicate. A live .5-second retry
            -- succeeded after the previous .2-second first request was rejected.
            for attempt=1,2 do
                task.wait(math.clamp((state.PingMs or 100)/1000+.25,.5,1))
                assert(state.Running and not state.StopEverything and state.AutomationTeleporting,"Floor travel cancelled")
                assert(not ownedByProgression or state.AccountProgression,"Account Progression stopped")
                assert(state.PanicToSpawn(),"Wait for a living character at the teleport pad")
                state.FloorTravelAttempt=attempt
                local result=game.ReplicatedStorage.Function:InvokeServer("Teleport",{"Teleport",placeId})
                if result==nil or result==""then return end
                if attempt==2 then error(tostring(result))end
            end
        end)
        state.LastFloorTravelError=not ok and tostring(message)or nil
        if not ok then fail(message) end
        return ok,state.LastFloorTravelError
    end
    local api=ctx.Make({
        UserId=player.UserId,PlaceId=game.PlaceId,JobId=game.JobId,Now=os.time,Clock=os.clock,
        SettleSeconds=.15,SoloSeconds=.3,BlockSettleSeconds=0,
        NewId=function()return HttpService:GenerateGUID(false)end,Random=function(count)return math.random(1,count)end,
        Preflight=preflight,Save=save,GetBlocked=getBlocked,SnapshotSettings=snapshot,RestoreSettings=restoreFeatures,
        GetPlayers=others,IsAllowed=allowed,IsFriend=function()return false end,
        ChooseTarget=function(candidates)
            for _,target in ipairs(candidates) do if target.UserId==state.SafePendingUserId then return target end end
            return candidates[math.random(1,#candidates)]
        end,
        IsPresent=function(target)return target.Parent==Players end,
        Block=function(target,active)
            local started=os.clock()
            local result=performBlock(target,active)
            state.LastSafeBlockSeconds=os.clock()-started
            local search=state.SoloServerSearch
            if search and search.Ticket then search.Ticket.LastBlockSeconds=state.LastSafeBlockSeconds end
            return result
        end,
        Queue=function()state.QueueAutomation()end,
        Hop=function()
            state.AutomationTeleporting=true;state.AutomationTeleportDeadline=os.clock()+40
            TeleportService:Teleport(game.PlaceId,player)
        end,
        Notify=function(search)
            state.SoloServerStatus=search.Status
            if state.SafeMode then state.SafeModeStatus=search.Status end
            refresh()
        end,
    })
    state.SoloServerSearch=api
    local safe=ctx.MakeSafe({State=state,Search=api,CurrentFloor=function()return game.PlaceId end,
        TargetFloor=function()return state.AccountProgression and game.PlaceId or state.SafeFloorId end,
        Players=others,Allowed=allowed,ChangeFloor=state.ChangeAutomationFloor,
        Panic=function()state.PanicToSpawn()end,ReleasePanic=function()state.ReleaseSafePanic()end,
        Travelling=function()return state.AutomationTeleporting or state.TravelBusy end,
        Status=function(text)state.SafeModeStatus=text end,Save=state.SaveNow})
    state.SafeController=safe
    local multi=ctx.MakeMulti({State=state,Spots=function()return catalog.Spots end,
        CurrentFloor=function()return game.PlaceId end,ChangeFloor=state.ChangeAutomationFloor,
        CanMove=function()
            if state.AccountProgression or state.ModeratorBlocking then return false end
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            if not root or root.Anchored or not humanoid or humanoid.Health<=0 then return false end
            return not state.AutomationTeleporting and not state.SafeModePanic and not api.Active and not (state.SafeMode and safe.Seeking)
                and not state.TravelBusy and not state.Dodging and not state.Recovering
        end,
        Moving=function()return state.TravelBusy end,
        Arrived=function(spot)
            state.MultiSpotOwnsTravel=false
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local landed=state.LastTravelPosition
            local arrived=spot and root and landed and state.LastTravelDestination==spot.DestinationId
                and (root.Position-landed).Magnitude<=25
            if arrived and state.FinishMultiSpotArrival then state.FinishMultiSpotArrival() end
            return arrived
        end,
        Go=function(spot)
            if state.TravelBusy then return false end
            state.RegisterAutomationDestination(spot)
            state.MultiSpotEmptySince=nil;state.MultiSpotAnchor=spot.Position;state.MultiSpotEncounter={};state.MultiSpotNextScan=0;state.FollowTarget=nil;state.LastTravelDestination=nil
            state.MultiSpotOwnsTravel=true
            return state.TeleportToDestination(spot.DestinationId,false,true)
        end,
        Encounter=function(spot)return state.ReadAutomationEncounter(spot)end,
        ClearEncounter=function()state.MultiSpotEncounter={};state.MultiSpotNextScan=0 end,
        Release=function()
            if state.ArenaFloat then state.ArenaFloat.Release() end
            if state.MultiSpotOwnsTravel and state.TravelBusy then state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false end
            state.MultiSpotEmptySince=nil;state.MultiSpotOwnsTravel=false;state.MultiSpotAnchor=nil;state.MultiSpotEncounter=nil;state.MultiSpotNextScan=0
            state.MultiSpotTravelPending=false
            state.MultiSpotLandingPosition=nil
        end,
        Status=function(text)state.MultiSpotStatus=text end,Save=state.SaveNow})
    state.MultiSpotController=multi
    local function ensureToken()
        if not state.SafeMode and not state.MultiSpot and not state.AccountProgression then
            state.AutomationRunId=HttpService:GenerateGUID(false);queuedToken=nil
        end
    end
    function state.SetSafeMode(on)
        ensureToken();safe.Reset();state.SafeMode=on==true
        if not state.SafeMode then state.ReleaseSafePanic() end
        state.SafeModeStatus=state.SafeMode and "Checking selected floor..." or "Safe Mode is off"
        state.SafePendingUserId=nil;state.SaveNow();refresh()
        if state.SafeMode then task.defer(function()workerIdentity();safe.Update();refresh()end)end
    end
    state.SetSoloServerSearch=state.SetSafeMode
    function state.SetSafeFloor(id)
        if state.AccountProgression then
            state.SafeFloorId=game.PlaceId
            state.SafeModeStatus="Account Progression · protecting the current floor"
            state.SaveNow();refresh();return false
        end
        local floor=catalog.FloorById[tonumber(id)]
        if not floor or not floor.Unlocked then state.SafeModeStatus="That floor is locked";refresh();return false end
        safe.Reset();multi.Reset();state.SafeFloorId=floor.Id;state.SaveNow();refresh()
        if state.SafeMode then
            state.PanicToSpawn()
            task.defer(function()workerIdentity();safe.Update();refresh()end)
        end
        return true
    end
    local whitelistGeneration=0
    function state.SetSafeWhitelist(text)
        text=tostring(text or "");if #text>2000 then state.SafeModeStatus="Whitelist is too long";refresh();return false end
        whitelistGeneration=whitelistGeneration+1;local token=whitelistGeneration
        safe.Reset();state.SafeWhitelistResolving=true
        task.spawn(function()
            local ids,count={},0
            local ok,message=pcall(function()
                for word in text:gmatch("[^,%s;]+") do
                    count=count+1;assert(count<=100,"Use at most 100 whitelist entries")
                    word=word:gsub("^@","")
                    local id=tonumber(word)
                    if not id then id=Players:GetUserIdFromNameAsync(word) end
                    assert(id and id>0 and id%1==0,"Invalid whitelist user: "..word)
                    ids[tostring(id)]=true
                end
            end)
            if token~=whitelistGeneration or not state.Running then return end
            state.SafeWhitelistResolving=false
            if not ok then state.SafeModeStatus="Whitelist was not saved: "..tostring(message);refresh();return end
            state.SafeWhitelistIds=ids;state.SafeWhitelistText=text;safe.Reset()
            if state.UI.SafeWhitelist and not state.UI.SafeWhitelist:IsFocused() then state.UI.SafeWhitelist.Text=text end
            state.SafeModeStatus=state.SafeMode and "Whitelist updated · checking server" or "Whitelist saved"
            state.SaveNow();refresh()
            if state.SafeMode then
                workerIdentity()
                safe.Update();refresh()
            end
        end)
        return true
    end
    function state.SetMultiSpot(on)
        ensureToken();multi.Reset();state.MultiSpot=on==true
        state.MultiSpotStatus=state.MultiSpot and "Starting selected arenas..." or "Multi Spot is off"
        state.SaveNow();refresh()
        if state.MultiSpot and not state.AccountProgression then task.defer(function()workerIdentity();multi.Update(os.clock());refresh()end)end
    end
    function state.SetMultiSpotSelection(id,on)
        id=catalog.Aliases[id] or id
        local spot=catalog.SpotById[id]
        if not spot or not spot.Floor.Unlocked then state.MultiSpotStatus="That arena's floor is locked";refresh();return false end
        state.MultiSpotSelected[id]=on==true or nil;multi.Reset();state.SaveNow();refresh();return true
    end
    local function joinFriendAtPad(id,active)
        state.AutoJoinFriendHolding=true
        local function permitted()
            return active()and not api.Active and not (state.SafeMode and safe.Seeking)
        end
        local ok,result=pcall(function()
            for attempt=1,2 do
                assert(permitted(),"Friend join cancelled for protection or travel")
                assert(state.PanicToSpawn(),"Wait for a living character at the teleport pad")
                task.wait(math.clamp((state.PingMs or 100)/1000+.25,.5,1))
                assert(permitted(),"Friend join cancelled for protection or travel")
                assert(state.PanicToSpawn(),"Teleport pad is unavailable")
                local message=game.ReplicatedStorage.Function:InvokeServer("Teleport",{"FriendTeleport",id})
                if message==nil or message==""then
                    -- Hold through the native transition instead of farming away from the pad.
                    local deadline=os.clock()+5
                    repeat task.wait(.1)until not permitted()or state.ServerTeleportStarted or os.clock()>=deadline
                    return message
                end
                if attempt==2 or not tostring(message):lower():find("teleport pad",1,true)then return message end
            end
        end)
        state.AutoJoinFriendHolding=false
        if state.Running and not state.ModeratorBlocking and not api.Active and not (state.SafeMode and safe.Seeking)then
            state.ReleaseSafePanic()
        end
        if not ok then error(result)end
        return result
    end
    local friend=ctx.MakeFriend({State=state,LocalUserId=player.UserId,Spawn=task.spawn,
        Resolve=function(name)return Players:GetUserIdFromNameAsync(name)end,
        Present=function(id)return Players:GetPlayerByUserId(id)~=nil end,
        Queue=function()
            local queue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
            assert(type(queue)=="function","Executor has no teleport queue support")
            state.SaveNow()
            queue('loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()')
        end,
        Join=joinFriendAtPad})
    state.AutoJoinFriendController=friend
    function state.SetAutoJoinFriend(on)
        state.AutoJoinFriend=on==true;friend.Reset();state.SaveNow();refresh()
    end
    function state.SetJoinFriendUsername(name)
        state.JoinFriendUsername=tostring(name or ""):match("^%s*(.-)%s*$"):gsub("^@", ""):sub(1,20)
        friend.Reset();state.SaveNow();refresh()
    end
    ui=ctx.MakeUI({State=state,Catalog=catalog,Create=ctx.Create,Button=ctx.Button,Label=ctx.Label,
        Bind=ctx.Bind,Corner=ctx.Corner,Reveal=ctx.Reveal,Parent=ctx.Parent})
    ctx.Bind(Players.PlayerAdded,function(person)
        safe.Joined(person)
        task.defer(function()workerIdentity();if state.Running then safe.Update();refresh() end end)
    end)
    ctx.Bind(TeleportService.TeleportInitFailed,function(who,result,message)
        if who==player then state.AutomationTeleporting=false;api.TeleportFailed(message or result.Name);fail(message or result.Name) end
    end)
    ctx.Bind(player.OnTeleport,function(stage)
        if stage==Enum.TeleportState.Started or stage==Enum.TeleportState.InProgress then
            state.ServerTeleportStarted=true
            if state.SafeMode or state.MultiSpot or state.AccountProgression then
                local ok,message=pcall(state.QueueAutomation);if not ok then fail(message) end
            end
        elseif stage==Enum.TeleportState.Failed then state.AutomationTeleporting=false end
    end)
    state.AutomationLoadedJob=game.JobId
    task.spawn(function()
        workerIdentity()
        local features=getgenv().SB2AutomationResumeFeatures
        getgenv().SB2AutomationResumeFeatures=nil
        if features then restoreFeatures(features) end
        local ok,resume=pcall(readTicket);if queuedResume then ok,resume=true,queuedResume end
        if not state.ModeratorBlocking and state.SafeMode and (state.AccountProgression or state.SafeFloorId==game.PlaceId) and ok and type(resume)=="table" and resume.Active==true and resume.PlaceId==game.PlaceId then api.Start(resume) end
        state.SaveNow()
        while state.Running do
            if state.AutomationTeleporting and os.clock()>state.AutomationTeleportDeadline then fail("Floor teleport timed out") end
            local updated,message=pcall(function()
                if state.ModeratorBlocking then return end
                friend.Update(os.clock())
                safe.Update()
                if state.AccountProgression then
                    if state.ProgressionController then state.ProgressionController.Update(os.clock())end
                else multi.Update(os.clock())end
            end)
            if not updated then fail(message) end
            refresh()
            task.wait((api.Active or state.SafeModePanic) and .03 or (state.MultiSpot or state.AccountProgression) and .1 or state.SafeMode and .5 or 1)
        end
    end)
    return api
end
