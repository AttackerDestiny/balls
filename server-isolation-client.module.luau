-- Native Roblox/executor boundary for safe search, floor travel and arena rotation.
return function(ctx)
    local state,player,Players=ctx.State,ctx.Player,ctx.Players
    local betweenId=78945654064532
    local inBetween=game.PlaceId==betweenId
    local function waitingForBetween()
        return not inBetween and not state.AccountProgression and state.SafeFloorId==betweenId
    end
    local farmClock=state.FarmClock or os.clock
    state.SafeWhitelistText=type(state.SafeWhitelistText)=="string"and state.SafeWhitelistText or ""
    state.SafeWhitelistIds=type(state.SafeWhitelistIds)=="table"and state.SafeWhitelistIds or {}
    state.MultiSpotSelected=type(state.MultiSpotSelected)=="table"and state.MultiSpotSelected or {}
    state.MultiSpotOrder=type(state.MultiSpotOrder)=="table"and state.MultiSpotOrder or {}
    local HttpService=game:GetService("HttpService")
    local StarterGui=game:GetService("StarterGui")
    local TeleportService=game:GetService("TeleportService")
    local GuiService=game:GetService("GuiService")
    local path="SB2Codex/solo-search_"..player.UserId..(state.PresetId and "_shared-preset_"..state.PresetId or "")..".json"
    local queuedResume=getgenv().SB2SoloResumeTicket
    getgenv().SB2SoloResumeTicket=nil
    local queue,savedSource,validatedSource,validatedPath,validatedGeneration
    local virtualInput
    pcall(function()virtualInput=game:GetService("VirtualInputManager")end)
    local blockPoint=ctx.BlockPoint
    local touchEnabled=false
    local inputService=game:GetService("UserInputService")
    pcall(function()touchEnabled=inputService.TouchEnabled end)
    local function supportsInput(name)
        local ok,method=pcall(function()return virtualInput and virtualInput[name]end)
        return ok and type(method)=="function"
    end
    local canMouse=supportsInput("SendMouseButtonEvent")
    local canTouch=touchEnabled and supportsInput("SendTouchEvent")
    local fireActivation=type(firesignal)=="function" and firesignal or nil
    local function requireBlockInput()
        assert(canMouse or canTouch or fireActivation,"Automatic block confirmation input is unavailable")
    end
    local function workerIdentity()
        if type(setthreadidentity)=="function"then pcall(setthreadidentity,8)end
    end
    local ui
    local definitions=require(game.ReplicatedStorage.Database.Locations).floors
    local nativeFloors={}
    for _,floor in ipairs(definitions)do nativeFloors[floor.PlaceId]=floor end
    local function floorUnlocked(floor)
        if floor.PlaceId==game.PlaceId or floor.PlaceId==betweenId or floor.Unlocked==true then return true end
        local profile=game.ReplicatedStorage.Profiles:FindFirstChild(player.Name)
        local locations=profile and profile:FindFirstChild("Locations")
        return locations~=nil and locations:FindFirstChild(tostring(floor.PlaceId))~=nil
    end
    local catalog=ctx.MakeCatalog({Floors=definitions,Unlocked=floorUnlocked})
    catalog.AddCurrent(state.FloorDestinations,game.PlaceId);catalog.Sort()
    state.MultiSpotSelected=catalog.NormalizeSelection(state.MultiSpotSelected)
    state.MultiSpotCursor=catalog.Aliases[state.MultiSpotCursor]or state.MultiSpotCursor
    state.MultiSpotPending=catalog.Aliases[state.MultiSpotPending]or state.MultiSpotPending
    state.AutomationCatalog=catalog
    function state.IsAutomationFloorUnlocked(id)
        local key=tonumber(id)
        local floor=catalog.FloorById[key]
        if not floor or not nativeFloors[key]then return false end
        local unlocked=floorUnlocked(nativeFloors[key])
        if floor.Unlocked~=unlocked then
            floor.Unlocked=unlocked
            state.AutomationFloorUnlockVersion=(state.AutomationFloorUnlockVersion or 0)+1
        end
        return unlocked
    end
    local function refresh()if ui then ui.Refresh()end end
    state.RefreshAutomationUI=refresh
    local function refreshUnlocks()
        for _,floor in ipairs(catalog.Floors)do state.IsAutomationFloorUnlocked(floor.Id)end
        refresh()
    end
    local profile=game.ReplicatedStorage.Profiles:FindFirstChild(player.Name)
    local locations=profile and profile:FindFirstChild("Locations")
    if locations then ctx.Bind(locations.ChildAdded,refreshUnlocks);ctx.Bind(locations.ChildRemoved,refreshUnlocks)end
    local function snapshot()return {Enabled=state.Enabled,AutoFarm=state.AutoFarm,SkillAura=state.SkillAura}end
    local function restoreFeatures(features)
        if not state.Running or type(features)~="table"then return end
        local setters={AutoFarm=state.SetAutoFarm,Enabled=state.SetEnabled,SkillAura=state.SetSkillAura}
        for _,name in ipairs({"AutoFarm","Enabled","SkillAura"})do
            if type(features[name])=="boolean"then setters[name](features[name])end
        end
    end
    local function allowed(person)return person==player or state.SafeWhitelistIds[tostring(person.UserId)]==true end
    local function others()
        local result={}
        for _,person in ipairs(Players:GetPlayers())do if person~=player then result[#result+1]=person end end
        return result
    end
    local function save(ticket)
        if state.StorageBootstrap then local ready,reason=state.StorageBootstrap.Ensure(true);assert(ready,reason)end
        writefile(path,HttpService:JSONEncode(ticket));return true
    end
    local function readTicket()
        if typeof(isfile)~="function"or typeof(readfile)~="function"or not isfile(path)then return nil end
        local source=readfile(path)
        assert(#source<16384,"Solo-search state exceeds its size limit")
        return HttpService:JSONDecode(source)
    end
    local nativeBlockedEvents,blockEventsBound={},false
    local function bindBlockEvents()
        if blockEventsBound then return end
        local blocked,added=pcall(StarterGui.GetCore,StarterGui,"PlayerBlockedEvent")
        local unblocked,removed=pcall(StarterGui.GetCore,StarterGui,"PlayerUnblockedEvent")
        if not blocked or not unblocked or not added or not removed then return end
        local function identity(value)return typeof(value)=="Instance"and value.UserId or tonumber(value)end
        ctx.Bind(added.Event,function(value)local id=identity(value);if id then nativeBlockedEvents[id]=true end end)
        ctx.Bind(removed.Event,function(value)local id=identity(value);if id then nativeBlockedEvents[id]=nil end end)
        blockEventsBound=true
    end
    local function getBlocked()
        bindBlockEvents()
        local values=StarterGui:GetCore("GetBlockedUserIds")
        assert(type(values)=="table","Blocked-user list is unavailable")
        local membership={}
        for _,value in ipairs(values)do membership[tonumber(value)]=true end
        for id in pairs(nativeBlockedEvents)do membership[id]=true end
        return membership
    end
    local function queuePreflight()
        if state.StorageBootstrap then local ready,reason=state.StorageBootstrap.Ensure();assert(ready,reason)end
        assert(typeof(readfile)=="function"and typeof(writefile)=="function"and typeof(isfile)=="function",
            "File access is required to resume after rejoining")
        queue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)or (fluxus and fluxus.queue_on_teleport)
        assert(typeof(queue)=="function","This executor has no queue_on_teleport support")
        local location=state.SavedScriptPath
        assert(isfile(location),"Automatic source installation failed: "..location)
        local generation=state.StorageBootstrap and state.StorageBootstrap.Generation or 0
        if validatedSource and validatedPath==location and validatedGeneration==generation then return end
        local source=readfile(location)
        assert(source:find(state.Build,1,true)and source:find("-- BEGIN BUNDLED SERVER ISOLATION",1,true),
            "The executor's saved script could not be refreshed automatically")
        if source~=validatedSource then
            assert(loadstring(source),"The saved script does not compile")
            validatedSource=source
        end
        savedSource=source;validatedPath=location;validatedGeneration=generation
    end
    local function preflight()
        queuePreflight()
        requireBlockInput()
        getBlocked()
        if not isfile(path)then save({Version=1,Active=false})end
    end
    local findPrompt=ctx.MakeBlockPrompt and ctx.MakeBlockPrompt({Root=game:GetService("CoreGui"),Targets=function()return Players:GetPlayers()end})or function()
        error("Native block dialog recognition is unavailable; no rejoin attempted")
    end
    local touchId=0
    local function inputPoint(button)
        if not blockPoint then return nil end
        local core=game:GetService("CoreGui")
        return blockPoint(button,GuiService:GetGuiInset(),function(point)
            local ok,objects=pcall(core.GetGuiObjectsAtPosition,core,point.X,point.Y)
            if not ok or type(objects)~="table"then return false end
            for _,object in ipairs(objects)do
                if object==button or object:IsDescendantOf(button)then return true end
                if object:IsA("GuiButton")or object:IsA("GuiObject")and object.Active then return false end
            end
            return false
        end)
    end
    local function click(button,attempt,purpose)
        assert(button.Visible and button.Active and button.AbsoluteSize.X>0,"Block dialog is not ready")
        local point=inputPoint(button)
        assert(point,"Native block button is covered or input coordinates unavailable; no rejoin attempted")
        local diagnostic={Attempt=attempt or 1,Errors={}}
        if purpose=="Cancel"then state.LastBlockCleanupInput=diagnostic else state.LastBlockInput=diagnostic end
        local function calibrate()
            local desired=point
            if not virtualInput or not supportsInput("SendMouseMoveEvent")then return end
            -- Android can add a window offset beyond Roblox's GuiInset. Measure it
            -- with movement only, then verify the correction before pressing anything.
            virtualInput:SendMouseMoveEvent(desired.X,desired.Y,game)
            task.wait(.03)
            local observed=inputService:GetMouseLocation()
            local dx=math.floor(desired.X-observed.X+.5)
            local dy=math.floor(desired.Y-observed.Y+.5)
            assert(math.abs(dx)<=128 and math.abs(dy)<=128,"Native block input calibration is unavailable")
            local corrected=desired+Vector2.new(dx,dy)
            if dx~=0 or dy~=0 then
                virtualInput:SendMouseMoveEvent(corrected.X,corrected.Y,game)
                task.wait(.03)
                local verified=inputService:GetMouseLocation()
                assert(math.abs(verified.X-desired.X)<=2 and math.abs(verified.Y-desired.Y)<=2,
                    "Native block input calibration did not settle")
            end
            local current=inputPoint(button)
            assert(current and math.abs(current.X-desired.X)<=1 and math.abs(current.Y-desired.Y)<=1,
                "Native block button moved during input calibration")
            diagnostic.OffsetX=dx;diagnostic.OffsetY=dy
            point=corrected
        end
        local function touch()
            touchId+=1
            local id=touchId
            local pressed,reason=pcall(function()
                virtualInput:SendTouchEvent(id,Enum.UserInputState.Begin.Value,point.X,point.Y)
                task.wait(.03)
            end)
            local released,releaseReason=pcall(virtualInput.SendTouchEvent,virtualInput,id,Enum.UserInputState.End.Value,point.X,point.Y)
            assert(pressed and released,tostring(reason or releaseReason))
        end
        local function mouse()
            local pressed,reason=pcall(function()
                virtualInput:SendMouseButtonEvent(point.X,point.Y,0,true,game,0)
                task.wait(.03)
            end)
            local released,releaseReason=pcall(virtualInput.SendMouseButtonEvent,virtualInput,point.X,point.Y,0,false,game,0)
            assert(pressed and released,tostring(reason or releaseReason))
        end
        local function activate()fireActivation(button.Activated,nil,1)end
        local function send(name,fn)
            -- Recheck the actual hit target before changing input method.
            point=inputPoint(button)
            assert(point,"Native block button is covered or input coordinates unavailable; no rejoin attempted")
            local ok,reason=pcall(function()
                if name=="Mouse"then calibrate()end
                diagnostic.X=point.X;diagnostic.Y=point.Y
                fn()
            end)
            if ok then diagnostic.Method=name;diagnostic.Dispatched=true;return true end
            diagnostic.Errors[#diagnostic.Errors+1]=name..": "..tostring(reason)
            return false
        end
        attempt=attempt or 1
        local primary=canTouch and attempt==2 and touch or canMouse and mouse or canTouch and touch
        local secondary=primary==touch and canMouse and mouse or primary==mouse and canTouch and touch
        if fireActivation and (attempt==3 or not primary)and send("Activated",activate)then return true end
        if primary and send(primary==touch and "Touch"or "Mouse",primary)then return true end
        if secondary and send(secondary==touch and "Touch"or "Mouse",secondary)then return true end
        if fireActivation and attempt~=3 and primary and send("Activated",activate)then return true end
        error("Automatic block input failed: "..table.concat(diagnostic.Errors," | "))
    end
    local function directBlock(target,active)
        local button,cancel=findPrompt(target)
        if not active()then return false end
        if not button then StarterGui:SetCore("PromptBlockPlayer",target)end
        local deadline=os.clock()+8
        repeat
            button,cancel=findPrompt(target)
            if not active()then if cancel then click(cancel,nil,"Cancel")end;return false end
            if button then break end
            task.wait(.05)
        until os.clock()>=deadline
        assert(button,"Roblox block dialog did not open; no rejoin attempted")
        if not active()then if cancel then click(cancel,nil,"Cancel")end;return false end
        click(button)
        local receipt
        deadline=os.clock()+10
        repeat
            if not active()then return false end
            if getBlocked()[target.UserId]then
                receipt=receipt or os.clock()
                if os.clock()-receipt>=math.clamp((state.PingMs or 100)/1000+.05,.15,.75)then return true end
            else receipt=nil end
            task.wait(.05)
        until os.clock()>=deadline
        error("Roblox did not confirm the block; no rejoin attempted")
    end
    local block=directBlock
    if ctx.MakeBlockConfirm then
        block=ctx.MakeBlockConfirm({Find=findPrompt,Prompt=function(target)StarterGui:SetCore("PromptBlockPlayer",target)end,
            Ready=function(button)return button.Visible and button.Active and button.AbsoluteSize.X>0 and inputPoint(button)~=nil end,
            Key=function(button)return tostring(button.AbsolutePosition).."/"..tostring(button.AbsoluteSize)end,
            Click=click,Now=os.clock,Sleep=task.wait,
            Blocked=function(target)return nativeBlockedEvents[target.UserId]==true or getBlocked()[target.UserId]==true end,
            Settle=function()return 0 end})
    end
    local blockBusy=false
    local maskTarget
    local blockMask=ctx.MakeBlockMask and ctx.MakeBlockMask({Root=game:GetService("CoreGui"),Render=game:GetService("RunService").PreRender,
        Match=function(modal)
            if not maskTarget then return false end
            local button=findPrompt(maskTarget)
            return button~=nil and button:IsDescendantOf(modal)
        end})
    state.BlockDialogMask=blockMask
    local function performBlock(target,active)
        local expires=os.clock()+10
        repeat
            if not active()then return false end
            if not blockBusy then break end
            assert(os.clock()<expires,"Another native block confirmation is still active")
            task.wait(.04)
        until false
        blockBusy=true
        state.LastBlockInput=nil
        state.LastBlockCleanupInput=nil
        maskTarget=target
        local sent,result=pcall(function()
            if blockMask then blockMask.Begin()end
            return block(target,active)
        end)
        if blockMask then
            if not sent or result~=true then pcall(function()local _,cancel=findPrompt(target);if cancel then click(cancel,nil,"Cancel")end end)end
            task.wait(.1)
            local restored,reason=pcall(blockMask.End)
            if not restored then state.LastBlockMaskError=tostring(reason)end
        end
        maskTarget=nil
        blockBusy=false
        if not sent then error(result)end
        return result==true
    end
    function state.BlockPlayerNative(target,active)
        workerIdentity()
        if not active()then return false end
        if getBlocked()[target.UserId]then return true end
        requireBlockInput()
        return performBlock(target,active)
    end
    local queuedToken,queuedAutoPreset
    function state.QueueAutomation()
        if queuedToken==state.AutomationRunId and queuedToken and queuedAutoPreset==state.AutoPreset then return end
        queuePreflight()
        local runId=state.AutomationRunId or HttpService:GenerateGUID(false)
        state.AutomationRunId=runId;state.AutomationResumeFeatures=snapshot()
        assert(state.SaveNow(),"Could not save automation settings")
        local code=string.format([[
if not game:IsLoaded()then game.Loaded:Wait()end
local Players=game:GetService("Players")
local player=Players.LocalPlayer
while not player do task.wait();player=Players.LocalPlayer end
local HttpService=game:GetService("HttpService")
local valid,settings=pcall(function()return HttpService:JSONDecode(readfile(%q))end)
if valid and type(settings)=="table"and settings.AutomationRunId==%q
    and (settings.SafeMode or settings.MultiSpot or settings.AccountProgression or settings.AutoCreateBetween or settings.AutoRegroup or %s)and game.GameId==%s then
    local active=getgenv().SB2KillAura
    if not(active and active.Running and active.AutomationLoadedJob==game.JobId and active.AutomationRunId==settings.AutomationRunId)then
        local source=readfile(%q)
        if source:find(%q,1,true)then
            getgenv().SB2AutomationResumeFeatures=settings.AutomationResumeFeatures
            getgenv().SB2AutomationResumeConfigPath=%q
            if settings.AutoCreateBetween and type(settings.BetweenRooms)=="table" then
                getgenv().SB2BetweenResumeRooms={UserId=player.UserId,Rooms=settings.BetweenRooms}
            end
            local ok,ticket=pcall(function()return HttpService:JSONDecode(readfile(%q))end)
            if ok and type(ticket)=="table"and ticket.Active==true and ticket.UserId==player.UserId and ticket.PlaceId==game.PlaceId then
                getgenv().SB2SoloResumeTicket=ticket
            end
            assert(loadstring(source))()
        end
    end
end
]],state.ConfigPath,runId,tostring(state.AutoPreset==true),tostring(game.GameId),state.SavedScriptPath,state.Build,state.ConfigPath,path)
        queue(code);queuedToken=runId;queuedAutoPreset=state.AutoPreset
    end
    local function clearRejoinAway()
        state.SafeRejoinRequested=false;state.SafeRejoinAway=nil;state.SafeRejoinDispatch=nil;state.ServerTeleportStarted=false
    end
    local function fail(reason)
        clearRejoinAway();state.AutomationTeleporting=false
        if state.SoloServerSearch and state.SoloServerSearch.Active then state.SoloServerSearch.Stop("Automation stopped")end
        if state.MultiSpotController then state.MultiSpotController.Pause(tostring(reason))end
        if state.AccountProgression and state.ProgressionController then state.ProgressionController.Pause(reason)end
        if state.SafeMode and state.SafeController then state.SafeController.Pause(reason)
        elseif state.ReleaseSafePanic then state.ReleaseSafePanic()end
        state.SafeModeStatus=tostring(reason);state.MultiSpotStatus=tostring(reason)
        state.SaveNow();refresh()
    end
    function state.ChangeAutomationFloor(placeId)
        if state.AutomationTeleporting then return true end
        local floor=catalog.FloorById[placeId]
        if not floor or not state.IsAutomationFloorUnlocked(placeId)then
            local reason="Selected floor is locked or unavailable"
            state.LastFloorTravelError=reason;fail(reason);return false,reason
        end
        local progression=state.AccountProgression==true
        state.FloorTravelAttempt=0
        local sent,reason=pcall(function()
            assert(state.PanicToSpawn(),"Wait for a living character at the teleport pad")
            state.QueueAutomation();state.AutomationTeleporting=true;state.AutomationTeleportDeadline=os.clock()+45
            local attempt=1
            repeat
                task.wait(math.clamp((state.PingMs or 100)/1000+.25,.5,1))
                assert(state.Running and not state.StopEverything and state.AutomationTeleporting,"Floor travel cancelled")
                assert(not progression or state.AccountProgression,"Account Progression stopped")
                assert(state.PanicToSpawn(),"Wait for a living character at the teleport pad")
                state.FloorTravelAttempt=attempt
                local reply=game.ReplicatedStorage.Function:InvokeServer("Teleport",{"Teleport",placeId})
                if reply==nil or reply==""then return end
                if attempt==2 then error(tostring(reply))end
                attempt=attempt+1
            until attempt>2
        end)
        state.LastFloorTravelError=not sent and tostring(reason)or nil
        if not sent then fail(reason)end
        return sent,state.LastFloorTravelError
    end
    local kickFallback,restTracker
    if ctx.MakeRest then
        local path="SB2Codex/anti-suspicious_"..player.UserId..".json"
        local function integer(value,fallback,maximum)
            return type(value)=="number" and value==value and math.clamp(math.round(value),1,maximum)or fallback
        end
        local limits=state.AntiSuspiciousLimits or {}
        state.AntiSuspiciousLimits=limits
        limits.Hops=integer(limits.Hops,10,100);limits.Window=integer(limits.Window,10,200)
        limits.Min=integer(limits.Min,40,200);limits.Max=math.max(limits.Min,integer(limits.Max,60,200))
        function state.SetAntiSuspicious(value)
            state.AntiSuspicious=value==true
            ctx.SavePreferences()
        end
        function state.SetAntiSuspiciousLimit(key,value,maximum)
            if key=="Hops"then limits.Hops=integer(value,limits.Hops,100)
            elseif key=="Window"then limits.Window=integer(value,limits.Window,200)
            elseif key=="Rest"then
                limits.Min=integer(value,limits.Min,200)
                limits.Max=math.max(limits.Min,integer(maximum,limits.Max,200))
            else return end
            ctx.SavePreferences()
        end
        restTracker=ctx.MakeRest({Now=os.time,Random=math.random,Enabled=function()return state.AntiSuspicious end,
            Limits=function()return limits end,
            Load=function()
                if type(isfile)~="function" or not isfile(path)then return end
                local bytes=readfile(path)
                if #bytes<8192 then return HttpService:JSONDecode(bytes)end
            end,
            Save=function(ledger)
                if state.StorageBootstrap then local ready,reason=state.StorageBootstrap.Ensure(true);assert(ready,reason)end
                writefile(path,HttpService:JSONEncode(ledger))
            end})
        state.AntiSuspiciousRestUntil=restTracker.Deadline()
    end
    local failurePath="SB2Codex/safe-failure_"..player.UserId..".json"
    pcall(function()
        if type(isfile)~="function"or type(readfile)~="function"or not isfile(failurePath)then return end
        local bytes=readfile(failurePath)
        if #bytes>8192 then return end
        local record=HttpService:JSONDecode(bytes)
        if type(record)=="table"and record.Version==1 and record.UserId==player.UserId then state.LastSafeFailure=record end
    end)
    local function recordFailure(failure)
        local record={Version=1,UserId=player.UserId,Build=state.Build,JobId=game.JobId,PlaceId=game.PlaceId,
            At=failure.At,Phase=failure.Phase,Reason=tostring(failure.Reason):sub(1,1500),
            TargetUserId=failure.TargetUserId,TargetName=failure.TargetName}
        local input=state.LastBlockInput
        if input and failure.TargetUserId then
            record.Input={Method=input.Method,Dispatched=input.Dispatched==true,Attempt=input.Attempt,X=input.X,Y=input.Y,
                OffsetX=input.OffsetX,OffsetY=input.OffsetY,Errors={}}
            for i=1,math.min(3,#(input.Errors or {}))do record.Input.Errors[i]=tostring(input.Errors[i]):sub(1,400)end
        end
        state.LastSafeFailure=record
        local saved,reason=pcall(function()
            assert(type(writefile)=="function","Failure record storage unavailable")
            if state.StorageBootstrap then local ready,problem=state.StorageBootstrap.Ensure();assert(ready,problem)end
            writefile(failurePath,HttpService:JSONEncode(record))
        end)
        state.SafeFailureSaveError=not saved and tostring(reason)or nil
    end
    local function restHoldReason()
        local deadline=state.AntiSuspiciousRestUntil
        if not deadline then return end
        local remaining=math.max(0,math.ceil(deadline-os.time()))
        if remaining>0 then
            local reason=string.format("Anti Suspicious rest · %d:%02d remaining",math.floor(remaining/60),remaining%60)
            local problem=state.RestMenuError or kickFallback and kickFallback.MenuRest and state.SafeKickFallbackStatus
            return problem and reason.." · "..problem or reason
        end
        if kickFallback and kickFallback.Armed then
            return state.SafeKickFallbackStatus or "Anti Suspicious rest ended · waiting for rejoin"
        end
        state.AntiSuspiciousRestUntil=nil
    end
    local function showAutomationHold(reason)
        if state.SafeMode then state.SafeModeStatus=reason end
        if state.MultiSpot then state.MultiSpotStatus=reason end
    end
    local function teleportRestMenu()
        state.QueueAutomation()
        state.ServerTeleportStarted=false
        state.AutomationTeleporting=true;state.AutomationTeleportDeadline=os.clock()+40
        local sent,reason=pcall(TeleportService.Teleport,TeleportService,659222129,player)
        if not sent then state.AutomationTeleporting=false;error(reason)end
    end
    local restMenuAttempts,restMenuRetryAt=0,0
    local function resumeRestMenu()
        if state.StopEverything or state.ModeratorBlocking or state.AutoRegroupHolding or state.ServerTeleportStarted
            or state.AutomationTeleporting or kickFallback and kickFallback.Armed then return end
        local now=os.clock()
        if restMenuAttempts>=3 then state.RestMenuError="Start menu unavailable · rejoin manually";return end
        if now<restMenuRetryAt then return end
        restMenuAttempts+=1;restMenuRetryAt=now+45
        local sent,reason=pcall(teleportRestMenu)
        state.RestMenuError=not sent and tostring(reason):sub(1,400)or nil
        if not sent then showAutomationHold("Anti Suspicious rest · Start menu retry · "..tostring(reason))end
    end
    local function chooseBlockTarget(people)
        for _,person in ipairs(people)do
            if not allowed(person)then
                local recognized,button=pcall(findPrompt,person)
                if recognized and button then return person end
            end
        end
        for _,person in ipairs(people)do if person.UserId==state.SafePendingUserId then return person end end
        return people[math.random(1,#people)]
    end
    local api=ctx.Make({UserId=player.UserId,PlaceId=game.PlaceId,JobId=game.JobId,Now=os.time,Clock=os.clock,
        SettleSeconds=0,SoloSeconds=.3,BlockSettleSeconds=0,NewId=function()return HttpService:GenerateGUID(false)end,
        Random=function(count)return math.random(1,count)end,Preflight=preflight,Save=save,GetBlocked=getBlocked,RecordFailure=recordFailure,
        SnapshotSettings=snapshot,RestoreSettings=restoreFeatures,GetPlayers=others,IsAllowed=allowed,IsFriend=function()return false end,
        ChooseTarget=chooseBlockTarget,IsPresent=function(person)return person.Parent==Players end,
        Block=function(person,active)
            local before=os.clock();local confirmed=performBlock(person,active)
            state.LastSafeBlockSeconds=os.clock()-before
            local search=state.SoloServerSearch
            if search and search.Ticket then search.Ticket.LastBlockSeconds=state.LastSafeBlockSeconds end
            return confirmed
        end,
        Queue=function()state.QueueAutomation()end,
        Hop=function()
            local ticket=state.SoloServerSearch and state.SoloServerSearch.Ticket
            local rest=kickFallback and restTracker and restTracker.Departure()
            if inBetween or rest then
                assert(kickFallback and ticket and ticket.LastBlockedUserId,"Confirmed-block rejoin unavailable")
                state.ServerTeleportStarted=false
                kickFallback.Requested(ticket.LastBlockedUserId,rest)
                return
            end
            state.AutomationTeleporting=true;state.AutomationTeleportDeadline=os.clock()+40;state.SafeRejoinRequested=true
            state.ServerTeleportStarted=false
            if kickFallback and ticket then kickFallback.Requested(ticket.LastBlockedUserId)end
            local ok,reason=pcall(function()TeleportService:Teleport(game.PlaceId,player)end)
            if not ok then clearRejoinAway();error(reason)end
        end,
        Notify=function(search)
            state.SoloServerStatus=search.Status
            if state.SafeMode then state.SafeModeStatus=search.Status end
            refresh()
        end})
    state.SoloServerSearch=api
    local safe=ctx.MakeSafe({State=state,Search=api,CurrentFloor=function()return game.PlaceId end,
        Suspended=function()
            local reason=restHoldReason()
            if reason then showAutomationHold(reason);return true end
            if not waitingForBetween()then return false end
            if state.SafeMode and not state.SafeWhitelistResolving then state.SafeModeStatus="Waiting to enter The Between through a room"end
            return true
        end,
        TargetFloor=function()return (inBetween or state.AccountProgression) and game.PlaceId or state.SafeFloorId end,
        Players=others,Allowed=allowed,ChangeFloor=state.ChangeAutomationFloor,
        Panic=function()
            if inBetween then return end
            if state.PanicInPlace then state.PanicInPlace()else state.PanicToSpawn()end
        end,
        Protected=function()if restTracker then restTracker.ObserveProtected()end end,
        ReleasePanic=function()state.ReleaseSafePanic()end,Travelling=function()return state.AutomationTeleporting or state.TravelBusy end,
        Status=function(message)state.SafeModeStatus=message end,Save=state.SaveNow})
    state.SafeController=safe
    local multi=ctx.MakeMulti({State=state,Respawns=state.MultiSpotRespawns,Spots=function()return catalog.Spots end,
        PriorityTarget=function()return state.GetFarmPriorityTarget and state.GetFarmPriorityTarget(os.clock())end,
        DepartureReady=function()return not state.FarmCoordination or state.FarmCoordination.Ready("spot")end,
        Suspend=function()
            state.MultiSpotPriorityActive=true
            if state.MultiSpotOwnsTravel and state.TravelBusy then state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false end
            state.MultiSpotOwnsTravel=false;state.MultiSpotTravelPending=false;state.MultiSpotLandingPosition=nil;state.MultiSpotEmptySince=nil
            state.TravelHold=false;state.TravelHoldPosition=nil
            if state.ArenaFloat then state.ArenaFloat.Release()end
        end,
        Resume=function()state.MultiSpotPriorityActive=false end,CurrentFloor=function()return game.PlaceId end,ChangeFloor=state.ChangeAutomationFloor,
        CanMove=function()
            if state.Running==false or state.StopEverything then return false,"Paused · Stop Everything or runtime stopped"end
            if not state.AutoFarm then return false,"Enable Auto Farm to travel to selected arenas"end
            if state.AccountProgression then return false,"Waiting · Account Progression owns travel"end
            if state.ModeratorBlocking then return false,"Waiting · moderator protection"end
            if state.AutoTradeBusy then return false,"Waiting · trading"end
            if state.AutomationTeleporting then return false,"Waiting · floor teleport"end
            if state.SafeModePanic or api.Active or state.SafeMode and safe.Seeking then return false,"Waiting · "..tostring(state.SafeModeStatus or "Safe Mode protection")end
            if os.clock()<(state.AtheonUnlockPauseUntil or 0)then return false,"Waiting · Atheon portal"end
            if state.IsFarmEnemyAlive and state.IsFarmEnemyAlive()then
                local target=state.FarmTargetLock or state.FollowTarget
                return false,"Finishing current enemy"..(target and " · "..target.Name or "")
            end
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            if not root or not humanoid or humanoid.Health<=0 then return false,"Waiting for a living character to load"end
            if root.Anchored then return false,"Waiting · character is anchored"end
            if state.TravelBusy then return false,"Waiting · current movement"end
            if state.Dodging then return false,"Waiting · dodging"end
            if state.Recovering then return false,"Waiting · recovery"end
            return true
        end,
        Moving=function()return state.TravelBusy end,
        Arrived=function(spot)
            state.MultiSpotOwnsTravel=false
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local position=state.LastTravelPosition
            local arrived=spot and root and position and state.LastTravelDestination==spot.DestinationId and (root.Position-position).Magnitude<=25
            if arrived and state.FinishMultiSpotArrival then state.FinishMultiSpotArrival()end
            return arrived
        end,
        Go=function(spot,resume)
            if state.TravelBusy then return false end
            state.RegisterAutomationDestination(spot);state.MultiSpotEmptySince=nil;state.MultiSpotAnchor=spot.Position
            state.MultiSpotEncounter=resume and state.MultiSpotEncounter or {};state.MultiSpotNextScan=0
            state.FollowTarget=nil;state.LastTravelDestination=nil;state.MultiSpotOwnsTravel=true
            return state.TeleportToDestination(spot.DestinationId,false,true)
        end,
        Encounter=function(spot)return state.ReadAutomationEncounter(spot)end,
        ClearEncounter=function()state.MultiSpotEncounter={};state.MultiSpotEncounterScope=nil;state.MultiSpotNextScan=0 end,
        Release=function()
            if state.ArenaFloat then state.ArenaFloat.Release()end
            if state.MultiSpotOwnsTravel and state.TravelBusy then state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false end
            state.MultiSpotPriorityActive=false;state.MultiSpotEmptySince=nil;state.MultiSpotOwnsTravel=false
            state.MultiSpotAnchor=nil;state.MultiSpotEncounter=nil;state.MultiSpotEncounterScope=nil;state.MultiSpotNextScan=0
            state.MultiSpotTravelPending=false;state.MultiSpotLandingPosition=nil
        end,Status=function(message)state.MultiSpotStatus=message end,Save=state.SaveNow})
    state.MultiSpotController=multi
    local function ensureToken()
        if state.SafeMode or state.MultiSpot or state.AccountProgression then return end
        state.AutomationRunId=HttpService:GenerateGUID(false);queuedToken=nil
    end
    function state.SetSafeMode(on)
        if state.SafeKickFallback then state.SafeKickFallback.Reset()end
        ensureToken();safe.Reset();state.SafeMode=on==true
        if not state.SafeMode then state.ReleaseSafePanic()end
        state.SafeModeStatus=state.SafeMode and "Checking selected floor..."or "Safe Mode is off"
        state.SafePendingUserId=nil;state.SaveNow();refresh()
        if state.SafeMode then task.defer(function()workerIdentity();safe.Update();refresh()end)end
    end
    state.SetSoloServerSearch=state.SetSafeMode
    function state.SetSafeFloor(id)
        if state.AccountProgression then
            state.SafeFloorId=game.PlaceId;state.SafeModeStatus="Account Progression · protecting the current floor"
            state.SaveNow();refresh();return false
        end
        local floor=catalog.FloorById[tonumber(id)]
        if not floor or not state.IsAutomationFloorUnlocked(floor.Id)then state.SafeModeStatus="That floor is locked";refresh();return false end
        safe.Reset();multi.Reset();state.SafeFloorId=floor.Id;state.SharedSafeFloorId=floor.Id
        state.SaveNow();refresh()
        if state.SafeMode and not state.AntiSuspiciousRestUntil then
            if waitingForBetween()then
                if state.SafeKickFallback then state.SafeKickFallback.Reset()end
                state.ReleaseSafePanic()
            elseif not inBetween then state.PanicToSpawn()end
            task.defer(function()workerIdentity();safe.Update();refresh()end)
        end
        return true
    end
    local whitelistGeneration=0
    function state.SetSafeWhitelist(text)
        local entries,used={},{}
        for value in tostring(text or ""):gsub("[^%w_]"," "):gmatch("%S+")do
            if not used[value:lower()]then used[value:lower()]=true;entries[#entries+1]=value end
        end
        text=table.concat(entries,", ")
        if #text>2000 then state.SafeModeStatus="Whitelist is too long";refresh();return false end
        whitelistGeneration=whitelistGeneration+1
        local token=whitelistGeneration
        safe.Reset();state.SafeWhitelistResolving=true
        task.delay(12,function()
            if token~=whitelistGeneration or not state.Running or not state.SafeWhitelistResolving then return end
            whitelistGeneration=whitelistGeneration+1;state.SafeWhitelistResolving=false
            state.SafeModeStatus="Whitelist lookup timed out · using the saved whitelist";refresh()
        end)
        task.spawn(function()
            local membership={}
            local ok,reason=pcall(function()
                assert(#entries<=100,"Use at most 100 whitelist entries")
                for _,name in ipairs(entries)do
                    local id=tonumber(name)or Players:GetUserIdFromNameAsync(name)
                    assert(id and id>0 and id%1==0,"Invalid whitelist user: "..name)
                    membership[tostring(id)]=true
                end
            end)
            if token~=whitelistGeneration or not state.Running then return end
            state.SafeWhitelistResolving=false
            if not ok then state.SafeModeStatus="Whitelist was not saved: "..tostring(reason);refresh();return end
            state.SafeWhitelistIds=membership;state.SafeWhitelistText=text;safe.Reset()
            if state.UI.SafeWhitelist and not state.UI.SafeWhitelist:IsFocused()then state.UI.SafeWhitelist.Text=text end
            state.SafeModeStatus=state.SafeMode and "Whitelist updated · checking server"or "Whitelist saved"
            state.SaveNow();refresh()
            if state.SafeMode then workerIdentity();safe.Update();refresh()end
        end)
        return true
    end
    function state.SetMultiSpot(on)
        ensureToken();multi.Reset();state.MultiSpot=on==true
        state.MultiSpotStatus=state.MultiSpot and "Starting selected arenas..."or "Multi Spot is off"
        state.SaveNow();refresh()
        if state.MultiSpot and not state.AccountProgression then task.defer(function()workerIdentity();multi.Update(farmClock());refresh()end)end
    end
    local function spotOrder(selected,requested)
        local order,membership={},{}
        local function append(id)
            local canonical=catalog.Aliases[id]or id
            if selected[canonical]and not membership[canonical]then order[#order+1]=canonical;membership[canonical]=true end
        end
        for _,id in ipairs(state.MultiSpotOrder)do
            local spot=catalog.SpotById[id]
            if spot and spot.PlaceId~=game.PlaceId then append(id)end
        end
        for _,id in ipairs(requested or {})do append(id)end
        for _,id in ipairs(state.MultiSpotOrder)do append(id)end
        for _,spot in ipairs(catalog.Spots)do append(spot.Id)end
        return order
    end
    function state.SetMultiSpotSelection(id,on)
        local key=catalog.Aliases[id]or id
        local spot=catalog.SpotById[key]
        if not spot or not state.IsAutomationFloorUnlocked(spot.PlaceId)then state.MultiSpotStatus="That arena's floor is locked";refresh();return false end
        state.MultiSpotSelected[key]=on==true or nil;state.MultiSpotOrder=spotOrder(state.MultiSpotSelected)
        multi.Reset();state.SaveNow();refresh();return true
    end
    function state.SetMultiSpotSelections(selected,order)
        local nextSelection=table.clone(state.MultiSpotSelected)
        for id in pairs(nextSelection)do
            local spot=catalog.SpotById[id]
            if spot and spot.PlaceId==game.PlaceId then nextSelection[id]=nil end
        end
        for id,on in pairs(selected or {})do
            if on then
                local spot=catalog.SpotById[catalog.Aliases[id]or id]
                if not spot or spot.PlaceId~=game.PlaceId or not state.IsAutomationFloorUnlocked(spot.PlaceId)then return false end
                nextSelection[spot.Id]=true
            end
        end
        state.MultiSpotOrder=spotOrder(nextSelection,order);state.MultiSpotSelected=nextSelection
        multi.Reset();state.SaveNow();refresh();return true
    end
    local function joinFriendAtPad(id,active)
        state.AutoJoinFriendHolding=true
        local function permitted()return active()and not api.Active and not(state.SafeMode and safe.Seeking)end
        local ok,result=pcall(function()
            local attempt=1
            repeat
                assert(permitted(),"Friend join cancelled for protection or travel")
                assert(state.PanicToSpawn(),"Wait for a living character at the teleport pad")
                task.wait(math.clamp((state.PingMs or 100)/1000+.25,.5,1))
                assert(permitted(),"Friend join cancelled for protection or travel")
                assert(state.PanicToSpawn(),"Teleport pad is unavailable")
                local reply=game.ReplicatedStorage.Function:InvokeServer("Teleport",{"FriendTeleport",id})
                if reply==nil or reply==""then
                    local expires=os.clock()+5
                    repeat task.wait(.1)until not permitted()or state.ServerTeleportStarted or os.clock()>=expires
                    return reply
                end
                if attempt==2 or not tostring(reply):lower():find("teleport pad",1,true)then return reply end
                attempt=attempt+1
            until attempt>2
        end)
        state.AutoJoinFriendHolding=false
        if state.Running and not state.ModeratorBlocking and not api.Active and not(state.SafeMode and safe.Seeking)then state.ReleaseSafePanic()end
        if not ok then error(result)end
        return result
    end
    local friend=ctx.MakeFriend({State=state,LocalUserId=player.UserId,Spawn=task.spawn,Now=os.clock,
        PendingTimedOut=function()state.ServerTeleportStarted=false end,
        Resolve=function(name)return Players:GetUserIdFromNameAsync(name)end,Present=function(id)return Players:GetPlayerByUserId(id)~=nil end,
        Queue=function()
            local enqueue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)or (fluxus and fluxus.queue_on_teleport)
            assert(type(enqueue)=="function","Executor has no teleport queue support")
            state.SaveNow();enqueue('loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()')
        end,Join=joinFriendAtPad})
    state.AutoJoinFriendController=friend
    function state.SetAutoJoinFriend(on)state.AutoJoinFriend=on==true;friend.Reset();state.SaveNow();refresh()end
    function state.SetJoinFriendUsername(name)
        state.JoinFriendUsername=tostring(name or ""):match("^%s*(.-)%s*$"):gsub("^@",""):sub(1,20)
        friend.Reset();state.SaveNow();refresh()
    end
    ui=ctx.MakeUI({State=state,Catalog=catalog,Create=ctx.Create,Button=ctx.Button,Label=ctx.Label,
        Bind=ctx.Bind,Corner=ctx.Corner,Reveal=ctx.Reveal,Parent=ctx.Parent})
    ctx.Bind(Players.PlayerAdded,function(person)
        safe.Joined(person)
        task.defer(function()workerIdentity();if state.Running then safe.Update();refresh()end end)
    end)
    ctx.Bind(TeleportService.TeleportInitFailed,function(who,result,reason)
        if who==player then
            local requested=state.SafeRejoinRequested
            state.ServerTeleportStarted=false
            if state.AutoRegroupHolding and state.AutoRegroupController then
                state.AutomationTeleporting=false
                state.AutoRegroupController.TeleportFailed(reason or result.Name)
                return
            end
            state.AutomationTeleporting=false;api.TeleportFailed(reason or result.Name);fail(reason or result.Name)
            if friend.TeleportFailed then friend.TeleportFailed(reason or result.Name)end
            if kickFallback and (requested or kickFallback.MenuRest)then kickFallback.TeleportFailed()end
        end
    end)
    local function fallbackTicket(rest)
        local ticket=api.Ticket
        if not ticket then
            local ok,value=pcall(readTicket)
            if ok and type(value)=="table"and type(value.RunId)=="string"then ticket=value end
        end
        if ticket then
            assert(ticket.UserId==player.UserId and ticket.PlaceId==game.PlaceId,"Saved search scope mismatch · no fallback kick")
            assert(type(ticket.StartedAt)=="number"and os.time()-ticket.StartedAt<900
                and type(ticket.Hops)=="number"and ticket.Hops<((inBetween or rest) and 13 or 12),"Safe Mode search limit reached · no fallback kick")
        end
        return ticket
    end
    if ctx.MakeKickFallback then
        kickFallback=ctx.MakeKickFallback({InitialJob=game.JobId,Job=function()return game.JobId end,Now=os.clock,
            WallTime=os.time,CommitRest=function(seconds)
                local untilAt=restTracker.Commit(seconds)
                state.AntiSuspiciousRestUntil=untilAt
                return untilAt
            end,
            Active=function()return state.Running and state.SafeMode and not waitingForBetween()and not state.StopEverything and not state.ModeratorBlocking and not state.SafeWhitelistResolving end,
            Players=others,Allowed=allowed,Present=function(person)return person.Parent==Players end,Spawn=task.spawn,Sleep=task.wait,CheckLimits=fallbackTicket,
            Started=function()return state.ServerTeleportStarted==true end,
            Pause=function()
                workerIdentity();state.SafeKickFallbackBusy=true;api.Destroy(true)
                if not inBetween then
                    if state.PanicInPlace then state.PanicInPlace()else state.PanicToSpawn()end
                end
            end,
            Block=function(person,active)return state.BlockPlayerNative(person,active)end,
            Prepare=function(person,rest)
                local ticket=fallbackTicket(rest)or {Version=1,UserId=player.UserId,PlaceId=game.PlaceId,
                    RunId=HttpService:GenerateGUID(false),StartedAt=os.time(),Hops=0,Visited={},Added={}}
                assert(os.time()-ticket.StartedAt<900 and ticket.Hops<((inBetween or rest) and 13 or 12),"Safe Mode search limit reached · no kick")
                ticket.SameServerReturns=math.min(ticket.SameServerReturns or 0,3)
                ticket.Active=true;ticket.SourceJob=game.JobId;ticket.Visited[game.JobId]=true
                ticket.LastBlockedUserId=person.UserId;save(ticket);state.QueueAutomation()
            end,
            Menu=function()workerIdentity();teleportRestMenu()end,
            Rejoin=function()workerIdentity();TeleportService:Teleport(game.PlaceId,player)end,Kick=function(reason)player:Kick(reason)end,
            Finish=function()state.SafeKickFallbackBusy=false end,Status=function(message)
                state.SafeKickFallbackStatus=message;state.SafeModeStatus=message;refresh()
            end})
        state.SafeKickFallback=kickFallback
    end
    ctx.Bind(player.OnTeleport,function(stage)
        if stage==Enum.TeleportState.Started or stage==Enum.TeleportState.InProgress then
            if not state.ServerTeleportStarted and state.RefreshPresetPreferences then state.RefreshPresetPreferences()end
            state.ServerTeleportStarted=true
            if kickFallback then kickFallback.MarkStarted()end
            if state.SafeMode or state.MultiSpot or state.AccountProgression or state.AutoCreateBetween or state.AutoRegroup or state.AutoPreset then
                local ok,reason=pcall(state.QueueAutomation)
                if not ok then
                    if state.AutoRegroupHolding then state.AutoRegroupPrepareError=tostring(reason)
                    else fail(reason)end
                end
            end
        elseif stage==Enum.TeleportState.Failed then
            local requested=state.SafeRejoinRequested
            state.ServerTeleportStarted=false
            clearRejoinAway();state.AutomationTeleporting=false
            if friend.TeleportFailed then friend.TeleportFailed("Teleport failed")end
            if kickFallback and (requested or kickFallback.MenuRest)then kickFallback.TeleportFailed()end
        end
    end)
    state.AutomationLoadedJob=game.JobId
    task.spawn(function()
        workerIdentity()
        local resumeFeatures=getgenv().SB2AutomationResumeFeatures;getgenv().SB2AutomationResumeFeatures=nil
        if resumeFeatures then restoreFeatures(resumeFeatures)end
        local ok,resume=pcall(readTicket)
        if queuedResume then ok,resume=true,queuedResume end
        local resumeAllowed=not state.AntiSuspiciousRestUntil and not state.ModeratorBlocking and state.SafeMode
            and (inBetween or state.AccountProgression or state.SafeFloorId==game.PlaceId)
        if resumeAllowed and ok and type(resume)=="table"and resume.Active==true and resume.PlaceId==game.PlaceId then
            api.Start(resume);if safe.AdoptSearch then safe.AdoptSearch()end
        end
        state.SaveNow()
        while state.Running do
            local updated,reason=pcall(function()
                if state.AutomationTeleporting then
                    local deadline=state.AutomationTeleportDeadline
                    if type(deadline)~="number"or os.clock()>deadline then fail("Floor teleport timed out")end
                end
                if state.AutoRegroupHolding then showAutomationHold("Waiting · Auto Regroup returning to lobby");return end
                local hold=restHoldReason()
                if hold then
                    showAutomationHold(hold)
                    if state.AntiSuspiciousRestUntil>os.time()then resumeRestMenu()end
                    return
                end
                if state.ModeratorBlocking or state.SafeKickFallbackBusy or kickFallback and kickFallback.Armed then
                    if state.MultiSpot then state.MultiSpotStatus="Waiting · "..tostring(state.SafeModeStatus or "protection and rejoin")end
                    return
                end
                if inBetween then safe.Update();return end
                friend.Update(os.clock());safe.Update()
                if state.AccountProgression then
                    if state.ProgressionController then state.ProgressionController.Update(os.clock())end
                else multi.Update(farmClock())end
            end)
            if not updated then state.LastAutomationError=tostring(reason);pcall(fail,reason)end
            local painted,paintError=pcall(refresh)
            state.LastAutomationUIError=not painted and tostring(paintError)or nil
            local interval=1
            if api.Active or state.SafeModePanic then interval=.03
            elseif state.MultiSpot or state.AccountProgression then interval=.1
            elseif state.SafeMode then interval=.2 end
            task.wait(interval)
        end
    end)
    task.spawn(function()
        while state.Running do
            if kickFallback then pcall(kickFallback.Update,os.clock())end
            if not state.SafeKickFallbackBusy and not(kickFallback and kickFallback.Armed)and safe.ObserveProtected then pcall(safe.ObserveProtected)end
            task.wait(state.SafeMode and .1 or 1)
        end
    end)
    return api
end
