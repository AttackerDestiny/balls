local embeddedSource=...
if not game:IsLoaded()then game.Loaded:Wait()end
-- Swordburst 2: nearby mob aura with a movable toggle panel.
-- Repeated execution reuses the active UI. Closing stops the runtime and saves preferences.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
while not player do task.wait(.1);player=Players.LocalPlayer end
local env = getgenv()
local previousRuntime=env.SB2KillAura
local previous=previousRuntime and previousRuntime.UserId==player.UserId and previousRuntime or nil
local BUILD="2026-11-03.teleport-section-v1.12.11"
local VERSION="1.12.11"
local storageBootstrap=(function()
-- BEGIN BUNDLED STORAGE BOOTSTRAP
-- Executor paths are relative to its workspace; never add a second "workspace".
-- Existing account settings/tickets are preserved. The runnable entry passes its
-- own embedded body so this can persist a complete, dependency-free loader.
return function(ctx)
    local api={Ready=false,Generation=0,Created={}}
    local folder="SB2Codex"
    local sourcePath=folder.."/kill-aura.luau"
    local cachedPath=type(ctx.Build)=="string"and (folder.."/source_"..ctx.Build:gsub("[^%w_-]","_")..".luau")or sourcePath
    api.SourcePath=cachedPath
    local saved=false
    local fullSource=type(ctx.Source)=="string"and ctx.Prefix..ctx.Source..ctx.Suffix or nil
    local function ensureFile(path,value)
        if not ctx.IsFile(path)then
            ctx.Write(path,value);api.Generation+=1;api.Created[path]=true
        end
    end
    function api.Ensure(verifySource)
        local ok,message=pcall(function()
            assert(type(ctx.IsFile)=="function"and type(ctx.Read)=="function"and type(ctx.Write)=="function",
                "This executor does not provide file storage for automatic rejoin")
            assert(fullSource,"Run the complete kill-aura.luau entry to install automatic rejoin")
            if type(ctx.IsFolder)=="function"then
                if not ctx.IsFolder(folder)then
                    assert(type(ctx.MakeFolder)=="function","This executor cannot create SB2Codex")
                    local made,reason=pcall(ctx.MakeFolder,folder)
                    assert(made or ctx.IsFolder(folder),tostring(reason))
                end
            elseif type(ctx.MakeFolder)=="function"then
                -- Executors without isfolder may report an existing folder as an error.
                pcall(ctx.MakeFolder,folder)
            end
            if (verifySource and cachedPath==sourcePath)or not saved or not ctx.IsFile(sourcePath)then
                if not ctx.IsFile(sourcePath)or ctx.Read(sourcePath)~=fullSource then
                    ctx.Write(sourcePath,fullSource);api.Generation+=1;api.Created[sourcePath]=true
                end
                saved=true
            end
            if cachedPath~=sourcePath and (verifySource or not ctx.IsFile(cachedPath))then
                if not ctx.IsFile(cachedPath)or ctx.Read(cachedPath)~=fullSource then
                    ctx.Write(cachedPath,fullSource);api.Generation+=1;api.Created[cachedPath]=true
                end
            end
            ensureFile(folder.."/settings_"..ctx.UserId..".json",ctx.Encode({Version=1}))
            ensureFile(folder.."/solo-search_"..ctx.UserId..".json",ctx.Encode({Version=1,Active=false,UserId=ctx.UserId,PlaceId=ctx.PlaceId}))
            ensureFile(folder.."/destinations_"..ctx.PlaceId..".json",ctx.Encode({Version=1,PlaceId=ctx.PlaceId,Areas={}}))
        end)
        api.Ready=ok;api.Error=not ok and tostring(message)or nil
        return ok,api.Error
    end
    api.Ensure(true)
    return api
end

-- END BUNDLED STORAGE BOOTSTRAP
end)()({Source=embeddedSource,Build=BUILD,UserId=player.UserId,PlaceId=game.PlaceId,
    Prefix="local SB2_SOURCE=["..string.rep("=",12).."[\n",
    Suffix="]"..string.rep("=",12).."]\nreturn assert(loadstring(SB2_SOURCE, \"SB2\"))(SB2_SOURCE)\n",
    IsFile=isfile,Read=readfile,Write=writefile,IsFolder=isfolder,MakeFolder=makefolder,
    Encode=function(value)return HttpService:JSONEncode(value)end})
env.SB2StorageBootstrap=storageBootstrap
local playerGui=player:WaitForChild("PlayerGui")
local runtimeOwner=(function()
-- BEGIN BUNDLED RUNTIME OWNER
-- Engine-instance ownership works even when getgenv is isolated per execution.
return function(ctx)
    local retired,existing={},nil
    for _,gui in ipairs(ctx.Parent:GetChildren()) do
        if gui.Name=="SB2KillAuraUI" and gui:IsA("ScreenGui") then
            local heartbeat=gui:GetAttribute("SB2Heartbeat")
            local phase=gui:GetAttribute("SB2Phase")
            if not existing and gui:GetAttribute("SB2Build")==ctx.Build and gui:GetAttribute("SB2Job")==ctx.Job
                and (phase=="Loading" or phase=="Running") and type(heartbeat)=="number"
                and ctx.Now()-heartbeat<10 then existing=gui
            else retired[#retired+1]=gui end
        end
    end
    if existing then
        for _,gui in ipairs(retired) do gui:Destroy() end
        -- Repeated auto-execute is a no-op; do not turn a hidden panel back on.
        return nil,existing
    end
    local root=ctx.Create()
    root.Name="SB2KillAuraUI"
    root:SetAttribute("SB2Build",ctx.Build);root:SetAttribute("SB2Job",ctx.Job)
    root:SetAttribute("SB2Phase","Loading");root:SetAttribute("SB2Heartbeat",ctx.Now())
    root.Parent=ctx.Parent
    local lease={Root=root}
    local connection,lastPulse,disposed=nil,ctx.Now(),false
    function lease.Alive()return not disposed and root.Parent==ctx.Parent end
    function lease.Retire()
        for _,gui in ipairs(retired) do gui:Destroy() end
        retired={}
    end
    function lease.Ready()
        if lease.Alive()then root:SetAttribute("SB2Phase","Running")end
    end
    function lease.Release()
        if disposed then return end
        disposed=true
        if connection then connection:Disconnect()end
        root:SetAttribute("SB2Phase","Stopped")
    end
    connection=ctx.Pulse:Connect(function()
        if not lease.Alive()then lease.Release();return end
        local now=ctx.Now()
        if now-lastPulse>=2 then lastPulse=now;root:SetAttribute("SB2Heartbeat",now)end
    end)
    return lease
end

-- END BUNDLED RUNTIME OWNER
end)()({Parent=playerGui,Build=BUILD,Job=game.JobId,Now=os.clock,Pulse=RunService.Heartbeat,
    Create=function()local root=Instance.new("ScreenGui");root.ResetOnSpawn=false;root.DisplayOrder=100;root.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;return root end})
if not runtimeOwner then return end
local loadToken={}
env.SB2LoadToken=loadToken
-- The native login place has no combat profile. Handle Play before waiting for it.
if game.PlaceId==659222129 and game.GameId==212154879 then
    local make=(function()
-- BEGIN BUNDLED LOBBY PLAY
-- Bounded login-screen helper; no frame connection or floor-runtime polling.
return function(ctx)
    local api={Attempts=0,Done=false}
    local deadline,nextTry,queued=ctx.Now()+60,0,false
    function api.Update()
        if api.Done then return end
        local now=ctx.Now()
        if not ctx.Alive() or now>=deadline then api.Done=true;return end
        local button=ctx.Find()
        if not button or not ctx.Ready(button) then
            if api.Attempts>0 then api.Done=true end
            return
        end
        if now<nextTry then return end
        nextTry=now+1
        if not queued then
            local ok,err=pcall(ctx.Queue)
            if not ok then api.Error=tostring(err);api.Done=true;return end
            queued=true
        end
        local ok,err=pcall(ctx.Activate,button)
        if not ok then api.Error=tostring(err);api.Done=true;return end
        if err~=false then api.Attempts+=1 end
    end
    return api
end

-- END BUNDLED LOBBY PLAY
end)()
    local helper=make({Now=os.clock,Alive=function()return env.SB2LoadToken==loadToken and runtimeOwner.Alive()end,
        Find=function()
            local gui=playerGui:FindFirstChild("ScreenGui")
            local frame=gui and gui:FindFirstChild("Frame")
            local buttons=frame and frame:FindFirstChild("Buttons")
            return buttons and buttons:FindFirstChild("Play")
        end,
        Ready=function(button)
            if not button:IsA("GuiButton") or not button.Visible or not button.Active then return false end
            if button.Position.Y.Scale==0 and button.Position.Y.Offset<0 then return false end
            local ancestor=button.Parent
            while ancestor and ancestor~=playerGui do
                if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
                if ancestor:IsA("ScreenGui") and not ancestor.Enabled then return false end
                ancestor=ancestor.Parent
            end
            local camera=workspace.CurrentCamera
            local position,size=button.AbsolutePosition,button.AbsoluteSize
            return camera and size.X>0 and size.Y>0 and position.X>=0 and position.Y>=0
                and position.X+size.X<=camera.ViewportSize.X and position.Y+size.Y<=camera.ViewportSize.Y
        end,
        Queue=function()
            local ready,reason=storageBootstrap.Ensure();assert(ready,reason)
            local queue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
            assert(type(queue)=="function","Auto Play requires teleport queue support")
            assert(type(readfile)=="function" and type(isfile)=="function" and isfile("SB2Codex/kill-aura.luau"),"Save the source before Auto Play")
            queue(string.format([==[
if not game:IsLoaded() then game.Loaded:Wait() end
local p=game:GetService("Players").LocalPlayer
while not p do task.wait();p=game:GetService("Players").LocalPlayer end
if p.UserId==%s and game.GameId==212154879 and isfile("SB2Codex/kill-aura.luau") then
    local source=readfile("SB2Codex/kill-aura.luau")
    if string.find(source,%q,1,true) then local run=loadstring(source);if run then run()end end
end
]==],tostring(player.UserId),BUILD))
        end,
        Activate=function(button)
            -- Potassium firesignal cannot resume this native callback after wait().
            -- Spawn its connected function on a real scheduler-owned thread instead.
            assert(type(getconnections)=="function","Native Play activation is unavailable")
            local fired=false
            for _,connection in ipairs(getconnections(button.MouseButton1Click)) do
                if connection.Enabled~=false and type(connection.Function)=="function" then task.spawn(connection.Function);fired=true end
            end
            return fired
        end})
    env.SB2LobbyPlay=helper
    repeat helper.Update();if not helper.Done then task.wait(.25)end until helper.Done
    runtimeOwner.Release();runtimeOwner.Root:Destroy()
    return
end
local configFolder = "SB2Codex"
local configPath = configFolder .. "/settings_" .. tostring(player.UserId) .. ".json"
local configData, configLoadError = {}, nil
local filePersistence = typeof(readfile) == "function" and typeof(writefile) == "function" and typeof(isfile) == "function"
if filePersistence then
    local ok, result = pcall(function()
        if not isfile(configPath) then return {} end
        local raw = readfile(configPath)
        if #raw > 32768 then error("Settings file exceeds its size limit") end
        local decodedOK, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
        if not decodedOK or type(decoded) ~= "table" or decoded.Version ~= 1 then
            if not isfile(configPath .. ".bak") then writefile(configPath .. ".bak", raw) end
            error("Invalid settings backed up; defaults restored")
        end
        return decoded
    end)
    if ok then configData = result else configLoadError = tostring(result) end
end
local sharedSettings,sharedPreferences=nil,{}
if filePersistence then
    local make=(function()
-- BEGIN BUNDLED SHARED SETTINGS
-- Shared preferences only; account progress and resume tickets remain private.
return function(ctx)
    local api={Values={}}
    local path="SB2Codex/shared-settings.json"
    local keys={"AutoTrade","TradeMode","TradeItems","AutoDismantle","AutoEquipBestSword","Enabled","AutoFarm","AutoSwing","SkillAura","SelectedSkill","SkillPerWeapon","SkillPerWeaponVersion",
        "MiscSkillEnabled","SelectedMiscSkill","AutoDodge","AtheonDodge","TransparentMap","PerformanceBoosters",
        "AutoJoinFriend","JoinFriendUsername","SafeMode","SafeWhitelistText","SafeWhitelistIds","MultiSpot","MultiSpotSelected",
        "AccountProgression","PanelPosition","HealthHUDPosition","WindUIPosition"}
    local function select(value)
        local result={Version=1}
        for _,key in ipairs(keys)do result[key]=value[key]end
        return result
    end
    local function read(file)
        local raw=ctx.Read(file);assert(#raw<=32768,"Settings file exceeds its size limit")
        local value=ctx.Decode(raw);assert(type(value)=="table"and value.Version==1,"Invalid shared settings")
        return value
    end
    local function score(value)
        return (type(value.SafeWhitelistText)=="string"and value.SafeWhitelistText:find("%S")and 1000 or 0)
            +(value.SafeMode==true and 10 or 0)+(value.AccountProgression==true and 5 or 0)
            +(value.Enabled==true and 1 or 0)+(value.AutoFarm==true and 1 or 0)
    end
    if ctx.IsFile(path)then api.Values=select(read(path))
    else
        local seed=ctx.Current or{}
        if type(ctx.List)=="function"and score(seed)<1000 then
            local ok,files=pcall(ctx.List,"SB2Codex")
            if ok and type(files)=="table"then
                table.sort(files)
                for index,file in ipairs(files)do
                    if index>200 then break end
                    if file:match("settings_%d+%.json$")then
                        local valid,value=pcall(read,file)
                        if valid and score(value)>score(seed)then seed=value end
                    end
                end
            end
        end
        api.Values=select(seed);ctx.Write(path,ctx.Encode(api.Values))
    end
    local function signatures(value)
        local result={}
        for _,key in ipairs(keys)do result[key]=ctx.Encode({Value=value[key]})end
        return result
    end
    -- Keep this runtime's last local values, separately from other accounts' edits.
    local last=signatures(api.Values)
    function api.Save(value)
        local shared=select(value)
        local current=signatures(shared)
        local changed={}
        for _,key in ipairs(keys)do if current[key]~=last[key]then changed[#changed+1]=key end end
        local exists=ctx.IsFile(path)
        if #changed==0 and exists then return end
        local merged=exists and select(read(path))or select(api.Values)
        for _,key in ipairs(changed)do merged[key]=shared[key]end
        ctx.Write(path,ctx.Encode(merged))
        last=current;api.Values=merged
    end
    return api
end

-- END BUNDLED SHARED SETTINGS
    end)()
    local ok,value=pcall(make,{Current=configData,IsFile=isfile,Read=readfile,Write=writefile,List=listfiles,
        Encode=function(v)return HttpService:JSONEncode(v)end,Decode=function(v)return HttpService:JSONDecode(v)end})
    if ok then sharedSettings=value;sharedPreferences=value.Values else configLoadError=tostring(value)end
end
local function preference(key, fallback)
    if sharedPreferences[key]~=nil then return sharedPreferences[key]end
    if previous and key=="StopEverything" and previous.ResumeRequested then return false end
    if previous and previous.StopEverything and previous.ResumeFeatures and previous.ResumeFeatures[key]~=nil then return previous.ResumeFeatures[key] end
    if previous and previous[key] ~= nil then return previous[key] end
    if configData[key] ~= nil then return configData[key] end
    return fallback
end
local function numericPreference(key, fallback, minimum, maximum)
    local value = preference(key, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then value = fallback end
    return math.clamp(value, minimum, maximum)
end
local restore = {
    Enabled=preference("Enabled",false)==true,
    Radius=30,
    SkillRange=30,
    AutoSwing=preference("AutoSwing",true)==true,
    AutoTrade=preference("AutoTrade",false)==true,TradeMode=preference("TradeMode","Selected"),TradeItems=preference("TradeItems",{}),
    AutoDismantle=preference("AutoDismantle",{}),
    AutoEquipBestSword=preference("AutoEquipBestSword",true)==true,
    AutoFarm=preference("AutoFarm",false)==true,
    FarmRange=math.huge,
    Threat=3,
    SkillAura=preference("SkillAura",false)==true,
    MiscSkillEnabled=preference("MiscSkillEnabled",false)==true,
    SelectedMiscSkill=preference("SelectedMiscSkill","Cursed Enhancement"),
    SelectedPlayerId=preference("SelectedPlayerId",nil),
    ViewingPlayer=preference("ViewingPlayer",false)==true,
    ViewingPlayerInventory=preference("ViewingPlayerInventory",false)==true,
    Skill=preference("SelectedSkill","Piercing Dash"),
    AutoExplore=preference("AutoExplore",true)==true,
    AutoDodge=preference("AutoDodge",true)==true,
    AtheonDodge=preference("AtheonDodge",false)==true,
    TransparentMap=preference("TransparentMap",false)==true,
    PerformanceBoosters=preference("PerformanceBoosters",{}),
    AutoJoinFriend=preference("AutoJoinFriend",false)==true,JoinFriendUsername=preference("JoinFriendUsername",""),
    SafeMode=preference("SafeMode",false)==true,SafeFloorId=tonumber(preference("SafeFloorId",game.PlaceId)) or game.PlaceId,
    SafeWhitelistText=preference("SafeWhitelistText",""),SafeWhitelistIds=preference("SafeWhitelistIds",{}),
    MultiSpot=preference("MultiSpot",false)==true,MultiSpotSelected=preference("MultiSpotSelected",{}),
    MultiSpotCursor=preference("MultiSpotCursor",nil),MultiSpotPending=preference("MultiSpotPending",nil),
    AccountProgression=preference("AccountProgression",false)==true,
    ProgressionFloor=math.floor(numericPreference("ProgressionFloor",1,1,12)),
    ProgressionBossCleared=preference("ProgressionBossCleared",false)==true,
    ProgressionBossClearedName=preference("ProgressionBossClearedName",nil),
    ProgressionComplete=preference("ProgressionComplete",false)==true,
    ProgressionRestore=preference("ProgressionRestore",nil),
    AutomationRunId=preference("AutomationRunId",nil),AutomationResumeFeatures=preference("AutomationResumeFeatures",nil),
}
if type(restore.Skill)~="string" then restore.Skill="Piercing Dash" end
if type(restore.ProgressionRestore)~="table"then restore.ProgressionRestore=nil end
if restore.ProgressionFloor~=12 then restore.ProgressionComplete=false end
if previousRuntime and previousRuntime.Destroy then
    previousRuntime.Destroy(true)
end
runtimeOwner.Retire()
if env.SB2FarmRecoveryUntil and env.SB2FarmRecoveryUntil > os.clock() then
    task.wait(math.min(3, env.SB2FarmRecoveryUntil - os.clock()))
end

do
    local profile=ReplicatedStorage:WaitForChild("Profiles"):WaitForChild(player.Name)
    profile:WaitForChild("Inventory")
    profile:WaitForChild("Locations")
end
local services = ReplicatedStorage:WaitForChild("CardinalClient"):WaitForChild("MainModule")
-- Teleport queues can run before Profiles exist. The game's main module waits
-- for its profile handshake and finishes service initialization before returning.
require(services)
services = services:WaitForChild("Services")
if env.SB2LoadToken~=loadToken or not runtimeOwner.Alive() then runtimeOwner.Release();return end
local Combat = require(services.Combat)
local Actions = require(services.Actions)
local Skills = require(services.Skills)
local GameUI = require(services.UI)
local CanRunSkill = require(ReplicatedStorage.Shared.Util.CanRunSkill)
if env.SB2LoadToken~=loadToken or not runtimeOwner.Alive() then runtimeOwner.Release();return end
local state = {
    Build=BUILD, Version=VERSION, UserId=player.UserId, StopEverything=false,
    Enabled = false, Radius = restore.Radius, SkillRange=restore.SkillRange, Running = true, Nearby = 0,
    HitsSent = 0, LastTarget = "None", LastError = nil,
    AttackInterval = 0.30, ThreatCycle = 0.12, MaxRequestsPerSecond = 48, EffectiveInterval = 0.30,
    Threat = math.clamp(math.floor(restore.Threat), 1, 3), BurstsSent = 0, LastBurstSize = 0,
    AttackBurstInterval = 0.30, AttackBurstActive = false, AttackBurstHistory = {},
    BurstProgress = 0, LastPulseAt = nil, MinimumPulseGap = nil,
    AutoSwing = restore.AutoSwing, SwordSwinging = false, SwingStarts = 0,
    LagPauseUntil = 0, PingMs = nil, Backoff = 1,
    AutoTrade=restore.AutoTrade,TradeMode=restore.TradeMode,TradeItems=type(restore.TradeItems)=="table"and restore.TradeItems or {},
    AutoDismantle=type(restore.AutoDismantle)=="table"and restore.AutoDismantle or {},
    AutoEquipBestSword=restore.AutoEquipBestSword,
    AutoFarm = false, FarmRange = math.huge, Recovering = false,
    TeleportOffset = -6, AutoOffset = true, OffsetStatus = "Waiting for a target",
    FarmAbove=false,OffsetMode="Below",
    OffsetProfiles = {}, UnsafeOffsetProfiles = {}, ProtectionStatus = "Retreat on health loss",
    ProtectionRetreats = 0, TeleportInterval = 0.18, TeleportsSent = 0,
    AverageFrameTime = 1 / 60, AverageLoopCost = 0, TargetScans = 0,
    Moving = false, FollowTarget = nil, MovementStatus = "Auto farm is off",
    ConfigPath = configPath, ConfigLoadError = configLoadError, ConfigLoadedFromDisk = configData.Version == 1,
    SavedScriptPath = storageBootstrap.SourcePath or (configFolder .. "/kill-aura.luau"),StorageBootstrap=storageBootstrap,
    MiscSkillEnabled=false, SelectedMiscSkill=type(restore.SelectedMiscSkill)=="string" and restore.SelectedMiscSkill or "Cursed Enhancement",
    MiscSkillRequests=0, MiscSkillCasts=0, MiscCastRunning=false, MiscReserveStamina=false,
    SkillPerWeapon=preference("SkillPerWeapon",{}), SkillPerWeaponVersion=preference("SkillPerWeaponVersion",0), SkillWeaponVersion=0,
    SkillAura = false, SelectedSkill = restore.Skill, SkillCasts = 0, SkillStatus = "Skill aura is off",
    AttackingTarget = nil, HealthUpdates = 0,
    HideSkillAnimation = true, SuppressSkillMotion = true, HiddenSkillAnimations = 0,
    SkillBurstInterval = 0.30, SkillHitRequests = 0, LastSkillBurstSize = 0, SkillBurstHistory = {},
    AutoExplore = restore.AutoExplore, ExploreHops = 0, Exploring = false,
    AutoDodge = restore.AutoDodge, AtheonDodge=restore.AtheonDodge, TransparentMap = restore.TransparentMap, Dodging = false,
    PerformanceBoosters=restore.PerformanceBoosters,
    AutoJoinFriend=restore.AutoJoinFriend,JoinFriendUsername=restore.JoinFriendUsername,
    SafeMode=restore.SafeMode,SafeFloorId=restore.SafeFloorId,SafeWhitelistText=restore.SafeWhitelistText,SafeWhitelistIds=restore.SafeWhitelistIds,
    MultiSpot=restore.MultiSpot,MultiSpotSelected=restore.MultiSpotSelected,MultiSpotCursor=restore.MultiSpotCursor,MultiSpotPending=restore.MultiSpotPending,
    AutomationRunId=restore.AutomationRunId,AutomationResumeFeatures=restore.AutomationResumeFeatures,
    AccountProgression=restore.AccountProgression,ProgressionFloor=restore.ProgressionFloor,
    ProgressionBossCleared=restore.ProgressionBossCleared,ProgressionComplete=restore.ProgressionComplete,
    ProgressionBossClearedName=type(restore.ProgressionBossClearedName)=="string"and restore.ProgressionBossClearedName or nil,
    ProgressionRestore=restore.ProgressionRestore,ProgressionPhase="Loading",
    AutoSaveStatus = filePersistence and "Auto-save · ready" or "Auto-save · file access unavailable",
}
do
    local profiles = preference("OffsetProfiles", {})
    local count = 0
    if type(profiles) == "table" then
        for key, value in pairs(profiles) do
            if count >= 32 then break end
            if type(key) == "string" and #key < 200 and string.find(key,":offset-v6:",1,true) and type(value) == "number" and value < 0 and value > -math.huge then
                state.OffsetProfiles[key] = value
                count += 1
            end
        end
    end
    local unsafe = preference("UnsafeOffsetProfiles", {})
    count = 0
    if type(unsafe) == "table" then
        for key, value in pairs(unsafe) do
            if count >= 32 then break end
            if type(key) == "string" and #key < 200 and string.find(key,":offset-v6:",1,true) and type(value) == "number" and value > 0 and value < math.huge then
                state.UnsafeOffsetProfiles[key] = value
                count += 1
            end
        end
    end
end
env.SB2KillAura = state
local connections = {}
local lastHit = setmetatable({}, { __mode = "k" })
local consecutiveErrors = 0
local nextAttack = 0
local nextTargetRefresh = 0
local nextPingCheck = 0
local candidates = {}
local targetCursor = 0
local normalScheduler=(function()
-- BEGIN BUNDLED ATTACK SCHEDULER
-- Supplied-source rule: one damage call per target, then a 0.3s cooldown.
-- Timestamps replace a delayed coroutine per hit; skills share these timers.
return function(state)
    local api={}
    local nextHit=setmetatable({}, {__mode="k"})
    local tokens,refill=4,os.clock()
    local nextReserveHit=0
    local ctx
    function api.Bind(value)ctx=value end
    function api.Ready(mob,now)return now>=(nextHit[mob] or 0)end
    function api.Next(mob)return nextHit[mob] or 0 end
    function api.Mark(mob,now,gap)nextHit[mob]=now+math.max(.3,gap or 0)end
    function api.Cancel(reason)
        state.AttackBurstActive=false
        state.ThreatReason=reason or "Paused"
    end
    function api.Destroy()api.Cancel("Script closed");table.clear(nextHit)end
    function api.Update(now,candidates,root,folder)
        state.AttackBurstActive=false
        if state.StopEverything or state.SafeModePanic or state.ModeratorBlocking or state.AutoTradeBusy then return end
        local reserve=state.ReserveGunStamina==true
        if state.SkillWantsWindow and not reserve then return "Skill aura owns damage" end
        if reserve and now<nextReserveHit then return end
        local batch=reserve and 1 or math.clamp(state.FrameRequestCap or 4,1,4)
        tokens=math.min(batch,tokens+math.max(0,now-refill)*(state.MaxRequestsPerSecond or 48))
        refill=now
        local gap=math.max(.3,state.AttackInterval or 0)
        state.EffectiveInterval=gap
        state.CurrentThreat=1;state.ThreatReason="Source per-target cooldown"
        local sent=0
        for _,mob in ipairs(candidates)do
            if sent>=batch or tokens<1 then break end
            if state.SkillRegistrationTarget and not state.Enabled and mob~=state.SkillRegistrationTarget then continue end
            if not api.Ready(mob,now)then continue end
            local data=mob.Parent==folder and ctx.GetData(mob)
            if not data or data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0)
                or data.Entity:FindFirstChild("Immortal")then continue end
            local delta=ctx.Delta and ctx.Delta(data,root)or data.Root.Position-root.Position
            local range=ctx.Radius(mob)
            if delta:Dot(delta)>range*range then continue end
            ctx.Damage(mob)
            api.Mark(mob,now,gap*math.max(1,data.AttackBackoff or 1))
            ctx.Sent(mob,data,now)
            sent+=1;tokens-=1
            if reserve then nextReserveHit=now+.5 end
        end
        if sent>0 then
            state.LastBurstSize=1
            state.BurstsSent=(state.BurstsSent or 0)+sent
            ctx.Visual()
        end
        return #candidates>0 and string.format("Active · %d targets · %d requests",#candidates,state.HitsSent or 0)or "Active · waiting for mobs"
    end
    return api
end

-- END BUNDLED ATTACK SCHEDULER
end)()(state)
local function finishAttackBurst(reason) normalScheduler.Cancel(reason) end
local createSkillBurst=(function()
-- BEGIN BUNDLED SKILL BURST
return function(ctx)
    local api={Started=false}
    local state,record=ctx.State,ctx.Record
    local observers={}
    local cancelled=false
    local rounds=math.clamp(ctx.Rounds or 3,1,ctx.RepeatWindow and 12 or 3)
    local seen={}
    record.Desired=ctx.SourceWindow and "Active window" or rounds
    record.Targets={}
    record.TotalRequests=0
    local function captureTargets(first)
        local current={}
        local included={}
        for _,mob in ipairs(ctx.Targets(first)) do
            local data=ctx.Valid(mob)
            local item=seen[mob]
            if data and not item and (ctx.SourceWindow or #record.Targets<(ctx.RefreshTargets and 16 or 8)) then
                item={Target=mob,TargetName=mob.Name,Health=data.Health,Before=data.Health.Value,Requested=0,HealthDrops=0}
                seen[mob]=item
                item.Distance=ctx.Distance and ctx.Distance(mob,data) or nil
                item.RangeDistance=ctx.RangeDistance and ctx.RangeDistance(mob,data) or item.Distance
                item.Distances={}
                if ctx.Contribution then item.BeforeContribution,item.Counter=ctx.Contribution(data.Health) end
                local previous=data.Health.Value
                observers[#observers+1]=data.Health:GetPropertyChangedSignal("Value"):Connect(function()
                    local hp=data.Health.Value
                    if hp<previous then
                        local drop=previous-hp
                        item.MinimumHealthDrop=item.MinimumHealthDrop and math.min(item.MinimumHealthDrop,drop) or drop
                        item.HealthDrops+=1; record.HealthDrops+=1
                    end
                    previous=hp
                end)
                record.Targets[#record.Targets+1]=item
                record.Before=(record.Before or 0)+item.Before
            end
            if data and item and not included[mob] then
                included[mob]=true
                current[#current+1]=item
                if not ctx.SourceWindow and #current>=8 then break end
            end
        end
        record.TargetCount=#record.Targets
        return current
    end
    local function runSourceWindow(extra)
        local nextScan=0
        local targets={}
        local tokens,refill=math.clamp(state.FrameRequestCap or 4,1,4),os.clock()
        local nextHit=setmetatable({}, {__mode="k"})
        record.Status="Source skill window"
        while not cancelled and not state.StopEverything and ctx.CanRun() and os.clock()<ctx.ExpiresAt do
            local now=os.clock()
            if now>=nextScan then targets=captureTargets();nextScan=now+.08 end
            local batch=math.clamp(state.FrameRequestCap or 4,1,4)
            tokens=math.min(batch,tokens+math.max(0,now-refill)*(state.MaxRequestsPerSecond or 48));refill=now
            local sent=0
            for _,item in ipairs(targets)do
                if sent>=batch or tokens<1 then break end
                if cancelled or state.StopEverything or not ctx.CanRun() or os.clock()>=ctx.ExpiresAt then break end
                now=os.clock()
                if ctx.Pacing and not ctx.Pacing.Ready(item.Target,now)or now<(nextHit[item.Target]or 0)then continue end
                local data=ctx.Valid(item.Target)
                if not data then continue end
                if ctx.Budget and ctx.Budget.Remaining(item,data.Health.Value,now)<=0 then
                    record.SkippedOverkill=(record.SkippedOverkill or 0)+1;continue
                end
                local hp=data.Health.Value
                if ctx.Send(item.Target,data,extra)==false then continue end
                local gap=math.max(.3,ctx.Spacing or 0)
                if ctx.Pacing then ctx.Pacing.Mark(item.Target,now,gap)end
                nextHit[item.Target]=now+gap
                if ctx.Budget then
                    local estimate=ctx.EstimateDamage and ctx.EstimateDamage(item.Target,data)or 0
                    ctx.Budget.Reserve(item,hp,estimate,now,math.max(.35,(state.PingMs or 100)/1000+.15))
                end
                if record.LastTarget and record.LastTarget~=item.Target then record.Retargets=(record.Retargets or 0)+1 end
                record.LastTarget=item.Target;record.LastRequestAt=now
                item.Requested+=1;record.TotalRequests+=1
                state.SkillHitRequests=(state.SkillHitRequests or 0)+1
                record.Requested=record.TotalRequests;state.LastSkillBurstSize=record.TotalRequests
                sent+=1;tokens-=1
            end
            task.wait(.03)
        end
        record.Status=cancelled and record.Status or "Source skill window completed"
    end
    function api.Start(first,extra)
        if cancelled or state.StopEverything or api.Started or (not ctx.RefreshTargets and not ctx.Valid(first)) then return false end
        captureTargets(first)
        if #record.Targets==0 then return false end
        api.Started=true
        api.Deadline=ctx.ExpiresAt and ctx.ExpiresAt+.15 or os.clock()+3*(ctx.Spacing+0.4)+0.5
        record.Status="Sending area skill burst"
        task.spawn(function()
            local ok,message=pcall(function()
                local delay=math.max(0,(ctx.FirstHitAt or 0)-os.clock())
                if delay>0 then task.wait(delay) end
                if ctx.SourceWindow then runSourceWindow(extra);return end
                for round=1,rounds do
                    if round>1 then
                        local due=(record.LastRequestAt or os.clock())+ctx.Spacing
                        local remaining=due-os.clock()
                        if remaining>0 then task.wait(remaining) end
                    end
                    if ctx.ExpiresAt and os.clock()>=ctx.ExpiresAt then record.Status="Skill firing window completed"; break end
                    if cancelled or state.StopEverything or not ctx.CanRun() then record.Status="Paused for movement, dodge or network"; break end
                    local targets=(ctx.RefreshTargets or ctx.FocusBudget) and captureTargets(first) or record.Targets
                    local sent=0
                    for _,item in ipairs(targets) do
                        local data=ctx.Valid(item.Target)
                        if data and ctx.FocusBudget and ctx.Budget and ctx.Budget.Remaining(item,data.Health.Value,os.clock())<=0 then
                            record.SkippedOverkill=(record.SkippedOverkill or 0)+1
                            data=nil
                        end
                        if data then
                            local batch=math.clamp(state.FrameRequestCap or 4,1,4)
                            if sent>0 and sent%batch==0 then task.wait(0.015) end
                            if cancelled or state.StopEverything or not ctx.CanRun() then break end
                            if ctx.Distance then item.Distances[#item.Distances+1]=ctx.Distance(item.Target,data) end
                            local healthBefore=data.Health.Value
                            ctx.Send(item.Target,data,extra)
                            if ctx.FocusBudget and ctx.Budget then
                                local estimate=ctx.EstimateDamage and ctx.EstimateDamage(item.Target,data) or 0
                                ctx.Budget.Reserve(item,healthBefore,estimate,os.clock(),math.max(.35,(state.PingMs or 100)/1000+.15))
                            end
                            if record.LastTarget and record.LastTarget~=item.Target then record.Retargets=(record.Retargets or 0)+1 end
                            record.LastTarget=item.Target
                            record.LastRequestAt=os.clock()
                            item.Requested+=1
                            record.TotalRequests+=1
                            state.SkillHitRequests+=1
                            sent+=1
                            if ctx.FocusBudget then break end
                        end
                    end
                    if sent==0 and not ctx.RefreshTargets then record.Status="Targets defeated or out of skill range"; break end
                    record.Requested=round
                    state.LastSkillBurstSize=round
                end
                if record.Requested==rounds then
                    record.Status=ctx.RepeatWindow and "Rifle firing sequence completed" or rounds==1 and "Skill shot sent" or "Three skill rounds sent"
                end
            end)
            if not ok then record.Status="Skill burst error"; state.LastSkillError=tostring(message) end
            record.FinishedAt=record.FinishedAt or os.clock()
        end)
        return true
    end
    function api.Finish()
        if record.ObservationFinished then return end
        record.ObservationFinished=true
        record.After,record.Damage=0,0
        for _,item in ipairs(record.Targets) do
            item.After=item.Health.Value
            item.HealthDamage=math.max(0,item.Before-item.After)
            local credited=ctx.Contribution and ctx.Contribution(item.Health,item.Counter)
            item.Damage=credited~=nil and math.max(0,credited-(item.BeforeContribution or 0)) or item.HealthDamage
            record.After+=item.After
            record.Damage+=item.Damage
        end
        for _,connection in ipairs(observers) do connection:Disconnect() end
        table.clear(observers)
    end
    function api.Cancel(reason)
        cancelled=true
        record.Status=reason or "Cast cancelled"
        record.FinishedAt=record.FinishedAt or os.clock()
        api.Finish()
    end
    return api
end

-- END BUNDLED SKILL BURST
end)()
local targetPriority=(function()
-- BEGIN BUNDLED TARGET PRIORITY
return function()
    local api={}
    local cache=setmetatable({}, {__mode="k"})
    local function clean(value) return string.lower((string.gsub(tostring(value or ""),"[^%w]",""))) end
    function api.Rank(mob)
        if not mob then return 3 end
        local entity=mob:FindFirstChild("Entity")
        local difficulty=entity and entity:FindFirstChild("Difficulty")
        local modelRank=mob:GetAttribute("Rank")
        local entityRank=entity and entity:GetAttribute("Rank")
        local difficultyRank=difficulty and difficulty.Value
        local cached=cache[mob]
        if cached and os.clock()<cached.Until and cached.Entity==entity and cached.ModelRank==modelRank
            and cached.EntityRank==entityRank and cached.Difficulty==difficultyRank then return cached.Rank end
        local main,boss,mini=false,false,false
        local function mark(value)
            local key=clean(value)
            if string.find(key,"mainboss",1,true)or string.find(key,"floorboss",1,true)then main=true
            elseif string.find(key,"mini",1,true)and string.find(key,"boss",1,true)then mini=true
            elseif string.find(key,"boss",1,true)then boss=true end
        end
        -- Read every native rank source: an unrelated model Rank must not
        -- mask the boss Difficulty or rank stored on its Entity.
        mark(modelRank);mark(entityRank);mark(difficultyRank)
        for _,instance in ipairs(entity and {mob,entity} or {mob}) do
            for _,tag in ipairs(instance:GetTags()) do mark(tag)end
        end
        local priority=3
        if main then priority=1
        elseif mini or clean(mob.Name)=="frogazoid" then priority=2
        elseif boss then priority=1 end
        cache[mob]={Rank=priority,Until=os.clock()+.15,Entity=entity,ModelRank=modelRank,EntityRank=entityRank,Difficulty=difficultyRank}
        return priority
    end
    function api.Less(a,b,origin,preferred)
        local ar,br=api.Rank(a),api.Rank(b)
        if ar~=br then return ar<br end
        if a==preferred then return b~=preferred end
        if b==preferred then return false end
        local ap=a:FindFirstChild("HumanoidRootPart")
        local bp=b:FindFirstChild("HumanoidRootPart")
        return (ap and (ap.Position-origin).Magnitude or math.huge)<(bp and (bp.Position-origin).Magnitude or math.huge)
    end
    -- A common order for farming: never use a particular account's position
    -- or previous target to break ties between otherwise eligible enemies.
    function api.FarmLess(a,b)
        if a==b then return false end
        local ar,br=api.Rank(a),api.Rank(b)
        if ar~=br then return ar<br end
        if a.Name~=b.Name then return a.Name<b.Name end
        local ap=a:FindFirstChild("HumanoidRootPart")or a.PrimaryPart or a:FindFirstChild("RootPart")
        local bp=b:FindFirstChild("HumanoidRootPart")or b.PrimaryPart or b:FindFirstChild("RootPart")
        if not ap or not bp then return ap~=nil and bp==nil end
        local av,bv=ap.Position,bp.Position
        if av.X~=bv.X then return av.X<bv.X end
        if av.Z~=bv.Z then return av.Z<bv.Z end
        return av.Y<bv.Y
    end
    return api
end

-- END BUNDLED TARGET PRIORITY
end)()()
local pendingDamage = setmetatable({}, { __mode = "k" })
local noDamageChecks = 0
local stopMovement = function() end
local nextWeaponDraw = 0
local weaponDrawThread
local trackedMobs = {}
local indexedMobFolder, mobAddedConnection, mobRemovedConnection
local nextMobReconcile = 0
local mobCache = setmetatable({}, { __mode = "k" })
local requestTokens, lastTokenRefill = 3, os.clock()
local combatStatus = "Paused"
local candidatePrimary
local configReady = false
local requestSave = function() end
local enemyHUD

local function refreshMobIndex()
    local folder = indexedMobFolder and indexedMobFolder.Parent == workspace and indexedMobFolder or workspace:FindFirstChild("Mobs")
    if folder ~= indexedMobFolder then
        if mobAddedConnection then mobAddedConnection:Disconnect() end
        if mobRemovedConnection then mobRemovedConnection:Disconnect() end
        table.clear(trackedMobs)
        table.clear(mobCache)
        indexedMobFolder = folder
        nextMobReconcile = 0
        if folder then
            mobAddedConnection = folder.ChildAdded:Connect(function(mob)
                if state.StopEverything then return end
                if mob:IsA("Model") then trackedMobs[mob] = true;state.MultiSpotNextScan=0;if state.WakeSkillAura then state.WakeSkillAura() end end
            end)
            mobRemovedConnection = folder.ChildRemoved:Connect(function(mob) trackedMobs[mob] = nil; mobCache[mob] = nil end)
        end
    end
    if folder and os.clock() >= nextMobReconcile then
        nextMobReconcile = os.clock() + 5
        for mob in pairs(trackedMobs) do if mob.Parent ~= folder then trackedMobs[mob] = nil end end
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") then trackedMobs[mob] = true end
        end
    end
    return folder
end
local function getMobData(mob)
    local cached = mobCache[mob]
    if cached and cached.Root and cached.Root.Parent and cached.Entity.Parent == mob and cached.Health.Parent == cached.Entity then
        -- HitLives can arrive or disappear independently of cached geometry.
        cached.HitLives=cached.Entity:FindFirstChild("HitLives")
        if os.clock()>=(cached.MetaAt or 0) then cached.Motion=cached.Root:FindFirstChild("BodyVelocity"); cached.MetaAt=os.clock()+.5 end
        return cached
    end
    local now = os.clock()
    if cached and cached.RetryAt and now < cached.RetryAt then return nil end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart or mob:FindFirstChild("RootPart")
    local entity = mob:FindFirstChild("Entity")
    local health = entity and entity:FindFirstChild("Health")
    if root and root:IsA("BasePart") and health then
        cached = { Root = root, Entity = entity, Health = health, HitLives=entity:FindFirstChild("HitLives"), Motion=root:FindFirstChild("BodyVelocity"), MetaAt=now+.5 }
        mobCache[mob] = cached
        return cached
    end
    mobCache[mob] = { RetryAt = now + 0.4 }
    return nil
end
function state.ReadOwnDamage(health,counter)
    counter=counter or health:FindFirstChild(player.Name)
    if counter and counter:IsA("ValueBase") and type(counter.Value)=="number" then return counter.Value,counter end
    return nil,nil
end
local function getMobRoot(mob)
    local data = getMobData(mob)
    return data and data.Root
end

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function corner(object, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, object)
end
local function bind(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

do
    local make=(function()
-- BEGIN BUNDLED ANTI AFK
-- One idle listener, no polling loop, movement or combat remote requests.
return function(ctx)
    local api={Enabled=true,Pulses=0}
    local state=ctx.State
    local stopped,busy=false,false
    local nextPulse=0
    local clock=ctx.Clock or os.clock
    state.AntiAfkStatus="Active · waiting for idle"
    local connection=ctx.Player.Idled:Connect(function()
        if stopped or busy or state.Running==false or clock()<nextPulse then return end
        busy=true;nextPulse=clock()+20
        local ok,message=pcall(ctx.Pulse)
        busy=false
        if stopped or state.Running==false then return end
        if ok then
            api.Pulses+=1;state.LastAntiAfkError=nil
            state.AntiAfkStatus="Active · idle input sent"
        else
            state.LastAntiAfkError=tostring(message)
            state.AntiAfkStatus="Idle input unavailable · retrying on next idle event"
        end
    end)
    function api.Destroy()
        if stopped then return end
        stopped=true;api.Enabled=false;connection:Disconnect()
        state.AntiAfkStatus="Stopped"
    end
    return api
end

-- END BUNDLED ANTI AFK
    end)()
    local virtualUser
    state.AntiAfk=make({State=state,Player=player,Pulse=function()
        virtualUser=virtualUser or game:GetService("VirtualUser")
        pcall(function()virtualUser:CaptureController()end)
        local camera=workspace.CurrentCamera
        virtualUser:ClickButton2(Vector2.new(0,0),camera and camera.CFrame or CFrame.new())
    end})
end

local gui=runtimeOwner.Root
local panel=create("Frame",{Name="Panel",Size=UDim2.fromOffset(300,500),Position=UDim2.new(1,-324,.5,-250),
    Visible=false,BackgroundColor3=Color3.fromRGB(20,22,31),BorderSizePixel=0},gui)
corner(panel,12)
create("UIStroke",{Color=Color3.fromRGB(60,63,83),Thickness=1},panel)
local panelScale=create("UIScale",{Scale=1},panel)
local function fitPanel()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local view=camera.ViewportSize
    panelScale.Scale=math.clamp(math.min((view.Y-48)/500,(view.X-32)/300),.35,1)
    local p=panel.AbsolutePosition
    panel.Position=UDim2.fromOffset(math.clamp(p.X,8,math.max(8,view.X-300*panelScale.Scale-8)),
        math.clamp(p.Y,8,math.max(8,view.Y-500*panelScale.Scale-8)))
end
fitPanel()
local dragBar=create("Frame",{Name="DragBar",BackgroundTransparency=1,Active=true,Size=UDim2.new(1,-84,0,62)},panel)
create("TextLabel",{Name="Eyebrow",Text="Feather",BackgroundTransparency=1,Position=UDim2.fromOffset(14,10),
    Size=UDim2.fromOffset(80,14),Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,
    TextColor3=Color3.fromRGB(157,143,255)},panel)
create("TextLabel",{Name="Version",Text="v"..state.Version,BackgroundTransparency=1,Position=UDim2.fromOffset(110,10),
    Size=UDim2.fromOffset(100,14),Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,
    TextColor3=Color3.fromRGB(137,143,164)},panel)
create("TextLabel",{Name="Title",Text="Main",BackgroundTransparency=1,Position=UDim2.fromOffset(14,28),
    Size=UDim2.fromOffset(220,26),Font=Enum.Font.GothamBold,TextSize=21,TextXAlignment=Enum.TextXAlignment.Left,
    TextColor3=Color3.fromRGB(233,235,246)},panel)
local close=create("TextButton",{Name="Close",Text="x",Font=Enum.Font.Gotham,TextSize=22,
    Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-42,0,12),BackgroundColor3=Color3.fromRGB(34,37,49),
    BorderSizePixel=0,TextColor3=Color3.fromRGB(188,192,210)},panel)
corner(close,8)
local hideUI=create("TextButton",{Name="HideUI",Text="-",Font=Enum.Font.GothamBold,TextSize=20,
    Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-78,0,12),BackgroundColor3=Color3.fromRGB(34,37,49),
    BorderSizePixel=0,TextColor3=Color3.fromRGB(188,192,210)},panel)
corner(hideUI,8)
local showUI=create("TextButton",{Name="ShowUI",Text="Show UI",Visible=false,Font=Enum.Font.GothamBold,TextSize=12,
    Size=UDim2.fromOffset(96,34),Position=UDim2.new(1,-108,0,12),BackgroundColor3=Color3.fromRGB(93,72,174),
    BorderSizePixel=0,TextColor3=Color3.fromRGB(239,234,255)},gui)
corner(showUI,8)
function state.SetUIVisible(visible)
    panel.Visible=visible==true
    showUI.Visible=not panel.Visible
    state.UIHidden=not panel.Visible
end
bind(hideUI.Activated,function()state.SetUIVisible(false)end)
bind(showUI.Activated,function()state.SetUIVisible(state.UIHidden)end)
local content=create("ScrollingFrame",{Name="Content",Position=UDim2.fromOffset(0,178),Size=UDim2.new(1,0,1,-202),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(114,100,180),
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,
    ClipsDescendants=true},panel)
create("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,12)},content)
create("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},content)
local function uiButton(name,text,order,height,parent)
    local object=create("TextButton",{Name=name,Text=text,LayoutOrder=order,Size=UDim2.new(1,0,0,height or 32),
        Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(38,41,56),
        TextColor3=Color3.fromRGB(225,228,241),TextTruncate=Enum.TextTruncate.AtEnd},parent or content)
    corner(object,8)
    return object
end
local function uiLabel(name,text,order,height,heading)
    return create("TextLabel",{Name=name,Text=text,LayoutOrder=order,Size=UDim2.new(1,0,0,height or 18),
        BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=heading and 10 or 11,
        TextColor3=heading and Color3.fromRGB(157,143,255) or Color3.fromRGB(153,161,187),
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
        TextWrapped=not heading,TextTruncate=heading and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None},content)
end
local function revealOptions(options)
    task.defer(function()
        RunService.Heartbeat:Wait()
        if not state.Running or not options.Parent or not options.Visible then return end
        local page=options.Parent
        local overflow=options.AbsolutePosition.Y+options.AbsoluteSize.Y-(page.AbsolutePosition.Y+page.AbsoluteSize.Y-8)
        if overflow>0 then
            local maximum=math.max(0,page.AbsoluteCanvasSize.Y-page.AbsoluteWindowSize.Y)
            local target=math.clamp(page.CanvasPosition.Y+overflow,0,maximum)
            TweenService:Create(page,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CanvasPosition=Vector2.new(0,target)}):Play()
        end
    end)
end
local toggle=uiButton("Toggle","Kill aura · OFF",10,38)
local farmToggle=uiButton("AutoFarm","Auto farm · OFF",20,34)
local dodgeToggle=uiButton("AutoDodge","Auto dodge · ON",10,34)
create("TextLabel",{Name="Hint",Text="Right Shift · show / hide",BackgroundTransparency=1,Position=UDim2.new(0,14,1,-20),
    Size=UDim2.new(1,-28,0,14),Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(111,121,148),
    TextXAlignment=Enum.TextXAlignment.Left},panel)
local savePending, lastSettingsEdit = false, 0
local lastSavedPayload,lastSavedStorageGeneration
local function settingsPayload()
    local position = panel.Position
    local healthPosition = enemyHUD and enemyHUD.Position or UDim2.new(0.5, 0, 0.7, 0)
    local features=state
    return {AutoTrade=state.AutoTrade,TradeMode=state.TradeMode,TradeItems=state.TradeItems,AutoDismantle=state.AutoDismantle,AutoEquipBestSword=state.AutoEquipBestSword,
        StopEverything=false,
        AutoJoinFriend=state.AutoJoinFriend,JoinFriendUsername=state.JoinFriendUsername,
        SafeMode=state.SafeMode,SafeFloorId=state.SafeFloorId,SafeWhitelistText=state.SafeWhitelistText,SafeWhitelistIds=state.SafeWhitelistIds,
        MultiSpot=state.MultiSpot,MultiSpotSelected=state.MultiSpotSelected,MultiSpotCursor=state.MultiSpotCursor,MultiSpotPending=state.MultiSpotPending,
        AccountProgression=state.AccountProgression,ProgressionFloor=state.ProgressionFloor,
        ProgressionBossCleared=state.ProgressionBossCleared,ProgressionComplete=state.ProgressionComplete,
        ProgressionBossClearedName=state.ProgressionBossClearedName,
        ProgressionRestore=state.ProgressionRestore,
        AutomationRunId=state.AutomationRunId,AutomationResumeFeatures=state.AutomationResumeFeatures,
        Version = 1, Enabled = features.Enabled, AutoFarm = features.AutoFarm,
        AutoSwing = features.AutoSwing, Radius = state.Radius, SkillRange=state.SkillRange,
        AutoOffset = true, OffsetProfiles = state.OffsetProfiles,
        UnsafeOffsetProfiles = state.UnsafeOffsetProfiles, Threat = state.Threat,
        SkillAura = features.SkillAura, SelectedSkill = state.SelectedSkill,SkillPerWeapon=state.SkillPerWeapon,SkillPerWeaponVersion=state.SkillPerWeaponVersion,
        MiscSkillEnabled=features.MiscSkillEnabled==true,SelectedMiscSkill=state.SelectedMiscSkill,
        AutoExplore = state.AutoExplore,
        AutoDodge = features.AutoDodge, AtheonDodge=features.AtheonDodge, TransparentMap = features.TransparentMap,
        PerformanceBoosters=features.PerformanceBoosters,
        PanelPosition = { position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset },
        WindUIPosition=state.WindUIPosition,
        SelectedPlayerId=state.SelectedPlayerId,
        ViewingPlayer=features.ViewingPlayer==true,ViewingPlayerInventory=features.ViewingPlayerInventory==true,
        HealthHUDPosition = { healthPosition.X.Scale, healthPosition.X.Offset, healthPosition.Y.Scale, healthPosition.Y.Offset },
    }
end
function state.SaveNow()
    if not filePersistence or state.AutoSaveSuspended then return false end
    local ok, result = pcall(function()
        if state.StorageBootstrap then local ready,reason=state.StorageBootstrap.Ensure();assert(ready,reason)end
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(configFolder) then makefolder(configFolder) end
        local payload=settingsPayload()
        local serialized = HttpService:JSONEncode(payload)
        local generation=state.StorageBootstrap and state.StorageBootstrap.Generation or 0
        if serialized ~= lastSavedPayload or generation~=lastSavedStorageGeneration
            or (typeof(readfile)=="function"and readfile(configPath)~=serialized)then
            writefile(configPath, serialized)
            lastSavedPayload = serialized;lastSavedStorageGeneration=generation
        end
    end)
    if ok and sharedSettings then
        local sharedOK,reason=pcall(sharedSettings.Save,settingsPayload())
        if not sharedOK then ok=false;result=reason end
    end
    if ok then state.ConfigSaveError = nil else state.ConfigSaveError = tostring(result) end
    state.AutoSaveStatus = ok and "Auto-save · saved" or "Auto-save · write failed"
    return ok
end
requestSave = function()
    if not configReady or not filePersistence or not state.Running or state.AutoSaveSuspended then return end
    lastSettingsEdit = os.clock()
    state.AutoSaveStatus = "Auto-save · pending"
    if savePending then return end
    savePending = true
    task.spawn(function()
        while state.Running and os.clock() - lastSettingsEdit < 0.6 do task.wait(0.15) end
        savePending = false
        if state.Running then state.SaveNow() end
    end)
end
function state.SetAutoExplore(enabled)
    state.AutoExplore = false
    requestSave()
end
if type(configData.PanelPosition) == "table" and #configData.PanelPosition == 4 then
    local position = configData.PanelPosition
    local valid = true
    for _, value in ipairs(position) do if type(value) ~= "number" or value ~= value or math.abs(value) > 100000 then valid = false end end
    if valid then
        local camera = workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            panel.Position = UDim2.fromOffset(
                math.clamp(position[1] * viewport.X + position[2], 0, math.max(0, viewport.X - 300 * panelScale.Scale)),
                math.clamp(position[3] * viewport.Y + position[4], 0, math.max(0, viewport.Y - 500 * panelScale.Scale - 8))
            )
        end
    end
end
do
    local viewportConnection
    local function watchCamera()
        if viewportConnection then viewportConnection:Disconnect() end
        fitPanel()
        local camera=workspace.CurrentCamera
        if camera then viewportConnection=bind(camera:GetPropertyChangedSignal("ViewportSize"),fitPanel) end
    end
    bind(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
    watchCamera()
end
function state.SetThreat()
    state.Threat=3
    state.BurstProgress=0
    requestSave()
end
state.SetThreat(state.Threat)

-- Each attacked mob gets an event-driven health row; only the fill is eased.
local healthHUD=(function()
-- BEGIN BUNDLED ENEMY HEALTH
return function(ctx)
    local state,create,corner=ctx.State,ctx.Create,ctx.Corner
    local now=ctx.Now or os.clock
    local rows,connections={},{}
    local healthRows={}
    local disposed=false
    local serial,nextUpdate,primary=0,0,nil
    local layoutDirty,snapshotDirty,nextRankCheck=true,true,0
    local api={Rows=rows,Count=0}
    -- Executors may reload with a fresh getgenv while the old GUI is still alive.
    -- Destroy only our previous HUD, never the game's own health displays.
    for _,child in ipairs(ctx.Parent:GetChildren()) do
        if child.Name=="EnemyHealth" and child:IsA("ScrollingFrame") then child:Destroy() end
    end
    local root=create("ScrollingFrame",{
        Name="EnemyHealth",Position=UDim2.new(.5,0,.7,0),AnchorPoint=Vector2.new(.5,.5),
        Size=UDim2.fromOffset(280,52),Visible=false,Active=true,BackgroundTransparency=1,
        BorderSizePixel=0,CanvasSize=UDim2.new(),ScrollBarThickness=0,
        ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,
    },ctx.Parent)
    api.Root=root
    create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},root)
    local function connect(signal,callback)
        local connection=signal:Connect(callback); connections[#connections+1]=connection; return connection
    end
    function api.Number(value)
        local digits=string.format("%.0f",math.floor(math.max(0,value)))
        return (string.reverse(string.gsub(string.reverse(digits),"(%d%d%d)","%1,")):gsub("^,",""))
    end
    local function viewport()
        local size=ctx.Viewport and ctx.Viewport() or ctx.Parent.AbsoluteSize
        return size.X>0 and size.Y>0 and size or Vector2.new(1280,720)
    end
    local function clampPosition()
        local size=viewport()
        local p=root.Position
        local x,y=p.X.Scale*size.X+p.X.Offset,p.Y.Scale*size.Y+p.Y.Offset
        local hw,hh=root.Size.X.Offset/2,root.Size.Y.Offset/2
        local cx=math.clamp(x,hw+4,math.max(hw+4,size.X-hw-4))
        local cy=math.clamp(y,hh+4,math.max(hh+4,size.Y-hh-4))
        if cx~=x or cy~=y then root.Position=UDim2.new(p.X.Scale,p.X.Offset+cx-x,p.Y.Scale,p.Y.Offset+cy-y) end
    end
    local function layout()
        local list={}
        for _,row in pairs(rows) do list[#list+1]=row end
        table.sort(list,function(a,b)
            local ar,br=a.Priority,b.Priority
            return ar~=br and ar<br or ar==br and a.Serial<b.Serial
        end)
        local compact=#list>1
        local width,height=compact and 244 or 280,compact and 42 or 52
        local total=math.max(height,#list*(height+5)-5)
        local maximum=math.max(52,math.min(360,math.floor(viewport().Y*.45)))
        root.Size=UDim2.fromOffset(width,math.min(total,maximum))
        root.CanvasSize=UDim2.fromOffset(0,total)
        root.ScrollBarThickness=total>maximum and 3 or 0
        root.Visible=#list>0
        api.Count=#list; state.HealthHUDCount=#list
        for index,row in ipairs(list) do
            row.Frame.LayoutOrder=index
            row.Frame.Size=UDim2.fromOffset(width,height)
            row.Name.Size=UDim2.fromOffset(width-20,15)
            row.Name.TextSize=compact and 11 or 12
            row.Track.Position=UDim2.fromOffset(10,compact and 22 or 25)
            row.Track.Size=UDim2.fromOffset(width-20,compact and 6 or 7)
            row.Numbers.Position=UDim2.fromOffset(10,compact and 30 or 35)
            row.Numbers.Size=UDim2.fromOffset(width-20,compact and 11 or 13)
            row.Numbers.TextSize=compact and 9 or 10
        end
        clampPosition()
        layoutDirty=false
    end
    local function remove(mob)
        local row=rows[mob]
        if not row then return end
        rows[mob]=nil
        if healthRows[row.Health]==row then healthRows[row.Health]=nil end
        layoutDirty,snapshotDirty=true,true
        for _,connection in ipairs(row.Connections) do connection:Disconnect() end
        if row.Tween then row.Tween:Cancel() end
        row.Frame:Destroy()
    end
    function api.Touch(mob)
        if disposed or not root.Parent or not state.Running or not mob or not mob.Parent then return end
        local row=rows[mob]
        if row then row.LastAttack=now(); return end
        local data=ctx.GetData(mob)
        if not data or not data.Health or data.Health.Value<=0 then return end
        local sameHealth=healthRows[data.Health]
        if sameHealth then sameHealth.LastAttack=now();return end
        serial+=1
        row={Mob=mob,Health=data.Health,LastAttack=now(),Serial=serial,Connections={},ObservedMax=data.Health.Value,Priority=ctx.Priority and ctx.Priority(mob) or 3}
        rows[mob]=row
        healthRows[data.Health]=row
        layoutDirty,snapshotDirty=true,true
        row.Frame=create("Frame",{Name="Target_"..serial,Size=UDim2.fromOffset(280,52),BackgroundColor3=Color3.fromRGB(42,42,44),BackgroundTransparency=0,BorderSizePixel=0},root)
        row.Frame:SetAttribute("TargetName",mob.Name)
        corner(row.Frame,14)
        create("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=.92},row.Frame)
        row.Name=create("TextLabel",{Name="Name",Text=mob.Name,BackgroundTransparency=1,Position=UDim2.fromOffset(10,4),Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.fromRGB(255,255,255),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
        row.Track=create("Frame",{Name="Track",BackgroundColor3=Color3.fromRGB(24,24,26),BorderSizePixel=0},row.Frame)
        corner(row.Track,3)
        row.Fill=create("Frame",{Name="Fill",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(51,199,89),BorderSizePixel=0},row.Track)
        corner(row.Fill,3)
        row.Numbers=create("TextLabel",{Name="Values",BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(161,161,170),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
        local maximum=data.Entity:FindFirstChild("MaxHealth")
        local constrained=data.Health:IsA("IntConstrainedValue") or data.Health:IsA("DoubleConstrainedValue")
        local initial=true
        local function render()
            if disposed or not root.Parent or not state.Running or rows[mob]~=row then return end
            local hp=math.max(0,row.Health.Value)
            row.ObservedMax=math.max(row.ObservedMax,hp)
            local maxHP=math.max(1,constrained and row.Health.MaxValue or maximum and maximum.Value or row.ObservedMax)
            local fraction=math.clamp(hp/maxHP,0,1)
            local color=Color3.fromRGB(51,199,89)
            if row.Tween then row.Tween:Cancel() end
            if initial then row.Fill.Size=UDim2.fromScale(fraction,1); row.Fill.BackgroundColor3=color; initial=false
            else row.Tween=ctx.TweenService:Create(row.Fill,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(fraction,1),BackgroundColor3=color}); row.Tween:Play() end
            row.Numbers.Text=string.format("%s / %s HP · %.0f%%",api.Number(hp),api.Number(maxHP),fraction*100)
            row.Current,row.Maximum=hp,maxHP
            snapshotDirty=true
            row.DeadAt=hp<=0 and (row.DeadAt or now()) or nil
            if mob==primary or api.Count<=1 then state.ObservedHealth,state.ObservedMaxHealth=hp,maxHP end
            state.HealthUpdates=(state.HealthUpdates or 0)+1
        end
        row.Connections[#row.Connections+1]=data.Health:GetPropertyChangedSignal("Value"):Connect(render)
        if constrained then row.Connections[#row.Connections+1]=data.Health:GetPropertyChangedSignal("MaxValue"):Connect(render)
        elseif maximum and maximum:IsA("ValueBase") then row.Connections[#row.Connections+1]=maximum.Changed:Connect(render) end
        render(); layout()
    end
    function api.Focus(mob) primary=mob end
    function api.Update()
        if disposed or not root.Parent then return end
        local time=now()
        if time<nextUpdate then return end
        nextUpdate=time+.12
        local refreshRanks=time>=nextRankCheck
        if refreshRanks then nextRankCheck=time+.5 end
        for mob,row in pairs(rows) do
            local present=mob.Parent and row.Health.Parent and (not ctx.Present or ctx.Present(mob))
            if row.DeadAt then if time-row.DeadAt>.45 then remove(mob) end
            elseif not present or (time-row.LastAttack>1.4 and not (mob==primary and (state.SkillPreparing or state.SkillCastRunning))) then remove(mob) end
            if rows[mob] and refreshRanks and ctx.Priority then
                local priority=ctx.Priority(mob)
                if priority~=row.Priority then row.Priority=priority; layoutDirty=true end
            end
        end
        if snapshotDirty then
            local snapshot={}
            for mob,row in pairs(rows) do snapshot[#snapshot+1]={Name=mob.Name,Health=row.Current,MaxHealth=row.Maximum} end
            state.HealthHUDTargets=snapshot
            snapshotDirty=false
        end
        if layoutDirty then layout() end
    end
    local position=ctx.Position
    if type(position)=="table" and #position==4 then
        local valid=true
        for _,value in ipairs(position) do if type(value)~="number" or value~=value or math.abs(value)>100000 then valid=false end end
        if valid then root.Position=UDim2.new(position[1],position[2],position[3],position[4]); clampPosition() end
    end
    connect(ctx.Parent:GetPropertyChangedSignal("AbsoluteSize"),function() layoutDirty=true end)
    local dragInput,dragStart,dragPosition
    connect(root.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragInput,dragStart,dragPosition=input,input.Position,root.Position end
    end)
    connect(ctx.Input.InputChanged,function(input)
        if dragInput and (input==dragInput or input.UserInputType==Enum.UserInputType.MouseMovement) then
            local delta=input.Position-dragStart
            root.Position=UDim2.new(dragPosition.X.Scale,dragPosition.X.Offset+delta.X,dragPosition.Y.Scale,dragPosition.Y.Offset+delta.Y)
            clampPosition()
        end
    end)
    connect(ctx.Input.InputEnded,function(input) if input==dragInput or (dragInput and input.UserInputType==Enum.UserInputType.MouseButton1 and dragInput.UserInputType==Enum.UserInputType.MouseButton1) then dragInput=nil; if ctx.Save then ctx.Save() end end end)
    function api.Destroy(fromDestroying)
        if disposed then return end
        disposed=true
        for _,connection in ipairs(connections) do connection:Disconnect() end
        local mobs={}; for mob in pairs(rows) do mobs[#mobs+1]=mob end
        for _,mob in ipairs(mobs) do remove(mob) end
        api.Count=0; state.HealthHUDCount=0; state.HealthHUDTargets={}
        if not fromDestroying then root:Destroy() end
    end
    connect(root.Destroying,function()api.Destroy(true)end)
    return api
end

-- END BUNDLED ENEMY HEALTH
end)()({State=state,Parent=gui,Create=create,Corner=corner,GetData=getMobData,
    TweenService=TweenService,Input=UserInputService,Position=configData.HealthHUDPosition,Save=requestSave,
    Priority=function(mob) return targetPriority.Rank(mob) end,
    Present=function(mob) return mob:IsDescendantOf(workspace) end,
})
enemyHUD=healthHUD.Root
local function trackHealth(mob) healthHUD.Focus(mob) end

uiLabel("SkillHeading","SKILL AURA",50,16,true)
local skillToggle=uiButton("SkillAura","Skill aura · OFF",60,34)
local skillDropdown=uiButton("SkillDropdown",state.SelectedSkill.."  v",70,32)
skillDropdown.Font=Enum.Font.Gotham
local skillList=create("ScrollingFrame",{Name="SkillOptions",Visible=false,LayoutOrder=80,Size=UDim2.new(1,0,0,138),
    BackgroundColor3=Color3.fromRGB(31,33,46),BorderSizePixel=0,ScrollBarThickness=3,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true},content)
corner(skillList,8)
create("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},skillList)
create("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},skillList)
function state.SetSkillRange(value)
    state.SkillRange=math.clamp(math.floor(tonumber(value) or state.SkillRange),20,120)
end
local AttackStats = require(ReplicatedStorage.Shared.Library.AttackStats)
local function refreshSkillChoices()
    local choices=state.WeaponSkills and state.WeaponSkills.Choices() or {}
    state.SkillChoices=choices
    for _,child in ipairs(skillList:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    for index,name in ipairs(choices) do
        local option=uiButton("Option"..index,name,index,28,skillList)
        option.Font=Enum.Font.Gotham
        option.BackgroundColor3=name==state.SelectedSkill and Color3.fromRGB(91,72,164) or Color3.fromRGB(41,44,59)
        option.Activated:Connect(function() state.SetSelectedSkill(name) end)
    end
    if #choices==0 then
        create("TextLabel",{Name="Empty",Text="Equip a compatible weapon",Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,
            Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.fromRGB(153,161,187)},skillList)
    end
end
function state.SetSelectedSkill(name)
    if not state.WeaponSkills or not state.WeaponSkills.Select(name) then return false end
    skillList.Visible=false
    return true
end
function state.SetSkillAura(enabled)
    if state.StopEverything and enabled==true then return false end
    state.SkillAura = enabled == true
    if state.AuraTouch then state.AuraTouch.Update()end
    if state.WakeSkillAura then state.WakeSkillAura() end
    if not state.SkillAura and state.CancelSkillAura then state.CancelSkillAura("Skill aura disabled") end
    skillToggle.Text = state.SkillAura and "Skill aura · ON" or "Skill aura · OFF"
    skillToggle.BackgroundColor3 = state.SkillAura and Color3.fromRGB(114, 88, 229) or Color3.fromRGB(45, 48, 63)
    state.SkillStatus = state.SkillAura and "Waiting for a nearby enemy" or "Skill aura is off"
    requestSave()
end
bind(skillToggle.Activated, function() state.SetSkillAura(not state.SkillAura) end)
bind(skillDropdown.Activated, function()
    if state.StopEverything then return end
    if state.SetTravelOpen then state.SetTravelOpen(false) end
    if state.UI and state.UI.MiscSkillOptions then state.UI.MiscSkillOptions.Visible=false end
    if not skillList.Visible then refreshSkillChoices() end
    skillList.Visible = not skillList.Visible
    if skillList.Visible then revealOptions(skillList) end
end)
refreshSkillChoices()

local travelHeading=uiLabel("TravelHeading","FLOOR TELEPORTS",100,16,true)
local travelDropdown=uiButton("TeleportDropdown","Teleport",110,32)
travelDropdown.Font=Enum.Font.Gotham
local travelList=create("ScrollingFrame",{Name="TeleportOptions",Visible=false,LayoutOrder=120,Size=UDim2.new(1,0,0,180),
    BackgroundColor3=Color3.fromRGB(31,33,46),BorderSizePixel=0,ScrollBarThickness=3,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true},content)
corner(travelList,8)
create("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},travelList)
create("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},travelList)
state.TravelStatus=""
local function setTravelStatus(message)
    state.TravelStatus=message
end
local function setTravelOpen(open)
    if open and state.StopEverything then return false end
    travelList.Visible=open
    if open then skillList.Visible=false; revealOptions(travelList) end
end
state.SetTravelOpen=setTravelOpen
state.UI={Root=gui,Panel=panel,Content=content,SkillOptions=skillList,TravelOptions=travelList,Pages={Main=content},TabButtons={}}
do
    local pages=state.UI.Pages
    local tabs={"Main","Combat","Challenge Floors","Auto Skill","Misc","Player","Utility","Speacial"}
    for _,name in ipairs(tabs) do
        if name~="Main" then
            local page=content:Clone()
            page.Name=name; page.Visible=false
            for _,child in ipairs(page:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
            page.CanvasPosition=Vector2.zero; page.Parent=panel
            pages[name]=page
        end
    end
    toggle.Parent=pages.Combat; farmToggle.Parent=pages.Combat
    local bestSword=uiButton("AutoEquipBestSword","Auto Equip Best Weapon",25,34,pages.Combat)
    state.UI.AutoEquipBestSword=bestSword
    function state.SetAutoEquipBestSword(on)
        state.AutoEquipBestSword=on==true
        bestSword.Text=state.AutoEquipBestSword and "Auto Equip Best Weapon · ON" or "Auto Equip Best Weapon · OFF"
        bestSword.BackgroundColor3=state.AutoEquipBestSword and Color3.fromRGB(91,72,164) or Color3.fromRGB(38,41,56)
        if state.ProgressionGearController then state.ProgressionGearController.Reset()end
        requestSave()
    end
    bind(bestSword.Activated,function()state.SetAutoEquipBestSword(not state.AutoEquipBestSword)end)
    state.SetAutoEquipBestSword(restore.AutoEquipBestSword)

    state.UI.AtheonDodge=uiButton("AtheonDodge","Atheon Dodge · OFF",30,34,pages.Combat)
    function state.SetAtheonDodge(on)
        state.AtheonDodge=on==true
        local button=state.UI.AtheonDodge
        button.Text=state.AtheonDodge and "Atheon Dodge · ON" or "Atheon Dodge · OFF"
        button.BackgroundColor3=state.AtheonDodge and Color3.fromRGB(91,72,164) or Color3.fromRGB(38,41,56)
        if not state.AtheonDodge and state.AtheonDodgeController then state.AtheonDodgeController.Reset() end
        requestSave()
    end
    bind(state.UI.AtheonDodge.Activated,function()state.SetAtheonDodge(not state.AtheonDodge)end)
    state.SetAtheonDodge(restore.AtheonDodge)
    dodgeToggle.Parent=pages["Challenge Floors"]
    for _,child in ipairs(content:GetChildren()) do
        if child:IsA("GuiObject") and (child.Name=="SkillHeading" or string.sub(child.Name,1,5)=="Skill") then child.Parent=pages["Auto Skill"] end
    end
    local navigation=create("Frame",{Name="Tabs",BackgroundTransparency=1,Position=UDim2.fromOffset(14,66),Size=UDim2.new(1,-28,0,102)},panel)
    local slots={Main={0,0,1/3},Combat={1/3,0,1/3},["Auto Skill"]={2/3,0,1/3},["Challenge Floors"]={0,36,1/2},Utility={1/2,36,1/2},Misc={0,72,1/3},Player={1/3,72,1/3},Speacial={2/3,72,1/3}}
    function state.SetTab(name)
        if not pages[name] then return false end
        skillList.Visible=false; travelList.Visible=false
        if state.CloseAutomationMenus then state.CloseAutomationMenus() end
        if state.UI.PlayerOptions then state.UI.PlayerOptions.Visible=false end
        if state.UI.MiscSkillOptions then state.UI.MiscSkillOptions.Visible=false end
        if state.UI.BoostOptions then state.UI.BoostOptions.Visible=false end
        for key,page in pairs(pages) do page.Visible=key==name end
        for key,button in pairs(state.UI.TabButtons) do
            local selected=key==name
            button.BackgroundColor3=selected and Color3.fromRGB(93,72,174) or Color3.fromRGB(31,34,47)
            button.TextColor3=selected and Color3.fromRGB(239,234,255) or Color3.fromRGB(168,175,197)
        end
        panel.Title.Text=name
        state.UI.ActiveTab=name
        return true
    end
    for _,name in ipairs(tabs) do
        local slot=slots[name]
        local button=uiButton("Tab"..name,name,1,28,navigation)
        button.Position=UDim2.new(slot[1],slot[1]>0 and 3 or 0,0,slot[2])
        button.Size=UDim2.new(slot[3],-4,0,28); button.TextSize=10
        state.UI.TabButtons[name]=button
        bind(button.Activated,function() state.SetTab(name) end)
    end
    local miscHeading=uiLabel("MiscSkillHeading","MISC SKILL",90,16,true)
    miscHeading.Parent=pages["Auto Skill"]
    state.UI.MiscSkillToggle=uiButton("MiscSkillToggle","Misc Skill · OFF",100,34,pages["Auto Skill"])
    state.UI.MiscSkillDropdown=uiButton("MiscSkillDropdown",state.SelectedMiscSkill.."  v",110,32,pages["Auto Skill"])
    state.UI.MiscSkillDropdown.Font=Enum.Font.Gotham
    state.UI.MiscSkillOptions=create("ScrollingFrame",{Name="MiscSkillOptions",Visible=false,LayoutOrder=120,Size=UDim2.new(1,0,0,116),
        BackgroundColor3=Color3.fromRGB(31,33,46),BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new(),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true},pages["Auto Skill"])
    corner(state.UI.MiscSkillOptions,8)
    create("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},state.UI.MiscSkillOptions)
    create("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},state.UI.MiscSkillOptions)
    local buttons={Dismantle="openDismantle",Upgrade="openUpgrade",["The Forge"]="openCrystalForge"}
    state.MiscMenuMethods=buttons
    function state.OpenGameMenu(name)
        if state.StopEverything then return false,"Stop Everything is on" end
        local method=buttons[name]
        if not method or type(GameUI[method])~="function" then return false,"Menu is unavailable" end
        local ok,message=pcall(GameUI[method])
        if not ok then state.LastMenuError=tostring(message) end
        return ok,message
    end
    for index,name in ipairs({"Dismantle","Upgrade","The Forge"}) do
        local button=uiButton("Open"..name,name,index,36,pages.Misc)
        bind(button.Activated,function() state.OpenGameMenu(name) end)
    end
    state.UI.BoostDropdown=uiButton("PerformanceBoosters","Performance boosters  v",10,34,pages.Utility)
    state.UI.BoostOptions=create("ScrollingFrame",{Name="BoostOptions",Visible=false,LayoutOrder=20,Size=UDim2.new(1,0,0,206),
        BackgroundColor3=Color3.fromRGB(31,33,46),BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},pages.Utility)
    corner(state.UI.BoostOptions,8)
    create("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},state.UI.BoostOptions)
    create("UIPadding",{PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},state.UI.BoostOptions)
    state.UI.BoostButtons={}
    for index,name in ipairs({"No damage text","No damage particles","Delete dead mobs","No vel obtained in chat","Hide players","Hide effects","Disable rendering","Limit FPS"}) do
        local button=uiButton("Boost"..index,name,index,28,state.UI.BoostOptions)
        button.Font=Enum.Font.Gotham; button.TextSize=11
        state.UI.BoostButtons[name]=button
        bind(button.Activated,function() if state.SetPerformanceBoost then state.SetPerformanceBoost(name,not state.PerformanceBoosters[name]) end end)
    end
    bind(state.UI.BoostDropdown.Activated,function()
        if state.StopEverything then return end
        state.UI.BoostOptions.Visible=not state.UI.BoostOptions.Visible
        if state.UI.BoostOptions.Visible then revealOptions(state.UI.BoostOptions) end
    end)
    state.UI.PlayerSelector=uiButton("PlayerSelector","Select player",10,32,pages.Player)
    state.UI.PlayerOptions=create("ScrollingFrame",{Name="PlayerOptions",Visible=false,LayoutOrder=20,Size=UDim2.new(1,0,0,116),
        BackgroundColor3=Color3.fromRGB(31,33,46),BorderSizePixel=0,ScrollBarThickness=3,
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true},pages.Player)
    corner(state.UI.PlayerOptions,8)
    create("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},state.UI.PlayerOptions)
    create("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},state.UI.PlayerOptions)
    state.UI.TeleportPlayer=uiButton("TeleportPlayer","TP to player",30,34,pages.Player)
    state.UI.ViewPlayer=uiButton("ViewPlayer","View player · OFF",40,34,pages.Player)
    state.UI.ViewInventory=uiButton("ViewInventory","View player inventory · OFF",50,34,pages.Player)
    state.UI.PlayerInventory=create("ScrollingFrame",{Name="PlayerInventory",Visible=false,LayoutOrder=60,Size=UDim2.new(1,0,0,180),
        BackgroundColor3=Color3.fromRGB(27,30,43),BorderSizePixel=0,ScrollBarThickness=3,
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true},pages.Player)
    corner(state.UI.PlayerInventory,8)
    create("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},state.UI.PlayerInventory)
    create("UIPadding",{PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},state.UI.PlayerInventory)
    state.UI.PlayerMessage=create("TextLabel",{Name="PlayerMessage",Text="",Visible=false,LayoutOrder=70,Size=UDim2.new(1,0,0,30),
        BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextColor3=Color3.fromRGB(179,184,205)},pages.Player)
    state.SetTab(previous and previous.UI and previous.UI.ActiveTab or "Main")
end



do
    local function renderBoost()
        local count=0
        for name,button in pairs(state.UI.BoostButtons) do
            local enabled=state.PerformanceBoosters[name]==true
            if enabled then count+=1 end
            local label=name=="Limit FPS" and "Limit FPS (15 FPS)" or name=="Disable rendering" and "Disable 3D rendering" or name
            if name=="No damage text" then label="Hide damage text" elseif name=="No vel obtained in chat" then label="Hide Vel in chat" end
            button.Text=(enabled and "[ON]  " or "[OFF]  ")..label
            button.BackgroundColor3=enabled and Color3.fromRGB(93,72,174) or Color3.fromRGB(38,41,56)
        end
        state.UI.BoostDropdown.Text="Performance boosters"..(count>0 and " ("..count..")" or "").."  v"
    end
    local createPlayerVisibility=(function()
-- BEGIN BUNDLED HIDE PLAYERS
-- Local rendering only. Never hide the local character or change physics.
return function(ctx)
    local api={BlockedEffects=0}
    local enabled,disposed=false,false
    local hideCharacters,hideEffects=false,false
    local players,connections,characters={},{},{}
    local itemFolder,itemConnections=nil,{}
    local effectHooks={}
    local selector="BasePart,Decal,ParticleEmitter,Beam,Trail,Light,Highlight,BillboardGui,SurfaceGui,Humanoid,Sound"
    local invisible=NumberSequence.new(1)
    local function restore(record)
        for _,connection in ipairs(record.Connections) do connection:Disconnect() end
        for _,connection in pairs(record.Guards) do connection:Disconnect() end
        for instance,properties in pairs(record.Properties) do
            for name,value in pairs(properties) do pcall(function() instance[name]=value end) end
        end
    end
    local function detach(character)
        local record=characters[character]
        if record then characters[character]=nil; restore(record) end
    end
    local function attach(player,character)
        if disposed or not enabled or player==ctx.Players.LocalPlayer or not character or characters[character] then return end
        local record={Properties={},Connections={},Guards={}}
        characters[character]=record
        local function hide(instance)
            if disposed or not enabled or characters[character]~=record or record.Properties[instance] then return end
            local properties
            if instance:IsA("BasePart") and hideCharacters then properties={Transparency=1,LocalTransparencyModifier=1,CastShadow=false}
            elseif instance:IsA("Decal") and hideCharacters then properties={Transparency=1}
            elseif instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then properties={Enabled=false,Transparency=invisible}
            elseif instance:IsA("Highlight") then properties={Enabled=false}
            elseif (instance:IsA("BillboardGui") or instance:IsA("SurfaceGui")) and hideCharacters then properties={Enabled=false}
            elseif instance:IsA("Light") then properties={Brightness=0}
            elseif instance:IsA("Sound") then properties={Volume=0}
            elseif instance:IsA("Humanoid") and hideCharacters then properties={DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None} end
            if not properties then return end
            local before={}
            for name,value in pairs(properties) do before[name]=instance[name]; instance[name]=value end
            record.Properties[instance]=before
            if properties.Enabled==false then
                record.Guards[instance]=instance:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if enabled and not disposed and characters[character]==record and record.Properties[instance] and instance.Enabled then instance.Enabled=false end
                end)
            end
            if instance:IsA("ParticleEmitter") then instance:Clear() end
        end
        record.Connections[1]=character.DescendantAdded:Connect(hide)
        record.Connections[2]=character.DescendantRemoving:Connect(function(instance)
            local before=record.Properties[instance]
            if before then
                record.Properties[instance]=nil
                if record.Guards[instance] then record.Guards[instance]:Disconnect(); record.Guards[instance]=nil end
                for name,value in pairs(before) do pcall(function() instance[name]=value end) end
            end
        end)
        for _,instance in ipairs(character:QueryDescendants(selector)) do hide(instance) end
    end
    local function removePlayer(player)
        local record=players[player]
        if not record then return end
        for _,connection in ipairs(record.Connections) do connection:Disconnect() end
        if record.Character then detach(record.Character) end
        if record.Items then detach(record.Items) end
        players[player]=nil
    end
    local function attachItems(player)
        local record=players[player]
        if not record then return end
        local items=itemFolder and itemFolder:FindFirstChild(tostring(player.UserId))
        if items==record.Items then return end
        if record.Items then detach(record.Items) end
        record.Items=items
        attach(player,items)
    end
    local function watchItems()
        local folder=ctx.Workspace and ctx.Workspace:FindFirstChild("CharacterItems")
        if folder==itemFolder then return end
        for _,connection in ipairs(itemConnections) do connection:Disconnect() end
        table.clear(itemConnections)
        itemFolder=folder
        if folder then
            itemConnections[1]=folder.ChildAdded:Connect(function(child)
                for player in pairs(players) do if child.Name==tostring(player.UserId) then attachItems(player) end end
            end)
            itemConnections[2]=folder.ChildRemoved:Connect(function(child)
                for _,record in pairs(players) do if record.Items==child then detach(child); record.Items=nil end end
            end)
        end
        for player in pairs(players) do attachItems(player) end
    end
    local function addPlayer(player)
        if disposed or not enabled or player==ctx.Players.LocalPlayer or players[player] then return end
        local record={Connections={}}
        players[player]=record
        local function changed(character)
            if record.Character then detach(record.Character) end
            record.Character=character; attach(player,character)
        end
        record.Connections[1]=player.CharacterAdded:Connect(changed)
        record.Connections[2]=player.CharacterRemoving:Connect(function(character)
            detach(character); if record.Character==character then record.Character=nil end
        end)
        changed(player.Character)
        attachItems(player)
    end
    local function owner(value)
        if typeof(value)~="Instance" and type(value)~="table" then return nil end
        if value==ctx.Players.LocalPlayer then return false end
        for player,record in pairs(players) do
            if value==player then return true end
            if typeof(value)=="Instance" then
                if record.Character and (value==record.Character or value:IsDescendantOf(record.Character)) then return true end
                if record.Items and (value==record.Items or value:IsDescendantOf(record.Items)) then return true end
            end
        end
        local localCharacter=ctx.Players.LocalPlayer.Character
        if typeof(value)=="Instance" and localCharacter and (value==localCharacter or value:IsDescendantOf(localCharacter)) then return false end
        return nil
    end
    function api.IsOtherEffect(data)
        if type(data)~="table" then return owner(data)==true end
        -- Only source/caster fields; target ownership must not suppress hazards.
        for _,field in ipairs({"Character","Player","SourceCharacter","SourcePlayer","Caster"}) do
            local result=owner(data[field])
            if result~=nil then return result end
        end
        return false
    end
    local function hookEffects()
        for _,service in ipairs(ctx.EffectServices or {}) do
            if type(service.DoEffect)=="function" then
                local previous=service.DoEffect
                local wrapper=function(name,data,...)
                    if enabled and not disposed and name~="Damage Text" and api.IsOtherEffect(data) then api.BlockedEffects+=1; return end
                    return previous(name,data,...)
                end
                service.DoEffect=wrapper
                effectHooks[#effectHooks+1]={Service=service,Previous=previous,Wrapper=wrapper}
            end
        end
    end
    local function clear()
        for _,connection in ipairs(connections) do connection:Disconnect() end
        table.clear(connections)
        for _,connection in ipairs(itemConnections) do connection:Disconnect() end
        table.clear(itemConnections); itemFolder=nil
        for _,hook in ipairs(effectHooks) do if hook.Service.DoEffect==hook.Wrapper then hook.Service.DoEffect=hook.Previous end end
        table.clear(effectHooks)
        for player in pairs(players) do removePlayer(player) end
        for character in pairs(characters) do detach(character) end
    end
    local function setMode(charactersValue,effectsValue)
        if disposed then return false end
        charactersValue=charactersValue==true; effectsValue=effectsValue==true
        local wasEnabled,wasCharacters=enabled,hideCharacters
        hideCharacters,hideEffects=charactersValue,effectsValue
        enabled=hideCharacters or hideEffects
        if wasEnabled==enabled and wasCharacters==hideCharacters then return true end
        clear()
        if not enabled then return true end
        connections[1]=ctx.Players.PlayerAdded:Connect(addPlayer)
        connections[2]=ctx.Players.PlayerRemoving:Connect(removePlayer)
        if ctx.Workspace then
            connections[3]=ctx.Workspace.ChildAdded:Connect(function(child) if child.Name=="CharacterItems" then watchItems() end end)
            connections[4]=ctx.Workspace.ChildRemoved:Connect(function(child) if child==itemFolder then watchItems() end end)
        end
        watchItems(); hookEffects()
        for _,player in ipairs(ctx.Players:GetPlayers()) do addPlayer(player) end
        return true
    end
    function api.Set(value) return setMode(value,hideEffects) end
    function api.SetEffects(value) return setMode(hideCharacters,value) end
    function api.Destroy()
        if disposed then return end
        disposed=true; enabled=false; clear()
    end
    return api
end

-- END BUNDLED HIDE PLAYERS
    end)()
    local playerVisibility=createPlayerVisibility({Players=Players,Workspace=workspace,
        EffectServices={require(services.Graphics),require(services.SkillEffects)}})
    state.PlayerVisibility=playerVisibility
    local createBoost=(function()
-- BEGIN BUNDLED PERFORMANCE BOOST
-- Source performance options; text is visible unless explicitly hidden.
return function(ctx)
    local state=ctx.State
    local api={Names={"No damage text","No damage particles","Delete dead mobs","No vel obtained in chat","Hide players","Hide effects","Disable rendering","Limit FPS"}}
    local options,known={},{}
    for _,name in ipairs(api.Names) do known[name]=true; options[name]=ctx.Options and ctx.Options[name]==true end
    state.PerformanceBoosters=options
    local disposed=false
    local hitFolder,added,removed
    local particles={}
    local invisible=NumberSequence.new(1)
    local graphics=ctx.Graphics
    local original,wrapper
    local uiOriginal,uiWrapper
    local renderOwned,fpsOwned=false,false
    local oldCap
    if ctx.GetFPS then local ok,value=pcall(ctx.GetFPS); if ok and type(value)=="number" then oldCap=value end end
    local function active(name) return not disposed and not ctx.Paused and state.Running and not state.StopEverything and options[name] end
    local function restoreParticles()
        for instance,record in pairs(particles) do pcall(function() instance.Enabled=record.Enabled; instance.Transparency=record.Transparency end) end
        table.clear(particles)
    end
    local function suppress(instance)
        if not active("No damage particles") or particles[instance] then return end
        if not (instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail")) then return end
        particles[instance]={Enabled=instance.Enabled,Transparency=instance.Transparency}
        instance.Enabled=false; instance.Transparency=invisible
        if instance:IsA("ParticleEmitter") then instance:Clear() end
    end
    local function detachParticles()
        if added then added:Disconnect(); added=nil end
        if removed then removed:Disconnect(); removed=nil end
        restoreParticles(); hitFolder=nil
    end
    local function attachParticles()
        local folder=ctx.Workspace:FindFirstChild("HitEffects")
        if folder==hitFolder then return end
        detachParticles(); hitFolder=folder
        if not folder then return end
        added=folder.DescendantAdded:Connect(suppress)
        removed=folder.DescendantRemoving:Connect(function(instance)
            local record=particles[instance]
            if record then pcall(function() instance.Enabled=record.Enabled; instance.Transparency=record.Transparency end); particles[instance]=nil end
        end)
        for _,instance in ipairs(folder:QueryDescendants("ParticleEmitter,Beam,Trail")) do suppress(instance) end
    end
    local function hookGraphics()
        if wrapper and graphics.ServerEvent==wrapper then return end
        original=graphics.ServerEvent
        local previous=original
        wrapper=function(payload,...)
            if active("No damage text") and type(payload)=="table" and payload[1]=="Damage Text" then return end
            if active("Delete dead mobs") and type(payload)=="table" and payload[1]=="KillFade" then
                local mob=payload[2]
                local mobs=ctx.Workspace:FindFirstChild("Mobs")
                if typeof(mob)=="Instance" and mob:IsA("Model") and mobs and mob:IsDescendantOf(mobs) then
                    local entity=mob:FindFirstChild("Entity")
                    local health=entity and entity:FindFirstChild("Health")
                    if health and health.Value<=0 then mob:Destroy(); return end
                end
            end
            return previous(payload,...)
        end
        graphics.ServerEvent=wrapper
    end
    local function unhookGraphics()
        if wrapper and graphics.ServerEvent==wrapper then graphics.ServerEvent=original end
        -- A newer wrapper may still call ours; keep its captured original valid.
    end
    local function hookUI()
        if uiWrapper and ctx.UI.ServerEvent==uiWrapper then return end
        uiOriginal=ctx.UI.ServerEvent
        local previous=uiOriginal
        uiWrapper=function(payload,...)
            if active("No vel obtained in chat") and type(payload)=="table" and payload[2]=="VelObtained" then return end
            return previous(payload,...)
        end
        ctx.UI.ServerEvent=uiWrapper
    end
    local function unhookUI()
        if uiWrapper and ctx.UI.ServerEvent==uiWrapper then ctx.UI.ServerEvent=uiOriginal end
    end
    local rootAdded=ctx.Workspace.ChildAdded:Connect(function(instance)
        if instance.Name=="HitEffects" and active("No damage particles") then attachParticles() end
    end)
    function api.Set(name,enabled)
        if disposed or ctx.Paused or not known[name] or state.StopEverything then return false end
        enabled=enabled==true
        if name=="Disable rendering" then
            local ok,message=pcall(ctx.SetRendering,not enabled)
            if not ok then state.LastBoostError=tostring(message); return false end
            renderOwned=enabled
        elseif name=="Limit FPS" then
            if not ctx.SetFPS or oldCap==nil then state.LastBoostError="FPS cap control is unavailable"; return false end
            local ok,message=pcall(ctx.SetFPS,enabled and 15 or oldCap)
            if not ok then state.LastBoostError=tostring(message); return false end
            fpsOwned=enabled
        elseif name=="Hide players" then
            if not ctx.PlayerVisibility or not ctx.PlayerVisibility.Set(enabled) then return false end
        elseif name=="Hide effects" then
            if not ctx.PlayerVisibility or not ctx.PlayerVisibility.SetEffects(enabled) then return false end
        end
        options[name]=enabled
        if name=="No damage particles" then if enabled then attachParticles() else detachParticles() end end
        if name=="Delete dead mobs" or name=="No damage text" then
            if options["Delete dead mobs"] or options["No damage text"] then hookGraphics() else unhookGraphics() end
        end
        if name=="No vel obtained in chat" then if enabled then hookUI() else unhookUI() end end
        if ctx.Changed then ctx.Changed() end
        return true
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        rootAdded:Disconnect(); detachParticles(); unhookGraphics(); unhookUI()
        if ctx.PlayerVisibility then ctx.PlayerVisibility.Destroy() end
        if renderOwned then pcall(ctx.SetRendering,true); renderOwned=false end
        if fpsOwned then pcall(ctx.SetFPS,oldCap); fpsOwned=false end
    end
    if not ctx.Paused and not state.StopEverything then
        for _,name in ipairs(api.Names) do
            if options[name] then options[name]=false; api.Set(name,true) end
        end
    end
    return api
end

-- END BUNDLED PERFORMANCE BOOST
    end)()
    state.PerformanceBoost=createBoost({State=state,Workspace=workspace,Graphics=require(services.Graphics),UI=GameUI,
        Options=type(restore.PerformanceBoosters)=="table" and restore.PerformanceBoosters or {},PlayerVisibility=playerVisibility,
        SetRendering=function(enabled) RunService:Set3dRenderingEnabled(enabled) end,
        GetFPS=typeof(getfpscap)=="function" and getfpscap or function()
            local cap=UserSettings():GetService("UserGameSettings").FramerateCap
            return type(cap)=="number" and cap or cap.Value
        end,
        SetFPS=typeof(setfpscap)=="function" and setfpscap or nil,
        Changed=function() renderBoost(); requestSave() end})
    function state.SetPerformanceBoost(name,enabled) return state.PerformanceBoost.Set(name,enabled) end
    renderBoost()
end

local movementRoot, movementHumanoid, previousAutoRotate, previousPlatformStand
local movementAttachment, positionAlign, orientationAlign
local collisionParts = {}
local characterPartConnection
local nextMovementUpdate = 0
local nextMovementStatusUpdate = 0
local lastSurfaceY, lastTeleportPosition, teleportTarget
local lastTeleportTime = 0
local correctionStrikes, correctionWindow = 0, 0
local correctionTarget
local targetMissingSince, nextAcquisition = nil, 0
local holdPaused = false
local offsetInitialized = false
local function movementStatus(message)
    state.MovementStatus = message
    if not state.AutoFarm and string.sub(message, 1, 7) == "Stopped" then state.LastFarmStopReason = message end
end
function state.SetTeleportOffset(value)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return end
    local newValue = (state.OffsetMode=="Above" and 1 or -1)*math.max(1,math.floor(math.abs(value)*10+0.5)/10)
    if offsetInitialized and newValue == state.TeleportOffset then return end
    state.TeleportOffset = newValue
    offsetInitialized = true
    -- Recalibration is an intentional destination change, not a server correction.
    teleportTarget, lastTeleportPosition = nil, nil
    lastTeleportTime, nextMovementUpdate = 0, 0
    state.OffsetGraceUntil = os.clock() + 0.4
    correctionStrikes, correctionTarget = 0, nil
end
local activeOffsetMob, offsetSample
state.OffsetAvoidTypes={}
state.AutoOffsetSolver=(function()
-- BEGIN BUNDLED AUTO OFFSET
-- Source autofarm geometry: height-corrected center and an outer attack radius.
-- A position must satisfy both attack reach and body clearance; never clamp an
-- unsafe position closer just to keep hitting.
return function(input)
    local enemy,playerRoot=input.Enemy,input.Player
    local size=enemy.Size
    local reach=math.min(120,input.Reach or (math.max(size.X,size.Z)*.5+20))
    local radius=math.min(math.max(size.X,size.Z)*.5+19,reach-(input.Margin or 2))
    if radius<=0 then return nil,"No usable attack reach" end
    if input.Mode=="Above" and input.AdaptiveAbove then
        local minimum=(input.PlayerBelow or 3)+1.5
        local center=input.Center or enemy.Position+Vector3.new(0,(playerRoot.Size.Y-size.Y)*.5,0)
        local offset=math.max(minimum,center.Y-enemy.Position.Y+radius)
        local distance=offset-(center.Y-enemy.Position.Y)
        if distance>reach-.2 then return nil,"Above position is outside the learned hit range" end
        local destination=enemy.Position+Vector3.new(0,offset,0)
        if destination.Y<=(input.DestroyHeight or -500)+40 then return nil,"Offset crosses the map kill plane" end
        return {Destination=destination,Offset=offset,Radius=distance,Reach=reach,
            Minimum=minimum,Center=center,Mode="Above"}
    end
    local center=input.Center or enemy.Position+Vector3.new(0,(playerRoot.Size.Y-size.Y)*.5,0)
    local above=input.Mode=="Above"
    local direction=above and 1 or -1
    local destination=center+Vector3.new(0,direction*radius,0)
    local offset=destination.Y-enemy.Position.Y
    local body=above and (input.BodyAbove or size.Y*.5) or (input.BodyBelow or size.Y*.5)
    local playerExtent=above and (input.PlayerBelow or 3) or (input.PlayerAbove or 3)
    local minimum=body+playerExtent+1.5
    if offset*direction<minimum then return nil,"No body clearance inside attack reach" end
    if destination.Y<=(input.DestroyHeight or -500)+40 then return nil,"Offset crosses the map kill plane" end
    return {Destination=destination,Offset=offset,Radius=radius,Reach=reach,
        Minimum=minimum,Center=center,Mode=above and "Above" or "Below"}
end

-- END BUNDLED AUTO OFFSET
end)()
function state.GetOffsetKey(mob,data)
    local mode=state.OffsetMode or "Below"
    if data.OffsetKeyMode~=mode or data.OffsetKeySize~=data.Root.Size then
        data.OffsetKey=tostring(game.PlaceId)..":"..mob.Name..":"..tostring(data.Root.Size)..":offset-v6:"..mode
        data.OffsetKeyMode,data.OffsetKeySize=mode,data.Root.Size
    end
    return data.OffsetKey
end
do
    local make=(function()
-- BEGIN BUNDLED GROUND FOLLOW
-- Cache each enemy's standing position; do not chase vertical attack animations.
return function(ctx)
    local records=setmetatable({}, {__mode="k"})
    local api={}
    function api.Resolve(mob,data,now)
        local root=data.Root
        local record=records[mob]
        if not record then record={NextProbe=0};records[mob]=record end
        if now>=record.NextProbe then
            record.NextProbe=now+.2
            local floor=ctx.Floor(mob,data)
            if type(floor)=="number" then record.Floor=floor end
        end
        local hint=ctx.GroundHint and ctx.GroundHint(mob)
        local humanoid=mob:FindFirstChildOfClass("Humanoid")
        local standing=math.max(data.BodyBelow or root.Size.Y*.5,
            root.Size.Y*.5+(humanoid and humanoid.HipHeight or 0))
        local floor=record.Floor
        local position=root.Position
        local elevated=floor and position.Y-floor>standing+7
        local rising=root.AssemblyLinearVelocity.Y>10
        local airborne=hint~=nil or elevated or rising
        if not airborne then
            record.Position=position
            record.Standing=floor and position.Y-floor or record.Standing
        elseif not record.Position then
            record.Position=hint or (floor and Vector3.new(position.X,floor+(record.Standing or standing),position.Z)) or nil
        end
        record.Airborne=airborne==true
        return record.Position or (not airborne and position or nil),record.Airborne
    end
    return api
end

-- END BUNDLED GROUND FOLLOW
    end)()
    local enemy=services:FindFirstChild("EnemySkills")
    state.NativeEnemySkills=enemy and require(enemy)
    state.GroundFollow=make({
        Floor=function(mob,data)
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
            local excluded={mob}
            for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects"})do
                local folder=workspace:FindFirstChild(name);if folder then excluded[#excluded+1]=folder end
            end
            if player.Character then excluded[#excluded+1]=player.Character end
            params.FilterDescendantsInstances=excluded
            local hit=workspace:Raycast(data.Root.Position+Vector3.new(0,32,0),Vector3.new(0,-2048,0),params)
            if hit and hit.Normal.Y>.6 then return hit.Position.Y end
        end,
        GroundHint=function(mob)
            local native=state.NativeEnemySkills
            local rig=native and native.RiggedEnemies and native.RiggedEnemies[mob]
            local smash=rig and rig.ActiveSkills.LavaSmash
            if smash and not smash.Destroyed then
                return smash.LastCFrame and smash.LastCFrame.Position or smash.SurfacePosition
            end
        end})
end
function state.ResolveAutoOffset(mob)
    local data=getMobData(mob)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not data or not root then return nil end
    local now,mobRoot=os.clock(),data.Root
    local key=state.GetOffsetKey(mob,data)
    if not data.BodyBelow or not data.BodyAbove or data.OffsetRootSize ~= mobRoot.Size then
        local bottom,top = -mobRoot.Size.Y/2,mobRoot.Size.Y/2
        local reach = math.max(12, mobRoot.Size.Magnitude * 2)
        -- Whole-model bounds can contain effects at the world origin. Only use
        -- visible body parts near the root, once per mob/size.
        for _, part in ipairs(mob:QueryDescendants("BasePart")) do
            local name = string.lower(part.Name)
            if part.Transparency < 0.95 and (part.Position - mobRoot.Position).Magnitude <= reach
                and not string.find(name, "hitbox", 1, true) and not string.find(name, "effect", 1, true)
                and not string.find(name, "attack", 1, true) and not string.find(name, "trail", 1, true)
                and not string.find(name,"weapon",1,true) and not string.find(name,"sword",1,true)
                and not string.find(name,"blade",1,true) and name~="handle"
                and not part:FindFirstAncestorWhichIsA("Tool") and not part:FindFirstAncestorWhichIsA("Accessory") then
                local cf, size = part.CFrame, part.Size
                local halfHeight = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
                bottom = math.min(bottom, part.Position.Y - mobRoot.Position.Y - halfHeight)
                top=math.max(top,part.Position.Y-mobRoot.Position.Y+halfHeight)
            end
        end
        data.BodyBelow,data.BodyAbove = -bottom,top
        data.OffsetRootSize = mobRoot.Size
    end
    local head=character:FindFirstChild("Head")
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    local playerAbove=head and math.max(root.Size.Y/2,head.Position.Y+head.Size.Y/2-root.Position.Y) or 3
    local playerBelow=math.max(3,humanoid and humanoid.HipHeight+root.Size.Y/2 or 3)
    local grounded,airborne=state.GroundFollow.Resolve(mob,data,now)
    state.FarmTargetAirborne=airborne
    if airborne then
        local destination=data.LastGroundedFarmDestination
            or (state.FarmAbove and root.Position)
            or (grounded and Vector3.new(grounded.X,grounded.Y-data.BodyBelow-20,grounded.Z)) or root.Position
        state.AutoOffsetTarget,state.AutoOffsetDestination=mob,destination
        state.OffsetStatus="Waiting for enemy to land"
        return destination.Y-mobRoot.Position.Y
    end
    local center=root.Position+state.AutoRanges.Delta(data,root)
    local reach=state.FarmAbove and state.AutoRanges.Range(state.Enabled and "Kill" or "Skill",data,state.SelectedSkill) or state.AutoRanges.BodyRange(data)
    local plan,reason=state.AutoOffsetSolver({Enemy=mobRoot,Player=root,Center=center,
        Mode=state.OffsetMode or "Below",Reach=reach,Margin=1.5+math.min(1,(state.PingMs or 150)/500),
        AdaptiveAbove=state.FarmAbove,BodyBelow=data.BodyBelow,BodyAbove=data.BodyAbove,PlayerAbove=playerAbove,PlayerBelow=playerBelow,
        DestroyHeight=workspace.FallenPartsDestroyHeight})
    local verifiedReach=state.AutoRanges.Range(state.Enabled and "Kill" or "Skill",data,state.SelectedSkill)
    if plan and plan.Radius>verifiedReach-(state.FarmAbove and .2 or 1) then plan=nil; reason="Outer position exceeds the learned attack reach" end
    if not plan then
        data.SkipUntil=now+8
        state.OffsetStatus=reason
        state.LastOffsetRejected={Target=mob.Name,Reason=reason,At=now}
        state.AutoOffsetTarget,state.AutoOffsetDestination=nil,nil
        if state.FollowTarget==mob then state.FollowTarget=nil end
        return nil
    end
    local playerHealth=character:FindFirstChild("Entity")
    playerHealth=playerHealth and playerHealth:FindFirstChild("Health")
    if activeOffsetMob~=mob or not offsetSample or offsetSample.Key~=key then
        activeOffsetMob=mob
        offsetSample={Offset=plan.Offset,Key=key,Requests=data.OffsetRequests or 0,At=now,
            SafeSince=now,PlayerHealth=playerHealth and playerHealth.Value,OwnDamage=state.ReadOwnDamage(data.Health),Misses=0,Confirmed=false}
        state.OffsetStatus="Source outer reach · checking clearance"
    end
    if math.abs(plan.Offset-offsetSample.Offset)>.75 then
        offsetSample.SafeSince=now; offsetSample.Confirmed=false; offsetSample.Offset=plan.Offset
    end
    if now-offsetSample.At>=1.2 then
        local requests=data.OffsetRequests or 0
        local contribution=state.ReadOwnDamage(data.Health)
        local damageConfirmed=contribution~=nil and contribution>(offsetSample.OwnDamage or 0)
        if requests>offsetSample.Requests and damageConfirmed then
            offsetSample.Misses=0
            local noDamage=now-(state.LastIncomingDamageAt or -math.huge)>=4
                and (not playerHealth or not offsetSample.PlayerHealth or playerHealth.Value>=offsetSample.PlayerHealth)
            if noDamage and now-offsetSample.SafeSince>=4 then
                offsetSample.Confirmed=true
                state.OffsetStatus="Holding damage-free source position"
                local saved=(plan.Mode=="Above" and 1 or -1)*math.floor(math.abs(plan.Offset)*4+.5)/4
                if state.OffsetProfiles[key]~=saved and now-(data.LastProfileSaveAt or -math.huge)>=10 then
                    local count=0; for _ in pairs(state.OffsetProfiles) do count+=1 end
                    if count<32 or state.OffsetProfiles[key] then state.OffsetProfiles[key]=saved; data.LastProfileSaveAt=now; requestSave() end
                end
            else state.OffsetStatus="Checking damage and player health" end
        elseif requests-offsetSample.Requests>=3 and not state.SkillCastRunning and not state.Recovering
            and now>=state.LagPauseUntil and (not state.PingMs or state.PingMs<=500) then
            offsetSample.Misses+=1
            state.OffsetStatus="No damage · holding outer clearance"
            if offsetSample.Misses>=3 then
                data.SkipUntil=now+8
                state.FollowTarget=nil
                state.AutoOffsetTarget,state.AutoOffsetDestination=nil,nil
                return nil
            end
        end
        offsetSample.Requests,offsetSample.At=requests,now
        offsetSample.OwnDamage=contribution
        offsetSample.PlayerHealth=playerHealth and playerHealth.Value
    end
    state.OffsetDebug={Target=mob.Name,Mode=plan.Mode,Distance=math.abs(plan.Offset),Minimum=plan.Minimum,
        Radius=plan.Radius,Reach=plan.Reach,CenterCorrection=center.Y-mobRoot.Position.Y,
        BodyBelow=data.BodyBelow,BodyAbove=data.BodyAbove,MissWindows=offsetSample.Misses,Confirmed=offsetSample.Confirmed}
    state.AutoOffsetTarget,state.AutoOffsetDestination=mob,plan.Destination
    data.LastGroundedFarmDestination=plan.Destination
    state.SetTeleportOffset(plan.Offset)
    return plan.Offset
end

local function attackDeltaFor(data,root)
    if state.AutoRanges then return state.AutoRanges.Delta(data,root) end
    return data.Root.Position+Vector3.new(0,(root.Size.Y-data.Root.Size.Y)*.5,0)-root.Position
end
local function attackRadiusFor(mob)
    local data=getMobData(mob)
    if not data then return 20 end
    if state.AutoRanges then return state.AutoRanges.Range("Kill",data) end
    local size=data.Root.Size
    return math.min(120,math.max(size.X,size.Z)*.5+20)
end
local function pivotRoot(root, position)
    local character = root.Parent
    local facing=root.CFrame.LookVector*Vector3.new(1,0,1)
    if facing.Magnitude<.001 then facing=Vector3.new(0,0,-1) end
    local targetRoot=CFrame.lookAt(position,position+facing.Unit,Vector3.yAxis)
    character:PivotTo(targetRoot * root.CFrame:ToObjectSpace(character:GetPivot()))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end
stopMovement = function(message, keepPosition)
    local floatingRoot=state.ArenaFloat and state.ArenaFloat.Root
    if state.ArenaFloat then state.ArenaFloat.Release() end
    state.TravelHold=false
    state.TravelHoldPosition=nil
    if state.Recovering and not movementRoot then return end
    if characterPartConnection then characterPartConnection:Disconnect(); characterPartConnection = nil end
    local oldRoot, oldHumanoid = movementRoot, movementHumanoid
    if not oldRoot and floatingRoot then
        oldRoot=floatingRoot
        oldHumanoid=floatingRoot.Parent and floatingRoot.Parent:FindFirstChildOfClass("Humanoid")
    end
    local oldRotate, oldPlatform = previousAutoRotate, previousPlatformStand
    local oldPosition, oldOrientation, oldAttachment = positionAlign, orientationAlign, movementAttachment
    local oldCollisions = collisionParts
    collisionParts = {}
    local function cleanup()
        if oldPosition then oldPosition:Destroy() end
        if oldOrientation then oldOrientation:Destroy() end
        if oldAttachment then oldAttachment:Destroy() end
        for part, value in pairs(oldCollisions) do if part.Parent then part.CanCollide = value end end
        if oldHumanoid and oldHumanoid.Parent then
            oldHumanoid.AutoRotate = oldRotate
            oldHumanoid.PlatformStand = oldPlatform
            if oldHumanoid.Health > 0 and not oldPlatform then oldHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
        if oldRoot and oldRoot.Parent then oldRoot.AssemblyLinearVelocity = Vector3.zero end
        state.Recovering = false
    end
    local surface
    if not keepPosition and oldRoot and oldRoot.Parent and (oldPosition or floatingRoot) and oldHumanoid and oldHumanoid.Health > 0 then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { oldRoot.Parent, workspace:FindFirstChild("Mobs") or oldRoot.Parent }
        params.RespectCanCollide = true
        local floor = workspace:Raycast(oldRoot.Position + Vector3.new(0, 35, 0), Vector3.new(0, -70, 0), params)
        local exitY = floor and floor.Position.Y + oldHumanoid.HipHeight + oldRoot.Size.Y / 2 + 1.5 or lastSurfaceY
        if exitY and math.abs(oldRoot.Position.Y - exitY) > 1 then surface = Vector3.new(oldRoot.Position.X, exitY, oldRoot.Position.Z) end
    end
    if surface then
        state.Recovering = true
        oldPosition.Enabled = true
        oldPosition.Position = surface
        pivotRoot(oldRoot, surface)
        local exitCollisionConnection = RunService.Stepped:Connect(function()
            for part in pairs(oldCollisions) do if part.Parent then part.CanCollide = false end end
        end)
        env.SB2FarmRecoveryUntil = os.clock() + 0.3
        task.delay(0.3, function()
            exitCollisionConnection:Disconnect()
            cleanup()
            if state.Running then movementStatus(state.LastFarmStopReason or message or "Stopped · character controls restored") end
        end)
    else
        cleanup()
    end
    movementRoot, movementHumanoid, previousAutoRotate, previousPlatformStand = nil, nil, nil, nil
    movementAttachment, positionAlign, orientationAlign = nil, nil, nil
    lastTeleportPosition, teleportTarget = nil, nil
    correctionStrikes, correctionTarget, holdPaused = 0, nil, false
    state.Exploring, state.LastExploreDestination = false, nil
    state.Moving = false
    if message then movementStatus(state.Recovering and "Returning above ground…" or message) end
end
do
    local make=(function()
-- BEGIN BUNDLED FARM NOCLIP
-- Auto Farm owns collision changes across idle, travel and farming handoffs.
return function(ctx)
    local api={}
    local character,added,pulse
    local originals={}
    local disposed=false
    local function restore()
        if added then added:Disconnect();added=nil end
        for part,value in pairs(originals)do if part.Parent then part.CanCollide=value end end
        originals={};character=nil
    end
    local function remember(part)
        if part:IsA("BasePart")then
            if originals[part]==nil then originals[part]=part.CanCollide end
            part.CanCollide=false
        end
    end
    function api.Original(part)return originals[part]end
    function api.Update()
        if disposed then return end
        if not ctx.Enabled()then
            restore()
            if pulse then pulse:Disconnect();pulse=nil end
            return
        end
        local current=ctx.Player.Character
        if current~=character then
            restore();character=current
            if current then
                for _,part in ipairs(current:QueryDescendants("BasePart"))do remember(part)end
                added=current.DescendantAdded:Connect(remember)
            end
        end
        for part in pairs(originals)do
            if not part.Parent then originals[part]=nil
            elseif character and not part:IsDescendantOf(character)then
                part.CanCollide=originals[part];originals[part]=nil
            elseif part.CanCollide then part.CanCollide=false end
        end
        if not pulse then pulse=ctx.Pulse:Connect(api.Update)end
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        if pulse then pulse:Disconnect();pulse=nil end
        restore()
    end
    return api
end

-- END BUNDLED FARM NOCLIP
    end)()
    state.FarmNoclip=make({Player=player,Pulse=RunService.Stepped,
        Enabled=function()return state.Running and state.AutoFarm and not state.StopEverything and not state.ModeratorBlocking end})
end
function state.SetAutoFarm(enabled, reason)
    if state.StopEverything and enabled==true then return false end
    if (enabled == true) == state.AutoFarm then return end
    state.LastAutoFarmChange={Enabled=enabled==true,Reason=reason or "API",At=os.clock(),Line=debug.info(2,"l")}
    if state.AutoFarm and enabled ~= true then state.ProtectionUntil = os.clock() + 8 end
    state.AutoFarm = enabled == true
    state.FarmTargetLock=nil
    if state.AutoFarm then state.LastFarmStopReason = nil end
    state.LastMovementError = nil
    farmToggle.Text = state.AutoFarm and "Auto farm  ·  ON" or "Auto farm  ·  OFF"
    farmToggle.BackgroundColor3 = state.AutoFarm and Color3.fromRGB(114, 88, 229) or Color3.fromRGB(45, 48, 63)
    stopMovement(state.AutoFarm and "Searching for the nearest living mob" or "Auto farm is off")
    state.FollowTarget = nil
    activeOffsetMob, offsetSample = nil, nil
    state.AutoOffsetTarget = nil
    nextTargetRefresh = 0
    nextMovementUpdate = 0
    targetMissingSince, nextAcquisition = nil, 0
    if state.AutoFarm and state.SetEnabled then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:Move(Vector3.zero, false) end
    end
    if state.FarmNoclip then state.FarmNoclip.Update()end
    requestSave()
end
function state.SetFarmRange(range)
    if type(range) ~= "number" or range ~= range then range = state.FarmRange end
    state.FarmRange = math.huge
    state.FollowTarget = nil
    nextTargetRefresh = 0
    movementStatus("Detection range updated")
    nextMovementUpdate = 0
    requestSave()
end
bind(farmToggle.Activated, function() state.SetAutoFarm(not state.AutoFarm,"UI toggle") end)
state.SetAutoFarm(false)
refreshMobIndex()
local function validMob(mob, mobs)
    if state.ModeratorBlocking or state.AutoTradeBusy then return nil end
    if not mob or mob.Parent ~= mobs then return nil end
    if state.AccountProgression and (state.ProgressionPhase~="Fighting" or state.ProgressionEquipping
        or mob~=state.ProgressionBossMob)then return nil end
    local data = getMobData(mob)
    if state.MultiSpotAnchor and data and not (state.MultiSpotEncounter and state.MultiSpotEncounter[mob]) and (data.Root.Position-state.MultiSpotAnchor).Magnitude>220 then return nil end
    if data and data.Health.Value > 0 and (not data.HitLives or data.HitLives.Value>0) and os.clock()>=(data.SkipUntil or 0) and not data.Entity:FindFirstChild("Immortal") then return data.Root end
    return nil
end
function state.IsAttackingEnemy()
    if not state.Running or state.StopEverything or state.SafeModePanic or state.TravelBusy or state.MultiSpotOwnsTravel or state.Dodging
        or state.Recovering or state.ProtectionRetreating then return false end
    local stamp=state.LastEnemyAttackAt
    if not stamp or os.clock()-stamp>.8 then return false end
    local kind=state.LastEnemyAttackKind
    if not ((kind=="Normal" and state.Enabled) or (kind=="Skill" and state.SkillAura)) then return false end
    local mob=state.LastEnemyAttackTarget
    if not validMob(mob,indexedMobFolder) then return false end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local entity=character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    if not health or health.Value<=0 then return false end
    local data=getMobData(mob)
    local range=kind=="Normal" and attackRadiusFor(mob) or state.AutoRanges.Range("Skill",data,state.LastEnemyAttackSkill)
    return attackDeltaFor(data,root).Magnitude<=range
end
local function pauseHold(message)
    if movementRoot and movementRoot.Parent and positionAlign and not holdPaused then positionAlign.Position = movementRoot.Position end
    holdPaused = true
    movementStatus(message)
end
local function ensureMovementController(character, root, humanoid, destination)
    if state.ArenaFloat and state.ArenaFloat.Root then state.ArenaFloat.Release() end
    if movementRoot and positionAlign and positionAlign.Parent then return end
    movementRoot, movementHumanoid = root, humanoid
    previousAutoRotate, previousPlatformStand = humanoid.AutoRotate, humanoid.PlatformStand
    humanoid.AutoRotate = false
    humanoid.PlatformStand = false
    humanoid.Sit = false
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    local function trackPart(part)
        if part:IsA("BasePart") then
            if collisionParts[part] == nil then
                local original=state.FarmNoclip and state.FarmNoclip.Original(part)
                if original==nil then original=part.CanCollide end
                collisionParts[part]=original
            end
            part.CanCollide = false
        end
    end
    for _, part in ipairs(character:QueryDescendants("BasePart")) do trackPart(part) end
    characterPartConnection = character.DescendantAdded:Connect(trackPart)
    movementAttachment = create("Attachment", { Name = "SB2FarmAttachment" }, root)
    positionAlign = create("AlignPosition", {
        Name = "SB2FarmPosition", Mode = Enum.PositionAlignmentMode.OneAttachment,
        Attachment0 = movementAttachment, Position = destination, ApplyAtCenterOfMass = true,
        MaxForce = math.max(1, root.AssemblyMass) * workspace.Gravity * 8,
        MaxVelocity = 60, Responsiveness = 40, RigidityEnabled = false,
    }, root)
    orientationAlign = create("AlignOrientation", {
        Name = "SB2FarmOrientation", Mode = Enum.OrientationAlignmentMode.OneAttachment,
        Attachment0 = movementAttachment, CFrame = state.UprightController.Rotation(root.CFrame),
        MaxTorque = math.max(1, root.AssemblyMass) * 10000, MaxAngularVelocity = 20,
        Responsiveness = 40, RigidityEnabled = true,
    }, root)
    state.Moving = true
end

state.UprightController=(function()
-- BEGIN BUNDLED UPRIGHT
return function(ctx)
    local api={}
    local nextUpdate=0
    local held,flags
    function api.Rotation(frame)
        local direction=frame.LookVector*Vector3.new(1,0,1)
        if direction.Magnitude<.001 then direction=Vector3.new(0,0,-1) end
        return CFrame.lookAt(Vector3.zero,direction.Unit,Vector3.yAxis)
    end
    function api.Release()
        if held and held.Parent and flags then
            for kind,enabled in pairs(flags) do held:SetStateEnabled(kind,enabled) end
        end
        held,flags=nil,nil
    end
    function api.Update(force)
        local now=os.clock()
        if not force and now<nextUpdate then return end
        nextUpdate=now+.1
        local character=ctx.Player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not ctx.Controlled() or not root or not humanoid or humanoid.Health<=0 then api.Release(); return end
        if held~=humanoid then
            api.Release()
            held,flags=humanoid,{}
            for _,kind in ipairs({Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll}) do
                flags[kind]=humanoid:GetStateEnabled(kind)
                humanoid:SetStateEnabled(kind,false)
            end
        end
        if humanoid.PlatformStand then humanoid.PlatformStand=false end
        if humanoid.Sit then humanoid.Sit=false end
        local kind=humanoid:GetState()
        if kind==Enum.HumanoidStateType.Physics or kind==Enum.HumanoidStateType.FallingDown
            or kind==Enum.HumanoidStateType.Ragdoll or kind==Enum.HumanoidStateType.Seated then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        local rotation=api.Rotation(root.CFrame)
        local align=ctx.Orientation()
        if align and align.Parent then align.CFrame=rotation; align.Enabled=true end
        if root.CFrame.UpVector.Y<.999 then
            root.CFrame=CFrame.new(root.Position)*rotation
            root.AssemblyAngularVelocity=Vector3.zero
            ctx.State.UprightCorrections=(ctx.State.UprightCorrections or 0)+1
        elseif root.AssemblyAngularVelocity.Magnitude>.1 then root.AssemblyAngularVelocity=Vector3.zero end
    end
    api.Destroy=api.Release
    return api
end
-- END BUNDLED UPRIGHT
end)()({State=state,Player=player,
    Controlled=function() return state.Running and ((state.AutoFarm and state.Enabled) or state.TravelBusy or state.TravelHold or state.Dodging) end,
    Orientation=function() return orientationAlign end,
})

do
    local create=(function()
-- BEGIN BUNDLED BOSS DODGE
-- React only to native enemy warning names/tags confirmed in EnemySkills.
return function(ctx)
    local api={ThreatCount=0}
    local roots,connections={},{}
    local disposed=false
    local lastPoint,holdUntil=nil,0
    local nextSearch=0
    local named={RedGroundWarning="Circle",LockedAimWarning="Beam"}
    local tags={"AegorSlam Rock","AegorSlam Slam","AegorSpike Spike","RiftDetonation Rift"}
    local projectileActive={}
    local function track(root,kind)
        if disposed or roots[root] then return end
        local count=0; for _ in pairs(roots) do count+=1 end
        if count>=48 then return end
        roots[root]={Kind=kind,Started=os.clock(),Name=root.Name}
        api.HasHazards=true
    end
    local function projectileMatch(part,spec)
        local template=spec.Template
        return template and part.ClassName==template.ClassName and part.Name==template.Name
            and part.Material==template.Material and part.Color==template.Color
            and (part.Size-template.Size).Magnitude<.15 and part:FindFirstChild(spec.Marker)~=nil
    end
    local function projectileAdded(part)
        for _,spec in ipairs(ctx.Projectiles or {}) do
            if projectileMatch(part,spec) then
                local function register()
                    if not disposed and part.Parent and os.clock()<(projectileActive[spec.Name] or 0) then
                        track(part,"Projectile")
                        local r=roots[part]
                        if r then r.Name=spec.Name; r.Radius=spec.Radius end
                    end
                end
                register(); if not roots[part] then task.defer(register) end
            end
        end
    end
    if ctx.Replicate then connections[#connections+1]=ctx.Replicate:Connect(function(_,phase,name)
        if phase=="Initial" or phase=="RunPhase" then
            for _,spec in ipairs(ctx.Projectiles or {}) do if name==spec.Name then projectileActive[name]=os.clock()+10 end end
        end
    end) end
    connections[#connections+1]=ctx.Workspace.DescendantAdded:Connect(function(instance)
        if named[instance.Name] and (instance:IsA("Model") or instance:IsA("BasePart")) then track(instance,named[instance.Name]) end
        if instance:IsA("BasePart") and instance.Name=="Part" then projectileAdded(instance) end
    end)
    for _,instance in ipairs(ctx.Workspace:QueryDescendants("#RedGroundWarning,#LockedAimWarning")) do track(instance,named[instance.Name]) end
    for _,tag in ipairs(tags) do
        local function added(part) if part:IsA("BasePart") and part.Name=="Circle" then track(part,"Circle") end end
        for _,part in ipairs(ctx.Collection:GetTagged(tag)) do added(part) end
        connections[#connections+1]=ctx.Collection:GetInstanceAddedSignal(tag):Connect(added)
    end
    -- Preserve protection when the script is reloaded during an existing cast.
    local mobs=ctx.Workspace:FindFirstChild("Mobs")
    local prime=false
    for _,spec in ipairs(ctx.Projectiles or {}) do
        local boss=mobs and spec.BossName and mobs:FindFirstChild(spec.BossName)
        local entity=boss and boss:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if health and health.Value>0 then projectileActive[spec.Name]=os.clock()+10; prime=true end
    end
    if prime then for _,part in ipairs(ctx.Workspace:GetChildren()) do if part:IsA("BasePart") and part.Name=="Part" then projectileAdded(part) end end end
    local boxes={}
    local function refresh()
        table.clear(boxes)
        local now=os.clock()
        for root,record in pairs(roots) do
            if root.Parent then
                local ok,cf,size=pcall(function() if root:IsA("Model") then return root:GetBoundingBox() end return root.CFrame,root.Size end)
                if ok and math.max(size.X,size.Z)>.2 then
                    if record.Kind=="Projectile" and record.CFrame and record.SampleAt and now>record.SampleAt then
                        local velocity=(cf.Position-record.CFrame.Position)/(now-record.SampleAt)
                        record.Velocity=velocity.Magnitude<=400 and velocity or Vector3.zero
                    end
                    record.CFrame,record.Size,record.SampleAt=cf,size,now
                end
                record.RemovedAt=nil
            else record.RemovedAt=record.RemovedAt or now end
            if now-record.Started>20 or (record.RemovedAt and now-record.RemovedAt>.8) then roots[root]=nil
            elseif record.CFrame then boxes[#boxes+1]=record end
        end
        api.ThreatCount=#boxes; ctx.State.BossThreatCount=#boxes
        api.HasHazards=next(roots)~=nil
    end
    local function threatened(point)
        local margin=5+math.min(3,(ctx.State.PingMs or 0)/100)
        for _,record in ipairs(boxes) do
            local cf,size=record.CFrame,record.Size
            if record.Kind=="Projectile" then
                local lead=math.clamp(.12+(ctx.State.PingMs or 0)/1000,.12,.4)
                local segment=(record.Velocity or Vector3.zero)*lead
                local alpha=segment:Dot(segment)>.01 and math.clamp((point-cf.Position):Dot(segment)/segment:Dot(segment),0,1) or 0
                local d=point-(cf.Position+segment*alpha)
                local radius=(record.Radius or math.max(size.X,size.Y,size.Z)*.5)+margin
                if d:Dot(d)<radius*radius then return true,record.Name end
            elseif record.Kind=="Beam" then
                local p=cf:PointToObjectSpace(point)
                if math.abs(p.X)<size.X*.5+margin and math.abs(p.Z)<size.Z*.5+margin then return true,record.Name end
            else
                local half=Vector3.new(math.abs(cf.RightVector.X)*size.X+math.abs(cf.UpVector.X)*size.Y+math.abs(cf.LookVector.X)*size.Z,
                    0,math.abs(cf.RightVector.Z)*size.X+math.abs(cf.UpVector.Z)*size.Y+math.abs(cf.LookVector.Z)*size.Z)*.5
                local radius=math.max(half.X,half.Z)+margin
                local delta=(point-cf.Position)*Vector3.new(1,0,1)
                if delta:Dot(delta)<radius*radius then return true,record.Name end
            end
        end
        return false
    end
    function api.RefreshThreats() if not disposed then refresh() end end
    function api.IsThreatened(point) return threatened(point) end
    function api.IsHazardPart(part)
        local node=part
        while node and node~=ctx.Workspace do if roots[node] then return true end; node=node.Parent end
        return false
    end
    function api.Plan(point,desired,region,extraThreat)
        if disposed or not ctx.State.AutoDodge then return nil end
        refresh()
        local now=os.clock()
        local unsafe,name=threatened(point)
        local wanted,wantedName=threatened(desired or point)
        api.Blocked=unsafe or wanted
        if not unsafe and not wanted and now>=holdUntil then lastPoint=nil; return nil end
        local function valid(p)
            if threatened(p) or (extraThreat and extraThreat(p)) then return false end
            if region then local q=region.CFrame:PointToObjectSpace(p); if math.abs(q.X)>region.Size.X*.5-8 or math.abs(q.Z)>region.Size.Z*.5-8 then return false end end
            return true
        end
        if lastPoint and valid(lastPoint) then return lastPoint,api.LastReason end
        if now<nextSearch then return nil end
        lastPoint=nil
        if valid(point) then lastPoint=point
        else
            for radius=10,220,10 do
                for i=1,16 do
                    local angle=i*math.pi/8
                    local p=point+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                    if valid(p) then lastPoint=p; break end
                end
                if lastPoint then break end
            end
        end
        if lastPoint then
            holdUntil=now+.45; api.LastReason=name or wantedName or "Boss warning"
            ctx.State.LastBossWarning=api.LastReason
            return lastPoint,api.LastReason
        end
        nextSearch=now+.15
        return nil
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        api.HasHazards=false
        for _,connection in ipairs(connections) do connection:Disconnect() end
        table.clear(roots); table.clear(boxes); lastPoint=nil
    end
    return api
end

-- END BUNDLED BOSS DODGE
    end)()
    local enemy=services:FindFirstChild("EnemySkills")
    local enemySkills=enemy and enemy:FindFirstChild("Skills")
    local waveSkills=enemySkills and enemySkills:FindFirstChild("Wave Defense")
    local bosses=waveSkills and waveSkills:FindFirstChild("Bosses")
    local projectiles={}
    for _,entry in ipairs({{"Nythrane, the Hollow Flame","PurpleFireyOrb","Burning",2.5,0},{"Vaelith, the Riftborn","RiftDetonation","Zap",1,8}}) do
        local boss=bosses and bosses:FindFirstChild(entry[1]); local skill=boss and boss:FindFirstChild(entry[2])
        local template=skill and skill:FindFirstChild("Part")
        if template and template:IsA("BasePart") then projectiles[#projectiles+1]={BossName=entry[1],Name=entry[2],Template=template,Marker=entry[3],Radius=math.max(entry[5],math.max(template.Size.X,template.Size.Y,template.Size.Z)*.5*entry[4])} end
    end
    local replicate=ReplicatedStorage:FindFirstChild("ReplicateSkill")
    state.BossDodge=create({State=state,Workspace=workspace,Collection=game:GetService("CollectionService"),
        Projectiles=projectiles,Replicate=replicate and replicate.OnClientEvent})
end
do
    local make=(function()
-- BEGIN BUNDLED ATHEON DODGE
-- Native Atheon cast data and LavaGyzer Point geometry; no damage/cooldown edits.
return function(ctx)
    local state=ctx.State
    local api={Moves=0,Seen={},Completed={},ThreatCount=0,MaxStep=112,MaxBossDistance=128,SmashRadius=90}
    local casts={}
    local points={}
    local disposed=false
    local now=ctx.Now or os.clock
    local flat=Vector3.new(1,0,1)
    local known={FireDash=true,LavaSmash=true,LavaGyzer=true}
    local lastPoint,nextPlan=nil,0
    local function update(point)
        local time=now()
        local closest,distance
        for _,boss in ipairs(ctx.Bosses()) do
            local position=ctx.Position(boss)
            local gap=position and (position-point).Magnitude
            if gap and (not distance or gap<distance) then closest,distance=position,gap end
            local rig=(ctx.Native.RiggedEnemies or {})[boss]
            for name,skill in pairs(rig and rig.ActiveSkills or {}) do
                if known[name] and not skill.Destroyed then
                    local record=casts[skill]
                    if not record then
                        record={Name=name,Skill=skill,Boss=boss,Started=time}
                        if name=="LavaSmash" then
                            record.MinimumUntil=time+math.clamp(tonumber(skill.Lifetime) or 3,1,8)+1.2+(state.PingMs or 0)/1000
                        end
                        casts[skill]=record;api.Seen[name]=(api.Seen[name] or 0)+1
                    end
                    record.Until=math.max(record.MinimumUntil or 0,time+(name=="FireDash" and 3.2 or name=="LavaGyzer" and 1 or .8))
                end
            end
        end
        local count=0
        for skill,record in pairs(casts) do
            local rig=(ctx.Native.RiggedEnemies or {})[record.Boss]
            local ended=skill.Destroyed==true or (rig and rig.ActiveSkills and rig.ActiveSkills[record.Name]~=skill)
            if record.Name=="FireDash" then
                record.Assets=record.Assets or {}
                for _,part in pairs(skill.CreatedAssets or {}) do
                    if part.Parent and part:IsA("BasePart") then record.Assets[part]=true;record.AssetsKnown=true end
                end
                if ended and not record.AssetQueryDone and ctx.FireAssets then
                    record.AssetQueryDone=true
                    local ok,assets=pcall(ctx.FireAssets,skill)
                    if ok and type(assets)=="table" then
                        record.AssetsKnown=true
                        for _,part in ipairs(assets) do record.Assets[part]=true end
                    end
                end
            end
            local grounded=record.Name~="LavaSmash"
            if record.Name=="LavaSmash" and time-record.Started<14 then
                local root=ctx.Position(record.Boss)
                local ground=skill.LastCFrame and skill.LastCFrame.Position or skill.SurfacePosition
                if root and ground then
                    if ctx.Grounded then grounded=ctx.Grounded(record.Boss)
                    else grounded=math.abs(root.Y-ground.Y)<=6 end
                    if not grounded and root.Y>ground.Y+6 then
                        record.WasAirborne=true;record.CompletedAt=nil;record.Until=math.max(record.Until,time+1.2)
                    elseif grounded and record.WasAirborne and not record.LandedAt then
                        record.LandedAt=time;record.Until=math.max(record.Until,time+1.2+(state.PingMs or 0)/1000)
                    end
                    -- A native Destroy plus the grounded root confirms completion;
                    -- do not spend the conservative fallback timer after that.
                end
            end
            if ended and grounded then
                if not record.CompletedAt then
                    record.CompletedAt=time
                    record.ReturnMargin=math.clamp(.1+(state.PingMs or 0)/1000,.15,.35)
                    api.LastSkillEndAt=time;api.LastSkillEndName=record.Name;api.LastReturnMargin=record.ReturnMargin
                    api.Completed[record.Name]={At=time,Margin=record.ReturnMargin}
                end
                local due=record.CompletedAt+record.ReturnMargin
                if record.Name=="FireDash" then
                    if record.AssetsKnown then
                        local alive=false
                        for part in pairs(record.Assets) do if part.Parent then alive=true else record.Assets[part]=nil end end
                        record.Until=alive and math.min(record.CompletedAt+3.2,math.max(due,time+.2)) or due
                    end
                else record.Until=math.min(record.Until,due) end
            end
            if time>record.Until then casts[skill]=nil else count+=1 end
        end
        local added=0
        for _,part in ipairs(ctx.Collection:GetTagged("LavaGyzer Point")) do
            added+=1;if added>48 then break end
            if part.Parent and part:IsA("BasePart") then
                local record=points[part]
                if not record then
                    record={Started=time}
                    local lifetime=part.GetAttribute and part:GetAttribute("Lifetime")
                    if type(lifetime)=="number" and lifetime>=0 and lifetime<=15 then record.Lifetime=lifetime end
                end
                record.Position=part.Position;record.Radius=math.max(part.Size.X,part.Size.Z)*.5;record.Until=time+1
                record.SeenAt=time;record.RemovedAt=nil
                points[part]=record
            end
        end
        for part,record in pairs(points) do
            if record.SeenAt~=time and record.Lifetime then
                record.RemovedAt=record.RemovedAt or time
                local margin=math.clamp(.1+(state.PingMs or 0)/1000,.15,.35)
                record.Until=math.max(record.Started+record.Lifetime+.15+margin,record.RemovedAt+.15+margin)
            end
            if time>record.Until then points[part]=nil else count+=1 end
        end
        api.ThreatCount=count
        local smashCenter
        for _,record in pairs(casts) do
            if record.Name=="LavaSmash" then smashCenter=record.Skill.SurfacePosition or smashCenter end
        end
        api.Anchor=smashCenter or closest
        api.NearBoss=api.Anchor~=nil and (api.Anchor-point).Magnitude<=api.MaxBossDistance
        return time
    end
    local function danger(point)
        local margin=8+math.min(4,(state.PingMs or 0)/100)
        for _,record in pairs(casts) do
            local skill=record.Skill
            if record.Name=="LavaSmash" and skill.SurfacePosition then
                local delta=(point-skill.SurfacePosition)*flat
                local radius=api.SmashRadius+margin
                if delta:Dot(delta)<radius*radius then return true,"LavaSmash" end
            end
            if record.Name=="FireDash" and skill.SurfacePosition and skill.FocusPosition then
                if record.CompletedAt and record.AssetsKnown and now()>=record.CompletedAt+record.ReturnMargin then
                    for part in pairs(record.Assets) do
                        if part.Parent then
                            local p=part.CFrame:PointToObjectSpace(Vector3.new(point.X,part.Position.Y,point.Z))
                            if math.abs(p.X)<part.Size.X*.5+margin and math.abs(p.Z)<part.Size.Z*.5+margin then return true,"FireDash flames" end
                        end
                    end
                    continue
                end
                local a=skill.SurfacePosition*flat
                local line=(skill.FocusPosition-skill.SurfacePosition)*flat
                local delta=point*flat-a
                local length=line:Dot(line)
                local alpha=length>.01 and math.clamp(delta:Dot(line)/length,0,1) or 0
                local width=(tonumber(skill.Width) or 0)*.5+10+margin
                local offset=delta-line*alpha
                if offset:Dot(offset)<width*width then return true,"FireDash" end
            end
        end
        for _,record in pairs(points) do
            local delta=(point-record.Position)*flat
            local radius=record.Radius+margin
            if delta:Dot(delta)<radius*radius then return true,"LavaGyzer" end
        end
        if api.ThreatCount>0 and ctx.Warnings then
            local unsafe,reason=ctx.Warnings.IsThreatened(point)
            if unsafe then return true,reason end
        end
        return false
    end
    function api.Reset()table.clear(casts);table.clear(points);lastPoint=nil;nextPlan=0;api.ThreatCount=0;api.Active=false;api.NearBoss=false end
    function api.Plan(point,desired,floorY)
        if disposed or not state.AtheonDodge or not state.Running or state.SafeModePanic or state.TravelBusy or state.Recovering then
            api.Reset();return nil
        end
        local time=update(point)
        if api.ThreatCount==0 then
            api.Active=false;lastPoint=nil
            return nil
        end
        local function valid(candidate)
            return candidate and ctx.Valid(candidate) and (candidate-point).Magnitude<=api.MaxStep
                and api.Anchor and (candidate-api.Anchor).Magnitude<=api.MaxBossDistance
        end
        local function shallow()
            local floor=floorY and floorY(point)
            local candidate=type(floor)=="number" and Vector3.new(point.X,floor-20,point.Z) or nil
            return valid(candidate) and candidate or nil
        end
        if ctx.Warnings and api.ThreatCount>0 then ctx.Warnings.RefreshThreats() end
        -- Evade the impact laterally; going only 20 below its center still gets hit.
        local unsafe,reason=danger(point)
        local wanted,wantedReason=danger(desired or point)
        if not unsafe and not wanted then api.Active=false;lastPoint=nil;return nil end
        if lastPoint and valid(lastPoint) and not danger(lastPoint) then api.Active=true;return lastPoint,api.LastReason end
        if time<nextPlan then return nil end
        nextPlan=time+.1
        lastPoint=nil
        if not unsafe and valid(point) then lastPoint=point
        elseif reason=="LavaSmash" and api.Anchor then
            -- Search one ring around the impact, not hundreds of floor raycasts.
            local floor=floorY and floorY(point)
            local y=type(floor)=="number" and floor-20 or point.Y
            local radius=api.SmashRadius+8+math.min(4,(state.PingMs or 0)/100)+6
            if state.FarmAbove then
                local vertical=math.sqrt(math.max(0,api.MaxBossDistance^2-radius^2))-1
                y=math.clamp(point.Y,api.Anchor.Y-vertical,api.Anchor.Y+vertical)
            end
            local best
            for i=1,16 do
                local angle=i*math.pi/8
                local candidate=Vector3.new(api.Anchor.X+math.cos(angle)*radius,y,api.Anchor.Z+math.sin(angle)*radius)
                local distance=(candidate-point).Magnitude
                if valid(candidate) and not danger(candidate) and (not best or distance<best) then lastPoint,best=candidate,distance end
            end
        else
            local floor
            if reason=="LavaSmash" or wantedReason=="LavaSmash" then floor=floorY and floorY(point) end
            for radius=8,api.MaxStep,8 do
                for i=1,16 do
                    local angle=i*math.pi/8
                    local candidate=point+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                    if reason=="LavaSmash" or wantedReason=="LavaSmash" then
                        if type(floor)=="number" then candidate=Vector3.new(candidate.X,floor-20,candidate.Z) end
                    end
                    if valid(candidate) and not danger(candidate) then lastPoint=candidate;break end
                end
                if lastPoint then break end
            end
        end
        if not lastPoint then
            local fallback=shallow()
            if fallback and not danger(fallback) then lastPoint=fallback end
        end
        if lastPoint then
            api.Active=true;api.LastReason=reason or wantedReason or "Atheon warning"
            api.Moves+=1
            return lastPoint,api.LastReason
        end
        api.Active=false;return nil
    end
    function api.Destroy()disposed=true;api.Reset()end
    return api
end

-- END BUNDLED ATHEON DODGE
    end)()
    local enemy=services:FindFirstChild("EnemySkills")
    local native=state.NativeEnemySkills or (enemy and require(enemy))
    state.AtheonDodgeController=make({State=state,Native=native or {RiggedEnemies={}},
        Collection=game:GetService("CollectionService"),Warnings=state.BossDodge,
        FireAssets=function(skill)
            local result={}
            local a,b=skill.SurfacePosition,skill.FocusPosition
            if not a or not b then error("Dash path unavailable") end
            local flat=Vector3.new(1,0,1)
            local line=(b-a)*flat;local length=line:Dot(line)
            local name=skill.IsCorrupted and "CorruptedFlames" or "Flames"
            for _,part in ipairs(workspace:QueryDescendants("#Flames,#CorruptedFlames")) do
                if part.Name==name and part:IsA("BasePart") then
                    local delta=(part.Position-a)*flat
                    local alpha=length>.01 and math.clamp(delta:Dot(line)/length,0,1) or 0
                    if (delta-line*alpha).Magnitude<=(tonumber(skill.Width) or 50)+32 then
                        result[#result+1]=part;if #result>=8 then break end
                    end
                end
            end
            return result
        end,
        Grounded=function(boss)
            local data=getMobData(boss)
            if not data then return false end
            local _,airborne=state.GroundFollow.Resolve(boss,data,os.clock())
            return not airborne
        end,
        Position=function(boss)
            local root=boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
            return root and root.Position
        end,
        Bosses=function()
            local list={}
            local mobs=workspace:FindFirstChild("Mobs")
            if mobs then
                for _,name in ipairs({"Atheon","Corrupted Atheon"}) do
                    local boss=mobs:FindFirstChild(name)
                    local entity=boss and boss:FindFirstChild("Entity")
                    local health=entity and entity:FindFirstChild("Health")
                    if health and health.Value>0 then list[#list+1]=boss end
                end
            end
            return list
        end,
        Valid=function(point)return point.Y>workspace.FallenPartsDestroyHeight+35 and point.Magnitude<1000000 end})
end
local waveDodge = (function()
-- BEGIN BUNDLED WAVE DODGE
return function(ctx)
    local state, player = ctx.State, game.Players.LocalPlayer
    local api = { Active = false, Seen = {}, History = {}, Moves = 0, RockChanges = 0 }
    local names = { "Lava", "Tempest", "Blackout", "Horde", "Rift", "Wisp", "Meme", "Bob" }
    local logPath="SB2Codex/wave-tests_"..player.UserId..".json"
    local audit=getgenv().SB2WaveDodgeAudit
    if not audit then
        audit={Seen={}}
        pcall(function()
            if isfile(logPath) then
                local raw=readfile(logPath)
                if #raw<65536 then
                    local data=game:GetService("HttpService"):JSONDecode(raw)
                    if data.Version==1 and type(data.Seen)=="table" then audit.Seen=data.Seen end
                end
            end
        end)
        getgenv().SB2WaveDodgeAudit=audit
    end
    api.Seen=audit.Seen
    local function saveAudit()
        pcall(function()
            if not isfolder("SB2Codex") then makefolder("SB2Codex") end
            writefile(logPath,game:GetService("HttpService"):JSONEncode({Version=1,Seen=api.Seen}))
        end)
    end
    local rocks, strikes = {}, {}
    local lastArea, currentRock, rockSince, nextScan = nil, nil, 0, 0
    local nextUpdate, lastMove, holdUntil = 0, 0, 0
    local cachedFloor, floorEnvironment, idleXZ
    local blackoutPoint,blackoutEnvironment,blackoutUntil=nil,nil,0
    local bobUntil,bobDepth,nextBobPlan=0,0,0
    local bobPoint,bobEnvironment=nil,nil
    local damageBefore, lastHealth, eventRecord
    local function horizontal(a, b)
        local d = (a - b) * Vector3.new(1, 0, 1)
        return d:Dot(d)
    end
    local function currentEvent()
        local a = tostring(workspace:GetAttribute("WaveDefenseArea") or "")
        local b = tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        local text = string.lower(a .. " " .. b .. " " .. tostring(workspace:GetAttribute("SpecialWave") or ""))
        if string.find(text,"darkness",1,true) then return "Blackout" end
        for _, name in ipairs(names) do if string.find(text, string.lower(name), 1, true) then return name end end
        return nil
    end
    local function isActor(part)
        for _, name in ipairs({ "Mobs", "Characters", "CharacterItems", "HitEffects" }) do
            local f = workspace:FindFirstChild(name)
            if f and part:IsDescendantOf(f) then return true end
        end
        return player.Character and part:IsDescendantOf(player.Character)
    end
    local function extent(part)
        local cf, s = part.CFrame, part.Size
        return Vector3.new(
            math.abs(cf.RightVector.X)*s.X + math.abs(cf.UpVector.X)*s.Y + math.abs(cf.LookVector.X)*s.Z,
            math.abs(cf.RightVector.Y)*s.X + math.abs(cf.UpVector.Y)*s.Y + math.abs(cf.LookVector.Y)*s.Z,
            math.abs(cf.RightVector.Z)*s.X + math.abs(cf.UpVector.Z)*s.Y + math.abs(cf.LookVector.Z)*s.Z) / 2
    end
    local function bounds()
        local stuff = workspace:FindFirstChild("WaveDefenseStuff")
        return stuff and stuff:FindFirstChild("LavaHazardRegion"), stuff and stuff:FindFirstChild("WaveDefenseOrigin")
    end
    function api.FloorY(point)
        local region, origin = bounds()
        local environment = tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        if environment ~= floorEnvironment then cachedFloor, idleXZ, floorEnvironment = nil, nil, environment end
        local offset=math.abs(state.TeleportOffset or 20)
        local reference = origin and origin.Position.Y or point.Y + (state.OffsetMode=="Above" and 32 or math.max(32,offset))
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excluded = {}
        for _, n in ipairs({ "Mobs", "Characters", "CharacterItems", "WaveDefenseStuff" }) do
            local f=workspace:FindFirstChild(n); if f then excluded[#excluded+1]=f end
        end
        if player.Character then excluded[#excluded+1]=player.Character end
        params.FilterDescendantsInstances = excluded
        params.RespectCanCollide = true
        local hit=workspace:Raycast(Vector3.new(point.X,reference+8,point.Z),Vector3.new(0,-math.max(180,offset+160),0),params)
        if hit and hit.Normal.Y > 0.6 then cachedFloor = hit.Position.Y end
        return cachedFloor or reference
    end
    function api.BlackoutPoint(point)
        local environment=tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        if blackoutPoint and environment==blackoutEnvironment and os.clock()<blackoutUntil then return blackoutPoint end
        local _,origin=bounds()
        local center=origin and origin.Position or point
        local reference=origin and origin.Position.Y or api.FloorY(point)
        local minimum=workspace.FallenPartsDestroyHeight+35
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.RespectCanCollide=true
        local excluded={}
        for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","WaveDefenseStuff","ActiveLavaHazard","PillarSpawns"}) do
            local folder=workspace:FindFirstChild(name); if folder then excluded[#excluded+1]=folder end
        end
        if player.Character then excluded[#excluded+1]=player.Character end
        local cursor=Vector3.new(center.X,reference+64,center.Z)
        local bottom
        for _=1,12 do
            if cursor.Y<=minimum then break end
            params.FilterDescendantsInstances=excluded
            local hit=workspace:Raycast(cursor,Vector3.new(0,minimum-cursor.Y,0),params)
            if not hit then break end
            local part=hit.Instance
            if not part or not part:IsA("BasePart") then return nil end
            excluded[#excluded+1]=part
            local under=part.Position.Y-extent(part).Y
            if part.Anchored and part.CanCollide and not isActor(part) then bottom=math.min(bottom or under,under) end
            cursor=Vector3.new(center.X,math.min(hit.Position.Y,under)-.5,center.Z)
        end
        if not bottom or bottom-20<=minimum then return nil end
        blackoutPoint=Vector3.new(center.X,bottom-20,center.Z)
        blackoutEnvironment=environment; blackoutUntil=os.clock()+1
        state.BlackoutMapBottom=bottom; state.BlackoutShelter=blackoutPoint
        return blackoutPoint
    end
    local function bobRefuge(point,now)
        local environment=tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        if environment~=bobEnvironment then bobPoint=nil; nextBobPlan=0; bobEnvironment=environment end
        if bobPoint and now<nextBobPlan then return bobPoint end
        nextBobPlan=now+.25
        local shelter=api.BlackoutPoint(point)
        if not shelter then return nil end
        local y=math.max(workspace.FallenPartsDestroyHeight+36,shelter.Y-bobDepth)
        if y>=shelter.Y+1 then return nil end
        local region,origin=bounds()
        if not region then return Vector3.new(shelter.X,y,shelter.Z) end
        if ctx.BossDodge then ctx.BossDodge.RefreshThreats() end
        local enemies={}
        local mobs=workspace:FindFirstChild("Mobs")
        if mobs then for _,mob in ipairs(mobs:GetChildren()) do
            local entity=mob:FindFirstChild("Entity"); local hp=entity and entity:FindFirstChild("Health")
            local root=mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
            if root and hp and hp.Value>0 and #enemies<64 then enemies[#enemies+1]=root.Position+root.AssemblyLinearVelocity*math.min(.3,(state.PingMs or 100)/1000+.1) end
        end end
        local function clearance(p)
            if ctx.BossDodge and ctx.BossDodge.IsThreatened(p) then return -1 end
            local value=math.huge
            for _,enemy in ipairs(enemies) do value=math.min(value,(p-enemy).Magnitude) end
            if #enemies==0 then value=math.sqrt(horizontal(p,origin and origin.Position or region.Position)) end
            return value
        end
        local best,bestScore=nil,-1
        for _,x in ipairs({-.85,0,.85}) do for _,z in ipairs({-.85,0,.85}) do
            if x~=0 or z~=0 then
                local raw=region.CFrame:PointToWorldSpace(Vector3.new(region.Size.X*.5*x,0,region.Size.Z*.5*z))
                local p=Vector3.new(raw.X,y,raw.Z)
                local score=clearance(p)
                if score>bestScore then best,bestScore=p,score end
            end
        end end
        if bobPoint then
            local current=Vector3.new(bobPoint.X,y,bobPoint.Z)
            local score=clearance(current)
            if score>=80 and score>=bestScore*.85 then best,bestScore=current,score end
        end
        bobPoint=best or Vector3.new(shelter.X,y,shelter.Z)
        state.BobRefuge=bobPoint; state.BobClearance=bestScore; state.BobExtraDepth=bobDepth
        return bobPoint
    end
    local function classify(part, now)
        if state.StopEverything then return end
        if not part:IsA("BasePart") or isActor(part) then return end
        local region, origin = bounds()
        if not origin or horizontal(part.Position,origin.Position)>450*450 then return end
        local name = string.lower(part.Name)
        local area=currentEvent()
        if area == "Tempest" then
            local c, e = part.Color, extent(part)
            local purple = c.B > 0.45 and c.R > 0.3 and c.G < math.max(c.R,c.B)*0.8
            if (part.Material==Enum.Material.Neon and purple and e.X>1 and e.Z>1)
                or (name=="vfx" and part.Size.Y>100 and part.Size.X<35 and part.Size.Z<35) then
                if not strikes[part] then strikes[part]={ First=now, Last=now }; if eventRecord then eventRecord.Warnings+=1 end end
                strikes[part].Last=now
                part.LocalTransparencyModifier=0
            end
        elseif area=="Lava" and part:IsDescendantOf(workspace:FindFirstChild("ActiveLavaHazard") or workspace:FindFirstChild("PillarSpawns") or part) then
            local e=extent(part)
            local floor=origin.Position.Y
            local top=part.Position.Y+e.Y
            local rockName = string.find(name,"rock",1,true) or string.find(name,"pillar",1,true) or string.find(name,"platform",1,true)
            local inside = not region or (math.abs(region.CFrame:PointToObjectSpace(part.Position).X)<region.Size.X/2-8 and math.abs(region.CFrame:PointToObjectSpace(part.Position).Z)<region.Size.Z/2-8)
            if inside and top>floor+2 and top<floor+90 and e.X>=2 and e.Z>=2 and e.X<40 and e.Z<40 and (rockName or part.Parent.Name=="PillarSpawns") then
                if not rocks[part] then rocks[part]={First=now,Last=now,StableAt=now,StablePosition=part.Position,StableSize=part.Size,PeakY=part.Position.Y,LastY=part.Position.Y,LastAlpha=part.Transparency}; if eventRecord then eventRecord.Rocks+=1 end end
                rocks[part].Last=now
                rocks[part].HalfHeight=e.Y
                part.LocalTransparencyModifier=0
            end
        end
    end
    local added=workspace.DescendantAdded:Connect(function(part)
        if state.AutoDodge and part:IsA("BasePart") and currentEvent() then
            classify(part,os.clock())
            task.delay(0.12,function() if part.Parent and state.Running then classify(part,os.clock()) end end)
        end
    end)
    function api.IsHazardPart(part)
        return rocks[part]~=nil or strikes[part]~=nil or (ctx.BossDodge and ctx.BossDodge.IsHazardPart(part))
    end
    local function recordMove(kind, point)
        api.Moves+=1
        if eventRecord then eventRecord.Moves=(eventRecord.Moves or 0)+1 end
        if string.sub(kind,1,3)=="Bob" and api.Seen.Bob and api.Seen.Bob~=eventRecord then
            api.Seen.Bob.ResidualMoves=(api.Seen.Bob.ResidualMoves or 0)+1
        end
        if eventRecord then eventRecord.Moves+=1 end
        api.History[#api.History+1]={Kind=kind,Position=point,At=os.clock(),Wave=workspace:GetAttribute("Wave")}
        if #api.History>40 then table.remove(api.History,1) end
    end
    local function hold(point,kind,now)
        if point.Y<=workspace.FallenPartsDestroyHeight+30 then return false end
        api.Active, state.Dodging = true, true
        ctx.Hold(point)
        if now-lastMove>0.2 and (not api.LastPosition or (api.LastPosition-point).Magnitude>2) then recordMove(kind,point); lastMove=now end
        api.LastPosition=point
        return true
    end
    local function threatened(point)
        for part in pairs(strikes) do
            if part.Parent then
                local e=extent(part)
                local radius=math.max(10,e.X,e.Z)+4
                if horizontal(point,part.Position)<radius*radius then return true end
            end
        end
        return false
    end
    function api.Update()
        if state.StopEverything then return false end
        local now=os.clock()
        if now<nextUpdate then return api.Active end
        local fast=state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.Active and not state.NetworkPressureLimited
        nextUpdate=now+(fast and 1/60 or .04)
        local area=currentEvent()
        api.Event=area
        state.OffsetMode=state.FarmAbove and "Above" or "Below"
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local entity=character and character:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if area=="Bob" then bobUntil=now+5 end
        if area=="Bob" and lastArea~="Bob" then bobDepth=40; bobPoint=nil; nextBobPlan=0 end
        if area~=lastArea then
            if eventRecord then eventRecord.EndHealth=health and health.Value; eventRecord.Completed=true; eventRecord.Ended=now; saveAudit() end
            if api.Active then ctx.Release() end
            api.Active, state.Dodging=false,false
            rocks, strikes, currentRock={}, {}, nil
            api.LastPosition=nil
            if area then
                local old=api.Seen[area]
                if old and old.JobId==game.JobId and old.Wave==workspace:GetAttribute("Wave") and not old.Completed then eventRecord=old
                else eventRecord={Name=area,Wave=workspace:GetAttribute("Wave"),JobId=game.JobId,Count=(old and old.Count or 0)+1,Started=now,StartHealth=health and health.Value,Damage=0,Moves=0,Rocks=0,Warnings=0,Enabled=state.AutoDodge} end
                api.Seen[area]=eventRecord
                eventRecord.DodgeVersion=state.Version
                saveAudit()
            else eventRecord=nil end
            lastArea=area
            nextScan=0
        end
        if health then
            if lastHealth and health.Value<lastHealth then
                if eventRecord then eventRecord.Damage+=lastHealth-health.Value end
                if now<bobUntil and api.Seen.Bob and api.Seen.Bob~=eventRecord then
                    api.Seen.Bob.ResidualDamage=(api.Seen.Bob.ResidualDamage or 0)+lastHealth-health.Value
                end
                if now<bobUntil and health.Value>0 then bobDepth=math.min(80,bobDepth+20); nextBobPlan=0 end
            end
            lastHealth=health.Value
        end
        state.WaveEventsSeen=api.Seen
        local seen=0; for _ in pairs(api.Seen) do seen+=1 end
        if root and humanoid and health and health.Value>0 and not state.TravelBusy and ctx.AtheonDodge then
            local target=state.FollowTarget
            local tr=target and target:FindFirstChild("HumanoidRootPart")
            local desired=tr and Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z) or root.Position
            local point,reason=ctx.AtheonDodge.Plan(root.Position,desired,api.FloorY)
            if point then
                hold(point,"Atheon evade: "..tostring(reason),now)
                ctx.Status("Atheon Dodge · "..tostring(reason))
                return true
            end
        end
        if not state.AutoDodge or not root or not humanoid or not health or health.Value<=0 or state.TravelBusy then
            if api.Active then ctx.Release() end
            api.Active,state.Dodging=false,false
            ctx.Status((state.AutoDodge and "Ready" or "Off").." · events "..seen.."/8")
            return false
        end
        if area=="Lava" or area=="Tempest" then
            if now>=nextScan then
                nextScan=now+3
                local container=area=="Lava" and workspace:FindFirstChild("ActiveLavaHazard") or workspace
                if container then for _,part in ipairs(container:QueryDescendants("BasePart")) do classify(part,now) end end
                for part in pairs(rocks) do if not part.Parent then rocks[part]=nil end end
                for part in pairs(strikes) do if not part.Parent then strikes[part]=nil end end
            end
        end
        if now<bobUntil and area~="Blackout" and area~="Lava" then
            local point=bobRefuge(root.Position,now)
            if point then hold(point,area=="Bob" and "Bob refuge" or "Bob residual-attack refuge",now)
            else hold(root.Position,"Bob waiting for map geometry",now) end
            ctx.Status(area=="Bob" and "Bob · keeping clear of enemies" or "Bob · waiting for residual attacks to end")
            return true
        end
        if area~="Blackout" and area~="Lava" and ctx.BossDodge and not (state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.NearBoss) then
            local region=bounds()
            local target=state.FollowTarget
            local tr=target and target:FindFirstChild("HumanoidRootPart")
            local desired=tr and Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z) or root.Position
            local point,reason=ctx.BossDodge.Plan(root.Position,desired,region,area=="Tempest" and threatened or nil)
            if point then
                hold(point,"Boss evade: "..tostring(reason),now)
                ctx.Status("Boss attack · outside danger zone")
                return true
            elseif ctx.BossDodge.Blocked then
                local fallback=api.BlackoutPoint(root.Position)
                if fallback then hold(fallback,"Boss evade below map bottom",now); return true end
            end
        end
        if area=="Blackout" then
            local point=api.BlackoutPoint(root.Position)
            if point then
                hold(point,"Blackout below map bottom",now)
                state.IdleBelowMap=true; state.IdleAboveMap=false
                ctx.Status("Blackout · sheltering below map bottom")
            else
                hold(root.Position,"Blackout waiting for map geometry",now)
                ctx.Status("Blackout · waiting for map bottom geometry")
            end
            return true
        elseif area=="Lava" then
            local region,origin=bounds()
            local baseY=region and region.Position.Y or (origin and origin.Position.Y or root.Position.Y)
            local best,score
            for part,data in pairs(rocks) do
                if not part.Parent then rocks[part]=nil
                else
                    local position,size,alpha=part.Position,part.Size,part.Transparency
                    local atSurface=position.Y>=baseY-0.12 and position.Y<=baseY+0.15
                    data.SurfaceTop=position.Y+(data.HalfHeight or size.Y/2)
                    local moved=(position-data.StablePosition).Magnitude>0.035 or (size-data.StableSize).Magnitude>0.04
                    if moved then data.StableAt=now; data.StablePosition=position; data.StableSize=size end
                    if data.WasReady and (data.SurfaceTop<baseY+2 or alpha>0.1
                        or not part.CanCollide or size.Magnitude<(data.ReadySize or size.Magnitude)*0.97) then data.Dying=true end
                    data.Ready=atSurface and part.CanCollide and alpha<0.08 and not data.Dying and now-data.StableAt>=0.24
                    if data.Ready then
                        data.WasReady=true; data.ReadySize=math.max(data.ReadySize or 0,size.Magnitude)
                        data.ReadySince=data.ReadySince or now
                        local value=horizontal(root.Position,position)
                        if part~=currentRock and (not score or value<score) then best,score=part,value end
                    end
                    data.LastY,data.LastAlpha=position.Y,alpha
                end
            end
            local current= currentRock and rocks[currentRock]
            local currentSolid=current and currentRock.Parent and currentRock.CanCollide and currentRock.Transparency<0.9 and (current.SurfaceTop or 0)>baseY+0.75
            local switch=not currentSolid or current.Dying or not current.WasReady
            local reason=not currentSolid and "Current rock unavailable" or (current and current.Dying and "Current rock disappearing" or "Initial rock")
            if not switch then best=currentRock
            elseif not best and currentSolid then best=currentRock end
            api.RockStatus={Current=currentRock,ReadyReplacement=best~=currentRock and best or nil,CurrentDying=current and current.Dying or false,Reason=reason}
            if best then
                if best~=currentRock then
                    currentRock,rockSince=best,now; api.RockChanges+=1
                    api.LastRockSwitch={At=now,Reason=reason,ReplacementReady=rocks[best] and rocks[best].Ready,Position=best.Position}
                    if eventRecord then eventRecord.RockChanges=(eventRecord.RockChanges or 0)+1 end
                end
                local e=extent(best)
                local top=best.Position+Vector3.new(0,e.Y,0)
                local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={best}
                local hit=workspace:Raycast(top+Vector3.new(0,4,0),Vector3.new(0,-e.Y*2-8,0),params)
                if hit then top=hit.Position end
                hold(top+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+0.25,0),"Lava rock",now)
                ctx.Status("Lava · "..((rocks[best] and rocks[best].Dying) and "waiting for a settled rock" or "holding current rock").." · events "..seen.."/8")
                return true
            end
            -- Do not let auto farm drive into the floor while rocks are loading.
            local _,origin=bounds()
            local minimumY=(origin and origin.Position.Y or root.Position.Y)+18
            local fallback=api.LastPosition and api.LastPosition.Y>=minimumY and api.LastPosition or Vector3.new(root.Position.X,minimumY,root.Position.Z)
            hold(fallback,"Waiting for rock",now)
            ctx.Status("Lava · waiting for a solid rock · events "..seen.."/8")
            return true
        elseif area=="Tempest" then
            local target=state.FollowTarget
            local tr=target and target:FindFirstChild("HumanoidRootPart")
            local desired=tr and Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z) or root.Position
            if threatened(root.Position) or threatened(desired) or now<holdUntil then
                local point=api.LastPosition or root.Position
                if threatened(point) then
                    local best,score
                    local region,origin=bounds()
                    for radius=10,60,5 do
                        for i=1,16 do
                            local angle=i*math.pi/8
                            local p=root.Position+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                            local inArena=not region or (math.abs(region.CFrame:PointToObjectSpace(p).X)<region.Size.X/2-10 and math.abs(region.CFrame:PointToObjectSpace(p).Z)<region.Size.Z/2-10)
                            if inArena and not threatened(p) then local value=horizontal(p,root.Position); if not score or value<score then best,score=p,value end end
                        end
                        if best then break end
                    end
                    if best then point=best; holdUntil=now+0.45 end
                end
                if not threatened(point) then
                    point=Vector3.new(point.X,api.FloorY(point)+(state.AutoFarm and -20 or humanoid.HipHeight+root.Size.Y/2+0.25),point.Z)
                    hold(point,"Lightning evade",now)
                    ctx.Status("Tempest · outside strike circles · events "..seen.."/8")
                    return true
                end
            end
        end
        if api.Active then ctx.Release() end
        api.Active,state.Dodging=false,false
        ctx.Status((area and area.." · watching" or "Ready").." · events "..seen.."/8")
        return false
    end
    function api.Idle(anchor)
        if state.StopEverything then return end
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local point=anchor or root.Position
        local floor=anchor and anchor.Y or api.FloorY(point)
        ctx.Hold(Vector3.new(point.X,floor-20,point.Z))
        state.IdleFloorY=floor
        state.IdleBelowMap=true
        state.IdleAboveMap=false
    end
    function api.Destroy()
        saveAudit()
        added:Disconnect()
        if ctx.BossDodge then ctx.BossDodge.Destroy() end
        if ctx.AtheonDodge then ctx.AtheonDodge.Destroy() end
        if api.Active then ctx.Release() end
        api.Active=false
        state.Dodging=false
    end
    return api
end

-- END BUNDLED WAVE DODGE
end)()({
    State = state,
    BossDodge = state.BossDodge,
    AtheonDodge = state.AtheonDodgeController,
    Hold = function(destination)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then return end
        if movementRoot and movementRoot ~= root then stopMovement(nil, true) end
        ensureMovementController(character, root, humanoid, destination)
        positionAlign.Enabled, orientationAlign.Enabled = true, true
        positionAlign.Position = destination
        if (root.Position-destination).Magnitude > 1.25 then pivotRoot(root, destination); state.TeleportsSent+=1 end
    end,
    Release = function()
        teleportTarget, correctionTarget = nil, nil
        correctionStrikes = 0
        nextMovementUpdate,nextAcquisition=0,0
        state.LastDodgeFinishedAt=os.clock()
        state.DodgeReturnPending=state.AutoFarm and state.Enabled
        if state.WakeSkillAura then state.WakeSkillAura() end
        state.OffsetGraceUntil = os.clock()+0.6
        if not state.AutoFarm then
            if state.MultiSpot and state.MultiSpotAnchor and state.FinishMultiSpotArrival then
                state.FinishMultiSpotArrival()
            elseif state.TravelHold and state.TravelHoldPosition then
                local character=player.Character; local root=character and character:FindFirstChild("HumanoidRootPart"); local humanoid=character and character:FindFirstChildOfClass("Humanoid")
                if root and humanoid then ensureMovementController(character,root,humanoid,state.TravelHoldPosition); positionAlign.Position=state.TravelHoldPosition; pivotRoot(root,state.TravelHoldPosition) end
            else stopMovement("Dodge complete",true) end
        end
    end,
    Status = function(message)
        state.DodgeStatus = message
    end,
})
state.WaveDodge = waveDodge
function state.SetAutoDodge(enabled)
    if state.StopEverything and enabled==true then return false end
    state.AutoDodge = enabled == true
    dodgeToggle.Text = state.AutoDodge and "Auto dodge · ON" or "Auto dodge · OFF"
    dodgeToggle.BackgroundColor3 = state.AutoDodge and Color3.fromRGB(91,72,164) or Color3.fromRGB(45,48,63)
    requestSave()
end
bind(dodgeToggle.Activated, function() state.SetAutoDodge(not state.AutoDodge) end)
state.SetAutoDodge(restore.AutoDodge)

do
    local oldZoom = player.CameraMaxZoomDistance
    local restoringZoom = false
    local function applyZoom()
        if restoringZoom or state.StopEverything or not state.Running then return end
        if player.CameraMaxZoomDistance < 1000000 then player.CameraMaxZoomDistance=1000000 end
    end
    applyZoom()
    bind(player:GetPropertyChangedSignal("CameraMaxZoomDistance"), applyZoom)
    local original = {}
    local function mapPart(part)
        if state.StopEverything then return false end
        if not part:IsA("BasePart") then return false end
        if state.SkillVisuals and state.SkillVisuals.IsEffect(part) then return false end
        if player.Character and part:IsDescendantOf(player.Character) then return false end
        for _, name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","WaveDefenseStuff","MobSpawnEffects"}) do
            local root=workspace:FindFirstChild(name)
            if root and part:IsDescendantOf(root) then return false end
        end
        return not waveDodge.IsHazardPart(part)
    end
    state.ExcludeMapPart=function(part)
        if original[part]~=nil then part.LocalTransparencyModifier=original[part]; original[part]=nil end
    end
    local function applyPart(part)
        if not mapPart(part) then return end
        if state.TransparentMap and not state.StopEverything then
            if original[part]==nil then
                local value=part.LocalTransparencyModifier
                original[part]=math.abs(value-0.7)<0.0001 and 0 or value
            end
            part.LocalTransparencyModifier=0.7
        elseif original[part]~=nil then part.LocalTransparencyModifier=original[part]; original[part]=nil end
    end
    function state.SetTransparentMap(enabled)
    if state.StopEverything and enabled==true then return false end
        state.TransparentMap=enabled==true
        for _,part in ipairs(workspace:QueryDescendants("BasePart")) do applyPart(part) end
        if not state.TransparentMap then
            for part,value in pairs(original) do if part.Parent then part.LocalTransparencyModifier=value end; original[part]=nil end
        end
        requestSave()
    end
    bind(workspace.DescendantAdded, function(part) if state.TransparentMap then applyPart(part) end end)
    bind(workspace.DescendantRemoving,function(part)
        if original[part]~=nil then part.LocalTransparencyModifier=original[part]; original[part]=nil end
    end)
    state.RestoreWorldVisuals=function()
        restoringZoom=true
        player.CameraMaxZoomDistance=oldZoom
        for part,value in pairs(original) do if part.Parent then part.LocalTransparencyModifier=value end end
    end
    state.SetTransparentMap(restore.TransparentMap)
end

do
    local create=(function()
-- BEGIN BUNDLED SKILL VISUALS
-- Suppress rendering while retaining animation timelines, hitboxes and callbacks.
return function(ctx)
    local state,player=ctx.State,game.Players.LocalPlayer
    local api={AnimationsHidden=0,EffectsHidden=0}
    local assets,names,effectNames,sounds,ordinaryAnimations={},{},{},{},{}
    local managed,tracks={},{}
    local maintenance,maintenanceQueued={},setmetatable({}, {__mode="k"})
    local maintenanceHead,maintenanceTail=1,0
    local ordinaryTracks=setmetatable({}, {__mode="k"})
    local connections={}
    local disposed=false
    local animator,played,nextCheck=nil,nil,0
    local urgent,background={},{ }
    local urgentHead,urgentTail,backgroundHead,backgroundTail=1,0,1,0
    local queued=setmetatable({}, {__mode="k"})
    local invisible=NumberSequence.new(1)
    local hiddenWeight=0.0001 -- A zero-weight track can stop before its damage markers.
    local gunUntil,gunOrigin=0,nil
    local gunModels=setmetatable({}, {__mode="k"})
    local function normalize(value) return string.lower((string.gsub(value or "","[^%w]",""))) end
    local function assetId(value) return string.match(value or "","%d+") end
    local generic={part=true,meshpart=true,model=true,folder=true,attachment=true,rock=true,rocks=true,groundrocks=true,floor=true,terrain=true,baseplate=true,spawnlocation=true,humanoidrootpart=true,uppertorso=true,lowertorso=true,vfx=true,handle=true,trail=true,beam=true,light=true,animation=true,particleemitter=true,pointlight=true,spotlight=true,surfacelight=true,sound=true,smoke=true,texture=true,decal=true}
    local locomotion={idle=true,walk=true,run=true,jump=true,fall=true,climb=true,swim=true,swimidle=true,sit=true,toolnone=true}
    for _,definition in ipairs(game.ReplicatedStorage.Database.Skills:GetChildren()) do names[normalize(definition.Name)]=true end
    for _,root in ipairs({ctx.Services.Skills,ctx.Services.SkillEffects}) do
        for _,animation in ipairs(root:QueryDescendants("Animation")) do
            local id=assetId(animation.AnimationId); if id then assets[id]=true end
        end
        for _,sound in ipairs(root:QueryDescendants("Sound")) do local id=assetId(sound.SoundId); if id then sounds[id]=true end end
        for _,instance in ipairs(root:QueryDescendants("BasePart,ParticleEmitter,Beam,Trail,Model,Sound")) do
            local key=normalize(instance.Name)
            if #key>=5 and not generic[key] then effectNames[key]=true end
        end
    end
    for _,style in pairs(ctx.Actions.animations) do
        if type(style)=="table" then for key,track in pairs(style) do
            if type(key)=="string" and typeof(track)=="Instance" and track:IsA("AnimationTrack") and track.Animation then
                local id=assetId(track.Animation.AnimationId)
                if id then if names[normalize(key)] then assets[id]=true else ordinaryAnimations[id]=true end end
            end
        end end
    end
    local function keep(instance)
        if (instance:IsA("BillboardGui") or instance:IsA("SurfaceGui"))
            and #instance:QueryDescendants("TextLabel,TextButton")>0 then return true end
        if ctx.Preserve and ctx.Preserve(instance) then return true end
        local mobs=workspace:FindFirstChild("Mobs")
        local characters=workspace:FindFirstChild("Characters")
        local items=workspace:FindFirstChild("CharacterItems")
        local ownItems=items and items:FindFirstChild(tostring(player.UserId))
        if items and instance:IsDescendantOf(items) and not (ownItems and instance:IsDescendantOf(ownItems)) then return true end
        if mobs and instance:IsDescendantOf(mobs) then return true end
        if characters and instance:IsDescendantOf(characters) and not (player.Character and instance:IsDescendantOf(player.Character)) then return true end
        return false
    end
    local function effect(instance)
        if managed[instance] then return true end
        if keep(instance) then return false end
        local gunNearby=false
        local part=instance:IsA("BasePart") and instance or instance:FindFirstAncestorWhichIsA("BasePart")
        if part then
            for model,expires in pairs(gunModels) do
                if not model.Parent or os.clock()>expires then gunModels[model]=nil
                else local gun=model:FindFirstChild("Gun"); if gun and gun:IsA("BasePart") and (part.Position-gun.Position).Magnitude<160 then gunNearby=true; break end end
            end
        end
        if (gunOrigin and os.clock()<gunUntil) or gunNearby then
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if part and (gunNearby or (gunOrigin and (part.Position-gunOrigin).Magnitude<160) or (root and (part.Position-root.Position).Magnitude<160)) then
                local sphere=part:IsA("Part") and part.Name=="Part" and not part.CanCollide and part.Shape==Enum.PartType.Ball
                    and part.Transparency>=.95 and part.Size.X>=8 and part.Size.X<=16
                if instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("ParticleEmitter") then return true end
                if instance:IsA("Decal") and (sphere or string.find(instance.Texture,"3170098415",1,true) or string.find(instance.Texture,"3170224154",1,true)) then return true end
                if sphere and (instance:IsA("Light") or instance:IsA("Sound")) then return true end
                if instance:IsA("BasePart") and not instance.CanCollide and instance.Material==Enum.Material.Neon
                    and (instance.BrickColor==BrickColor.new("Bright yellow")
                        or (instance:IsA("Part") and instance.Name=="Part" and instance.BrickColor==BrickColor.new("Bright blue")
                            and (instance.Shape==Enum.PartType.Ball or (instance.Size.Z>instance.Size.X*3 and instance.Size.Z>instance.Size.Y*3)))) then return true end
            end
        end
        if instance:IsA("Sound") and sounds[assetId(instance.SoundId)] then return true end
        local own=player.Character and instance:IsDescendantOf(player.Character)
        if own and instance:IsA("BasePart") and (instance.Parent==player.Character or instance.Parent:IsA("Accessory") or instance.Parent:IsA("Tool")) then return false end
        if own and (instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") or instance:IsA("Light") or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles")) then return true end
        local node=instance
        while node and node~=workspace do
            local key=normalize(node.Name)
            local rifle=key=="ar" and node:IsA("Model") and node:FindFirstChild("Gun")
                and (node:FindFirstChild("Portal1") or node:FindFirstChild("Portal2"))
            if node.Name=="HitEffects" or names[key] or effectNames[key] or key=="pistol" or key=="rifle" or key=="summonrifle" or rifle then return true end
            node=node.Parent
        end
        return false
    end
    -- Mobile executors may reject LocalTransparencyModifier on effect classes.
    -- Treat each property independently so one unsupported member cannot stall VFX cleanup.
    local function write(instance,property,value)
        return pcall(function()instance[property]=value end)
    end
    local function restore(instance,record)
        for property,value in pairs(record.Before) do write(instance,property,value) end
    end
    local function suppress(instance)
        if disposed or state.StopEverything then return end
        if managed[instance] or not effect(instance) then return end
        local properties
        if instance:IsA("BasePart") then
            if ctx.ExcludeMapPart then ctx.ExcludeMapPart(instance) end
            properties={LocalTransparencyModifier=1,Transparency=1}
        elseif instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then properties={Enabled=false,Transparency=invisible,LocalTransparencyModifier=1}
        elseif instance:IsA("Light") then properties={Enabled=false,Brightness=0}
        elseif instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then properties={Enabled=false}
        elseif instance:IsA("Sound") then properties={Volume=0}
        elseif instance:IsA("Decal") or instance:IsA("Texture") then properties={Transparency=1}
        elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then properties={Enabled=false}
        elseif instance:IsA("Highlight") then properties={Enabled=false,FillTransparency=1,OutlineTransparency=1} end
        if not properties then return end
        local record={Before={},Hidden=properties,Parent=instance.Parent}
        for property,value in pairs(properties) do
            local readable,before=pcall(function()return instance[property]end)
            if readable and write(instance,property,value) then record.Before[property]=before
            else record.Hidden[property]=nil end
        end
        if not next(record.Hidden)then return end
        managed[instance]=record
        if not maintenanceQueued[instance]then
            maintenanceTail+=1;maintenance[maintenanceTail]=instance;maintenanceQueued[instance]=true
        end
        if instance:IsA("ParticleEmitter") or instance:IsA("Trail") then pcall(function()instance:Clear()end) end
        api.EffectsHidden+=1
    end
    local function isSkill(track)
        if ordinaryTracks[track] then return false end
        local key=normalize(track.Name)
        if locomotion[key] or string.sub(key,1,5)=="swing" then return false end
        local id=track.Animation and assetId(track.Animation.AnimationId)
        if id and assets[id] then return true end
        if id and ordinaryAnimations[id] then return false end
        if names[key] then return true end
        if track.Priority.Value>=Enum.AnimationPriority.Action.Value then return true end
        return (state.SkillCastRunning or (ctx.SkillState and ctx.SkillState.usingSkill~="none")) and not locomotion[key]
    end
    api.IsSkillAnimation=isSkill
    function api.MarkGunCast(name,origin)
        if name=="Summon Pistol" or name=="Summon Rifle" then gunUntil=os.clock()+5; gunOrigin=origin end
    end
    function api.AllowSwingTrack(track)
        ordinaryTracks[track]=true
        local before=tracks[track]
        if before and track.IsPlaying then track:AdjustWeight(before.Weight,0) end
        tracks[track]=nil
    end
    local function hideTrack(track)
        if disposed or state.StopEverything then return end
        if not isSkill(track) then return end
        if not tracks[track] then
            tracks[track]={Weight=track.WeightTarget}
            api.AnimationsHidden+=1
        end
        if math.abs(track.WeightTarget-hiddenWeight)>0.00001 or track.WeightCurrent>0.001 then track:AdjustWeight(hiddenWeight,0) end
    end
    local function enqueue(instance,priority)
        if disposed or state.StopEverything or queued[instance] or managed[instance] then return end
        local name=instance.ClassName
        if not (instance:IsA("BasePart") or instance:IsA("Light") or name=="ParticleEmitter" or name=="Beam" or name=="Trail"
            or name=="Smoke" or name=="Fire" or name=="Sparkles" or name=="Texture" or name=="Sound" or name=="Decal" or name=="BillboardGui" or name=="SurfaceGui" or name=="Highlight") then return end
        queued[instance]=true
        if priority then urgentTail+=1; urgent[urgentTail]=instance
        else backgroundTail+=1; background[backgroundTail]=instance end
    end
    function api.ProcessPending()
        local deadline=os.clock()+.0006
        local count=0
        while count<64 and (count==0 or os.clock()<deadline) do
            local instance
            if urgentHead<=urgentTail then instance=urgent[urgentHead]; urgent[urgentHead]=nil; urgentHead+=1
            elseif backgroundHead<=backgroundTail then instance=background[backgroundHead]; background[backgroundHead]=nil; backgroundHead+=1
            else break end
            queued[instance]=nil
            if instance.Parent then pcall(suppress,instance) end
            count+=1
        end
        if urgentHead>urgentTail then table.clear(urgent); urgentHead,urgentTail=1,0 end
        if backgroundHead>backgroundTail then table.clear(background); backgroundHead,backgroundTail=1,0 end
        api.Pending=urgentTail-urgentHead+1+backgroundTail-backgroundHead+1
        state.VisualQueueSize=api.Pending
    end
    local immediateCount,immediateSince=0,0
    local function added(instance)
        if disposed or state.StopEverything or not state.Running then return end
        if instance:IsA("Model") and (instance.Name=="AR" or instance.Name=="Pistol") then
            gunModels[instance]=os.clock()+5
            for _,part in ipairs(instance:QueryDescendants("BasePart,ParticleEmitter,Beam,Trail,Smoke,Fire,Sparkles,Sound,Decal,Texture")) do enqueue(part,true) end
        end
        if instance:IsA("TextLabel") or instance:IsA("TextButton") then
            local gui=instance:FindFirstAncestorWhichIsA("BillboardGui") or instance:FindFirstAncestorWhichIsA("SurfaceGui")
            local record=gui and managed[gui]
            if record then
                restore(gui,record)
                managed[gui]=nil
            end
            return
        end
        -- Hide proven effects on arrival, before waiting for the next mobile frame.
        -- Cap synchronous work during bursty casts; overflow uses the bounded queue.
        local now=os.clock()
        if now-immediateSince>=.05 then immediateSince=now;immediateCount=0 end
        if immediateCount<24 then
            immediateCount+=1
            pcall(suppress,instance)
        end
        enqueue(instance,state.SkillCastRunning or state.MiscCastRunning or instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail")
            or instance:IsA("Sound") or effectNames[normalize(instance.Name)]~=nil)
    end
    connections[#connections+1]=workspace.DescendantAdded:Connect(added)
    connections[#connections+1]=workspace.DescendantRemoving:Connect(function(instance)
        local record=managed[instance]
        if record then restore(instance,record); managed[instance]=nil end
    end)
    for _,instance in ipairs(workspace:QueryDescendants("ParticleEmitter,Beam,Trail,Smoke,Fire,Sparkles,Light,BasePart,Decal,Texture,BillboardGui,SurfaceGui,Highlight,Sound")) do enqueue(instance,false) end
    for _,model in ipairs(workspace:QueryDescendants("#AR,#Pistol")) do if model:IsA("Model") then gunModels[model]=os.clock()+5 end end
    function api.IsEffect(instance) return effect(instance) end
    function api.ProcessManaged()
        local dynamic=not ctx.DynamicHazards or ctx.DynamicHazards()
        local deadline=os.clock()+.0006
        local available=math.min(64,maintenanceTail-maintenanceHead+1)
        local count=0
        while count<available and (count==0 or os.clock()<deadline)do
            local instance=maintenance[maintenanceHead]
            maintenance[maintenanceHead]=nil;maintenanceHead+=1;maintenanceQueued[instance]=nil
            local record=managed[instance]
            if record then
                pcall(function()
                    if not instance.Parent then managed[instance]=nil
                    elseif (instance:IsA("BillboardGui") or instance:IsA("SurfaceGui")) and keep(instance) then
                        restore(instance,record)
                        managed[instance]=nil
                    elseif (dynamic or instance.Parent~=record.Parent) and keep(instance) then
                        restore(instance,record)
                        managed[instance]=nil
                    else
                        record.Parent=instance.Parent
                        for property,value in pairs(record.Hidden) do
                            local ok,current=pcall(function()return instance[property]end)
                            if ok then
                                if typeof(value)=="NumberSequence" then
                                    local points=current.Keypoints
                                    if #points~=2 or points[1].Value~=1 or points[2].Value~=1 then write(instance,property,value) end
                                elseif current~=value then write(instance,property,value) end
                            end
                        end
                    end
                end)
                if managed[instance]then
                    maintenanceTail+=1;maintenance[maintenanceTail]=instance;maintenanceQueued[instance]=true
                end
            end
            count+=1
        end
        if maintenanceHead>maintenanceTail then table.clear(maintenance);maintenanceHead,maintenanceTail=1,0 end
        return count
    end
    function api.Update()
        if disposed or state.StopEverything then return end
        api.ProcessPending()
        local now=os.clock()
        if now<nextCheck then return end
        nextCheck=now+0.08
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local current=humanoid and humanoid:FindFirstChildOfClass("Animator")
        if current~=animator then
            if played then played:Disconnect(); played=nil end
            animator=current
            if animator then played=animator.AnimationPlayed:Connect(function(track)
                hideTrack(track)
                task.defer(function() if state.Running and track.IsPlaying then hideTrack(track) end end)
            end) end
        end
        if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do hideTrack(track) end end
        for track,record in pairs(tracks) do
            if not track.IsPlaying then tracks[track]=nil
            elseif track.WeightCurrent>0.001 or math.abs(track.WeightTarget-hiddenWeight)>0.00001 then track:AdjustWeight(hiddenWeight,0) end
        end
        api.ProcessManaged()
        state.HiddenSkillAnimations=api.AnimationsHidden
        state.HiddenSkillEffects=api.EffectsHidden
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        if played then played:Disconnect() end
        for _,connection in ipairs(connections) do connection:Disconnect() end
        for track,record in pairs(tracks) do if track.IsPlaying then track:AdjustWeight(record.Weight,0) end end
        for instance,record in pairs(managed) do if instance.Parent then restore(instance,record) end end
        table.clear(managed); table.clear(tracks)
        table.clear(maintenance);table.clear(maintenanceQueued);maintenanceHead,maintenanceTail=1,0
        table.clear(urgent); table.clear(background); table.clear(queued)
        table.clear(gunModels)
        urgentHead,urgentTail,backgroundHead,backgroundTail=1,0,1,0
        api.Pending=0; state.VisualQueueSize=0
    end
    api.Update()
    return api
end

-- END BUNDLED SKILL VISUALS
    end)()
    state.SkillVisuals=create({
        State=state,Services=services,Actions=Actions,SkillState=Skills,ExcludeMapPart=state.ExcludeMapPart,
        DynamicHazards=function() return waveDodge.Event=="Lava" or waveDodge.Event=="Tempest" or (state.BossDodge and state.BossDodge.HasHazards) end,
        Preserve=function(instance)
            local node=instance
            while node and node~=workspace do
                if node.Name=="ActiveLavaHazard" or node.Name=="WaveDefenseStuff" or node.Name=="PillarSpawns" then return true end
                if node:IsA("BasePart") and waveDodge.IsHazardPart(node) then return true end
                node=node.Parent
            end
            return false
        end,
    })
end

-- Area coordinates remain usable when distance-based spawning removes the mob.
local destinationPath = configFolder .. "/destinations_" .. tostring(game.PlaceId) .. ".json"
local destinations = {}
local destinationsDirty=false
local function finitePoint(point)
    return typeof(point) == "Vector3" and point.X == point.X and point.Y == point.Y and point.Z == point.Z
        and math.abs(point.X) < 1000000 and math.abs(point.Y) < 1000000 and math.abs(point.Z) < 1000000
end
local function rememberDestination(id, name, kind, point)
    if not finitePoint(point) then return end
    local old=destinations[id]
    if old and old.Name==name and old.Kind==kind and (old.Position-point).Magnitude<.01 then return end
    destinations[id] = { Id = id, Name = name, Kind = kind, Position = point }
    destinationsDirty=true
end
-- Verified on the current Floor 7 map; independent of whether Frogazoid exists.
if game.PlaceId == 582198062 then
    rememberDestination("mob:Frogazoid", "Frogazoid", "Mini boss", Vector3.new(-154.811, 1214.301, -758.796))
end
if filePersistence then
    pcall(function()
        if not isfile(destinationPath) then return end
        local raw = readfile(destinationPath)
        if #raw > 65536 then return end
        local data = HttpService:JSONDecode(raw)
        if data.Version ~= 1 or data.PlaceId ~= game.PlaceId or type(data.Areas) ~= "table" then return end
        for index, area in ipairs(data.Areas) do
            if index > 64 then break end
            if type(area.Id) == "string" and type(area.Name) == "string" and type(area.Kind) == "string" and type(area.Position) == "table" then
                local p = area.Position
                if type(p[1]) == "number" and type(p[2]) == "number" and type(p[3]) == "number" then
                    rememberDestination(area.Id, area.Name, area.Kind, Vector3.new(p[1], p[2], p[3]))
                end
            end
        end
    end)
end
-- Fixed destination coordinates from the supplied source, available before areas stream in.
do
    local supplied = ({
        [542351431] = { -- floor 1
            Boss = Vector3.new(-2977.1355, -229.28125, 1221.8555),
            Portal = Vector3.new(-2940.8562, -207.597794, 982.687012),
            Miniboss = Vector3.new(139.343933, 225.040985, -132.926147)
        },
        [548231754] = { -- floor 2
            Boss = Vector3.new(-2013.0431, 445.54346, -8953.9512),
            Portal = Vector3.new(-2181.09204, 466.482727, -8955.31055)
        },
        [555980327] = { -- floor 3
            Boss = Vector3.new(448.331146, 4279.3374, -385.050385),
            Portal = Vector3.new(-381.196564, 4184.99902, -327.238312)
        },
        [572487908] = { -- floor 4
            Boss = Vector3.new(-2318.12964, 2280.41992, -514.067749),
            Portal = Vector3.new(-2319.54028, 2091.30078, -106.37648),
            Miniboss = Vector3.new(-1361.35596, 5173.21387, -390.738007)
        },
        [580239979] = { -- floor 5
            Boss = Vector3.new(2189.17822, 1308.125, -121.071182),
            Portal = Vector3.new(2188.29614, 1255.37036, -407.864594)
        },
        [582198062] = { -- floor 7
            Boss = Vector3.new(3347.78955, 800.043884, -804.310425),
            Portal = Vector3.new(3336.35645, 747.824036, -614.307983)
        },
        [548878321] = { -- floor 8
            Boss = Vector3.new(1848.35413, 4110.43945, 7723.38623),
            Portal = Vector3.new(1665.46252, 4094.20312, 7722.29443),
            Miniboss = Vector3.new(-811.7854, 3179.59814, -949.255676)
        },
        [573267292] = { -- floor 9
            Boss = Vector3.new(12241.4648, 461.776215, -3655.09009),
            Portal = Vector3.new(12357.0059, 439.948914, -3470.23218),
            Miniboss = Vector3.new(1928, 2889, -11349),
            ['Second miniboss'] = Vector3.new(1973.94238, 2986.00952, -4486.8125)
        },
        [2659143505] = { -- floor 10
            Boss = Vector3.new(45.494194, 1003.77246, 25432.9902),
            Portal = Vector3.new(110.383698, 940.75531, 24890.9922),
            Miniboss = Vector3.new(-894.185791, 467.646698, 6505.85254)
        },
        [5287433115] = { -- floor 11
            Boss = Vector3.new(4916.49414, 2312.97021, 7762.28955),
            Portal = Vector3.new(5224.18994, 2602.94019, 6438.44678),
            Miniboss = Vector3.new(4801.12695, 1646.30347, 2083.19116),
            ['Za, the Eldest'] = Vector3.new(4001.55908, 421.515015, -3794.19727),
            ['Wa, the Curious'] = Vector3.new(4821.5874, 3226.32788, 5868.81787),
            ['Duality Reaper  '] = Vector3.new(4763.06934, 501.713593, -4344.83838),
            ['Neon chest       '] = Vector3.new(5204.35449, 2294.14502, 5778.00195)
        },
        [13965775911] = { -- Atheon / floor 13 (user-provided arena)
            ['Atheon arena'] = Vector3.new(840, 798, 336)
        },
        [6144637080] = { -- floor 12
            ['Suspended Unborn'] = Vector3.new(-5324.62305, 427.934784, 3754.23682),
            ['Limor the Devourer'] = Vector3.new(-1093.02625, -169.141785, 7769.1875),
            ['Radioactive Experiment'] = Vector3.new(-4643.86816, 425.090515, 3782.8252)
        }
    })[game.PlaceId] or {}
    local kinds = {Boss="Boss", Miniboss="Mini boss", ["Second miniboss"]="Mini boss", Portal="Exit", ["Atheon arena"]="Arena"}
    local names = {Boss="Boss area", Miniboss="Mini-boss area"}
    state.SourceDestinationCount = 0
    for originalName, point in pairs(supplied) do
        local name = string.match(originalName, "^%s*(.-)%s*$")
        local id = "source:" .. name
        rememberDestination(id, names[name] or name, kinds[name] or "Area", point)
        destinations[id].Source = "Provided source"
        state.SourceDestinationCount += 1
    end
end
local lastAreaPayload
local function saveDestinations()
    if not filePersistence or not destinationsDirty then return end
    pcall(function()
        if not isfolder(configFolder) then makefolder(configFolder) end
        local areas = {}
        for _, area in pairs(destinations) do
            if #areas >= 64 then break end
            local p = area.Position
            areas[#areas + 1] = { Id = area.Id, Name = area.Name, Kind = area.Kind, Position = { p.X, p.Y, p.Z } }
        end
        table.sort(areas, function(a, b) return a.Id < b.Id end)
        local payload = HttpService:JSONEncode({ Version = 1, PlaceId = game.PlaceId, Areas = areas })
        if payload ~= lastAreaPayload then writefile(destinationPath, payload); lastAreaPayload = payload end
        destinationsDirty=false
    end)
end
local function rankMob(mob)
    local priority=targetPriority.Rank(mob)
    return priority==1 and "Boss" or priority==2 and "Mini boss" or nil
end
local function discoverDestinations(onlyMobs)
    if workspace:FindFirstChild("WaveDefenseStuff") then
        local stage=tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        if state.DestinationEnvironment~=stage then
            for id in pairs(destinations) do if string.sub(id,1,4)=="mob:" or id=="wave:rift" then destinations[id]=nil; destinationsDirty=true end end
            state.DestinationEnvironment=stage
        end
        local marker=workspace.WaveDefenseStuff:FindFirstChild("RiftBossSpawn")
        if marker and string.find(string.lower(stage),"rift",1,true) then rememberDestination("wave:rift","Rift boss spawn","Boss",marker.Position) end
    end
    if not onlyMobs then
    local mapContainers = { workspace }
    for _, folderName in ipairs({ "Models", "OptimizedGame" }) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then mapContainers[#mapContainers + 1] = folder end
    end
    for _, models in ipairs(mapContainers) do
        for _, model in ipairs(models:GetChildren()) do
            if model:IsA("Model") or model:IsA("BasePart") then
                local key = string.lower((string.gsub(model.Name, "[^%w]", "")))
                local kind
                if key == "bossroom" or key == "bossarena" or key == "bossspawn" or key == "aspawnboss" then kind = "Boss"
                elseif key == "minibossroom" or key == "minibossarena" or key == "minibossspawn" or key == "aspawnminiboss" then kind = "Mini boss"
                elseif key == "entryroom" or key == "dungeonentrance" then kind = "Dungeon"
                elseif key == "exitteleportroom" or key == "exitportal" then kind = "Exit"
                elseif string.match(key, "^bigdungeonroom%d+$") then kind = "Dungeon" end
                if kind then
                    local displayName = model.Name == "BossRoom" and "Boss room" or model.Name
                    if key == "aspawnboss" then displayName = "Boss spawn area"
                    elseif key == "aspawnminiboss" then displayName = "Mini-boss spawn area" end
                    local room = string.match(key, "^bigdungeonroom(%d+)$")
                    if room then displayName = "Room " .. room end
                    rememberDestination("map:" .. model.Name, displayName, kind, model:GetPivot().Position)
                end
            end
        end
    end
    local checkpoints = workspace:FindFirstChild("CheckpointPortals")
    if checkpoints then
        local points = {}
        for _, model in ipairs(checkpoints:GetChildren()) do
            if model:IsA("Model") or model:IsA("BasePart") then points[#points + 1] = model:GetPivot().Position end
        end
        table.sort(points, function(a, b) if a.X ~= b.X then return a.X < b.X end; return a.Z < b.Z end)
        for index, point in ipairs(points) do rememberDestination("checkpoint:" .. index, "Checkpoint " .. index, "Checkpoint", point) end
    end
    local spawns = workspace:QueryDescendants("SpawnLocation")
    if #spawns > 0 then
        local total = Vector3.zero
        for _, spawn in ipairs(spawns) do total += spawn.Position end
        rememberDestination("spawn", "Floor spawn", "Spawn", total / #spawns)
    end
    end
    for mob in pairs(trackedMobs) do
        if mob.Parent then
            local kind, root = rankMob(mob), mob:FindFirstChild("HumanoidRootPart")
            if kind and root then
                local id = "mob:" .. mob.Name
                -- Keep the first observed spawn area instead of following a boss that chases players.
                if not destinations[id] or workspace:FindFirstChild("WaveDefenseStuff") then rememberDestination(id, mob.Name, kind, root.Position) end
            end
        end
    end
    state.FloorDestinations = destinations
    saveDestinations()
end
local floorName = "Floor " .. tostring(game.PlaceId)
pcall(function()
    for _, floor in ipairs(require(ReplicatedStorage.Database.Locations).floors) do
        if floor.PlaceId == game.PlaceId then floorName = floor.Name; break end
    end
end)
state.FloorName = floorName
function state.ReadAutomationEncounter(spot)
    local tracked=state.MultiSpotEncounter or {}
    state.MultiSpotEncounter=tracked
    local now=os.clock()
    local function scan()
        state.MultiSpotNextScan=now+1
        for mob in pairs(trackedMobs) do
            if mob.Parent then
                local data=getMobData(mob)
                local root=data and data.Root or mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart or mob:FindFirstChild("RootPart")
                if root and ((spot.EncounterNames and spot.EncounterNames[mob.Name]) or (root.Position-spot.Position).Magnitude<=220)
                    and (not data or (data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0))) then
                    tracked[mob]=true
                end
                if not data then state.MultiSpotNextScan=math.min(state.MultiSpotNextScan,now+.1) end
            end
        end
    end
    local function count()
        local alive,seen=0,false
        for mob in pairs(tracked) do
            if mob.Parent then
                local data=getMobData(mob)
                -- Missing streamed health is not proof that a previously seen mob died.
                if not data or (data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0)) then alive=alive+1 end
            end
            seen=true
        end
        return alive,seen
    end
    local scanned=now>=(state.MultiSpotNextScan or 0)
    if scanned then scan() end
    local alive,seen=count()
    -- A cached zero must never authorize travel without checking for new adds.
    if alive==0 and not scanned then scan();alive,seen=count() end
    return alive,seen
end
function state.RegisterAutomationDestination(spot)
    if spot.PlaceId~=game.PlaceId then return false end
    local existing=destinations[spot.DestinationId]
    if existing then
        if spot.MainBoss then rememberDestination(spot.DestinationId,existing.Name,spot.Kind,spot.Position)end
        if spot.DestinationId:sub(1,4)=="mob:" then existing.Name=spot.DestinationId:sub(5) end
        return true
    end
    rememberDestination(spot.DestinationId,spot.Name,spot.Kind,spot.Position)
    return true
end
travelHeading.Text = "TELEPORTS · " .. floorName
travelHeading.TextTruncate = Enum.TextTruncate.AtEnd

do
    local make=(function()
-- BEGIN BUNDLED ARENA TRAVEL
-- Stream from near the destination, then confirm an actual stable landing.
-- Engine operations are injected for offline delayed-stream/cancellation tests.
return function(ctx)
    local api={}
    function api.Move(point,_automatic,active)
        local character,root,humanoid=ctx.Character()
        assert(character and root and humanoid and humanoid.Health>0 and not root.Anchored,"Character is not ready")
        local function current()
            local latest=ctx.Character()
            return active() and latest==character and root.Parent~=nil and humanoid.Health>0
        end
        local function check()assert(current(),"Travel cancelled")end
        check()
        local stage=point-Vector3.new(0,20,0)
        assert(ctx.Valid(stage),"Invalid arena position")
        ctx.Hold(character,root,humanoid,stage)
        local surface
        -- Moving nearby also triggers streaming when RequestStreamAroundAsync is
        -- unavailable in a mobile executor. Never raycast an unloaded remote map.
        for attempt=1,4 do
            check()
            if ctx.Stream then pcall(ctx.Stream,point,attempt==1 and 2 or .5) end
            check()
            surface=ctx.Surface(point)
            if surface then break end
            ctx.Wait(.15)
        end
        assert(surface,"Arena collision has not streamed in yet")
        check()
        local destination=stage
        assert(ctx.Valid(destination),"Landing surface is too low")
        local stableSince
        local deadline=ctx.Clock()+2
        repeat
            check()
            ctx.Hold(character,root,humanoid,destination)
            ctx.Wait(.1)
            check()
            if (root.Position-destination).Magnitude<=3 then
                stableSince=stableSince or ctx.Clock()
                if ctx.Clock()-stableSince>=.3 then
                    return {Position=destination,SurfaceY=surface.Y,Character=character}
                end
            else stableSince=nil end
        until ctx.Clock()>=deadline
        error("The game corrected this teleport; retrying the same arena")
    end
    return api
end

-- END BUNDLED ARENA TRAVEL
    end)()
    state.ArenaTravel=make({Clock=os.clock,Wait=task.wait,
        Character=function()
            local character=player.Character
            return character,character and character:FindFirstChild("HumanoidRootPart"),character and character:FindFirstChildOfClass("Humanoid")
        end,
        Valid=function(point)return finitePoint(point) and point.Y>workspace.FallenPartsDestroyHeight+30 end,
        Stream=function(point,timeout)player:RequestStreamAroundAsync(point,timeout)end,
        Surface=function(point)
            local character=player.Character
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances={character,workspace:FindFirstChild("Mobs") or character,workspace:FindFirstChild("Characters") or character}
            params.RespectCanCollide=true;params.IgnoreWater=false
            local hit=workspace:Raycast(point+Vector3.new(0,8,0),Vector3.new(0,-320,0),params)
            if not hit then hit=workspace:Raycast(point+Vector3.new(0,96,0),Vector3.new(0,-480,0),params) end
            if hit and hit.Normal.Y>=.65 and hit.Material~=Enum.Material.Water then return hit.Position end
        end,
        Hold=function(character,root,humanoid,point)
            ensureMovementController(character,root,humanoid,point)
            positionAlign.Enabled=true;positionAlign.Position=point
            if orientationAlign then orientationAlign.Enabled=true end
            if (root.Position-point).Magnitude>1 then pivotRoot(root,point) end
        end,
    })
end
do
    local make=(function()
-- BEGIN BUNDLED ARENA FLOAT
-- Counter gravity after a one-shot arena trip without pinning a position.
return function(ctx)
    local api={}
    local attachment,force,nextUpdate
    function api.Release()
        if force then force:Destroy();force=nil end
        if attachment then attachment:Destroy();attachment=nil end
        api.Root=nil
    end
    function api.Attach(root)
        if root.Anchored then return end
        if api.Root==root and force and force.Parent then return end
        api.Release();api.Root=root
        attachment=ctx.Create("Attachment",{Name="SB2ArenaFloatAttachment"},root)
        force=ctx.Create("VectorForce",{Name="SB2ArenaFloat",Attachment0=attachment,
            ApplyAtCenterOfMass=true,RelativeTo=Enum.ActuatorRelativeTo.World,
            Force=Vector3.new(0,root.AssemblyMass*ctx.Workspace.Gravity,0)},root)
        nextUpdate=0
    end
    function api.Update(now)
        if not api.Root then return end
        if not api.Root.Parent or api.Root.Anchored or ctx.Root()~=api.Root then api.Release();return end
        if now<(nextUpdate or 0) then return end
        nextUpdate=now+.5
        force.Force=Vector3.new(0,api.Root.AssemblyMass*ctx.Workspace.Gravity,0)
    end
    api.Destroy=api.Release
    return api
end

-- END BUNDLED ARENA FLOAT
    end)()
    state.ArenaFloat=make({Create=create,Workspace=workspace,Root=function()
        local character=player.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end})
end
function state.FinishMultiSpotArrival()
    state.TravelHold=false;state.TravelHoldPosition=nil;state.MultiSpotLandingPosition=nil
    if state.AutoFarm and state.Enabled then return true end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or root.Anchored or not humanoid or humanoid.Health<=0 then return false end
    if state.ArenaFloat.Root~=root then
        stopMovement(nil,true)
        state.ArenaFloat.Attach(root)
    end
    return true
end
function state.HoldMultiSpotIdle()
    if not state.MultiSpot or not state.MultiSpotAnchor or state.StopEverything or state.SafeModePanic
        or state.TravelBusy or state.MultiSpotOwnsTravel or state.Dodging or state.Recovering then state.MultiSpotEmptySince=nil;return false end
    local spot=state.MultiSpotController and state.MultiSpotController.Current
    if not spot or state.ReadAutomationEncounter(spot)~=0 then state.MultiSpotEmptySince=nil;return false end
    if state.MultiSpotEmptyAnchor~=state.MultiSpotAnchor then
        state.MultiSpotEmptyAnchor=state.MultiSpotAnchor;state.MultiSpotEmptySince=nil
    end
    local now=os.clock()
    state.MultiSpotEmptySince=state.MultiSpotEmptySince or now
    if now-state.MultiSpotEmptySince<5 then return false end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or root.Anchored or not humanoid or humanoid.Health<=0 then return false end
    waveDodge.Idle(state.MultiSpotAnchor)
    return true
end
function state.TeleportToDestination(id,urgent,automatic)
    if state.SafeModePanic or state.StopEverything or state.TravelBusy or not state.Running then return false,"Another movement has priority" end
    discoverDestinations()
    local area=destinations[id]
    if not area then setTravelStatus("Area not located on this floor yet");return false,"Arena is not available" end
    state.TravelSerial=(state.TravelSerial or 0)+1
    local serial=state.TravelSerial
    state.TravelBusy=true;state.MultiSpotTravelPending=automatic==true
    state.LastTravelDestination=nil;state.LastTravelPosition=nil
    state.TravelError=nil
    setTravelOpen(false)
    -- Prevent continuous skills from taking a new lease before travel gets a turn.
    if automatic and state.CancelSkillAura then state.CancelSkillAura("Moving to next selected arena") end
    stopMovement("Travelling · farming will resume",true)
    task.spawn(function()
        local function current()return state.Running and not state.SafeModePanic and not state.StopEverything and state.TravelSerial==serial end
        local ok,message=pcall(function()
            local deadline=os.clock()+4
            while current() and (state.Recovering or state.SkillCastRunning) and os.clock()<deadline do task.wait(.05) end
            if not current() then return end
            assert(not state.Recovering and not state.SkillCastRunning,"Wait for the current movement or skill to finish")
            setTravelStatus("Loading "..area.Name.."...")
            local landing=state.ArenaTravel.Move(area.Position,automatic==true,current)
            if not current() then return end
            local destination=landing.Position
            state.LastTravelLanding={SourcePosition=area.Position,SurfaceY=landing.SurfaceY,Requested=destination,Actual=destination,Depth=landing.SurfaceY-destination.Y}
            state.LastTravelDestination=id;state.LastTravelPosition=destination
            state.MultiSpotLandingPosition=automatic and destination or nil
            state.TeleportsSent+=1
            state.TravelHold=automatic==true or not (state.AutoFarm and state.Enabled)
            state.TravelHoldPosition=state.TravelHold and destination or nil
            if area.Kind=="Boss" or area.Kind=="Mini boss" then
                state.TravelFocus={Kind=area.Kind,Name=id:sub(1,4)=="mob:" and area.Name or nil,Until=os.clock()+8}
                state.FollowTarget=nil
            end
            setTravelStatus("Arrived: "..area.Name.." · 20 studs below position")
            if automatic and state.MultiSpotController and state.MultiSpotController.Current then
                local _,seen=state.ReadAutomationEncounter(state.MultiSpotController.Current)
                if seen then state.MultiSpotController.EncounterSeen=true end
            end
            lastSurfaceY=landing.SurfaceY+4
        end)
        if state.TravelSerial~=serial then return end
        if not ok then stopMovement("Travel will retry",true);state.TravelError=tostring(message);setTravelStatus(state.TravelError) end
        state.TravelBusy=false;state.MultiSpotTravelPending=false
        if ok and automatic and state.MultiSpotOwnsTravel and state.MultiSpotController then
            local confirmed,reason=pcall(state.MultiSpotController.Update,os.clock())
            if not confirmed then state.MultiSpotController.Pause(tostring(reason)) end
        end
    end)
    return true
end
local function refreshTravelChoices()
    discoverDestinations()
    for _, child in ipairs(travelList:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
    local choices, hasMini = {}, false
    local order = { Boss = 1, ["Mini boss"] = 2, Spawn = 3, Checkpoint = 4, Dungeon = 5, Exit = 6 }
    for _, area in pairs(destinations) do choices[#choices + 1] = area; if area.Kind == "Mini boss" then hasMini = true end end
    table.sort(choices, function(a, b) local x,y=order[a.Kind] or 7,order[b.Kind] or 7; if x ~= y then return x < y end; return a.Name < b.Name end)
    local function option(text, index, callback)
        local button = create("TextButton", {
            Name = "Destination" .. index, Text = text, Font = Enum.Font.Gotham, TextSize = 11,
            Size = UDim2.new(1, -4, 0, 30), LayoutOrder = index, BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(41, 44, 59), TextColor3 = Color3.fromRGB(226, 229, 243),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, travelList)
        corner(button, 6)
        button.Activated:Connect(callback)
    end
    for index, area in ipairs(choices) do
        option(area.Kind .. " · " .. area.Name, index, function() state.TeleportToDestination(area.Id) end)
    end
    if not hasMini then
        option("Mini boss · area not discovered yet", 100, function() setTravelStatus("Visit the mini-boss area once, then save it below") end)
        option("Save current spot as mini-boss area", 101, function()state.SaveCurrentMiniBossArea()end)
    end
end
function state.SaveCurrentMiniBossArea()
    if state.StopEverything then return false end
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then rememberDestination("saved:mini", "Saved mini-boss area", "Mini boss", root.Position); saveDestinations(); refreshTravelChoices(); setTravelStatus("Mini-boss area saved for " .. floorName) end
end
state.RefreshTeleportDestinations = refreshTravelChoices
bind(travelDropdown.Activated, function()
    if state.StopEverything or state.TravelBusy then return end
    if not travelList.Visible then refreshTravelChoices() end
    skillList.Visible = false
    setTravelOpen(not travelList.Visible)
end)
refreshTravelChoices()
local nextAreaDiscovery = 0

local nextExploreAt, exploreAngle = 0, 0
local exploredCenters = {}
local function freshExplorePoint(position)
    for _, center in ipairs(exploredCenters) do
        local delta = (position - center) * Vector3.new(1, 0, 1)
        if delta:Dot(delta) < 420 * 420 then return false end
    end
    return true
end
local function exploreEmptyArea(character, root, humanoid, now)
    if now < nextExploreAt then movementStatus("Exploring · waiting for the new area to load"); return end
    local destination, hint
    local best = 1500 * 1500
    for mob in pairs(trackedMobs) do
        local mobRoot = validMob(mob, indexedMobFolder)
        if mobRoot then
            local delta = (mobRoot.Position - root.Position) * Vector3.new(1, 0, 1)
            local distance = delta:Dot(delta)
            if distance > 540 * 540 and distance < best and freshExplorePoint(mobRoot.Position) and mobRoot.Position.Y > workspace.FallenPartsDestroyHeight + 60 then
                best = distance
                destination = mobRoot.Position + Vector3.new(0, state.TeleportOffset, 0)
                hint = mob
            end
        end
    end
    if hint then
        local hintRoot = getMobRoot(hint)
        if hintRoot then
            local offset = state.ResolveAutoOffset(hint)
            if not offset then return end
            destination = state.AutoOffsetDestination or hintRoot.Position + Vector3.new(0, offset, 0)
        end
    end
    if not destination then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { character, indexedMobFolder or character, workspace:FindFirstChild("Characters") or character }
        params.RespectCanCollide = true
        params.IgnoreWater = false
        for index = 1, 12 do
            local angle = exploreAngle + (index - 1) * math.pi / 6
            local point = root.Position + Vector3.new(math.cos(angle) * 560, 0, math.sin(angle) * 560)
            local floor = workspace:Raycast(point + Vector3.new(0, 400, 0), Vector3.new(0, -900, 0), params)
            if floor and floor.Normal.Y >= 0.65 and floor.Material ~= Enum.Material.Water and floor.Position.Y > workspace.FallenPartsDestroyHeight + 60 and freshExplorePoint(floor.Position) then
                destination = floor.Position + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 1.5, 0)
                exploreAngle = angle + 2.399963
                break
            end
        end
    end
    if not destination then nextExploreAt = now + 2; movementStatus("Exploring paused · no safe destination found"); return end
    exploredCenters[#exploredCenters + 1] = root.Position
    if #exploredCenters > 8 then table.remove(exploredCenters, 1) end
    ensureMovementController(character, root, humanoid, destination)
    positionAlign.Position = destination
    positionAlign.Enabled, orientationAlign.Enabled = true, true
    pivotRoot(root, destination)
    teleportTarget, correctionTarget = nil, nil
    correctionStrikes = 0
    lastTeleportTime, lastTeleportPosition = now, destination
    state.OffsetGraceUntil = now + 1
    state.FollowTarget = hint
    state.Exploring = true
    state.LastExploreDestination = destination
    state.ExploreConfirmAt = now + 0.6
    state.ExploreHops += 1
    state.TeleportsSent += 1
    nextExploreAt = now + 4
    nextAcquisition = now + (hint and 0.25 or 0.75)
    targetMissingSince = now
    state.AttackingTarget = nil
    trackHealth(nil)
    movementStatus("Exploring · moved beyond the previous spawn area")
end

local function updateMovement()
    local now = os.clock()
    if now < nextMovementUpdate then return end
    nextMovementUpdate = now + 0.08
    if state.SafeModePanic or state.AutomationTeleporting or state.TravelBusy or state.MultiSpotOwnsTravel or state.Dodging or now<(state.FarmPauseUntil or 0) then return end
    if state.MultiSpot and state.MultiSpotAnchor and not state.AutoFarm then
        if not state.HoldMultiSpotIdle() then state.FinishMultiSpotArrival() end
        return
    end
    if state.Recovering or not state.AutoFarm then return end
    if not state.Enabled then
        if state.MultiSpot and state.MultiSpotAnchor then
            if not state.HoldMultiSpotIdle() then state.FinishMultiSpotArrival() end
            return
        end
        if state.TravelHold then return end
        stopMovement("Enable the aura to start auto farm"); return
    end
    state.TravelHold=false; state.TravelHoldPosition=nil
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local entity = character and character:FindFirstChild("Entity")
    local health = entity and entity:FindFirstChild("Health")
    local mobs = refreshMobIndex()
    if not root or not humanoid or humanoid.Health <= 0 or (health and health.Value <= 0) or not mobs then
        state.FollowTarget = nil
        stopMovement("Waiting for a living character")
        return
    end
    if root ~= movementRoot and movementRoot then stopMovement(); return end
    if state.Exploring and state.LastExploreDestination and now >= (state.ExploreConfirmAt or 0) then
        if (root.Position - state.LastExploreDestination).Magnitude > 18 then
            state.ExploreFailures = (state.ExploreFailures or 0) + 1
            if state.ExploreFailures >= 2 then state.FarmPauseUntil=os.clock()+1; state.ExploreFailures=0; state.FollowTarget=nil; pauseHold("Reacquiring after a corrected position"); return end
        else state.ExploreFailures = 0 end
        state.LastExploreDestination = nil
    end
    if (state.SkillCastRunning or Skills.usingSkill ~= "none") and not (state.SkillCastRunning and state.SuppressSkillMotion) then
        if positionAlign then positionAlign.Enabled = false end
        if orientationAlign then orientationAlign.Enabled = false end
        state.SkillMovementSuspended = true
        movementStatus("Casting " .. tostring(state.SelectedSkill))
        return
    end
    if state.SkillMovementSuspended then
        state.SkillMovementSuspended = false
        teleportTarget = nil
        state.OffsetGraceUntil = now + 0.5
    end
    if now < state.LagPauseUntil or (state.PingMs and state.PingMs > 500) then pauseHold("Paused in place · waiting for lag"); return end
    if root.Anchored or humanoid.SeatPart then stopMovement("Paused · character cannot move"); return end
    if character:GetAttribute("Disabled") then pauseHold("Paused in place · character disabled"); return end
    if holdPaused then
        holdPaused = false
        teleportTarget = nil
        state.OffsetGraceUntil = now + 0.5
    end
    local targetRoot=validMob(state.FollowTarget,mobs)
    if targetRoot and (targetRoot.Position-root.Position).Magnitude>state.FarmRange+math.abs(state.TeleportOffset)+4 then targetRoot=nil end
    if now>=nextAcquisition then
        nextAcquisition=now+0.15
        local locked=state.FarmTargetLock
        if state.FarmLockArena~=state.MultiSpotAnchor or state.FarmLockProgression~=state.ProgressionBossMob then locked=nil end
        if locked and locked.Parent==mobs then
            local data=getMobData(locked)
            -- Missing streamed data, invulnerability or a rejected offset is
            -- not a confirmed kill. Wait for this enemy instead of retargeting.
            if data and (data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0))then locked=nil end
        else locked=nil end
        if locked then
            local rank=targetPriority.Rank(locked)
            local promoted
            if rank>1 then
                for mob in pairs(trackedMobs)do
                    if targetPriority.Rank(mob)<rank and validMob(mob,mobs)
                        and (not promoted or targetPriority.FarmLess(mob,promoted))then promoted=mob end
                end
            end
            if promoted then locked=promoted;state.FarmTargetLock=promoted end
            state.FollowTarget=locked
            targetRoot=validMob(locked,mobs)
            state.TargetPriority=targetPriority.Rank(locked)
        else
        local preferred=targetRoot and state.FollowTarget or nil
        local best=preferred
        state.TargetScans+=1
        for mob in pairs(trackedMobs) do
            local mobRoot=validMob(mob,mobs)
            if mobRoot and (mobRoot.Position-root.Position).Magnitude<=state.FarmRange then
                if not best or targetPriority.FarmLess(mob,best) then best=mob end
            end
        end
        state.FollowTarget=best
        targetRoot=best and validMob(best,mobs)
        state.TargetPriority=best and targetPriority.Rank(best) or nil
        state.FarmTargetLock=best
        state.FarmLockArena=state.MultiSpotAnchor
        state.FarmLockProgression=state.ProgressionBossMob
        end
    end
    if not targetRoot then
        if state.AccountProgression and state.ProgressionAnchor then
            state.FollowTarget=nil;waveDodge.Idle(state.ProgressionAnchor)
            movementStatus("Account Progression · waiting for the main boss");return
        end
        if state.MultiSpot and state.MultiSpotAnchor then
            state.FollowTarget=nil
            if not state.HoldMultiSpotIdle() then waveDodge.Idle() end
            movementStatus("Multi Spot · waiting for selected arena mobs");return
        end
        state.AutoOffsetTarget,state.AutoOffsetDestination = nil,nil
        activeOffsetMob, offsetSample = nil, nil
        targetMissingSince = targetMissingSince or now
        if now - targetMissingSince > 0.9 then
            waveDodge.Idle()
            movementStatus("No loaded enemy · unlimited detection · idle -20")
        else waveDodge.Idle(); movementStatus("Waiting below the map · 20 studs") end
        return
    end
    state.MultiSpotEmptySince=nil
    targetMissingSince = nil
    state.IdleBelowMap = false
    state.Exploring = false
    state.LastExploreDestination = nil
    if correctionTarget ~= state.FollowTarget then correctionTarget = state.FollowTarget; correctionStrikes = 0 end
    local autoOffset = state.ResolveAutoOffset(state.FollowTarget)
    if not autoOffset or not state.AutoFarm or state.TravelBusy then return end
    local destination = state.AutoOffsetDestination or targetRoot.Position + Vector3.new(0, autoOffset, 0)
    lastSurfaceY = targetRoot.Position.Y + 3
    if destination.Y <= workspace.FallenPartsDestroyHeight + 30 then stopMovement("Paused · destination is too low"); return end
    if teleportTarget == state.FollowTarget and positionAlign and now > (state.OffsetGraceUntil or 0) and now - lastTeleportTime > 0.2 then
        local errorDistance = (root.Position - positionAlign.Position).Magnitude
        local tolerance = math.max(5, math.min(12, targetRoot.AssemblyLinearVelocity.Magnitude * 0.25 + 3))
        if errorDistance > tolerance and now - correctionWindow > 0.35 then
            if now - correctionWindow > 2.5 then correctionStrikes = 0 end
            correctionStrikes += 1
            correctionWindow = now
            state.TeleportCorrections = (state.TeleportCorrections or 0) + 1
            if correctionStrikes >= 3 then
                state.FarmPauseUntil = os.clock()+1
                correctionStrikes = 0
                state.FollowTarget = nil
                pauseHold("Reacquiring after position corrections")
                return
            end
            teleportTarget = nil
        elseif errorDistance < 2 and now - correctionWindow > 2.5 then correctionStrikes = 0 end
    end
    ensureMovementController(character, root, humanoid, destination)
    positionAlign.Position = destination
    positionAlign.Enabled = true
    orientationAlign.Enabled = true
    local changedTarget = teleportTarget ~= state.FollowTarget
    if changedTarget or (now - lastTeleportTime >= state.TeleportInterval and (destination - root.Position).Magnitude > 3.5) then
        pivotRoot(root, destination)
        if changedTarget then state.OffsetGraceUntil = now + 0.35 end
        teleportTarget = state.FollowTarget
        lastTeleportTime, lastTeleportPosition = now, destination
        state.TeleportsSent += 1
        if state.DodgeReturnPending then
            state.LastDodgeReturnDelay=os.clock()-(state.LastDodgeFinishedAt or os.clock())
            state.DodgeReturnPending=false
        end
    end
    if now >= nextMovementStatusUpdate or changedTarget then
        nextMovementStatusUpdate = now + 0.2
        movementStatus(string.format("Auto offset %.1f %s %s", math.abs(state.TeleportOffset),state.OffsetMode=="Above" and "above" or "below",state.FollowTarget.Name))
    end
end

do
    local make=(function()
-- BEGIN BUNDLED AURA TOUCH
-- The supplied source disables native blade touches while aura sends damage.
-- Watch only this player's weapon container and restore original properties.
return function(ctx)
    local api={}
    local originals=setmetatable({}, {__mode="k"})
    local root,connection,enabled
    local nextPoll=0
    local function restore()
        for blade,value in pairs(originals)do pcall(function()blade.CanTouch=value end)end
        table.clear(originals)
    end
    local function apply(blade)
        local tool=blade and blade.Parent
        local weapon=tool and tool.Parent
        if not enabled or not blade or not blade:IsA("BasePart")or blade.Name~="Blade"or not tool or tool.Name~="Tool"
            or not weapon or weapon.Parent~=root or (weapon.Name~="RightWeapon"and weapon.Name~="LeftWeapon")then return end
        pcall(function()
            if originals[blade]==nil then originals[blade]=blade.CanTouch end
            if blade.CanTouch then blade.CanTouch=false end
        end)
    end
    function api.Update(now)
        now=now or os.clock()
        local active=ctx.Active()==true
        if now<nextPoll and active==enabled then return end
        nextPoll=now+.5
        local current=ctx.Items()
        if current~=root then
            if connection then connection:Disconnect();connection=nil end
            restore();root=current
            if root then connection=root.DescendantAdded:Connect(apply)end
        end
        enabled=active
        if not enabled then restore();return end
        if not root then return end
        for _,name in ipairs({"RightWeapon","LeftWeapon"})do
            local weapon=root:FindFirstChild(name)
            local tool=weapon and weapon:FindFirstChild("Tool")
            local blade=tool and tool:FindFirstChild("Blade")
            if blade then apply(blade)end
        end
    end
    function api.Destroy()
        if connection then connection:Disconnect();connection=nil end
        enabled=false;restore();root=nil
    end
    return api
end

-- END BUNDLED AURA TOUCH
    end)()
    state.AuraTouch=make({Active=function()return state.Running and not state.StopEverything and (state.Enabled or state.SkillAura)end,
        Items=function()
            local items=workspace:FindFirstChild("CharacterItems")
            return items and items:FindFirstChild(tostring(player.UserId))
        end})
end

local swingThread
local swingTrack,nextSwingAt,swingIndex=nil,0,0
local function stopSword(force)
    if not force and state.Enabled and state.AutoSwing and not state.StopEverything then return end
    state.SwordSwinging=false
    if swingTrack and swingTrack.IsPlaying then swingTrack:Stop(.08) end
    swingTrack=nil; nextSwingAt=0
end
function state.SetAutoSwing(enabled)
    state.AutoSwing=enabled==true
    if not state.AutoSwing then stopSword(true) end
    requestSave()
end
local function playBurstSwing()
    if not state.Running or not state.Enabled or not state.AutoSwing or state.StopEverything then return end
    local now=os.clock()
    if now<nextSwingAt then return end
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health<=0 then stopSword(true); return end
    if state.WeaponSkills and not state.WeaponSkills.Ready then return end
    local style=state.WeaponSkills and state.WeaponSkills.Style or Combat.CalculateCombatStyle(false)
    local animations=Actions.animations[style]
    if not animations then return end
    swingIndex=swingIndex%3+1
    local track=animations["Swing"..swingIndex] or animations.Swing1
    if not track then return end
    if state.SkillVisuals then state.SkillVisuals.AllowSwingTrack(track) end
    if swingTrack and swingTrack~=track and swingTrack.IsPlaying then swingTrack:Stop(.06) end
    swingTrack=track
    track:Play(.12,1,1)
    nextSwingAt=now+math.max(.65,(track.Length>0 and track.Length or .6)+.1)
    state.SwordSwinging=true; state.SwingStarts+=1
    state.SwingMode="Continuous visuals"
end
local function updateAutoSwing()
    if not state.Enabled or not state.AutoSwing or state.StopEverything then stopSword(true); return end
    playBurstSwing()
end

do
    local create=(function()
-- BEGIN BUNDLED SKILL ACTIVATION
-- Supplied-source activation: activate once and keep the skill name active
-- for its duration. Damage uses the same per-target cooldown as Kill Aura.
return function(ctx)
    local api={}
    local windows={['Sweeping Strike']=1.4,['Downward Smash']=1,['Leaping Slash']=1.8,['Piercing Dash']=1,['Beam Rush']=2.8,
        ['Whirlwind Spin']=1,['Reaper Frenzy']=3.5,['Infinity Slash']=1,['Summon Pistol']=.2,['Meteor Shot']=1,
        ['Everfrost Strike']=1.5,['Cursed Three Fold Slash']=3.3,['Water Blast']=1.2,['Spearitual Strike']=1,
        ['Summon Rifle']=3,['Summon Minigun']=3}
    local retry={}
    local gunProfiles={['Summon Pistol']={FirstHitDelay=0},['Summon Rifle']={FirstHitDelay=0}}
    local owner
    local clock=ctx.Clock or os.clock
    local wait=ctx.Wait or task.wait
    function api.Window(name) return windows[name] or (ctx.ResolveWindow and ctx.ResolveWindow(name)) end
    function api.Profile(name) return gunProfiles[name] end
    function api.CanHandle(name) return api.Window(name)~=nil and clock()>=(retry[name] or 0) end
    function api.Reset() table.clear(retry) end
    function api.Begin(name,definition,entity,root,current,onEmit,aimDirection)
        if not api.CanHandle(name) then return false,"Waiting for a supported activation window" end
        local function valid() return ctx.CanRun() and (not current or current()) end
        if not valid() then return false,"Cast interrupted" end
        if ctx.Skills.usingSkill and ctx.Skills.usingSkill~="none" then return false,"Another skill is active" end
        if ctx.Skills.GetCooldown(name)<0 then return false,"Waiting for cooldown" end
        local stamina=entity:FindFirstChild("Stamina")
        local cost=definition.Cost.Value
        if not stamina or stamina.Value<cost then return false,"Waiting for stamina" end
        local buffs=entity:FindFirstChild("Buffs")
        local reduction=buffs and buffs:FindFirstChild("SkillReduction")
        local cooldown=definition.Cooldown.Value*math.clamp(1-(reduction and reduction.Value or 0),0,1)
        local before=stamina.Value
        local profile=gunProfiles[name]
        local started=clock()
        local lease={Name=name,Started=started,ExpiresAt=started+api.Window(name),
            FirstHitAt=started+(profile and profile.FirstHitDelay or 0),SourceWindow=true,
            HoldWindow=true,RefreshTargets=true,MinimumInterval=.3}
        owner=lease
        ctx.Skills.usingSkill=name
        ctx.Skills.SetCooldown(name,cooldown)
        pcall(ctx.SkillUsed,name,cooldown)
        local direction=typeof(aimDirection)=="Vector3" and aimDirection.Magnitude>.001 and aimDirection.Unit or root.CFrame.LookVector
        lease.Direction=direction
        ctx.Emit(name,{Direction=direction})
        ctx.State.SkillActiveUntil=lease.ExpiresAt
        if onEmit then onEmit(lease) end
        local deadline=clock()+math.clamp(.35+(ctx.State.PingMs or 100)/500,.4,1.2)
        repeat
            if cost<=0 or before-stamina.Value>=math.max(1,cost*.5) then
                return true,nil,lease
            end
            if not stamina.Parent or not root.Parent or not valid() then return false,"Cast interrupted" end
            wait(.02)
        until clock()>=deadline
        retry[name]=clock()+2
        return false,"Skill start not acknowledged; retrying after cooldown"
    end
    function api.Release(name)
        if owner and (not name or name==owner.Name) then
            if ctx.Skills.usingSkill==owner.Name then ctx.Skills.usingSkill="none" end
            owner=nil
        end
    end
    function api.Result(name,damage,requests)
        ctx.State.LastSkillActivationResult={Name=name,Damage=damage,Requests=requests}
    end
    return api
end

-- END BUNDLED SKILL ACTIVATION
    end)()
    state.SkillActivation=create({State=state,Skills=Skills,SkillUsed=GameUI.SkillUsed,
        ResolveWindow=function(name) if AttackStats[name] and Skills.skillHandlers[name] then return 1 end end,
        Emit=function(name,options)
            options.TimeStarted=workspace:GetServerTimeNow()
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and state.SkillVisuals then state.SkillVisuals.MarkGunCast(name,root.Position) end
            ReplicatedStorage.Event:FireServer("Skills",{"UseSkill",name,options})
        end,
        CanRun=function()
            local c=player.Character; local e=c and c:FindFirstChild("Entity"); local hp=e and e:FindFirstChild("Health")
            return state.Running and state.SkillAura and hp and hp.Value>0 and not state.TravelBusy and not state.Dodging and not state.Recovering and not state.ProtectionRetreating
                and not state.StopEverything and not state.SafeModePanic and not state.ModeratorBlocking and not state.AutoTradeBusy
        end,
    })
end
local skillThread,nextSkillCheck=nil,0
function state.WakeSkillAura()nextSkillCheck=0 end
local skillCastSerial=0
function state.CancelSkillAura(reason)
    state.ReserveGunStamina=false
    state.SkillRegistrationTarget=nil
    local active=state.ActiveSkillCast
    if active then
        active.Cancelled=true
        if active.Multi then active.Multi.Cancel(reason or "Cast interrupted") end
        state.SkillActivation.Release(active.Name)
    end
    if state.FinishSkillObservation then state.FinishSkillObservation(); state.FinishSkillObservation=nil end
    if skillThread then pcall(task.cancel,skillThread); skillThread=nil end
    state.ActiveSkillCast=nil
    state.SkillPreparing=false; state.SkillCastRunning=false; state.SkillWantsWindow=false
    state.CombatReadyAt=os.clock()
    nextSkillCheck=0
end
state.CleanupSkillCast=state.CancelSkillAura
do
    local make=(function()
-- BEGIN BUNDLED SKILL DAMAGE BUDGET
-- Reserves expected damage while HP replication catches up; never changes real HP.
return function()
    local api={}
    local samples,order={},{}
    function api.Learn(key,damage,requests,smallestDrop)
        if type(damage)~="number" or damage<=0 or not requests or requests<=0 then return end
        local estimate=damage/requests
        if smallestDrop and smallestDrop>0 then estimate=math.min(estimate,smallestDrop) end
        local old=samples[key]
        if not old then
            if #order>=128 then samples[table.remove(order,1)]=nil end
            order[#order+1]=key
        end
        samples[key]=old and math.min(old,estimate) or estimate
    end
    function api.Estimate(key)return samples[key] or 0 end
    function api.Remaining(item,health,now)
        if not item.ReservationUntil or now>=item.ReservationUntil then
            item.ReservationBase=health;item.ReservedDamage=0
        end
        return math.min(health,(item.ReservationBase or health)-(item.ReservedDamage or 0))
    end
    function api.Reserve(item,health,damage,now,ttl)
        api.Remaining(item,health,now)
        if not damage or damage<=0 then return end
        item.ReservedDamage=(item.ReservedDamage or 0)+damage
        item.ReservationUntil=now+(ttl or .5)
    end
    return api
end

-- END BUNDLED SKILL DAMAGE BUDGET
    end)()
    state.SkillDamageBudget=make()
end
local function updateSkillAura()
    local now=os.clock()
    if now<nextSkillCheck then return end
    nextSkillCheck=now+(state.NetworkPressureLimited and .04 or 1/60)
    state.SkillWantsWindow=false; state.SkillPreparing=false
    state.ReserveGunStamina=false
    state.SkillRegistrationTarget=nil
    if state.SafeModePanic or state.MultiSpotTravelPending or state.MultiSpotOwnsTravel or not state.SkillAura or state.StopEverything then return end
    local weapons=state.WeaponSkills
    if not weapons or not weapons.Ready or not weapons.IsCompatible(state.SelectedSkill) then state.SkillStatus="Waiting for equipped weapon skills"; return end
    if state.ActiveSkillCast or skillThread or Skills.usingSkill~="none" then return end
    if state.MiscReserveStamina or state.MiscCastRunning then state.SkillStatus="Reserving stamina for Misc Skill"; return end
    if state.TravelBusy or state.Dodging or state.Recovering or now<(state.FarmPauseUntil or 0)
        or now<state.LagPauseUntil or now<(state.SkillRetryAt or 0) or (state.PingMs and state.PingMs>500) then return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local entity=character and character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    if not root or not health or health.Value<=0 then return end
    local name=state.SelectedSkill
    local definition=ReplicatedStorage.Database.Skills:FindFirstChild(name)
    if not definition or not GameUI.IsSkillValid(definition) then weapons.Notify("Updating compatible weapon skill"); return end
    local remaining=Skills.GetCooldown(name)
    if remaining<0 then nextSkillCheck=now+math.clamp(-remaining,1/60,.25); return end
    local gunProfile=state.SkillActivation.Profile(name)
    if not gunProfile and not Skills.HasStamina(definition.Cost.Value) then return end
    if not CanRunSkill(player,name) or GameUI.IsMenuOpen() or not state.SkillActivation.CanHandle(name) then return end
    local mobs=refreshMobIndex()
    local target,targetRoot
    local function consider(mob)
        local mobRoot=validMob(mob,mobs)
        if not mobRoot then return end
        local data=getMobData(mob)
        local reach=state.AutoRanges.Range("Skill",data,name)
        if attackDeltaFor(data,root).Magnitude<=reach and (not target or targetPriority.Less(mob,target,root.Position,state.AutoFarm and state.FollowTarget or nil)) then target,targetRoot=mob,mobRoot end
    end
    local primary=state.AutoFarm and state.FollowTarget or nil
    if primary then consider(primary) end
    for mob in pairs(trackedMobs) do if mob~=primary then consider(mob) end end
    if not target then nextSkillCheck=now+(state.NetworkPressureLimited and .15 or .08);return end
    local targetData=getMobData(target)
    if state.ReadOwnDamage(targetData.Health)==nil then
        state.SkillRegistrationTarget=target
        state.SkillStatus="Registering enemy before skill activation"
        return
    end
    if not Skills.HasStamina(definition.Cost.Value) then
        state.ReserveGunStamina=true; state.SkillWantsWindow=true
        state.SkillStatus="Recovering stamina for "..name
        return
    end
    state.SkillWantsWindow=true
    if state.AttackBurstActive then finishAttackBurst("Handing off to ready skill") end
    state.SkillPreparing=true
    if not normalScheduler.Ready(target,now)then return end
    state.SkillPreparing=false; state.SkillCastRunning=true
    skillCastSerial+=1
    local cast={Id=skillCastSerial,Name=name,Version=weapons.Version,Character=character,Cancelled=false}
    state.ActiveSkillCast=cast
    state.AttackingTarget=target; trackHealth(target)
    state.SkillExecution="Source window"
    state.SkillStatus="Casting "..name
    local direction=(targetRoot.Position-root.Position)*Vector3.new(1,0,1)
    if direction.Magnitude>.5 then
        root.CFrame=CFrame.lookAt(root.Position,root.Position+direction.Unit,Vector3.yAxis)
        if orientationAlign then orientationAlign.CFrame=root.CFrame.Rotation end
    end
    local function current()
        return not cast.Cancelled and state.ActiveSkillCast==cast and state.Running and not state.StopEverything
            and state.SkillAura and weapons.Version==cast.Version and weapons.Ready and state.SelectedSkill==name
            and player.Character==character and root.Parent~=nil and health.Value>0
            and not state.TravelBusy and not state.Dodging and os.clock()>=state.LagPauseUntil
            and not state.SafeModePanic and not state.ModeratorBlocking and not state.AutoTradeBusy and not state.Recovering
    end
    skillThread=task.defer(function()
        local burst={Skill=name,Target=target.Name,Requested=0,HealthDrops=0,Before=0,Direct=true,Status="Activating equipped weapon skill"}
        state.LastSkillBurst=burst; state.LastSkillBurstSize=0
        local function observe()
            if not cast.Multi or burst.ObservationFinished then return end
            cast.Multi.Finish()
            state.SkillActivation.Result(name,burst.Damage,burst.TotalRequests)
            if not cast.Cancelled then for _,item in ipairs(burst.Targets) do
                local entry=getMobData(item.Target)
                local settled=not burst.ObservationReadyAt or os.clock()>=burst.ObservationReadyAt
                if entry and state.ReadOwnDamage(item.Health,item.Counter)~=nil and (item.Damage>0 or (settled and entry.Health.Value>0)) then
                    if item.Damage>0 and item.Requested>0 then
                        local key=name..":"..cast.Version
                        state.SkillDamageBudget.Learn(key..":"..item.TargetName,item.Damage,item.Requested,item.MinimumHealthDrop)
                        state.SkillDamageBudget.Learn(key,item.Damage,item.Requested,item.MinimumHealthDrop)
                    end
                    state.AutoRanges.Record("Skill",item.RangeDistance,item.Damage,entry,name)
                end
            end end
            if state.FinishSkillObservation==observe then state.FinishSkillObservation=nil end
        end
        local ok,message=pcall(function()
            if state.FinishSkillObservation then state.FinishSkillObservation() end
            local function startDamage(lease)
            cast.Lease=lease
            burst.DamageSkill=name
            burst.Spacing=math.max(state.SkillBurstInterval,.3,lease.MinimumInterval or 0)
            burst.ActivationAt=lease.Started; burst.FirstHitAt=lease.FirstHitAt; burst.AimDirection=lease.Direction
            cast.Multi=createSkillBurst({State=state,Record=burst,Spacing=burst.Spacing,Contribution=state.ReadOwnDamage,
                SourceWindow=lease.SourceWindow,Pacing=normalScheduler,FirstHitAt=lease.FirstHitAt,
                RefreshTargets=true,ExpiresAt=lease.ExpiresAt,FocusBudget=true,Budget=state.SkillDamageBudget,
                EstimateDamage=function(mob)
                    local key=name..":"..cast.Version
                    local specific=state.SkillDamageBudget.Estimate(key..":"..mob.Name)
                    return specific>0 and specific or state.SkillDamageBudget.Estimate(key)
                end,
                Valid=function(mob)
                    if not current() or not validMob(mob,mobs) then return end
                    local entry=getMobData(mob)
                    if not entry or entry.Health.Value<=0 or (entry.HitLives and entry.HitLives.Value<=0)
                        or os.clock()<(entry.SkipUntil or 0) or entry.Entity:FindFirstChild("Immortal") then return end
                    if attackDeltaFor(entry,root).Magnitude<=state.AutoRanges.Range("Skill",entry,name) then return entry end
                end,
                Targets=function()
                    local list={}
                    for mob in pairs(trackedMobs) do
                        local entry=validMob(mob,mobs)and getMobData(mob)
                        if entry and attackDeltaFor(entry,root).Magnitude<=state.AutoRanges.Range("Skill",entry,name)then list[#list+1]=mob end
                    end
                    table.sort(list,function(a,b) return targetPriority.Less(a,b,root.Position,target) end)
                    return list
                end,
                Distance=function(_,entry) return (entry.Root.Position-root.Position).Magnitude end,
                RangeDistance=function(_,entry) return attackDeltaFor(entry,root).Magnitude end,
                CanRun=function() return current() and os.clock()<lease.ExpiresAt end,
                Send=function(mob,entry)
                    if not current() then return false end
                    if state.MultiSpotEncounter then state.MultiSpotEncounter[mob]=true end
                    Combat.DealDamage(mob,name)
                    state.LastEnemyAttackAt=os.clock();state.LastEnemyAttackTarget=mob
                    state.LastEnemyAttackKind="Skill";state.LastEnemyAttackSkill=name
                    healthHUD.Touch(mob)
                    entry.OffsetRequests=(entry.OffsetRequests or 0)+1
                end,
            })
            if not cast.Multi.Start(target,table.pack()) then burst.Status="Target changed before skill damage"; return end
            end
            local acknowledged,reason,lease=state.SkillActivation.Begin(name,definition,entity,root,current,function(window)
                if current() then startDamage(window) end
            end, state.SkillActivation.Profile(name) and targetRoot.Parent and (targetRoot.Position-root.Position) or nil)
            burst.ActivationAcknowledged=acknowledged
            if not acknowledged or not current() then
                if cast.Multi then cast.Multi.Cancel(reason or "Cast interrupted") end
                burst.Status=reason or "Equipment changed during activation"
                return
            end
            if not cast.Multi then startDamage(lease) end
            if cast.Multi and cast.Multi.Started then
                while current() and not burst.FinishedAt and os.clock()<cast.Multi.Deadline do task.wait(.03) end
                if not current() and not burst.FinishedAt then cast.Multi.Cancel("Equipment or game state changed") end
            end
            if lease.HoldWindow then
                while current() and os.clock()<lease.ExpiresAt do task.wait(.03) end
            end
            if not cast.Multi or not cast.Multi.Started then return end
            state.FinishSkillObservation=observe
            local settle=math.clamp((state.PingMs or 150)/1000+.1,.25,.6)
            burst.ObservationReadyAt=os.clock()+settle
            task.delay(settle,observe)
            state.SkillCasts+=1
        end)
        state.SkillActivation.Release(name)
        if not ok then
            state.LastSkillError=tostring(message); state.SkillRetryAt=os.clock()+1
            if cast.Multi then cast.Multi.Cancel("Skill cast error") end
        end
        if state.ActiveSkillCast==cast then
            state.ActiveSkillCast=nil; state.SkillCastRunning=false; state.SkillWantsWindow=false; skillThread=nil
            state.CombatReadyAt=os.clock()
        end
        if not ok then burst.Status=tostring(message) end
        state.SkillBurstHistory[#state.SkillBurstHistory+1]=burst
        if #state.SkillBurstHistory>8 then table.remove(state.SkillBurstHistory,1) end
        state.OffsetGraceUntil=os.clock()+.5
    end)
end

do
    local profile=ReplicatedStorage.Profiles:FindFirstChild(player.Name)
    local equip=profile and profile:FindFirstChild("Equip")
    local util=require(services.Util)
    local fingerprint
    local createWeaponSkills=(function()
-- BEGIN BUNDLED WEAPON SKILLS
-- Re-resolve equipped item IDs/classes as the supplied source does, rather
-- than carrying a skill's old weapon reference across equipment changes.
return function(ctx)
    local state=ctx.State
    local api={Ready=false,Version=0,Style="",Skills={}}
    local allowed,dirty={},true
    local lastKey,lastCharacter,settleUntil,nextPoll,nextRecheck=nil,nil,0,0,0
    local preferred=type(state.SkillPerWeapon)=="table" and state.SkillPerWeapon or {}
    if state.SkillPerWeaponVersion~=2 then preferred={} end
    state.SkillPerWeapon=preferred
    state.SkillPerWeaponVersion=2
    local defaults={SingleSword="Sweeping Strike",["2HSword"]="Downward Smash",DualWield="Whirlwind Spin",
        Rapier="Piercing Dash",Katana="Leaping Slash",Spear="Beam Rush",Scythe="Reaper Frenzy"}
    function api.Class(value)
        local key=string.lower((string.gsub(tostring(value or ""),"[^%w]","")))
        if key=="1hsword" or key=="singlesword" then return "SingleSword" end
        if key=="2hsword" then return "2HSword" end
        for name in pairs(defaults) do if string.lower(name)==key then return name end end
        return tostring(value or "")
    end
    function api.Notify(reason,now)
        api.Version+=1; api.Ready=false; dirty=true
        settleUntil=(now or os.clock())+.18
        state.SkillWeaponVersion=api.Version
        state.SkillStatus=reason or "Updating equipped weapon skills"
        if ctx.Cancel then ctx.Cancel(reason or "Equipment changed") end
    end
    function api.Choices() return api.Skills end
    function api.IsCompatible(name) return api.Ready and allowed[name]~=nil end
    function api.Select(name)
        if not api.IsCompatible(name) then return false end
        if name~=state.SelectedSkill and ctx.Cancel then ctx.Cancel("Selected skill changed") end
        state.SelectedSkill=name
        preferred[api.Style]=name
        if ctx.Changed then ctx.Changed(name,api.Skills) end
        return true
    end
    function api.Update(now)
        now=now or os.clock()
        if now<nextPoll and not dirty then return end
        nextPoll=now+.25
        local key,character=ctx.Key()
        if key~=lastKey or character~=lastCharacter then
            lastKey,lastCharacter=key,character
            api.Notify("Equipped weapon changed",now)
        end
        if not dirty and now>=nextRecheck then dirty=true; settleUntil=now end
        if not dirty or now<settleUntil then return end
        local snapshot=ctx.Read()
        allowed={}; api.Skills={}
        local previousStyle=api.Style
        api.Style=api.Class(snapshot.Style)
        for _,skill in ipairs(snapshot.Skills) do
            if skill.Allowed then allowed[skill.Name]=skill; api.Skills[#api.Skills+1]=skill.Name end
        end
        table.sort(api.Skills)
        local selected=preferred[api.Style]
        if not allowed[selected] then
            selected=(previousStyle=="" or previousStyle==api.Style) and allowed[state.SelectedSkill] and state.SelectedSkill or nil
        end
        if not selected then selected=allowed[defaults[api.Style]] and defaults[api.Style] or api.Skills[1] end
        if selected~=(state.SelectedSkill~="" and state.SelectedSkill or nil) and ctx.Cancel then ctx.Cancel("Available skill changed") end
        state.SelectedSkill=selected or ""
        state.SkillWeaponStyle=api.Style
        api.Ready=true; dirty=false; nextRecheck=now+2
        if selected and previousStyle=="" then preferred[api.Style]=selected end
        if ctx.Changed then ctx.Changed(state.SelectedSkill,api.Skills) end
    end
    return api
end

-- END BUNDLED WEAPON SKILLS
    end)()
    local function combatStyle()
        local ok,value=pcall(Combat.CalculateCombatStyle,false)
        return ok and value or ""
    end
    local resolver=createWeaponSkills({State=state,
        Key=function()
            local right=equip and equip:FindFirstChild("Right")
            local left=equip and equip:FindFirstChild("Left")
            return tostring(right and right.Value or 0)..":"..tostring(left and left.Value or 0)..":"..tostring(combatStyle()),player.Character
        end,
        Read=function()
            local skills={}
            local exp=profile and profile:FindFirstChild("Stats") and profile.Stats:FindFirstChild("Exp")
            local level=exp and util.LevelFromExp(exp.Value) or 0
            for _,definition in ipairs(ReplicatedStorage.Database.Skills:GetChildren()) do
                if AttackStats[definition.Name] and type(Skills.skillHandlers[definition.Name])=="function" and state.SkillActivation.Window(definition.Name) then
                    local ok,valid=pcall(GameUI.IsSkillValid,definition)
                    local minimum=definition:FindFirstChild("Level")
                    skills[#skills+1]={Name=definition.Name,Allowed=ok and valid==true and (not minimum or minimum.Value<=level)}
                end
            end
            return {Style=combatStyle(),Skills=skills}
        end,
        Cancel=function(reason)
            state.CancelSkillAura(reason)
            state.SkillActivation.Reset()
            stopSword(true)
        end,
        Changed=function(name,choices)
            local nextFingerprint=name.."|"..table.concat(choices,",")
            if fingerprint==nextFingerprint then return end
            fingerprint=nextFingerprint
            skillDropdown.Text=name~="" and name.."  v" or "Select skill"
            refreshSkillChoices()
            state.SkillRetryAt=0
            requestSave()
        end,
    })
    state.WeaponSkills=resolver
    if equip then
        for _,slot in ipairs({"Right","Left"}) do
            local value=equip:FindFirstChild(slot)
            if value then bind(value.Changed,function() resolver.Notify("Equipped "..slot.." weapon changed") end) end
        end
    end
    local owned=profile and profile:FindFirstChild("Skills")
    if owned then
        bind(owned.ChildAdded,function() resolver.Notify("Unlocked skills updated") end)
        bind(owned.ChildRemoved,function() resolver.Notify("Unlocked skills updated") end)
    end
    bind(player.CharacterAdded,function() resolver.Notify("Character respawned") end)
    state.WeaponSkillsDestroy=function() state.CancelSkillAura("Weapon controller closed") end
    resolver.Update()
end

function state.SetEnabled(enabled)
    if state.StopEverything and enabled==true then return false end
    if not state.Running then return end
    state.Enabled = enabled == true
    if state.AuraTouch then state.AuraTouch.Update()end
    if state.Enabled then state.AutoSwing=true end
    if not state.Enabled then finishAttackBurst("Paused"); stopSword(); stopMovement("Aura paused · movement stopped") end
    state.LastError = nil
    consecutiveErrors = 0
    nextAttack = 0
    nextTargetRefresh = 0
    state.Backoff = 1
    noDamageChecks = 0
    table.clear(lastHit)
    table.clear(pendingDamage)
    toggle.Text = state.Enabled and "Kill aura · ON" or "Kill aura · OFF"
    toggle.BackgroundColor3 = state.Enabled and Color3.fromRGB(114, 88, 229) or Color3.fromRGB(45, 48, 63)
    requestSave()
end
function state.SetRadius(radius)
    state.Radius = math.clamp(math.floor(radius), 20, 120)
    nextTargetRefresh = 0
end
local guardHealth, guardConnection, guardLastValue
local nextGuardRefresh = 0
local function updateHealthGuard()
    local now = os.clock()
    if now < nextGuardRefresh then return end
    nextGuardRefresh = now + 0.5
    local character = player.Character
    local entity = character and character:FindFirstChild("Entity")
    local health = entity and entity:FindFirstChild("Health")
    if health == guardHealth then return end
    if guardConnection then guardConnection:Disconnect(); guardConnection = nil end
    guardHealth = health
    guardLastValue = health and health.Value
    if health then
        guardConnection = health:GetPropertyChangedSignal("Value"):Connect(function()
            local value, before = health.Value, guardLastValue
            guardLastValue = value
            local active = state.AutoFarm or state.SkillCastRunning or os.clock() < (state.ProtectionUntil or 0)
                or ((state.Enabled or state.SkillAura) and state.AttackingTarget and state.AttackingTarget.Parent)
            if state.Running and not state.StopEverything and active and before and value < before then
                local event={At=os.clock(),Before=before,After=value,Target=state.FollowTarget and state.FollowTarget.Name or state.AttackingTarget and state.AttackingTarget.Name,Offset=state.TeleportOffset,Mode=state.OffsetMode or "Below",Dodging=state.Dodging}
                local root=character and character:FindFirstChild("HumanoidRootPart")
                event.Position=root and root.Position
                local dodge=state.AtheonDodgeController
                event.DodgeReason=dodge and dodge.LastReason
                event.Anchor=dodge and dodge.Anchor
                event.Planned=waveDodge.LastPosition
                state.LastDamageEvent=event
                state.DamageHistory=state.DamageHistory or {}
                state.DamageHistory[#state.DamageHistory+1]=event
                if #state.DamageHistory>8 then table.remove(state.DamageHistory,1) end
                state.LastIncomingDamageAt=event.At
            end
        end)
    end
end
function state.Destroy(replacing, teleportCleanup)
    if not state.Running then return end
    local preserveSearch = teleportCleanup == true and (state.AutomationTeleporting
        or ((state.SafeMode or state.MultiSpot or state.AccountProgression) and state.ServerTeleportStarted)
        or (state.SoloServerSearch and state.SoloServerSearch.Active and state.SoloServerSearch.Phase=="Teleporting"))
    -- Persist the user's choices BEFORE releasing runtime flags. Closing/reloading
    -- must not silently turn Multi Spot off in the next execution.
    if configReady and not preserveSearch then state.SaveNow() end
    state.Enabled = false
    state.AutoFarm = false
    state.SkillAura = false
    state.Running = false
    if state.WindUI then state.WindUI.Destroy()end
    if state.AntiAfk then state.AntiAfk.Destroy()end
    runtimeOwner.Release()
    if state.SoloServerSearch then state.SoloServerSearch.Destroy(preserveSearch) end
    if state.SafeController and not preserveSearch then state.SafeController.Destroy() end
    if state.MultiSpotController then state.MultiSpotController.Destroy() end
    if state.ProgressionDestroy then state.ProgressionDestroy() end
    if state.PerformanceBoost then state.PerformanceBoost.Destroy() end
    if state.CancelSkillAura then state.CancelSkillAura("Script replaced") end
    if state.WeaponSkillsDestroy then state.WeaponSkillsDestroy() end
    stopSword(true)
    if state.CancelMiscSkill then state.CancelMiscSkill() end
    if state.PlayerTools then state.PlayerTools.Destroy() end
    if state.ModeratorWatch then state.ModeratorWatch.Destroy() end
    if state.UprightController then state.UprightController.Destroy() end
    waveDodge.Destroy()
    if state.SkillVisuals then state.SkillVisuals.Destroy() end
    if state.RestoreWorldVisuals then state.RestoreWorldVisuals() end
    if state.RestoreSkillDamageHook then state.RestoreSkillDamageHook() end
    if state.SkillActivation then state.SkillActivation.Release() end
    if state.FinishSkillObservation then state.FinishSkillObservation() end
    normalScheduler.Destroy()
    if guardConnection then guardConnection:Disconnect(); guardConnection = nil end
    stopSword()
    stopMovement(nil,replacing==true)
    if state.FarmNoclip then state.FarmNoclip.Destroy()end
    if state.AuraTouch then state.AuraTouch.Destroy()end
    healthHUD.Destroy()
    if mobAddedConnection then mobAddedConnection:Disconnect() end
    if mobRemovedConnection then mobRemovedConnection:Disconnect() end
    table.clear(trackedMobs)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
    if gui then gui:Destroy() end
    if env.SB2KillAura == state then env.SB2KillAura = nil end
end
bind(toggle.Activated, function() state.SetEnabled(not state.Enabled) end)
bind(close.Activated, state.Destroy)
bind(gui.Destroying, function() state.Destroy(false, true) end)

local dragging, dragStart, panelStart, dragInput
bind(dragBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragInput = true, input
        dragStart, panelStart = input.Position, panel.AbsolutePosition
    end
end)
bind(UserInputService.InputEnded, function(input)
    if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging then requestSave() end
        dragging = false
    end
end)
bind(UserInputService.InputChanged, function(input)
    if not dragging or not (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then return end
    local delta = input.Position - dragStart
    local bounds = gui.AbsoluteSize
    panel.Position = UDim2.fromOffset(
        math.clamp(panelStart.X + delta.X, 0, math.max(0, bounds.X - panel.AbsoluteSize.X)),
        math.clamp(panelStart.Y + delta.Y, 0, math.max(0, bounds.Y - panel.AbsoluteSize.Y))
    )
end)
bind(UserInputService.InputBegan, function(input, processed)
    if state.TravelHold and not (state.AutoFarm and state.Enabled) and not processed and not UserInputService:GetFocusedTextBox() then
        if input.KeyCode==Enum.KeyCode.W or input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.S or input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Space then stopMovement("Travel hold released") end
    end
    if not processed and input.KeyCode == Enum.KeyCode.RightShift and not UserInputService:GetFocusedTextBox() then
        state.SetUIVisible(state.UIHidden)
    end
end)
bind(RunService.Stepped, function()
    if state.Moving then
        for part in pairs(collisionParts) do if part.Parent and part.CanCollide then part.CanCollide = false end end
    end
end)

do
    local create=(function()
-- BEGIN BUNDLED AUTO RANGE
return function(ctx)
    local state=ctx.State
    local clock=ctx.Clock or os.clock
    local api={Cap=120,Profiles=setmetatable({}, {__mode="k"})}
    local nextUpdate=0
    state.AutoRangeCap=api.Cap
    function api.BodyRange(data)
        local size=data.Root.Size
        return math.min(api.Cap,math.max(size.X,size.Z)*.5+20)
    end
    function api.Delta(data,root)
        local height=(root.Size.Y-data.Root.Size.Y)*.5
        local point=data.Root.Position+Vector3.new(0,height,0)
        local motion=data.Motion
        if motion and motion.Parent==data.Root then
            local velocity=motion:IsA("LinearVelocity") and motion.VectorVelocity
                or motion:IsA("BodyVelocity") and motion.Velocity
            if velocity and velocity.Magnitude>1 then point+=velocity.Unit end
        end
        return point-root.Position
    end
    local function profile(kind,data,skill)
        local entries=api.Profiles[data]
        if not entries then entries={}; api.Profiles[data]=entries end
        local key=kind=="Skill" and "Skill:"..tostring(skill or state.SelectedSkill) or "Kill"
        if state.AutoFarm and state.FarmAbove then key="Above:"..key end
        local value=entries[key]
        if not value or value.Size~=data.Root.Size then
            value={Size=data.Root.Size,Limit=api.BodyRange(data),Samples={},NextProbe=0}
            entries[key]=value
        end
        return value
    end
    function api.Range(kind,data,skill)
        local value=profile(kind,data,skill)
        local now,body=clock(),api.BodyRange(data)
        if value.Limit<body and now>=value.NextProbe then
            if now-(value.LastSample or 0)>12 then value.Limit=body
            elseif value.LastHit and now-value.LastHit<6 then value.Limit=math.min(body,value.Limit+1) end
            value.NextProbe=now+6
        end
        return math.min(body,value.Limit)
    end
    function api.Record(kind,distance,damage,data,skill)
        if not data or (kind~="Kill" and kind~="Skill") or type(distance)~="number"
            or distance~=distance or distance>api.Cap or distance<0 then return end
        local value=profile(kind,data,skill)
        local now=clock()
        value.LastSample=now
        if type(damage)=="number" and damage>0 then value.LastHit=now end
        local samples=value.Samples
        samples[#samples+1]={At=now,Distance=distance,Damage=damage or 0}
        if #samples>12 then table.remove(samples,1) end
        local hits,misses,maxHit,nearestMiss=0,0,0,math.huge
        for i=#samples,1,-1 do
            local sample=samples[i]
            if now-sample.At>12 then table.remove(samples,i)
            elseif sample.Damage>0 then hits+=1; maxHit=math.max(maxHit,sample.Distance)
            else misses+=1; nearestMiss=math.min(nearestMiss,sample.Distance) end
        end
        local limit=api.Range(kind,data,skill)
        if hits>0 then limit=math.min(api.BodyRange(data),math.max(limit,maxHit+1)) end
        -- Close misses can mean cooldown, stamina, or invulnerability. Only
        -- learn a shorter reach from repeated misses at the outer boundary.
        if misses>=2 and hits>0 and nearestMiss>maxHit+2 and nearestMiss>=limit-3 then
            limit=math.min(limit,math.max(20,math.ceil(maxHit+2)))
        elseif hits==0 and misses>=3 and nearestMiss>=limit-3 then
            limit=math.max(20,limit-2)
        end
        if limit~=value.Limit then value.Limit=limit; value.NextProbe=now+6 end
    end
    function api.Update()
        local now=clock()
        if now<nextUpdate then return end
        nextUpdate=now+.5
        local data=ctx.PrimaryData and ctx.PrimaryData()
        for _,kind in ipairs({"Kill","Skill"}) do
            local current=kind=="Kill" and state.Radius or state.SkillRange
            local effective=data and api.Range(kind,data,state.SelectedSkill) or math.clamp(current,20,api.Cap)
            local desired=math.ceil(effective)
            if desired~=current then
                if kind=="Kill" then ctx.SetKill(desired) else ctx.SetSkill(desired) end
            end
            local text=string.format("Auto · %.1f / %d studs",effective,api.Cap)
            if kind=="Kill" then state.KillRangeStatus=text else state.SkillRangeStatus=text end
        end
    end
    return api
end

-- END BUNDLED AUTO RANGE
    end)()
    state.AutoRanges=create({State=state,SetKill=state.SetRadius,SetSkill=state.SetSkillRange,
        PrimaryData=function()
            local mob=state.AutoFarm and state.FollowTarget or state.AttackingTarget
            local data=mob and getMobData(mob)
            return data and data.Health.Value>0 and data or nil
        end,
    })
end
normalScheduler.Bind({
    GetData=function(mob)
        if not validMob(mob,indexedMobFolder) then return end
        local data=getMobData(mob)
        if data and os.clock()>=(data.SkipUntil or 0) then return data end
    end,
    Contribution=state.ReadOwnDamage,
    Radius=attackRadiusFor,
    Delta=attackDeltaFor,
    Damage=function(mob)
        if state.FinishSkillObservation then state.FinishSkillObservation() end
        if not pendingDamage[mob] then
            local data=getMobData(mob)
            local contribution,counter=state.ReadOwnDamage(data.Health)
            pendingDamage[mob]={Health=data.Health,Before=data.Health.Value,Time=os.clock(),Requests=0,
                Distance=attackDeltaFor(data,player.Character.HumanoidRootPart).Magnitude,
                Contribution=contribution,Counter=counter,SkillRequests=state.SkillHitRequests}
        end
        if state.MultiSpotEncounter then state.MultiSpotEncounter[mob]=true end
        Combat.DealDamage(mob,nil)
        state.LastEnemyAttackAt=os.clock();state.LastEnemyAttackTarget=mob;state.LastEnemyAttackKind="Normal"
    end,
    Visual=playBurstSwing,
    Sent=function(mob,data,now)
        local sample=pendingDamage[mob]
        if sample then sample.Requests+=1 end
        data.OffsetRequests=(data.OffsetRequests or 0)+1
        state.LastPulseAt=now
        state.HitsSent+=1
        state.LastTarget=mob.Name
        state.AttackingTarget=mob
        lastHit[mob]=now
        healthHUD.Touch(mob)
        trackHealth(state.AutoFarm and state.FollowTarget or mob)
    end,
})

local function scan()
    if state.Dodging or os.clock()<(state.FarmPauseUntil or 0) then finishAttackBurst("Dodging or repositioning"); stopSword(); return "Special-wave dodge / repositioning" end
    if state.TravelBusy or state.MultiSpotOwnsTravel then finishAttackBurst("Travelling"); stopSword(); return "Travelling to a floor destination" end
    if not state.Enabled and not (state.SkillAura and state.SkillRegistrationTarget)then stopSword(); return "Paused" end
    local now = os.clock()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local entity = character and character:FindFirstChild("Entity")
    local health = entity and entity:FindFirstChild("Health")
    if not root or not humanoid or humanoid.Health <= 0 or (health and health.Value <= 0) then finishAttackBurst("Character unavailable"); stopSword(); return "Waiting for your character" end
    local mobs = refreshMobIndex()
    if not mobs then stopSword(); return "Waiting for mobs" end
    if now >= nextPingCheck then
        nextPingCheck = now + 2
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        state.PingMs = ok and type(ping) == "number" and ping or nil
    end
    if now < state.LagPauseUntil or (state.PingMs and state.PingMs > 500) then stopSword(); return "Paused · waiting for lag to clear" end
    if state.Recovering then stopSword(); return "Returning to ground…" end
    if state.SkillPreparing or state.SkillCastRunning or now<(state.CombatReadyAt or 0) then stopSword(); return "Skill aura · skill hit window" end
    if character:GetAttribute("Disabled") then stopSword(); return "Paused · character disabled" end
    stopSword()
    if swingThread or Actions.IsSwinging() then return "Finishing sword swing" end
    if now >= nextTargetRefresh then
        nextTargetRefresh = now + 0.22
        table.clear(candidates)
        state.NearestKillExcluded=nil
        local function consider(mob)
            if not mob or mob.Parent ~= mobs then return end
            local data = getMobData(mob)
            if data and data.Health.Value > 0 and not data.Entity:FindFirstChild("Immortal") then
                local delta = attackDeltaFor(data,root)
                local radius = attackRadiusFor(mob)
                local distance=delta.Magnitude
                if distance<=radius then candidates[#candidates+1]=mob
                end
            end
        end
        local primary = state.AutoFarm and state.FollowTarget or nil
        if primary then consider(primary) end
        for mob in pairs(trackedMobs) do if mob ~= primary then consider(mob) end end
        table.sort(candidates,function(a,b)
            return targetPriority.Less(a,b,root.Position,primary)
        end)
        if candidatePrimary ~= primary then candidatePrimary = primary; targetCursor = 0 end
    end
    state.Nearby = #candidates
    for mob, sample in pairs(pendingDamage) do
        if now - sample.Time >= 0.7 then
            pendingDamage[mob] = nil
            local credited=state.ReadOwnDamage(sample.Health,sample.Counter)
            local damage=credited~=nil and math.max(0,credited-(sample.Contribution or 0)) or math.max(0,sample.Before-sample.Health.Value)
            local observedData=sample.Health.Parent and mob.Parent==mobs and getMobData(mob)
            local pureNormal=sample.SkillRequests==state.SkillHitRequests
            if state.AutoRanges and observedData and pureNormal and credited~=nil
                and (damage>0 or (sample.Health.Value>0 and math.abs(attackDeltaFor(observedData,root).Magnitude-sample.Distance)<4)) then
                state.AutoRanges.Record("Kill",sample.Distance,damage,observedData)
                if damage>0 and sample.Requests>0 then
                    local perHit=damage/sample.Requests
                    observedData.NormalDamagePerHit=observedData.NormalDamagePerHit and observedData.NormalDamagePerHit*.5+perHit*.5 or perHit
                end
            end
            if sample.Health.Parent and mob.Parent == mobs then
                if damage>0 then
                    local data=getMobData(mob)
                    if data then data.RegisteredDamage=true; data.AttackMisses=0; data.AttackBackoff=math.max(1,(data.AttackBackoff or 1)/2) end
                else
                    local data=getMobData(mob)
                    if data then
                        data.AttackMisses=(data.AttackMisses or 0)+1
                        if data.AttackMisses>=2 then data.AttackBackoff=math.min(4,(data.AttackBackoff or 1)*2); data.AttackMisses=0 end
                    end
                end
            end
        end
    end
    return normalScheduler.Update(now,candidates,root,mobs)
end

local frameTiming=(function()
-- BEGIN BUNDLED FRAME TIMING
-- All deadlines remain wall-clock based. Steady 10 FPS is not a freeze.
return function(state)
    local api={}
    function api.Sample(delta,now)
        if type(delta)~="number" or delta~=delta or delta<=0 or delta==math.huge then return end
        local previous=state.AverageFrameTime or 1/60
        local stalled=delta>math.max(.35,previous*4)
        -- Ignore a single long hitch in the baseline so it cannot poison pacing.
        state.AverageFrameTime=previous+(math.min(delta,.2)-previous)*.08
        if stalled and (state.Enabled or state.SkillAura) then
            state.LagPauseUntil=math.max(state.LagPauseUntil or 0,now+.5)
        end
        return stalled
    end
    return api
end

-- END BUNDLED FRAME TIMING
end)()(state)

state.PerformanceBudget=(function()
-- BEGIN BUNDLED PERFORMANCE BUDGET
return function(state)
    local nextUpdate,pressureUntil=0,0
    local api={}
    function api.Update(now)
        now=now or os.clock()
        if now<nextUpdate then return end
        nextUpdate=now+1
        local pressure=(state.AverageFrameTime or 1/60)>1/45 or (state.PingMs or 0)>300
            or (state.AverageLoopCost or 0)>.002
        if pressure then pressureUntil=now+3 end
        local limited=now<pressureUntil
        state.FrameRequestCap=limited and 2 or 4
        state.MaxRequestsPerSecond=limited and 24 or 48
        state.NetworkPressureLimited=limited
    end
    api.Update()
    return api
end
-- END BUNDLED PERFORMANCE BUDGET
end)()(state)

do
    local make=(function()
-- BEGIN BUNDLED TRADE HOLD
return function(ctx)
    local api={}
    local root,anchor,owned
    function api.Update()
        if ctx.Blocked()then root,anchor,owned=nil,nil,false;return end
        if not ctx.Active()then
            if owned then ctx.Release()end
            root,anchor,owned=nil,nil,false;return
        end
        local current=ctx.Root()
        if current~=root or not owned then
            root=current;anchor=nil;owned=true
            if root then anchor=ctx.Anchor(root)end
            ctx.Pause()
        end
        if root and anchor then ctx.Hold(anchor)end
    end
    return api
end

-- END BUNDLED TRADE HOLD
    end)()
    state.TradeHold=make({
        Active=function()return state.AutoTradeBusy==true end,
        Blocked=function()return state.StopEverything or state.ModeratorBlocking or state.SafeModePanic or state.AutoJoinFriendHolding or state.AutomationTeleporting end,
        Root=function()
            local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
            return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")or nil
        end,
        Anchor=function(root)
            local p=root.Position
            return Vector3.new(p.X,waveDodge.FloorY(p),p.Z)
        end,
        Pause=function()
            state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false
            finishAttackBurst("Trading");stopSword(true)
            if state.CancelSkillAura then state.CancelSkillAura("Trading")end
            if state.CancelMiscSkill then state.CancelMiscSkill()end
            if state.MultiSpotController then state.MultiSpotController.Reset()end
            if state.ProgressionController then state.ProgressionController.Reset()end
            state.FollowTarget=nil
            stopMovement("Trading · holding 20 studs below ground",true)
        end,
        Hold=function(anchor)waveDodge.Idle(anchor)end,
        Release=function()stopMovement("Trade ended · resuming farming",true);nextMovementUpdate=0;nextAcquisition=0 end})
end

local nextPresentationUpdate=0
local function runFrame()
        if state.TradeHold then state.TradeHold.Update()end
        if state.AuraTouch then state.AuraTouch.Update()end
        if state.StopEverything then return end
        if state.ModeratorBlocking then
            if state.PanicToSpawn then state.PanicToSpawn()end
            return
        end
        if state.AutoJoinFriendHolding then
            if state.PanicToSpawn then state.PanicToSpawn()end
            return
        end
        if state.SafeModePanic then
            if state.SafePanicHoldHere then state.PanicInPlace()else state.PanicToSpawn()end
            return
        end
        if state.AutoTradeBusy then return end
        local started = os.clock()
        if state.ArenaFloat then state.ArenaFloat.Update(started) end
        state.PerformanceBudget.Update(started)
        if state.UpdateBestSword then state.UpdateBestSword(started)end
        if state.WeaponSkills then state.WeaponSkills.Update(started) end
        local swingOK,swingError=pcall(updateAutoSwing)
        if not swingOK then state.LastSwingError=tostring(swingError) end
        local dodgeOK,dodgeError=pcall(waveDodge.Update)
        if not dodgeOK then state.LastDodgeError=tostring(dodgeError) end
        updateHealthGuard()
        local updatePresentation=started>=nextPresentationUpdate
        if updatePresentation then
            nextPresentationUpdate=started+math.max(.05,math.min(.15,state.AverageFrameTime or 1/60))
            local healthOK,healthError=pcall(healthHUD.Update)
            if not healthOK then state.LastHealthHUDError=tostring(healthError) end
        end
        if state.AutoRanges then state.AutoRanges.Update() end
        if updatePresentation and state.SkillVisuals then
            local visualOK,visualError=pcall(state.SkillVisuals.Update)
            if not visualOK then state.LastVisualError=tostring(visualError) end
        end
        if started >= nextAreaDiscovery then
            nextAreaDiscovery = started + 5
            pcall(discoverDestinations, true)
        end
        local movementOK, movementError = pcall(updateMovement)
        if not movementOK then
            state.FarmPauseUntil = os.clock() + 1
            state.FollowTarget = nil
            state.LastMovementError = tostring(movementError)
            movementStatus("Paused · movement error")
            warn("[SB2 Auto Farm] " .. tostring(movementError))
        end
        local uprightOK,uprightError=pcall(state.UprightController.Update)
        if not uprightOK then state.LastUprightError=tostring(uprightError) end
        if state.MiscController then
            local miscOK,miscError=pcall(state.MiscController.Update,started)
            if not miscOK then state.LastMiscSkillError=tostring(miscError); state.MiscReserveStamina=false end
        end
        local skillOK, skillError = pcall(updateSkillAura)
        if not skillOK then
            state.SkillRetryAt=os.clock()+1.5
            state.LastSkillError = tostring(skillError)
            state.SkillStatus = "Skill retry · waiting for game state"
            warn("[SB2 Skill Aura] " .. tostring(skillError))
        end
        local ok, message = pcall(scan)
        if not state.Running then return end
        if ok then
            consecutiveErrors = 0
            if not state.LastError then combatStatus = message end
        else
            consecutiveErrors += 1
            state.Backoff = math.min(8, state.Backoff * 2)
            nextAttack = os.clock() + 0.5
            stopSword()
            if consecutiveErrors >= 3 then
                state.FarmPauseUntil = os.clock()+1
                consecutiveErrors = 0
                state.LastError = tostring(message)
                combatStatus = "Recovering combat · auto farm stays enabled"
                warn("[SB2 Kill Aura] " .. tostring(message))
            end
        end
        local now = os.clock()
        state.AverageLoopCost += ((os.clock() - started) - state.AverageLoopCost) * 0.08
end

do
    local accumulator,busy,lastErrorAt=0,false,0
    bind(RunService.Heartbeat,function(delta)
        frameTiming.Sample(delta,os.clock())
        if not state.Running or state.StopEverything or not gui.Parent then return end
        accumulator+=delta
        local period=state.SafeModePanic and .1 or (state.Enabled or state.SkillAura) and 1/60 or (state.AutoDodge and workspace:FindFirstChild("WaveDefenseStuff") and .04 or .1)
        if busy or accumulator+.0005<period then return end
        accumulator=math.min(period,math.max(0,accumulator-period))
        busy=true
        local ok,message=pcall(runFrame)
        busy=false
        if not ok then
            state.LastCoordinatorError=tostring(message)
            state.FarmPauseUntil=os.clock()+.5
            if os.clock()-lastErrorAt>5 then lastErrorAt=os.clock();warn("[SB2 Coordinator] "..tostring(message)) end
        end
    end)
end

state.SetAutoSwing(restore.AutoSwing)
state.SetEnabled(restore.Enabled)
if restore.AutoFarm then state.SetAutoFarm(true); if not restore.Enabled then state.SetEnabled(false) end end
state.SetSkillAura(restore.SkillAura)
configReady = true
state.SaveNow()
do
    local create=(function()
-- BEGIN BUNDLED MODERATOR WATCH
-- Account IDs from the moderator list explicitly supplied by the user.
return function(ctx)
    local ids={
        [12671]=true,
        [4402987]=true,
        [7858636]=true,
        [13444058]=true,
        [24156180]=true,
        [35311411]=true,
        [38559058]=true,
        [45035796]=true,
        [48662268]=true,
        [50879012]=true,
        [51696441]=true,
        [55715138]=true,
        [57436909]=true,
        [59341698]=true,
        [60673083]=true,
        [62240513]=true,
        [66489540]=true,
        [68210875]=true,
        [72480719]=true,
        [75043989]=true,
        [76999375]=true,
        [81113783]=true,
        [90258662]=true,
        [93988508]=true,
        [101291900]=true,
        [102706901]=true,
        [104541778]=true,
        [109105759]=true,
        [111051084]=true,
        [121104177]=true,
        [129806297]=true,
        [151751026]=true,
        [154847513]=true,
        [154876159]=true,
        [161577703]=true,
        [161949719]=true,
        [163733925]=true,
        [167655046]=true,
        [167856414]=true,
        [173116569]=true,
        [184366742]=true,
        [194755784]=true,
        [220726786]=true,
        [225179429]=true,
        [269112100]=true,
        [271388254]=true,
        [309775741]=true,
        [349854657]=true,
        [354326302]=true,
        [357870914]=true,
        [358748060]=true,
        [367879806]=true,
        [371108489]=true,
        [373676463]=true,
        [429690599]=true,
        [434696913]=true,
        [440458342]=true,
        [448343431]=true,
        [454205259]=true,
        [455293249]=true,
        [461121215]=true,
        [478848349]=true,
        [500009807]=true,
        [533787513]=true,
        [542470517]=true,
        [571218846]=true,
        [575623917]=true,
        [630696850]=true,
        [810458354]=true,
        [852819491]=true,
        [874771971]=true,
        [918971121]=true,
        [1033291447]=true,
        [1033291716]=true,
        [1058240421]=true,
        [1099119770]=true,
        [1114937945]=true,
        [1190978597]=true,
        [1266604023]=true,
        [1379309318]=true,
        [1390415574]=true,
        [1416070243]=true,
        [1584345084]=true,
        [1607227678]=true,
        [1648776562]=true,
        [1650372835]=true,
        [1666720713]=true,
        [1728535349]=true,
        [1785469599]=true,
        [1794965093]=true,
        [1801714748]=true,
        [1868318363]=true,
        [1998442044]=true,
        [2034822362]=true,
        [2216826820]=true,
        [2324028828]=true,
        [2462374233]=true,
        [2787915712]=true,
        [360470140]=true,
        [2475151189]=true,
        [3522932153]=true,
        [3772282131]=true,
        [7557087747]=true,
        [5536587740]=true,
        [3931735673]=true,
        [33903799]=true,
        [22026533]=true,
        [417576199]=true,
        [80692318]=true,
        [102583875]=true,
        [492574273]=true,
        [468344010]=true,
        [1560324163]=true,
    }
    local api={Enabled=true,Count=113}
    local stopped,fired=false,false
    local function status(message)
        api.Status=message;ctx.State.ModeratorStatus=message
        if ctx.Notify then pcall(ctx.Notify,message)end
    end
    local function active()
        return not stopped and ctx.State.Running~=false and not ctx.State.StopEverything
    end
    local function check(player)
        if ctx.State.StopEverything or stopped or fired or player.UserId==ctx.Players.LocalPlayer.UserId or not ids[player.UserId] then return end
        fired=true
        ctx.State.ModeratorDetected={Name=player.Name,UserId=player.UserId,At=os.time()}
        ctx.State.ModeratorBlocking=true
        status("Moderator detected · blocking @"..player.Name.." before disconnect")
        if ctx.Pause then pcall(ctx.Pause,player)end
        if ctx.Save then pcall(ctx.Save) end
        task.defer(function()
            if not active()then return end
            local ok,confirmed=pcall(function()
                assert(type(ctx.Block)=="function","Native block handler is unavailable")
                return ctx.Block(player,active)
            end)
            if not active()then return end
            if not ok or confirmed~=true then
                api.Failed=true
                ctx.State.ModeratorBlockError=not ok and tostring(confirmed)or"Roblox did not confirm the moderator block"
                status("Moderator block failed · automation paused · "..ctx.State.ModeratorBlockError)
                return
            end
            ctx.State.ModeratorBlockConfirmed=true;ctx.State.ModeratorBlockError=nil
            status("Moderator blocked · disconnecting")
            if ctx.Save then pcall(ctx.Save)end
            if active()then
                ctx.Kick("Blocked moderator "..player.Name.." ("..player.UserId.."). Disconnected automatically.")
            end
        end)
    end
    local connection=ctx.Players.PlayerAdded:Connect(check)
    for _,player in ipairs(ctx.Players:GetPlayers()) do task.defer(check,player) end
    function api.Destroy() stopped=true; api.Enabled=false; connection:Disconnect() end
    return api
end

-- END BUNDLED MODERATOR WATCH
    end)()
    local makeRejoin=(function()
-- BEGIN BUNDLED MODERATOR REJOIN
-- Armed only by the confirmed moderator-block path, never by arbitrary kicks.
return function(ctx)
    local api={Armed=false,Attempts=0}
    function api.Kick(message)
        if api.Armed then return end
        api.Armed=true
        local active=function()return ctx.State.Running~=false and not ctx.State.StopEverything end
        local ok,err=pcall(ctx.Queue)
        if not ok then ctx.State.ModeratorRejoinError="Resume queue: "..tostring(err)end
        -- Start the worker before Kick: some executors throw when Kick returns.
        ctx.Spawn(function()
            ctx.Sleep(1)
            for attempt=1,3 do
                if not active()or api.Started then return end
                api.Attempts=attempt
                ctx.State.ModeratorRejoinStatus="Rejoining current floor · attempt "..attempt
                local sent,reason=pcall(ctx.Teleport)
                if not sent then ctx.State.ModeratorRejoinError=tostring(reason)end
                ctx.Sleep(8)
            end
            if active()and not api.Started then
                ctx.State.ModeratorRejoinStatus="Automatic rejoin did not start · rejoin manually"
            end
        end)
        ctx.Kick(message)
    end
    function api.MarkStarted()api.Started=true end
    return api
end

-- END BUNDLED MODERATOR REJOIN
    end)()
    local teleportService=game:GetService("TeleportService")
    local rejoin=makeRejoin({State=state,Spawn=task.spawn,Sleep=task.wait,
        Queue=function()
            local queue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
            assert(type(queue)=="function","Executor has no teleport queue")
            queue('loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()')
        end,
        Teleport=function()teleportService:Teleport(game.PlaceId,player)end,
        Kick=function(message)player:Kick(message)end})
    state.ModeratorRejoin=rejoin
    bind(player.OnTeleport,function(phase)
        if phase==Enum.TeleportState.Started or phase==Enum.TeleportState.InProgress then rejoin.MarkStarted()end
    end)
    state.ModeratorWatch=create({State=state,Players=Players,Save=state.SaveNow,
        Pause=function()
            if state.SoloServerSearch and state.SoloServerSearch.Active then pcall(state.SoloServerSearch.Stop,"Moderator detection has priority")end
            state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false;state.AutomationTeleporting=false
            finishAttackBurst("Moderator detected");stopSword(true)
            if state.CancelSkillAura then state.CancelSkillAura("Moderator detected")end
            if state.CancelMiscSkill then state.CancelMiscSkill()end
            stopMovement("Moderator detected · blocking before disconnect",true)
            if state.FarmNoclip then state.FarmNoclip.Update()end
            if state.PanicToSpawn then state.PanicToSpawn()end
        end,
        Block=function(target,active)
            local deadline=os.clock()+8
            while active()and not state.BlockPlayerNative and os.clock()<deadline do task.wait(.04)end
            if not active()then return false end
            assert(state.BlockPlayerNative,"Native block handler did not initialize")
            return state.BlockPlayerNative(target,active)
        end,
        Notify=function(message)
            state.SafeModeStatus=message;state.MultiSpotStatus=message;state.ProgressionStatus=message
            movementStatus(message)
        end,
        Kick=rejoin.Kick})
end
bind(player.OnTeleport, function(teleportState)
    if teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress then state.SaveNow() end
end)

-- Player utilities use the same replicated profile and character paths as the supplied source.
do
    local ui=state.UI
    local tools
    local savedSelection=restore.SelectedPlayerId
    local savedView,savedInventory=restore.ViewingPlayer,restore.ViewingPlayerInventory
    local function message(text)
        if not state.Running then return end
        state.PlayerStatus=text or ""
        ui.PlayerMessage.Text=state.PlayerStatus
        ui.PlayerMessage.Visible=state.PlayerStatus~=""
    end
    local function render()
        if not tools or not state.Running then return end
        local selected=tools.GetSelected()
        ui.PlayerSelector.Text=selected and (selected.DisplayName==selected.Name and "@"..selected.Name or selected.DisplayName.." (@"..selected.Name..")") or "Select player"
        ui.ViewPlayer.Text=tools.Viewing and "View player · ON" or "View player · OFF"
        ui.ViewInventory.Text=tools.InventoryVisible and "View player inventory · ON" or "View player inventory · OFF"
        ui.ViewPlayer.BackgroundColor3=tools.Viewing and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        ui.ViewInventory.BackgroundColor3=tools.InventoryVisible and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        ui.PlayerInventory.Visible=tools.InventoryVisible
        if savedSelection~=state.SelectedPlayerId or savedView~=tools.Viewing or savedInventory~=tools.InventoryVisible then
            savedSelection,savedView,savedInventory=state.SelectedPlayerId,tools.Viewing,tools.InventoryVisible
            requestSave()
        end
    end
    local function refreshPlayers()
        if not tools or not state.Running or state.StopEverything then return end
        for _,child in ipairs(ui.PlayerOptions:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
        local choices=tools.Choices()
        state.PlayerChoices=choices
        for index,entry in ipairs(choices) do
            local text=entry.DisplayName==entry.Name and "@"..entry.Name or entry.DisplayName.." (@"..entry.Name..")"
            local option=uiButton("Player"..entry.UserId,text,index,28,ui.PlayerOptions)
            option.Font=Enum.Font.Gotham; option.TextSize=10
            option.Activated:Connect(function()
                if state.StopEverything then return end
                local ok,reason=tools.Select(entry.UserId)
                ui.PlayerOptions.Visible=false
                message(ok and "" or reason)
            end)
        end
        if #choices==0 then
            create("TextLabel",{Name="Empty",Text="No other players in this server",Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,
                Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.fromRGB(153,161,187)},ui.PlayerOptions)
        end
    end
    local makePlayerTools=(function()
-- BEGIN BUNDLED PLAYER TOOLS
-- Player/character/profile data paths adapted from the supplied source.
return function(ctx)
    local state,players,localPlayer=ctx.State,ctx.Players,ctx.LocalPlayer
    local api={Viewing=false,InventoryVisible=false}
    local connections,inventoryConnections,targetConnection={},{},nil
    local selected,priorSubject,priorType
    local disposed,inventoryQueued=false,false
    local function connect(signal,callback,list)
        local value=signal:Connect(callback)
        table.insert(list or connections,value)
        return value
    end
    local function clearInventoryConnections()
        for _,connection in ipairs(inventoryConnections) do connection:Disconnect() end
        table.clear(inventoryConnections)
    end
    function api.GetSelected() return selected and selected.Parent==players and selected or nil end
    function api.Choices()
        local result={}
        for _,p in ipairs(players:GetPlayers()) do
            if p~=localPlayer then result[#result+1]={UserId=p.UserId,Name=p.Name,DisplayName=p.DisplayName} end
        end
        table.sort(result,function(a,b) return string.lower(a.Name)<string.lower(b.Name) end)
        return result
    end
    local function attachCamera()
        local target=api.GetSelected()
        local character=target and target.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local camera=ctx.Workspace.CurrentCamera
        if api.Viewing and not disposed and not state.StopEverything and humanoid and humanoid.Health>0 and camera then
            camera.CameraType=Enum.CameraType.Custom
            camera.CameraSubject=humanoid
        end
    end
    function api.SetViewing(enabled)
        if enabled and state.StopEverything then return false,"Stop Everything is on" end
        if enabled and not api.GetSelected() then return false,"Select a player first" end
        local camera=ctx.Workspace.CurrentCamera
        local wasViewing=api.Viewing
        if enabled and not api.Viewing and camera then priorSubject,priorType=camera.CameraSubject,camera.CameraType end
        api.Viewing=enabled==true
        state.ViewingPlayer=api.Viewing
        if api.Viewing then attachCamera()
        elseif camera and wasViewing then
            local character=localPlayer.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local subject=humanoid or (priorSubject and priorSubject.Parent and priorSubject)
            if subject then camera.CameraSubject=subject end
            camera.CameraType=priorType or Enum.CameraType.Custom
            priorSubject,priorType=nil,nil
        end
        if ctx.Changed then ctx.Changed() end
        return true
    end
    function api.InventoryRows()
        local target=api.GetSelected()
        local profile=target and ctx.Profiles and ctx.Profiles:FindFirstChild(target.Name)
        local inventory=profile and profile:FindFirstChild("Inventory")
        if not inventory then return {},"Inventory is not loaded for this player" end
        local grouped={}
        for _,item in ipairs(inventory:GetChildren()) do
            local upgrade=item:FindFirstChild("Upgrade")
            local level=upgrade and upgrade:IsA("ValueBase") and tonumber(upgrade.Value) or 0
            local key=item.Name..":"..tostring(level)
            local row=grouped[key]
            if not row then row={Name=item.Name,Upgrade=level,Count=0}; grouped[key]=row end
            row.Count+=1
        end
        local rows={}
        for _,row in pairs(grouped) do rows[#rows+1]=row end
        table.sort(rows,function(a,b) if a.Name~=b.Name then return a.Name<b.Name end; return a.Upgrade<b.Upgrade end)
        return rows,nil,inventory
    end
    function api.RefreshInventory()
        if not api.InventoryVisible or disposed or state.StopEverything then return end
        local rows,message=api.InventoryRows()
        ctx.Inventory(rows,message,api.GetSelected())
    end
    local function queueInventory()
        if inventoryQueued or not api.InventoryVisible or disposed then return end
        inventoryQueued=true
        task.defer(function()
            inventoryQueued=false
            if not disposed then api.RefreshInventory() end
        end)
    end
    local function watchInventory()
        clearInventoryConnections()
        if not api.InventoryVisible then return end
        local _,_,inventory=api.InventoryRows()
        if inventory then
            connect(inventory.ChildAdded,queueInventory,inventoryConnections)
            connect(inventory.ChildRemoved,queueInventory,inventoryConnections)
            connect(inventory.DescendantAdded,queueInventory,inventoryConnections)
            connect(inventory.DescendantRemoving,queueInventory,inventoryConnections)
            for _,item in ipairs(inventory:GetChildren()) do
                connect(item:GetPropertyChangedSignal("Name"),queueInventory,inventoryConnections)
                local upgrade=item:FindFirstChild("Upgrade")
                if upgrade and upgrade:IsA("ValueBase") then connect(upgrade.Changed,queueInventory,inventoryConnections) end
            end
        end
        api.RefreshInventory()
    end
    function api.SetInventoryVisible(enabled)
        if enabled and state.StopEverything then return false,"Stop Everything is on" end
        if enabled and not api.GetSelected() then return false,"Select a player first" end
        api.InventoryVisible=enabled==true
        state.ViewingPlayerInventory=api.InventoryVisible
        watchInventory()
        if ctx.Changed then ctx.Changed() end
        return true
    end
    function api.Select(userId)
        local target=players:GetPlayerByUserId(tonumber(userId) or 0)
        if not target or target==localPlayer then return false,"Player is no longer in this server" end
        if targetConnection then targetConnection:Disconnect(); targetConnection=nil end
        selected=target
        state.SelectedPlayerId=target.UserId
        targetConnection=target.CharacterAdded:Connect(function(character)
            task.defer(function()
                local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",3)
                if humanoid and selected==target and not disposed then attachCamera() end
            end)
        end)
        attachCamera(); watchInventory()
        if ctx.Changed then ctx.Changed() end
        return true
    end
    function api.Teleport()
        if state.StopEverything then return false,"Stop Everything is on" end
        local target=api.GetSelected()
        if not target then return false,"Select a player first" end
        return ctx.Teleport(target)
    end
    connect(players.PlayerAdded,function() if ctx.RosterChanged then ctx.RosterChanged() end end)
    connect(players.PlayerRemoving,function(target)
        if selected and target.UserId==selected.UserId then
            api.SetViewing(false); api.SetInventoryVisible(false)
            if targetConnection then targetConnection:Disconnect(); targetConnection=nil end
            selected=nil; state.SelectedPlayerId=nil
            if ctx.Changed then ctx.Changed() end
        end
        if ctx.RosterChanged then task.defer(function() if not disposed then ctx.RosterChanged() end end) end
    end)
    connect(ctx.Workspace:GetPropertyChangedSignal("CurrentCamera"),attachCamera)
    connect(localPlayer.CharacterAdded,function()
        if api.Viewing then task.defer(attachCamera) end
    end)
    function api.Destroy()
        if disposed then return end
        api.SetViewing(false); api.SetInventoryVisible(false)
        disposed=true
        if targetConnection then targetConnection:Disconnect() end
        clearInventoryConnections()
        for _,connection in ipairs(connections) do connection:Disconnect() end
    end
    return api
end
-- END BUNDLED PLAYER TOOLS
    end)()
    tools=makePlayerTools({State=state,Players=Players,LocalPlayer=player,Workspace=workspace,Profiles=ReplicatedStorage:FindFirstChild("Profiles"),
        Changed=render,RosterChanged=function() if ui.PlayerOptions.Visible then refreshPlayers() end end,
        Inventory=function(rows,reason,target)
            if not state.Running then return end
            state.PlayerInventoryRows=rows;state.PlayerInventoryMessage=reason
            for _,child in ipairs(ui.PlayerInventory:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
            local function row(text,index)
                create("TextLabel",{Name="Item"..index,Text=text,LayoutOrder=index,Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
                    Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,
                    TextColor3=Color3.fromRGB(219,223,238)},ui.PlayerInventory)
            end
            if reason or #rows==0 then row(reason or "No inventory items",1)
            else for index,item in ipairs(rows) do
                row(item.Name..(item.Upgrade>0 and " +"..item.Upgrade or "")..(item.Count>1 and " ×"..item.Count or ""),index)
            end end
            state.ViewedInventoryCount=#rows
        end,
        Teleport=function(target)
            if state.TravelBusy then return false,"Another teleport is still running" end
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local targetRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if not root or not humanoid or humanoid.Health<=0 or not targetRoot or root.Anchored then return false,"Player character is not loaded or ready" end
            state.TravelBusy=true
            ui.PlayerOptions.Visible=false
            task.spawn(function()
                local moved=false
                local ok,reason=pcall(function()
                    local deadline=os.clock()+4
                    repeat task.wait(.05) until (not state.Recovering and not state.SkillCastRunning) or os.clock()>deadline or not state.Running or state.StopEverything
                    if not state.Running or state.StopEverything then return end
                    assert(not state.SkillCastRunning and not state.Recovering,"Wait for the current skill to finish")
                    assert(target.Parent==Players and target.Character and player.Character==character,"Player left or respawned")
                    local otherRoot=target.Character:FindFirstChild("HumanoidRootPart")
                    local otherHumanoid=target.Character:FindFirstChildOfClass("Humanoid")
                    assert(otherRoot and otherHumanoid and otherHumanoid.Health>0,"Target character is unavailable")
                    local destination=otherRoot.Position+Vector3.new(0,5,0)
                    assert(finitePoint(destination) and destination.Y>workspace.FallenPartsDestroyHeight+40,"Target position is too low")
                    stopMovement("Travelling to player",true)
                    ensureMovementController(character,root,humanoid,destination)
                    positionAlign.Position=destination; pivotRoot(root,destination)
                    moved=true
                    lastSurfaceY=otherRoot.Position.Y+3
                    state.TeleportsSent+=1
                    state.LastPlayerTeleport={UserId=target.UserId,Name=target.Name,Requested=destination,Actual=root.Position,At=os.clock()}
                    task.wait(.75)
                    if not state.Running or state.StopEverything then return end
                    assert(root.Parent and (root.Position-destination).Magnitude<18,"The game corrected this teleport")
                    state.TravelHold=not (state.AutoFarm and state.Enabled)
                    state.TravelHoldPosition=state.TravelHold and destination or nil
                end)
                state.TravelBusy=false
                if not state.Running or state.StopEverything then return end
                if not ok then
                    if moved then stopMovement("Player teleport stopped") end
                    message(tostring(reason))
                else message("") end
            end)
            return true
        end,
    })
    state.PlayerTools=tools
    if savedSelection then tools.Select(savedSelection) end
    if restore.ViewingPlayer then tools.SetViewing(true) end
    if restore.ViewingPlayerInventory then tools.SetInventoryVisible(true) end
    render(); refreshPlayers()
    bind(ui.PlayerSelector.Activated,function()
        if state.StopEverything then return end
        if not ui.PlayerOptions.Visible then refreshPlayers() end
        ui.PlayerOptions.Visible=not ui.PlayerOptions.Visible
        if ui.PlayerOptions.Visible then revealOptions(ui.PlayerOptions) end
    end)
    bind(ui.TeleportPlayer.Activated,function() local ok,reason=tools.Teleport(); message(ok and "" or reason) end)
    bind(ui.ViewPlayer.Activated,function() local ok,reason=tools.SetViewing(not tools.Viewing); message(ok and "" or reason) end)
    bind(ui.ViewInventory.Activated,function()
        local ok,reason=tools.SetInventoryVisible(not tools.InventoryVisible)
        message(ok and "" or reason)
        if ok and tools.InventoryVisible then revealOptions(ui.PlayerInventory) end
    end)
end

-- Support skills from the provided source, with native cooldown and stamina checks.
do
    local miscThread
    local catalog={"Cursed Enhancement","Heal","Mending Spirit","Summon Tree"}
    local function definition(name) return ReplicatedStorage.Database.Skills:FindFirstChild(name) end
    local function usable(name)
        local value=definition(name)
        return value and type(Skills.skillHandlers[name])=="function" and GameUI.IsSkillValid(value)==true
    end
    local function refreshMisc()
        local list=state.UI.MiscSkillOptions
        for _,child in ipairs(list:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
        state.MiscSkillChoices={}
        for index,name in ipairs(catalog) do
            if definition(name) and Skills.skillHandlers[name] then
                local allowed=usable(name)
                state.MiscSkillChoices[#state.MiscSkillChoices+1]={Name=name,Usable=allowed}
                local option=uiButton("MiscOption"..index,name..(allowed and "" or " (locked)"),index,28,list)
                option.Font=Enum.Font.Gotham; option.TextSize=11; option.Active=allowed
                option.TextColor3=allowed and Color3.fromRGB(226,229,243) or Color3.fromRGB(117,124,146)
                option.Activated:Connect(function() if allowed then state.SetMiscSkill(name) end end)
            end
        end
    end
    function state.SetMiscSkill(name)
        if not table.find(catalog,name) or not usable(name) then return false end
        state.SelectedMiscSkill=name
        state.MiscReserveStamina=false
        state.UI.MiscSkillDropdown.Text=name.."  v"
        state.UI.MiscSkillOptions.Visible=false
        requestSave()
        return true
    end
    function state.SetMiscSkillEnabled(enabled)
        if enabled and state.StopEverything then return false end
        state.MiscSkillEnabled=enabled==true
        if not enabled then state.MiscReserveStamina=false end
        state.UI.MiscSkillToggle.Text=state.MiscSkillEnabled and "Misc Skill · ON" or "Misc Skill · OFF"
        state.UI.MiscSkillToggle.BackgroundColor3=state.MiscSkillEnabled and Color3.fromRGB(114,88,229) or Color3.fromRGB(38,41,56)
        requestSave()
    end
    function state.CancelMiscSkill()
        if miscThread then pcall(task.cancel,miscThread); miscThread=nil end
        state.MiscCastRunning=false; state.MiscReserveStamina=false
    end
    local makeMisc=(function()
-- BEGIN BUNDLED MISC SKILL
return function(ctx)
    local state=ctx.State
    local api={Names={"Cursed Enhancement","Heal","Mending Spirit","Summon Tree"}}
    local nextCheck,nextAttempt=0,0
    function api.Needed(name,snapshot)
        if name=="Heal" or name=="Mending Spirit" then return snapshot.Health/snapshot.MaxHealth<=.66 end
        if name=="Summon Tree" then return snapshot.Stamina<=66 end
        if name=="Cursed Enhancement" then return snapshot.Attacking==true and not snapshot.BuffActive end
        return false
    end
    function api.Update(now)
        now=now or os.clock()
        if not state.MiscSkillEnabled or state.StopEverything then state.MiscReserveStamina=false; return end
        if state.MiscCastRunning then state.MiscReserveStamina=true; return end
        if now<nextCheck then return end
        nextCheck=now+.2
        local snapshot=ctx.Read(state.SelectedMiscSkill)
        if not snapshot or not snapshot.Usable or snapshot.Health<=0 or snapshot.MaxHealth<=0
            or snapshot.Cooldown<0 or not api.Needed(state.SelectedMiscSkill,snapshot) then
            state.MiscReserveStamina=false; return
        end
        state.MiscReserveStamina=true
        if snapshot.Blocked or snapshot.Busy or snapshot.Stamina<snapshot.Cost or now<nextAttempt then return end
        nextAttempt=now+1
        ctx.Cast(state.SelectedMiscSkill,snapshot)
    end
    return api
end

-- END BUNDLED MISC SKILL
    end)()
    state.MiscController=makeMisc({State=state,
        Read=function(name)
            local value=definition(name)
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local entity=character and character:FindFirstChild("Entity")
            local health=entity and entity:FindFirstChild("Health")
            local stamina=entity and entity:FindFirstChild("Stamina")
            if not value or not root or not health or not stamina then return end
            local maximum=entity:FindFirstChild("MaxHealth")
            local constrained=health:IsA("IntConstrainedValue") or health:IsA("DoubleConstrainedValue")
            local maxHealth=constrained and health.MaxValue or maximum and maximum.Value or math.max(1,health.Value)
            return {Definition=value,Character=character,Entity=entity,Root=root,HealthValue=health,StaminaValue=stamina,
                Health=health.Value,MaxHealth=maxHealth,Stamina=stamina.Value,Cost=value.Cost.Value,
                Cooldown=Skills.GetCooldown(name),Usable=usable(name),BuffActive=name=="Cursed Enhancement" and character:GetAttribute("CursedEnhancement")==true,
                Attacking=state.IsAttackingEnemy(),
                Busy=state.SkillCastRunning or Skills.usingSkill~="none",
                Blocked=state.SafeModePanic or state.TravelBusy or state.Dodging or state.Recovering or state.ProtectionRetreating
                    or os.clock()<state.LagPauseUntil or (state.PingMs and state.PingMs>500)
                    or GameUI.IsMenuOpen() or not CanRunSkill(player,name)}
        end,
        Cast=function(name,snapshot)
            if state.StopEverything or not state.MiscSkillEnabled or state.MiscCastRunning then return false end
            state.MiscCastRunning=true
            miscThread=task.defer(function()
                local ok,message=pcall(function()
                    if state.StopEverything or not state.Running or not state.MiscSkillEnabled or player.Character~=snapshot.Character then return end
                    if name=="Cursed Enhancement" and not state.IsAttackingEnemy() then return end
                    local buffs=snapshot.Entity:FindFirstChild("Buffs")
                    local reduction=buffs and buffs:FindFirstChild("SkillReduction")
                    local cooldown=snapshot.Definition.Cooldown.Value*math.clamp(1-(reduction and reduction.Value or 0),0,1)
                    Skills.SetCooldown(name,cooldown)
                    pcall(GameUI.SkillUsed,name,cooldown)
                    ReplicatedStorage.Event:FireServer("Skills",{"UseSkill",name,{Direction=snapshot.Root.CFrame.LookVector}})
                    state.MiscSkillRequests+=1
                    local record={Name=name,At=os.clock(),Acknowledged=false}
                    state.LastMiscSkillCast=record
                    local deadline=os.clock()+math.clamp((state.PingMs or 100)/1000+.6,.8,1.5)
                    repeat
                        local curse=name=="Cursed Enhancement" and snapshot.Character:GetAttribute("CursedEnhancement")
                        if curse or snapshot.Stamina-snapshot.StaminaValue.Value>=math.max(1,snapshot.Cost*.5) then
                            record.Acknowledged=true
                            state.MiscSkillCasts+=1
                            break
                        end
                        task.wait(.04)
                    until os.clock()>=deadline or state.StopEverything or not state.Running or not snapshot.Root.Parent
                    if not record.Acknowledged and state.Running and not state.StopEverything then state.LastMiscSkillError="Support skill was not acknowledged" end
                end)
                if not ok then state.LastMiscSkillError=tostring(message) end
                state.MiscCastRunning=false; state.MiscReserveStamina=false; miscThread=nil
            end)
            return true
        end,
    })
    if not table.find(catalog,state.SelectedMiscSkill) then state.SelectedMiscSkill="Cursed Enhancement" end
    state.UI.MiscSkillDropdown.Text=state.SelectedMiscSkill.."  v"
    bind(state.UI.MiscSkillToggle.Activated,function() state.SetMiscSkillEnabled(not state.MiscSkillEnabled) end)
    bind(state.UI.MiscSkillDropdown.Activated,function()
        if state.StopEverything then return end
        skillList.Visible=false
        if not state.UI.MiscSkillOptions.Visible then refreshMisc() end
        state.UI.MiscSkillOptions.Visible=not state.UI.MiscSkillOptions.Visible
        if state.UI.MiscSkillOptions.Visible then revealOptions(state.UI.MiscSkillOptions) end
    end)
    refreshMisc()
    state.SetMiscSkillEnabled(restore.MiscSkillEnabled)
end



function state.PanicToSpawn(inPlace)
    local holdHere=inPlace==true
    if state.SafePanicHoldHere~=holdHere then state.SafePanicHerePosition=nil;state.SafePanicHereRoot=nil end
    state.SafePanicHoldHere=holdHere
    local first=not state.SafeModePanic
    state.SafeModePanic=true
    if first then
        state.SafePanicStartedAt=os.clock()
        state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false
        finishAttackBurst("Safe Mode panic");stopSword(true)
        if state.CancelSkillAura then state.CancelSkillAura("Safe Mode panic") end
        if state.CancelMiscSkill then state.CancelMiscSkill() end
        if state.MultiSpotController then state.MultiSpotController.Reset() end
        stopMovement(holdHere and "Safe Mode · holding current position"or "Holding at teleport pad",true)
        state.FollowTarget=nil;state.TravelFocus=nil
    end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return false end
    local position=state.AutomationTeleporting and not state.ModeratorBlocking and state.SafeRejoinAway or nil
    if not position and holdHere then
        if state.SafePanicHereRoot~=root or not state.SafePanicHerePosition then
            state.SafePanicHereRoot=root;state.SafePanicHerePosition=root.Position
        end
        position=state.SafePanicHerePosition
    end
    if not position then
        local pad=state.SafePanicSpawnPart
        if not pad or not pad.Parent then
            local reference=destinations.spawn and destinations.spawn.Position or root.Position
            local bestDistance
            for _,candidate in ipairs(workspace:QueryDescendants("SpawnLocation"))do
                local distance=(candidate.Position-reference).Magnitude
                if not bestDistance or distance<bestDistance then pad,bestDistance=candidate,distance end
            end
            state.SafePanicSpawnPart=pad
        end
        if pad then position=pad.Position+Vector3.new(0,pad.Size.Y/2+humanoid.HipHeight+root.Size.Y/2+.5,0)
        elseif destinations.spawn then position=destinations.spawn.Position+Vector3.new(0,4,0)end
    end
    if not position then return false end
    if root~=movementRoot then stopMovement(nil,true) end
    ensureMovementController(character,root,humanoid,position)
    if positionAlign and positionAlign.Position~=position then positionAlign.Position=position end
    if first or (root.Position-position).Magnitude>3 then pivotRoot(root,position) end
    state.TravelHold=true;state.TravelHoldPosition=position;state.SafePanicPosition=position
    return true
end
function state.PanicInPlace()return state.PanicToSpawn(true)end
function state.EscapeSafeRejoin()
    if not state.SafeRejoinRequested or not state.AutomationTeleporting or state.StopEverything or state.ModeratorBlocking then return false end
    if not state.SafeRejoinAway then
        local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
        local origin=state.SafePanicPosition or (root and root.Position)
        if not origin then return false end
        state.SafeRejoinAway=origin+Vector3.new(10000,0,0)
    end
    return state.PanicToSpawn(state.SafePanicHoldHere==true)
end
function state.ReleaseSafePanic()
    state.SafeRejoinRequested=false;state.SafeRejoinAway=nil;state.SafeRejoinDispatch=nil
    if not state.SafeModePanic then return end
    state.SafeModePanic=false;state.SafePanicPosition=nil;state.SafePanicHoldHere=nil;state.SafePanicHerePosition=nil;state.SafePanicHereRoot=nil
    stopMovement("Safe Mode · server protected",true)
    state.FollowTarget=nil
end

do
    local make=(function()
-- BEGIN BUNDLED SERVER ISOLATION
-- Best-effort public matchmaking. Being alone does not prove a server is new/private.
-- All yielding/account/teleport operations are injected so cancellation can be tested.
return function(ctx)
    local api = {Active=false, Phase="Idle", Status="Ready", JobId=ctx.JobId}
    local generation, soloSince, settleUntil, hopDeadline = 0, nil, 0, nil
    local ticket, blocked, pendingPlayer, busy, retryBlockId
    local sameServerReturn=false
    local function announce(message)
        api.Status = message
        if ctx.Notify then ctx.Notify(api) end
    end
    local function live(token) return api.Active and generation == token end
    local function readable(message)
        local value = tostring(message)
        return string.match(value, ":%d+: (.*)") or value
    end
    local function persist()
        local ok, result = pcall(ctx.Save, ticket)
        if not ok or result ~= true then error("Could not save the search; stopped before rejoining") end
    end
    local function recoverable(message)
        local text=tostring(message or ""):lower()
        return text:find("block dialog did not open",1,true)~=nil
            or text:find("did not confirm the block",1,true)~=nil
            or text:find("block was not confirmed",1,true)~=nil
            or text:find("getblockeduserids",1,true)~=nil
            or text:find("blocked-user list",1,true)~=nil
            or text:find("another native block confirmation",1,true)~=nil
            or text:find("has not been registered",1,true)~=nil
    end
    function api.Stop(message,outcome)
        api.RetryWasTeleporting=api.Phase=="Teleporting"
        api.Retryable=outcome~="Safe"and (api.RetryWasTeleporting or recoverable(message))
        generation = generation + 1
        api.Active, api.Phase = false, "Idle"
        api.Outcome=outcome or "Stopped"
        soloSince, pendingPlayer, hopDeadline = nil, nil, nil
        if ticket then
            ticket.Active = false
            local ok, result = pcall(ctx.Save, ticket)
            if not ok or result ~= true then message = (message or "Stopped") .. " (could not clear resume file)" end
        end
        announce(message or "Stopped; added blocks remain in your Roblox account")
    end
    local function valid(t)
        return type(t) == "table" and t.Version == 1 and t.Active == true
            and t.UserId == ctx.UserId and t.PlaceId == ctx.PlaceId
            and type(t.RunId) == "string" and #t.RunId <= 80
            and type(t.StartedAt) == "number" and t.StartedAt <= ctx.Now()
            and ctx.Now() - t.StartedAt < 900
            and type(t.Hops) == "number" and t.Hops >= 0 and t.Hops <= 12 and t.Hops % 1 == 0
            and type(t.Visited) == "table" and type(t.Added) == "table"
            and type(t.SourceJob) == "string"
            and (t.SameServerReturns==nil or (type(t.SameServerReturns)=="number"and t.SameServerReturns>=0
                and t.SameServerReturns<=3 and t.SameServerReturns%1==0))
    end
    function api.Start(resume)
        if api.Active or busy then return false end
        if resume and not valid(resume) then
            ticket = type(resume) == "table" and resume or nil
            api.Stop("Resume expired, changed floor/account, or did not change server")
            return false
        end
        generation = generation + 1
        retryBlockId=nil;sameServerReturn=false
        local token = generation
        api.Active, api.Phase = true, "Preparing"
        api.Outcome="Searching"
        announce("Checking block access and rejoin support...")
        local ok, message = pcall(function()
            if resume and ctx.RestoreSettings then ctx.RestoreSettings(resume.Features) end
            if resume and (resume.SourceJob==ctx.JobId or resume.Visited[ctx.JobId])then
                ticket=resume;api.Ticket=ticket
                ticket.SameServerReturns=(ticket.SameServerReturns or 0)+1
                assert(ticket.SameServerReturns<=3,"Same-server retry limit reached · matchmaking did not move you")
                sameServerReturn=true
            end
            ctx.Preflight()
            if not live(token) then return end
            blocked = ctx.GetBlocked()
            if type(blocked) ~= "table" then error("Could not read the blocked-user list") end
            if not live(token) then return end
            ticket = resume or {Version=1, Active=true, UserId=ctx.UserId, PlaceId=ctx.PlaceId,
                RunId=ctx.NewId(), StartedAt=ctx.Now(), Hops=0, SourceJob=ctx.JobId, Visited={}, Added={}}
            if not resume and ctx.SnapshotSettings then ticket.Features = ctx.SnapshotSettings() end
            -- GetBlockedUserIds contains only users present in this server.
            -- An absent player disappearing from it is expected after a hop.
            if ticket.Visited[ctx.JobId]and not sameServerReturn then error("Matchmaking returned a visited server; search stopped") end
            api.Ticket = ticket
            persist()
            if not live(token) then return end
            settleUntil, soloSince = ctx.Clock() + (sameServerReturn and math.min(1,.25*(ticket.SameServerReturns-1))or (ctx.SettleSeconds or 8)), nil
            api.Phase = "Waiting"
            announce(sameServerReturn and ("Returned to the same server · retry "..ticket.SameServerReturns.."/3 pending")or "Checking this floor's population...")
        end)
        if not ok and live(token) then api.Stop(readable(message)) end
        return ok and live(token)
    end
    local function hop(token)
        if not live(token) then return end
        -- Queue is guarded by the persisted run ID; stopping makes queued work inert.
        ticket.Hops = ticket.Hops + 1
        ticket.SourceJob = ctx.JobId
        ticket.Visited[ctx.JobId] = true
        if ctx.SnapshotSettings then ticket.Features = ctx.SnapshotSettings() end
        persist()
        if not live(token) then return end
        ctx.Queue(ticket.RunId)
        if not live(token) then return end
        api.Phase, hopDeadline = "Teleporting", ctx.Clock() + 35
        announce("Rejoining this floor (" .. ticket.Hops .. "/12)...")
        ctx.Hop()
    end
    local function step(token)
        if api.Phase == "Preparing" then return end
        if ctx.Now() - ticket.StartedAt >= 900 then api.Stop("15-minute search limit reached"); return end
        if api.Phase == "Teleporting" then
            if ctx.Clock() >= hopDeadline then api.Stop("Rejoin timed out; no further blocks added") end
            return
        end
        local others = {}
        for _,person in ipairs(ctx.GetPlayers()) do
            if not ctx.IsAllowed or not ctx.IsAllowed(person) then others[#others+1]=person end
        end
        if #others == 0 then
            soloSince = soloSince or ctx.Clock()
            if ctx.Clock() - soloSince >= (ctx.SoloSeconds or 8) then
                api.Stop("Protected · only you and whitelisted players", "Safe")
            end
            return
        end
        soloSince = nil
        if ctx.Clock() < settleUntil then return end
        if sameServerReturn then
            if ticket.Hops>=12 then api.Stop("12-hop search limit reached");return end
            local confirmed=ctx.GetBlocked()
            if not live(token)then return end
            for _,person in ipairs(others)do
                if confirmed[person.UserId]then
                    ticket.LastBlockedUserId=person.UserId;hop(token);return
                end
            end
            for _,person in ipairs(others)do
                if person.UserId==ticket.LastBlockedUserId then
                    error("Block was not confirmed after same-server return; no rejoin attempted")
                end
            end
            -- The earlier target left. Any new block still follows the normal
            -- native confirmation path; never add a block merely because we returned.
            sameServerReturn=false
        end
        if api.Phase == "Block settling" then
            if ctx.IsPresent(pendingPlayer) then
                local confirmed = ctx.GetBlocked()
                if not live(token) then return end
                if not confirmed[pendingPlayer.UserId] then error("Block was not confirmed; no rejoin attempted") end
            end
            hop(token)
            return
        end
        if ticket.Hops >= 12 then api.Stop("12-hop search limit reached"); return end
        blocked = ctx.GetBlocked()
        if not live(token) then return end
        local candidates = {}
        for _, target in ipairs(others) do
            if blocked[target.UserId] then
                if ticket.Hops == 0 or retryBlockId==target.UserId then ticket.LastBlockedUserId = target.UserId; hop(token); return end
                error("A blocked player is in the joined server; matchmaking exclusion is not reliable here")
            end
            local friend = ctx.IsFriend(target)
            if not live(token) then return end
            if friend == false then candidates[#candidates + 1] = target end
        end
        if #candidates == 0 then api.Stop("No eligible players to block (friends are skipped)"); return end
        local target = ctx.ChooseTarget and ctx.ChooseTarget(candidates) or candidates[ctx.Random(#candidates)]
        if not ctx.IsPresent(target) then settleUntil = ctx.Clock() + 2; return end
        announce("Blocking @" .. target.Name .. "...")
        retryBlockId=target.UserId
        local success = ctx.Block(target, function() return live(token) end)
        if not live(token) then return end
        if success ~= true then error("Roblox rejected the block; no rejoin attempted") end
        ticket.LastBlockedUserId = target.UserId
        ticket.Added[#ticket.Added + 1] = target.UserId
        persist()
        if not live(token) then return end
        pendingPlayer, api.Phase = target, "Block settling"
        settleUntil = ctx.Clock() + (ctx.BlockSettleSeconds or 3)
        announce("Waiting for the block to register...")
        if ctx.BlockSettleSeconds==0 then
            if ctx.IsPresent(target)then
                local confirmed=ctx.GetBlocked()
                if not live(token)then return end
                assert(confirmed[target.UserId],"Block was not confirmed; no rejoin attempted")
            end
            hop(token)
        end
    end
    function api.Update()
        if not api.Active or busy then return end
        busy = true
        local token = generation
        local ok, message = pcall(step, token)
        busy = false
        if not ok and live(token) then api.Stop(readable(message)) end
    end
    function api.TeleportFailed(message)
        if api.Active and api.Phase == "Teleporting" then api.Stop("Rejoin failed: " .. tostring(message)) end
    end
    function api.Retry()
        if api.Active or busy or not api.Retryable then return false end
        if not ticket then return api.Start()end -- Preflight failed before any block/hop.
        if ctx.Now()-ticket.StartedAt>=900 or ticket.Hops>=12 then
            api.Retryable=false;announce("Search limit reached · toggle Safe Mode OFF/ON to begin a new search");return false
        end
        local wasTeleporting=api.RetryWasTeleporting
        generation=generation+1;local token=generation
        api.Active=true;api.Phase="Preparing";api.Outcome="Searching";busy=true
        local ok,message=pcall(function()
            ctx.Preflight()
            if not live(token)then return end
            blocked=ctx.GetBlocked();assert(type(blocked)=="table","Could not read the blocked-user list")
            if not live(token)then return end
            ticket.Active=true;persist()
            if not live(token)then return end
            if wasTeleporting then
                local outsiders=0
                for _,person in ipairs(ctx.GetPlayers())do
                    if not ctx.IsAllowed or not ctx.IsAllowed(person)then outsiders=outsiders+1 end
                end
                if outsiders>0 then
                    assert(ticket.LastBlockedUserId and blocked[ticket.LastBlockedUserId],"Cannot verify previous block · no rejoin attempted")
                    hop(token);return
                end
            end
            settleUntil=ctx.Clock();soloSince=nil;api.Phase="Waiting"
            announce("Retrying Safe Mode · checking this server")
        end)
        busy=false
        if not ok and live(token)then api.Stop(readable(message))end
        return ok and live(token)
    end
    function api.Destroy(preserveResume)
        if preserveResume then
            generation = generation + 1
            api.Active = false
        else api.Stop("Search stopped") end
    end
    return api
end

-- END BUNDLED SERVER ISOLATION
    end)()
    local makeSafe=(function()
-- BEGIN BUNDLED SAFE MODE
return function(ctx)
    local state,search=ctx.State,ctx.Search
    local api={Seeking=false}
    local started=false
    local retries,retryAt=0,nil
    local clock=ctx.Clock or os.clock
    local function targetFloor()return ctx.TargetFloor and ctx.TargetFloor() or state.SafeFloorId end
    local protectedSince
    function api.AdoptSearch()started=true end
    function api.ObserveProtected()
        if not state.SafeMode or not state.Running or state.StopEverything or state.ModeratorBlocking
            or state.SafeWhitelistResolving or ctx.Travelling()or ctx.CurrentFloor()~=targetFloor()then protectedSince=nil;return end
        for _,person in ipairs(ctx.Players())do if not ctx.Allowed(person)then protectedSince=nil;return end end
        protectedSince=protectedSince or clock()
        if clock()-protectedSince<.6 then return end
        if search.Active then search.Stop("Protected · only you and whitelisted players","Safe")end
        protectedSince=nil;started=false;api.Seeking=false;api.Paused=false;api.PauseReason=nil;retries=0;retryAt=nil
        if ctx.ReleasePanic then ctx.ReleasePanic()end
        ctx.Status("Protected · only you and whitelisted players")
    end
    function api.Update()
        if not state.SafeMode or not state.Running or state.StopEverything or state.ModeratorBlocking then return end
        if state.AccountProgression and state.AutomationTeleporting then api.Seeking=true;return end
        if api.Paused then
            local protected=ctx.CurrentFloor()==targetFloor()
            for _,person in ipairs(ctx.Players()) do if not ctx.Allowed(person) then protected=false;break end end
            if protected then api.Paused=false;api.PauseReason=nil;retries=0;retryAt=nil
            else
                api.Seeking=true;if ctx.Panic then ctx.Panic() end
                if search.Retryable and type(search.Retry)=="function"and retries<3 then
                    retryAt=retryAt or clock()+math.min(8,2^(retries+1))
                    if clock()>=retryAt then
                        retries=retries+1;retryAt=nil
                        api.Paused=false;started=search.Retry()==true
                        if not started then api.Pause(search.Status)end
                        return
                    end
                    ctx.Status("Safe Mode retry "..(retries+1).."/3 in "..math.max(0,math.ceil(retryAt-clock())).."s · "..tostring(api.PauseReason))
                else ctx.Status("Holding position · "..tostring(api.PauseReason)..(retries>=3 and " · retries exhausted"or ""))end
                return
            end
        end
        if state.SafeWhitelistResolving then
            api.Seeking=true
            for _,person in ipairs(ctx.Players()) do
                if not ctx.Allowed(person) then if ctx.Panic then ctx.Panic() end;break end
            end
            ctx.Status("Checking whitelist entries...");return
        end
        if ctx.CurrentFloor()~=targetFloor() then
            api.Seeking=true
            if ctx.Panic then ctx.Panic() end
            if not ctx.Travelling() then ctx.ChangeFloor(targetFloor()) end
            return
        end
        if search.Active then
            started=true;api.Seeking=true
            if ctx.Panic then ctx.Panic() end
            search.Update();return
        end
        if started and search.Outcome~="Safe" then
            started=false;api.Pause(search.Status);ctx.Save();return
        end
        started=false
        local outsiders={}
        for _,person in ipairs(ctx.Players()) do
            if not ctx.Allowed(person) then outsiders[#outsiders+1]=person end
        end
        if #outsiders==0 then
            api.Seeking=false
            if ctx.ReleasePanic then ctx.ReleasePanic() end
            ctx.Status("Protected · only you and whitelisted players")
            return
        end
        api.Seeking=true
        if ctx.Panic then ctx.Panic() end
        started=search.Start()==true
        if not started then api.Pause(search.Status);ctx.Save()
        else search.Update()end
    end
    function api.Pause(reason)
        api.Paused=true;api.PauseReason=reason;api.Seeking=true;retryAt=nil
        if ctx.Panic then ctx.Panic() end
        ctx.Status("Holding position · "..tostring(reason))
    end
    function api.Joined(person)
        if state.SafeMode and not ctx.Allowed(person) then
            state.SafePendingUserId=person.UserId
            if ctx.Panic then ctx.Panic() end
        end
    end
    function api.Reset()
        protectedSince=nil;started=false;api.Seeking=false;api.Paused=false;api.PauseReason=nil;retries=0;retryAt=nil
        if search.Active then search.Stop("Safe Mode settings changed") end
        if not state.SafeMode and ctx.ReleasePanic then ctx.ReleasePanic() end
    end
    function api.Destroy() api.Reset() end
    return api
end

-- END BUNDLED SAFE MODE
    end)()
    local makeMulti=(function()
-- BEGIN BUNDLED MULTI SPOT
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Current=nil,Visits=0}
    local clearedSince
    local retryAt,retries=0,0
    local function travelFailed(now,message)
        ctx.Release()
        retries=retries+1
        api.LastError=message
        api.Phase=retries>=3 and "Paused" or "Retrying travel"
        retryAt=now+math.min(8,2*retries)
        ctx.Status(retries>=3 and ("Multi Spot paused · "..message.." · toggle off/on to retry")
            or ("Retrying arena travel · "..message))
        -- Runtime failures must never overwrite the user's saved ON preference.
        ctx.Save()
    end
    local function choices()
        local result={}
        for _,spot in ipairs(ctx.Spots()) do
            if spot.PlaceId==ctx.CurrentFloor() and state.MultiSpotSelected[spot.Id]
                and (not state.SafeMode or spot.PlaceId==state.SafeFloorId) then
                result[#result+1]=spot
            end
        end
        return result
    end
    function api.Reset()
        api.Phase="Idle";api.Current=nil;clearedSince=nil;api.EncounterSeen=false
        retryAt,retries=0,0;api.LastError=nil;api.MoveDeadline=nil;ctx.Release()
    end
    function api.Update(now)
        if not state.MultiSpot or not state.Running then return end
        if api.Phase=="Paused" then return end
        if api.Phase=="Retrying travel" then
            if now<retryAt then return end
            api.Phase="Idle";api.Current=nil
        end
        -- Observe an in-progress trip even if casting or TravelBusy prevents a new one.
        if api.Phase=="Moving" then
            if ctx.Moving() then
                if now>(api.MoveDeadline or math.huge) then travelFailed(now,"Travel timed out") end
                return
            end
            if not ctx.Arrived(api.Current) then travelFailed(now,"Arrival was not confirmed");return end
            api.MoveDeadline=nil;retries=0;api.LastError=nil
            local alive,seen=ctx.Encounter(api.Current)
            api.Phase="Waiting for spawn";api.EncounterSeen=api.EncounterSeen or seen or alive>0;clearedSince=nil;api.Visits=api.Visits+1
            ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name)
        end
        if not ctx.CanMove() then return end
        local selected=choices()
        if #selected==0 then ctx.Status(state.SafeMode and "Select arenas on the Safe Mode floor" or "Select at least one arena");return end
        if api.Current then
            local alive,seen=ctx.Encounter(api.Current)
            api.Remaining=alive
            if seen or alive>0 then api.EncounterSeen=true end
            if alive>0 then
                clearedSince=nil;api.Phase="Clearing arena"
                ctx.Status(api.Current.Name.." · "..alive.." mobs remaining")
                return
            end
            if not api.EncounterSeen then
                api.Phase="Waiting for spawn"
                ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name)
                return
            end
            clearedSince=clearedSince or now
            if now-clearedSince<.6 then return end
            api.Phase="Cleared";ctx.Status("Arena cleared · moving to next spot")
            api.ClearedRounds=(api.ClearedRounds or 0)+1
            state.MultiSpotPending=nil
            if #selected==1 and selected[1].Id==api.Current.Id then
                state.MultiSpotPending=api.Current.Id
                api.EncounterSeen=false;clearedSince=nil;api.Phase="Waiting for spawn"
                if ctx.ClearEncounter then ctx.ClearEncounter() end
                ctx.Status("Arena cleared · waiting for the next spawn")
                return
            end
        end
        local spot
        if state.MultiSpotPending then
            for _,item in ipairs(selected) do if item.Id==state.MultiSpotPending then spot=item;break end end
        end
        if not spot then
            local index=0
            for i,item in ipairs(selected) do if item.Id==state.MultiSpotCursor then index=i;break end end
            spot=selected[index%#selected+1]
        end
        if ctx.CurrentFloor()~=spot.PlaceId then
            state.MultiSpotPending=spot.Id
            ctx.Status("Travelling to "..spot.Floor.Name)
            ctx.ChangeFloor(spot.PlaceId);return
        end
        ctx.Release()
        api.Current=spot
        api.EncounterSeen=false
        state.MultiSpotCursor=spot.Id;state.MultiSpotPending=spot.Id
        -- Keep the same destination across stream/retry failures.
        api.Phase="Moving";api.MoveDeadline=now+15;ctx.Save()
        local ok,message=ctx.Go(spot)
        if not ok then travelFailed(now,message or "Arena is unavailable") end
    end
    function api.Pause(message)
        ctx.Release();api.Phase="Paused";api.LastError=tostring(message)
        ctx.Status("Multi Spot paused · "..api.LastError.." · toggle off/on to retry")
    end
    function api.Destroy() api.Reset() end
    return api
end

-- END BUNDLED MULTI SPOT
    end)()
    local makeCatalog=(function()
-- BEGIN BUNDLED FLOOR CATALOG
-- Source-provided arena coordinates; current-floor discoveries may refine them.
return function(ctx)
    local source = {
        [542351431] = { -- floor 1
            Boss = Vector3.new(-2977.1355, -229.28125, 1221.8555),
            Portal = Vector3.new(-2940.8562, -207.597794, 982.687012),
            Miniboss = Vector3.new(139.343933, 225.040985, -132.926147)
        },
        [548231754] = { -- floor 2
            Boss = Vector3.new(-2013.0431, 445.54346, -8953.9512),
            Portal = Vector3.new(-2181.09204, 466.482727, -8955.31055)
        },
        [555980327] = { -- floor 3
            Boss = Vector3.new(448.331146, 4279.3374, -385.050385),
            Portal = Vector3.new(-381.196564, 4184.99902, -327.238312)
        },
        [572487908] = { -- floor 4
            Boss = Vector3.new(-2318.12964, 2280.41992, -514.067749),
            Portal = Vector3.new(-2319.54028, 2091.30078, -106.37648),
            Miniboss = Vector3.new(-1361.35596, 5173.21387, -390.738007)
        },
        [580239979] = { -- floor 5
            Boss = Vector3.new(2189.17822, 1308.125, -121.071182),
            Portal = Vector3.new(2188.29614, 1255.37036, -407.864594)
        },
        [582198062] = { -- floor 7
            Boss = Vector3.new(3347.78955, 800.043884, -804.310425),
            Portal = Vector3.new(3336.35645, 747.824036, -614.307983)
        },
        [548878321] = { -- floor 8
            Boss = Vector3.new(1848.35413, 4110.43945, 7723.38623),
            Portal = Vector3.new(1665.46252, 4094.20312, 7722.29443),
            Miniboss = Vector3.new(-811.7854, 3179.59814, -949.255676)
        },
        [573267292] = { -- floor 9
            Boss = Vector3.new(12241.4648, 461.776215, -3655.09009),
            Portal = Vector3.new(12357.0059, 439.948914, -3470.23218),
            Miniboss = Vector3.new(1928, 2889, -11349),
            ['Second miniboss'] = Vector3.new(1973.94238, 2986.00952, -4486.8125)
        },
        [2659143505] = { -- floor 10
            Boss = Vector3.new(45.494194, 1003.77246, 25432.9902),
            Portal = Vector3.new(110.383698, 940.75531, 24890.9922),
            Miniboss = Vector3.new(-894.185791, 467.646698, 6505.85254)
        },
        [5287433115] = { -- floor 11
            Boss = Vector3.new(4916.49414, 2312.97021, 7762.28955),
            Portal = Vector3.new(5224.18994, 2602.94019, 6438.44678),
            Miniboss = Vector3.new(4801.12695, 1646.30347, 2083.19116),
            ['Za, the Eldest'] = Vector3.new(4001.55908, 421.515015, -3794.19727),
            ['Wa, the Curious'] = Vector3.new(4821.5874, 3226.32788, 5868.81787),
            ['Duality Reaper  '] = Vector3.new(4763.06934, 501.713593, -4344.83838),
            ['Neon chest       '] = Vector3.new(5204.35449, 2294.14502, 5778.00195)
        },
        [134019705603409] = { -- Atlantis: native client arena discovery
            Leviathan = Vector3.new(15.89453125, 1320.01953125, -797.10546875)
        },
        [13965775911] = { -- Atheon / floor 13 (user-provided arena)
            ['Atheon arena'] = Vector3.new(840, 798, 336)
        },
        [6144637080] = { -- floor 12
            ['Suspended Unborn'] = Vector3.new(-5324.62305, 427.934784, 3754.23682),
            ['Limor the Devourer'] = Vector3.new(-1093.02625, -169.141785, 7769.1875),
            ['Radioactive Experiment'] = Vector3.new(-4643.86816, 425.090515, 3782.8252)
        }
    }
    local numbers = {[542351431]=1,[548231754]=2,[555980327]=3,[572487908]=4,[580239979]=5,[566212942]=6,
        [582198062]=7,[548878321]=8,[573267292]=9,[2659143505]=10,[5287433115]=11,[6144637080]=12,[13965775911]=13,[134019705603409]=14}
    local catalog={Floors={},FloorById={},Spots={},SpotById={},Aliases={}}
    -- Identities and positions verified in the new-account live progression test.
    local mainBossNames={
        [542351431]={["Rahjin the Thief King"]=true},
        [548231754]={["Borik the BeeKeeper"]=true},
    }
    local function accepts(spot,name)
        if not spot.EncounterNames then return true end
        local cleaned=tostring(name or ""):lower():gsub("[^%w]","")
        for expected in pairs(spot.EncounterNames)do
            if expected:lower():gsub("[^%w]","")==cleaned then return true end
        end
        return false
    end
    for _,floor in ipairs(ctx.Floors) do
        local n=numbers[floor.PlaceId]
        if n then
            local item={Id=floor.PlaceId,Number=n,Name=floor.Name,Label=floor.PlaceId==134019705603409 and floor.Name or ("F"..n.." · "..floor.Name),Unlocked=ctx.Unlocked(floor)}
            catalog.Floors[#catalog.Floors+1]=item;catalog.FloorById[item.Id]=item
        end
    end
    table.sort(catalog.Floors,function(a,b)return a.Number<b.Number end)
    local extraKinds={Leviathan='Boss',['Suspended Unborn']='Arena',['Limor the Devourer']='Arena',['Radioactive Experiment']='Arena',
        ['Za, the Eldest']='Mini boss',['Wa, the Curious']='Arena',['Duality Reaper']='Mini boss',['Atheon arena']='Arena'}
    for placeId,areas in pairs(source) do
        local floor=catalog.FloorById[placeId]
        if floor then for original,point in pairs(areas) do
            local key=original:match('^%s*(.-)%s*$')
            local kind=key=='Boss' and 'Boss' or (key=='Miniboss' or key=='Second miniboss') and 'Mini boss' or extraKinds[key]
            if kind then
                local name=key=='Boss' and 'Boss arena' or key=='Miniboss' and 'Mini-boss arena' or key
                local spot={Id=tostring(placeId)..'/'..key,PlaceId=placeId,Name=name,Kind=kind,Position=point,
                    DestinationId='source:'..key,Floor=floor,Label=floor.Label..' · '..name,
                    MainBoss=key=='Boss',PositionLocked=(placeId==573267292 and key=='Miniboss') or placeId==13965775911,
                    EncounterNames=placeId==13965775911 and {Atheon=true,['Corrupted Atheon']=true}
                        or (placeId==134019705603409 and key=='Leviathan' and {Leviathan=true})
                        or (key=='Boss' and mainBossNames[placeId]) or nil}
                catalog.Spots[#catalog.Spots+1]=spot;catalog.SpotById[spot.Id]=spot
            end
        end end
    end
    function catalog.AddCurrent(areas,placeId)
        local floor=catalog.FloorById[placeId];if not floor then return end
        for _,kind in ipairs({'Boss','Mini boss'}) do
            local generic=catalog.SpotById[tostring(placeId)..'/'..(kind=='Boss' and 'Boss' or 'Miniboss')]
            -- Keep the user's explicit F9 first-arena location even if only the second mini-boss is loaded.
            if generic and not generic.PositionLocked then
                local closest,distance
                for id,area in pairs(areas or {}) do
                    if id:sub(1,4)=='mob:' and area.Kind==kind and accepts(generic,id:sub(5)) then
                        local d=(area.Position-generic.Position).Magnitude
                        if not distance or d<distance then closest,distance=area,d end
                    end
                end
                if closest then generic.Position=closest.Position;generic.DestinationId=closest.Id;generic.SourceRefined=true end
            end
        end
        for id,area in pairs(areas or {}) do
            if area.Kind=='Boss' or area.Kind=='Mini boss' then
                local key=tostring(placeId)..'/'..id
                if id:sub(1,7)~='source:' then
                    local name=id:sub(1,4)=='mob:' and id:sub(5) or area.Name
                    local primary
                    if placeId==13965775911 and (name=='Atheon' or name=='Corrupted Atheon') then
                        primary=catalog.SpotById[tostring(placeId)..'/Atheon arena']
                    end
                    for _,spot in ipairs(catalog.Spots) do
                        if not primary and spot.PlaceId==placeId and spot.Name:lower()==name:lower() then primary=spot;break end
                    end
                    if primary then
                        if not primary.PositionLocked then
                            primary.Position=area.Position;primary.DestinationId=id;primary.Kind=area.Kind;primary.SourceRefined=true
                        end
                    else
                        local nearest
                        for _,spot in ipairs(catalog.Spots) do
                            if spot.PlaceId==placeId and accepts(spot,name)
                                and (spot.Kind==area.Kind or (spot.PositionLocked and spot.Kind=='Arena')) then
                                local distance=(spot.Position-area.Position).Magnitude
                                if distance<=220 and (not nearest or distance<nearest) then primary,nearest=spot,distance end
                            end
                        end
                    end
                    if primary then
                        catalog.Aliases[key]=primary.Id;catalog.SpotById[key]=primary
                    else
                        local spot={Id=key,PlaceId=placeId,Name=name,Kind=area.Kind,Position=area.Position,
                            DestinationId=id,Floor=floor,Label=floor.Label..' · '..name}
                        catalog.Spots[#catalog.Spots+1]=spot;catalog.SpotById[key]=spot
                    end
                end
            end
        end
    end
    function catalog.NormalizeSelection(selected)
        local result={}
        for id,on in pairs(selected or {}) do
            if on then result[catalog.Aliases[id] or id]=true end
        end
        return result
    end
    function catalog.Sort()
        table.sort(catalog.Spots,function(a,b)
            if a.Floor.Number~=b.Floor.Number then return a.Floor.Number<b.Floor.Number end
            if a.Kind~=b.Kind then
                local ranks={Boss=1,['Mini boss']=2,Arena=3}
                return (ranks[a.Kind] or 4)<(ranks[b.Kind] or 4)
            end
            if a.Name~=b.Name then return a.Name<b.Name end
            return a.Id<b.Id
        end)
    end
    catalog.Sort()
    return catalog
end

-- END BUNDLED FLOOR CATALOG
    end)()
    local makeUI=(function()
-- BEGIN BUNDLED AUTOMATION UI
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

-- END BUNDLED AUTOMATION UI
    end)()
    local attach=(function()
-- BEGIN BUNDLED SERVER ISOLATION CLIENT
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
    local queue, savedSource,validatedSource
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
    local definitions=require(game.ReplicatedStorage.Database.Locations).floors
    local nativeFloors={}
    for _,floor in ipairs(definitions)do nativeFloors[floor.PlaceId]=floor end
    local function floorUnlocked(floor)
        local profile=game.ReplicatedStorage.Profiles:FindFirstChild(player.Name)
        local locations=profile and profile:FindFirstChild("Locations")
        return floor.PlaceId==game.PlaceId or floor.Unlocked==true
            or (locations and locations:FindFirstChild(tostring(floor.PlaceId)))~=nil
    end
    local catalog=ctx.MakeCatalog({Floors=definitions,Unlocked=floorUnlocked})
    catalog.AddCurrent(state.FloorDestinations,game.PlaceId);catalog.Sort()
    state.MultiSpotSelected=catalog.NormalizeSelection(state.MultiSpotSelected)
    state.MultiSpotCursor=catalog.Aliases[state.MultiSpotCursor] or state.MultiSpotCursor
    state.MultiSpotPending=catalog.Aliases[state.MultiSpotPending] or state.MultiSpotPending
    state.AutomationCatalog=catalog
    function state.IsAutomationFloorUnlocked(id)
        id=tonumber(id)
        local floor=catalog.FloorById[id]
        if not floor or not nativeFloors[id] then return false end
        local unlocked=floorUnlocked(nativeFloors[id])
        if floor.Unlocked~=unlocked then
            floor.Unlocked=unlocked
            state.AutomationFloorUnlockVersion=(state.AutomationFloorUnlockVersion or 0)+1
        end
        return floor.Unlocked
    end
    local function refresh() if ui then ui.Refresh() end end
    state.RefreshAutomationUI=refresh
    local function refreshUnlocks()
        for _,floor in ipairs(catalog.Floors)do state.IsAutomationFloorUnlocked(floor.Id)end
        refresh()
    end
    local profile=game.ReplicatedStorage.Profiles:FindFirstChild(player.Name)
    local locations=profile and profile:FindFirstChild("Locations")
    if locations then
        ctx.Bind(locations.ChildAdded,refreshUnlocks)
        ctx.Bind(locations.ChildRemoved,refreshUnlocks)
    end
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
        if state.StorageBootstrap then local ready,reason=state.StorageBootstrap.Ensure(true);assert(ready,reason)end
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
        if savedSource~=validatedSource then
            assert(loadstring(savedSource), "The saved script does not compile")
            validatedSource=savedSource
        end
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
            Blocked=function(target)return nativeBlockedEvents[target.UserId]==true or getBlocked()[target.UserId]==true end,
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
        if queuedToken and queuedToken==state.AutomationRunId then return end
        queuePreflight()
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
    local function clearRejoinAway()
        state.SafeRejoinRequested=false;state.SafeRejoinAway=nil;state.SafeRejoinDispatch=nil;state.ServerTeleportStarted=false
    end
    local function escapeAfterRejoin()
        if not state.SafeRejoinAway and state.SafeRejoinRequested and state.AutomationTeleporting and state.Running and not state.StopEverything and not state.ModeratorBlocking then
            if state.EscapeSafeRejoin then state.EscapeSafeRejoin()end
        end
    end
    local function fail(message)
        clearRejoinAway()
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
        SettleSeconds=0,SoloSeconds=.3,BlockSettleSeconds=0,
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
            state.SafeRejoinRequested=true
            local dispatch={};state.SafeRejoinDispatch=dispatch
            -- Defer runs after the native call is entered (or returns), so a
            -- yielding Teleport call cannot hold the character at spawn.
            task.defer(function()
                if state.SafeRejoinDispatch==dispatch then escapeAfterRejoin()end
            end)
            local sent,message=pcall(function()TeleportService:Teleport(game.PlaceId,player)end)
            if not sent then clearRejoinAway();error(message)end
            escapeAfterRejoin()
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
        Panic=function()if state.PanicInPlace then state.PanicInPlace()else state.PanicToSpawn()end end,ReleasePanic=function()state.ReleaseSafePanic()end,
        Travelling=function()return state.AutomationTeleporting or state.TravelBusy end,
        Status=function(text)state.SafeModeStatus=text end,Save=state.SaveNow})
    state.SafeController=safe
    local multi=ctx.MakeMulti({State=state,Spots=function()return catalog.Spots end,
        CurrentFloor=function()return game.PlaceId end,ChangeFloor=state.ChangeAutomationFloor,
        CanMove=function()
            if state.AutoTradeBusy or state.AccountProgression or state.ModeratorBlocking then return false end
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
        if state.SafeKickFallback then state.SafeKickFallback.Reset()end
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
        if not floor or not state.IsAutomationFloorUnlocked(floor.Id) then state.SafeModeStatus="That floor is locked";refresh();return false end
        safe.Reset();multi.Reset();state.SafeFloorId=floor.Id;state.SaveNow();refresh()
        if state.SafeMode then
            state.PanicToSpawn()
            task.defer(function()workerIdentity();safe.Update();refresh()end)
        end
        return true
    end
    local whitelistGeneration=0
    function state.SetSafeWhitelist(text)
        text=tostring(text or ""):gsub("[^%w_]", " ")
        local entries,seen={},{}
        for word in text:gmatch("%S+")do
            local key=word:lower()
            if not seen[key]then seen[key]=true;entries[#entries+1]=word end
        end
        text=table.concat(entries,", ")
        if #text>2000 then state.SafeModeStatus="Whitelist is too long";refresh();return false end
        whitelistGeneration=whitelistGeneration+1;local token=whitelistGeneration
        safe.Reset();state.SafeWhitelistResolving=true
        task.delay(12,function()
            if token~=whitelistGeneration or not state.Running or not state.SafeWhitelistResolving then return end
            whitelistGeneration=whitelistGeneration+1;state.SafeWhitelistResolving=false
            state.SafeModeStatus="Whitelist lookup timed out · using the saved whitelist"
            refresh()
        end)
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
        if not spot or not state.IsAutomationFloorUnlocked(spot.PlaceId) then state.MultiSpotStatus="That arena's floor is locked";refresh();return false end
        state.MultiSpotSelected[id]=on==true or nil;multi.Reset();state.SaveNow();refresh();return true
    end
    function state.SetMultiSpotSelections(selected)
        local result=table.clone(state.MultiSpotSelected)
        for id in pairs(result)do
            local spot=catalog.SpotById[id]
            if spot and spot.PlaceId==game.PlaceId then result[id]=nil end
        end
        for id,on in pairs(selected or {})do
            if on then
                local spot=catalog.SpotById[catalog.Aliases[id]or id]
                if not spot or spot.PlaceId~=game.PlaceId or not state.IsAutomationFloorUnlocked(spot.PlaceId)then return false end
                result[spot.Id]=true
            end
        end
        state.MultiSpotSelected=result;multi.Reset();state.SaveNow();refresh();return true
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
    local function fallbackTicket()
        local ticket=api.Ticket
        if not ticket then
            local ok,value=pcall(readTicket)
            if ok and type(value)=="table"and type(value.RunId)=="string"then ticket=value end
        end
        if ticket then
            assert(ticket.UserId==player.UserId and ticket.PlaceId==game.PlaceId,"Saved search scope mismatch · no fallback kick")
            assert(type(ticket.StartedAt)=="number"and os.time()-ticket.StartedAt<900
                and type(ticket.Hops)=="number"and ticket.Hops<12,"Safe Mode search limit reached · no fallback kick")
        end
        return ticket
    end
    local kickFallback
    if ctx.MakeKickFallback then
        kickFallback=ctx.MakeKickFallback({InitialJob=game.JobId,Job=function()return game.JobId end,Now=os.clock,
            Active=function()return state.Running and state.SafeMode and not state.StopEverything and not state.ModeratorBlocking and not state.SafeWhitelistResolving end,
            Players=others,Allowed=allowed,Present=function(person)return person.Parent==Players end,
            Spawn=task.spawn,Sleep=task.wait,CheckLimits=fallbackTicket,
            Pause=function()
                workerIdentity();state.SafeKickFallbackBusy=true
                api.Destroy(true) -- Invalidate pending normal block/hop callbacks without resetting the ticket.
                if state.PanicInPlace then state.PanicInPlace()else state.PanicToSpawn()end
            end,
            Block=function(person,active)return state.BlockPlayerNative(person,active)end,
            Prepare=function(person)
                local ticket=fallbackTicket() or {Version=1,UserId=player.UserId,PlaceId=game.PlaceId,
                    RunId=HttpService:GenerateGUID(false),StartedAt=os.time(),Hops=0,Visited={},Added={}}
                assert(os.time()-ticket.StartedAt<900 and ticket.Hops<12,"Safe Mode search limit reached · no kick")
                ticket.SameServerReturns=math.min(ticket.SameServerReturns or 0,3)
                ticket.Active=true;ticket.Hops=ticket.Hops+1;ticket.SourceJob=game.JobId;ticket.Visited[game.JobId]=true
                ticket.LastBlockedUserId=person.UserId
                save(ticket)
                state.QueueAutomation()
            end,
            Rejoin=function()workerIdentity();TeleportService:Teleport(game.PlaceId,player)end,
            Kick=function(message)player:Kick(message)end,
            Finish=function()state.SafeKickFallbackBusy=false end,
            Status=function(message)state.SafeModeStatus=message;refresh()end})
        state.SafeKickFallback=kickFallback
    end
    ctx.Bind(player.OnTeleport,function(stage)
        if stage==Enum.TeleportState.Started or stage==Enum.TeleportState.InProgress then
            state.ServerTeleportStarted=true
            if kickFallback then kickFallback.MarkStarted()end
            escapeAfterRejoin()
            if state.SafeMode or state.MultiSpot or state.AccountProgression then
                local ok,message=pcall(state.QueueAutomation);if not ok then fail(message) end
            end
        elseif stage==Enum.TeleportState.Failed then clearRejoinAway();state.AutomationTeleporting=false end
    end)
    state.AutomationLoadedJob=game.JobId
    task.spawn(function()
        workerIdentity()
        local features=getgenv().SB2AutomationResumeFeatures
        getgenv().SB2AutomationResumeFeatures=nil
        if features then restoreFeatures(features) end
        local ok,resume=pcall(readTicket);if queuedResume then ok,resume=true,queuedResume end
        if not state.ModeratorBlocking and state.SafeMode and (state.AccountProgression or state.SafeFloorId==game.PlaceId) and ok and type(resume)=="table" and resume.Active==true and resume.PlaceId==game.PlaceId then api.Start(resume);if safe.AdoptSearch then safe.AdoptSearch()end end
        state.SaveNow()
        while state.Running do
            if state.AutomationTeleporting and os.clock()>state.AutomationTeleportDeadline then fail("Floor teleport timed out") end
            local updated,message=pcall(function()
                if state.ModeratorBlocking or state.SafeKickFallbackBusy or (kickFallback and kickFallback.Armed)then return end
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
    -- Population monitoring stays responsive even while the search worker yields.
    task.spawn(function()
        while state.Running do
            if kickFallback then pcall(kickFallback.Update,os.clock())end
            if not state.SafeKickFallbackBusy and not(kickFallback and kickFallback.Armed)and safe.ObserveProtected then pcall(safe.ObserveProtected)end
            task.wait(state.SafeMode and .1 or 1)
        end
    end)
    return api
end

-- END BUNDLED SERVER ISOLATION CLIENT
    end)()
    local blockPoint=(function()
-- BEGIN BUNDLED BLOCK INPUT
-- Live Core FoundationOverlay input needs GuiService's inset, even when the
-- overlay reports IgnoreGuiInset=true (58 px in the observed client).
return function(button,inset)
    return button.AbsolutePosition+button.AbsoluteSize/2+inset
end

-- END BUNDLED BLOCK INPUT
    end)()
    local makeBlockConfirm=(function()
-- BEGIN BUNDLED BLOCK CONFIRM
-- Native dialog confirmation only: never reopen after dismissal or click report.
return function(ctx)
    return function(target,active)
        local button,cancel=ctx.Find(target)
        if not active()then return false end
        if not button then ctx.Prompt(target)end
        local deadline=ctx.Now()+8
        repeat
            button,cancel=ctx.Find(target)
            if not active()then if cancel then ctx.Click(cancel)end;return false end
            if button and ctx.Ready(button)then break end
            ctx.Sleep(.03)
        until ctx.Now()>=deadline
        assert(button and ctx.Ready(button),"Roblox block dialog did not open; no rejoin attempted")
        local firstReady=ctx.Now()
        local stableSince,key=firstReady,ctx.Key(button)
        local nextClick,clicks,confirmedAt=firstReady+.10,0,nil
        deadline=firstReady+10
        repeat
            if not active()then
                button,cancel=ctx.Find(target);if cancel then ctx.Click(cancel)end
                return false
            end
            local now=ctx.Now()
            if ctx.Blocked(target)then
                confirmedAt=confirmedAt or now
                if now-confirmedAt>=ctx.Settle()then return true end
            else confirmedAt=nil end
            if not confirmedAt then button,cancel=ctx.Find(target)end
            if not confirmedAt and button and ctx.Ready(button)and clicks<4 then
                local currentKey=ctx.Key(button)
                if currentKey~=key then key=currentKey;stableSince=now end
                if now>=nextClick and now-stableSince>=.06 then
                    ctx.Click(button);clicks+=1;nextClick=ctx.Now()+.3
                end
            end
            ctx.Sleep(.03)
        until ctx.Now()>=deadline
        error("Roblox did not confirm the block; no rejoin attempted")
    end
end

-- END BUNDLED BLOCK CONFIRM
    end)()
    local makeFriend=(function()
-- BEGIN BUNDLED AUTO JOIN FRIEND
-- Uses the game's native friend-teleport route; never guesses server IDs.
return function(ctx)
    local s=ctx.State
    local api={}
    local nextTry,busy,serial=0,false,0
    local resolvedName,resolvedId
    function api.Reset()
        serial+=1;nextTry=0;resolvedName=nil;resolvedId=nil
        s.AutoJoinFriendStatus=s.AutoJoinFriend and "Checking friend..." or "Auto Join Friend is off"
    end
    function api.Update(now)
        if not s.AutoJoinFriend then s.AutoJoinFriendStatus="Auto Join Friend is off";return end
        if not s.Running then return end
        if s.StopEverything then s.AutoJoinFriendStatus="Paused · Stop Everything is on";return end
        if busy then return end
        local name=tostring(s.JoinFriendUsername or ""):match("^%s*(.-)%s*$"):gsub("^@", "")
        if name==""then s.AutoJoinFriendStatus="Enter a Roblox username";return end
        if not name:match("^[%w_]+$")or #name>20 then s.AutoJoinFriendStatus="Enter a username, not a display name";return end
        if s.ModeratorBlocking then s.AutoJoinFriendStatus="Waiting · moderator protection";return end
        if s.SafeModePanic then s.AutoJoinFriendStatus="Waiting · Safe Mode protection";return end
        if s.TravelBusy then s.AutoJoinFriendStatus="Waiting · current movement";return end
        if s.AutomationTeleporting then s.AutoJoinFriendStatus="Waiting · teleport in progress";return end
        if s.AccountProgression then s.AutoJoinFriendStatus="Waiting · Account Progression owns floor travel";return end
        if now<nextTry then return end
        s.AutoJoinFriendStatus="Checking @"..name
        nextTry=now+20;busy=true
        local token=serial
        local function active()return token==serial and s.Running and not s.StopEverything and s.AutoJoinFriend end
        local function ready()return active()and not(s.ModeratorBlocking or (s.SafeModePanic and not s.AutoJoinFriendHolding) or s.TravelBusy or s.AutomationTeleporting or s.AccountProgression)end
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                if resolvedName~=name:lower()then
                    local id=ctx.Resolve(name)
                    if not active()then return end
                    assert(type(id)=="number"and id>0,"Username was not found")
                    resolvedName,resolvedId=name:lower(),id
                end
                if not ready()then return end
                if resolvedId==ctx.LocalUserId then s.AutoJoinFriendStatus="Choose another player";return end
                if ctx.Present(resolvedId)then s.AutoJoinFriendStatus="Joined @"..name.." · staying in this server";return end
                if s.SafeMode and not(s.SafeWhitelistIds and s.SafeWhitelistIds[tostring(resolvedId)])then
                    s.AutoJoinFriendStatus="Add @"..name.." to the Safe Mode whitelist first";return
                end
                ctx.Queue()
                if not ready()then return end
                s.AutoJoinFriendStatus="Joining @"..name
                local message=ctx.Join(resolvedId,ready)
                if active()then s.AutoJoinFriendStatus=type(message)=="string"and message~=""and message or "Join requested · waiting for teleport"end
            end)
            busy=false
            if not ok and active()then s.AutoJoinFriendStatus="Retrying · "..tostring(reason)end
        end)
    end
    api.Reset()
    return api
end

-- END BUNDLED AUTO JOIN FRIEND
    end)()
    local makeKickFallback=(function()
-- BEGIN BUNDLED SAFE KICK FALLBACK
-- Eight seconds with a present outsider in this job triggers one confirmed-block kick.
return function(ctx)
    local api={Armed=false,Attempts=0}
    local seen,busy,retryAt,failures={},false,0,0
    local generation=0
    function api.Reset()generation=generation+1;seen={};retryAt=0;failures=0;api.Armed=false;api.Started=false;api.Attempts=0 end
    local function enabled()return ctx.Active()and ctx.Job()==ctx.InitialJob end
    function api.MarkStarted()if api.Armed and api.Attempts>0 then api.Started=true end end
    function api.Update(now)
        if api.Armed then return end
        if not enabled()then seen={};return end
        local present,target,oldest={}
        for _,person in ipairs(ctx.Players())do
            if not ctx.Allowed(person)then
                present[person.UserId]=true
                seen[person.UserId]=seen[person.UserId]or now
                if not oldest or seen[person.UserId]<oldest then target,oldest=person,seen[person.UserId]end
            end
        end
        for id in pairs(seen)do if not present[id]then seen[id]=nil end end
        if not target then failures=0;retryAt=0;return end
        if busy or failures>=3 or now<retryAt or now-oldest<8 then return end
        busy=true
        local token=generation
        local function active()return token==generation and enabled()and not ctx.Allowed(target)and ctx.Present(target)end
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                if not active()then return end
                if ctx.CheckLimits then ctx.CheckLimits()end
                ctx.Pause()
                if not active()then return end
                assert(ctx.Block(target,active)==true,"Native block was not confirmed · no kick")
                if not active()then return end
                ctx.Prepare(target)
                if not active()then return end
                api.Armed=true
                ctx.Status("Outsider still present after 8s · blocked · kicking and rejoining")
                -- Arm recovery before Kick: it may throw or return after disconnect.
                ctx.Spawn(function()
                    ctx.Sleep(.2)
                    for attempt=1,3 do
                        if token~=generation or not enabled()or api.Started then return end
                        api.Attempts=attempt
                        local sent,message=pcall(ctx.Rejoin)
                        if not sent then ctx.Status("Fallback rejoin · "..tostring(message))end
                        ctx.Sleep(3)
                    end
                    if enabled()and not api.Started then ctx.Status("Fallback rejoin unavailable · rejoin manually")end
                end)
                ctx.Kick("Safe Mode: blocked @"..target.Name.." before automatic rejoin.")
            end)
            busy=false;ctx.Finish()
            if not ok then
                failures=failures+1;retryAt=ctx.Now()+math.min(8,2^failures)
                ctx.Status("Safe fallback · "..tostring(reason))
            end
        end)
    end
    return api
end

-- END BUNDLED SAFE KICK FALLBACK
    end)()
    attach({MakeKickFallback=makeKickFallback,Make=make,MakeSafe=makeSafe,MakeMulti=makeMulti,MakeCatalog=makeCatalog,MakeUI=makeUI,MakeFriend=makeFriend,BlockPoint=blockPoint,MakeBlockConfirm=makeBlockConfirm,
        State=state,Player=player,Players=Players,Bind=bind,Button=uiButton,Label=uiLabel,Create=create,
        Corner=corner,Reveal=revealOptions,Parent=content})
end

-- Account Progression owns only boss selection and cross-floor sequencing.
do
    local makeController=(function()
-- BEGIN BUNDLED ACCOUNT PROGRESSION
-- Floor orchestration only. Combat, safe matchmaking, equipment and travel keep
-- their existing owners; no health, unlock or inventory values are written.
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Attempts=0}
    local nextTry,arrivalDeadline,waitingSince=0,nil,nil
    local spot,scoutIndex=nil,1
    local unlockWaitSince
    local function status(phase,message)
        api.Phase=phase;state.ProgressionPhase=phase;ctx.Status(message)
    end
    function api.Pause(message)
        api.Paused=true;api.LastError=tostring(message)
        ctx.Release();status("Paused","Paused · "..tostring(message).." · toggle OFF/ON to retry")
    end
    function api.Reset()
        api.Paused=false;api.LastError=nil;api.Attempts=0
        nextTry,arrivalDeadline,waitingSince,spot,scoutIndex=0,nil,nil,nil,1
        unlockWaitSince=nil
        ctx.Release();status("Idle",state.AccountProgression and "Starting account progression..." or "Account Progression is off")
    end
    local function travelFailed(now,message)
        api.Attempts+=1;ctx.Release();spot=nil;arrivalDeadline=nil
        if api.Attempts>=3 then api.Pause(message);return end
        nextTry=now+api.Attempts*2;status("Retrying","Retrying boss travel · "..tostring(message))
    end
    local function advance(now)
        local number=state.ProgressionFloor+1
        if number==6 then number=7 end
        local floor=ctx.Floor(number)
        if not floor then api.Pause("Floor "..number.." is unavailable");return end
        if not ctx.Unlocked(floor) then
            if state.ProgressionFloor~=6 then
                unlockWaitSince=unlockWaitSince or now
                if now-unlockWaitSince>=8 then
                    -- A saved/observed death does not prove the server granted
                    -- progression credit. Reacquire this floor's boss if it did not.
                    state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
                    unlockWaitSince=nil;spot=nil;arrivalDeadline=nil;waitingSince=nil
                    ctx.Release();ctx.Save()
                    status("Rechecking boss","Next floor is still locked · returning to the current main boss")
                    return
                end
            end
            status("Waiting for unlock","Boss defeated · waiting for F"..number.." unlock")
            return
        end
        ctx.Release();spot=nil;waitingSince=nil;arrivalDeadline=nil;api.Attempts=0
        unlockWaitSince=nil
        state.ProgressionFloor=number;state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
        -- Save the next checkpoint BEFORE queuing a cross-server transition.
        ctx.Save();status("Changing floor","Returning to the teleport pad · F"..number)
        nextTry=now+2
        local ok,message=ctx.ChangeFloor(floor)
        if not ok then api.Pause(message or "Floor travel failed") end
    end
    function api.Update(now)
        if not state.AccountProgression or not state.Running or state.StopEverything or api.Paused then return end
        if ctx.SyncFloor then ctx.SyncFloor()end
        if state.ProgressionComplete then
            status("Complete","Complete · F12 boss defeated · toggle OFF to restore your modes")
            return
        end
        if not ctx.Ready() then unlockWaitSince=nil;status("Waiting","Waiting for protection, character or current movement");return end
        if now<nextTry then return end
        local number=state.ProgressionFloor
        local floor=ctx.Floor(number)
        if not floor then api.Pause("Floor "..tostring(number).." is unavailable");return end
        -- Skip town even when resuming an old F6 checkpoint from another server.
        if number==6 then advance(now);return end
        if ctx.CurrentFloor()~=floor.Id then
            if not ctx.Unlocked(floor) then api.Pause("F"..number.." is locked");return end
            status("Changing floor","Returning to the teleport pad · F"..number)
            nextTry=now+2
            local ok,message=ctx.ChangeFloor(floor)
            if not ok then api.Pause(message or "Floor travel failed") end
            return
        end
        if state.ProgressionBossCleared then
            if number==12 then
                state.ProgressionComplete=true;ctx.Complete();ctx.Save()
                status("Complete","Complete · F12 boss defeated · toggle OFF to restore your modes")
            else advance(now) end
            return
        end
        if not ctx.CombatReady() then status("Waiting for combat","Enable Kill Aura and Auto Farm to continue");return end
        ctx.Equipment(now)
        if spot and not arrivalDeadline and ctx.NearBossSpot and not ctx.NearBossSpot(spot) then
            -- Respawn/panic can return to a pad beyond Auto Farm's detection range.
            -- Re-enter through finite arena travel rather than pinning the old point.
            ctx.Release();spot=nil;waitingSince=nil
        end
        if api.Phase=="Travelling to boss" or arrivalDeadline then
            if ctx.Moving() then
                if now>arrivalDeadline then travelFailed(now,"Boss travel timed out") end
                return
            end
            if not ctx.Arrived(spot) then travelFailed(now,"Boss arrival was not confirmed");return end
            arrivalDeadline=nil;api.Attempts=0;waitingSince=now
            ctx.Arrival();status("Fighting","Waiting for the main boss · F"..number)
        end
        if not spot then
            spot=ctx.BossSpot(floor,scoutIndex)
            if not spot then status("Finding boss","Waiting for the main boss arena to load · F"..number);return end
            local ok,message=ctx.Go(spot)
            if not ok then travelFailed(now,message or "Boss arena is unavailable");return end
            arrivalDeadline=now+15
            status("Travelling to boss","Moving to the main boss · F"..number)
            return
        end
        local boss=ctx.Boss(spot)
        if boss and boss.Defeated and boss.Credited then
            state.ProgressionBossCleared=true
            state.ProgressionBossClearedName=boss.Name
            ctx.Release();spot=nil;ctx.Save()
            status("Boss defeated","Main boss defeated · F"..number)
            return
        end
        status("Fighting",boss and boss.Alive and ("Defeating "..boss.Name.." · F"..number)
            or ("Waiting for the main boss to spawn · F"..number))
        -- F12 source contains several arenas. Scout only unclassified candidates;
        -- never treat a miniboss/regular mob or disappearance as a main-boss kill.
        if spot.Scout and not (boss and boss.Alive) and now-(waitingSince or now)>=20 then
            scoutIndex+=1;ctx.Release();spot=nil;waitingSince=nil
        end
    end
    function api.Destroy()ctx.Release()end
    return api
end

-- END BUNDLED ACCOUNT PROGRESSION
    end)()
    local makeGear=(function()
-- BEGIN BUNDLED PROGRESSION GEAR
-- Rank only owned, level-usable items using the native inventory display formula.
return function(ctx)
    local api={Dirty=true}
    local pending,nextRead,failures=nil,0,0
    local function effective(item,stat,snapshot)
        local value=tonumber(item.Stats[stat])
        if not value then return 0 end
        if item.Scale then value*=item.Scale*snapshot.Level end
        if item.MatchBest then value+=(snapshot.Highest[stat] or 0)*item.MatchBest end
        value=math.floor(value)
        local maximum=ctx.Rarity.RarityUpgrades[item.Rarity] or ctx.Rarity.RarityUpgrades.Common
        if maximum and item.Upgrade>0 then
            local multiplier=ctx.Rarity.UpgradeLevelMultipliers[maximum] or ctx.Rarity.UpgradeLevelMultipliers.default
            if stat=="Damage" then multiplier=tonumber(item.Stats.DamageUpgrade) or multiplier
            else multiplier=ctx.Rarity.UpgradeLevelMultipliers.default end
            value=math.floor(value+item.Upgrade/maximum*multiplier*value)
        end
        return value
    end
    function api.Plan(snapshot)
        local weapons,armor,accessories={},{},{}
        local equipped={};for _,id in pairs(snapshot.Equip)do equipped[id]=true end
        for _,item in ipairs(snapshot.Items)do
            if item.Level<=snapshot.Level and not item.Skin then
                local damage,defense=effective(item,"Damage",snapshot),effective(item,"Defense",snapshot)
                item.Damage,item.Defense=damage,defense
                item.Utility=(tonumber(item.Stats.Critical)or 0)+(tonumber(item.Stats.Lifesteal)or 0)
                    +(tonumber(item.Stats.HealthRegeneration)or 0)+(tonumber(item.Stats.StaminaRegeneration)or 0)
                if item.Type=="Weapon" then item.Score=damage;weapons[#weapons+1]=item
                elseif item.Type=="Clothing" and damage==0 and defense>0 then item.Score=defense;armor[#armor+1]=item
                elseif item.Type=="Accessory" and (damage>0 or defense>0 or item.Utility>0)then
                    item.Score=damage/math.max(1,snapshot.Highest.Damage or 1)
                        +defense/math.max(1,snapshot.Highest.Defense or 1)+item.Utility/100
                    accessories[#accessories+1]=item
                end
            end
        end
        local function less(a,b)
            if a.Score~=b.Score then return a.Score>b.Score end
            if a.Utility~=b.Utility then return a.Utility>b.Utility end
            if equipped[a.Id]~=equipped[b.Id]then return equipped[a.Id]==true end
            return a.Id<b.Id
        end
        table.sort(weapons,less);table.sort(armor,less);table.sort(accessories,less)
        local operations={}
        local function add(action,item,slot)
            operations[#operations+1]={Action=action,Item=item,Slot=slot}
        end
        if not (ctx.SkipWeapons and ctx.SkipWeapons())then
            local weapon=weapons[1]
            if weapon then
                -- Clear an existing offhand first, including when the winner is
                -- currently in Left. Only request Right after native acknowledgment.
                local left=snapshot.Equip.Left
                if left and left~=0 then
                    for _,item in ipairs(snapshot.Items)do
                        if item.Id==left then add("Unequip",item,"Left");break end
                    end
                end
                if snapshot.Equip.Right~=weapon.Id then add("EquipWeapon",weapon,"Right")end
            end
        end
        if ctx.WeaponsOnly and ctx.WeaponsOnly()then return operations end
        if armor[1] and snapshot.Equip.Clothing~=armor[1].Id then add("Wear",armor[1],"Clothing")end
        local desired={};for i=1,math.min(2,#accessories)do desired[accessories[i].Id]=true end
        local worn={};for _,slot in ipairs({"Accessory1","Accessory2"})do
            local id=snapshot.Equip[slot]
            if id and id~=0 then
                worn[id]=true
                if not desired[id] and next(desired) then
                    for _,item in ipairs(snapshot.Items)do if item.Id==id then add("Unequip",item,slot);break end end
                end
            end
        end
        for i=1,math.min(2,#accessories)do if not worn[accessories[i].Id]then add("Wear",accessories[i],"Accessory")end end
        return operations
    end
    function api.Invalidate()api.Dirty=true end
    function api.HasWork()return api.Dirty or pending~=nil end
    function api.Reset()pending=nil;nextRead=0;failures=0;api.Paused=false;api.Error=nil;api.Dirty=true end
    function api.Update(now)
        if api.Paused or not ctx.Active() or ctx.Busy() or now<nextRead then return end
        nextRead=now+.3
        if not pending and not api.Dirty then return end
        local snapshot=ctx.Read()
        if not snapshot then return end
        if pending then
            local found=false
            if pending.Action=="Unequip" then found=snapshot.Equip[pending.Slot]~=pending.Item.Id
            elseif pending.Slot=="Accessory"then
                found=snapshot.Equip.Accessory1==pending.Item.Id or snapshot.Equip.Accessory2==pending.Item.Id
            else found=snapshot.Equip[pending.Slot]==pending.Item.Id end
            if not found and now<pending.Deadline then return end
            if not found then
                failures+=1;api.Error="Equipment was not acknowledged: "..pending.Item.Name
                if failures>=3 then api.Paused=true;ctx.Status(api.Error);return end
            else failures=0;api.Error=nil end
            pending=nil
        end
        local op=api.Plan(snapshot)[1]
        if not op then api.Dirty=false;nextRead=now+1;ctx.Status("Best usable gear equipped");return end
        if not ctx.Active() or ctx.Busy() then return end
        local ok,message=ctx.Equip(op)
        if not ok then
            failures+=1;api.Error=tostring(message or "Equipment request failed");nextRead=now+2
            if failures>=3 then api.Paused=true end
            ctx.Status(api.Error);return
        end
        pending=op;pending.Deadline=now+4
        ctx.Status("Equipping "..op.Item.Name)
    end
    return api
end

-- END BUNDLED PROGRESSION GEAR
    end)()
    local attach=(function()
-- BEGIN BUNDLED PROGRESSION CLIENT
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
            return not state.AutoTradeBusy and root and not root.Anchored and humanoid and humanoid.Health>0
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

-- END BUNDLED PROGRESSION CLIENT
    end)()
    attach({State=state,Player=player,MakeController=makeController,MakeGear=makeGear,
        Parent=state.UI.Pages.Speacial,Button=uiButton,Label=uiLabel,Bind=bind,
        Mobs=function()refreshMobIndex();return trackedMobs end,Data=getMobData,
        Rank=targetPriority.Rank,OwnDamage=state.ReadOwnDamage,
        SkillsBusy=function()return Skills.usingSkill~="none"end,
        StopCombat=function(reason)
            finishAttackBurst(reason);stopSword(true)
            if state.CancelSkillAura then state.CancelSkillAura(reason)end
            state.FollowTarget=nil
        end})
end

runtimeOwner.Ready()

-- Manual restart intentionally retires the same-build singleton before reloading.
do
    local make=(function()
-- BEGIN BUNDLED RESTART SCRIPT
return function(ctx)
    local busy=false
    return function()
        if busy then return end
        busy=true;ctx.Status("Restarting...")
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                ctx.Save()
                -- Download and compile before retiring the current runtime.
                local run=ctx.Compile(ctx.Fetch())
                assert(type(run)=="function","Loader did not compile")
                ctx.Destroy()
                run()
            end)
            busy=false
            if not ok then ctx.Status("Restart failed · try again");ctx.Error(tostring(reason))end
        end)
    end
end

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
-- Existing inventory and new drops; bounded scans and send-time protections.
return function(ctx)
    local api={}
    local allowed={Common=true,Uncommon=true,Rare=true}
    local queue,queued={},setmetatable({}, {__mode="k"})
    local head,tail,nextSend=1,0,0
    local scan,scanIndex,scanAt=nil,1,0
    local requested=setmetatable({}, {__mode="k"})
    function api.Add(item,now)
        if queued[item]or requested[item]then return end
        local rarity=ctx.Rarity(item)
        if not allowed[rarity]or not ctx.Selected(rarity)then return end
        tail+=1;queue[tail]={Item=item,Rarity=rarity,Ready=now+.75};queued[item]=true
    end
    function api.Scan(items,now)
        scan,scanIndex,scanAt=items,1,now
    end
    function api.Update(now)
        if not ctx.Active()or ctx.Busy()then return end
        if scan then
            for _=1,32 do
                local item=scan[scanIndex]
                if not item then scan=nil;break end
                scanIndex+=1;api.Add(item,scanAt)
            end
        end
        if now<nextSend or head>tail then return end
        local entry=queue[head]
        if now<entry.Ready then return end
        queue[head]=nil;head+=1;queued[entry.Item]=nil
        if head>tail then table.clear(queue);head,tail=1,0 end
        local item,rarity=entry.Item,entry.Rarity
        if not ctx.Selected(rarity)or ctx.Rarity(item)~=rarity or ctx.Protected(item)then return end
        -- Native Event has no response. Send once, never retry destruction blindly.
        nextSend=now+.4
        requested[item]=true
        local ok,reason=pcall(ctx.Send,item)
        ctx.Status(ok and ("Dismantle requested · "..item.Name)or ("Dismantle failed · "..tostring(reason)))
    end
    function api.Clear()table.clear(queue);table.clear(queued);table.clear(requested);scan=nil;head,tail=1,0 end
    return api
end

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
return function(ctx)
    local api={}
    function api.AlwaysInclude(name)
        return name=="Upgrade Protection Scroll"or name=="Resurrection Crystal"
    end
    local highRarities={Legendary=true,Tribute=true,Burst=true}
    function api.IncludesRarity(mode,rarity)
        return (mode=="Legendary"or mode=="Tribute")and highRarities[rarity]==true
    end
    function api.MaxVel(balance)
        if type(balance)~="number"or balance~=balance or balance==math.huge or balance<=0 then return 0 end
        -- Clamp before multiplying: avoids float division by 1.1 rounding exact
        -- balances down (e.g. 660000 must permit an offer of 600000).
        return math.floor(math.min(math.floor(balance),110000000)*10/11)
    end
    local trade,lastSignature,stableSince,lastAction=nil,nil,0,nil
    local pending,acceptedRequest,pendingAdd
    function api.Event(kind,data)
        if not ctx.Active()then trade=nil;return end
        if kind=="Request"then
            pending=data
            ctx.Status("Checking incoming trade request")
        elseif kind=="TradeChanged"or kind=="RequestAccept"then
            if kind=="RequestAccept"then pendingAdd=nil;lastSignature=nil;lastAction=nil end
            trade=data;pending=nil;acceptedRequest=nil
        elseif kind=="TradeCancel"or kind=="TradeCompleted"then trade=nil;pending=nil;acceptedRequest=nil;pendingAdd=nil;lastSignature=nil;lastAction=nil end
    end
    function api.Update(now)
        if not ctx.Active()then return false end
        local requester=ctx.Pending and ctx.Pending()or (not ctx.Pending and pending or nil)
        if not requester then acceptedRequest=nil
        elseif not ctx.Allowed(requester)then ctx.Status("Trade request ignored · user is not whitelisted")
        elseif requester~=acceptedRequest then
            ctx.Send("RequestAccept",{});acceptedRequest=requester;pending=nil
            ctx.Status("Accepted whitelisted trade request")
        end
        if not trade then return false end
        local role=trade.Requester==ctx.Player and "Requester"or trade.Partner==ctx.Player and "Partner"
        if not role then return false end
        local peer=role=="Requester"and "Partner"or "Requester"
        if not ctx.Allowed(trade[peer])then ctx.Status("Trade paused · partner is not whitelisted");return false end
        local desired,vel=ctx.Plan()
        local ours=trade[role.."Items"]or{}
        local have,wanted={},{}
        local signature={tostring(vel)}
        for _,item in ipairs(desired)do
            local count=ctx.Count and ctx.Count(item)or 1
            count=type(count)=="number"and count==count and count~=math.huge and math.max(0,math.floor(count))or 0
            local amount=count
            if amount>0 then wanted[item]=amount end
            signature[#signature+1]="want:"..item.Value..":"..amount
        end
        for _,side in ipairs({role,peer})do
            signature[#signature+1]=tostring(trade[side.."Currency"]or 0)
            for _,v in ipairs(trade[side.."Items"]or{})do
                local item=v.item
                signature[#signature+1]=side..":"..tostring(item and item.Value)..":"..tostring(v.count or 1)
            end
        end
        local key=table.concat(signature,"|")
        if key~=lastSignature then lastSignature=key;stableSince=now;lastAction=nil end
        for _,v in ipairs(ours)do if v.item then have[v.item]=(have[v.item]or 0)+(v.count or 1)end end
        for item,count in pairs(have)do
            if not wanted[item]or count>wanted[item]then ctx.Status("Trade paused · offer exceeds selected quantity");return true end
        end
        if pendingAdd then
            if (have[pendingAdd.Item]or 0)<pendingAdd.Expected then
                ctx.Status(now-pendingAdd.At>=10 and "Server has not acknowledged the batch · trade may be full · automatic acceptance paused"or "Waiting for stacked items to register");return true
            end
            pendingAdd=nil
        end
        for _,item in ipairs(desired)do
            local current=have[item]or 0
            local amount=wanted[item]or 0
            if current<amount then
                local batch=math.min(4,amount-current)
                pendingAdd={Item=item,Expected=current+batch,At=now}
                for _=1,batch do ctx.Send("TradeAddItem",{item})end
                ctx.Status("Adding "..item.Name.." · "..current.."/"..amount);return true
            end
        end
        if (trade[role.."Currency"]or 0)~=vel then
            if lastAction~="vel"then lastAction="vel";ctx.Send("TradeChangeCurrency",{vel})end
            ctx.Status("Setting trade Vel");return true
        end
        if now-stableSince<2 then ctx.Status("Waiting for the trade offer to settle");return true end
        if trade[role.."Confirmed"]~=true then
            if lastAction~="confirm"then lastAction="confirm";ctx.Send("TradeConfirm",{})end
        elseif trade[peer.."Confirmed"]==true and trade[role.."Accepted"]~=true then
            if lastAction~="accept"then lastAction="accept";ctx.Send("TradeAccept",{})end
        end
        ctx.Status("Trade offer ready · automatic confirmation active")
        return true
    end
    return api
end

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

-- WindUI is bundled at a fixed release; queued rejoins need no library download.
do
    local librarySource=(function()
-- BEGIN BUNDLED WINDUI SOURCE
return [==========[
--[[
MIT License

Copyright (c) 2026 Footages

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]
--[[
     _      ___         ____  ______
    | | /| / (_)__  ___/ / / / /  _/
    | |/ |/ / / _ \/ _  / /_/ // /
    |__/|__/_/_//_/\_,_/\____/___/

    v1.6.65  |  2026-07-01  |  Roblox UI Library for scripts

    To view the source code, see the `src/` folder on the official GitHub repository.

    Author: Footagesus (Footages, .ftgs, oftgs)
    Github: https://github.com/Footagesus/WindUI
    Discord: https://discord.gg/ftgs-development-hub-1300692552005189632
    License: MIT
]]

type ConfigType__DARKLUA_TYPE_a={
Object:Instance,
Camera:Instance?,
Interactive:boolean?,
Height:number?,
Focused:boolean,

Window:any,
WindUI:any,
Tab:any,
Parent:Instance,
}local a a={cache={}, load=function(b)if not a.cache[b]then a.cache[b]={c=a[b]()}end return a.cache[b].c end}do function a.a()

local b

local d={
New=nil,
Init=nil,
Shapes={
Circle={
Image="rbxassetid://111665032676235",
Rect=Rect.new(512,512,512,512),
Radius=512,
},
CircleOutline={
Image="rbxassetid://108556680453287",
Rect=Rect.new(512,512,512,512),
Radius=512,
},
CircleGlass={
Image="rbxassetid://95600044758841",
Rect=Rect.new(512,512,512,512),
Radius=512,
},



SquircleH={
Image="rbxassetid://125083578015333",
Rect=Rect.new(512,325,512,325),
Radius=325,
},
SquircleHOutline={
Image="rbxassetid://107043713170567",
Rect=Rect.new(512,325,512,325),
Radius=325,
},
SquircleHGlass={
Image="rbxassetid://84819521201001",
Rect=Rect.new(512,325,512,325),
Radius=325,
},
["SquircleH-TL-TR"]={
Image="rbxassetid://90680657206619",
Rect=Rect.new(807,512,807,512),
Radius=325,
AutoChange=false,
},
["SquircleH-BL-BR"]={
Image="rbxassetid://99216342056719",
Rect=Rect.new(0,512,0,512),
Radius=325,
AutoChange=false,
},

SquircleV={
Image="rbxassetid://124965260437653",
Rect=Rect.new(325,512,325,512),
Radius=325,
},
SquircleVOutline={
Image="rbxassetid://88808835404198",
Rect=Rect.new(325,512,325,512),
Radius=325,
},
SquircleVGlass={
Image="rbxassetid://124982801466667",
Rect=Rect.new(325,512,325,512),
Radius=325,
},

Squircle={
Image="rbxassetid://89641024074289",
Rect=Rect.new(460,460,460,460),
Radius=310,
},
SquircleOutline={
Image="rbxassetid://74029063732681",
Rect=Rect.new(512,512,512,512),
Radius=310,
},
SquircleGlass={
Image="rbxassetid://131126436897551",
Rect=Rect.new(512,512,512,512),
Radius=310,
},

["Squircle-TL-TR"]={
Image="rbxassetid://75712142040725",
Rect=Rect.new(512,512,512,512),
Radius=310,
AutoChange=false,
},
["Squircle-BL-BR"]={
Image="rbxassetid://83676684425544",
Rect=Rect.new(512,0,512,0),
Radius=310,
AutoChange=false,
},Square=
{
Image="rbxassetid://82909646051652",
Rect=Rect.new(512,512,512,512),
Radius=512,
AutoChange=false,
},
},
}

function d.Init(e,f)
b=f
return e.New
end

function d.New(e,f,g,h,i,j,l)
local m={
Radius=f or 0,
Type=g or"Circle",
GetRadius=nil,
GetType=nil,
SetRadius=nil,
SetType=nil,
}

local p={
["Glass-0.7"]="SquircleGlass",
["Glass-1"]="SquircleGlass",
["Glass-1.4"]="SquircleGlass",
["Squircle-Outline"]="SquircleOutline",
}

local function GetShape(r)
return d.Shapes[p[r]or r]or d.Shapes.Circle
end

local r=b.New(j and"ImageButton"or"ImageLabel",{
Image="",
ScaleType=l~=false and"Slice"or nil,
SliceCenter=m.Type~="Squircle"and Rect.new(512,512,512,512)or nil,
SliceScale=1,
ThemeTag=h and h.ThemeTag or nil,
BackgroundTransparency=1,
},i)

for u,v in next,h do
if not table.find({"ThemeTag"},u)then
r[u]=v
end
end

function m.SetRadius(u,v)
m.Radius=v
r.SliceScale=math.max(v/GetShape(m.Type).Radius,0.0001)
return m
end

function m.SetType(u,v)
m.Type=v
local x=GetShape(v)
r.Image=x.Image
r.SliceCenter=x.Rect
m:SetRadius(m.Radius)
return m
end

function m.GetRadius(u)
return m.Radius
end

function m.GetType(u)
return m.Type
end

m:SetRadius(f)
m:SetType(g)

b.AddSignal(r:GetPropertyChangedSignal"AbsoluteSize",function()
local u=GetShape(m.Type)
if u.AutoChange==false then
return
end

if string.find(m.Type,"Squircle")then
local v=string.find(m.Type,"Glass")and"Glass"or nil
local x=string.find(m.Type,"Outline")and"Outline"or nil

local z=math.round(r.AbsoluteSize.X/b.UIScale)
local A=math.round(r.AbsoluteSize.Y/b.UIScale)

local B=m.Radius~=0 and m.Radius or math.min(z,A)/2
local C=d.Shapes.Squircle.Radius/1024
local F=B/math.min(z,A)

local G

if z>A then
if F>=C then
G="SquircleH"..(x or v or"")
else
G="Squircle"..(x or v or"")
end
elseif z<A then
if F>=C then
G="SquircleV"..(x or v or"")
else
G="Squircle"..(x or v or"")
end
else
if F>=C then
G="Circle"..(x or v or"")
else
G="Squircle"..(x or v or"")
end
end

if G~=m:GetType()then
m:SetType(G)
end
end
end)

return r,m
end

return d end function a.b()

local b=(cloneref or clonereference or function(b)return b end)

local d=b(game:GetService"ReplicatedStorage":WaitForChild("GetIcons",99999):InvokeServer())

local function parseIconString(e)
if type(e)=="string"then
local f=e:find":"
if f then
local g=e:sub(1,f-1)
local h=e:sub(f+1)
return g,h
end
end
return nil,e
end

function d.AddIcons(e,f)
if type(e)~="string"or type(f)~="table"then
error"AddIcons: packName must be string, iconsData must be table"
return
end

if not d.Icons[e]then
d.Icons[e]={
Icons={},
Spritesheets={}
}
end

for g,h in pairs(f)do
if type(h)=="number"or(type(h)=="string"and h:match"^rbxassetid://")then
local i=h
if type(h)=="number"then
i="rbxassetid://"..tostring(h)
end

d.Icons[e].Icons[g]={
Image=i,
ImageRectSize=Vector2.new(0,0),
ImageRectPosition=Vector2.new(0,0),
Parts=nil
}
d.Icons[e].Spritesheets[i]=i

elseif type(h)=="table"then
if h.Image and h.ImageRectSize and h.ImageRectPosition then
local i=h.Image
if type(i)=="number"then
i="rbxassetid://"..tostring(i)
end

d.Icons[e].Icons[g]={
Image=i,
ImageRectSize=h.ImageRectSize,
ImageRectPosition=h.ImageRectPosition,
Parts=h.Parts
}

if not d.Icons[e].Spritesheets[i]then
d.Icons[e].Spritesheets[i]=i
end
else
warn("AddIcons: Invalid spritesheet data format for icon '"..g.."'")
end
else
warn("AddIcons: Unsupported data type for icon '"..g.."': "..type(h))
end
end
end

function d.SetIconsType(e)
d.IconsType=e
end

local e
function d.Init(f,g)
d.New=f
d.IconThemeTag=g

e=f
return d
end

function d.Icon(f,g,h)
h=h~=false
local i,j=parseIconString(f)

local l=i or g or d.IconsType
local m=j

local p=d.Icons[l]

if p and p.Icons and p.Icons[m]then
return{
p.Spritesheets[tostring(p.Icons[m].Image)],
p.Icons[m],
}
elseif p and p[m]and string.find(p[m],"rbxassetid://")then
return h and{
p[m],
{ImageRectSize=Vector2.new(0,0),ImageRectPosition=Vector2.new(0,0)}
}or p[m]
end
return nil
end

function d.GetIcon(f,g)
return d.Icon(f,g,false)
end


function d.Icon2(f,g,h)
return d.Icon(f,g,true)
end

function d.Image(f)
local g={
Icon=f.Icon or nil,
Type=f.Type,
Colors=f.Colors or{(d.IconThemeTag or Color3.new(1,1,1)),Color3.new(1,1,1)},
Transparency=f.Transparency or{0,0},
Size=f.Size or UDim2.new(0,24,0,24),

IconFrame=nil,
}

local h={}
local i={}

for j,l in next,g.Colors do
h[j]={
ThemeTag=typeof(l)=="string"and l,
Color=typeof(l)=="Color3"and l,
}
end

for j,l in next,g.Transparency do
i[j]={
ThemeTag=typeof(l)=="string"and l,
Value=typeof(l)=="number"and l,
}
end


local j=d.Icon2(g.Icon,g.Type)
local l=typeof(j)=="string"and string.find(j,'rbxassetid://')

if d.New then
local m=e or d.New



local p=m("ImageLabel",{
Size=g.Size,
BackgroundTransparency=1,
ImageColor3=h[1].Color or nil,
ImageTransparency=i[1].Value or nil,
ThemeTag=h[1].ThemeTag and{
ImageColor3=h[1].ThemeTag,
ImageTransparency=i[1].ThemeTag,
},
Image=l and j or j[1],
ImageRectSize=l and nil or j[2].ImageRectSize,
ImageRectOffset=l and nil or j[2].ImageRectPosition,
})


if not l and j[2].Parts then
for r,u in next,j[2].Parts do
local v=d.Icon(u,g.Type)

m("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
ImageColor3=h[1+r].Color or nil,
ImageTransparency=i[1+r].Value or nil,
ThemeTag=h[1+r].ThemeTag and{
ImageColor3=h[1+r].ThemeTag,
ImageTransparency=i[1+r].ThemeTag,
},
Image=v[1],
ImageRectSize=v[2].ImageRectSize,
ImageRectOffset=v[2].ImageRectPosition,
Parent=p,
})
end
end

g.IconFrame=p
else
local m=Instance.new"ImageLabel"
m.Size=g.Size
m.BackgroundTransparency=1
m.ImageColor3=h[1].Color
m.ImageTransparency=i[1].Value or nil
m.Image=l and j or j[1]
m.ImageRectSize=l and nil or j[2].ImageRectSize
m.ImageRectOffset=l and nil or j[2].ImageRectPosition


if not l and j[2].Parts then
for p,r in next,j[2].Parts do
local u=d.Icon(r,g.Type)

local v=Instance.New"ImageLabel"
v.Size=UDim2.new(1,0,1,0)
v.BackgroundTransparency=1
v.ImageColor3=h[1+p].Color
v.ImageTransparency=i[1+p].Value or nil
v.Image=u[1]
v.ImageRectSize=u[2].ImageRectSize
v.ImageRectOffset=u[2].ImageRectPosition
v.Parent=m
end
end

g.IconFrame=m
end


return g
end

return d end function a.c()
return function(b)
return{


Primary="Icon",

White=Color3.new(1,1,1),
Black=Color3.new(0,0,0),

Dialog="Accent",

Background="Accent",
BackgroundTransparency=0,
Hover="Text",

PanelBackground="White",
PanelBackgroundTransparency=0.95,

WindowBackground="Background",

WindowShadow="Black",


WindowTopbarTitle="Text",
WindowTopbarAuthor="Text",
WindowTopbarIcon="Icon",
WindowTopbarButtonIcon="Icon",


WindowSearchBarBackground="Dialog",

TabBackground="Hover",
TabBackgroundHover="Hover",
TabBackgroundHoverTransparency=0.97,
TabBackgroundActive="Hover",
TabBackgroundActiveTransparency=0.93,
TabText="Text",
TabTextTransparency=0.3,
TabTextTransparencyActive=0,
TabTitle="Text",
TabIcon="Icon",
TabIconTransparency=0.4,
TabIconTransparencyActive=0.1,
TabBorderTransparency=1,
TabBorderTransparencyActive=0.75,
TabBorder="White",

ElementBackground="Text",
ElementBackgroundTransparency=0.93,
ElementBackgroundHover=b:AddColor("ElementBackground","#ffffff",0.1),
ElementTitle="Text",
ElementDesc="Text",
ElementIcon="Icon",

PopupBackground="Background",
PopupBackgroundTransparency="BackgroundTransparency",
PopupTitle="Text",
PopupContent="Text",
PopupIcon="Icon",

DialogBackground="Dialog",
DialogBackgroundTransparency="BackgroundTransparency",
DialogTitle="Text",
DialogContent="Text",
DialogIcon="Icon",

Toggle="Button",
ToggleBar="White",

Checkbox="Primary",
CheckboxIcon="White",
CheckboxBorder="White",
CheckboxBorderTransparency=0.75,

SliderIcon="Icon",

Slider="Primary",
SliderThumb="White",
SliderIconFrom="SliderIcon",
SliderIconTo="SliderIcon",

ProgressBar="Primary",
ProgressBarTrack="Text",
ProgressBarTrackTransparency=0.9,
ProgressBarText="Text",

Tooltip=Color3.fromHex"4C4C4C",
TooltipText="White",
TooltipSecondary="Primary",
TooltipSecondaryText="White",

TabSectionIcon="Icon",

SectionIcon="Icon",

SectionExpandIcon="Icon",
SectionExpandIconTransparency=0.4,
SectionBox="Text",
SectionBoxTransparency=0.95,
SectionBoxBorder="White",
SectionBoxBorderTransparency=0.75,
SectionBoxBackground="Text",
SectionBoxBackgroundTransparency=0.97,

SearchBarBorder="White",
SearchBarBorderTransparency=0.75,

Notification="Background",
Notification2="White",
Notification2Transparency=0.92,
NotificationTitle="Text",
NotificationTitleTransparency=0,
NotificationContent="Text",
NotificationContentTransparency=0.4,
NotificationDuration="White",
NotificationDurationTransparency=0.95,
NotificationBorder="White",
NotificationBorderTransparency=0.75,

DropdownTabBorder="White",
DropdownTabBackground="ElementBackground",
DropdownBackground="Background",

LabelBackground="White",
LabelBackgroundTransparency=0.95,

ViewportBackground="ElementBackground",
ViewportBackgroundTransparency="ElementBackgroundTransparency",
}
end end function a.d()

local b=(cloneref or clonereference or function(b)
return b
end)

local d=b(game:GetService"RunService")
local e=b(game:GetService"UserInputService")
local f=b(game:GetService"TweenService")
local g=b(game:GetService"LocalizationService")
local h=b(game:GetService"HttpService")

local i=a.load'a'local j=

d.Heartbeat

local l="https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"

local m
if d:IsStudio()or not writefile then
m=a.load'b'
else
m=loadstring(
game.HttpGet and game:HttpGet(l)or h:GetAsync(l)
)()
end

m.SetIconsType"lucide"

local p

local r
r={
Font="rbxassetid://12187365364",
Localization=nil,
CanDraggable=true,
Theme=nil,
Themes=nil,
Icons=m,
Signals={},
Objects={},
LocalizationObjects={},
UIScale=1,
FontObjects={},
Language=string.match(g.SystemLocaleId,"^[a-z]+"),
Request=http_request or(syn and syn.request)or request,
DefaultProperties={
ScreenGui={
ResetOnSpawn=false,
ZIndexBehavior="Sibling",
},
CanvasGroup={
BorderSizePixel=0,
BackgroundColor3=Color3.new(1,1,1),
},
Frame={
BorderSizePixel=0,
BackgroundColor3=Color3.new(1,1,1),
},
TextLabel={
BackgroundColor3=Color3.new(1,1,1),
BorderSizePixel=0,
Text="",
RichText=true,
TextColor3=Color3.new(1,1,1),
TextSize=14,
},
TextButton={
BackgroundColor3=Color3.new(1,1,1),
BorderSizePixel=0,
Text="",
AutoButtonColor=false,
TextColor3=Color3.new(1,1,1),
TextSize=14,
},
TextBox={
BackgroundColor3=Color3.new(1,1,1),
BorderColor3=Color3.new(0,0,0),
ClearTextOnFocus=false,
Text="",
TextColor3=Color3.new(0,0,0),
TextSize=14,
},
ImageLabel={
BackgroundTransparency=1,
BackgroundColor3=Color3.new(1,1,1),
BorderSizePixel=0,
},
ImageButton={
BackgroundColor3=Color3.new(1,1,1),
BorderSizePixel=0,
AutoButtonColor=false,
},
UIListLayout={
SortOrder="LayoutOrder",
},
ScrollingFrame={
ScrollBarImageTransparency=1,
BorderSizePixel=0,
},
VideoFrame={
BorderSizePixel=0,
},
},
Colors={
Red="#e53935",
Orange="#f57c00",
Green="#43a047",
Blue="#039be5",
White="#ffffff",
Grey="#484848",
},
ThemeFallbacks=nil,





















ThemeChangeCallbacks={},
}

function r.Init(u)
p=u

r.ThemeFallbacks=a.load'c'(r)

r.UIScale=u.UIScale

i:Init(r)
end

function r.AddSignal(u,v)
local x=u:Connect(v)
table.insert(r.Signals,x)
return x
end

function r.DisconnectAll()
for u,v in next,r.Signals do
local x=table.remove(r.Signals,u)
x:Disconnect()
end
end

function r.SafeCallback(u,...)
if not u then
return
end

local v,x=pcall(u,...)
if not v then
if p and p.Window and p.Window.Debug then local
z, A=x:find":%d+: "

warn("[ WindUI: DEBUG Mode ] "..x)

return p:Notify{
Title="DEBUG Mode: Error",
Content=not A and x or x:sub(A+1),
Duration=8,
}
end
end
end

function r.Gradient(u,v)
if p and p.Gradient then
return p:Gradient(u,v)
end

local x={}
local z={}

for A,B in next,u do
local C=tonumber(A)
if C then
C=math.clamp(C/100,0,1)
table.insert(x,ColorSequenceKeypoint.new(C,B.Color))
table.insert(z,NumberSequenceKeypoint.new(C,B.Transparency or 0))
end
end

table.sort(x,function(A,B)
return A.Time<B.Time
end)
table.sort(z,function(A,B)
return A.Time<B.Time
end)

if#x<2 then
error"ColorSequence requires at least 2 keypoints"
end

local A={
Color=ColorSequence.new(x),
Transparency=NumberSequence.new(z),
}

if v then
for B,C in pairs(v)do
A[B]=C
end
end

return A
end

function r.SetTheme(u)
local v=r.Theme
r.Theme=u
r.UpdateTheme(nil,false)

for x,z in next,r.ThemeChangeCallbacks do
r.SafeCallback(z,u,v)
end
end

function r.AddFontObject(u)
table.insert(r.FontObjects,u)
r.UpdateFont(r.Font)
end

function r.UpdateFont(u)
r.Font=u
for v,x in next,r.FontObjects do
x.FontFace=Font.new(u,x.FontFace.Weight,x.FontFace.Style)
end
end

function r.GetThemeProperty(u,v)
local function getValue(x,z)
local A=z[x]

if A==nil then
return nil
end

if typeof(A)=="string"and string.sub(A,1,1)=="#"then
return Color3.fromHex(A)
end

if typeof(A)=="Color3"then
return A
end

if typeof(A)=="number"then
return A
end

if typeof(A)=="table"and A.Color and A.Transparency then
return A
end

if typeof(A)=="function"then
return A(z)
end

return A
end

local x=getValue(u,v)
if x~=nil then
if typeof(x)=="string"and string.sub(x,1,1)~="#"then
local z=r.GetThemeProperty(x,v)
if z~=nil then
return z
end
else
return x
end
end

local z=r.ThemeFallbacks[u]
if z~=nil then
if typeof(z)=="string"and string.sub(z,1,1)~="#"then
return r.GetThemeProperty(z,v)
else
return getValue(u,{[u]=z})
end
end

x=getValue(u,r.Themes.Dark)
if x~=nil then
if typeof(x)=="string"and string.sub(x,1,1)~="#"then
local A=r.GetThemeProperty(x,r.Themes.Dark)
if A~=nil then
return A
end
else
return x
end
end

if z~=nil then
if typeof(z)=="string"and string.sub(z,1,1)~="#"then
return r.GetThemeProperty(z,r.Themes.Dark)
else
return getValue(u,{[u]=z})
end
end

return nil
end

function r.AddThemeObject(u,v,x)
if r.Objects[u]then
for z,A in pairs(v)do
r.Objects[u].Properties[z]=A
end
else
r.Objects[u]={Object=u,Properties=v}
end

if not x then
r.UpdateTheme(u,false)
end
return u
end

function r.AddLangObject(u)
local v=r.LocalizationObjects[u]
if not v then
return
end

local x=v.Object

r.SetLangForObject(u)

return x
end

function r.UpdateTheme(u,v,x,z,A,B)
local function ApplyTheme(C)
for F,G in pairs(C.Properties or{})do
local H=r.GetThemeProperty(G,r.Theme)
if H~=nil then
if typeof(H)=="Color3"then
local J=C.Object:FindFirstChild"LibraryGradient"
if J then
J:Destroy()
end

if x then
r.Tween(
C.Object,
z or 0.2,
{[F]=H},
A or Enum.EasingStyle.Quint,
B or Enum.EasingDirection.Out
):Play()
elseif v then
r.Tween(C.Object,0.08,{[F]=H}):Play()
else
C.Object[F]=H
end
elseif typeof(H)=="table"and H.Color and H.Transparency then
C.Object[F]=Color3.new(1,1,1)

local J=C.Object:FindFirstChild"LibraryGradient"
if not J then
J=Instance.new"UIGradient"
J.Name="LibraryGradient"
J.Parent=C.Object
end

J.Color=H.Color
J.Transparency=H.Transparency

for L,M in pairs(H)do
if L~="Color"and L~="Transparency"and J[L]~=nil then
J[L]=M
end
end
elseif typeof(H)=="number"then
if x then
r.Tween(
C.Object,
z or 0.2,
{[F]=H},
A or Enum.EasingStyle.Quint,
B or Enum.EasingDirection.Out
):Play()
elseif v then
r.Tween(C.Object,0.08,{[F]=H}):Play()
else
C.Object[F]=H
end
end
else
local J=C.Object:FindFirstChild"LibraryGradient"
if J then
J:Destroy()
end
end
end
end

if u then
local C=r.Objects[u]
if C then
ApplyTheme(C)
end
else
for C,F in pairs(r.Objects)do
ApplyTheme(F)
end
end
end

function r.SetThemeTag(u,v,x,z,A)
r.AddThemeObject(u,v)
r.UpdateTheme(u,false,true,x,z,A)
end

function r.SetLangForObject(u)
if r.Localization and r.Localization.Enabled then
local v=r.LocalizationObjects[u]
if not v then
return
end

local x=v.Object
local z=v.TranslationId

local A=r.Localization.Translations[r.Language]
if A and A[z]then
x.Text=A[z]
else
local B=r.Localization
and r.Localization.Translations
and r.Localization.Translations.en
or nil
if B and B[z]then
x.Text=B[z]
else
x.Text="["..z.."]"
end
end
end
end

function r.ChangeTranslationKey(u,v,x)
if r.Localization and r.Localization.Enabled then
local z=string.match(x,"^"..r.Localization.Prefix.."(.+)")
if z then
for A,B in ipairs(r.LocalizationObjects)do
if B.Object==v then
B.TranslationId=z
r.SetLangForObject(A)
return
end
end

table.insert(r.LocalizationObjects,{
TranslationId=z,
Object=v,
})
r.SetLangForObject(#r.LocalizationObjects)
end
end
end

function r.UpdateLang(u)
if u then
r.Language=u
end

for v=1,#r.LocalizationObjects do
local x=r.LocalizationObjects[v]
if x.Object and x.Object.Parent~=nil then
r.SetLangForObject(v)
else
r.LocalizationObjects[v]=nil
end
end
end

function r.SetLanguage(u)
r.Language=u
r.UpdateLang()
end

function r.Icon(u,v)
return m.Icon2(u,nil,v~=false)
end

function r.AddIcons(u,v)
return m.AddIcons(u,v)
end

function r.New(u,v,x)
local z=Instance.new(u)

for A,B in next,r.DefaultProperties[u]or{}do
z[A]=B
end

for A,B in next,v or{}do
if A~="ThemeTag"then
z[A]=B
end
if r.Localization and r.Localization.Enabled and A=="Text"then
local C=string.match(B,"^"..r.Localization.Prefix.."(.+)")
if C then
local F=#r.LocalizationObjects+1
r.LocalizationObjects[F]={TranslationId=C,Object=z}

r.SetLangForObject(F)
end
end
end

for A,B in next,x or{}do
B.Parent=z
end

if v and v.ThemeTag then
r.AddThemeObject(z,v.ThemeTag)
end
if v and v.FontFace then
r.AddFontObject(z)
end
return z
end

function r.Tween(u,v,x,...)
return f:Create(u,TweenInfo.new(v,...),x)
end








































































function r.NewRoundFrame(u,v,x,z,A,B)
return i:New(u,v,x,z,A,nil)
end

local u=r.New local v=
r.Tween

function r.SetDraggable(x)
r.CanDraggable=x
end

function r.Drag(x,z,A)
local B=p.GenerateGUID()

local C
local F=false
local G,H
local J

local L={
CanDraggable=true,
}

if not z or typeof(z)~="table"then
z={x}
end

local function update(M)
if not F or not L.CanDraggable then
return
end

local N=M.Position-G
r.Tween(x,0.02,{
Position=UDim2.new(
H.X.Scale,
H.X.Offset+N.X,
H.Y.Scale,
H.Y.Offset+N.Y
),
}):Play()
end

for M,N in pairs(z)do
N.InputBegan:Connect(function(O)
if not L.CanDraggable or F then
return
end

if
O.UserInputType==Enum.UserInputType.MouseButton1
or O.UserInputType==Enum.UserInputType.Touch
then
if p and p.CurrentInput and p.CurrentInput~=B then
return
end

p.CurrentInput=B

F=true
J=O
C=N
G=O.Position
H=x.Position

if A and typeof(A)=="function"then
A(true,C)
end
end
end)
end

e.InputChanged:Connect(function(M)
if not F then
return
end
if p.CurrentInput and p.CurrentInput~=B then
return
end

if J.UserInputType==Enum.UserInputType.MouseButton1 then
if M.UserInputType==Enum.UserInputType.MouseMovement then
update(M)
end
elseif J.UserInputType==Enum.UserInputType.Touch then
if M==J then
update(M)
end
end
end)

e.InputEnded:Connect(function(M)
if not F or p.CurrentInput~=B then
return
end

if
M==J
or(
J.UserInputType==Enum.UserInputType.MouseButton1
and M.UserInputType==Enum.UserInputType.MouseButton1
)
then
p.CurrentInput=nil
F=false
J=nil
C=nil

if A and typeof(A)=="function"then
A(false,nil)
end
end
end)

function L.Set(M,N)
L.CanDraggable=N
end

return L
end

m.Init(u,"Icon")

function r.SanitizeFilename(x)
local z=x:match"([^/]+)$"or x

z=z:gsub("%.[^%.]+$","")

z=z:gsub("[^%w%-_]","_")

if#z>50 then
z=z:sub(1,50)
end

return z
end

function r.Image(x,z,A,B,C,F,G,H)
B=B or"Temp"
z=r.SanitizeFilename(z)

local J=u("Frame",{
Size=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
},{
u("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
ScaleType="Crop",
ThemeTag=(r.Icon(x)or G)and{
ImageColor3=F and(H or"Icon")or nil,
}or nil,
},{
u("UICorner",{
CornerRadius=UDim.new(0,A),
}),
}),
})
if r.Icon(x)then
J.ImageLabel:Destroy()

local L=m.Image{
Icon=x,
Size=UDim2.new(1,0,1,0),
Colors={
(F and(H or"Icon")or false),
"Button",
},
}.IconFrame
L.Parent=J
elseif string.find(x,"http")and not string.find(x,"roblox.com")then
local L="WindUI/"..B.."/assets/."..C.."-"..z..".png"
local M,N=pcall(function()
task.spawn(function()
local M=r.Request
and r.Request{
Url=x,
Method="GET",
}.Body
or{}

if not d:IsStudio()and writefile then
writefile(L,M)
end


local N,O=pcall(getcustomasset,L)
if N then
J.ImageLabel.Image=O
else
warn(
string.format(
"[ WindUI.Creator ] Failed to load custom asset '%s': %s",
L,
tostring(O)
)
)
J:Destroy()

return
end
end)
end)
if not M then
warn(
"[ WindUI.Creator ]  '"..identifyexecutor()
or"Studio".."' doesnt support the URL Images. Error: "..N
)

J:Destroy()
end
elseif x==""then
J.Visible=false
else
J.ImageLabel.Image=x
end

return J
end

function r.Color3ToHSB(x)
local z,A,B=x.R,x.G,x.B
local C=math.max(z,A,B)
local F=math.min(z,A,B)
local G=C-F

local H=0
if G~=0 then
if C==z then
H=(A-B)/G%6
elseif C==A then
H=(B-z)/G+2
else
H=(z-A)/G+4
end
H=H*60
else
H=0
end

local J=(C==0)and 0 or(G/C)
local L=C

return{
h=math.floor(H+0.5),
s=J,
b=L,
}
end

function r.GetPerceivedBrightness(x)
local z=x.R
local A=x.G
local B=x.B
return 0.299*z+0.587*A+0.114*B
end

function r.GetTextColorForHSB(x,z)
local A=r.Color3ToHSB(x)local
B, C, F=A.h, A.s, A.b
if r.GetPerceivedBrightness(x)>(z or 0.5)then
return Color3.fromHSV(B/360,0,0.05)
else
return Color3.fromHSV(B/360,0,0.98)
end
end

function r.GetAverageColor(x)
local z,A,B=0,0,0
local C=x.Color.Keypoints
for F,G in ipairs(C)do

z=z+G.Value.R
A=A+G.Value.G
B=B+G.Value.B
end
local F=#C
return Color3.new(z/F,A/F,B/F)
end

function r.GenerateUniqueID(x)
return h:GenerateGUID(false)
end

function r.OnThemeChange(x,z)
if typeof(z)~="function"then
return
end

local A=h:GenerateGUID(false)
r.ThemeChangeCallbacks[A]=z

return{
Disconnect=function()
r.ThemeChangeCallbacks[A]=nil
end,
}
end

function r.AddColor(x,z,A,B)
B=math.clamp(B or 1,0,1)
if typeof(A)=="string"then
A=Color3.fromHex(A)
end

return function(C)
local F
if typeof(z)=="string"and string.sub(z,1,1)~="#"then
F=r.GetThemeProperty(z,C)
elseif typeof(z)=="string"then
F=Color3.fromHex(z)
else
F=z
end

if not F or typeof(F)~="Color3"then
return nil
end

return Color3.new(
math.clamp(F.R+A.R*B,0,1),
math.clamp(F.G+A.G*B,0,1),
math.clamp(F.B+A.B*B,0,1)
)
end
end

function r.GetElementPosition(x,z,A,B)
if type(A)~="number"or A~=math.floor(A)then
return nil,1
end






local C=#z


if C==0 or A<1 or A>C then
return nil,2
end

local function isDelimiter(F)
if F==nil then
return true
end
local G=F.__type
return G=="Divider"or G=="Space"or G=="Section"
end

if isDelimiter(z[A])then
return nil,3
end

local function calculate(F,G)
if G==1 then
return"Squircle"
end
if F==1 then
return B and"SquircleH-TL-TR"or"Squircle-TL-TR"
end
if F==G then
return B and"SquircleH-BL-BR"or"Squircle-BL-BR"
end
return"Square"
end

local F=1
local G=0

for H=1,C do
local J=z[H]
if isDelimiter(J)then
if A>=F and A<=H-1 then
local L=A-F+1
return calculate(L,G)
end
F=H+1
G=0
else
G=G+1
end
end

if A>=F and A<=C then
local H=A-F+1
return calculate(H,G)
end

return nil,4
end

return r end function a.e()

local b={}







function b.New(d,e,f)
local g={
Enabled=e.Enabled or false,
Translations=e.Translations or{},
Prefix=e.Prefix or"loc:",
DefaultLanguage=e.DefaultLanguage or"en"
}

f.Localization=g

return g
end



return b end function a.f()
local b=a.load'd'
local d=b.New
local e=b.Tween

local f={
Size=UDim2.new(0,300,1,-156),
SizeLower=UDim2.new(0,300,1,-56),
UICorner=18,
UIPadding=14,

Holder=nil,
NotificationIndex=0,
Notifications={},
}

function f.Init(g)
local h={
Lower=false,
}

function h.SetLower(i)
h.Lower=i
h.Frame.Size=i and f.SizeLower or f.Size
end

h.Frame=d("Frame",{
Position=UDim2.new(1,-29,0,56),
AnchorPoint=Vector2.new(1,0),
Size=f.Size,
Parent=g,
BackgroundTransparency=1,




},{
d("UIListLayout",{
HorizontalAlignment="Center",
SortOrder="LayoutOrder",
VerticalAlignment="Bottom",
Padding=UDim.new(0,8),
}),
d("UIPadding",{
PaddingBottom=UDim.new(0,29),
}),
})
return h
end

function f.New(g)
local h={
Title=g.Title or"Notification",
Content=g.Content or nil,
Icon=g.Icon or nil,
IconThemed=g.IconThemed,
Background=g.Background,
BackgroundImageTransparency=g.BackgroundImageTransparency,
Duration=g.Duration or 5,
Buttons=g.Buttons or{},
CanClose=g.CanClose~=false,
UIElements={},
Closed=false,
}



f.NotificationIndex=f.NotificationIndex+1
f.Notifications[f.NotificationIndex]=h









local i

if h.Icon then





















i=b.Image(
h.Icon,
h.Title..":"..h.Icon,
0,
g.Window,
"Notification",
h.IconThemed
)
i.Size=UDim2.new(0,26,0,26)
i.Position=UDim2.new(0,f.UIPadding,0,f.UIPadding)

end

local l
if h.CanClose then
l=d("ImageButton",{
Image=b.Icon"x"[1],
ImageRectSize=b.Icon"x"[2].ImageRectSize,
ImageRectOffset=b.Icon"x"[2].ImageRectPosition,
BackgroundTransparency=1,
Size=UDim2.new(0,16,0,16),
Position=UDim2.new(1,-f.UIPadding,0,f.UIPadding),
AnchorPoint=Vector2.new(1,0),
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=0.4,
},{
d("TextButton",{
Size=UDim2.new(1,8,1,8),
BackgroundTransparency=1,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Text="",
}),
})
end

local m=b.NewRoundFrame(f.UICorner,"Squircle",{
Size=UDim2.new(0,0,1,0),
ThemeTag={
ImageTransparency="NotificationDurationTransparency",
ImageColor3="NotificationDuration",
},

})

local p=d("Frame",{
Size=UDim2.new(1,h.Icon and-28-f.UIPadding or 0,1,0),
Position=UDim2.new(1,0,0,0),
AnchorPoint=Vector2.new(1,0),
BackgroundTransparency=1,
AutomaticSize="Y",
},{
d("UIPadding",{
PaddingTop=UDim.new(0,f.UIPadding),
PaddingLeft=UDim.new(0,f.UIPadding),
PaddingRight=UDim.new(0,f.UIPadding),
PaddingBottom=UDim.new(0,f.UIPadding),
}),
d("TextLabel",{
AutomaticSize="Y",
Size=UDim2.new(1,-30-f.UIPadding,0,0),
TextWrapped=true,
TextXAlignment="Left",
RichText=true,
BackgroundTransparency=1,
TextSize=18,
ThemeTag={
TextColor3="NotificationTitle",
TextTransparency="NotificationTitleTransparency",
},
Text=h.Title,
FontFace=Font.new(b.Font,Enum.FontWeight.SemiBold),
}),
d("UIListLayout",{
Padding=UDim.new(0,f.UIPadding/3),
}),
})

if h.Content then
d("TextLabel",{
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
TextWrapped=true,
TextXAlignment="Left",
RichText=true,
BackgroundTransparency=1,

TextSize=15,
ThemeTag={
TextColor3="NotificationContent",
TextTransparency="NotificationContentTransparency",
},
Text=h.Content,
FontFace=Font.new(b.Font,Enum.FontWeight.Medium),
Parent=p,
})
end

local r=b.NewRoundFrame(f.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,0),
Position=UDim2.new(2,0,1,0),
AnchorPoint=Vector2.new(0,1),
AutomaticSize="Y",
ImageTransparency=0.05,
ThemeTag={
ImageColor3="Notification",
},

},{
b.NewRoundFrame(f.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="Notification2",
ImageTransparency="Notification2Transparency",
},
}),
d("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Name="DurationFrame",
},{






d("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
ClipsDescendants=true,
},{
m,
}),




}),
d("ImageLabel",{
Name="Background",
Image=h.Background,
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
ScaleType="Crop",
ImageTransparency=h.BackgroundImageTransparency,

},{
d("UICorner",{
CornerRadius=UDim.new(0,f.UICorner),
}),
}),

p,
i,
l,
})

local u=d("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,0,0),
Parent=g.Holder,
},{
r,
})

function h.Close(v)
if not h.Closed then
h.Closed=true
e(
u,
0.45,
{Size=UDim2.new(1,0,0,-8)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
e(r,0.55,{Position=UDim2.new(2,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
task.wait(0.45)
u:Destroy()
end
end

task.spawn(function()
task.wait()
e(
u,
0.45,
{Size=UDim2.new(1,0,0,r.AbsoluteSize.Y)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
e(r,0.45,{Position=UDim2.new(0,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
if h.Duration then
m.Size=UDim2.new(0,r.DurationFrame.AbsoluteSize.X,1,0)
e(
r.DurationFrame.Frame,
h.Duration,
{Size=UDim2.new(0,0,1,0)},
Enum.EasingStyle.Linear,
Enum.EasingDirection.InOut
):Play()
task.wait(h.Duration)
h:Close()
end
end)

if l then
b.AddSignal(l.TextButton.MouseButton1Click,function()
h:Close()
end)
end


return h
end

return f end function a.g()












local b=4294967296;local d=b-1;local function c(e,f)local g,h=0,1;while e~=0 or f~=0 do local i,l=e%2,f%2;local m=(i+l)%2;g=g+m*h;e=math.floor(e/2)f=math.floor(f/2)h=h*2 end;return g%b end;local function k(e,f,g,...)local h;if f then e=e%b;f=f%b;h=c(e,f)if g then h=k(h,g,...)end;return h elseif e then return e%b else return 0 end end;local function n(e,f,g,...)local h;if f then e=e%b;f=f%b;h=(e+f-c(e,f))/2;if g then h=n(h,g,...)end;return h elseif e then return e%b else return d end end;local function o(e)return d-e end;local function q(e,f)if f<0 then return lshift(e,-f)end;return math.floor(e%4294967296/2^f)end;local function s(e,f)if f>31 or f<-31 then return 0 end;return q(e%b,f)end;local function lshift(e,f)if f<0 then return s(e,-f)end;return e*2^f%4294967296 end;local function t(e,f)e=e%b;f=f%32;local g=n(e,2^f-1)return s(e,f)+lshift(g,32-f)end;local e={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function w(f)return string.gsub(f,".",function(g)return string.format("%02x",string.byte(g))end)end;local function y(f,g)local h=""for i=1,g do local l=f%256;h=string.char(l)..h;f=(f-l)/256 end;return h end;local function D(f,g)local h=0;for i=g,g+3 do h=h*256+string.byte(f,i)end;return h end;local function E(f,g)local h=64-(g+9)%64;g=y(8*g,8)f=f.."\128"..string.rep("\0",h)..g;assert(#f%64==0)return f end;local function I(f)f[1]=0x6a09e667;f[2]=0xbb67ae85;f[3]=0x3c6ef372;f[4]=0xa54ff53a;f[5]=0x510e527f;f[6]=0x9b05688c;f[7]=0x1f83d9ab;f[8]=0x5be0cd19;return f end;local function K(f,g,h)local i={}for l=1,16 do i[l]=D(f,g+(l-1)*4)end;for l=17,64 do local m=i[l-15]local p=k(t(m,7),t(m,18),s(m,3))m=i[l-2]i[l]=(i[l-16]+p+i[l-7]+k(t(m,17),t(m,19),s(m,10)))%b end;local l,m,p,r,u,v,x,z=h[1],h[2],h[3],h[4],h[5],h[6],h[7],h[8]for A=1,64 do local B=k(t(l,2),t(l,13),t(l,22))local C=k(n(l,m),n(l,p),n(m,p))local F=(B+C)%b;local G=k(t(u,6),t(u,11),t(u,25))local H=k(n(u,v),n(o(u),x))local J=(z+G+H+e[A]+i[A])%b;z=x;x=v;v=u;u=(r+J)%b;r=p;p=m;m=l;l=(J+F)%b end;h[1]=(h[1]+l)%b;h[2]=(h[2]+m)%b;h[3]=(h[3]+p)%b;h[4]=(h[4]+r)%b;h[5]=(h[5]+u)%b;h[6]=(h[6]+v)%b;h[7]=(h[7]+x)%b;h[8]=(h[8]+z)%b end;local function Z(f)f=E(f,#f)local g=I{}for h=1,#f,64 do K(f,h,g)end;return w(y(g[1],4)..y(g[2],4)..y(g[3],4)..y(g[4],4)..y(g[5],4)..y(g[6],4)..y(g[7],4)..y(g[8],4))end;local f;local g={["\\"]="\\",["\""]="\"",["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t"}local h={["/"]="/"}for i,l in pairs(g)do h[l]=i end;local i=function(i)return"\\"..(g[i]or string.format("u%04x",i:byte()))end;local l=function(l)return"null"end;local m=function(m,p)local r={}p=p or{}if p[m]then error"circular reference"end;p[m]=true;if rawget(m,1)~=nil or next(m)==nil then local u=0;for v in pairs(m)do if type(v)~="number"then error"invalid table: mixed or invalid key types"end;u=u+1 end;if u~=#m then error"invalid table: sparse array"end;for v,x in ipairs(m)do table.insert(r,f(x,p))end;p[m]=nil;return"["..table.concat(r,",").."]"else for u,v in pairs(m)do if type(u)~="string"then error"invalid table: mixed or invalid key types"end;table.insert(r,f(u,p)..":"..f(v,p))end;p[m]=nil;return"{"..table.concat(r,",").."}"end end;local p=function(p)return'"'..p:gsub('[%z\1-\31\\"]',i)..'"'end;local r=function(r)if r~=r or r<=-math.huge or r>=math.huge then error("unexpected number value '"..tostring(r).."'")end;return string.format("%.14g",r)end;local u={["nil"]=l,table=m,string=p,number=r,boolean=tostring}f=function(v,x)local z=type(v)local A=u[z]if A then return A(v,x)end;error("unexpected type '"..z.."'")end;local v=function(v)return f(v)end;local x;local z=function(...)local z={}for A=1,select("#",...)do z[select(A,...)]=true end;return z end;local A=z(" ","\t","\r","\n")local B=z(" ","\t","\r","\n","]","}",",")local C=z("\\","/",'"',"b","f","n","r","t","u")local F=z("true","false","null")local G={["true"]=true,["false"]=false,null=nil}local H=function(H,J,L,M)for N=J,#H do if L[H:sub(N,N)]~=M then return N end end;return#H+1 end;local J=function(J,L,M)local N=1;local O=1;for P=1,L-1 do O=O+1;if J:sub(P,P)=="\n"then N=N+1;O=1 end end;error(string.format("%s at line %d col %d",M,N,O))end;local L=function(L)local M=math.floor;if L<=0x7f then return string.char(L)elseif L<=0x7ff then return string.char(M(L/64)+192,L%64+128)elseif L<=0xffff then return string.char(M(L/4096)+224,M(L%4096/64)+128,L%64+128)elseif L<=0x10ffff then return string.char(M(L/262144)+240,M(L%262144/4096)+128,M(L%4096/64)+128,L%64+128)end;error(string.format("invalid unicode codepoint '%x'",L))end;local M=function(M)local N=tonumber(M:sub(1,4),16)local O=tonumber(M:sub(7,10),16)if O then return L((N-0xd800)*0x400+O-0xdc00+0x10000)else return L(N)end end;local N=function(N,O)local P=""local Q=O+1;local R=Q;while Q<=#N do local S=N:byte(Q)if S<32 then J(N,Q,"control character in string")elseif S==92 then P=P..N:sub(R,Q-1)Q=Q+1;local T=N:sub(Q,Q)if T=="u"then local U=N:match("^[dD][89aAbB]%x%x\\u%x%x%x%x",Q+1)or N:match("^%x%x%x%x",Q+1)or J(N,Q-1,"invalid unicode escape in string")P=P..M(U)Q=Q+#U else if not C[T]then J(N,Q-1,"invalid escape char '"..T.."' in string")end;P=P..h[T]end;R=Q+1 elseif S==34 then P=P..N:sub(R,Q-1)return P,Q+1 end;Q=Q+1 end;J(N,O,"expected closing quote for string")end;local O=function(O,P)local Q=H(O,P,B)local R=O:sub(P,Q-1)local S=tonumber(R)if not S then J(O,P,"invalid number '"..R.."'")end;return S,Q end;local P=function(P,Q)local R=H(P,Q,B)local S=P:sub(Q,R-1)if not F[S]then J(P,Q,"invalid literal '"..S.."'")end;return G[S],R end;local Q=function(Q,R)local S={}local T=1;R=R+1;while 1 do local U;R=H(Q,R,A,true)if Q:sub(R,R)=="]"then R=R+1;break end;U,R=x(Q,R)S[T]=U;T=T+1;R=H(Q,R,A,true)local V=Q:sub(R,R)R=R+1;if V=="]"then break end;if V~=","then J(Q,R,"expected ']' or ','")end end;return S,R end;local R=function(R,S)local T={}S=S+1;while 1 do local U,V;S=H(R,S,A,true)if R:sub(S,S)=="}"then S=S+1;break end;if R:sub(S,S)~='"'then J(R,S,"expected string for key")end;U,S=x(R,S)S=H(R,S,A,true)if R:sub(S,S)~=":"then J(R,S,"expected ':' after key")end;S=H(R,S+1,A,true)V,S=x(R,S)T[U]=V;S=H(R,S,A,true)local W=R:sub(S,S)S=S+1;if W=="}"then break end;if W~=","then J(R,S,"expected '}' or ','")end end;return T,S end;local S={['"']=N,["0"]=O,["1"]=O,["2"]=O,["3"]=O,["4"]=O,["5"]=O,["6"]=O,["7"]=O,["8"]=O,["9"]=O,["-"]=O,t=P,f=P,n=P,["["]=Q,["{"]=R}x=function(T,U)local V=T:sub(U,U)local W=S[V]if W then return W(T,U)end;J(T,U,"unexpected character '"..V.."'")end;local T=function(T)if type(T)~="string"then error("expected argument of type string, got "..type(T))end;local U,V=x(T,H(T,1,A,true))V=H(T,V,A,true)if V<=#T then J(T,V,"trailing garbage")end;return U end;
local U,V,W=v,T,Z;





local X={}

local Y=(cloneref or clonereference or function(Y)return Y end)


function X.New(_,aa)

local ab=_;
local ac=aa;
local ad=true;


local ae=function(ae)end;


repeat task.wait(1)until game:IsLoaded();


local af=false;
local ag,ah,ai,aj,ak,al,am,an,ao=setclipboard or toclipboard,request or http_request or syn_request,string.char,tostring,string.sub,os.time,math.random,math.floor,gethwid or function()return Y(game:GetService"Players").LocalPlayer.UserId end
local ap,aq="",0;


local ar="https://api.platoboost.app";
local as=ah{
Url=ar.."/public/connectivity",
Method="GET"
};
if as.StatusCode~=200 and as.StatusCode~=429 then
ar="https://api.platoboost.net";
end


function cacheLink()
if aq+(600)<al()then
local at=ah{
Url=ar.."/public/start",
Method="POST",
Body=U{
service=ab,
identifier=W(ao())
},
Headers={
["Content-Type"]="application/json",
["User-Agent"]="Roblox/Exploit"
}
};

if at.StatusCode==200 then
local au=V(at.Body);

if au.success==true then
ap=au.data.url;
aq=al();
return true,ap
else
ae(au.message);
return false,au.message
end
elseif at.StatusCode==429 then
local au="you are being rate limited, please wait 20 seconds and try again.";
ae(au);
return false,au
end

local au="Failed to cache link.";
ae(au);
return false,au
else
return true,ap
end
end

cacheLink();


local at=function()
local at=""
for au=1,16 do
at=at..ai(an(am()*(26))+97)
end
return at
end


for au=1,5 do
local av=at();
task.wait(0.2)
if at()==av then
local aw="platoboost nonce error.";
ae(aw);
error(aw);
end
end


local au=function()
local au,av=cacheLink();

if au then
ag(av);
end
end


local av=function(av)
local aw=at();
local ax=ar.."/public/redeem/"..aj(ab);

local ay={
identifier=W(ao()),
key=av
}

if ad then
ay.nonce=aw;
end

local az=ah{
Url=ax,
Method="POST",
Body=U(ay),
Headers={
["Content-Type"]="application/json"
}
};

if az.StatusCode==200 then
local aA=V(az.Body);

if aA.success==true then
if aA.data.valid==true then
if ad then
if aA.data.hash==W("true".."-"..aw.."-"..ac)then
return true
else
ae"failed to verify integrity.";
return false
end
else
return true
end
else
ae"key is invalid.";
return false
end
else
if ak(aA.message,1,27)=="unique constraint violation"then
ae"you already have an active key, please wait for it to expire before redeeming it.";
return false
else
ae(aA.message);
return false
end
end
elseif az.StatusCode==429 then
ae"you are being rate limited, please wait 20 seconds and try again.";
return false
else
ae"server returned an invalid status code, please try again later.";
return false
end
end


local aw=function(aw)
if af==true then
return false,("A request is already being sent, please slow down.")
else
af=true;
end

local ax=at();
local ay=ar.."/public/whitelist/"..aj(ab).."?identifier="..W(ao()).."&key="..aw;

if ad then
ay=ay.."&nonce="..ax;
end

local az=ah{
Url=ay,
Method="GET",
};

af=false;

if az.StatusCode==200 then
local aA=V(az.Body);

if aA.success==true then
if aA.data.valid==true then
if ad then
if aA.data.hash==W("true".."-"..ax.."-"..ac)then
return true,""
else
return false,("failed to verify integrity.")
end
else
return true
end
else
if ak(aw,1,4)=="KEY_"then
return true,av(aw)
else
return false,("Key is invalid.")
end
end
else
return false,(aA.message)
end
elseif az.StatusCode==429 then
return false,("You are being rate limited, please wait 20 seconds and try again.")
else
return false,("Server returned an invalid status code, please try again later.")
end
end


local ax=function(ax)
local ay=at();
local az=ar.."/public/flag/"..aj(ab).."?name="..ax;

if ad then
az=az.."&nonce="..ay;
end

local aA=ah{
Url=az,
Method="GET",
};

if aA.StatusCode==200 then
local aB=V(aA.Body);

if aB.success==true then
if ad then
if aB.data.hash==W(aj(aB.data.value).."-"..ay.."-"..ac)then
return aB.data.value
else
ae"failed to verify integrity.";
return nil
end
else
return aB.data.value
end
else
ae(aB.message);
return nil
end
else
return nil
end
end


return{
Verify=aw,
GetFlag=ax,
Copy=au,
}
end


return X end function a.h()






local aa=(cloneref or clonereference or function(aa)
return aa
end)

local ab=aa(game:GetService"HttpService")
local ac={}

function ac.New(ad)
local ae=gethwid or function()
return aa(game:GetService"Players").LocalPlayer.UserId
end
local af,ag=request or http_request or syn_request,setclipboard or toclipboard

function ValidateKey(ah)
local ai="https://api.pandauth.com/api/v1/keys/validate"

local aj={
ServiceID=ad,
HWID=tostring(ae()),
Key=tostring(ah),
}

local ak=ab:JSONEncode(aj)
local al,am=pcall(function()
return af{
Url=ai,
Method="POST",
Headers={
["User-Agent"]="Roblox/Exploit",
["Content-Type"]="application/json",
},
Body=ak,
}
end)

if al and am then
if am.Success then
local an,ao=pcall(function()
return ab:JSONDecode(am.Body)
end)

if an and ao then
if ao.Authenticated_Status and ao.Authenticated_Status=="Success"then
return true,"Authenticated"
else
local ap=ao.Note or"Unknown reason"
return false,"Authentication failed: "..ap
end
else
return false,"JSON decode error"
end
else
warn(
" HTTP request was not successful. Code: "
..tostring(am.StatusCode)
.." Message: "
..am.StatusMessage
)
return false,"HTTP request failed: "..am.StatusMessage
end
else
return false,"Request pcall error"
end
end

function GetKeyLink()
return"https://new.pandadevelopment.net/getkey/"..tostring(ad).."?hwid="..tostring(ae())
end

function CopyLink()
return ag(GetKeyLink())
end

return{
Verify=ValidateKey,
Copy=CopyLink,
}
end

return ac end function a.i()







local aa={}

function aa.New(ab,ac)
local ad="https://sdkapi-public.luarmor.net/library.lua"

local ae=loadstring(game.HttpGet and game:HttpGet(ad)or HttpService:GetAsync(ad))()
local af=setclipboard or toclipboard

ae.script_id=ab

function ValidateKey(ag)
local ah=ae.check_key(ag)


if ah.code=="KEY_VALID"then
return true,"Whitelisted!"
elseif ah.code=="KEY_HWID_LOCKED"then
return false,"Key linked to a different HWID. Please reset it using our bot"
elseif ah.code=="KEY_INCORRECT"then
return false,"Key is wrong or deleted!"
else
return false,"Key check failed:"..ah.message.." Code: "..ah.code
end
end

function CopyLink()
af(tostring(ac))
end

return{
Verify=ValidateKey,
Copy=CopyLink,
}
end

return aa end function a.j()









local aa={}

function aa.New(ab,ac,ad)
JunkieProtected.API_KEY=ac
JunkieProtected.PROVIDER=ad
JunkieProtected.SERVICE_ID=ab

local function ValidateKey(ae)
if not ae or ae==""then
print"No key provided!"

return false,"No key provided. Please get a key."
end

local af=JunkieProtected.IsKeylessMode()
if af and af.keyless_mode then
print"Keyless mode enabled. Starting script..."
return true,"Keyless mode enabled. Starting script..."
end

local ag=JunkieProtected.ValidateKey{Key=ae}
if ag=="valid"then
print"Key is valid! Starting script..."
load()
if _G.JD_IsPremium then
print"Premium user detected!"
else
print"Standard user"
end

return true,"Key is valid!"
else
local ah=JunkieProtected.GetKeyLink()
print"Invalid key!"

return false,"Invalid key. Get one from:"..ah
end
end

local function copyLink()
local ae=JunkieProtected.GetKeyLink()

if setclipboard then
setclipboard(ae)
end
end
return{
Verify=ValidateKey,
Copy=copyLink
}
end

return aa end function a.k()



return{
platoboost={
Name="Platoboost",
Icon="rbxassetid://75920162824531",
Args={"ServiceId","Secret"},

New=a.load'g'.New
},
pandadevelopment={
Name="Panda Development",
Icon="panda",
Args={"ServiceId"},

New=a.load'h'.New
},
luarmor={
Name="Luarmor",
Icon="rbxassetid://130918283130165",
Args={"ScriptId","Discord"},

New=a.load'i'.New
},
junkiedevelopment={
Name="Junkie Development",
Icon="rbxassetid://106310347705078",
Args={"ServiceId","ApiKey","Provider"},

New=a.load'j'.New
},


}end function a.l()



return[[
{
    "name": "windui",
    "version": "1.6.65",
    "main": "./dist/main.lua",
    "repository": "https://github.com/Footagesus/WindUI",
    "discord": "https://discord.gg/ftgs-development-hub-1300692552005189632",
    "author": "Footagesus",
    "description": "Roblox UI Library for scripts",
    "license": "MIT",
    "scripts": {
        "dev": "bash build/build.sh dev $INPUT_FILE",
        "build": "bash build/build.sh build $INPUT_FILE",
        "live": "python3 -m http.server 8642",
        "watch": "chokidar . -i 'node_modules' -i 'dist' -i 'build' -c 'npm run dev --'",
        "live-build": "concurrently \"npm run live\" \"npm run watch --\"",
        "example-live-build": "INPUT_FILE=main_example.lua npm run live-build",
        "updater": "python3 updater/main.py"
    },
    "keywords": [
        "ui-library",
        "ui-design",
        "script",
        "script-hub",
        "exploiting"
    ],
    "devDependencies": {
        "chokidar-cli": "^3.0.0",
        "concurrently": "^9.2.0"
    }
}
]]end function a.m()

local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween

function aa.New(ae,af,ag,ah,ai,aj,ak,al)
ah=ah or"Primary"
local am=al or(not ak and 10 or 999)
local an
if af and af~=""then
an=ac("ImageLabel",{
Image=ab.Icon(af)[1],
ImageRectSize=ab.Icon(af)[2].ImageRectSize,
ImageRectOffset=ab.Icon(af)[2].ImageRectPosition,
Size=UDim2.new(0,21,0,21),
BackgroundTransparency=1,
ImageColor3=ah=="White"and Color3.new(0,0,0)or nil,
ImageTransparency=ah=="White"and 0.4 or 0,
ThemeTag={
ImageColor3=ah~="White"and"Icon"or nil,
},
})
end

local ao=ac("TextButton",{
Size=UDim2.new(0,0,1,0),
AutomaticSize="X",
Parent=ai,
BackgroundTransparency=1,
},{
ab.NewRoundFrame(am,"Squircle",{
ThemeTag={
ImageColor3=ah~="White"and"Button"or nil,
},
ImageColor3=ah=="White"and Color3.new(1,1,1)or nil,
Size=UDim2.new(1,0,1,0),
Name="Squircle",
ImageTransparency=ah=="Primary"and 0 or ah=="White"and 0 or 0.9,
}),

ab.NewRoundFrame(am,"Squircle",{



ImageColor3=Color3.new(1,1,1),
Size=UDim2.new(1,0,1,0),
Name="Special",
ImageTransparency=ah=="Secondary"and 0.95 or 1,
}),

ab.NewRoundFrame(am,"Shadow-sm",{



ImageColor3=Color3.new(0,0,0),
Size=UDim2.new(1,3,1,3),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Shadow",

ImageTransparency=1,
Visible=not ak,
}),

ab.NewRoundFrame(am,"SquircleGlass",{
ThemeTag={
ImageColor3="White",
},
Size=UDim2.new(1,1,1,1),

ImageTransparency=0.9,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Outline",
},{













}),

ab.NewRoundFrame(am,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Frame",
ThemeTag={
ImageColor3=ah~="White"and"Text"or nil,
},
ImageColor3=ah=="White"and Color3.new(0,0,0)or nil,
ImageTransparency=1,
},{
ac("UIPadding",{
PaddingLeft=UDim.new(0,16),
PaddingRight=UDim.new(0,16),
}),
ac("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,8),
VerticalAlignment="Center",
HorizontalAlignment="Center",
}),
an,
ac("TextLabel",{
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.SemiBold),
Text=ae or"Button",
ThemeTag={
TextColor3=(ah~="Primary"and ah~="White")and"Text",
},
TextColor3=ah=="Primary"and Color3.new(1,1,1)
or ah=="White"and Color3.new(0,0,0)
or nil,
AutomaticSize="XY",
TextSize=18,
}),
}),
})

ab.AddSignal(ao.MouseEnter,function()
ad(ao.Frame,0.047,{ImageTransparency=0.95}):Play()
end)
ab.AddSignal(ao.MouseLeave,function()
ad(ao.Frame,0.047,{ImageTransparency=1}):Play()
end)
ab.AddSignal(ao.MouseButton1Click,function()
if aj then
aj:Close()()
end
if ag then
ab.SafeCallback(ag)
end
end)

return ao
end

return aa end function a.n()

local aa={}

local ab=a.load'd'
local ac=ab.New local ad=
ab.Tween

function aa.New(ae,af,ag,ah,ai,aj,ak,al,am)
ah=ah or"Input"
local an=ak or 10
local ao
if af and af~=""then
ao=ac("ImageLabel",{
Image=ab.Icon(af)[1],
ImageRectSize=ab.Icon(af)[2].ImageRectSize,
ImageRectOffset=ab.Icon(af)[2].ImageRectPosition,
Size=UDim2.new(0,21,0,21),
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
})
end

local ap=ah=="Textarea"

local aq=ac("TextBox",{
BackgroundTransparency=1,
TextSize=17,
FontFace=Font.new(ab.Font,Enum.FontWeight.Regular),
Size=UDim2.new(1,ao and-29 or 0,1,0),
PlaceholderText=ae,
ClearTextOnFocus=al or false,
ClipsDescendants=true,
TextWrapped=ap,
MultiLine=ap,
TextXAlignment="Left",
TextYAlignment=ah~="Textarea"and"Center"or"Top",

ThemeTag={
PlaceholderColor3="PlaceholderText",
TextColor3="Text",
},
})

local ar=ac("Frame",{
Size=UDim2.new(1,0,0,42),
Parent=ag,
BackgroundTransparency=1,
},{
ac("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ab.NewRoundFrame(an,"Squircle",{
ThemeTag={
ImageColor3="Placeholder",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
}),
not am and ab.NewRoundFrame(an-1,"SquircleGlass",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,1,1,1),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ImageTransparency=0.8,
})or nil,
ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Frame",
ThemeTag={
ImageColor3="LabelBackground",
ImageTransparency="LabelBackgroundTransparency",
},


},{
ac("UIPadding",{
PaddingTop=UDim.new(0,ah~="Textarea"and 0 or 12),
PaddingLeft=UDim.new(0,12),
PaddingRight=UDim.new(0,12),
PaddingBottom=UDim.new(0,ah~="Textarea"and 0 or 12),
}),
ac("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,8),
VerticalAlignment=ah~="Textarea"and"Center"or"Top",
HorizontalAlignment="Left",
}),
ao,
aq,
}),
}),
})










if aj then
ab.AddSignal(aq:GetPropertyChangedSignal"Text",function()
if ai then
ab.SafeCallback(ai,aq.Text)
end
end)
else
ab.AddSignal(aq.FocusLost,function()
if ai then
ab.SafeCallback(ai,aq.Text)
end
end)
end

return ar
end

return aa end function a.o()

local aa=a.load'd'
local ab=aa.New
local ac=aa.Tween




local ad={
Holder=nil,

Parent=nil,
}

function ad.Create(ae,af,ag,ah,ai)
local aj={
UICorner=28,
UIPadding=12,

Window=ag,
WindUI=ah,

UIElements={},
}

if ae then
aj.UIPadding=0
end
if ae then
aj.UICorner=26
end

af=af or"Dialog"

if not ae then
aj.UIElements.FullScreen=ab("Frame",{
ZIndex=999,
BackgroundTransparency=1,
BackgroundColor3=Color3.fromHex"#000000",
Size=UDim2.new(1,0,1,0),
Active=false,
Visible=false,
Parent=ad.Parent
or(ag and ag.UIElements and ag.UIElements.Main and ag.UIElements.Main.Main),
},{
ab("UICorner",{
CornerRadius=UDim.new(0,ag.UICorner),
}),
})
end

ab("ImageLabel",{
Image="rbxassetid://8992230677",
ThemeTag={
ImageColor3="WindowShadow",

},
ImageTransparency=1,
Size=UDim2.new(1,100,1,100),
Position=UDim2.new(0,-50,0,-50),
ScaleType="Slice",
SliceCenter=Rect.new(99,99,99,99),
BackgroundTransparency=1,
ZIndex=-999999999999999,
Name="Blur",
})

aj.UIElements.Main=ab("Frame",{
Size=UDim2.new(0,280,0,0),
ThemeTag={
BackgroundColor3=af.."Background",
},
AutomaticSize="Y",
BackgroundTransparency=1,
Visible=false,
ZIndex=99999,
},{
ab("UIPadding",{
PaddingTop=UDim.new(0,aj.UIPadding),
PaddingLeft=UDim.new(0,aj.UIPadding),
PaddingRight=UDim.new(0,aj.UIPadding),
PaddingBottom=UDim.new(0,aj.UIPadding),
}),
})

aj.UIElements.MainContainer=aa.NewRoundFrame(aj.UICorner,"Squircle",{
Visible=false,

ImageTransparency=ae and 0.15 or 0,
Parent=ai or aj.UIElements.FullScreen,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
AutomaticSize="XY",
ThemeTag={
ImageColor3=af.."Background",
ImageTransparency=af.."BackgroundTransparency",
},
ZIndex=9999,
},{






aj.UIElements.Main,




















})

function aj.Open(ak)
if not ae then
aj.UIElements.FullScreen.Visible=true
aj.UIElements.FullScreen.Active=true
end

task.spawn(function()
aj.UIElements.MainContainer.Visible=true

if not ae then
ac(aj.UIElements.FullScreen,0.1,{BackgroundTransparency=0.65}):Play()
end
ac(aj.UIElements.MainContainer,0.1,{ImageTransparency=0}):Play()


task.spawn(function()
task.wait(0.05)
aj.UIElements.Main.Visible=true
end)
end)
end
function aj.Close(ak)
if not ae then
ac(aj.UIElements.FullScreen,0.1,{BackgroundTransparency=1}):Play()
aj.UIElements.FullScreen.Active=false
task.spawn(function()
task.wait(0.1)
aj.UIElements.FullScreen.Visible=false
end)
end
aj.UIElements.Main.Visible=false

ac(aj.UIElements.MainContainer,0.1,{ImageTransparency=1}):Play()



task.spawn(function()
task.wait(0.1)
if not ae then
aj.UIElements.FullScreen:Destroy()
else
aj.UIElements.MainContainer:Destroy()
end
end)

return function()end
end


return aj
end

return ad end function a.p()

local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween

local ae=a.load'm'.New
local af=a.load'n'.New

function aa.new(ag,ah,ai,aj)
local ak=a.load'o'
local al=ak.Create(true,"Popup",ag.Window,ag.WindUI,ag.WindUI.ScreenGui.KeySystem)

local am={}

local an

local ao=(ag.KeySystem.Thumbnail and ag.KeySystem.Thumbnail.Width)or 200

local ap=430
if ag.KeySystem.Thumbnail and ag.KeySystem.Thumbnail.Image then
ap=430+(ao/2)
end

al.UIElements.Main.AutomaticSize="Y"
al.UIElements.Main.Size=UDim2.new(0,ap,0,0)

local aq

if ag.Icon then
aq=
ab.Image(ag.Icon,ag.Title..":"..ag.Icon,0,"Temp","KeySystem",ag.IconThemed)
aq.Size=UDim2.new(0,24,0,24)
aq.LayoutOrder=-1
end

local ar=ac("TextLabel",{
AutomaticSize="XY",
BackgroundTransparency=1,
Text=ag.KeySystem.Title or ag.Title,
FontFace=Font.new(ab.Font,Enum.FontWeight.SemiBold),
ThemeTag={
TextColor3="Text",
},
TextSize=20,
})

local as=ac("TextLabel",{
AutomaticSize="XY",
BackgroundTransparency=1,
Text="Key System",
AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,0,0.5,0),
TextTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
ThemeTag={
TextColor3="Text",
},
TextSize=16,
})

local at=ac("Frame",{
BackgroundTransparency=1,
AutomaticSize="XY",
},{
ac("UIListLayout",{
Padding=UDim.new(0,14),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
aq,
ar,
})

local au=ac("Frame",{
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
},{





at,
as,
})

local av=af("Enter Key","key",nil,"Input",function(av)
an=av
end)

local aw
if ag.KeySystem.Note and ag.KeySystem.Note~=""then
aw=ac("TextLabel",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
TextXAlignment="Left",
Text=ag.KeySystem.Note,
TextSize=18,
TextTransparency=0.4,
ThemeTag={
TextColor3="Text",
},
BackgroundTransparency=1,
RichText=true,
TextWrapped=true,
})
end

local ax=ac("Frame",{
Size=UDim2.new(1,0,0,42),
BackgroundTransparency=1,
},{
ac("Frame",{
BackgroundTransparency=1,
AutomaticSize="X",
Size=UDim2.new(0,0,1,0),
},{
ac("UIListLayout",{
Padding=UDim.new(0,9),
FillDirection="Horizontal",
}),
}),
})

local ay
if ag.KeySystem.Thumbnail and ag.KeySystem.Thumbnail.Image then
local az
if ag.KeySystem.Thumbnail.Title then
az=ac("TextLabel",{
Text=ag.KeySystem.Thumbnail.Title,
ThemeTag={
TextColor3="Text",
},
TextSize=18,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
AutomaticSize="XY",
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
})
end
ay=ac("ImageLabel",{
Image=ag.KeySystem.Thumbnail.Image,
BackgroundTransparency=1,
Size=UDim2.new(0,ao,1,-12),
Position=UDim2.new(0,6,0,6),
Parent=al.UIElements.Main,
ScaleType="Crop",
},{
az,
ac("UICorner",{
CornerRadius=UDim.new(0,20),
}),
})
end

ac("Frame",{

Size=UDim2.new(1,ay and-ao or 0,1,0),
Position=UDim2.new(0,ay and ao or 0,0,0),
BackgroundTransparency=1,
Parent=al.UIElements.Main,
},{
ac("Frame",{

Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ac("UIListLayout",{
Padding=UDim.new(0,18),
FillDirection="Vertical",
}),
au,
aw,
av,
ax,
ac("UIPadding",{
PaddingTop=UDim.new(0,16),
PaddingLeft=UDim.new(0,16),
PaddingRight=UDim.new(0,16),
PaddingBottom=UDim.new(0,16),
}),
}),
})





local az=ae("Exit","log-out",function()
al:Close()()
end,"Tertiary",ax.Frame)

if ay then
az.Parent=ay
az.Size=UDim2.new(0,0,0,42)
az.Position=UDim2.new(0,10,1,-10)
az.AnchorPoint=Vector2.new(0,1)
end

if ag.KeySystem.URL then
ae("Get key","key",function()
setclipboard(ag.KeySystem.URL)
end,"Secondary",ax.Frame)
end

if ag.KeySystem.API then








local aA=240
local aB=false
local b=ae("Get key","key",nil,"Secondary",ax.Frame)

local d=ab.NewRoundFrame(99,"Squircle",{
Size=UDim2.new(0,1,1,0),
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=0.9,
})

ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(0,0,1,0),
AutomaticSize="X",
Parent=b.Frame,
},{
d,
ac("UIPadding",{
PaddingLeft=UDim.new(0,5),
PaddingRight=UDim.new(0,5),
}),
})

local f=ab.Image("chevron-down","chevron-down",0,"Temp","KeySystem",true)

f.Size=UDim2.new(1,0,1,0)

ac("Frame",{
Size=UDim2.new(0,21,0,21),
Parent=b.Frame,
BackgroundTransparency=1,
},{
f,
})

local g=ab.NewRoundFrame(15,"Squircle",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
ThemeTag={
ImageColor3="Background",
},
},{
ac("UIPadding",{
PaddingTop=UDim.new(0,5),
PaddingLeft=UDim.new(0,5),
PaddingRight=UDim.new(0,5),
PaddingBottom=UDim.new(0,5),
}),
ac("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,5),
}),
})

local h=ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(0,aA,0,0),
ClipsDescendants=true,
AnchorPoint=Vector2.new(1,0),
Parent=b,
Position=UDim2.new(1,0,1,15),
},{
g,
})

ac("TextLabel",{
Text="Select Service",
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
ThemeTag={TextColor3="Text"},
TextTransparency=0.2,
TextSize=16,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
TextWrapped=true,
TextXAlignment="Left",
Parent=g,
},{
ac("UIPadding",{
PaddingTop=UDim.new(0,10),
PaddingLeft=UDim.new(0,10),
PaddingRight=UDim.new(0,10),
PaddingBottom=UDim.new(0,10),
}),
})

for i,l in next,ag.KeySystem.API do
local m=ag.WindUI.Services[l.Type]
if m then
local p={}
for r,u in next,m.Args do
table.insert(p,l[u])
end

local r=m.New(table.unpack(p))
r.Type=l.Type
table.insert(am,r)

local u=ab.Image(
l.Icon or m.Icon or Icons[l.Type]or"user",
l.Icon or m.Icon or Icons[l.Type]or"user",
0,
"Temp",
"KeySystem",
true
)
u.Size=UDim2.new(0,24,0,24)

local v=ab.NewRoundFrame(10,"Squircle",{
Size=UDim2.new(1,0,0,0),
ThemeTag={ImageColor3="Text"},
ImageTransparency=1,
Parent=g,
AutomaticSize="Y",
},{
ac("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,10),
VerticalAlignment="Center",
}),
u,
ac("UIPadding",{
PaddingTop=UDim.new(0,10),
PaddingLeft=UDim.new(0,10),
PaddingRight=UDim.new(0,10),
PaddingBottom=UDim.new(0,10),
}),
ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,-34,0,0),
AutomaticSize="Y",
},{
ac("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,5),
HorizontalAlignment="Center",
}),
ac("TextLabel",{
Text=l.Title or m.Name,
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
ThemeTag={TextColor3="Text"},
TextTransparency=0.05,
TextSize=18,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
TextWrapped=true,
TextXAlignment="Left",
}),
ac("TextLabel",{
Text=l.Desc or"",
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Regular),
ThemeTag={TextColor3="Text"},
TextTransparency=0.2,
TextSize=16,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
TextWrapped=true,
Visible=l.Desc and true or false,
TextXAlignment="Left",
}),
}),
},true)

ab.AddSignal(v.MouseEnter,function()
ad(v,0.08,{ImageTransparency=0.95}):Play()
end)
ab.AddSignal(v.InputEnded,function()
ad(v,0.08,{ImageTransparency=1}):Play()
end)
ab.AddSignal(v.MouseButton1Click,function()
r.Copy()
ag.WindUI:Notify{
Title="Key System",
Content="Key link copied to clipboard.",
Image="key",
}
end)
end
end

ab.AddSignal(b.MouseButton1Click,function()
if not aB then
ad(
h,
0.3,
{Size=UDim2.new(0,aA,0,g.AbsoluteSize.Y+1)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ad(f,0.3,{Rotation=180},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
else
ad(
h,
0.25,
{Size=UDim2.new(0,aA,0,0)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ad(f,0.25,{Rotation=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
aB=not aB
end)
end

local function handleSuccess(aA)
al:Close()()
writefile((ag.Folder or"Temp").."/"..ah..".key",tostring(aA))
task.wait(0.4)
ai(true)
end

local aA=ae("Submit","arrow-right",function()
local aA=tostring(an or"empty")local aB=
ag.Folder or ag.Title

if ag.KeySystem.KeyValidator then
local b=ag.KeySystem.KeyValidator(aA)

if b then
if ag.KeySystem.SaveKey then
handleSuccess(aA)
else
al:Close()()
task.wait(0.4)
ai(true)
end
else
ag.WindUI:Notify{
Title="Key System. Error",
Content="Invalid key.",
Icon="triangle-alert",
}
end
elseif not ag.KeySystem.API then
local b=type(ag.KeySystem.Key)=="table"and table.find(ag.KeySystem.Key,aA)
or ag.KeySystem.Key==aA

if b then
if ag.KeySystem.SaveKey then
handleSuccess(aA)
else
al:Close()()
task.wait(0.4)
ai(true)
end
end
else
local b,d
for f,g in next,am do
local h,i=g.Verify(aA)
if h then
b,d=true,i
break
end
d=i
end

if b then
handleSuccess(aA)
else
ag.WindUI:Notify{
Title="Key System. Error",
Content=d,
Icon="triangle-alert",
}
end
end
end,"Primary",ax)

aA.AnchorPoint=Vector2.new(1,0.5)
aA.Position=UDim2.new(1,0,0.5,0)










al:Open()
end

return aa end function a.q()




local aa=(cloneref or clonereference or function(aa)return aa end)


local function map(ab,ac,ad,ae,af)
return(ab-ac)*(af-ae)/(ad-ac)+ae
end

local function viewportPointToWorld(ab,ac)
local ad=aa(game:GetService"Workspace").CurrentCamera:ScreenPointToRay(ab.X,ab.Y)
return ad.Origin+ad.Direction*ac
end

local function getOffset()
local ab=aa(game:GetService"Workspace").CurrentCamera.ViewportSize.Y
return map(ab,0,2560,8,56)
end

return{viewportPointToWorld,getOffset}end function a.r()



local aa=(cloneref or clonereference or function(aa)return aa end)


local ab=a.load'd'
local ac=ab.New


local ad,ae=unpack(a.load'q')
local af=Instance.new("Folder",aa(game:GetService"Workspace").CurrentCamera)


local function createAcrylic()
local ag=ac("Part",{
Name="Body",
Color=Color3.new(0,0,0),
Material=Enum.Material.Glass,
Size=Vector3.new(1,1,0),
Anchored=true,
CanCollide=false,
Locked=true,
CastShadow=false,
Transparency=0.98,
},{
ac("SpecialMesh",{
MeshType=Enum.MeshType.Brick,
Offset=Vector3.new(0,0,-1E-6),
}),
})

return ag
end


local function createAcrylicBlur(ag)
local ah={}

ag=ag or 0.001
local ai={
topLeft=Vector2.new(),
topRight=Vector2.new(),
bottomRight=Vector2.new(),
}
local aj=createAcrylic()
aj.Parent=af

local function updatePositions(ak,al)
ai.topLeft=al
ai.topRight=al+Vector2.new(ak.X,0)
ai.bottomRight=al+ak
end

local function render()
local ak=aa(game:GetService"Workspace").CurrentCamera
if ak then
ak=ak.CFrame
end
local al=ak
if not al then
al=CFrame.new()
end

local am=al
local an=ai.topLeft
local ao=ai.topRight
local ap=ai.bottomRight

local aq=ad(an,ag)
local ar=ad(ao,ag)
local as=ad(ap,ag)

local at=(ar-aq).Magnitude
local au=(ar-as).Magnitude

aj.CFrame=
CFrame.fromMatrix((aq+as)/2,am.XVector,am.YVector,am.ZVector)
aj.Mesh.Scale=Vector3.new(at,au,0)
end

local function onChange(ak)
local al=ae()
local am=ak.AbsoluteSize-Vector2.new(al,al)
local an=ak.AbsolutePosition+Vector2.new(al/2,al/2)

updatePositions(am,an)
task.spawn(render)
end

local function renderOnChange()
local ak=aa(game:GetService"Workspace").CurrentCamera
if not ak then
return
end

table.insert(ah,ak:GetPropertyChangedSignal"CFrame":Connect(render))
table.insert(ah,ak:GetPropertyChangedSignal"ViewportSize":Connect(render))
table.insert(ah,ak:GetPropertyChangedSignal"FieldOfView":Connect(render))
task.spawn(render)
end

aj.Destroying:Connect(function()
for ak,al in ah do
pcall(function()
al:Disconnect()
end)
end
end)

renderOnChange()

return onChange,aj
end

return function(ag)
local ah={}
local ai,aj=createAcrylicBlur(ag)

local ak=ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
})

ab.AddSignal(ak:GetPropertyChangedSignal"AbsolutePosition",function()
ai(ak)
end)

ab.AddSignal(ak:GetPropertyChangedSignal"AbsoluteSize",function()
ai(ak)
end)

ah.AddParent=function(al)
ab.AddSignal(al:GetPropertyChangedSignal"Visible",function()

end)
end

ah.SetVisibility=function(al)
aj.Transparency=al and 0.98 or 1
end

ah.Frame=ak
ah.Model=aj

return ah
end end function a.s()


local aa=a.load'd'
local ab=a.load'r'

local ac=aa.New

return function(ad)
local ae={}

ae.Frame=ac("Frame",{
Size=UDim2.fromScale(1,1),
BackgroundTransparency=1,
BackgroundColor3=Color3.fromRGB(255,255,255),
BorderSizePixel=0,
},{












ac("UICorner",{
CornerRadius=UDim.new(0,8),
}),

ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
Name="Background",
ThemeTag={
BackgroundColor3="AcrylicMain",
},
},{
ac("UICorner",{
CornerRadius=UDim.new(0,8),
}),
}),

ac("Frame",{
BackgroundColor3=Color3.fromRGB(255,255,255),
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
},{










}),

ac("ImageLabel",{
Image="rbxassetid://9968344105",
ImageTransparency=0.98,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.new(0,128,0,128),
Size=UDim2.fromScale(1,1),
BackgroundTransparency=1,
},{
ac("UICorner",{
CornerRadius=UDim.new(0,8),
}),
}),

ac("ImageLabel",{
Image="rbxassetid://9968344227",
ImageTransparency=0.9,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.new(0,128,0,128),
Size=UDim2.fromScale(1,1),
BackgroundTransparency=1,
ThemeTag={
ImageTransparency="AcrylicNoise",
},
},{
ac("UICorner",{
CornerRadius=UDim.new(0,8),
}),
}),

ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
ZIndex=2,
},{










}),
})


local af

task.wait()
if ad.UseAcrylic then
af=ab()

af.Frame.Parent=ae.Frame
ae.Model=af.Model
ae.AddParent=af.AddParent
ae.SetVisibility=af.SetVisibility
end

return ae,af
end end function a.t()



local aa=(cloneref or clonereference or function(aa)return aa end)


local ab={
AcrylicBlur=a.load'r',

AcrylicPaint=a.load's',
}

function ab.init()
local ac=Instance.new"DepthOfFieldEffect"
ac.FarIntensity=0
ac.InFocusRadius=0.1
ac.NearIntensity=1

local ad={}

function ab.Enable()
for ae,af in pairs(ad)do
af.Enabled=false
end
ac.Parent=aa(game:GetService"Lighting")
end

function ab.Disable()
for ae,af in pairs(ad)do
af.Enabled=af.enabled
end
ac.Parent=nil
end

local function registerDefaults()
local function register(ae)
if ae:IsA"DepthOfFieldEffect"then
ad[ae]={enabled=ae.Enabled}
end
end

for ae,af in pairs(aa(game:GetService"Lighting"):GetChildren())do
register(af)
end

if aa(game:GetService"Workspace").CurrentCamera then
for ae,af in pairs(aa(game:GetService"Workspace").CurrentCamera:GetChildren())do
register(af)
end
end
end

registerDefaults()
ab.Enable()
end

return ab end function a.u()

local aa={}

local ab=a.load'd'
local ac=ab.New local ad=
ab.Tween


function aa.new(ae,af)
local ag={
Title=ae.Title or"Dialog",
Content=ae.Content,
Icon=ae.Icon,
IconThemed=ae.IconThemed,
Thumbnail=ae.Thumbnail,
Buttons=ae.Buttons,

IconSize=22,
}

local ah=a.load'o'
local ai=ah.Create(true,"Popup",ae.WindUI.Window,ae.WindUI,af)

local aj=200

local ak=430
if ag.Thumbnail and ag.Thumbnail.Image then
ak=430+(aj/2)
end

ai.UIElements.Main.AutomaticSize="Y"
ai.UIElements.Main.Size=UDim2.new(0,ak,0,0)



local al

if ag.Icon then
al=ab.Image(
ag.Icon,
ag.Title..":"..ag.Icon,
0,
ae.WindUI.Window,
"Popup",
true,
ae.IconThemed,
"PopupIcon"
)
al.Size=UDim2.new(0,ag.IconSize,0,ag.IconSize)
al.LayoutOrder=-1
end


local am=ac("TextLabel",{
AutomaticSize="Y",
BackgroundTransparency=1,
Text=ag.Title,
TextXAlignment="Left",
FontFace=Font.new(ab.Font,Enum.FontWeight.SemiBold),
ThemeTag={
TextColor3="PopupTitle",
},
TextSize=20,
TextWrapped=true,
Size=UDim2.new(1,al and-ag.IconSize-14 or 0,0,0)
})

local an=ac("Frame",{
BackgroundTransparency=1,
AutomaticSize="XY",
},{
ac("UIListLayout",{
Padding=UDim.new(0,14),
FillDirection="Horizontal",
VerticalAlignment="Center"
}),
al,am
})

local ao=ac("Frame",{
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
},{





an,
})

local ap
if ag.Content and ag.Content~=""then
ap=ac("TextLabel",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
TextXAlignment="Left",
Text=ag.Content,
TextSize=18,
TextTransparency=.2,
ThemeTag={
TextColor3="PopupContent",
},
BackgroundTransparency=1,
RichText=true,
TextWrapped=true,
})
end

local aq=ac("Frame",{
Size=UDim2.new(1,0,0,42),
BackgroundTransparency=1,
},{
ac("UIListLayout",{
Padding=UDim.new(0,9),
FillDirection="Horizontal",
HorizontalAlignment="Right"
})
})

local ar
if ag.Thumbnail and ag.Thumbnail.Image then
local as
if ag.Thumbnail.Title then
as=ac("TextLabel",{
Text=ag.Thumbnail.Title,
ThemeTag={
TextColor3="Text",
},
TextSize=18,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
AutomaticSize="XY",
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
})
end
ar=ac("ImageLabel",{
Image=ag.Thumbnail.Image,
BackgroundTransparency=1,
Size=UDim2.new(0,aj,1,0),
Parent=ai.UIElements.Main,
ScaleType="Crop"
},{
as,
ac("UICorner",{
CornerRadius=UDim.new(0,0),
})
})
end

ac("Frame",{

Size=UDim2.new(1,ar and-aj or 0,1,0),
Position=UDim2.new(0,ar and aj or 0,0,0),
BackgroundTransparency=1,
Parent=ai.UIElements.Main
},{
ac("Frame",{

Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ac("UIListLayout",{
Padding=UDim.new(0,18),
FillDirection="Vertical",
}),
ao,
ap,
aq,
ac("UIPadding",{
PaddingTop=UDim.new(0,16),
PaddingLeft=UDim.new(0,16),
PaddingRight=UDim.new(0,16),
PaddingBottom=UDim.new(0,16),
})
}),
})

local as=a.load'm'.New

for at,au in next,ag.Buttons do
as(au.Title,au.Icon,au.Callback,au.Variant,aq,ai)
end

ai:Open()


return ag
end

return aa end function a.v()
return function(aa,ab)
return{
Dark={
Name="Dark",

Accent=Color3.fromHex"#18181b",
Dialog=Color3.fromHex"#1a1a1a",
Outline=Color3.fromHex"#FFFFFF",
Text=Color3.fromHex"#FFFFFF",
Placeholder=Color3.fromHex"#a1a1a1",
Background=Color3.fromHex"#101010",
Button=Color3.fromHex"#52525b",
Icon=Color3.fromHex"#a1a1aa",
Toggle=Color3.fromHex"#33C759",
Slider=Color3.fromHex"#0091FF",
Checkbox=Color3.fromHex"#0091FF",

PanelBackground=Color3.fromHex"#FFFFFF",
PanelBackgroundTransparency=0.95,

SliderIcon=Color3.fromHex"#908F95",
Primary=Color3.fromHex"#0091FF",


LabelBackground=Color3.fromHex"#000000",
LabelBackgroundTransparency=0.83,

ElementBackground=Color3.fromHex"#2A2A2C",
ElementBackgroundTransparency=0,
},

Light={
Name="Light",

Accent=Color3.fromHex"#efefef",
Dialog=Color3.fromHex"#f4f4f5",
Outline=Color3.fromHex"#ffffff",
Text=Color3.fromHex"#000000",
Placeholder=Color3.fromHex"#555555",
Background=Color3.fromHex"#FFFFFF",
Button=Color3.fromHex"#18181b",
Icon=Color3.fromHex"#52525b",
Toggle=Color3.fromHex"#33C759",
Slider=Color3.fromHex"#0091FF",
Checkbox=Color3.fromHex"#0091FF",

DropdownTabBackground=Color3.fromHex"#bebebe",
DropdownBackground=Color3.fromHex"#ffffff",

TabBackground=Color3.fromHex"#ffffff",
TabBackgroundHover=Color3.fromHex"#f3f3f3",
TabBackgroundHoverTransparency=0,
TabBackgroundActive=Color3.fromHex"#efefef",
TabBackgroundActiveTransparency=0,

PanelBackground=Color3.fromHex"#efefef",
PanelBackgroundTransparency=0,

LabelBackground=Color3.fromHex"#efefef",
LabelBackgroundTransparency=0,

ElementBackground=Color3.fromHex"#ffffff",
ElementBackgroundTransparency=0,
},

Rose={
Name="Rose",

Accent=Color3.fromHex"#be185d",
Dialog=Color3.fromHex"#4c0519",

Text=Color3.fromHex"#fdf2f8",
Placeholder=Color3.fromHex"#d67aa6",
Background=Color3.fromHex"#1f0308",
Button=Color3.fromHex"#e95f74",
Icon=Color3.fromHex"#fb7185",

ElementBackground=Color3.fromHex"#381E23",
ElementBackgroundTransparency=0,
},

Plant={
Name="Plant",

Accent=Color3.fromHex"#166534",
Dialog=Color3.fromHex"#052e16",

Text=Color3.fromHex"#f0fdf4",
Placeholder=Color3.fromHex"#4fbf7a",
Background=Color3.fromHex"#0a1b0f",
Button=Color3.fromHex"#16a34a",
Icon=Color3.fromHex"#4ade80",

ElementBackground=Color3.fromHex"#28342A",
ElementBackgroundTransparency=0,
},

Red={
Name="Red",

Accent=Color3.fromHex"#991b1b",
Dialog=Color3.fromHex"#450a0a",

Text=Color3.fromHex"#fef2f2",
Placeholder=Color3.fromHex"#d95353",
Background=Color3.fromHex"#1c0606",
Button=Color3.fromHex"#dc2626",
Icon=Color3.fromHex"#ef4444",

ElementBackground=Color3.fromHex"#322221",
ElementBackgroundTransparency=0,
},

Indigo={
Name="Indigo",

Accent=Color3.fromHex"#3730a3",
Dialog=Color3.fromHex"#1e1b4b",

Text=Color3.fromHex"#f1f5f9",
Placeholder=Color3.fromHex"#7078d9",
Background=Color3.fromHex"#0f0a2e",
Button=Color3.fromHex"#4f46e5",
Icon=Color3.fromHex"#6366f1",

ElementBackground=Color3.fromHex"#282543",
ElementBackgroundTransparency=0,
},

Sky={
Name="Sky",

Accent=Color3.fromHex"#00d4ff",
Dialog=Color3.fromHex"#0a4d66",

Text=Color3.fromHex"#e6f7ff",
Placeholder=Color3.fromHex"#66b3cc",
Background=Color3.fromHex"#051a26",
Button=Color3.fromHex"#00a8cc",
Icon=Color3.fromHex"#2db8d9",

Toggle=Color3.fromHex"#00d9d9",
Slider=Color3.fromHex"#00d4ff",
Checkbox=Color3.fromHex"#00d4ff",

PanelBackground=Color3.fromHex"#0d3a47",
PanelBackgroundTransparency=0.8,

ElementBackground=Color3.fromHex"#172E3B",
ElementBackgroundTransparency=0,
},

Violet={
Name="Violet",

Accent=Color3.fromHex"#6d28d9",
Dialog=Color3.fromHex"#3c1361",

Text=Color3.fromHex"#faf5ff",
Placeholder=Color3.fromHex"#8f7ee0",
Background=Color3.fromHex"#1e0a3e",
Button=Color3.fromHex"#7c3aed",
Icon=Color3.fromHex"#8b5cf6",

ElementBackground=Color3.fromHex"#342650",
ElementBackgroundTransparency=0,
},

Amber={
Name="Amber",

Accent=aa:Gradient({
["0"]={Color=Color3.fromHex"#b45309",Transparency=0},
["100"]={Color=Color3.fromHex"#d97706",Transparency=0},
},{Rotation=45}),

Dialog=aa:Gradient({
["0"]={Color=Color3.fromHex"#451a03",Transparency=0},
["100"]={Color=Color3.fromHex"#6b2e05",Transparency=0},
},{Rotation=90}),






Text=aa:Gradient({
["0"]={Color=Color3.fromHex"#fffbeb",Transparency=0},
["100"]={Color=Color3.fromHex"#fff7ed",Transparency=0},
},{Rotation=45}),

Placeholder=aa:Gradient({
["0"]={Color=Color3.fromHex"#d1a326",Transparency=0},
["100"]={Color=Color3.fromHex"#fbbf24",Transparency=0},
},{Rotation=45}),

Background=aa:Gradient({
["0"]={Color=Color3.fromHex"#1c1003",Transparency=0},
["100"]={Color=Color3.fromHex"#3f210d",Transparency=0},
},{Rotation=90}),

Button=aa:Gradient({
["0"]={Color=Color3.fromHex"#d97706",Transparency=0},
["100"]={Color=Color3.fromHex"#f59e0b",Transparency=0},
},{Rotation=45}),

Icon=Color3.fromHex"#f59e0b",

Toggle=aa:Gradient({
["0"]={Color=Color3.fromHex"#d97706",Transparency=0},
["100"]={Color=Color3.fromHex"#f59e0b",Transparency=0},
},{Rotation=45}),

Slider=Color3.fromHex"#d97706",

Checkbox=aa:Gradient({
["0"]={Color=Color3.fromHex"#d97706",Transparency=0},
["100"]={Color=Color3.fromHex"#fbbf24",Transparency=0},
},{Rotation=45}),

PanelBackground=Color3.fromHex"#FFFFFF",
PanelBackgroundTransparency=0.95,

ElementBackground=Color3.fromHex"#3A2E22",
ElementBackgroundTransparency=0,
},

Emerald={
Name="Emerald",

Accent=Color3.fromHex"#047857",
Dialog=Color3.fromHex"#022c22",

Text=Color3.fromHex"#ecfdf5",
Placeholder=Color3.fromHex"#3fbf8f",
Background=Color3.fromHex"#011411",
Button=Color3.fromHex"#059669",
Icon=Color3.fromHex"#10b981",

ElementBackground=Color3.fromHex"#202E2A",
ElementBackgroundTransparency=0,
},

Midnight={
Name="Midnight",

Accent=Color3.fromHex"#1e3a8a",
Dialog=Color3.fromHex"#0c1e42",

Text=Color3.fromHex"#dbeafe",
Placeholder=Color3.fromHex"#2f74d1",
Background=Color3.fromHex"#0a0f1e",
Button=Color3.fromHex"#2563eb",
Primary=Color3.fromHex"#2563eb",
Icon=Color3.fromHex"#5591f4",

ElementBackground=Color3.fromHex"#242836",
ElementBackgroundTransparency=0,
},

Crimson={
Name="Crimson",

Accent=Color3.fromHex"#b91c1c",
Dialog=Color3.fromHex"#450a0a",

Text=Color3.fromHex"#fef2f2",
Placeholder=Color3.fromHex"#6f757b",
Background=Color3.fromHex"#0c0404",
Button=Color3.fromHex"#991b1b",
Icon=Color3.fromHex"#dc2626",

ElementBackground=Color3.fromHex"#251F1F",
ElementBackgroundTransparency=0,
},

MonokaiPro={
Name="Monokai Pro",

Accent=Color3.fromHex"#fc9867",
Dialog=Color3.fromHex"#1e1e1e",

Text=Color3.fromHex"#fcfcfa",
Placeholder=Color3.fromHex"#afafaf",
Background=Color3.fromHex"#191622",
Button=Color3.fromHex"#ab9df2",
Icon=Color3.fromHex"#a9dc76",

ElementBackground=Color3.fromHex"#323039",
ElementBackgroundTransparency=0,

Metadata={
PullRequest=23,
},
},

CottonCandy={
Name="Cotton Candy",

Accent=Color3.fromHex"#ec4899",
Dialog=Color3.fromHex"#2d1b3d",

Text=Color3.fromHex"#fdf2f8",
Placeholder=Color3.fromHex"#8a5fd3",
Background=Color3.fromHex"#1a0b2e",
Button=Color3.fromHex"#d946ef",
Slider=Color3.fromHex"#d946ef",
Icon=Color3.fromHex"#06b6d4",

ElementBackground=Color3.fromHex"#312643",
ElementBackgroundTransparency=0,
},

Mellowsi={
Name="Mellowsi",

Accent=Color3.fromHex"#342A1E",
Dialog=Color3.fromHex"#291C13",

Text=Color3.fromHex"#F5EBDD",
Placeholder=Color3.fromHex"#9C8A73",
Background=Color3.fromHex"#1C1002",
Button=Color3.fromHex"#342A1E",
Icon=Color3.fromHex"#C9B79C",

Toggle=Color3.fromHex"#a9873f",
Slider=Color3.fromHex"#C9A24D",
Checkbox=Color3.fromHex"#C9A24D",

ElementBackground=Color3.fromHex"#33291E",
ElementBackgroundTransparency=0,

Metadata={
PullRequest=52,
},
},

Rainbow={
Name="Rainbow",

Accent=aa:Gradient({
["0"]={Color=Color3.fromHex"#00ff41",Transparency=0},
["33"]={Color=Color3.fromHex"#00ffff",Transparency=0},
["66"]={Color=Color3.fromHex"#0080ff",Transparency=0},
["100"]={Color=Color3.fromHex"#8000ff",Transparency=0},
},{Rotation=45}),

Dialog=aa:Gradient({
["0"]={Color=Color3.fromHex"#ff0080",Transparency=0},
["25"]={Color=Color3.fromHex"#8000ff",Transparency=0},
["50"]={Color=Color3.fromHex"#0080ff",Transparency=0},
["75"]={Color=Color3.fromHex"#00ff80",Transparency=0},
["100"]={Color=Color3.fromHex"#ff8000",Transparency=0},
},{Rotation=135}),


Text=Color3.fromHex"#ffffff",
Placeholder=Color3.fromHex"#00ff80",

Background=aa:Gradient({
["0"]={Color=Color3.fromHex"#ff0040",Transparency=0},
["20"]={Color=Color3.fromHex"#ff4000",Transparency=0},
["40"]={Color=Color3.fromHex"#ffff00",Transparency=0},
["60"]={Color=Color3.fromHex"#00ff40",Transparency=0},
["80"]={Color=Color3.fromHex"#0040ff",Transparency=0},
["100"]={Color=Color3.fromHex"#4000ff",Transparency=0},
},{Rotation=90}),

Button=aa:Gradient({
["0"]={Color=Color3.fromHex"#ff0080",Transparency=0},
["25"]={Color=Color3.fromHex"#ff8000",Transparency=0},
["50"]={Color=Color3.fromHex"#ffff00",Transparency=0},
["75"]={Color=Color3.fromHex"#80ff00",Transparency=0},
["100"]={Color=Color3.fromHex"#00ffff",Transparency=0},
},{Rotation=60}),

Icon=Color3.fromHex"#ffffff",
},
}
end end function a.w()

local aa={}

local ab=a.load'd'
local ac=ab.New local ad=
ab.Tween

function aa.New(ae,af,ag,ah,ai,aj)
local ak=ai or 10
local al
if af and af~=""then
al=ac("ImageLabel",{
Image=ab.Icon(af)[1],
ImageRectSize=ab.Icon(af)[2].ImageRectSize,
ImageRectOffset=ab.Icon(af)[2].ImageRectPosition,
Size=UDim2.new(0,21,0,21),
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
})
end

local am=ac("TextLabel",{
BackgroundTransparency=1,
TextSize=17,
FontFace=Font.new(ab.Font,Enum.FontWeight.Regular),
Size=UDim2.new(1,al and-29 or 0,1,0),
TextXAlignment="Left",
ThemeTag={
TextColor3=ah and"Placeholder"or"Text",
},
Text=ae,
})

local an=ac("TextButton",{
Size=UDim2.new(1,0,0,42),
Parent=ag,
BackgroundTransparency=1,
Text="",
},{
ac("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ab.NewRoundFrame(ak,"Squircle",{
ThemeTag={
ImageColor3="Placeholder",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
}),
not aj and ab.NewRoundFrame(ak,"SquircleGlass",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,1,1,1),
ImageTransparency=0.9,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
})or nil,
ab.NewRoundFrame(ak,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Frame",
ThemeTag={
ImageColor3="LabelBackground",
ImageTransparency="LabelBackgroundTransparency",
},


},{
ac("UIPadding",{
PaddingLeft=UDim.new(0,12),
PaddingRight=UDim.new(0,12),
}),
ac("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,8),
VerticalAlignment="Center",
HorizontalAlignment="Left",
}),
al,
am,
}),
}),
})

return an
end

return aa end function a.x()

local aa={}

local ab=cloneref or clonereference or function(ab)
return ab
end
local ac=ab(game:GetService"UserInputService")

local ad=a.load'd'
local ae=ad.New

function aa.New(af,ag,ah,ai,aj)
local ak=ae("Frame",{
Size=UDim2.new(0,ai,1,0),
BackgroundTransparency=1,
Position=UDim2.new(1,0,0,0),
AnchorPoint=Vector2.new(1,0),
Parent=ag,
ZIndex=999,
Active=true,
})

local al=ad.NewRoundFrame(ai/2,"Squircle",{
Size=UDim2.new(1,0,0,0),
ImageTransparency=0.85,
ThemeTag={ImageColor3="Text"},
Parent=ak,
})

local am=ae("Frame",{
Size=UDim2.new(1,12,1,12),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
BackgroundTransparency=1,
Active=true,
ZIndex=999,
Parent=al,
})

local an=ad:GenerateUniqueID()
local ao=false
local ap,aq

local function UpdateVisuals()
local ar=af.AbsoluteCanvasSize.Y
local as=af.AbsoluteWindowSize.Y

if ar<=as then
al.Visible=false
return
end

al.Visible=true

local at=math.clamp(as/ar,0.05,1)
al.Size=UDim2.new(1,0,at,0)

local au=ar-as
local av=1-at

if au>0 then
local aw=af.CanvasPosition.Y/au
al.Position=UDim2.new(0,0,math.clamp(aw*av,0,av),0)
else
al.Position=UDim2.new(0,0,0,0)
end
end

local function StopDrag()
if aj.CurrentInput==an then
aj.CurrentInput=nil
end
ao=false
af.ScrollingEnabled=true
if ap then
ap:Disconnect()
end
if aq then
aq:Disconnect()
end
end

ad.AddSignal(am.InputBegan,function(ar)
if
ar.UserInputType~=Enum.UserInputType.MouseButton1
and ar.UserInputType~=Enum.UserInputType.Touch
then
return
end
if ao then
return
end
if aj.CurrentInput and aj.CurrentInput~=an then
return
end

aj.CurrentInput=an

ao=true
af.ScrollingEnabled=false

local as=ar.Position.Y
local at=af.CanvasPosition.Y

ap=ac.InputChanged:Connect(function(au)
if
au.UserInputType==Enum.UserInputType.MouseMovement
or au.UserInputType==Enum.UserInputType.Touch
then
local av=au.Position.Y-as

local aw=af.AbsoluteCanvasSize.Y
local ax=af.AbsoluteWindowSize.Y
local ay=math.max(aw-ax,0)

local az=ak.AbsoluteSize.Y
local aA=al.AbsoluteSize.Y
local aB=math.max(az-aA,1)

local b=av*(ay/aB)

af.CanvasPosition=
Vector2.new(af.CanvasPosition.X,math.clamp(at+b,0,ay))
end
end)

aq=ac.InputEnded:Connect(function(au)
if au.UserInputType==ar.UserInputType then
if aj.CurrentInput and aj.CurrentInput~=an then
return
end

aj.CurrentInput=nil

StopDrag()
end
end)
end)

ad.AddSignal(af:GetPropertyChangedSignal"AbsoluteWindowSize",UpdateVisuals)
ad.AddSignal(af:GetPropertyChangedSignal"AbsoluteCanvasSize",UpdateVisuals)
ad.AddSignal(af:GetPropertyChangedSignal"CanvasPosition",UpdateVisuals)

UpdateVisuals()

return ak
end

return aa end function a.y()

local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween

function aa.New(ae,af,ag)
local ah={
Title=af.Title or"Tag",
Icon=af.Icon,
Color=af.Color or Color3.fromHex"#315dff",
Radius=af.Radius or 999,
Border=af.Border or false,

TagFrame=nil,
Height=26,
Padding=10,
TextSize=14,
IconSize=16,
}

local ai
if ah.Icon then
ai=ab.Image(ah.Icon,ah.Icon,0,af.Window,"Tag",false)

ai.Size=UDim2.new(0,ah.IconSize,0,ah.IconSize)
ai.ImageLabel.ImageColor3=typeof(ah.Color)=="Color3"
and ab.GetTextColorForHSB(ah.Color)
or typeof(ah.Color)=="string"
and(ab.GetTextColorForHSB(ab.GetThemeProperty(ah.Color,ab.Theme)))
end

local aj=ac("TextLabel",{
BackgroundTransparency=1,
AutomaticSize="XY",
TextSize=ah.TextSize,
FontFace=Font.new(ab.Font,Enum.FontWeight.SemiBold),
Text=ah.Title,
TextColor3=typeof(ah.Color)=="Color3"and ab.GetTextColorForHSB(ah.Color)or typeof(
ah.Color
)=="string"and(ab.GetTextColorForHSB(ab.GetThemeProperty(ah.Color,ab.Theme))),
})

local ak

if typeof(ah.Color)=="table"then
ak=ac"UIGradient"
for al,am in next,ah.Color do
ak[al]=am
end

aj.TextColor3=ab.GetTextColorForHSB(ab.GetAverageColor(ak))
if ai then
ai.ImageLabel.ImageColor3=ab.GetTextColorForHSB(ab.GetAverageColor(ak))
end
end

local al=ab.NewRoundFrame(ah.Radius,"Squircle",{
AutomaticSize="X",
Size=UDim2.new(0,0,0,ah.Height),
Parent=ag,
ImageColor3=typeof(ah.Color)=="Color3"and ah.Color
or typeof(ah.Color)=="table"and Color3.new(1,1,1)
or nil,
ThemeTag=typeof(ah.Color)=="string"and{
ImageColor3=ah.Color,
},
},{
ak,
ab.NewRoundFrame(ah.Radius+1,"SquircleGlass",{
Size=UDim2.new(1,1,1,1),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ThemeTag={
ImageColor3="White",
},
ImageTransparency=0.75,
}),
ac("Frame",{
Size=UDim2.new(0,0,1,0),
AutomaticSize="X",
Name="Content",
BackgroundTransparency=1,
},{
ai,
aj,
ac("UIPadding",{
PaddingLeft=UDim.new(0,ah.Padding),
PaddingRight=UDim.new(0,ah.Padding),
}),
ac("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
Padding=UDim.new(0,ah.Padding/1.5),
}),
}),
})

function ah.SetTitle(am,an)
ah.Title=an
aj.Text=an

return ah
end

function ah.SetColor(am,an)
ah.Color=an
if typeof(an)=="table"then
local ao=ab.GetAverageColor(an)
ad(aj,0.06,{TextColor3=ab.GetTextColorForHSB(ao)}):Play()
local ap=al:FindFirstChildOfClass"UIGradient"or ac("UIGradient",{Parent=al})
for aq,ar in next,an do
ap[aq]=ar
end
ad(al,0.06,{ImageColor3=Color3.new(1,1,1)}):Play()
else
if ak then
ak:Destroy()
end
ad(aj,0.06,{TextColor3=ab.GetTextColorForHSB(an)}):Play()
if ai then
ad(ai.ImageLabel,0.06,{ImageColor3=ab.GetTextColorForHSB(an)}):Play()
end
ad(al,0.06,{ImageColor3=an}):Play()
end

return ah
end

function ah.SetIcon(am,an)
ah.Icon=an

if an then
ai=ab.Image(an,an,0,af.Window,"Tag",false)

ai.Size=UDim2.new(0,ah.IconSize,0,ah.IconSize)
ai.Parent=al

if typeof(ah.Color)=="Color3"then
ai.ImageLabel.ImageColor3=ab.GetTextColorForHSB(ah.Color)
elseif typeof(ah.Color)=="table"then
ai.ImageLabel.ImageColor3=ab.GetTextColorForHSB(ab.GetAverageColor(ak))
end
else
if ai then
ai:Destroy()
ai=nil
end
end
return ah
end

function ah.Destroy(am)
al:Destroy()
return ah
end

ab:OnThemeChange(function(am,an)
aj.TextColor3=ab.GetTextColorForHSB(ab.GetThemeProperty(ah.Color,ab.Theme))
ai.ImageLabel.ImageColor3=
ab.GetTextColorForHSB(ab.GetThemeProperty(ah.Color,ab.Theme))
end)

return ah
end

return aa end function a.z()

local aa=(cloneref or clonereference or function(aa)return aa end)


local ab=aa(game:GetService"RunService")
local ac=aa(game:GetService"HttpService")

local ad

local ae
ae={
Folder=nil,
Path=nil,
Configs={},
Parser={
Colorpicker={
Save=function(af)
return{
__type=af.__type,
value=af.Default:ToHex(),
transparency=af.Transparency or nil,
}
end,
Load=function(af,ag)
if af and af.Update then
af:Update(Color3.fromHex(ag.value),ag.transparency or nil)
end
end
},
Dropdown={
Save=function(af)
return{
__type=af.__type,
value=af.Value,
}
end,
Load=function(af,ag)
if af and af.Select then
af:Select(ag.value)
end
end
},
Input={
Save=function(af)
return{
__type=af.__type,
value=af.Value,
}
end,
Load=function(af,ag)
if af and af.Set then
af:Set(ag.value)
end
end
},
Keybind={
Save=function(af)
return{
__type=af.__type,
value=af.Value,
}
end,
Load=function(af,ag)
if af and af.Set then
af:Set(ag.value)
end
end
},
Slider={
Save=function(af)
return{
__type=af.__type,
value=af.Value.Default,
}
end,
Load=function(af,ag)
if af and af.Set then
af:Set(tonumber(ag.value))
end
end
},
Toggle={
Save=function(af)
return{
__type=af.__type,
value=af.Value,
}
end,
Load=function(af,ag)
if af and af.Set then
af:Set(ag.value)
end
end
},
}
}

function ae.Init(af,ag)
if not ag.Folder then
warn"[ WindUI.ConfigManager ] Window.Folder is not specified."
return false
end
if ab:IsStudio()or not writefile then
warn"[ WindUI.ConfigManager ] The config system doesn't work in the studio."
return false
end

ad=ag
ae.Folder=ad.Folder
ae.Path="WindUI/"..tostring(ae.Folder).."/config/"

if not isfolder(ae.Path)then
makefolder(ae.Path)
end

local ah=ae:AllConfigs()

for ai,aj in next,ah do
if isfile and readfile and isfile(aj..".json")then
ae.Configs[aj]=readfile(aj..".json")
end
end

return ae
end

function ae.SetPath(af,ag)
if not ag then
warn"[ WindUI.ConfigManager ] Custom path is not specified."
return false
end

ae.Path=ag
if not ag:match"/$"then
ae.Path=ag.."/"
end

if not isfolder(ae.Path)then
makefolder(ae.Path)
end

return true
end

function ae.CreateConfig(af,ag,ah)
local ai={
Path=ae.Path..ag..".json",
Elements={},
CustomData={},
AutoLoad=ah or false,
Version=1.2,
}

if not ag then
return false,"No config file is selected"
end

function ai.SetAsCurrent(aj)
ad:SetCurrentConfig(ai)
end

function ai.Register(aj,ak,al)
ai.Elements[ak]=al
end

function ai.Set(aj,ak,al)
ai.CustomData[ak]=al
end

function ai.Get(aj,ak)
return ai.CustomData[ak]
end

function ai.SetAutoLoad(aj,ak)
ai.AutoLoad=ak
end

function ai.Save(aj)
if ad.PendingFlags then
for ak,al in next,ad.PendingFlags do
ai:Register(ak,al)
end
end

local ak={
__version=ai.Version,
__elements={},
__autoload=ai.AutoLoad,
__custom=ai.CustomData
}

for al,am in next,ai.Elements do
if ae.Parser[am.__type]then
ak.__elements[tostring(al)]=ae.Parser[am.__type].Save(am)
end
end

local al=ac:JSONEncode(ak)
if writefile then
writefile(ai.Path,al)
end

return ak
end

function ai.Load(aj)
if isfile and not isfile(ai.Path)then
return false,"Config file does not exist"
end

local ak,al=pcall(function()
local ak=readfile or function()
warn"[ WindUI.ConfigManager ] The config system doesn't work in the studio."
return nil
end
return ac:JSONDecode(ak(ai.Path))
end)

if not ak then
return false,"Failed to parse config file"
end

if not al.__version then
local am={
__version=ai.Version,
__elements=al,
__custom={}
}
al=am
end

if ad.PendingFlags then
for am,an in next,ad.PendingFlags do
ai:Register(am,an)
end
end

for am,an in next,(al.__elements or{})do
if ai.Elements[am]and ae.Parser[an.__type]then
task.spawn(function()
ae.Parser[an.__type].Load(ai.Elements[am],an)
end)
end
end

ai.CustomData=al.__custom or{}

return ai.CustomData
end

function ai.Delete(aj)
if not delfile then
return false,"delfile function is not available"
end

if not isfile(ai.Path)then
return false,"Config file does not exist"
end

local ak,al=pcall(function()
delfile(ai.Path)
end)

if not ak then
return false,"Failed to delete config file: "..tostring(al)
end

ae.Configs[ag]=nil

if ad.CurrentConfig==ai then
ad.CurrentConfig=nil
end

return true,"Config deleted successfully"
end

function ai.GetData(aj)
return{
elements=ai.Elements,
custom=ai.CustomData,
autoload=ai.AutoLoad
}
end


if isfile(ai.Path)then
local aj,ak=pcall(function()
return ac:JSONDecode(readfile(ai.Path))
end)

if aj and ak and ak.__autoload then
ai.AutoLoad=true

task.spawn(function()
task.wait(0.5)
local al,am=pcall(function()
return ai:Load()
end)
if al then
if ad.Debug then print("[ WindUI.ConfigManager ] AutoLoaded config: "..ag)end
else
warn("[ WindUI.ConfigManager ] Failed to AutoLoad config: "..ag.." - "..tostring(am))
end
end)
end
end


ai:SetAsCurrent()
ae.Configs[ag]=ai
return ai
end

function ae.Config(af,ag,ah)
return ae:CreateConfig(ag,ah)
end

function ae.GetAutoLoadConfigs(af)
local ag={}

for ah,ai in pairs(ae.Configs)do
if ai.AutoLoad then
table.insert(ag,ah)
end
end

return ag
end

function ae.DeleteConfig(af,ag)
if not delfile then
return false,"delfile function is not available"
end

local ah=ae.Path..ag..".json"

if not isfile(ah)then
return false,"Config file does not exist"
end

local ai,aj=pcall(function()
delfile(ah)
end)

if not ai then
return false,"Failed to delete config file: "..tostring(aj)
end

ae.Configs[ag]=nil

if ad.CurrentConfig and ad.CurrentConfig.Path==ah then
ad.CurrentConfig=nil
end

return true,"Config deleted successfully"
end

function ae.AllConfigs(af)
if not listfiles then return{}end

local ag={}
if not isfolder(ae.Path)then
makefolder(ae.Path)
return ag
end

for ah,ai in next,listfiles(ae.Path)do
local aj=ai:match"([^\\/]+)%.json$"
if aj then
table.insert(ag,aj)
end
end

return ag
end

function ae.GetConfig(af,ag)
return ae.Configs[ag]
end

return ae end function a.A()
local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween


local ae=(cloneref or clonereference or function(ae)return ae end)


ae(game:GetService"UserInputService")


function aa.New(af)
local ag={
Button=nil
}

local ah













local ai=ac("TextLabel",{
Text=af.Title,
TextSize=17,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
AutomaticSize="XY",
})

local aj=ac("Frame",{
Size=UDim2.new(0,36,0,36),
BackgroundTransparency=1,
Name="Drag",
},{
ac("ImageLabel",{
Image=ab.Icon"move"[1],
ImageRectOffset=ab.Icon"move"[2].ImageRectPosition,
ImageRectSize=ab.Icon"move"[2].ImageRectSize,
Size=UDim2.new(0,18,0,18),
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=.3,
})
})
local ak=ac("Frame",{
Size=UDim2.new(0,1,1,0),
Position=UDim2.new(0,36,0.5,0),
AnchorPoint=Vector2.new(0,0.5),
BackgroundColor3=Color3.new(1,1,1),
BackgroundTransparency=.9,
})

local al=ac("Frame",{
Size=UDim2.new(0,0,0,0),
Position=UDim2.new(0.5,0,0,28),
AnchorPoint=Vector2.new(0.5,0.5),
Parent=af.Parent,
BackgroundTransparency=1,
Active=true,
Visible=false,
})


local am=ac("UIScale",{
Scale=1,
})

local an=ac("Frame",{
Size=UDim2.new(0,0,0,44),
AutomaticSize="X",
Parent=al,
Active=false,
BackgroundTransparency=.25,
ZIndex=99,
BackgroundColor3=Color3.new(0,0,0),
},{
am,
ac("UICorner",{
CornerRadius=UDim.new(1,0)
}),
ac("UIStroke",{
Thickness=1,
ApplyStrokeMode="Border",
Color=Color3.new(1,1,1),
Transparency=0,
},{
ac("UIGradient",{
Color=ColorSequence.new(Color3.fromHex"40c9ff",Color3.fromHex"e81cff")
})
}),
aj,
ak,

ac("UIListLayout",{
Padding=UDim.new(0,4),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),

ac("TextButton",{
AutomaticSize="XY",
Active=true,
BackgroundTransparency=1,
Size=UDim2.new(0,0,0,36),

BackgroundColor3=Color3.new(1,1,1),
},{
ac("UICorner",{
CornerRadius=UDim.new(1,-4)
}),
ah,
ac("UIListLayout",{
Padding=UDim.new(0,af.UIPadding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
ai,
ac("UIPadding",{
PaddingLeft=UDim.new(0,11),
PaddingRight=UDim.new(0,11),
}),
}),
ac("UIPadding",{
PaddingLeft=UDim.new(0,4),
PaddingRight=UDim.new(0,4),
})
})

ag.Button=an



function ag.SetIcon(ao,ap)
if ah then
ah:Destroy()
end
if ap then
ah=ab.Image(
ap,
af.Title,
0,
af.Folder,
"OpenButton",
true,
af.IconThemed
)
ah.Size=UDim2.new(0,22,0,22)
ah.LayoutOrder=-1
ah.Parent=ag.Button.TextButton
end
end

if af.Icon then
ag:SetIcon(af.Icon)
end



ab.AddSignal(an:GetPropertyChangedSignal"AbsoluteSize",function()
al.Size=UDim2.new(
0,an.AbsoluteSize.X,
0,an.AbsoluteSize.Y
)
end)

ab.AddSignal(an.TextButton.MouseEnter,function()
ad(an.TextButton,.1,{BackgroundTransparency=.93}):Play()
end)
ab.AddSignal(an.TextButton.MouseLeave,function()
ad(an.TextButton,.1,{BackgroundTransparency=1}):Play()
end)

local ao=ab.Drag(al)


function ag.Visible(ap,aq)
al.Visible=aq
end

function ag.SetScale(ap,aq)
am.Scale=aq
end

function ag.Edit(ap,aq)
local ar={
Title=aq.Title,
Icon=aq.Icon,
Enabled=aq.Enabled,
Position=aq.Position,
OnlyIcon=aq.OnlyIcon or false,
Draggable=aq.Draggable or nil,
OnlyMobile=aq.OnlyMobile,
CornerRadius=aq.CornerRadius or UDim.new(1,0),
StrokeThickness=aq.StrokeThickness or 2,
Scale=aq.Scale or 1,
Color=aq.Color
or ColorSequence.new(Color3.fromHex"40c9ff",Color3.fromHex"e81cff"),
}



if ar.Enabled==false then
af.IsOpenButtonEnabled=false
end

if ar.OnlyMobile~=false then
ar.OnlyMobile=true
else
af.IsPC=false
end


if ar.Draggable==false and aj and ak then
aj.Visible=ar.Draggable
ak.Visible=ar.Draggable

if ao then
ao:Set(ar.Draggable)
end
end

if ar.Position and al then
al.Position=ar.Position
end

if ar.OnlyIcon==true and ai then
ai.Visible=false
an.TextButton.UIPadding.PaddingLeft=UDim.new(0,7)
an.TextButton.UIPadding.PaddingRight=UDim.new(0,7)
elseif ar.OnlyIcon==false then
ai.Visible=true
an.TextButton.UIPadding.PaddingLeft=UDim.new(0,11)
an.TextButton.UIPadding.PaddingRight=UDim.new(0,11)
end





if ai then
if ar.Title then
ai.Text=ar.Title
ab:ChangeTranslationKey(ai,ar.Title)
elseif ar.Title==nil then

end
end

if ar.Icon then
ag:SetIcon(ar.Icon)
end

an.UIStroke.UIGradient.Color=ar.Color
if Glow then
Glow.UIGradient.Color=ar.Color
end

an.UICorner.CornerRadius=ar.CornerRadius
an.TextButton.UICorner.CornerRadius=UDim.new(ar.CornerRadius.Scale,ar.CornerRadius.Offset-4)
an.UIStroke.Thickness=ar.StrokeThickness

ag:SetScale(ar.Scale)
end

return ag
end



return aa end function a.B()
local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween


function aa.New(ae,af,ag,ah,ai,aj)
local ak={
Container=nil,
TooltipSize=16,

TooltipArrowSizeX=ai=="Small"and 16 or 24,
TooltipArrowSizeY=ai=="Small"and 6 or 9,

PaddingX=ai=="Small"and 12 or 14,
PaddingY=ai=="Small"and 7 or 9,

Radius=999,

TitleFrame=nil,
}

ah=ah or""
aj=aj~=false

local al=ac("TextLabel",{
AutomaticSize="XY",
TextWrapped=aj,
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
Text=ae,
TextSize=ai=="Small"and 15 or 17,
TextTransparency=1,
ThemeTag={
TextColor3="Tooltip"..ah.."Text",
}
})

ak.TitleFrame=al

local am=ac("UIScale",{
Scale=.9
})

local an=ac("Frame",{
AnchorPoint=Vector2.new(0.5,0),
AutomaticSize="XY",
BackgroundTransparency=1,
Parent=af,

Visible=false
},{
ac("UISizeConstraint",{
MaxSize=Vector2.new(400,math.huge)
}),
ac("Frame",{
AutomaticSize="XY",
BackgroundTransparency=1,
LayoutOrder=99,
Visible=ag,
Name="Arrow",
},{
ac("ImageLabel",{
Size=UDim2.new(0,ak.TooltipArrowSizeX,0,ak.TooltipArrowSizeY),
BackgroundTransparency=1,

Image="rbxassetid://105854070513330",
ThemeTag={
ImageColor3="Tooltip"..ah,
},
},{










}),
}),
ab.NewRoundFrame(ak.Radius,"Squircle",{
AutomaticSize="XY",
ThemeTag={
ImageColor3="Tooltip"..ah,
},
ImageTransparency=1,
Name="Background",
},{



ac("Frame",{



AutomaticSize="XY",
BackgroundTransparency=1,
},{
ac("UICorner",{
CornerRadius=UDim.new(0,16),
}),
ac("UIListLayout",{
Padding=UDim.new(0,12),
FillDirection="Horizontal",
VerticalAlignment="Center"
}),

al,
ac("UIPadding",{
PaddingTop=UDim.new(0,ak.PaddingY),
PaddingLeft=UDim.new(0,ak.PaddingX),
PaddingRight=UDim.new(0,ak.PaddingX),
PaddingBottom=UDim.new(0,ak.PaddingY),
}),
})
}),
am,
ac("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
VerticalAlignment="Center",
HorizontalAlignment="Center",
}),
})
ak.Container=an

function ak.Open(ao)
an.Visible=true


ad(an.Background,.2,{ImageTransparency=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(an.Arrow.ImageLabel,.2,{ImageTransparency=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(al,.2,{TextTransparency=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(am,.22,{Scale=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end

function ak.Close(ao,ap)

ad(an.Background,.3,{ImageTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(an.Arrow.ImageLabel,.2,{ImageTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(al,.3,{TextTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(am,.35,{Scale=.9},Enum.EasingStyle.Quint,Enum.EasingDirection.In):Play()

ap=ap~=false
if ap then
task.wait(.35)

an.Visible=false
an:Destroy()
end
end

return ak
end



return aa end function a.C()
game:GetService"ReplicatedStorage"
local aa=a.load'd'
local ab=aa.New
local ac=aa.NewRoundFrame
local ad=aa.Tween

local ae=(cloneref or clonereference or function(ae)
return ae
end)

ae(game:GetService"UserInputService")

local af=a.load'y'

local function Color3ToHSB(ag)
local ah,ai,aj=ag.R,ag.G,ag.B
local ak=math.max(ah,ai,aj)
local al=math.min(ah,ai,aj)
local am=ak-al

local an=0
if am~=0 then
if ak==ah then
an=(ai-aj)/am%6
elseif ak==ai then
an=(aj-ah)/am+2
else
an=(ah-ai)/am+4
end
an=an*60
else
an=0
end

local ao=(ak==0)and 0 or(am/ak)
local ap=ak

return{
h=math.floor(an+0.5),
s=ao,
b=ap,
}
end

local function GetPerceivedBrightness(ag)
local ah=ag.R
local ai=ag.G
local aj=ag.B
return 0.299*ah+0.587*ai+0.114*aj
end

local function GetTextColorForHSB(ag)
local ah=Color3ToHSB(ag)local
ai, aj, ak=ah.h, ah.s, ah.b
if GetPerceivedBrightness(ag)>0.5 then
return Color3.fromHSV(ai/360,0,0.05)
else
return Color3.fromHSV(ai/360,0,0.98)
end
end

return function(ag)
local ah={
Title=ag.Title,
Desc=ag.Desc or nil,
Hover=ag.Hover,
Thumbnail=ag.Thumbnail,
ThumbnailSize=ag.ThumbnailSize or 80,
Image=ag.Image,
IconThemed=ag.IconThemed or false,
ImageSize=ag.ImageSize or 30,
Color=ag.Color,
Scalable=ag.Scalable,
Parent=ag.Parent,
Justify=ag.Justify or"Between",
UIPadding=ag.Window.ElementConfig.UIPadding,
UICorner=ag.Window.ElementConfig.UICorner,
Size=ag.Size or"Default",
Tags=ag.Tags or{},
UIElements={},

Index=ag.Index,
}

local ai=ah.Size=="Small"and-4 or ah.Size=="Large"and 4 or 0
local aj=ah.Size=="Small"and-4 or ah.Size=="Large"and 4 or 0

local ak=ah.ImageSize
local al=ah.ThumbnailSize
local am=true


local an=0

local ao
local ap
if ah.Thumbnail then
ao=aa.Image(
ah.Thumbnail,
ah.Title,
ag.Window.NewElements and ah.UICorner-11 or(ah.UICorner-4),
ag.Window.Folder,
"Thumbnail",
false,
ah.IconThemed
)
ao.Size=UDim2.new(1,0,0,al)
end
if ah.Image then
ap=aa.Image(
ah.Image,
ah.Title,
ag.Window.NewElements and ah.UICorner-11 or(ah.UICorner-4),
ag.Window.Folder,
"Image",
ah.IconThemed,
not ah.Color and true or false,
"ElementIcon"
)

if typeof(ah.Color)=="string"and not string.find(ah.Image,"rbxthumb")then
ap.ImageLabel.ImageColor3=GetTextColorForHSB(Color3.fromHex(aa.Colors[ah.Color]))
elseif typeof(ah.Color)=="Color3"and not string.find(ah.Image,"rbxthumb")then
ap.ImageLabel.ImageColor3=GetTextColorForHSB(ah.Color)
end

ap.Size=UDim2.new(0,ak,0,ak)

an=ak
end

local function CreateText(aq,ar)
local as=typeof(ah.Color)=="string"
and GetTextColorForHSB(Color3.fromHex(aa.Colors[ah.Color]))
or typeof(ah.Color)=="Color3"and GetTextColorForHSB(ah.Color)

return ab("TextLabel",{
BackgroundTransparency=1,
Text=aq or"",
TextSize=ar=="Desc"and 15 or 17,
TextXAlignment="Left",
ThemeTag={
TextColor3=not ah.Color and("Element"..ar)or nil,
},
TextColor3=ah.Color and as or nil,
TextTransparency=ar=="Desc"and 0.3 or 0,
TextWrapped=true,
Size=UDim2.new(ah.Justify=="Between"and 1 or 0,0,0,0),
AutomaticSize=ah.Justify=="Between"and"Y"or"XY",
FontFace=Font.new(aa.Font,ar=="Desc"and Enum.FontWeight.Medium or Enum.FontWeight.SemiBold),
})
end

local aq=CreateText(ah.Title,"Title")
local ar=CreateText(ah.Desc,"Desc")
if not ah.Title or ah.Title==""then
ar.Visible=false
end
if not ah.Desc or ah.Desc==""then
ar.Visible=false
end

ah.UIElements.Title=aq
ah.UIElements.Desc=ar

ah.UIElements.Container=ab("Frame",{
Size=UDim2.new(1,0,1,0),
AutomaticSize="Y",
BackgroundTransparency=1,
},{
ab("UIListLayout",{
Padding=UDim.new(0,ah.UIPadding),
FillDirection="Vertical",
VerticalAlignment="Center",
HorizontalAlignment=ah.Justify=="Between"and"Left"or"Center",
}),
ao,
ab("Frame",{
Size=UDim2.new(
ah.Justify=="Between"and 1 or 0,
ah.Justify=="Between"and-ag.TextOffset or 0,
0,
0
),
AutomaticSize=ah.Justify=="Between"and"Y"or"XY",
BackgroundTransparency=1,
Name="TitleFrame",
},{
ab("UIListLayout",{
Padding=UDim.new(0,ah.UIPadding),
FillDirection="Horizontal",
VerticalAlignment=ag.Window.NewElements and(ah.Justify=="Between"and"Top"or"Center")
or"Center",
HorizontalAlignment=ah.Justify~="Between"and ah.Justify or"Center",
}),
ap,
ab("Frame",{
BackgroundTransparency=1,
AutomaticSize=ah.Justify=="Between"and"Y"or"XY",
Size=UDim2.new(
ah.Justify=="Between"and 1 or 0,
ah.Justify=="Between"and(ap and-an-ah.UIPadding or-an)
or 0,
1,
0
),
Name="TitleFrame",
},{
ab("UIPadding",{
PaddingTop=UDim.new(0,(ag.Window.NewElements and ah.UIPadding/2 or 0)+aj),
PaddingLeft=UDim.new(0,(ag.Window.NewElements and ah.UIPadding/2 or 0)+ai),
PaddingRight=UDim.new(
0,
(ag.Window.NewElements and ah.UIPadding/2 or 0)+ai
),
PaddingBottom=UDim.new(
0,
(ag.Window.NewElements and ah.UIPadding/2 or 0)+aj
),
}),
ab("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Vertical",
VerticalAlignment="Center",
HorizontalAlignment="Left",
}),
ab("ScrollingFrame",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
LayoutOrder=-99,
BackgroundTransparency=1,
ScrollingDirection="X",
CanvasSize=UDim2.new(0,0,0,0),
ScrollBarThickness=0,
Visible=false,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Left",
Padding=UDim.new(0,ag.Window.UIPadding/2),
}),
}),
ab("Frame",{
Name="Space",
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
Visible=false,
}),
aq,
ar,
}),
}),
})

for as,at in next,ag.Tags or{}do
if not ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.Visible then
ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.Visible=true
ah.UIElements.Container.TitleFrame.TitleFrame.Space.Visible=true
end
af:New(at,ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame)
end

aa.AddSignal(
ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.UIListLayout:GetPropertyChangedSignal
"AbsoluteContentSize"
,
function()
ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.Size=UDim2.new(
1,
0,
0,
ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y
/ag.ParentConfig.UIScale
)
end
)





local as=aa.Image("lock","lock",0,ag.Window.Folder,"Lock",false)
as.Size=UDim2.new(0,20,0,20)
as.ImageLabel.ImageColor3=Color3.new(1,1,1)
as.ImageLabel.ImageTransparency=0.4

local at=ab("TextLabel",{
Text="Locked",
TextSize=18,
FontFace=Font.new(aa.Font,Enum.FontWeight.Medium),
AutomaticSize="XY",
BackgroundTransparency=1,
TextColor3=Color3.new(1,1,1),
TextTransparency=0.05,
})

local au=ab("Frame",{
Size=UDim2.new(1,ah.UIPadding*2,1,ah.UIPadding*2),
BackgroundTransparency=1,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ZIndex=9999999,
})

local av,aw=ac(ah.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.25,
ImageColor3=Color3.new(0,0,0),
Visible=false,
Active=false,
Parent=au,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
as,
at,
},nil,true)local

ax=ac(ah.UICorner,"Squircle-Outline",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
Active=false,
ThemeTag={
ImageColor3="Text",
},
Parent=au,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
},nil,true)

local ay,az=ac(ah.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
Active=false,
ThemeTag={
ImageColor3="Text",
},
Parent=au,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
},nil,true)local

aA=ac(ah.UICorner,"Squircle-Outline",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
Visible=false,
Active=false,
ThemeTag={
ImageColor3="Text",
},
Parent=au,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
ab("UIGradient",{
Name="HoverGradient",
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,1),
NumberSequenceKeypoint.new(0.25,0.9),
NumberSequenceKeypoint.new(0.5,0.3),
NumberSequenceKeypoint.new(0.75,0.9),
NumberSequenceKeypoint.new(1,1),
},
}),
},nil,true)

local aB,b=ac(ah.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
Active=false,
ThemeTag={
ImageColor3="Text",
},
Parent=au,
},{
ab("UIGradient",{
Name="HoverGradient",
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,1),
NumberSequenceKeypoint.new(0.25,0.9),
NumberSequenceKeypoint.new(0.5,0.3),
NumberSequenceKeypoint.new(0.75,0.9),
NumberSequenceKeypoint.new(1,1),
},
}),
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
},nil,true)

local d,f=ac(ah.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
ImageTransparency=ah.Color and 0.05 or(not ag.Window.NewElements and 0.93 or nil),



Parent=ag.Parent,
ThemeTag={
ImageColor3=not ah.Color and(ag.Window.NewElements and"ElementBackground"or"Text")or nil,
ImageTransparency=not ah.Color
and(ag.Window.NewElements and"ElementBackgroundTransparency"or nil)
or nil,
},
ImageColor3=ah.Color and(typeof(ah.Color)=="string"and Color3.fromHex(
aa.Colors[ah.Color]
)or typeof(ah.Color)=="Color3"and ah.Color)or nil,
},{
ah.UIElements.Container,
au,
ab("UIPadding",{
PaddingTop=UDim.new(0,ah.UIPadding),
PaddingLeft=UDim.new(0,ah.UIPadding),
PaddingRight=UDim.new(0,ah.UIPadding),
PaddingBottom=UDim.new(0,ah.UIPadding),
}),
},true,true)

ah.UIElements.Main=d
ah.UIElements.Locked=av

if ah.Hover then
aa.AddSignal(d.MouseEnter,function()
if am then

ad(aB,0.12,{ImageTransparency=0.9}):Play()
ad(aA,0.12,{ImageTransparency=0.8}):Play()
aa.AddSignal(d.MouseMoved,function(g,h)
aB.HoverGradient.Offset=
Vector2.new(((g-d.AbsolutePosition.X)/d.AbsoluteSize.X)-0.5,0)
aA.HoverGradient.Offset=
Vector2.new(((g-d.AbsolutePosition.X)/d.AbsoluteSize.X)-0.5,0)
end)
end
end)
aa.AddSignal(d.InputEnded,function()
if am then

ad(aB,0.12,{ImageTransparency=1}):Play()
ad(aA,0.12,{ImageTransparency=1}):Play()
end
end)
end

function ah.SetTitle(g,h)
ah.Title=h
aq.Text=h
end

function ah.SetDesc(g,h)
ah.Desc=h
ar.Text=h or""
if not h then
ar.Visible=false
elseif not ar.Visible then
ar.Visible=true
end
end

function ah.Colorize(g,h,i)
if ah.Color then
h[i]=typeof(ah.Color)=="string"
and GetTextColorForHSB(Color3.fromHex(aa.Colors[ah.Color]))
or typeof(ah.Color)=="Color3"and GetTextColorForHSB(ah.Color)
or nil
end
end

if ag.ElementTable then
aa.AddSignal(aq:GetPropertyChangedSignal"Text",function()
if ah.Title~=aq.Text then
ah:SetTitle(aq.Text)
ag.ElementTable.Title=aq.Text
end
end)
aa.AddSignal(ar:GetPropertyChangedSignal"Text",function()
if ah.Desc~=ar.Text then
ah:SetDesc(ar.Text)
ag.ElementTable.Desc=ar.Text
end
end)
end





function ah.SetThumbnail(g,h,i)
ah.Thumbnail=h
if i then
ah.ThumbnailSize=i
al=i
end

if ao then
if h then
ao:Destroy()
ao=aa.Image(
h,
ah.Title,
ah.UICorner-3,
ag.Window.Folder,
"Thumbnail",
false,
ah.IconThemed
)
if ao then
ao.Size=UDim2.new(1,0,0,al)
ao.Parent=ah.UIElements.Container
local l=ah.UIElements.Container:FindFirstChild"UIListLayout"
if l then
ao.LayoutOrder=-1
end
end
else
ao.Visible=false
end
else
if h then
ao=aa.Image(
h,
ah.Title,
ah.UICorner-3,
ag.Window.Folder,
"Thumbnail",
false,
ah.IconThemed
)
if ao then
ao.Size=UDim2.new(1,0,0,al)
ao.Parent=ah.UIElements.Container
local l=ah.UIElements.Container:FindFirstChild"UIListLayout"
if l then
ao.LayoutOrder=-1
end
end
end
end
end

function ah.SetImage(g,h,i)
ah.Image=h
if i then
ah.ImageSize=i
ak=i
end

if h then
local l=ap and ap.Parent or ah.UIElements.Container.TitleFrame
if ap then
ap:Destroy()
end

ap=aa.Image(
h,
h,
ah.UICorner-3,
ag.Window.Folder,
"Image",
not ah.Color and true or false
)
if ap then
if typeof(ah.Color)=="string"and not string.find(ah.Image,"rbxthumb")then
ap.ImageLabel.ImageColor3=
GetTextColorForHSB(Color3.fromHex(aa.Colors[ah.Color]))
elseif typeof(ah.Color)=="Color3"and not string.find(ah.Image,"rbxthumb")then
ap.ImageLabel.ImageColor3=GetTextColorForHSB(ah.Color)
end

ap.Visible=true
ap.Parent=l
ap.LayoutOrder=-99

ap.Size=UDim2.new(0,ak,0,ak)
an=ah.ImageSize+ah.UIPadding
end
else
if ap then
ap.Visible=true
end
an=0
end

ah.UIElements.Container.TitleFrame.TitleFrame.Size=UDim2.new(1,-an,1,0)
end

function ah.Destroy(g)
d:Destroy()
end

function ah.Lock(g,h)
am=false
av.Active=true
av.Visible=true
at.Text=h or"Locked"
end

function ah.Unlock(g)
am=true
av.Active=false
av.Visible=false
end

function ah.Highlight(g)
local h=ab("UIGradient",{
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,1),
NumberSequenceKeypoint.new(0.1,0.9),
NumberSequenceKeypoint.new(0.5,0.3),
NumberSequenceKeypoint.new(0.9,0.9),
NumberSequenceKeypoint.new(1,1),
},
Rotation=0,
Offset=Vector2.new(-1,0),
Parent=ax,
})

local i=ab("UIGradient",{
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,1),
NumberSequenceKeypoint.new(0.15,0.8),
NumberSequenceKeypoint.new(0.5,0.1),
NumberSequenceKeypoint.new(0.85,0.8),
NumberSequenceKeypoint.new(1,1),
},
Rotation=0,
Offset=Vector2.new(-1,0),
Parent=ay,
})

ax.ImageTransparency=0.65
ay.ImageTransparency=0.88

ad(h,0.75,{
Offset=Vector2.new(1,0),
}):Play()

ad(i,0.75,{
Offset=Vector2.new(1,0),
}):Play()

task.spawn(function()
task.wait(0.75)
ax.ImageTransparency=1
ay.ImageTransparency=1
h:Destroy()
i:Destroy()
end)
end

function ah.UpdateShape(g)
if ag.Window.NewElements then
local h=aa:GetElementPosition(
g.Elements,
ah.Index,
ag.ParentConfig.ParentTable.__type=="HStack"or ag.ParentConfig.ParentTable.__type=="Group"
)

if h and d then
f:SetType(h)
aw:SetType(h)
az:SetType(h)

b:SetType(h)

end
end
end





return ah
end end function a.D()

local aa=a.load'd'
local ab=aa.New

local ac={}

local ad=a.load'm'.New

function ac.New(ae,af)
af.Hover=false
af.TextOffset=0
af.ParentConfig=af
af.IsButtons=af.Buttons and#af.Buttons>0 and true or false

local ag={
__type="Paragraph",
Title=af.Title or"Paragraph",
Desc=af.Desc or nil,

Locked=af.Locked or false,
}
local ah=a.load'C'(af)

ag.ParagraphFrame=ah
if af.Buttons and#af.Buttons>0 then
local ai=ab("Frame",{
Size=UDim2.new(1,0,0,38),
BackgroundTransparency=1,
AutomaticSize="Y",
Parent=ah.UIElements.Container,
},{
ab("UIListLayout",{
Padding=UDim.new(0,10),
FillDirection="Vertical",
}),
})

for aj,ak in next,af.Buttons do
local al=ad(
ak.Title,
ak.Icon,
ak.Callback,
ak.Variant or"White",
ai,
nil,
nil,
af.Window.NewElements and 999 or 10
)
al.Size=UDim2.new(1,0,0,38)

end
end

return ag.__type,ag
end

return ac end function a.E()

local aa=a.load'd'local ab=
aa.New

local ac={}

function ac.New(ad,ae)
local af={
__type="Button",
Title=ae.Title or"Button",
Desc=ae.Desc or nil,
Icon=ae.Icon or"mouse-pointer-click",
IconThemed=ae.IconThemed or false,
IconColor=ae.IconColor or nil,
Color=ae.Color,
Justify=ae.Justify or"Between",
IconAlign=ae.IconAlign or"Right",
Locked=ae.Locked or false,
LockedTitle=ae.LockedTitle,
Callback=ae.Callback or function()end,
UIElements={},
}

local ag=true

af.ButtonFrame=a.load'C'{
Title=af.Title,
Desc=af.Desc,
Parent=ae.Parent,




Window=ae.Window,
Color=af.Color,
Justify=af.Justify,
TextOffset=20,
Hover=true,
Scalable=true,
Tab=ae.Tab,
Index=ae.Index,
ElementTable=af,
ParentConfig=ae,
Size=ae.Size,
Tags=ae.Tags,
}














af.UIElements.ButtonIcon=aa.Image(
af.Icon,
af.Icon,
0,
ae.Window.Folder,
"Button",
not(af.Color or af.IconColor)and true or nil,
af.IconThemed
)

if af.IconColor then
af.UIElements.ButtonIcon.ImageLabel.ImageColor3=af.IconColor
end

af.UIElements.ButtonIcon.Size=UDim2.new(0,20,0,20)
af.UIElements.ButtonIcon.Parent=af.Justify=="Between"and af.ButtonFrame.UIElements.Main
or af.ButtonFrame.UIElements.Container.TitleFrame
af.UIElements.ButtonIcon.LayoutOrder=af.IconAlign=="Left"and-99999 or 99999
af.UIElements.ButtonIcon.AnchorPoint=Vector2.new(1,0.5)
af.UIElements.ButtonIcon.Position=UDim2.new(1,0,0.5,0)

af.ButtonFrame:Colorize(af.UIElements.ButtonIcon.ImageLabel,"ImageColor3")

function af.Lock(ah)
af.Locked=true
ag=false
return af.ButtonFrame:Lock(af.LockedTitle)
end
function af.Unlock(ah)
af.Locked=false
ag=true
return af.ButtonFrame:Unlock()
end

if af.Locked then
af:Lock()
end

aa.AddSignal(af.ButtonFrame.UIElements.Main.MouseButton1Click,function()
if ag then
task.spawn(function()
aa.SafeCallback(af.Callback)
end)
end
end)
return af.__type,af
end

return ac end function a.F()

local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween

local ae=game:GetService"UserInputService"

function aa.New(af,ag,ah,ai,aj,ak,al)
local am={
GlassSpritesheet={
Id="rbxassetid://77297718671545",
MirroredId="rbxassetid://92258969882244",
Size=Vector2.new(102,128),
Total=80,
Cols=10,
},
}

function am.GetGlassFrame(an,ao:number):(string,Vector2,Vector2)
local ap=am.GlassSpritesheet
local aq:number

if ao<=0.4 then
aq=math.floor((ao/0.4)*(ap.Total-1))
elseif ao<0.6 then
aq=ap.Total-1
else
aq=math.floor(((ao-0.6)/0.4)*(ap.Total-1))
end

aq=math.clamp(aq,0,ap.Total-1)

local ar=ao>=0.6
if ar then
aq=(ap.Total-1)-aq
end

local as=ar and ap.MirroredId or ap.Id

return as,ap.Size,Vector2.new((aq%ap.Cols)*ap.Size.X,math.floor(aq/ap.Cols)*ap.Size.Y)
end

local an=12
local ao
if ag and ag~=""then
ao=ac("ImageLabel",{
Size=UDim2.new(0,13,0,13),
BackgroundTransparency=1,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Image=ab.Icon(ag)[1],
ImageRectOffset=ab.Icon(ag)[2].ImageRectPosition,
ImageRectSize=ab.Icon(ag)[2].ImageRectSize,
ImageTransparency=1,
ImageColor3=Color3.new(0,0,0),
})
end

local ap=ac("Frame",{
Size=UDim2.new(0,2,0,26),
BackgroundTransparency=1,
Parent=ai,
})

local aq=ab.NewRoundFrame(an,"Squircle",{
ImageTransparency=0.85,
ThemeTag={
ImageColor3="Text",
},
Parent=ap,
Size=UDim2.new(0,ak and(52)or(40.8),0,24),
AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(0,0,0.5,0),
Name="ToggleFrame",
},{
ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Layer",
ThemeTag={
ImageColor3="Toggle",
},
ImageTransparency=1,
}),
ab.NewRoundFrame(an,"SquircleOutline",{
Size=UDim2.new(1,0,1,0),
Name="Stroke",
ImageColor3=Color3.new(1,1,1),
ImageTransparency=1,
},{
ac("UIGradient",{
Rotation=90,
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,0),
NumberSequenceKeypoint.new(1,1),
},
}),
}),


ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(0,ak and 30 or 20,0,20),
Position=UDim2.new(0,2,0.5,0),
AnchorPoint=Vector2.new(0,0.5),
ImageTransparency=1,
Name="Frame",
},{
ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=0,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Bar",
},{
ab.New("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundColor3=Color3.new(1,1,1),
Name="Highlight",
BackgroundTransparency=1,
},{
ab.NewRoundFrame(9999,"SquircleGlass",{
Size=UDim2.new(1,1,1,1),
ImageColor3=Color3.new(1,1,1),
Name="SquircleGlass",
ImageTransparency=0.5,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
}),
ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="GlassBackground",
ImageTransparency=0,
ThemeTag={
ImageColor3="ElementBackground",
},
ZIndex=-1,
}),
ac("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Name="Glass",
ImageTransparency=0,
},{
ac("UICorner",{
CornerRadius=UDim.new(1,0),
}),
}),






ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="BarOverlay",
ThemeTag={
ImageColor3="ToggleBar",
},
ZIndex=999,
}),
}),
ao,
ac("UIScale",{
Scale=1,
}),
}),
}),
ac("TextButton",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
Name="Hitbox",
Text="",
}),
})

local ar
local as

local at=ak and 30 or 20
local au=aq.Size.X.Offset

function am.Set(av,aw,ax,ay)
if not ay then
if aw then
ad(aq.Frame,0.35,{
Position=UDim2.new(0,au-at-2,0.5,0),
},Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
ab.SetThemeTag(aq.Frame.Bar.Highlight.Glass,{ImageColor3="Toggle"},0.15)

ad(
aq.Frame.Bar.Highlight.Glass,
0.15,
{ImageTransparency=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
else
ad(aq.Frame,0.35,{
Position=UDim2.new(0,2,0.5,0),
},Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
ab.SetThemeTag(aq.Frame.Bar.Highlight.Glass,{ImageColor3="Text"},0.15)
ad(
aq.Frame.Bar.Highlight.Glass,
0.15,
{ImageTransparency=0.85},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
else
if aw then
aq.Frame.Position=UDim2.new(0,au-at-2,0.5,0)
else
aq.Frame.Position=UDim2.new(0,2,0.5,0)
end
end

if aw then
ad(aq.Layer,0.1,{
ImageTransparency=0,
}):Play()
ab.SetThemeTag(aq.Frame.Bar.Highlight.Glass,{ImageColor3="Toggle"},0.1)
ad(
aq.Frame.Bar.Highlight.Glass,
0.1,
{ImageTransparency=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()

if ao then
ad(ao,0.1,{
ImageTransparency=0,
}):Play()
end

local az,aA,aB=am:GetGlassFrame(1)

aq.Frame.Bar.Highlight.Glass.Image=az
aq.Frame.Bar.Highlight.Glass.ImageRectSize=aA
aq.Frame.Bar.Highlight.Glass.ImageRectOffset=aB
else
ad(aq.Layer,0.1,{
ImageTransparency=1,
}):Play()
ab.SetThemeTag(aq.Frame.Bar.Highlight.Glass,{ImageColor3="Text"},0.1)
ad(
aq.Frame.Bar.Highlight.Glass,
0.1,
{ImageTransparency=0.85},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()

if ao then
ad(ao,0.1,{
ImageTransparency=1,
}):Play()
end

local az,aA,aB=am:GetGlassFrame(0)

aq.Frame.Bar.Highlight.Glass.Image=az
aq.Frame.Bar.Highlight.Glass.ImageRectSize=aA
aq.Frame.Bar.Highlight.Glass.ImageRectOffset=aB
end

ax=ax~=false

task.spawn(function()
if aj and ax then
ab.SafeCallback(aj,aw)
end
end)
end

function am.Animate(av,aw,ax)
if not al.Window.IsToggleDragging then
al.Window.IsToggleDragging=true

local ay=aw.Position.X
local az=aw.Position.Y
local aA=aq.Frame.Position.X.Offset
local aB=false
local b=false

ad(
aq.Frame.Bar.UIScale,
0.28,
{Scale=1.5},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ad(
aq.Frame.Bar.Highlight.BarOverlay,
0.28,
{ImageTransparency=0.86},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()

if ar then
ar:Disconnect()
end

ar=ae.InputChanged:Connect(function(d)
if not al.Window.IsToggleDragging then
return
end
if
d.UserInputType~=Enum.UserInputType.MouseMovement
and d.UserInputType~=Enum.UserInputType.Touch
then
return
end
if aB then
return
end

local f=math.abs(d.Position.X-ay)
math.abs(d.Position.Y-az)

if not b and f>8 then
b=true
end

local g=d.Position.X-ay
local h=math.max(2,math.min(aA+g,au-at-2))

local i=math.clamp((h-2)/(au-at-4),0,1)

local l,m,p=am:GetGlassFrame(i)
aq.Frame.Bar.Highlight.Glass.Image=l
aq.Frame.Bar.Highlight.Glass.ImageRectSize=m
aq.Frame.Bar.Highlight.Glass.ImageRectOffset=p

ad(aq.Frame,0.12,{
Position=UDim2.new(0,h,0.5,0),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end)

if as then
as:Disconnect()
end

as=ae.InputEnded:Connect(function(d)
if not al.Window.IsToggleDragging then
return
end
if
d.UserInputType~=Enum.UserInputType.MouseButton1
and d.UserInputType~=Enum.UserInputType.Touch
then
return
end

al.Window.IsToggleDragging=false

if ar then
ar:Disconnect()
ar=nil
end
if as then
as:Disconnect()
as=nil
end

al.WindUI.CurrentInput=nil

if aB then
return
end

if not b then
ax:Set(not ax.Value,true,false)
else
local f=aq.Frame.Position.X.Offset
local g=f+at/2
local h=g>au/2
ax:Set(h,true,false)
end

ad(
aq.Frame.Bar.UIScale,
0.23,
{Scale=1},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ad(
aq.Frame.Bar.Highlight.BarOverlay,
0.23,
{ImageTransparency=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end)
end
end

return ap,am
end

return aa end function a.G()

local aa={}

local ab=a.load'd'local ac=
ab.New
local ad=ab.Tween


function aa.New(ae,af,ag,ah,ai,aj)
local ak={}

af=af or"sfsymbols:checkmark"

local al=9

local am=ab.Image(
af,
af,
0,
(aj and aj.Window.Folder or"Temp"),
"Checkbox",
true,
false,
"CheckboxIcon"
)
am.Size=UDim2.new(1,-26+ag,1,-26+ag)
am.AnchorPoint=Vector2.new(0.5,0.5)
am.Position=UDim2.new(0.5,0,0.5,0)


local an=ab.NewRoundFrame(al,"Squircle",{
ImageTransparency=.85,
ThemeTag={
ImageColor3="Text"
},
Parent=ah,
Size=UDim2.new(0,26,0,26),
},{
ab.NewRoundFrame(al,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Layer",
ThemeTag={
ImageColor3="Checkbox",
},
ImageTransparency=1,
}),
ab.NewRoundFrame(al,"Glass-1.4",{
Size=UDim2.new(1,0,1,0),
Name="Stroke",
ThemeTag={
ImageColor3="CheckboxBorder",
ImageTransparency="CheckboxBorderTransparency",
},
},{







}),

am,
},true)

function ak.Set(ao,ap)
if ap then
ad(an.Layer,0.06,{
ImageTransparency=0,
}):Play()



ad(am.ImageLabel,0.06,{
ImageTransparency=0,
}):Play()
else
ad(an.Layer,0.05,{
ImageTransparency=1,
}):Play()



ad(am.ImageLabel,0.06,{
ImageTransparency=1,
}):Play()
end

task.spawn(function()
if ai then
ab.SafeCallback(ai,ap)
end
end)
end

return an,ak
end


return aa end function a.H()
local aa=a.load'd'local ab=
aa.New local ac=
aa.Tween

local ad=a.load'F'.New
local ae=a.load'G'.New

local af={}

function af.New(ag,ah)
local ai={
__type="Toggle",
Title=ah.Title or"Toggle",
Desc=ah.Desc or nil,
Locked=ah.Locked or false,
LockedTitle=ah.LockedTitle,
Value=ah.Value,
Icon=ah.Icon or nil,
IconSize=ah.IconSize or 23,
Type=ah.Type or"Toggle",
Callback=ah.Callback or function()end,
UIElements={},
}
ai.ToggleFrame=a.load'C'{
Title=ai.Title,
Desc=ai.Desc,




Window=ah.Window,
Parent=ah.Parent,
TextOffset=(52),
Hover=false,
Tab=ah.Tab,
Index=ah.Index,
ElementTable=ai,
ParentConfig=ah,
Tags=ah.Tags,
}

local aj=true

if ai.Value==nil then
ai.Value=false
end

function ai.Lock(ak)
ai.Locked=true
aj=false
return ai.ToggleFrame:Lock(ai.LockedTitle)
end
function ai.Unlock(ak)
ai.Locked=false
aj=true
return ai.ToggleFrame:Unlock()
end

if ai.Locked then
ai:Lock()
end

local ak=ai.Value

local al,am
if ai.Type=="Toggle"then
al,am=ad(
ak,
ai.Icon,
ai.IconSize,
ai.ToggleFrame.UIElements.Main,
ai.Callback,
ah.Window.NewElements,
ah
)
elseif ai.Type=="Checkbox"then
al,am=ae(
ak,
ai.Icon,
ai.IconSize,
ai.ToggleFrame.UIElements.Main,
ai.Callback,
ah
)
else
error("Unknown Toggle Type: "..tostring(ai.Type))
end

al.AnchorPoint=Vector2.new(1,ah.Window.NewElements and 0 or 0.5)
al.Position=UDim2.new(1,0,ah.Window.NewElements and 0 or 0.5,0)

function ai.Set(an,ao,ap,aq)
if aj then
am:Set(ao,ap,aq or false)
ak=ao
ai.Value=ao
end
end

ai:Set(ak,false,ah.Window.NewElements)

local an=ah.WindUI.GenerateGUID()

if ah.Window.NewElements and am.Animate then
if ai.Type=="Toggle"then
aa.AddSignal(al.ToggleFrame.Hitbox.InputBegan,function(ao)
if
not ah.Window.IsToggleDragging
and(
ao.UserInputType==Enum.UserInputType.MouseButton1
or ao.UserInputType==Enum.UserInputType.Touch
)
then
if ah.WindUI.CurrentInput and ah.WindUI.CurrentInput~=an then
return
end

ah.WindUI.CurrentInput=an
am:Animate(ao,ai)
end
end)
end





else
if ai.Type=="Toggle"then
aa.AddSignal(al.ToggleFrame.Hitbox.MouseButton1Click,function()
ai:Set(not ai.Value,nil,ah.Window.NewElements)
end)
elseif ai.Type=="Checkbox"then
aa.AddSignal(al.MouseButton1Click,function()
ai:Set(not ai.Value,nil,ah.Window.NewElements)
end)
end
end

return ai.__type,ai
end

return af end function a.I()

local aa=(cloneref or clonereference or function(aa)
return aa
end)

local ac=aa(game:GetService"UserInputService")
local ad=aa(game:GetService"RunService")

local ae=a.load'd'
local af=ae.New
local ag=ae.Tween

local ah={}

local ai=false

function ah.New(aj,ak)
local al={
__type="Slider",
Title=ak.Title or nil,
Desc=ak.Desc or nil,
Locked=ak.Locked or nil,
LockedTitle=ak.LockedTitle,
Value=ak.Value or{},
Icons=ak.Icons or nil,
IsTooltip=ak.IsTooltip or false,
IsTextbox=ak.IsTextbox,
Step=ak.Step or 1,
Callback=ak.Callback or function()end,
UIElements={},
IsFocusing=false,

Width=ak.Width or 130,
TextBoxWidth=ak.Window.NewElements and 40 or 30,
ThumbSize=13,
IconSize=26,
}
if al.Icons=={}then
al.Icons={
From="sfsymbols:sunMinFill",
To="sfsymbols:sunMaxFill",
}
end
if al.IsTextbox==nil and al.Title==nil then
al.IsTextbox=false
else
al.IsTextbox=al.IsTextbox~=false
end

local am
local an
local ao
local ap=al.Value.Default or al.Value.Min or 0

local aq=ap
local ar=(ap-(al.Value.Min or 0))/((al.Value.Max or 100)-(al.Value.Min or 0))

local as=true
local at=al.Step%1~=0

local function FormatValue(au)
if at then
return tonumber(string.format("%.2f",au))
end
return math.floor(au+0.5)
end

local function CalculateValue(au)
if at then
return math.floor(au/al.Step+0.5)*al.Step
else
return math.floor(au/al.Step+0.5)*al.Step
end
end

local au,av
local aw=32
if al.Icons then
if al.Icons.From then
au=ae.Image(
al.Icons.From,
al.Icons.From,
0,
ak.Window.Folder,
"SliderIconFrom",
true,
true,
"SliderIconFrom"
)
au.Size=UDim2.new(0,al.IconSize,0,al.IconSize)
aw=aw+al.IconSize-2
end
if al.Icons.To then
av=ae.Image(
al.Icons.To,
al.Icons.To,
0,
ak.Window.Folder,
"SliderIconTo",
true,
true,
"SliderIconTo"
)
av.Size=UDim2.new(0,al.IconSize,0,al.IconSize)
aw=aw+al.IconSize-2
end
end
al.SliderFrame=a.load'C'{
Title=al.Title,
Desc=al.Desc,
Parent=ak.Parent,
TextOffset=al.Width,
Hover=false,
Tab=ak.Tab,
Index=ak.Index,
Window=ak.Window,
ElementTable=al,
ParentConfig=ak,
Tags=ak.Tags,
}

al.UIElements.SliderIcon=ae.NewRoundFrame(99,"Squircle",{
ImageTransparency=0.95,
Size=UDim2.new(1,not al.IsTextbox and-aw or(-al.TextBoxWidth-8),0,4),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Frame",
ThemeTag={
ImageColor3="Text",
},
},{
ae.NewRoundFrame(99,"Squircle",{
Name="Frame",
Size=UDim2.new(ar,0,1,0),
ImageTransparency=0.1,
ThemeTag={
ImageColor3="Slider",
},
},{
ae.NewRoundFrame(99,"Squircle",{
Size=UDim2.new(
0,
ak.Window.NewElements and(al.ThumbSize*2)or(al.ThumbSize+2),
0,
ak.Window.NewElements and(al.ThumbSize+4)or(al.ThumbSize+2)
),
Position=UDim2.new(1,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
ThemeTag={
ImageColor3="SliderThumb",
},
Name="Thumb",
},{
ae.NewRoundFrame(999,"SquircleGlass",{
Size=UDim2.new(1,0,1,0),
ImageColor3=Color3.new(1,1,1),
Name="Highlight",
ImageTransparency=0.5,
}),
}),
}),
})

al.UIElements.SliderContainer=af("Frame",{
Size=UDim2.new(al.Title==nil and 1 or 0,al.Title==nil and 0 or al.Width,0,0),
AutomaticSize="Y",
Position=UDim2.new(1,al.IsTextbox and(ak.Window.NewElements and-16 or 0)or 0,0.5,0),
AnchorPoint=Vector2.new(1,0.5),
BackgroundTransparency=1,
Parent=al.SliderFrame.UIElements.Main,
},{
af("UIListLayout",{
Padding=UDim.new(0,al.Title~=nil and 8 or 12),
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment=al.Icons
and(al.Icons.From and(al.Icons.To and"Center"or"Left")or al.Icons.To and"Right")
or"Center",
}),
au,
al.UIElements.SliderIcon,
av,
af("TextBox",{
Size=UDim2.new(0,al.TextBoxWidth,0,0),
TextXAlignment="Left",
Text=FormatValue(ap),
ThemeTag={
TextColor3="Text",
},
TextTransparency=0.4,
AutomaticSize="Y",
TextSize=15,
FontFace=Font.new(ae.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
LayoutOrder=-1,
Visible=al.IsTextbox,
}),
})

local ax
if al.IsTooltip then
ax=a.load'B'.New(
ap,
al.UIElements.SliderIcon.Frame.Thumb,
true,
"Secondary",
"Small",
false
)
ax.Container.AnchorPoint=Vector2.new(0.5,1)
ax.Container.Position=UDim2.new(0.5,0,0,-8)
end

function al.Lock(ay)
al.Locked=true
as=false
return al.SliderFrame:Lock(al.LockedTitle)
end
function al.Unlock(ay)
al.Locked=false
as=true
return al.SliderFrame:Unlock()
end

if al.Locked then
al:Lock()
end


local ay=ak.Tab.UIElements.ContainerFrame

function al.Set(az,aA,aB)
if as then
if
not al.IsFocusing
and not ai
and(
not aB
or(
aB.UserInputType==Enum.UserInputType.MouseButton1
or aB.UserInputType==Enum.UserInputType.Touch
)
)
then
if aB then
am=(aB.UserInputType==Enum.UserInputType.Touch)
ay.ScrollingEnabled=false
ai=true

local b=am and aB.Position.X or ac:GetMouseLocation().X
local d=math.clamp(
(b-al.UIElements.SliderIcon.AbsolutePosition.X)
/al.UIElements.SliderIcon.AbsoluteSize.X,
0,
1
)
aA=CalculateValue(al.Value.Min+d*(al.Value.Max-al.Value.Min))
aA=math.clamp(aA,al.Value.Min or 0,al.Value.Max or 100)

if aA~=aq then
ag(al.UIElements.SliderIcon.Frame,0.05,{Size=UDim2.new(d,0,1,0)}):Play()
al.UIElements.SliderContainer.TextBox.Text=FormatValue(aA)
if ax then
ax.TitleFrame.Text=FormatValue(aA)
end
al.Value.Default=FormatValue(aA)
aq=aA
ae.SafeCallback(al.Callback,FormatValue(aA))
end

an=ad.RenderStepped:Connect(function()
local f=am and aB.Position.X or ac:GetMouseLocation().X
local g=math.clamp(
(f-al.UIElements.SliderIcon.AbsolutePosition.X)
/al.UIElements.SliderIcon.AbsoluteSize.X,
0,
1
)
aA=CalculateValue(al.Value.Min+g*(al.Value.Max-al.Value.Min))

if aA~=aq then
ag(al.UIElements.SliderIcon.Frame,0.05,{Size=UDim2.new(g,0,1,0)}):Play()
al.UIElements.SliderContainer.TextBox.Text=FormatValue(aA)
if ax then
ax.TitleFrame.Text=FormatValue(aA)
end
al.Value.Default=FormatValue(aA)
aq=aA
ae.SafeCallback(al.Callback,FormatValue(aA))
end
end)


ao=ac.InputEnded:Connect(function(f)
if
(
f.UserInputType==Enum.UserInputType.MouseButton1
or f.UserInputType==Enum.UserInputType.Touch
)and aB==f
then
an:Disconnect()
ao:Disconnect()
ai=false
ay.ScrollingEnabled=true

ak.WindUI.CurrentInput=nil

if ak.Window.NewElements then
ag(al.UIElements.SliderIcon.Frame.Thumb,0.2,{
ImageTransparency=0,
Size=UDim2.new(
0,
ak.Window.NewElements and(al.ThumbSize*2)or(al.ThumbSize+2),
0,
ak.Window.NewElements and(al.ThumbSize+4)or(al.ThumbSize+2)
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut):Play()
end
if ax then
ax:Close(false)
end
end
end)
else
aA=math.clamp(aA,al.Value.Min or 0,al.Value.Max or 100)

local b=math.clamp(
(aA-(al.Value.Min or 0))/((al.Value.Max or 100)-(al.Value.Min or 0)),
0,
1
)
aA=CalculateValue(al.Value.Min+b*(al.Value.Max-al.Value.Min))

if aA~=aq then
ag(al.UIElements.SliderIcon.Frame,0.05,{Size=UDim2.new(b,0,1,0)}):Play()
al.UIElements.SliderContainer.TextBox.Text=FormatValue(aA)
if ax then
ax.TitleFrame.Text=FormatValue(aA)
end
al.Value.Default=FormatValue(aA)
aq=aA
ae.SafeCallback(al.Callback,FormatValue(aA))
end
end
end
end
end

function al.SetMax(az,aA)
al.Value.Max=aA

local aB=tonumber(al.Value.Default)or aq
if aB>aA then
al:Set(aA)
else
local b=
math.clamp((aB-(al.Value.Min or 0))/(aA-(al.Value.Min or 0)),0,1)
ag(al.UIElements.SliderIcon.Frame,0.1,{Size=UDim2.new(b,0,1,0)}):Play()
end
end

function al.SetMin(az,aA)
al.Value.Min=aA

local aB=tonumber(al.Value.Default)or aq
if aB<aA then
al:Set(aA)
else
local b=math.clamp((aB-aA)/((al.Value.Max or 100)-aA),0,1)
ag(al.UIElements.SliderIcon.Frame,0.1,{Size=UDim2.new(b,0,1,0)}):Play()
end
end

ae.AddSignal(al.UIElements.SliderContainer.TextBox.FocusLost,function(az)
local aA=tonumber(al.UIElements.SliderContainer.TextBox.Text)
if aA then
al:Set(aA)
else
al.UIElements.SliderContainer.TextBox.Text=FormatValue(aq)
if ax then
ax.TitleFrame.Text=FormatValue(aq)
end
end
end)

local az=ak.WindUI.GenerateGUID()

ae.AddSignal(al.UIElements.SliderContainer.InputBegan,function(aA)
if al.Locked or ai then
return
end
if
aA.UserInputType==Enum.UserInputType.MouseButton1
or aA.UserInputType==Enum.UserInputType.Touch
then
if ak.WindUI.CurrentInput and ak.WindUI.CurrentInput~=az then
return
end
ak.WindUI.CurrentInput=az

al:Set(ap,aA)


if ak.Window.NewElements then
ag(al.UIElements.SliderIcon.Frame.Thumb,0.24,{
ImageTransparency=0.85,
Size=UDim2.new(
0,
(ak.Window.NewElements and(al.ThumbSize*2)or al.ThumbSize)+8,
0,
al.ThumbSize+8
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
if ax then
ax:Open()
end

end
end)

return al.__type,al
end

return ah end function a.J()

local aa=a.load'd'
local ac=aa.New
local ad=aa.Tween

local ae={}

local function ToFiniteNumber(af)
local ag=tonumber(af)
if ag==nil or ag~=ag or math.abs(ag)==math.huge then
return nil
end

return ag
end

local function FormatNumber(af)
if af%1==0 then
return tostring(af)
end

return tostring(tonumber(string.format("%.2f",af)))
end

function ae.New(af,ag)
local ah=typeof(ag.Value)=="table"and ag.Value or{}
local ai=ToFiniteNumber(ah.Min)or ToFiniteNumber(ag.Min)or 0
local aj=ToFiniteNumber(ah.Max)or ToFiniteNumber(ag.Max)or 100

if ai>aj then
ai,aj=aj,ai
end

local ak=typeof(ag.Value)=="number"and ag.Value
or ToFiniteNumber(ah.Default)
or ToFiniteNumber(ag.Default)
or ai
ak=ToFiniteNumber(ak)or ai

local al=ag.Indeterminate==true

local am=ag.ShowValue
if am==nil then
am=not al
end

local an=math.max(ToFiniteNumber(ag.ValueWidth)or 44,0)

local ao={
__type="ProgressBar",
Title=ag.Title or"Progress",
Desc=ag.Desc or nil,
Value={
Min=ai,
Max=aj,
Default=math.clamp(ak,ai,aj),
},
ShowValue=am,
DisplayMode=ag.DisplayMode or"Percent",
Format=ag.Format,
Animate=ag.Animate~=false,
AnimationDuration=math.max(ToFiniteNumber(ag.AnimationDuration)or 0.15,0),
Indeterminate=al,
IndeterminateText=ag.IndeterminateText or"",
Speed=math.max(ToFiniteNumber(ag.Speed)or 1,0.01),
ControlGap=math.max(ToFiniteNumber(ag.ControlGap)or 16,0),
UIElements={},

Width=math.max(ToFiniteNumber(ag.Width)or 160,0),
ValueWidth=an,
}

local function GetRatio(ap)
if ao.Value.Max==ao.Value.Min then
return ap>=ao.Value.Max and 1 or 0
end

return math.clamp((ap-ao.Value.Min)/(ao.Value.Max-ao.Value.Min),0,1)
end

local function GetValueText(ap,aq)
if ao.Indeterminate then
return tostring(ao.IndeterminateText)
end

local ar=aq*100

if typeof(ao.Format)=="function"then
local as,at=
pcall(ao.Format,ap,ar,ao.Value.Min,ao.Value.Max)

if as and at~=nil then
return tostring(at)
end
end

if ao.DisplayMode=="Value"then
return FormatNumber(ap)
elseif ao.DisplayMode=="Fraction"then
return FormatNumber(ap).."/"..FormatNumber(ao.Value.Max)
end

return tostring(math.floor(ar+0.5)).."%"
end

ao.ProgressBarFrame=a.load'C'{
Title=ao.Title,
Desc=ao.Desc,
Parent=ag.Parent,
TextOffset=ao.Width+ao.ControlGap,
Hover=false,
Tab=ag.Tab,
Index=ag.Index,
Window=ag.Window,
ElementTable=ao,
ParentConfig=ag,
Tags=ag.Tags,
}

ao.UIElements.Fill=aa.NewRoundFrame(99,"Squircle",{
Name="Fill",
Size=ao.Indeterminate and UDim2.new(0.3,0,1,0)
or UDim2.new(GetRatio(ao.Value.Default),0,1,0),
Position=ao.Indeterminate and UDim2.new(-0.3,0,0,0)or UDim2.new(0,0,0,0),
ThemeTag={
ImageColor3="ProgressBar",
},
})

ao.UIElements.Bar=aa.NewRoundFrame(99,"Squircle",{
Name="Bar",
Size=UDim2.new(1,ao.ShowValue and-(ao.ValueWidth+8)or 0,0,6),
ClipsDescendants=true,
ImageTransparency=0.9,
ThemeTag={
ImageColor3="ProgressBarTrack",
ImageTransparency="ProgressBarTrackTransparency",
},
},{
ao.UIElements.Fill,
})

ao.UIElements.Value=ac("TextLabel",{
Name="Value",
Size=UDim2.new(0,ao.ValueWidth,0,20),
BackgroundTransparency=1,
FontFace=Font.new(aa.Font,Enum.FontWeight.Medium),
Text=GetValueText(ao.Value.Default,GetRatio(ao.Value.Default)),
TextSize=14,
TextTransparency=0.25,
TextTruncate="AtEnd",
TextXAlignment="Right",
Visible=ao.ShowValue,
ThemeTag={
TextColor3="ProgressBarText",
},
})

ao.UIElements.Container=ac("Frame",{
Name="ProgressBarContainer",
Size=UDim2.new(0,ao.Width,0,36),
Position=UDim2.new(1,0,ag.Window.NewElements and 0 or 0.5,0),
AnchorPoint=Vector2.new(1,ag.Window.NewElements and 0 or 0.5),
BackgroundTransparency=1,
Parent=ao.ProgressBarFrame.UIElements.Main,
},{
ac("UIListLayout",{
Padding=UDim.new(0,8),
FillDirection="Horizontal",
HorizontalAlignment="Right",
VerticalAlignment="Center",
}),
ao.UIElements.Bar,
ao.UIElements.Value,
})

if ao.Indeterminate then
local ap=ad(
ao.UIElements.Fill,
1/ao.Speed,
{Position=UDim2.new(1,0,0,0)},
Enum.EasingStyle.Linear,
Enum.EasingDirection.InOut,-1

)
aa.AddSignal(ao.UIElements.Bar.Destroying,function()
ap:Cancel()
end)
ap:Play()
end

local function Update(ap,aq)
local ar=ToFiniteNumber(ap)
if ar==nil then
return ao.Value.Default
end

ar=math.clamp(ar,ao.Value.Min,ao.Value.Max)
ao.Value.Default=ar

local as=GetRatio(ar)
local at=UDim2.new(as,0,1,0)

if ao.UIElements.Fill and not ao.Indeterminate then
if aq or not ao.Animate or ao.AnimationDuration<=0 then
ao.UIElements.Fill.Size=at
else
ad(
ao.UIElements.Fill,
ao.AnimationDuration,
{Size=at},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
end

ao.UIElements.Value.Text=GetValueText(ar,as)

return ar
end

function ao.Set(ap,aq)
return Update(aq,false)
end

function ao.Get(ap)
return ao.Value.Default
end

function ao.GetPercentage(ap)
return GetRatio(ao.Value.Default)*100
end

function ao.SetRange(ap,aq,ar)
aq=ToFiniteNumber(aq)
ar=ToFiniteNumber(ar)

if aq==nil or ar==nil then
return ao.Value.Min,ao.Value.Max
end

if aq>ar then
aq,ar=ar,aq
end

ao.Value.Min=aq
ao.Value.Max=ar
Update(ao.Value.Default,false)

return aq,ar
end

function ao.SetMin(ap,aq)
aq=ToFiniteNumber(aq)
if aq==nil then
return ao.Value.Min
end

ao:SetRange(aq,math.max(aq,ao.Value.Max))
return ao.Value.Min
end

function ao.SetMax(ap,aq)
aq=ToFiniteNumber(aq)
if aq==nil then
return ao.Value.Max
end

ao:SetRange(math.min(ao.Value.Min,aq),aq)
return ao.Value.Max
end

Update(ao.Value.Default,true)

return ao.__type,ao
end

return ae end function a.K()

local aa=(cloneref or clonereference or function(aa)
return aa
end)

local ac=aa(game:GetService"UserInputService")

local ad=a.load'd'
local ae=ad.New local af=
ad.Tween

local ag={
UICorner=6,
UIPadding=8,
}

local ah=a.load'w'.New

function ag.New(ai,aj)
local function NormalizeKeyCode(ak)
if typeof(ak)=="EnumItem"then
return ak.Name
elseif type(ak)=="string"then
return ak
else
return"F"
end
end

local ak={
__type="Keybind",
Title=aj.Title or"Keybind",
Desc=aj.Desc or nil,
Locked=aj.Locked or false,
LockedTitle=aj.LockedTitle,
Value=NormalizeKeyCode(aj.Value)or"F",
Callback=aj.Callback or function()end,
CanChange=aj.CanChange~=false,
Blacklist=aj.Blacklist or{},
Picking=false,
UIElements={},
}

local al={}

for am,an in next,ak.Blacklist do
table.insert(al,Enum.KeyCode[NormalizeKeyCode(an)])
end
table.insert(al,Enum.KeyCode[NormalizeKeyCode"Escape"])

local am=true

ak.KeybindFrame=a.load'C'{
Title=ak.Title,
Desc=ak.Desc,
Parent=aj.Parent,
TextOffset=85,
Hover=ak.CanChange,
Tab=aj.Tab,
Index=aj.Index,
Window=aj.Window,
ElementTable=ak,
ParentConfig=aj,
Tags=aj.Tags,
}

ak.UIElements.Keybind=ah(
ak.Value,
nil,
ak.KeybindFrame.UIElements.Main,
nil,
aj.Window.NewElements and 12 or 10
)

ak.UIElements.Keybind.Size=
UDim2.new(0,24+ak.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X,0,42)
ak.UIElements.Keybind.AnchorPoint=Vector2.new(1,0.5)
ak.UIElements.Keybind.Position=UDim2.new(1,0,0.5,0)
ak.UIElements.Keybind.Interactable=false

ae("UIScale",{
Parent=ak.UIElements.Keybind,
Scale=0.85,
})

ad.AddSignal(
ak.UIElements.Keybind.Frame.Frame.TextLabel:GetPropertyChangedSignal"TextBounds",
function()
ak.UIElements.Keybind.Size=
UDim2.new(0,24+ak.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X,0,42)
end
)

function ak.Lock(an)
ak.Locked=true
am=false
return ak.KeybindFrame:Lock(ak.LockedTitle)
end
function ak.Unlock(an)
ak.Locked=false
am=true
return ak.KeybindFrame:Unlock()
end

function ak.Set(an,ao)
local ap=NormalizeKeyCode(ao)
ak.Value=ap
ak.UIElements.Keybind.Frame.Frame.TextLabel.Text=ap
end

if ak.Locked then
ak:Lock()
end

local an

ad.AddSignal(ak.KeybindFrame.UIElements.Main.MouseButton1Click,function()
if am then
if ak.CanChange then
ak.Picking=true
ak.UIElements.Keybind.Frame.Frame.TextLabel.Text="..."



local ao
ao=ac.InputBegan:Connect(function(ap)
local aq

if ap.UserInputType==Enum.UserInputType.Keyboard then
if table.find(al,ap.KeyCode)then
aq=nil
return
else
aq=ap.KeyCode.Name
end
elseif
ap.UserInputType==Enum.UserInputType.MouseButton1
and not table.find(al,"MouseLeftButton")
then
aq="MouseLeftButton"
elseif
ap.UserInputType==Enum.UserInputType.MouseButton2
and not table.find(al,"MouseRightButton")
then
aq="MouseRightButton"
end

if an then
an:Disconnect()
end

an=ac.InputEnded:Connect(function(ar)
if
aq
and(
ar.KeyCode.Name==aq
or aq=="MouseLeft"and ar.UserInputType==Enum.UserInputType.MouseButton1
or aq=="MouseRight"and ar.UserInputType==Enum.UserInputType.MouseButton2
)
then
ak.Picking=false

ak.UIElements.Keybind.Frame.Frame.TextLabel.Text=aq
ak.Value=aq

ao:Disconnect()
an:Disconnect()
end
end)
end)
end
end
end)

ad.AddSignal(ac.InputBegan,function(ao,ap)
if ac:GetFocusedTextBox()then
return
end
if not am then
return
end
if ak.Picking then
return
end

if ao.UserInputType==Enum.UserInputType.Keyboard then
if ao.KeyCode.Name==ak.Value then
ad.SafeCallback(ak.Callback,ao.KeyCode.Name)
end
elseif ao.UserInputType==Enum.UserInputType.MouseButton1 and ak.Value=="MouseLeft"then
ad.SafeCallback(ak.Callback,"MouseLeft")
elseif ao.UserInputType==Enum.UserInputType.MouseButton2 and ak.Value=="MouseRight"then
ad.SafeCallback(ak.Callback,"MouseRight")
end
end)

return ak.__type,ak
end

return ag end function a.L()

local aa=a.load'd'local ac=
aa.New local ad=
aa.Tween

local ae={
UICorner=8,
UIPadding=8,
}local af=a.load'm'

.New
local ag=a.load'n'.New

function ae.New(ah,ai)
local aj={
__type="Input",
Title=ai.Title or"Input",
Desc=ai.Desc or nil,
Type=ai.Type or"Input",
Locked=ai.Locked or false,
LockedTitle=ai.LockedTitle,
InputIcon=ai.InputIcon or false,
Placeholder=ai.Placeholder or"Enter Text...",
Value=ai.Value or"",
Callback=ai.Callback or function()end,
ClearTextOnFocus=ai.ClearTextOnFocus or false,
UIElements={},

Width=150,
}

local ak=true

aj.InputFrame=a.load'C'{
Title=aj.Title,
Desc=aj.Desc,
Parent=ai.Parent,
TextOffset=aj.Width,
Hover=false,
Tab=ai.Tab,
Index=ai.Index,
Window=ai.Window,
ElementTable=aj,
ParentConfig=ai,
Tags=ai.Tags,
}

local al=ag(
aj.Placeholder,
aj.InputIcon,
aj.Type=="Textarea"and aj.InputFrame.UIElements.Container or aj.InputFrame.UIElements.Main,
aj.Type,
function(al)
aj:Set(al,true)
end,
nil,
ai.Window.NewElements and 12 or 10,
aj.ClearTextOnFocus
)

if aj.Type~="Textarea"then
al.Size=UDim2.new(0,aj.Width,0,36)
al.Position=UDim2.new(1,0,ai.Window.NewElements and 0 or 0.5,0)
al.AnchorPoint=Vector2.new(1,ai.Window.NewElements and 0 or 0.5)
else
al.Size=UDim2.new(1,0,0,148)
end






function aj.Lock(am)
aj.Locked=true
ak=false
return aj.InputFrame:Lock(aj.LockedTitle)
end
function aj.Unlock(am)
aj.Locked=false
ak=true
return aj.InputFrame:Unlock()
end

function aj.Set(am,an,ao)
if ak then
aj.Value=an
aa.SafeCallback(aj.Callback,an)

if not ao then
al.Frame.Frame.TextBox.Text=an
end
end
end

function aj.SetPlaceholder(am,an)
al.Frame.Frame.TextBox.PlaceholderText=an
aj.Placeholder=an
end

aj:Set(aj.Value)

if aj.Locked then
aj:Lock()
end

return aj.__type,aj
end

return ae end function a.M()

local aa=a.load'd'
local ae=aa.New

local af={}

function af.New(ag,ah)
local ai=ae("Frame",{
Size=ah.ParentType~="Group"and UDim2.new(1,0,0,1)or UDim2.new(0,1,1,0),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
BackgroundTransparency=.9,
ThemeTag={
BackgroundColor3="Text"
}
})
local aj=ae("Frame",{
Parent=ah.Parent,
Size=ah.ParentType~="Group"and UDim2.new(1,-7,0,7)or UDim2.new(0,7,1,-7),
BackgroundTransparency=1,
},{
ai
})

return"Divider",{__type="Divider",ElementFrame=aj}
end

return af end function a.N()
local aa={}

local ae=(cloneref or clonereference or function(ae)
return ae
end)

local af=ae(game:GetService"UserInputService")
local ag=ae(game:GetService"Players").LocalPlayer:GetMouse()
local ah=ae(game:GetService"Workspace").CurrentCamera local ai=

workspace.CurrentCamera

local aj=a.load'n'.New

local ak=a.load'd'
local al=ak.New
local am=ak.Tween

local an=0.67

function aa.New(ao,ap,aq,ar)
local as={}

if not ap.Callback then
ar="Menu"
end

ap.UIElements.UIListLayout=al("UIListLayout",{
Padding=UDim.new(0,aq.MenuPadding/1.5),
FillDirection="Vertical",
HorizontalAlignment="Center",
})

ap.UIElements.Menu=ak.NewRoundFrame(aq.MenuCorner,"Squircle",{
ThemeTag={
ImageColor3="DropdownBackground",
},
ImageTransparency=1,
Size=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(1,0),
Position=UDim2.new(1,0,0,0),
},{
al("UIPadding",{
PaddingTop=UDim.new(0,aq.MenuPadding),
PaddingLeft=UDim.new(0,aq.MenuPadding),
PaddingRight=UDim.new(0,aq.MenuPadding),
PaddingBottom=UDim.new(0,aq.MenuPadding),
}),
al("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,aq.MenuPadding),
}),
al("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,ap.SearchBarEnabled and-aq.MenuPadding-aq.SearchBarHeight),

ClipsDescendants=true,
LayoutOrder=999,
Name="Frame",
},{
al("UICorner",{
CornerRadius=UDim.new(0,aq.MenuCorner-aq.MenuPadding),
}),
al("ScrollingFrame",{
Size=UDim2.new(1,0,1,0),
ScrollBarThickness=0,
ScrollingDirection="Y",
AutomaticCanvasSize="Y",
CanvasSize=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
ScrollBarImageTransparency=1,
},{
ap.UIElements.UIListLayout,
}),
}),
})

ap.UIElements.MenuCanvas=al("Frame",{
Size=UDim2.new(0,ap.MenuWidth,0,300),
BackgroundTransparency=1,
Position=UDim2.new(-10,0,-10,0),
Visible=false,
Active=false,

Parent=ao.WindUI.DropdownGui,
AnchorPoint=Vector2.new(1,0),
},{
ap.UIElements.Menu,
al("UISizeConstraint",{
MinSize=Vector2.new(170,0),
MaxSize=Vector2.new(300,400),
}),
})

local function RecalculateCanvasSize()
ap.UIElements.Menu.Frame.ScrollingFrame.CanvasSize=
UDim2.fromOffset(0,ap.UIElements.UIListLayout.AbsoluteContentSize.Y)
end

local function RecalculateListSize()
local at=ao.WindUI.DropdownGui.AbsoluteSize.Y

local au=ap.UIElements.UIListLayout.AbsoluteContentSize.Y/ao.UIScale
local av=ap.SearchBarEnabled and(aq.SearchBarHeight+(aq.MenuPadding*3))
or(aq.MenuPadding*2)
local aw=au+av

if aw>at then
ap.UIElements.MenuCanvas.Size=
UDim2.fromOffset(ap.UIElements.MenuCanvas.AbsoluteSize.X,at)
else
ap.UIElements.MenuCanvas.Size=
UDim2.fromOffset(ap.UIElements.MenuCanvas.AbsoluteSize.X,aw)
end
end

function UpdatePosition()
local at=ap.UIElements.Dropdown or ap.DropdownFrame.UIElements.Main
local au=ap.UIElements.MenuCanvas

local av=ah.ViewportSize.Y
-(at.AbsolutePosition.Y+at.AbsoluteSize.Y)
-aq.MenuPadding
-54
local aw=au.AbsoluteSize.Y+aq.MenuPadding

local ax=-54
if av<aw then
ax=aw-av-54
end

au.Position=UDim2.new(
0,
at.AbsolutePosition.X+at.AbsoluteSize.X,
0,
at.AbsolutePosition.Y+at.AbsoluteSize.Y-ax+(aq.MenuPadding*2)
)
end

local at

function as.Display(au)
local av=ap.Values
local aw=""

if ap.Multi then
local ax={}
if typeof(ap.Value)=="table"then
for ay,az in ipairs(ap.Value)do
local aA=typeof(az)=="table"and az.Title or az
ax[aA]=true
end
end

for ay,az in ipairs(av)do
local aA=typeof(az)=="table"and az.Title or az
if ax[aA]then
aw=aw..aA..", "
end
end

if#aw>0 then
aw=aw:sub(1,#aw-2)
end
else
aw=typeof(ap.Value)=="table"and(ap.Value.Title or ap.Value[1])
or ap.Value
or""
end

if ap.UIElements.Dropdown then
ap.UIElements.Dropdown.Frame.Frame.TextLabel.Text=(aw==""and"--"or aw)
end
end

local function Callback(au)
as:Display()
if ap.Locked then
return
end

if ap.Callback then
task.spawn(function()
if ap.Locked then
return
end
ak.SafeCallback(ap.Callback,ap.Value)
end)
else
task.spawn(function()
if ap.Locked then
return
end
ak.SafeCallback(au)
end)
end
end

function as.LockValues(au,av)
if not av then
return
end

for aw,ax in next,ap.Tabs do
if ax and ax.UIElements and ax.UIElements.TabItem then
local ay=ax.Name
local az=false

for aA,aB in next,av do
if ay==aB then
az=true
break
end
end

if az then
am(ax.UIElements.TabItem,0.1,{ImageTransparency=1}):Play()

am(ax.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0.6}):Play()
if ax.UIElements.TabIcon then
am(ax.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0.6}):Play()
end

ax.UIElements.TabItem.Active=false
ax.Locked=true
else
if ax.Selected then
am(ax.UIElements.TabItem,0.1,{ImageTransparency=an}):Play()

am(ax.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0}):Play()
if ax.UIElements.TabIcon then
am(ax.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0}):Play()
end
else
am(ax.UIElements.TabItem,0.1,{ImageTransparency=1}):Play()

am(
ax.UIElements.TabItem.Frame.Title.TextLabel,
0.1,
{TextTransparency=ar=="Dropdown"and 0.4 or 0.05}
):Play()
if ax.UIElements.TabIcon then
am(
ax.UIElements.TabIcon.ImageLabel,
0.1,
{ImageTransparency=ar=="Dropdown"and 0.2 or 0}
):Play()
end
end

ax.UIElements.TabItem.Active=true
ax.Locked=false
end
end
end
end

function as.Refresh(au,av)
if ao.Window.Destroyed then
return
end

for aw,ax in next,ap.UIElements.Menu.Frame.ScrollingFrame:GetChildren()do
if not ax:IsA"UIListLayout"then
ax:Destroy()
end
end

ap.Tabs={}

if ap.SearchBarEnabled then
if not at then
at=aj("Search...","search",ap.UIElements.Menu,nil,function(aw)
for ax,ay in next,ap.Tabs do
if string.find(string.lower(ay.Name),string.lower(aw),1,true)then
ay.UIElements.TabItem.Visible=true
else
ay.UIElements.TabItem.Visible=false
end
RecalculateListSize()
RecalculateCanvasSize()
end
end,true)
at.Size=UDim2.new(1,0,0,aq.SearchBarHeight)
at.Position=UDim2.new(0,0,0,0)
at.Name="SearchBar"
end
end

for aw,ax in next,av do
if ax.Type~="Divider"then
local ay={
Name=typeof(ax)=="table"and ax.Title or ax,
Desc=typeof(ax)=="table"and ax.Desc or nil,
Icon=typeof(ax)=="table"and ax.Icon or nil,
IconSize=typeof(ax)=="table"and ax.IconSize or nil,
Original=ax,
Selected=false,
Locked=typeof(ax)=="table"and ax.Locked or false,
UIElements={},
}
local az
if ay.Icon then
az=ak.Image(ay.Icon,ay.Icon,0,ao.Window.Folder,"Dropdown",true)
az.Size=
UDim2.new(0,ay.IconSize or aq.TabIcon,0,ay.IconSize or aq.TabIcon)
az.ImageLabel.ImageTransparency=ar=="Dropdown"and 0.2 or 0
ay.UIElements.TabIcon=az
end
ay.UIElements.TabItem=ak.NewRoundFrame(
aq.MenuCorner-aq.MenuPadding,
"Squircle",
{
Size=UDim2.new(1,0,0,36),
AutomaticSize=ay.Desc and"Y",
ImageTransparency=1,
Parent=ap.UIElements.Menu.Frame.ScrollingFrame,

ThemeTag={
ImageColor3="DropdownTabBackground",
},
Active=not ay.Locked,
},
{
ak.NewRoundFrame(aq.MenuCorner-aq.MenuPadding,"Glass-1.4",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="DropdownTabBorder",
},
ImageTransparency=1,
Name="Highlight",
},{













}),
al("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
al("UIListLayout",{
Padding=UDim.new(0,aq.TabPadding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
al("UIPadding",{
PaddingTop=UDim.new(0,aq.TabPadding),
PaddingLeft=UDim.new(0,aq.TabPadding),
PaddingRight=UDim.new(0,aq.TabPadding),
PaddingBottom=UDim.new(0,aq.TabPadding),
}),
al("UICorner",{
CornerRadius=UDim.new(0,aq.MenuCorner-aq.MenuPadding),
}),
az,
al("Frame",{
Size=UDim2.new(1,az and-aq.TabPadding-aq.TabIcon or 0,0,0),
BackgroundTransparency=1,
AutomaticSize="Y",
Name="Title",
},{
al("TextLabel",{
Text=ay.Name,
TextXAlignment="Left",
FontFace=Font.new(ak.Font,Enum.FontWeight.Medium),
ThemeTag={
TextColor3="Text",
BackgroundColor3="Text",
},
TextSize=15,
BackgroundTransparency=1,
TextTransparency=ar=="Dropdown"and 0.4 or 0.05,
LayoutOrder=999,
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
}),
al("TextLabel",{
Text=ay.Desc or"",
TextXAlignment="Left",
FontFace=Font.new(ak.Font,Enum.FontWeight.Regular),
ThemeTag={
TextColor3="Text",
BackgroundColor3="Text",
},
TextSize=15,
BackgroundTransparency=1,
TextTransparency=ar=="Dropdown"and 0.6 or 0.35,
LayoutOrder=999,
AutomaticSize="Y",
TextWrapped=true,
Size=UDim2.new(1,0,0,0),
Visible=ay.Desc and true or false,
Name="Desc",
}),
al("UIListLayout",{
Padding=UDim.new(0,aq.TabPadding/3),
FillDirection="Vertical",
}),
}),
}),
},
true
)

if ay.Locked then
ay.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency=0.6
if ay.UIElements.TabIcon then
ay.UIElements.TabIcon.ImageLabel.ImageTransparency=0.6
end
end

if ap.Multi and typeof(ap.Value)=="string"then
for aA,aB in next,ap.Values do
if typeof(aB)=="table"then
if aB.Title==ap.Value then
ap.Value={aB}
end
else
if aB==ap.Value then
ap.Value={ap.Value}
end
end
end
end

if ap.Multi then
local aA=false
if typeof(ap.Value)=="table"then
for aB,b in ipairs(ap.Value)do
local d=typeof(b)=="table"and b.Title or b
if d==ay.Name then
aA=true
break
end
end
end
ay.Selected=aA
else
local aA=typeof(ap.Value)=="table"and ap.Value.Title or ap.Value
ay.Selected=aA==ay.Name
end

if ay.Selected and not ay.Locked then
ay.UIElements.TabItem.ImageTransparency=an

ay.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency=0
if ay.UIElements.TabIcon then
ay.UIElements.TabIcon.ImageLabel.ImageTransparency=0
end
end

ap.Tabs[aw]=ay

as:Display()

if ar=="Dropdown"then
ak.AddSignal(ay.UIElements.TabItem.MouseButton1Click,function()
if ap.Locked or ay.Locked then
return
end

if ap.Multi then
if not ay.Selected then
ay.Selected=true
am(
ay.UIElements.TabItem,
0.1,
{ImageTransparency=an}
):Play()

am(ay.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0}):Play()
if ay.UIElements.TabIcon then
am(ay.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0}):Play()
end
table.insert(ap.Value,ay.Original)
else
if not ap.AllowNone and#ap.Value==1 then
return
end
ay.Selected=false
am(ay.UIElements.TabItem,0.1,{ImageTransparency=1}):Play()

am(ay.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0.4}):Play()
if ay.UIElements.TabIcon then
am(ay.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0.2}):Play()
end

for aA,aB in next,ap.Value do
if typeof(aB)=="table"and(aB.Title==ay.Name)or(aB==ay.Name)then
table.remove(ap.Value,aA)
break
end
end
end
else
for aA,aB in next,ap.Tabs do
am(aB.UIElements.TabItem,0.1,{ImageTransparency=1}):Play()

am(
aB.UIElements.TabItem.Frame.Title.TextLabel,
0.1,
{TextTransparency=0.4}
):Play()
if aB.UIElements.TabIcon then
am(aB.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0.2}):Play()
end
aB.Selected=false
end
ay.Selected=true
am(ay.UIElements.TabItem,0.1,{ImageTransparency=an}):Play()

am(ay.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0}):Play()
if ay.UIElements.TabIcon then
am(ay.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0}):Play()
end
ap.Value=ay.Original
end
Callback()
end)
elseif ar=="Menu"then
if not ay.Locked then
ak.AddSignal(ay.UIElements.TabItem.MouseEnter,function()
am(ay.UIElements.TabItem,0.08,{ImageTransparency=an}):Play()
end)
ak.AddSignal(ay.UIElements.TabItem.InputEnded,function()
am(ay.UIElements.TabItem,0.08,{ImageTransparency=1}):Play()
end)
end
ak.AddSignal(ay.UIElements.TabItem.MouseButton1Click,function()
if ap.Locked or ay.Locked then
return
end
Callback(ax.Callback or function()end)
end)
end

RecalculateCanvasSize()
RecalculateListSize()
else a.load'M'
:New{Parent=ap.UIElements.Menu.Frame.ScrollingFrame}
end
end










ap.UIElements.MenuCanvas.Size=UDim2.new(
0,
ap.MenuWidth+6+6+5+5+18+6+6,
ap.UIElements.MenuCanvas.Size.Y.Scale,
ap.UIElements.MenuCanvas.Size.Y.Offset
)
Callback()

ap.Values=av
end

as:Refresh(ap.Values)

function as.Select(au,av)
if av then
ap.Value=av
else
if ap.Multi then
ap.Value={}
else
ap.Value=nil
end
end
as:Refresh(ap.Values)
end

RecalculateListSize()
RecalculateCanvasSize()

function as.Open(au)
if not ap.Locked then
ap.UIElements.Menu.Visible=true
ap.UIElements.MenuCanvas.Visible=true
ap.UIElements.MenuCanvas.Active=true
ap.UIElements.Menu.Size=UDim2.new(1,0,0,0)
am(ap.UIElements.Menu,0.1,{
Size=UDim2.new(1,0,1,0),
ImageTransparency=0,
},Enum.EasingStyle.Quart,Enum.EasingDirection.Out):Play()

task.spawn(function()
task.wait(0.1)
if ap.Locked then
return
end
ap.Opened=true
end)

UpdatePosition()
end
end

function as.Close(au)
ap.Opened=false

am(ap.UIElements.Menu,0.25,{
Size=UDim2.new(1,0,0,0),
ImageTransparency=1,
},Enum.EasingStyle.Quart,Enum.EasingDirection.Out):Play()

task.spawn(function()
task.wait(0.1)
ap.UIElements.Menu.Visible=false
end)

task.spawn(function()
task.wait(0.25)
ap.UIElements.MenuCanvas.Visible=false
ap.UIElements.MenuCanvas.Active=false
end)
end

ak.AddSignal(
(
ap.UIElements.Dropdown and ap.UIElements.Dropdown.MouseButton1Click
or ap.DropdownFrame.UIElements.Main.MouseButton1Click
),
function()
as:Open()
end
)

ak.AddSignal(af.InputBegan,function(au)
if
au.UserInputType==Enum.UserInputType.MouseButton1
or au.UserInputType==Enum.UserInputType.Touch
then
local av=ap.UIElements.MenuCanvas
local aw,ax=av.AbsolutePosition,av.AbsoluteSize

local ay=ap.UIElements.Dropdown or ap.DropdownFrame.UIElements.Main
local az=ay.AbsolutePosition
local aA=ay.AbsoluteSize

local aB=ag.X>=az.X
and ag.X<=az.X+aA.X
and ag.Y>=az.Y
and ag.Y<=az.Y+aA.Y

local b=ag.X>=aw.X
and ag.X<=aw.X+ax.X
and ag.Y>=aw.Y
and ag.Y<=aw.Y+ax.Y

if ao.Window.CanDropdown and ap.Opened and not aB and not b then
as:Close()
end
end
end)

ak.AddSignal(
ap.UIElements.Dropdown and ap.UIElements.Dropdown:GetPropertyChangedSignal"AbsolutePosition"
or ap.DropdownFrame.UIElements.Main:GetPropertyChangedSignal"AbsolutePosition",
UpdatePosition
)

return as
end

return aa end function a.O()

local aa=(cloneref or clonereference or function(aa)
return aa
end)

aa(game:GetService"UserInputService")
aa(game:GetService"Players").LocalPlayer:GetMouse()local ae=
aa(game:GetService"Workspace").CurrentCamera

local af=a.load'd'
local ag=af.New local ah=
af.Tween

local ai=a.load'w'.New local aj=a.load'n'
.New
local ak=a.load'N'.New local al=

workspace.CurrentCamera

local am={
UICorner=10,
UIPadding=12,
MenuCorner=15,
MenuPadding=5,
TabPadding=10,
SearchBarHeight=39,
TabIcon=18,
}

function am.New(an,ao)
local ap={
__type="Dropdown",
Title=ao.Title or"Dropdown",
Desc=ao.Desc or nil,
Locked=ao.Locked or false,
LockedTitle=ao.LockedTitle,
Values=ao.Values or{},
MenuWidth=ao.MenuWidth or 180,
Value=ao.Value,
AllowNone=ao.AllowNone,
SearchBarEnabled=ao.SearchBarEnabled or false,
Multi=ao.Multi,
Callback=ao.Callback or nil,

UIElements={},

Opened=false,
Tabs={},

Width=150,
}

if ap.Multi and not ap.Value then
ap.Value={}
end
if ap.Values and typeof(ap.Value)=="number"then
ap.Value=ap.Values[ap.Value]
end

ap.DropdownFrame=a.load'C'{
Title=ap.Title,
Desc=ap.Desc,
Parent=ao.Parent,
TextOffset=ap.Callback and ap.Width or 20,
Hover=not ap.Callback and true or false,
Tab=ao.Tab,
Index=ao.Index,
Window=ao.Window,
ElementTable=ap,
ParentConfig=ao,
Tags=ao.Tags,
}

if ap.Callback then
ap.UIElements.Dropdown=
ai("",nil,ap.DropdownFrame.UIElements.Main,nil,ao.Window.NewElements and 12 or 10)

ap.UIElements.Dropdown.Frame.Frame.TextLabel.TextTruncate="AtEnd"
ap.UIElements.Dropdown.Frame.Frame.TextLabel.Size=
UDim2.new(1,ap.UIElements.Dropdown.Frame.Frame.TextLabel.Size.X.Offset-18-12-12,0,0)

ap.UIElements.Dropdown.Size=UDim2.new(0,ap.Width,0,36)
ap.UIElements.Dropdown.Position=UDim2.new(1,0,ao.Window.NewElements and 0 or 0.5,0)
ap.UIElements.Dropdown.AnchorPoint=Vector2.new(1,ao.Window.NewElements and 0 or 0.5)





end

ap.DropdownMenu=ak(ao,ap,am,"Dropdown")

ap.Display=ap.DropdownMenu.Display
ap.Refresh=ap.DropdownMenu.Refresh
ap.Select=ap.DropdownMenu.Select
ap.Open=ap.DropdownMenu.Open
ap.Close=ap.DropdownMenu.Close

ag("ImageLabel",{
Image=af.Icon"chevrons-up-down"[1],
ImageRectOffset=af.Icon"chevrons-up-down"[2].ImageRectPosition,
ImageRectSize=af.Icon"chevrons-up-down"[2].ImageRectSize,
Size=UDim2.new(0,18,0,18),
Position=UDim2.new(1,ap.UIElements.Dropdown and-12 or 0,0.5,0),
ThemeTag={
ImageColor3="Icon",
},
AnchorPoint=Vector2.new(1,0.5),
Parent=ap.UIElements.Dropdown and ap.UIElements.Dropdown.Frame
or ap.DropdownFrame.UIElements.Main,
})

function ap.Lock(aq)
ap.Locked=true
if ap.Opened or ap.UIElements.MenuCanvas.Visible then
ap:Close()
end
return ap.DropdownFrame:Lock(ap.LockedTitle)
end
function ap.Unlock(aq)
ap.Locked=false
return ap.DropdownFrame:Unlock()
end

if ap.Locked then
ap:Lock()
end

return ap.__type,ap
end

return am end function a.P()




local aa={}
local af={
lua={
"and",
"break",
"or",
"else",
"elseif",
"if",
"then",
"until",
"repeat",
"while",
"do",
"for",
"in",
"end",
"local",
"return",
"function",
"export",
},
rbx={
"game",
"workspace",
"script",
"math",
"string",
"table",
"task",
"wait",
"select",
"next",
"Enum",
"tick",
"assert",
"shared",
"loadstring",
"tonumber",
"tostring",
"type",
"typeof",
"unpack",
"Instance",
"CFrame",
"Vector3",
"Vector2",
"Color3",
"UDim",
"UDim2",
"Ray",
"BrickColor",
"OverlapParams",
"RaycastParams",
"Axes",
"Random",
"Region3",
"Rect",
"TweenInfo",
"collectgarbage",
"not",
"utf8",
"pcall",
"xpcall",
"_G",
"setmetatable",
"getmetatable",
"os",
"pairs",
"ipairs",
},
operators={
"#",
"+",
"-",
"*",
"%",
"/",
"^",
"=",
"~",
"=",
"<",
">",
},
}

local ag={
numbers=Color3.fromHex"#FAB387",
boolean=Color3.fromHex"#FAB387",
operator=Color3.fromHex"#94E2D5",
lua=Color3.fromHex"#CBA6F7",
rbx=Color3.fromHex"#F38BA8",
str=Color3.fromHex"#A6E3A1",
comment=Color3.fromHex"#9399B2",
null=Color3.fromHex"#F38BA8",
call=Color3.fromHex"#89B4FA",
self_call=Color3.fromHex"#89B4FA",
local_property=Color3.fromHex"#CBA6F7",
}

local function createKeywordSet(ai)
local ak={}
for al,am in ipairs(ai)do
ak[am]=true
end
return ak
end

local ai=createKeywordSet(af.lua)
local ak=createKeywordSet(af.rbx)
local al=createKeywordSet(af.operators)

local function getHighlight(am,an)
local ao=am[an]

if ag[ao.."_color"]then
return ag[ao.."_color"]
end

if tonumber(ao)then
return ag.numbers
elseif ao=="nil"then
return ag.null
elseif ao:sub(1,2)=="--"then
return ag.comment
elseif al[ao]then
return ag.operator
elseif ai[ao]then
return ag.lua
elseif ak[ao]then
return ag.rbx
elseif ao:sub(1,1)=='"'or ao:sub(1,1)=="'"then
return ag.str
elseif ao=="true"or ao=="false"then
return ag.boolean
end

if am[an+1]=="("then
if am[an-1]==":"then
return ag.self_call
end

return ag.call
end

if am[an-1]=="."then
if am[an-2]=="Enum"then
return ag.rbx
end

return ag.local_property
end
end

function aa.run(am,an)
if an~=nil then
for ao,ap in next,an do
ag[ao]=ap
end
end

local ao={}
local ap=""

local aq=false
local ar=false
local as=false

for at=1,#am do
local au=am:sub(at,at)

if ar then
if au=="\n"and not as then
table.insert(ao,ap)
table.insert(ao,au)
ap=""

ar=false
elseif am:sub(at-1,at)=="]]"and as then
ap=ap.."]"

table.insert(ao,ap)
ap=""

ar=false
as=false
else
ap=ap..au
end
elseif aq then
if au==aq and am:sub(at-1,at-1)~="\\"or au=="\n"then
ap=ap..au
aq=false
else
ap=ap..au
end
else
if am:sub(at,at+1)=="--"then
table.insert(ao,ap)
ap="-"
ar=true
as=am:sub(at+2,at+3)=="[["
elseif au=='"'or au=="'"then
table.insert(ao,ap)
ap=au
aq=au
elseif al[au]then
table.insert(ao,ap)
table.insert(ao,au)
ap=""
elseif au:match"[%w_]"then
ap=ap..au
else
table.insert(ao,ap)
table.insert(ao,au)
ap=""
end
end
end

table.insert(ao,ap)

local at={}

for au,av in ipairs(ao)do
local aw=getHighlight(ao,au)

if aw then
local ax=string.format(
'<font color = "#%s">%s</font>',
aw:ToHex(),
av:gsub("<","&lt;"):gsub(">","&gt;")
)

table.insert(at,ax)
else
table.insert(at,av)
end
end

return table.concat(at)
end

return aa end function a.Q()

local aa={}

local af=a.load'd'
local ag=af.New
local ai=af.Tween

local ak=a.load'P'

function aa.New(al,am,an,ao,ap)
local aq={
Radius=am.ElementConfig.UICorner,
Padding=am.NewElements and am.ElementConfig.UIPadding+4 or am.ElementConfig.UIPadding,

CodeFrame=nil,
}

local ar=ag("TextLabel",{
Text="",
TextColor3=Color3.fromHex"#CDD6F4",
TextTransparency=0,
TextSize=al.CodeSize,
TextWrapped=false,
LineHeight=1.15,
RichText=true,
TextXAlignment="Left",
Size=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
AutomaticSize="XY",
},{
ag("UIPadding",{
PaddingTop=UDim.new(0,aq.Padding+3),
PaddingLeft=UDim.new(0,aq.Padding+3),
PaddingRight=UDim.new(0,aq.Padding+3),
PaddingBottom=UDim.new(0,aq.Padding+3),
}),
})
ar.Font="Code"

local as=ag("ScrollingFrame",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
AutomaticCanvasSize=al.Height~=nil and"XY"or"X",
ScrollingDirection=al.Height~=nil and"XY"or"X",
ElasticBehavior="Never",
CanvasSize=UDim2.new(0,0,0,0),
ScrollBarThickness=0,
},{
ar,
})

local at=al.CanCopied
and ag("TextButton",{
BackgroundTransparency=1,
Size=UDim2.new(0,35,0,35),
Position=UDim2.new(1,-aq.Padding/2,0,aq.Padding/2),
AnchorPoint=Vector2.new(1,0),
Visible=ao and true or false,
},{
af.NewRoundFrame(aq.Radius-4,"Squircle",{



ImageColor3=Color3.fromHex"#ffffff",
ImageTransparency=1,
Size=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Button",
},{
ag("UIScale",{
Scale=1,
}),
ag("ImageLabel",{
Image=af.Icon"copy"[1],
ImageRectSize=af.Icon"copy"[2].ImageRectSize,
ImageRectOffset=af.Icon"copy"[2].ImageRectPosition,
BackgroundTransparency=1,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Size=UDim2.new(0,12,0,12),



ImageColor3=Color3.fromHex"#ffffff",
ImageTransparency=0.1,
}),
}),
})
or nil

local au,av=af.NewRoundFrame(aq.Radius,"SquircleOutline",{
Size=UDim2.new(1,0,1,0),



ImageColor3=Color3.fromHex"#ffffff",
ImageTransparency=0.955,
Visible=false,
})

local aw,ax=af.NewRoundFrame(aq.Radius,"Squircle-TL-TR",{



ImageColor3=Color3.fromHex"#ffffff",
ImageTransparency=0.96,
Size=UDim2.new(1,0,0,20+(aq.Padding*2)),
Visible=al.Title and true or false,
},{










ag("TextLabel",{
Text=al.Title,



TextColor3=Color3.fromHex"#ffffff",
TextTransparency=0.2,
TextSize=18,
AutomaticSize="Y",
FontFace=Font.new(af.Font,Enum.FontWeight.Medium),
TextXAlignment="Left",
BackgroundTransparency=1,
TextTruncate="AtEnd",
Size=UDim2.new(1,at and-20-(aq.Padding*2),0,0),
}),
ag("UIPadding",{

PaddingLeft=UDim.new(0,aq.Padding+3),
PaddingRight=UDim.new(0,aq.Padding+3),

}),
ag("UIListLayout",{
Padding=UDim.new(0,aq.Padding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
})

local ay,az=af.NewRoundFrame(aq.Radius,"Squircle",{



ImageColor3=Color3.fromHex"#212121",
ImageTransparency=0.035,
Size=al.Height~=nil
and UDim2.new(1,0,al.Height.Scale,al.Height.Offset==0 and-40 or al.Height.Offset)
or UDim2.new(1,0,0,20+(aq.Padding*2)),
AutomaticSize=al.Height~=nil and"None"or"Y",
Parent=an,
},{
au,
ag("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,al.Height~=nil and 1 or 0,0),
AutomaticSize=al.Height~=nil and"None"or"Y",
},{
aw,
as,
ag("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
}),
}),
at,
},nil,true)

aq.CodeFrame=ay
aq.CodeFrameModule=az
aq.OutlineFrame=au
aq.OutlineFrameModule=av
aq.TopbarFrame=aw
aq.TopbarFrameModule=ax

af.AddSignal(ar:GetPropertyChangedSignal"TextBounds",function()
if al.Height~=nil then
as.Size=UDim2.new(1,0,1,al.Title~=nil and-(20+(aq.Padding*2))or nil)
else
as.Size=
UDim2.new(1,0,0,(ar.TextBounds.Y/(ap or 1))+((aq.Padding+3)*2))
end
end)

function aq.Set(aA)
ar.Text=ak.run(aA,al.CodeTheme)
end

function aq.Destroy()
ay:Destroy()
aq=nil
end

aq.Set(al.Code)

if at then
af.AddSignal(at.InputBegan,function(aA:InputObject)
if
aA.UserInputType==Enum.UserInputType.MouseButton1
or aA.UserInputType==Enum.UserInputType.Touch
then
ai(at.Button,0.05,{ImageTransparency=0.95}):Play()
ai(at.Button.UIScale,0.05,{Scale=0.9}):Play()
end
end)
af.AddSignal(at.InputEnded,function()
ai(at.Button,0.08,{ImageTransparency=1}):Play()
ai(at.Button.UIScale,0.08,{Scale=1}):Play()
end)
af.AddSignal(at.MouseButton1Click,function()
if ao then
ao()
local aA=af.Icon"check"
at.Button.ImageLabel.Image=aA[1]
at.Button.ImageLabel.ImageRectSize=aA[2].ImageRectSize
at.Button.ImageLabel.ImageRectOffset=aA[2].ImageRectPosition

task.delay(1,function()
local aB=af.Icon"copy"
at.Button.ImageLabel.Image=aB[1]
at.Button.ImageLabel.ImageRectSize=aB[2].ImageRectSize
at.Button.ImageLabel.ImageRectOffset=aB[2].ImageRectPosition
end)
end
end)
end

return aq
end

return aa end function a.R()

local aa=a.load'd'local af=
aa.New


local ag=a.load'Q'

local ai={}

function ai.New(ak,al)
local am={
__type="Code",
Title=al.Title,
Code=al.Code,
CodeSize=al.CodeSize or 18,
Height=al.Height,
CodeTheme=al.CodeTheme,
Locked=false,
CanCopied=al.CanCopied~=false,
OnCopy=al.OnCopy,

Index=al.Index,
}

local an=not am.Locked











local ao=ag.New(am,al.Window,al.Parent,function()
if an then
local ao=am.Title or"code"
local ap,aq=pcall(function()
if toclipboard then
toclipboard(am.Code)
end
if setclipboard then
setclipboard(am.Code)
end

if am.OnCopy then
am.OnCopy()
end
end)
if not ap then
al.WindUI:Notify{
Title="Error",
Content="The "..ao.." is not copied. Error: "..aq,
Icon="x",
Duration=5,
}
end
end
end,al.WindUI.UIScale)

function am.SetCode(ap,aq)
ao.Set(aq)
am.Code=aq
end

function am.Set(ap,aq)
return am.SetCode(aq)
end

function am.Destroy(ap)
ao.Destroy()
am=nil
end

function am.UpdateShape(ap)
if al.Window.NewElements then
local aq=aa:GetElementPosition(
ap.Elements,
am.Index,
al.ParentType=="HStack"or al.ParentType=="Group"
)

if aq and ao.CodeFrameModule then
ao.CodeFrameModule:SetType(aq)

print(aq)
ao.TopbarFrameModule:SetType(
table.find({"Squircle-BL-BR","SquircleH-BL-BR"},aq)~=nil and"Square"or aq
)
end
end
end

am.UIElements={Main=ao.CodeFrame}
am.ElementFrame=ao.CodeFrame

return am.__type,am
end

return ai end function a.S()

local aa=a.load'd'
local af=aa.New local ag=
aa.Tween

local ai=(cloneref or clonereference or function(ai)
return ai
end)

local ak=ai(game:GetService"UserInputService")
ai(game:GetService"TouchInputService")
local al=ai(game:GetService"RunService")
local am=ai(game:GetService"Players")local an=

al.RenderStepped
local ao=am.LocalPlayer
local ap=ao:GetMouse()

local aq=a.load'm'.New
local ar=a.load'n'.New

local as={
UICorner=9,

}

local at

function as.Colorpicker(au,av,aw,ax,ay)
local az={
__type="Colorpicker",
Title=av.Title,
Desc=av.Desc,
Default=av.Value or av.Default,
Callback=av.Callback,
Transparency=av.Transparency,
UIElements=av.UIElements,

TextPadding=10,
}

local aA={}
local aB=az.Transparency~=nil

function az.SetHSVFromRGB(b,d)
local f,g,h=Color3.toHSV(d)
az.Hue=f
az.Sat=g
az.Vib=h
end

az:SetHSVFromRGB(az.Default)

local b=a.load'o'
local d=b.Create(nil,"Dialog",aw,ax,aw.UIElements.Main.Main)

az.ColorpickerFrame=d

d.UIElements.Main.Size=UDim2.new(1,0,0,0)



local f,g,h=az.Hue,az.Sat,az.Vib

az.UIElements.Title=af("TextLabel",{
Text=az.Title,
TextSize=20,
FontFace=Font.new(aa.Font,Enum.FontWeight.SemiBold),
TextXAlignment="Left",
Size=UDim2.new(0,0,0,0),
AutomaticSize="Y",
ThemeTag={
TextColor3="Text",
},
BackgroundTransparency=1,
Parent=d.UIElements.Main,
},{
af("UIPadding",{
PaddingTop=UDim.new(0,az.TextPadding/2),
PaddingLeft=UDim.new(0,az.TextPadding/2),
PaddingRight=UDim.new(0,az.TextPadding/2),
PaddingBottom=UDim.new(0,az.TextPadding/2),
}),
})





local i=af("Frame",{
Size=UDim2.new(1,0,1,0),
Position=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
})

local l=af("Frame",{
Size=UDim2.new(0,14,0,14),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0,0),
Parent=i,
BackgroundColor3=az.Default,
},{
af("UIStroke",{
Thickness=2,
Transparency=0.1,
ThemeTag={
Color="Text",
},
}),
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
})

az.UIElements.SatVibMap=af("ImageLabel",{
Size=UDim2.fromOffset(160,158),
Position=UDim2.fromOffset(0,40+az.TextPadding),
Image="rbxassetid://4155801252",
BackgroundColor3=Color3.fromHSV(f,1,1),
BackgroundTransparency=0,
Parent=d.UIElements.Main,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),
aa.NewRoundFrame(8,"SquircleOutline",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
ZIndex=99999,
},{
af("UIGradient",{
Rotation=45,
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.0,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(1.0,Color3.fromRGB(255,255,255)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.0,0.1),
NumberSequenceKeypoint.new(0.5,1),
NumberSequenceKeypoint.new(1.0,0.1),
},
}),
}),

l,
})

az.UIElements.Inputs=af("Frame",{
AutomaticSize="XY",
Size=UDim2.new(0,0,0,0),
Position=UDim2.fromOffset(
aB and 240 or 210,
40+az.TextPadding
),
BackgroundTransparency=1,
Parent=d.UIElements.Main,
},{
af("UIListLayout",{
Padding=UDim.new(0,4),
FillDirection="Vertical",
}),
})





local m=af("Frame",{
BackgroundColor3=az.Default,
Size=UDim2.fromScale(1,1),
BackgroundTransparency=az.Transparency,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),
})

af("ImageLabel",{
Image="http://www.roblox.com/asset/?id=14204231522",
ImageTransparency=0.45,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.fromOffset(40,40),
BackgroundTransparency=1,
Position=UDim2.fromOffset(85,208+az.TextPadding),
Size=UDim2.fromOffset(75,24),
Parent=d.UIElements.Main,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),
aa.NewRoundFrame(8,"SquircleOutline",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
ZIndex=99999,
},{
af("UIGradient",{
Rotation=60,
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.0,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(1.0,Color3.fromRGB(255,255,255)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.0,0.1),
NumberSequenceKeypoint.new(0.5,1),
NumberSequenceKeypoint.new(1.0,0.1),
},
}),
}),







m,
})

local p=af("Frame",{
BackgroundColor3=az.Default,
Size=UDim2.fromScale(1,1),
BackgroundTransparency=0,
ZIndex=9,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),
})

af("ImageLabel",{
Image="http://www.roblox.com/asset/?id=14204231522",
ImageTransparency=0.45,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.fromOffset(40,40),
BackgroundTransparency=1,
Position=UDim2.fromOffset(0,208+az.TextPadding),
Size=UDim2.fromOffset(75,24),
Parent=d.UIElements.Main,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),







aa.NewRoundFrame(8,"SquircleOutline",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
ZIndex=99999,
},{
af("UIGradient",{
Rotation=60,
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.0,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(1.0,Color3.fromRGB(255,255,255)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.0,0.1),
NumberSequenceKeypoint.new(0.5,1),
NumberSequenceKeypoint.new(1.0,0.1),
},
}),
}),
p,
})

local r={}

for u=0,1,0.1 do
table.insert(r,ColorSequenceKeypoint.new(u,Color3.fromHSV(u,1,1)))
end

local u=af("UIGradient",{
Color=ColorSequence.new(r),
Rotation=90,
})

local v=af("Frame",{
Size=UDim2.new(0,14,0,14),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0,0),
Parent=i,


BackgroundColor3=az.Default,
},{
af("UIStroke",{
Thickness=2,
Transparency=0.1,
ThemeTag={
Color="Text",
},
}),
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
})

local x=af("Frame",{
Size=UDim2.fromOffset(6,192),
Position=UDim2.fromOffset(180,40+az.TextPadding),
Parent=d.UIElements.Main,
},{
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
u,
i,
})

local function CreateNewInput(z,A)
local B=ar(z,nil,az.UIElements.Inputs,nil,nil,nil,nil,nil,true)

af("TextLabel",{
BackgroundTransparency=1,
TextTransparency=0.4,
TextSize=17,
FontFace=Font.new(aa.Font,Enum.FontWeight.Regular),
AutomaticSize="XY",
ThemeTag={
TextColor3="Placeholder",
},
AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,-12,0.5,0),
Parent=B.Frame,
Text=z,
})

af("UIScale",{
Parent=B,
Scale=0.85,
})

B.Frame.Frame.TextBox.Text=A
B.Size=UDim2.new(0,150,0,42)

return B
end

local function ToRGB(z)
return{
R=math.floor(z.R*255),
G=math.floor(z.G*255),
B=math.floor(z.B*255),
}
end

local z=CreateNewInput("Hex","#"..az.Default:ToHex())

local A=CreateNewInput("Red",ToRGB(az.Default).R)
local B=CreateNewInput("Green",ToRGB(az.Default).G)
local C=CreateNewInput("Blue",ToRGB(az.Default).B)
local F
if aB then
F=CreateNewInput("Alpha",((1-az.Transparency)*100).."%")
end

local G=af("Frame",{
Size=UDim2.new(0,0,0,40),
AutomaticSize="Y",
Position=UDim2.new(0,0,0,254+az.TextPadding),
BackgroundTransparency=1,
Parent=d.UIElements.Main,
LayoutOrder=4,
},{
af("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Horizontal",
HorizontalAlignment="Right",
}),






})

aa.AddSignal(d.UIElements.Main:GetPropertyChangedSignal"AbsoluteSize",function()
az.UIElements.Title.Size=UDim2.new(
0,
d.UIElements.Main.AbsoluteSize.X/av.UIScale-(d.UIPadding*2),
0,
0
)
G.Size=UDim2.new(
0,
d.UIElements.Main.AbsoluteSize.X/av.UIScale-d.UIPadding*2,
0,
40
)
end)

local H={
{
Title="Cancel",
Variant="Secondary",
Callback=function()
av.IsShowed=false
for H,J in next,aA do
J:Disconnect()
end
aA={}
end,
},
{
Title="Apply",

Variant="Primary",
Callback=function()
av.IsShowed=false
for H,J in next,aA do
J:Disconnect()
end
aA={}

ay(Color3.fromHSV(az.Hue,az.Sat,az.Vib),az.Transparency)
end,
},
}

for J,L in next,H do
local M=aq(
L.Title,
L.Icon,
L.Callback,
L.Variant,
G,
d,
true
)
M.Size=UDim2.new(0.5,-3,0,40)
M.AutomaticSize="None"
end

local J,L,M
if aB then
local N=af("Frame",{
Size=UDim2.new(1,0,1,0),
Position=UDim2.fromOffset(0,0),
BackgroundTransparency=1,
})

L=af("ImageLabel",{
Size=UDim2.new(0,14,0,14),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0,0),
ThemeTag={
BackgroundColor3="Text",
},
Parent=N,
},{
af("UIStroke",{
Thickness=2,
Transparency=0.1,
ThemeTag={
Color="Text",
},
}),
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
})

M=af("Frame",{
Size=UDim2.fromScale(1,1),
},{
af("UIGradient",{
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,0),
NumberSequenceKeypoint.new(1,1),
},
Rotation=270,
}),
af("UICorner",{
CornerRadius=UDim.new(0,6),
}),
})

J=af("Frame",{
Size=UDim2.fromOffset(6,192),
Position=UDim2.fromOffset(210,40+az.TextPadding),
Parent=d.UIElements.Main,
BackgroundTransparency=1,
},{
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
af("ImageLabel",{
Image="rbxassetid://14204231522",
ImageTransparency=0.45,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.fromOffset(40,40),
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
},{
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
}),
M,
N,
})
end

function az.Round(N,O,P)
if P==0 then
return math.floor(O)
end
O=tostring(O)
return O:find"%."and tonumber(O:sub(1,O:find"%."+P))or O
end

function az.Update(N,O,P)
if O then
f,g,h=Color3.toHSV(O)
else
f,g,h=az.Hue,az.Sat,az.Vib
end

az.UIElements.SatVibMap.BackgroundColor3=Color3.fromHSV(f,1,1)
l.Position=UDim2.new(g,0,1-h,0)
l.BackgroundColor3=Color3.fromHSV(f,g,h)
p.BackgroundColor3=Color3.fromHSV(f,g,h)
v.BackgroundColor3=Color3.fromHSV(f,1,1)
v.Position=UDim2.new(0.5,0,f,0)

z.Frame.Frame.TextBox.Text="#"..Color3.fromHSV(f,g,h):ToHex()
A.Frame.Frame.TextBox.Text=ToRGB(Color3.fromHSV(f,g,h)).R
B.Frame.Frame.TextBox.Text=ToRGB(Color3.fromHSV(f,g,h)).G
C.Frame.Frame.TextBox.Text=ToRGB(Color3.fromHSV(f,g,h)).B

if P or aB then
p.BackgroundTransparency=az.Transparency or P
M.BackgroundColor3=Color3.fromHSV(f,g,h)
L.BackgroundColor3=Color3.fromHSV(f,g,h)
L.BackgroundTransparency=az.Transparency or P
L.Position=UDim2.new(0.5,0,1-az.Transparency or P,0)
F.Frame.Frame.TextBox.Text=az:Round(
(1-az.Transparency or P)*100,
0
).."%"
end
end

az:Update(az.Default,az.Transparency)

local function GetRGB()
local N=Color3.fromHSV(az.Hue,az.Sat,az.Vib)
return{R=math.floor(N.r*255),G=math.floor(N.g*255),B=math.floor(N.b*255)}
end



local function clamp(N,O,P)
return math.clamp(tonumber(N)or 0,O,P)
end

table.insert(
aA,
aa.AddSignal(z.Frame.Frame.TextBox.FocusLost,function(N)
if N then
local O=z.Frame.Frame.TextBox.Text:gsub("#","")
local P,Q=pcall(Color3.fromHex,O)
if P and typeof(Q)=="Color3"then
az.Hue,az.Sat,az.Vib=Color3.toHSV(Q)
az:Update()
az.Default=Q
end
end
end)
)

local function updateColorFromInput(N,O)
aa.AddSignal(N.Frame.Frame.TextBox.FocusLost,function(P)
if P then
local Q=N.Frame.Frame.TextBox
local R=GetRGB()
local S=clamp(Q.Text,0,255)
Q.Text=tostring(S)

R[O]=S
local T=Color3.fromRGB(R.R,R.G,R.B)
az.Hue,az.Sat,az.Vib=Color3.toHSV(T)
az:Update()
end
end)
end

updateColorFromInput(A,"R")
updateColorFromInput(B,"G")
updateColorFromInput(C,"B")

if aB then
aa.AddSignal(F.Frame.Frame.TextBox.FocusLost,function(N)
if N then
local O=F.Frame.Frame.TextBox
local P=clamp(O.Text,0,100)
O.Text=tostring(P)

az.Transparency=1-P*0.01
az:Update(nil,az.Transparency)
end
end)
end



local function UpdateSatVib(N,O)
local P=N.AbsolutePosition.X
local Q=P+N.AbsoluteSize.X
local R=N.AbsolutePosition.Y
local S=R+N.AbsoluteSize.Y

local T=math.clamp(ap.X,P,Q)
local U=math.clamp(ap.Y,R,S)

O.Sat=(T-P)/(Q-P)
O.Vib=1-((U-R)/(S-R))

O:Update()
end

local function UpdateHue(N,O)
local P=N.AbsolutePosition.Y
local Q=P+N.AbsoluteSize.Y

local R=math.clamp(ap.Y,P,Q)

O.Hue=(R-P)/(Q-P)

O:Update()
end

local function UpdateTransparency(N,O)
local P=N.AbsolutePosition.Y
local Q=P+N.AbsoluteSize.Y

local R=math.clamp(ap.Y,P,Q)

O.Transparency=1-((R-P)/(Q-P))

O:Update()
end

local N=ax.GenerateGUID()

table.insert(
aA,
ak.InputChanged:Connect(function(O)
if
O.UserInputType~=Enum.UserInputType.MouseMovement
and O.UserInputType~=Enum.UserInputType.Touch
then
return
end

if at=="SatVib"then
UpdateSatVib(az.UIElements.SatVibMap,az)
elseif at=="Hue"then
UpdateHue(x,az)
elseif at=="Transparency"then
UpdateTransparency(J,az)
end
end)
)

table.insert(
aA,
az.UIElements.SatVibMap.InputBegan:Connect(function(O)
if
O.UserInputType~=Enum.UserInputType.MouseButton1
and O.UserInputType~=Enum.UserInputType.Touch
then
return
end

if ax.CurrentInput and ax.CurrentInput~=N then
return
end
ax.CurrentInput=N

if at and at~="SatVib"then
return
end

at="SatVib"

UpdateSatVib(az.UIElements.SatVibMap,az)
end)
)

table.insert(
aA,
x.InputBegan:Connect(function(O)
if
O.UserInputType~=Enum.UserInputType.MouseButton1
and O.UserInputType~=Enum.UserInputType.Touch
then
return
end

if ax.CurrentInput and ax.CurrentInput~=N then
return
end
ax.CurrentInput=N

if at and at~="Hue"then
return
end

at="Hue"

UpdateHue(x,az)
end)
)

if J then
table.insert(
aA,
J.InputBegan:Connect(function(O)
if
O.UserInputType~=Enum.UserInputType.MouseButton1
and O.UserInputType~=Enum.UserInputType.Touch
then
return
end

if ax.CurrentInput and ax.CurrentInput~=N then
return
end
ax.CurrentInput=N

if at and at~="Transparency"then
return
end

at="Transparency"

UpdateTransparency(J,az)
end)
)
end

table.insert(
aA,
ak.InputEnded:Connect(function(O)
at=nil

if ax.CurrentInput and ax.CurrentInput~=N then
return
end
ax.CurrentInput=nil
end)
)

return az
end

function as.New(au,av)
local aw={
__type="Colorpicker",
Title=av.Title or"Colorpicker",
Desc=av.Desc or nil,
Locked=av.Locked or false,
LockedTitle=av.LockedTitle,
Default=av.Default or Color3.new(1,1,1),
Callback=av.Callback or function()end,

UIScale=av.UIScale,
Transparency=av.Transparency,
UIElements={},

IsShowed=false,
}

local ax=true



aw.ColorpickerFrame=a.load'C'{
Title=aw.Title,
Desc=aw.Desc,
Parent=av.Parent,
TextOffset=40,
Hover=false,
Tab=av.Tab,
Index=av.Index,
Window=av.Window,
ElementTable=aw,
ParentConfig=av,
Tags=av.Tags,
}

aw.UIElements.Colorpicker=aa.NewRoundFrame(as.UICorner,"Squircle",{
ImageTransparency=0,
Active=true,
ImageColor3=aw.Default,
Parent=aw.ColorpickerFrame.UIElements.Main,
Size=UDim2.new(0,26,0,26),
AnchorPoint=Vector2.new(1,0),
Position=UDim2.new(1,0,0,0),
ZIndex=2,
},{
aa.NewRoundFrame(as.UICorner,"SquircleGlass",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="Outline",
},
ImageTransparency=0.55,
}),
},true)

function aw.Lock(ay)
aw.Locked=true
ax=false
return aw.ColorpickerFrame:Lock(aw.LockedTitle)
end
function aw.Unlock(ay)
aw.Locked=false
ax=true
return aw.ColorpickerFrame:Unlock()
end

if aw.Locked then
aw:Lock()
end

function aw.Update(ay,az,aA)
aw.UIElements.Colorpicker.ImageTransparency=aA or 0
aw.UIElements.Colorpicker.ImageColor3=az
aw.Default=az
if aA then
aw.Transparency=aA
end
end

function aw.Set(ay,az,aA)
return aw:Update(az,aA)
end

aa.AddSignal(aw.UIElements.Colorpicker.MouseButton1Click,function()
if ax and not aw.IsShowed then
aw.IsShowed=true

as:Colorpicker(aw,av.Window,av.WindUI,function(ay,az)
aw:Update(ay,az)
aw.Default=ay
aw.Transparency=az
aa.SafeCallback(aw.Callback,ay,az)
end).ColorpickerFrame
:Open()
end
end)

return aw.__type,aw
end

return as end function a.T()

local aa=a.load'd'
local af=aa.New
local ai=aa.Tween

local ak={}

function ak.New(al,am)
local an={
__type="Section",
Title=am.Title or"Section",
Desc=am.Desc,
Icon=am.Icon,
IconThemed=am.IconThemed,
TextXAlignment=am.TextXAlignment or"Left",
TextSize=am.TextSize or 19,
DescTextSize=am.DescTextSize or 16,
Box=am.Box or false,
BoxBorder=am.BoxBorder or false,
FontWeight=am.FontWeight or Enum.FontWeight.SemiBold,
DescFontWeight=am.DescFontWeight or Enum.FontWeight.Medium,
TextTransparency=am.TextTransparency or 0.05,
DescTextTransparency=am.DescTextTransparency or 0.4,
Opened=am.Opened or false,
UIElements={},

HeaderSize=48,
IconSize=20,
Padding=10,

Elements={},

Expandable=false,
}

local ao

function an.SetIcon(ap,aq)
an.Icon=aq or nil
if ao then
ao:Destroy()
end
if aq then
ao=aa.Image(
aq,
aq..":"..an.Title,
0,
am.Window.Folder,
an.__type,
true,
an.IconThemed,
"SectionIcon"
)
ao.Size=UDim2.new(0,an.IconSize,0,an.IconSize)
end
end

local ap=af("Frame",{
Size=UDim2.new(0,an.IconSize,0,an.IconSize),
BackgroundTransparency=1,
Visible=false,
},{
af("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Image=aa.Icon"chevron-down"[1],
ImageRectSize=aa.Icon"chevron-down"[2].ImageRectSize,
ImageRectOffset=aa.Icon"chevron-down"[2].ImageRectPosition,
ThemeTag={
ImageTransparency="SectionExpandIconTransparency",
ImageColor3="SectionExpandIcon",
},
}),
})

if an.Icon then
an:SetIcon(an.Icon)
end

local aq=af("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
af("UIListLayout",{
FillDirection="Vertical",
HorizontalAlignment=an.TextXAlignment,
VerticalAlignment="Center",
Padding=UDim.new(0,4),
}),
})

local ar,as

local function createTitle(at,au)
return af("TextLabel",{
BackgroundTransparency=1,
TextXAlignment=an.TextXAlignment,
AutomaticSize="Y",
TextSize=au=="Title"and an.TextSize or an.DescTextSize,
TextTransparency=au=="Title"and an.TextTransparency or an.DescTextTransparency,
ThemeTag={
TextColor3="Text",
},
FontFace=Font.new(aa.Font,au=="Title"and an.FontWeight or an.DescFontWeight),


Text=at,
Size=UDim2.new(1,0,0,0),
TextWrapped=true,
Parent=aq,
})
end

ar=createTitle(an.Title,"Title")
if an.Desc then
as=createTitle(an.Desc,"Desc")
end

local function UpdateTitleSize()
local at=0
if ao then
at=at-(an.IconSize+8)
end
if ap.Visible then
at=at-(an.IconSize+8)
end
aq.Size=UDim2.new(1,at,0,0)
end

local at=aa.NewRoundFrame(am.Window.ElementConfig.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
Parent=am.Parent,

AutomaticSize="Y",
ThemeTag={
ImageTransparency=an.Box and"SectionBoxBackgroundTransparency"or nil,
ImageColor3="SectionBoxBackground",
},
ImageTransparency=not an.Box and 1 or nil,
},{
aa.NewRoundFrame(am.Window.ElementConfig.UICorner-1,"SquircleOutline",{
Size=UDim2.new(1,0,1,0),



ThemeTag={

ImageColor3="SectionBoxBorder",
},
ImageTransparency=an.Box and an.BoxBorder and 0.92 or 1,
Name="Outline",
ClipsDescendants=true,
},{
af("TextButton",{
Size=UDim2.new(1,0,0,an.Expandable and 0 or(not as and an.HeaderSize or 0)),
BackgroundTransparency=1,
AutomaticSize=(not an.Expandable or as)and"Y"or nil,
Text="",
Name="Top",
},{
an.Box and af("UIPadding",{
PaddingTop=UDim.new(
0,
am.Window.ElementConfig.UIPadding+(am.Window.NewElements and 4 or 0)
),
PaddingLeft=UDim.new(
0,
am.Window.ElementConfig.UIPadding+(am.Window.NewElements and 4 or 0)
),
PaddingRight=UDim.new(
0,
am.Window.ElementConfig.UIPadding+(am.Window.NewElements and 4 or 0)
),
PaddingBottom=UDim.new(
0,
am.Window.ElementConfig.UIPadding+(am.Window.NewElements and 4 or 0)
),
})or nil,
ao,
aq,
af("UIListLayout",{
Padding=UDim.new(0,8),
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Left",
}),
ap,
}),
af("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
Name="Content",
Visible=false,
Position=UDim2.new(0,0,0,an.HeaderSize+10),
},{
an.Box and af("UIPadding",{
PaddingLeft=UDim.new(0,am.Window.ElementConfig.UIPadding/1.5),
PaddingRight=UDim.new(0,am.Window.ElementConfig.UIPadding/1.5),
PaddingBottom=UDim.new(0,am.Window.ElementConfig.UIPadding/1.5),
})or nil,
af("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,am.Tab.Gap),
VerticalAlignment="Top",
}),
}),
}),
})





an.ElementFrame=at

at.Outline.Top:GetPropertyChangedSignal"AbsoluteSize":Connect(function()
at.Outline.Content.Position=UDim2.new(0,0,0,(at.Outline.Top.AbsoluteSize.Y/am.UIScale)+10)

if an.Opened then
an:Open(true)
else
an.Close(true)
end
end)

local au=am.ElementsModule

au.Load(an,at.Outline.Content,au.Elements,am.Window,am.WindUI,function()
if not an.Expandable then
an.Expandable=true
ap.Visible=true
UpdateTitleSize()
end
end,au,am.UIScale,am.Tab)

UpdateTitleSize()

function an.SetTitle(av,aw)
an.Title=aw
ar.Text=aw
end

function an.SetDesc(av,aw)
an.Desc=aw
if not as then
as=createTitle(aw,"Desc")
end
as.Text=aw
end

function an.Destroy(av)
for aw,ax in next,an.Elements do
ax:Destroy()
end








at:Destroy()
end

function an.Open(av,aw)
if an.Expandable then
an.Opened=true
if aw then
at.Size=UDim2.new(
at.Size.X.Scale,
at.Size.X.Offset,
0,
at.Outline.Top.AbsoluteSize.Y/am.UIScale
+(at.Outline.Content.AbsoluteSize.Y/am.UIScale)
+10
)
ap.ImageLabel.Rotation=180
else
ai(at,0.33,{
Size=UDim2.new(
at.Size.X.Scale,
at.Size.X.Offset,
0,
at.Outline.Top.AbsoluteSize.Y/am.UIScale
+(at.Outline.Content.AbsoluteSize.Y/am.UIScale)
+10
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

ai(
ap.ImageLabel,
0.2,
{Rotation=180},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
end
end
function an.Close(av,aw)
if an.Expandable then
an.Opened=false
if aw then
at.Size=UDim2.new(
at.Size.X.Scale,
at.Size.X.Offset,
0,
(at.Outline.Top.AbsoluteSize.Y/am.UIScale)
)
ap.ImageLabel.Rotation=0
else
ai(at,0.26,{
Size=UDim2.new(
at.Size.X.Scale,
at.Size.X.Offset,
0,
(at.Outline.Top.AbsoluteSize.Y/am.UIScale)
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ai(
ap.ImageLabel,
0.2,
{Rotation=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
end
end

aa.AddSignal(at.Outline.Top.MouseButton1Click,function()
if an.Expandable then
if an.Opened then
an:Close()
else
an:Open()
end
end
end)

aa.AddSignal(at.Outline.Content.UIListLayout:GetPropertyChangedSignal"AbsoluteContentSize",function()
if an.Opened then
an:Open(true)
else
an:Close(true)
end
end)

task.defer(function()
if an.Expandable then








at.Size=
UDim2.new(at.Size.X.Scale,at.Size.X.Offset,0,at.Outline.Top.AbsoluteSize.Y/am.UIScale)
at.AutomaticSize="None"
at.Outline.Top.Size=UDim2.new(1,0,0,(not as and an.HeaderSize or 0))
at.Outline.Top.AutomaticSize=(not an.Expandable or as)and"Y"or"None"
at.Outline.Content.Visible=true
end
if an.Opened then
an:Open()
else
an:Close(true)
end
end)

return an.__type,an
end

return ak end function a.U()

local aa=a.load'd'
local af=aa.New

local ai={}

function ai.New(ak,al)
local am=af("Frame",{
Parent=al.Parent,
Size=not table.find({"Group","HStack"},al.ParentType)and UDim2.new(1,-7,0,7*(al.Columns or 1))or UDim2.new(0,7*(al.Columns or 1),0,0),
BackgroundTransparency=1,
})

return"Space",{__type="Space",ElementFrame=am}
end

return ai end function a.V()
local aa=a.load'd'
local af=aa.New

local ai={}

local function ParseAspectRatio(ak)
if type(ak)=="string"then
local al,am=ak:match"(%d+):(%d+)"
if al and am then
return tonumber(al)/tonumber(am)
end
elseif type(ak)=="number"then
return ak
end
return nil
end

function ai.New(ak,al)
local am={
__type="Image",
Image=al.Image or"",
AspectRatio=al.AspectRatio or"16:9",
Radius=al.Radius or al.Window.ElementConfig.UICorner,
}
local an=aa.Image(
am.Image,
am.Image,
am.Radius,
al.Window.Folder,
"Image",
false
)
if an and an.Parent then
an.Parent=al.Parent
an.Size=UDim2.new(1,0,0,0)
an.BackgroundTransparency=1












local ao=ParseAspectRatio(am.AspectRatio)
local ap

if ao then
ap=af("UIAspectRatioConstraint",{
Parent=an,
AspectRatio=ao,
AspectType="ScaleWithParentSize",
DominantAxis="Width"
})
end

function am.Destroy(aq)
an:Destroy()
end
end

return am.__type,am
end

return ai end function a.W()
local aa=a.load'd'
local af=aa.New

local ai={}

function ai.New(ak,al)
local am={
__type="Group",
Elements={},
ElementFrame=nil,
}

local an=af("Frame",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
AutomaticSize="Y",
Parent=al.Parent,
},{
af("UIListLayout",{
FillDirection="Horizontal",
HorizontalAlignment="Center",

Padding=UDim.new(0,al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6))
}),
})

am.ElementFrame=an

local ao=al.ElementsModule
ao.Load(
am,
an,
ao.Elements,
al.Window,
al.WindUI,
function(ap,aq)
local ar=al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6)

local as={}
local at=0

for au,av in next,aq do
if av.__type=="Space"then
at=at+(av.ElementFrame.Size.X.Offset or 6)
elseif av.__type=="Divider"then
at=at+(av.ElementFrame.Size.X.Offset or 1)
else
table.insert(as,av)
end
end

local au=#as
if au==0 then return end

local av=1/au

local aw=ar*(au-1)

local ax=-(aw+at)

local ay=math.floor(ax/au)
local az=ax-(ay*au)

for aA,aB in next,as do
local b=ay
if aA<=math.abs(az)then
b=b-1
end

if aB.ElementFrame then
aB.ElementFrame.Size=UDim2.new(av,b,1,0)
end
end
end,
ao,
al.UIScale,
al.Tab
)



return am.__type,am
end

return ai end function a.X()
local aa=a.load'd'
local af=aa.New

local ai={}

function ai.New(ak,al)
local am={
__type="HStack",
AutoSpace=al.AutoSpace or false,
Elements={},
ElementFrame=nil,
}

local an=af("Frame",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
AutomaticSize="Y",
Parent=al.Parent,
},{
af("UIListLayout",{
FillDirection="Horizontal",
HorizontalAlignment="Center",

Padding=UDim.new(0,al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6)),
}),
})

am.ElementFrame=an

local ao=al.ElementsModule
ao.Load(
am,
an,
ao.Elements,
al.Window,
al.WindUI,
function(ap,aq)
local ar=al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6)

local as={}
local at=0

for au,av in next,aq do
if av.__type=="Space"then
at=at+(av.ElementFrame.Size.X.Offset or 6)
elseif av.__type=="Divider"then
at=at+(av.ElementFrame.Size.X.Offset or 1)
else
table.insert(as,av)
end
end

local au=#as
if au==0 then
return
end

local av=1/au

local aw=ar*(au-1)

local ax=-(aw+at)

local ay=math.floor(ax/au)
local az=ax-(ay*au)

for aA,aB in next,as do
local b=ay
if aA<=math.abs(az)then
b=b-1
end

if aB.ElementFrame then
aB.ElementFrame.Size=UDim2.new(av,b,1,0)
end
end
end,
ao,
al.UIScale,
al.Tab
)

if am.AutoSpace then
for ap in next,ao.Elements do
if ap~="Space"and ap~="Divider"then
local aq=am[ap]
am[ap]=function(ar,as)
if#am.Elements>0 then
am:Space()
end
return aq(ar,as)
end
end
end
end

return am.__type,am
end

return ai end function a.Y()

local aa=a.load'd'
local af=aa.New

local ai={}

function ai.New(ak,al)
local am={
__type="VStack",
Elements={},
ElementFrame=nil,
}

local an=af("Frame",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
AutomaticSize="Y",
Parent=al.Parent,
},{
af("UIListLayout",{
FillDirection="Vertical",
HorizontalAlignment="Center",

Padding=UDim.new(0,al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6))
}),
})

am.ElementFrame=an

local ao=al.ElementsModule
ao.Load(
am,
an,
ao.Elements,
al.Window,
al.WindUI,







































nil,
ao,
al.UIScale,
al.Tab
)



return am.__type,am
end

return ai end function a.Z()
local aa=(cloneref or clonereference or function(aa)
return aa
end)

local af=aa(game:GetService"UserInputService")

local ai=a.load'd'
local ak=ai.New

local al={}














function al.New(am,an:ConfigType__DARKLUA_TYPE_a)
local ao={
__type="Viewport",
Object=an.Object,
Camera=an.Camera or Instance.new"Camera",
Interactive=an.Interactive or false,
Height=an.Height or 200,
Focused=an.Focused~=false,
}

local ap=false
local aq=false
local ar,as=0

local at=ai.NewRoundFrame(an.Window.ElementConfig.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,ao.Height),
Parent=an.Parent,
ThemeTag={
ImageColor3="ViewportBackground",
ImageTransparency="ViewportBackgroundTransparency",
},
},{
ak("CanvasGroup",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ak("UICorner",{
CornerRadius=UDim.new(0,an.Window.ElementConfig.UICorner),
}),
ak("ViewportFrame",{
Name="Viewport",
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
CurrentCamera=ao.Camera,
Active=ao.Interactive,
},{
ao.Object,
}),
}),
})

local function IsTouchInsideViewport(au)
local av=at.CanvasGroup.Viewport.AbsolutePosition
local aw=at.CanvasGroup.Viewport.AbsoluteSize

return au.X>=av.X
and au.X<=av.X+aw.X
and au.Y>=av.Y
and au.Y<=av.Y+aw.Y
end

local au=an.WindUI.GenerateGUID()

ai.AddSignal(at.CanvasGroup.Viewport.MouseEnter,function()
if ao.Interactive then
an.Tab.UIElements.ContainerFrame.ScrollingEnabled=false
end
end)

ai.AddSignal(at.CanvasGroup.Viewport.InputEnded,function(av)
if
av.UserInputType==Enum.UserInputType.MouseMovement
or av.UserInputType==Enum.UserInputType.Touch
then
an.Tab.UIElements.ContainerFrame.ScrollingEnabled=true
end
end)

ai.AddSignal(at.CanvasGroup.Viewport.InputBegan,function(av)
if ao.Interactive then
if
(av.UserInputType==Enum.UserInputType.MouseButton1)
or(av.UserInputType==Enum.UserInputType.Touch and not aq)
then
if an.WindUI.CurrentInput and an.WindUI.CurrentInput~=au then
return
end

an.WindUI.CurrentInput=au

ap=true
as=av.Position
end
end
end)

ai.AddSignal(af.InputEnded,function(av)
if ao.Interactive then
if
av.UserInputType==Enum.UserInputType.MouseButton1
or av.UserInputType==Enum.UserInputType.Touch
then
if an.WindUI.CurrentInput and an.WindUI.CurrentInput~=au then
return
end

an.WindUI.CurrentInput=nil

ap=false
end
end
end)

ai.AddSignal(af.InputChanged,function(av)
if ao.Interactive and ap and not aq then
if
av.UserInputType==Enum.UserInputType.MouseMovement
or av.UserInputType==Enum.UserInputType.Touch
then
local aw=av.Position-as
as=av.Position

local ax=ao.Object:GetPivot().Position
local ay=ao.Camera

local az=CFrame.fromAxisAngle(Vector3.new(0,1,0),-aw.X*0.02)
ay.CFrame=CFrame.new(ax)*az*CFrame.new(-ax)*ay.CFrame

local aA=CFrame.fromAxisAngle(ay.CFrame.RightVector,-aw.Y*0.02)
local aB=CFrame.new(ax)*aA*CFrame.new(-ax)*ay.CFrame

if aB.UpVector.Y>0.1 then
ay.CFrame=aB
end
end
end
end)

ai.AddSignal(at.CanvasGroup.Viewport.InputChanged,function(av)
if ao.Interactive then
if av.UserInputType==Enum.UserInputType.MouseWheel then
local aw=av.Position.Z*2
ao.Camera.CFrame+=ao.Camera.CFrame.LookVector*aw
end
end
end)

ai.AddSignal(af.TouchPinch,function(av,aw,ax,ay)
if not IsTouchInsideViewport(av[1])or not IsTouchInsideViewport(av[2])then
return
end
if ao.Interactive then
if ay==Enum.UserInputState.Begin then
aq=true
ap=false
ar=(av[1]-av[2]).Magnitude
elseif ay==Enum.UserInputState.Change then
if aq then
local az=(av[1]-av[2]).Magnitude
local aA=(az-ar)*0.03
ar=az
ao.Camera.CFrame+=ao.Camera.CFrame.LookVector*aA
end
elseif ay==Enum.UserInputState.End or ay==Enum.UserInputState.Cancel then
aq=false
end
end
end)

local function FocusCamera()
local av=ao.Object:IsA"BasePart"and ao.Object.Size
or select(2,ao.Object:GetBoundingBox(0))
local aw=math.max(av.X,av.Y,av.Z)
local ax=aw*2
local ay=ao.Object:GetPivot().Position

ao.Camera.CFrame=
CFrame.new(ay+Vector3.new(0,aw/2,ax),ay)
end

if ao.Focused then
FocusCamera()
end

function ao.SetObject(av,aw,ax)
if ax then
aw=aw:Clone()
end
if ao.Object then
ao.Object:Destroy()
end

ao.Object=aw
ao.Object.Parent=at.CanvasGroup.Viewport
end

function ao.SetHeight(av,aw)
at.Size=UDim2.new(1,0,0,aw)
end

function ao.Focus(av)
if ao.Object then
FocusCamera()
end
end

function ao.SetCamera(av,aw)
ao.Camera=aw
at.CanvasGroup.Viewport.CurrentCamera=aw
end

function ao.SetInteractive(av,aw)
ao.Interactive=aw
at.CanvasGroup.Viewport.Active=aw
end

ao.Main=at

return ao.__type,ao
end

return al end function a._()

return{
Elements={
Paragraph=a.load'D',
Button=a.load'E',
Toggle=a.load'H',
Slider=a.load'I',
ProgressBar=a.load'J',
Keybind=a.load'K',
Input=a.load'L',
Dropdown=a.load'O',
Code=a.load'R',
Colorpicker=a.load'S',
Section=a.load'T',
Divider=a.load'M',
Space=a.load'U',
Image=a.load'V',
Group=a.load'W',
HStack=a.load'X',
VStack=a.load'Y',
Viewport=a.load'Z',

},
Load=function(aa,af,ai,ak,al,am,an,ao,ap)
for aq,ar in next,ai do
aa[aq]=function(as,at)
at=at or{}
at.Tab=ap or aa
at.ParentType=aa.__type
at.ParentTable=aa
at.Index=#aa.Elements+1
at.GlobalIndex=#ak.AllElements+1
at.Parent=af
at.Window=ak
at.WindUI=al
at.UIScale=ao
at.ElementsModule=an local

au, av=ar:New(at)

if at.Flag and typeof(at.Flag)=="string"then
if ak.CurrentConfig then
ak.CurrentConfig:Register(at.Flag,av)

if ak.PendingConfigData and ak.PendingConfigData[at.Flag]then
local aw=ak.PendingConfigData[at.Flag]

local ax=ak.ConfigManager
if ax.Parser[aw.__type]then
task.defer(function()
local ay,az=pcall(function()
ax.Parser[aw.__type].Load(av,aw)
end)

if ay then
ak.PendingConfigData[at.Flag]=nil
else
warn(
"[ WindUI ] Failed to apply pending config for '"
..at.Flag
.."': "
..tostring(az)
)
end
end)
end
end
else
ak.PendingFlags=ak.PendingFlags or{}
ak.PendingFlags[at.Flag]=av
end
end

local aw
for ax,ay in next,av do
if typeof(ay)=="table"and ax~="ElementFrame"and ax:match"Frame$"then
aw=ay
break
end
end

if aw then
av.ElementFrame=aw.UIElements.Main
function av.SetTitle(ax,ay)
return aw.SetTitle and aw:SetTitle(ay)
end
function av.SetDesc(ax,ay)
return aw.SetDesc and aw:SetDesc(ay)
end
function av.SetImage(ax,ay,az)
return aw.SetImage and aw:SetImage(ay,az)
end
function av.SetThumbnail(ax,ay,az)
return aw.SetThumbnail and aw:SetThumbnail(ay,az)
end
function av.Highlight(ax)
aw:Highlight()
end
function av.Destroy(ax)
aw:Destroy()

table.remove(ak.AllElements,at.GlobalIndex)
table.remove(aa.Elements,at.Index)
table.remove(ap.Elements,at.Index)
aa:UpdateAllElementShapes(aa)
end
end

ak.AllElements[at.Index]=av
aa.Elements[at.Index]=av
if ap then
ap.Elements[at.Index]=av
end

if ak.NewElements then
aa:UpdateAllElementShapes(aa)
end

if am then
am(av,aa.Elements)
end
return av
end
end
function aa.UpdateAllElementShapes(aq,ar)
for as,at in next,ar.Elements do
local au
for av,aw in pairs(at)do
if typeof(aw)=="table"and av:match"Frame$"then
au=aw
break
end
end

if not au and at.UpdateShape then
au=at
end

if au then

au.Index=as
if au.UpdateShape then

au.UpdateShape(ar)
end
end
end
end
end,
}end function a.aa()

local aa=(cloneref or clonereference or function(aa)
return aa
end)

local af=game:GetService"Players"

aa(game:GetService"UserInputService")
local ai=af.LocalPlayer:GetMouse()

local ak=a.load'd'
local al=ak.New

local am=a.load'B'.New
local an=a.load'x'.New



local ao={


Tabs={},
Containers={},
SelectedTab=nil,
TabCount=0,
ToolTipParent=nil,
TabHighlight=nil,

OnChangeFunc=function(ao)end,
}

function ao.Init(ap,aq,ar,as)
Window=ap
WindUI=aq
ao.ToolTipParent=ar
ao.TabHighlight=as
return ao
end

function ao.New(ap,aq)
local ar={
__type="Tab",
Title=ap.Title or"Tab",
Desc=ap.Desc,
Icon=ap.Icon,
IconColor=ap.IconColor,
IconShape=ap.IconShape,
IconThemed=ap.IconThemed,
Locked=ap.Locked,
ShowTabTitle=ap.ShowTabTitle,
TabTitleAlign=ap.TabTitleAlign or"Left",
CustomEmptyPage=(ap.CustomEmptyPage and next(ap.CustomEmptyPage)~=nil)and ap.CustomEmptyPage
or{Icon="lucide:frown",IconSize=48,Title="This tab is Empty",Desc=nil},
Border=ap.Border,
Selected=false,
Index=nil,
Parent=ap.Parent,
UIElements={},
Elements={},
ContainerFrame=nil,
UICorner=Window.UICorner-(Window.UIPadding/2),

Gap=Window.NewElements and 1 or 6,

TabPaddingX=4+(Window.UIPadding/2),
TabPaddingY=3+(Window.UIPadding/2),
TitlePaddingY=0,
}









if ar.IconShape then
ar.TabPaddingX=2+(Window.UIPadding/4)
ar.TabPaddingY=2+(Window.UIPadding/4)
ar.TitlePaddingY=2+(Window.UIPadding/4)
end

ao.TabCount=ao.TabCount+1

local as=ao.TabCount
ar.Index=as

ar.UIElements.Main=ak.NewRoundFrame(ar.UICorner,"Squircle",{
BackgroundTransparency=1,
Size=UDim2.new(1,-7,0,0),
AutomaticSize="Y",
Parent=ap.Parent,
ThemeTag={
ImageColor3="TabBackground",
},
ImageTransparency=1,
},{
ak.NewRoundFrame(ar.UICorner-1,"Glass-1.4",{
Size=UDim2.new(1,1,1,1),
ThemeTag={
ImageColor3="TabBorder",
},
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ImageTransparency=1,
Name="Outline",
},{













}),
ak.NewRoundFrame(ar.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=1,
Name="Frame",
},{
al("UIListLayout",{
SortOrder="LayoutOrder",
Padding=UDim.new(0,2+(Window.UIPadding/2)),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
al("TextLabel",{
Text=ar.Title,
ThemeTag={
TextColor3="TabTitle",
},
TextTransparency=not ar.Locked and 0.4 or 0.7,
TextSize=15,
Size=UDim2.new(1,0,0,0),
FontFace=Font.new(ak.Font,Enum.FontWeight.Medium),
TextWrapped=true,
RichText=true,
AutomaticSize="Y",
LayoutOrder=2,
TextXAlignment="Left",
BackgroundTransparency=1,
},{
al("UIPadding",{
PaddingTop=UDim.new(0,ar.TitlePaddingY),


PaddingBottom=UDim.new(0,ar.TitlePaddingY),
}),
}),
al("UIPadding",{
PaddingTop=UDim.new(0,ar.TabPaddingY),
PaddingLeft=UDim.new(0,ar.TabPaddingX),
PaddingRight=UDim.new(0,ar.TabPaddingX),
PaddingBottom=UDim.new(0,ar.TabPaddingY),
}),
}),
},true)

local at=0
local au
local av

if ar.Icon then
au=ak.Image(
ar.Icon,
ar.Icon..":"..ar.Title,
0,
Window.Folder,
ar.__type,
ar.IconColor and false or true,
ar.IconThemed,
"TabIcon"
)
au.Size=UDim2.new(0,16,0,16)
if ar.IconColor then
au.ImageLabel.ImageColor3=ar.IconColor
end
if not ar.IconShape then
au.Parent=ar.UIElements.Main.Frame
ar.UIElements.Icon=au
au.ImageLabel.ImageTransparency=not ar.Locked and 0 or 0.7
at=-18-(Window.UIPadding/2)
ar.UIElements.Main.Frame.TextLabel.Size=UDim2.new(1,at,0,0)
elseif ar.IconColor then
ak.NewRoundFrame(
ar.IconShape~="Circle"and(ar.UICorner+5-(2+(Window.UIPadding/4)))or 9999,
"Squircle",
{
Size=UDim2.new(0,26,0,26),
ImageColor3=ar.IconColor,
Parent=ar.UIElements.Main.Frame,
},
{
au,
ak.NewRoundFrame(
ar.IconShape~="Circle"and(ar.UICorner+5-(2+(Window.UIPadding/4)))or 9999,
"Glass-1.4",
{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="White",
},
ImageTransparency=0,
Name="Outline",
},
{













}
),
}
)
au.AnchorPoint=Vector2.new(0.5,0.5)
au.Position=UDim2.new(0.5,0,0.5,0)
au.ImageLabel.ImageTransparency=0
au.ImageLabel.ImageColor3=ak.GetTextColorForHSB(ar.IconColor,0.68)
at=-28-(Window.UIPadding/2)
ar.UIElements.Main.Frame.TextLabel.Size=UDim2.new(1,at,0,0)
end

av=
ak.Image(ar.Icon,ar.Icon..":"..ar.Title,0,Window.Folder,ar.__type,true,ar.IconThemed)
av.Size=UDim2.new(0,16,0,16)
av.ImageLabel.ImageTransparency=not ar.Locked and 0 or 0.7
at=-30




end

ar.UIElements.ContainerFrame=al("ScrollingFrame",{
Size=UDim2.new(1,0,1,ar.ShowTabTitle and-((Window.UIPadding*2.4)+12)or 0),
BackgroundTransparency=1,
ScrollBarThickness=0,
ElasticBehavior="Never",
CanvasSize=UDim2.new(0,0,0,0),
AnchorPoint=Vector2.new(0,1),
Position=UDim2.new(0,0,1,0),
AutomaticCanvasSize="Y",

ScrollingDirection="Y",
},{
al("UIPadding",{
PaddingTop=UDim.new(0,not Window.HidePanelBackground and 20 or 10),
PaddingLeft=UDim.new(0,not Window.HidePanelBackground and 20 or 10),
PaddingRight=UDim.new(0,not Window.HidePanelBackground and 20 or 10),
PaddingBottom=UDim.new(0,not Window.HidePanelBackground and 20 or 10),
}),
al("UIListLayout",{
SortOrder="LayoutOrder",
Padding=UDim.new(0,ar.Gap),
HorizontalAlignment="Center",
}),
})





ar.UIElements.ContainerFrameCanvas=al("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Visible=false,
Parent=Window.UIElements.MainBar,
ZIndex=5,
},{
ar.UIElements.ContainerFrame,
al("Frame",{
Size=UDim2.new(1,-14,1,-14),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
BackgroundTransparency=1,
Name="ScrollSliderHolder",
}),
al("Frame",{
Size=UDim2.new(1,0,0,((Window.UIPadding*2.4)+12)),
BackgroundTransparency=1,
Visible=ar.ShowTabTitle or false,
Name="TabTitle",
},{
av,
al("TextLabel",{
Text=ar.Title,
ThemeTag={
TextColor3="Text",
},
TextSize=20,
TextTransparency=0.1,
Size=UDim2.new(0,0,1,0),
FontFace=Font.new(ak.Font,Enum.FontWeight.SemiBold),

RichText=true,
LayoutOrder=2,
TextXAlignment="Left",
BackgroundTransparency=1,
AutomaticSize="X",
}),
al("UIPadding",{
PaddingTop=UDim.new(0,20),
PaddingLeft=UDim.new(0,20),
PaddingRight=UDim.new(0,20),
PaddingBottom=UDim.new(0,20),
}),
al("UIListLayout",{
SortOrder="LayoutOrder",
Padding=UDim.new(0,10),
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment=ar.TabTitleAlign,
}),
}),
al("Frame",{
Size=UDim2.new(1,0,0,1),
BackgroundTransparency=0.9,
ThemeTag={
BackgroundColor3="Text",
},
Position=UDim2.new(0,0,0,((Window.UIPadding*2.4)+12)),
Visible=ar.ShowTabTitle or false,
}),
})

ao.Containers[as]=ar.UIElements.ContainerFrameCanvas
ao.Tabs[as]=ar

ar.ContainerFrame=ar.UIElements.ContainerFrameCanvas

ak.AddSignal(ar.UIElements.Main.MouseButton1Click,function()
if not ar.Locked then
ao:SelectTab(as)
end
end)

if Window.ScrollBarEnabled then
an(
ar.UIElements.ContainerFrame,
ar.UIElements.ContainerFrameCanvas.ScrollSliderHolder,
Window,
4,
WindUI
)
end

local aw
local ax
local ay
local az=false


if ar.Desc then
ak.AddSignal(ar.UIElements.Main.InputBegan,function()
az=true
ax=task.spawn(function()
task.wait(0.35)
if az and not aw then
aw=am(ar.Desc,ao.ToolTipParent,true)
aw.Container.AnchorPoint=Vector2.new(0.5,0.5)

local function updatePosition()
if aw then
aw.Container.Position=UDim2.new(0,ai.X,0,ai.Y-4)
end
end

updatePosition()
ay=ai.Move:Connect(updatePosition)
aw:Open()
end
end)
end)
end

ak.AddSignal(ar.UIElements.Main.MouseEnter,function()
if not ar.Locked then
ak.SetThemeTag(ar.UIElements.Main.Frame,{
ImageTransparency="TabBackgroundHoverTransparency",
ImageColor3="TabBackgroundHover",
},0.1)
end
end)
ak.AddSignal(ar.UIElements.Main.InputEnded,function()
if ar.Desc then
az=false
if ax then
task.cancel(ax)
ax=nil
end
if ay then
ay:Disconnect()
ay=nil
end
if aw then
aw:Close()
aw=nil
end
end

if not ar.Locked then
ak.SetThemeTag(ar.UIElements.Main.Frame,{
ImageTransparency="TabBorderTransparency",
},0.1)
end
end)

function ar.ScrollToTheElement(aA,aB)
ar.UIElements.ContainerFrame.ScrollingEnabled=false

ak.Tween(ar.UIElements.ContainerFrame,0.45,{
CanvasPosition=Vector2.new(
0,
ar.Elements[aB].ElementFrame.AbsolutePosition.Y
-ar.UIElements.ContainerFrame.AbsolutePosition.Y
-ar.UIElements.ContainerFrame.UIPadding.PaddingTop.Offset
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

task.spawn(function()
task.wait(0.48)

if ar.Elements[aB].Highlight then
ar.Elements[aB]:Highlight()
end
ar.UIElements.ContainerFrame.ScrollingEnabled=true
end)

return ar
end



local aA=a.load'_'

aA.Load(
ar,
ar.UIElements.ContainerFrame,
aA.Elements,
Window,
WindUI,
nil,
aA,
aq,
ar
)

function ar.LockAll(aB)

for b,d in next,Window.AllElements do
if d.Tab and d.Tab.Index and d.Tab.Index==ar.Index and d.Lock then
d:Lock()
end
end
end
function ar.UnlockAll(aB)
for b,d in next,Window.AllElements do
if d.Tab and d.Tab.Index and d.Tab.Index==ar.Index and d.Unlock then
d:Unlock()
end
end
end
function ar.GetLocked(aB)
local b={}

for d,f in next,Window.AllElements do
if f.Tab and f.Tab.Index and f.Tab.Index==ar.Index and f.Locked==true then
table.insert(b,f)
end
end

return b
end
function ar.GetUnlocked(aB)
local b={}

for d,f in next,Window.AllElements do
if f.Tab and f.Tab.Index and f.Tab.Index==ar.Index and f.Locked==false then
table.insert(b,f)
end
end

return b
end

function ar.Select(aB)
return ao:SelectTab(ar.Index)
end

task.spawn(function()
local aB
if ar.CustomEmptyPage.Icon then
aB=
ak.Image(ar.CustomEmptyPage.Icon,ar.CustomEmptyPage.Icon,0,"Temp","EmptyPage",true)
aB.Size=
UDim2.fromOffset(ar.CustomEmptyPage.IconSize or 48,ar.CustomEmptyPage.IconSize or 48)
end

local b=al("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,-Window.UIElements.Main.Main.Topbar.AbsoluteSize.Y),
Parent=ar.UIElements.ContainerFrame,
},{
al("UIListLayout",{
Padding=UDim.new(0,8),
SortOrder="LayoutOrder",
VerticalAlignment="Center",
HorizontalAlignment="Center",
FillDirection="Vertical",
}),











aB,
ar.CustomEmptyPage.Title and al("TextLabel",{
AutomaticSize="XY",
Text=ar.CustomEmptyPage.Title,
ThemeTag={
TextColor3="Text",
},
TextSize=18,
TextTransparency=0.5,
BackgroundTransparency=1,
FontFace=Font.new(ak.Font,Enum.FontWeight.Medium),
})or nil,
ar.CustomEmptyPage.Desc and al("TextLabel",{
AutomaticSize="XY",
Text=ar.CustomEmptyPage.Desc,
ThemeTag={
TextColor3="Text",
},
TextSize=15,
TextTransparency=0.65,
BackgroundTransparency=1,
FontFace=Font.new(ak.Font,Enum.FontWeight.Regular),
})or nil,
})





local d
d=ak.AddSignal(ar.UIElements.ContainerFrame.ChildAdded,function()
b.Visible=false
d:Disconnect()
end)
end)

return ar
end

function ao.OnChange(ap,aq)
ao.OnChangeFunc=aq
end

function ao.SelectTab(ap,aq)
if not ao.Tabs[aq].Locked then
ao.SelectedTab=aq

for ar,as in next,ao.Tabs do
if not as.Locked then
ak.SetThemeTag(as.UIElements.Main,{
ImageTransparency="TabBorderTransparency",
},0.15)
if as.Border then
ak.SetThemeTag(as.UIElements.Main.Outline,{
ImageTransparency="TabBorderTransparency",
},0.15)
end
ak.SetThemeTag(as.UIElements.Main.Frame.TextLabel,{
TextTransparency="TabTextTransparency",
},0.15)
if as.UIElements.Icon and not as.IconColor then
ak.SetThemeTag(as.UIElements.Icon.ImageLabel,{
ImageTransparency="TabIconTransparency",
},0.15)
end
as.Selected=false
end
end
ak.SetThemeTag(ao.Tabs[aq].UIElements.Main,{
ImageColor3="TabBackgroundActive",
ImageTransparency="TabBackgroundActiveTransparency",
},0.15)
if ao.Tabs[aq].Border then
ak.SetThemeTag(ao.Tabs[aq].UIElements.Main.Outline,{
ImageTransparency="TabBorderTransparencyActive",
},0.15)
end
ak.SetThemeTag(ao.Tabs[aq].UIElements.Main.Frame.TextLabel,{
TextTransparency="TabTextTransparencyActive",
},0.15)
if ao.Tabs[aq].UIElements.Icon and not ao.Tabs[aq].IconColor then
ak.SetThemeTag(ao.Tabs[aq].UIElements.Icon.ImageLabel,{
ImageTransparency="TabIconTransparencyActive",
},0.15)
end
ao.Tabs[aq].Selected=true

task.spawn(function()
for ar,as in next,ao.Containers do
as.AnchorPoint=Vector2.new(0,0.05)
as.Visible=false
end
ao.Containers[aq].Visible=true
local ar=game:GetService"TweenService"

local as=TweenInfo.new(0.15,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
local at=ar:Create(ao.Containers[aq],as,{
AnchorPoint=Vector2.new(0,0),
})
at:Play()
end)

ao.OnChangeFunc(aq)
end
end

return ao end function a.ab()

local aa={}


local af=a.load'd'
local ai=af.New
local ak=af.Tween

local al=a.load'aa'

function aa.New(am,an,ao,ap,aq)
local ar={
Title=am.Title or"Section",
Icon=am.Icon,
IconThemed=am.IconThemed,
Opened=am.Opened or false,

HeaderSize=42,
IconSize=18,

Expandable=false,
}

local as
if ar.Icon then
as=af.Image(
ar.Icon,
ar.Icon,
0,
ao,
"Section",
true,
ar.IconThemed,
"TabSectionIcon"
)

as.Size=UDim2.new(0,ar.IconSize,0,ar.IconSize)
as.ImageLabel.ImageTransparency=.25
end

local at=ai("Frame",{
Size=UDim2.new(0,ar.IconSize,0,ar.IconSize),
BackgroundTransparency=1,
Visible=false
},{
ai("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Image=af.Icon"chevron-down"[1],
ImageRectSize=af.Icon"chevron-down"[2].ImageRectSize,
ImageRectOffset=af.Icon"chevron-down"[2].ImageRectPosition,
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=.7,
})
})

local au=ai("Frame",{
Size=UDim2.new(1,0,0,ar.HeaderSize),
BackgroundTransparency=1,
Parent=an,
ClipsDescendants=true,
},{
ai("TextButton",{
Size=UDim2.new(1,0,0,ar.HeaderSize),
BackgroundTransparency=1,
Text="",
},{
as,
ai("TextLabel",{
Text=ar.Title,
TextXAlignment="Left",
Size=UDim2.new(
1,
as and(-ar.IconSize-10)*2
or(-ar.IconSize-10),

1,
0
),
ThemeTag={
TextColor3="Text",
},
FontFace=Font.new(af.Font,Enum.FontWeight.SemiBold),
TextSize=14,
BackgroundTransparency=1,
TextTransparency=.7,

TextWrapped=true
}),
ai("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
Padding=UDim.new(0,10)
}),
at,
ai("UIPadding",{
PaddingLeft=UDim.new(0,11),
PaddingRight=UDim.new(0,11),
})
}),
ai("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
Name="Content",
Visible=true,
Position=UDim2.new(0,0,0,ar.HeaderSize)
},{
ai("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,aq.Gap),
VerticalAlignment="Bottom",
}),
})
})


function ar.Tab(av,aw)
if not ar.Expandable then
ar.Expandable=true
at.Visible=true
end
aw.Parent=au.Content
return al.New(aw,ap)
end

function ar.Open(av)
if ar.Expandable then
ar.Opened=true
ak(au,0.33,{
Size=UDim2.new(1,0,0,ar.HeaderSize+(au.Content.AbsoluteSize.Y/ap))
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

ak(at.ImageLabel,0.1,{Rotation=180},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end
function ar.Close(av)
if ar.Expandable then
ar.Opened=false
ak(au,0.26,{
Size=UDim2.new(1,0,0,ar.HeaderSize)
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ak(at.ImageLabel,0.1,{Rotation=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end

af.AddSignal(au.TextButton.MouseButton1Click,function()
if ar.Expandable then
if ar.Opened then
ar:Close()
else
ar:Open()
end
end
end)

af.AddSignal(au.Content.UIListLayout:GetPropertyChangedSignal"AbsoluteContentSize",function()
if ar.Opened then
ar:Open()
end
end)

if ar.Opened then
task.spawn(function()
task.wait()
ar:Open()
end)
end



return ar
end


return aa end function a.ac()
return{
Tab="table-of-contents",
Paragraph="type",
Button="square-mouse-pointer",
Toggle="toggle-right",
Slider="sliders-horizontal",
Keybind="command",
Input="text-cursor-input",
Dropdown="chevrons-up-down",
Code="terminal",
Colorpicker="palette",
}end function a.ad()
local aa=(cloneref or clonereference or function(aa)
return aa
end)

aa(game:GetService"UserInputService")

local af={
Margin=8,
Padding=9,
}

local ai=a.load'd'
local ak=ai.New
local al=ai.Tween

function af.new(am,an,ao)
local ap={
IconSize=18,
Padding=14,
Radius=22,
Width=400,
MaxHeight=380,

Icons=a.load'ac',
}

local aq=ak("TextBox",{
Text="",
PlaceholderText="Search...",
ThemeTag={
PlaceholderColor3="Placeholder",
TextColor3="Text",
},
Size=UDim2.new(1,-((ap.IconSize*2)+(ap.Padding*2)),0,0),
AutomaticSize="Y",
ClipsDescendants=true,
ClearTextOnFocus=false,
BackgroundTransparency=1,
TextXAlignment="Left",
FontFace=Font.new(ai.Font,Enum.FontWeight.Regular),
TextSize=18,
})

local ar=ak("ImageLabel",{
Image=ai.Icon"x"[1],
ImageRectSize=ai.Icon"x"[2].ImageRectSize,
ImageRectOffset=ai.Icon"x"[2].ImageRectPosition,
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=0.1,
Size=UDim2.new(0,ap.IconSize,0,ap.IconSize),
},{
ak("TextButton",{
Size=UDim2.new(1,8,1,8),
BackgroundTransparency=1,
Active=true,
ZIndex=999999999,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Text="",
}),
})

local as=ak("ScrollingFrame",{
Size=UDim2.new(1,0,0,0),
AutomaticCanvasSize="Y",
ScrollingDirection="Y",
ElasticBehavior="Never",
ScrollBarThickness=0,
CanvasSize=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
Visible=false,
},{
ak("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
}),
ak("UIPadding",{
PaddingTop=UDim.new(0,ap.Padding),
PaddingLeft=UDim.new(0,ap.Padding),
PaddingRight=UDim.new(0,ap.Padding),
PaddingBottom=UDim.new(0,ap.Padding),
}),
})

local at=ai.NewRoundFrame(ap.Radius,"Squircle",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="WindowSearchBarBackground",
},
ImageTransparency=0,
},{
ai.NewRoundFrame(ap.Radius,"Squircle",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,

Visible=false,
ThemeTag={
ImageColor3="White",
},
ImageTransparency=1,
Name="Frame",
},{
ak("Frame",{
Size=UDim2.new(1,0,0,46),
BackgroundTransparency=1,
},{








ak("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ak("ImageLabel",{
Image=ai.Icon"search"[1],
ImageRectSize=ai.Icon"search"[2].ImageRectSize,
ImageRectOffset=ai.Icon"search"[2].ImageRectPosition,
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=0.1,
Size=UDim2.new(0,ap.IconSize,0,ap.IconSize),
}),
aq,
ar,
ak("UIListLayout",{
Padding=UDim.new(0,ap.Padding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
ak("UIPadding",{
PaddingLeft=UDim.new(0,ap.Padding),
PaddingRight=UDim.new(0,ap.Padding),
}),
}),
}),
ak("Frame",{
BackgroundTransparency=1,
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
Name="Results",
},{
ak("Frame",{
Size=UDim2.new(1,0,0,1),
ThemeTag={
BackgroundColor3="Outline",
},
BackgroundTransparency=0.9,
Visible=false,
}),
as,
ak("UISizeConstraint",{
MaxSize=Vector2.new(ap.Width,ap.MaxHeight),
}),
}),
ak("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
}),
}),
})

local au=ak("Frame",{
Size=UDim2.new(0,ap.Width,0,0),
AutomaticSize="Y",
Parent=an,
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
Visible=false,

ZIndex=99999999,
},{
ak("UIScale",{
Scale=0.9,
}),
at,















})

local function CreateSearchTab(av,aw,ax,ay,az,aA)
local aB=ak("TextButton",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
BackgroundTransparency=1,
Parent=ay or nil,
},{
ai.NewRoundFrame(ap.Radius-11,"Squircle",{
Size=UDim2.new(1,0,0,0),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),

ThemeTag={
ImageColor3="Text",
},
ImageTransparency=1,
Name="Main",
},{
ai.NewRoundFrame(ap.Radius-11,"Glass-1",{
Size=UDim2.new(1,0,1,0),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
ThemeTag={
ImageColor3="White",
},
ImageTransparency=1,
Name="Outline",
},{








ak("UIPadding",{
PaddingTop=UDim.new(0,ap.Padding-2),
PaddingLeft=UDim.new(0,ap.Padding),
PaddingRight=UDim.new(0,ap.Padding),
PaddingBottom=UDim.new(0,ap.Padding-2),
}),
ak("ImageLabel",{
Image=ai.Icon(ax)[1],
ImageRectSize=ai.Icon(ax)[2].ImageRectSize,
ImageRectOffset=ai.Icon(ax)[2].ImageRectPosition,
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=0.1,
Size=UDim2.new(0,ap.IconSize,0,ap.IconSize),
}),
ak("Frame",{
Size=UDim2.new(1,-ap.IconSize-ap.Padding,0,0),
BackgroundTransparency=1,
},{
ak("TextLabel",{
Text=av,
ThemeTag={
TextColor3="Text",
},
TextSize=17,
BackgroundTransparency=1,
TextXAlignment="Left",
FontFace=Font.new(ai.Font,Enum.FontWeight.Medium),
Size=UDim2.new(1,0,0,0),
TextTruncate="AtEnd",
AutomaticSize="Y",
Name="Title",
}),
ak("TextLabel",{
Text=aw or"",
Visible=aw and true or false,
ThemeTag={
TextColor3="Text",
},
TextSize=15,
TextTransparency=0.3,
BackgroundTransparency=1,
TextXAlignment="Left",
FontFace=Font.new(ai.Font,Enum.FontWeight.Medium),
Size=UDim2.new(1,0,0,0),
TextTruncate="AtEnd",
AutomaticSize="Y",
Name="Desc",
})or nil,
ak("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Vertical",
}),
}),
ak("UIListLayout",{
Padding=UDim.new(0,ap.Padding),
FillDirection="Horizontal",
}),
}),
},true),
ak("Frame",{
Name="ParentContainer",
Size=UDim2.new(1,-ap.Padding,0,0),
AutomaticSize="Y",
BackgroundTransparency=1,
Visible=az,

},{
ai.NewRoundFrame(99,"Squircle",{
Size=UDim2.new(0,2,1,0),
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=0.9,
}),
ak("Frame",{
Size=UDim2.new(1,-ap.Padding-2,0,0),
Position=UDim2.new(0,ap.Padding+2,0,0),
BackgroundTransparency=1,
},{
ak("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
}),
}),
}),
ak("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
HorizontalAlignment="Right",
}),
})



aB.Main.Size=UDim2.new(
1,
0,
0,
aB.Main.Outline.Frame.Desc.Visible
and(((ap.Padding-2)*2)+aB.Main.Outline.Frame.Title.TextBounds.Y+6+aB.Main.Outline.Frame.Desc.TextBounds.Y)
or(((ap.Padding-2)*2)+aB.Main.Outline.Frame.Title.TextBounds.Y)
)

ai.AddSignal(aB.Main.MouseEnter,function()
al(aB.Main,0.04,{ImageTransparency=0.95}):Play()

end)
ai.AddSignal(aB.Main.InputEnded,function()
al(aB.Main,0.08,{ImageTransparency=1}):Play()

end)
ai.AddSignal(aB.Main.MouseButton1Click,function()
if aA then
aA()
end
end)

return aB
end

local function ContainsText(av,aw)
if not aw or aw==""then
return false
end

if not av or av==""then
return false
end

local ax=string.lower(av)
local ay=string.lower(aw)

return string.find(ax,ay,1,true)~=nil
end

local function Search(av)
if not av or av==""then
return{}
end

local aw={}
for ax,ay in next,am.Tabs do
local az=ContainsText(ay.Title or"",av)
local aA={}

for aB,b in next,ay.Elements do
if b.__type~="Section"then
local d=ContainsText(b.Title or"",av)
local f=ContainsText(b.Desc or"",av)

if d or f then
aA[aB]={
Title=b.Title,
Desc=b.Desc,
Original=b,
__type=b.__type,
Index=aB,
}
end
end
end

if az or next(aA)~=nil then
aw[ax]={
Tab=ay,
Title=ay.Title,
Icon=ay.Icon,
Elements=aA,
}
end
end
return aw
end

ai.AddSignal(as.UIListLayout:GetPropertyChangedSignal"AbsoluteContentSize",function()

al(as,0.06,{
Size=UDim2.new(
1,
0,
0,
math.clamp(
as.UIListLayout.AbsoluteContentSize.Y+(ap.Padding*2),
0,
ap.MaxHeight
)
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut):Play()






end)

function ap.Open(av)
task.spawn(function()
at.Frame.Visible=true
au.Visible=true
al(au.UIScale,0.12,{Scale=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end)
end

function ap.Close(av,aw)
task.spawn(function()
ao()
at.Frame.Visible=false
al(au.UIScale,0.12,{Scale=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

task.wait(0.12)
au.Visible=false
if aw then
au:Destroy()
end
end)
end

ai.AddSignal(ar.TextButton.MouseButton1Click,function()
ap:Close(true)
end)

ap:Open()

function ap.Search(av,aw)
aw=aw or""

local ax=Search(aw)

as.Visible=true
at.Frame.Results.Frame.Visible=true
for ay,az in next,as:GetChildren()do
if az.ClassName~="UIListLayout"and az.ClassName~="UIPadding"then
az:Destroy()
end
end

if ax and next(ax)~=nil then
for ay,az in next,ax do
local aA=ap.Icons.Tab
local aB=CreateSearchTab(az.Title,nil,aA,as,true,function()
ap:Close()
am:SelectTab(ay)
end)
if az.Elements and next(az.Elements)~=nil then
for b,d in next,az.Elements do
local f=ap.Icons[d.__type]
CreateSearchTab(
d.Title,
d.Desc,
f,
aB:FindFirstChild"ParentContainer"and aB.ParentContainer.Frame
or nil,
false,
function()
ap:Close()
am:SelectTab(ay)
if az.Tab.ScrollToTheElement then

az.Tab:ScrollToTheElement(d.Index)
end

end
)

end
end
end
elseif aw~=""then
ak("TextLabel",{
Size=UDim2.new(1,0,0,70),
Text="No results found",
TextSize=16,
ThemeTag={
TextColor3="Text",
},
TextTransparency=0.2,
BackgroundTransparency=1,
FontFace=Font.new(ai.Font,Enum.FontWeight.Medium),
Parent=as,
Name="NotFound",
})
else
as.Visible=false
at.Frame.Results.Frame.Visible=false
end
end

ai.AddSignal(aq:GetPropertyChangedSignal"Text",function()
ap:Search(aq.Text)
end)

return ap
end

return af end function a.ae()



local aa=(cloneref or clonereference or function(aa)
return aa
end)

local af=aa(game:GetService"UserInputService")
local ai=aa(game:GetService"RunService")
local ak=aa(game:GetService"Players")

local al=workspace.CurrentCamera

local am=a.load't'

local an=a.load'd'
local ao=an.New
local ap=an.Tween


local aq=a.load'w'.New
local ar=a.load'm'.New
local as=a.load'x'.New
local at=a.load'y'

local au=a.load'z'



return function(av)
local aw={
Title=av.Title or"UI Library",
Author=av.Author,
Icon=av.Icon,
IconSize=av.IconSize or 22,
IconThemed=av.IconThemed,
IconRadius=av.IconRadius or 0,
Folder=av.Folder,
Resizable=av.Resizable~=false,
Background=av.Background,
BackgroundImageTransparency=av.BackgroundImageTransparency or 0,
ShadowTransparency=av.ShadowTransparency or 0.6,
User=av.User or{},
Footer=av.Footer or{},
Topbar=av.Topbar or{Height=52,ButtonsType="Default"},

Size=av.Size,

MinSize=av.MinSize or Vector2.new(560,350),
MaxSize=av.MaxSize or Vector2.new(850,560),

TopBarButtonIconSize=av.TopBarButtonIconSize,

ToggleKey=av.ToggleKey,
ElementsRadius=av.ElementsRadius,
Radius=av.Radius or 16,
Transparent=av.Transparent or false,
HideSearchBar=av.HideSearchBar~=false,
ScrollBarEnabled=av.ScrollBarEnabled or false,
SideBarWidth=av.SideBarWidth or 200,
Acrylic=av.Acrylic or false,
NewElements=av.NewElements or false,
IgnoreAlerts=av.IgnoreAlerts or false,
HidePanelBackground=av.HidePanelBackground or false,
AutoScale=av.AutoScale~=false,
OpenButton=av.OpenButton,
DragFrameSize=160,

Position=UDim2.new(0.5,0,0.5,0),
UICorner=16,
UIPadding=14,
UIElements={},
CanDropdown=true,
Closed=false,
Parent=av.Parent,
Destroyed=false,
IsFullscreen=false,
CanResize=av.Resizable~=false,
IsOpenButtonEnabled=true,

CurrentConfig=nil,
ConfigManager=nil,
AcrylicPaint=nil,
CurrentTab=nil,
TabModule=nil,

OnOpenCallback=nil,
OnCloseCallback=nil,
OnDestroyCallback=nil,

IsPC=false,

Gap=5,

TopBarButtons={},
AllElements={},

ElementConfig={},

PendingFlags={},

IsToggleDragging=false,
}

aw.UICorner=aw.Radius

aw.TopBarButtonIconSize=aw.TopBarButtonIconSize or(aw.Topbar.ButtonsType=="Mac"and 11 or 16)

aw.ElementConfig={
UIPadding=(aw.NewElements and 10 or 13),
UICorner=aw.ElementsRadius or(aw.NewElements and 23 or 16),
}

local ax=aw.Size or UDim2.new(0,580,0,460)
aw.Size=UDim2.new(
ax.X.Scale,
math.clamp(ax.X.Offset,aw.MinSize.X,aw.MaxSize.X),
ax.Y.Scale,
math.clamp(ax.Y.Offset,aw.MinSize.Y,aw.MaxSize.Y)
)

if aw.Topbar=={}then
aw.Topbar={Height=52,ButtonsType="Default"}
end

if not ai:IsStudio()and aw.Folder and writefile then
if not isfolder("WindUI/"..aw.Folder)then
makefolder("WindUI/"..aw.Folder)
end
if not isfolder("WindUI/"..aw.Folder.."/assets")then
makefolder("WindUI/"..aw.Folder.."/assets")
end
if not isfolder(aw.Folder)then
makefolder(aw.Folder)
end
if not isfolder(aw.Folder.."/assets")then
makefolder(aw.Folder.."/assets")
end
end

local ay=ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
})

if aw.Folder then
aw.ConfigManager=au:Init(aw)
end

if aw.Acrylic then local
az=am.AcrylicPaint{UseAcrylic=aw.Acrylic}

aw.AcrylicPaint=az
end

local az=ao("Frame",{
Size=UDim2.new(0,32,0,32),
Position=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(0.5,0.5),
BackgroundTransparency=1,
ZIndex=99,
Active=true,
},{
ao("ImageLabel",{
Size=UDim2.new(0,96,0,96),
BackgroundTransparency=1,
Image="rbxassetid://120997033468887",
Position=UDim2.new(0.5,-16,0.5,-16),
AnchorPoint=Vector2.new(0.5,0.5),
ImageTransparency=1,
}),
})
local aA=an.NewRoundFrame(aw.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
ImageColor3=Color3.new(0,0,0),
ZIndex=98,
Active=false,
},{
ao("ImageLabel",{
Size=UDim2.new(0,70,0,70),
Image=an.Icon"expand"[1],
ImageRectOffset=an.Icon"expand"[2].ImageRectPosition,
ImageRectSize=an.Icon"expand"[2].ImageRectSize,
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
ImageTransparency=1,
}),
})

local aB=an.NewRoundFrame(aw.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
ImageColor3=Color3.new(0,0,0),
ZIndex=999,
Active=false,
})









aw.UIElements.SideBar=ao("ScrollingFrame",{
Size=UDim2.new(
1,
aw.ScrollBarEnabled and-3-(aw.UIPadding/2)or 0,
1,
not aw.HideSearchBar and-45 or 0
),
Position=UDim2.new(0,0,1,0),
AnchorPoint=Vector2.new(0,1),
BackgroundTransparency=1,
ScrollBarThickness=0,
ElasticBehavior="Never",
CanvasSize=UDim2.new(0,0,0,0),
AutomaticCanvasSize="Y",
ScrollingDirection="Y",
ClipsDescendants=true,
VerticalScrollBarPosition="Left",
},{
ao("Frame",{
BackgroundTransparency=1,
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
Name="Frame",
},{
ao("UIPadding",{



PaddingBottom=UDim.new(0,aw.UIPadding/2),
}),
ao("UIListLayout",{
SortOrder="LayoutOrder",
Padding=UDim.new(0,aw.Gap),
}),
}),
ao("UIPadding",{

PaddingLeft=UDim.new(0,aw.UIPadding/2),
PaddingRight=UDim.new(0,aw.UIPadding/2),
PaddingBottom=UDim.new(0,aw.UIPadding/2),
}),

})

aw.UIElements.SideBarContainer=ao("Frame",{
Size=UDim2.new(
0,
aw.SideBarWidth,
1,
aw.User.Enabled and-aw.Topbar.Height-42-(aw.UIPadding*2)or-aw.Topbar.Height
),
Position=UDim2.new(0,0,0,aw.Topbar.Height),
BackgroundTransparency=1,
Visible=true,
},{
ao("Frame",{
Name="Content",
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,not aw.HideSearchBar and-45-aw.UIPadding or-aw.UIPadding/2),
Position=UDim2.new(0,0,1,-aw.UIPadding/2),
AnchorPoint=Vector2.new(0,1),
}),
aw.UIElements.SideBar,
})

if aw.ScrollBarEnabled then
as(
aw.UIElements.SideBar,
aw.UIElements.SideBarContainer.Content,
aw,
3,
av.WindUI
)
end

aw.UIElements.MainBar=ao("Frame",{
Size=UDim2.new(1,-aw.UIElements.SideBarContainer.AbsoluteSize.X,1,-aw.Topbar.Height),
Position=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(1,1),
BackgroundTransparency=1,
},{
an.NewRoundFrame(aw.UICorner-(aw.UIPadding/2),"Squircle",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="PanelBackground",
ImageTransparency="PanelBackgroundTransparency",
},


ZIndex=3,
Name="Background",
Visible=not aw.HidePanelBackground,
}),
ao("UIPadding",{

PaddingLeft=UDim.new(0,aw.UIPadding/2),
PaddingRight=UDim.new(0,aw.UIPadding/2),
PaddingBottom=UDim.new(0,aw.UIPadding/2),
}),
})

local b=ao("ImageLabel",{
Image="rbxassetid://8992230677",
ThemeTag={
ImageColor3="WindowShadow",

},
ImageTransparency=1,
Size=UDim2.new(1,100,1,100),
Position=UDim2.new(0,-50,0,-50),
ScaleType="Slice",
SliceCenter=Rect.new(99,99,99,99),
BackgroundTransparency=1,
ZIndex=-999999999999999,
Name="Blur",
})

if af.TouchEnabled and not af.KeyboardEnabled then
aw.IsPC=false
elseif af.KeyboardEnabled then
aw.IsPC=true
else
aw.IsPC=nil
end







local d
if aw.User then
local function GetUserThumb()local
f=ak:GetUserThumbnailAsync(
aw.User.Anonymous and 1 or ak.LocalPlayer.UserId,
Enum.ThumbnailType.HeadShot,
Enum.ThumbnailSize.Size420x420
)
return f
end

d=ao("TextButton",{
Size=UDim2.new(
0,
aw.UIElements.SideBarContainer.AbsoluteSize.X-(aw.UIPadding/2),
0,
42+aw.UIPadding
),
Position=UDim2.new(0,aw.UIPadding/2,1,-(aw.UIPadding/2)),
AnchorPoint=Vector2.new(0,1),
BackgroundTransparency=1,
Visible=aw.User.Enabled or false,
},{
an.NewRoundFrame(aw.UICorner-(aw.UIPadding/2),"SquircleOutline",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=1,
Name="Outline",
},{
ao("UIGradient",{
Rotation=78,
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.0,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(1.0,Color3.fromRGB(255,255,255)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.0,0.1),
NumberSequenceKeypoint.new(0.5,1),
NumberSequenceKeypoint.new(1.0,0.1),
},
}),
}),
an.NewRoundFrame(aw.UICorner-(aw.UIPadding/2),"Squircle",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=1,
Name="UserIcon",
},{
ao("ImageLabel",{
Image=GetUserThumb(),
BackgroundTransparency=1,
Size=UDim2.new(0,42,0,42),
ThemeTag={
BackgroundColor3="Text",
},
BackgroundTransparency=0.93,
},{
ao("UICorner",{
CornerRadius=UDim.new(1,0),
}),
}),
ao("Frame",{
AutomaticSize="XY",
BackgroundTransparency=1,
},{
ao("TextLabel",{
Text=aw.User.Anonymous and"Anonymous"or ak.LocalPlayer.DisplayName,
TextSize=17,
ThemeTag={
TextColor3="Text",
},
FontFace=Font.new(an.Font,Enum.FontWeight.SemiBold),
AutomaticSize="Y",
BackgroundTransparency=1,
Size=UDim2.new(1,-27,0,0),
TextTruncate="AtEnd",
TextXAlignment="Left",
Name="DisplayName",
}),
ao("TextLabel",{
Text=aw.User.Anonymous and"anonymous"or ak.LocalPlayer.Name,
TextSize=15,
TextTransparency=0.6,
ThemeTag={
TextColor3="Text",
},
FontFace=Font.new(an.Font,Enum.FontWeight.Medium),
AutomaticSize="Y",
BackgroundTransparency=1,
Size=UDim2.new(1,-27,0,0),
TextTruncate="AtEnd",
TextXAlignment="Left",
Name="UserName",
}),
ao("UIListLayout",{
Padding=UDim.new(0,4),
HorizontalAlignment="Left",
}),
}),
ao("UIListLayout",{
Padding=UDim.new(0,aw.UIPadding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
ao("UIPadding",{
PaddingLeft=UDim.new(0,aw.UIPadding/2),
PaddingRight=UDim.new(0,aw.UIPadding/2),
}),
}),
})

function aw.User.Enable(f)
aw.User.Enabled=true
ap(
aw.UIElements.SideBarContainer,
0.25,
{Size=UDim2.new(0,aw.SideBarWidth,1,-aw.Topbar.Height-42-(aw.UIPadding*2))},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
d.Visible=true
end
function aw.User.Disable(f)
aw.User.Enabled=false
ap(
aw.UIElements.SideBarContainer,
0.25,
{Size=UDim2.new(0,aw.SideBarWidth,1,-aw.Topbar.Height)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
d.Visible=false
end
function aw.User.SetAnonymous(f,g)
if g~=false then
g=true
end
aw.User.Anonymous=g
d.UserIcon.ImageLabel.Image=GetUserThumb()
d.UserIcon.Frame.DisplayName.Text=g and"Anonymous"or ak.LocalPlayer.DisplayName
d.UserIcon.Frame.UserName.Text=g and"anonymous"or ak.LocalPlayer.Name
end

if aw.User.Enabled then
aw.User:Enable()
else
aw.User:Disable()
end

if aw.User.Callback then
an.AddSignal(d.MouseButton1Click,function()
aw.User.Callback()
end)
an.AddSignal(d.MouseEnter,function()
ap(d.UserIcon,0.04,{ImageTransparency=0.95}):Play()
ap(d.Outline,0.04,{ImageTransparency=0.85}):Play()
end)
an.AddSignal(d.InputEnded,function()
ap(d.UserIcon,0.04,{ImageTransparency=1}):Play()
ap(d.Outline,0.04,{ImageTransparency=1}):Play()
end)
end
end

local f
local g

local h=false
local i

local l=typeof(aw.Background)=="string"and string.match(aw.Background,"^video:(.+)")or nil

local m=typeof(aw.Background)=="string"
and not l
and string.match(aw.Background,"^https?://.+")
or nil

local p=typeof(aw.Background)=="string"
and not l
and string.match(aw.Background,"^rbxassetid://%d+")
or nil

local function GetImageExtension(r)
if not r or typeof(r)~="string"then
return".png"
end
local u=r:match"^([^?#]+)"or r
local v=u:match"%.(%w+)$"
if v then
v=v:lower()
if v=="jpg"or v=="jpeg"or v=="png"or v=="webp"then
return"."..v
end
end
return".png"
end



if typeof(aw.Background)=="string"and l then
h=true

if string.find(l,"http")then
local r=(aw.Folder or"Temp").."/assets/."..an.SanitizeFilename(l)..".webm"
if not isfile(r)then
local u,v=pcall(function()





local u=game.HttpGet and game:HttpGet(l)
or an.Request{
Url=l,
Method="GET",
Headers={["User-Agent"]="Roblox/Exploit"},
}.Body

writefile(r,u)
end)
if not u then
warn("[ WindUI.Window.Background ] Failed to download video: "..tostring(v))
end
end

local u,v=pcall(function()
return getcustomasset(r)
end)
if not u then
warn("[ WindUI.Window.Background ] Failed to load custom asset: "..tostring(v))
end
warn"[ WindUI.Window.Background ] VideoFrame may not work with custom video"
l=v
end

i=ao("VideoFrame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
Video=l,
Looped=true,
Volume=0,
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
})
i:Play()
elseif m then
local r=(aw.Folder or"Temp")
.."/assets/."
..an.SanitizeFilename(m)
..GetImageExtension(m)

if isfile and not isfile(r)then
local u,v=pcall(function()
local u=game.HttpGet and game:HttpGet(m)
or an.Request{
Url=m,
Method="GET",
Headers={["User-Agent"]="Roblox/Exploit"},
}.Body

writefile(r,u)
end)

if not u then
warn("[ Window.Background ] Failed to download image: "..tostring(v))
end
end

local u,v=pcall(function()
return getcustomasset(r)
end)

if not u then
warn("[ Window.Background ] Failed to load custom asset: "..tostring(v))
end

i=ao("ImageLabel",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
Image=v,
ImageTransparency=0,
ScaleType="Crop",
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
})
elseif p then
i=ao("ImageLabel",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
Image=p,
ImageTransparency=0,
ScaleType="Crop",
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
})
elseif aw.Background then
i=ao("ImageLabel",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
Image=typeof(aw.Background)=="string"and aw.Background or"",
ImageTransparency=1,
ScaleType="Crop",
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
})
end

local r=an.NewRoundFrame(99,"Squircle",{
ImageTransparency=0.8,
ImageColor3=Color3.new(1,1,1),
Size=UDim2.new(0,0,0,4),
Position=UDim2.new(0.5,0,1,4),
AnchorPoint=Vector2.new(0.5,0),
},{
ao("TextButton",{
Size=UDim2.new(1,12,1,12),
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
Active=true,
ZIndex=99,
Name="Frame",
}),
})

function createAuthor(u)
return ao("TextLabel",{
Text=u,
FontFace=Font.new(an.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
TextTransparency=0.35,
AutomaticSize="XY",
Parent=aw.UIElements.Main and aw.UIElements.Main.Main.Topbar.Left.Title,
TextXAlignment="Left",
TextSize=13,
LayoutOrder=2,
ThemeTag={
TextColor3="WindowTopbarAuthor",
},
Name="Author",
})
end

local u
local v

if aw.Author then
u=createAuthor(aw.Author)
end

local x=ao("TextLabel",{
Text=aw.Title,
FontFace=Font.new(an.Font,Enum.FontWeight.SemiBold),
BackgroundTransparency=1,
AutomaticSize="XY",
Name="Title",
TextXAlignment="Left",
TextSize=16,
ThemeTag={
TextColor3="WindowTopbarTitle",
},
})

aw.UIElements.Main=ao("Frame",{
Size=UDim2.new(aw.Size.X.Scale,aw.Size.X.Offset,0,0),
Position=aw.Position,
BackgroundTransparency=1,
Parent=av.Parent,
AnchorPoint=Vector2.new(0.5,0.5),
Active=true,

},{
av.WindUI.UIScaleObj,
aw.AcrylicPaint and aw.AcrylicPaint.Frame or nil,
b,
an.NewRoundFrame(aw.UICorner,"Squircle",{
ImageTransparency=1,
Size=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Background",
ThemeTag={
ImageColor3="WindowBackground",
},

},{
i,
r,
az,
}),




ay,
aA,
aB,
ao("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Name="Main",

Visible=false,
ZIndex=97,
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
aw.UIElements.SideBarContainer,
aw.UIElements.MainBar,

d,

g,
ao("Frame",{
Size=UDim2.new(1,0,0,aw.Topbar.Height),
BackgroundTransparency=1,
BackgroundColor3=Color3.fromRGB(50,50,50),
Name="Topbar",
},{
f,






ao("Frame",{
AutomaticSize="X",
Size=UDim2.new(0,0,1,0),
BackgroundTransparency=1,
Name="Left",
},{
ao("UIListLayout",{
Padding=UDim.new(0,aw.UIPadding+4),
SortOrder="LayoutOrder",
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
ao("Frame",{
AutomaticSize="XY",
BackgroundTransparency=1,
Name="Title",
Size=UDim2.new(0,0,1,0),
LayoutOrder=2,
},{
ao("UIListLayout",{
Padding=UDim.new(0,0),
SortOrder="LayoutOrder",
FillDirection="Vertical",
VerticalAlignment="Center",
}),
x,
u,
}),
ao("UIPadding",{
PaddingLeft=UDim.new(0,4),
}),
}),
ao("CanvasGroup",{
Size=UDim2.new(0,0,1,0),
BackgroundTransparency=1,
Name="Center",
AnchorPoint=Vector2.new(0,0.5),
Position=UDim2.new(0,0,0.5,0),
AutomaticSize="Y",
Visible=false,
},{



ao("ScrollingFrame",{
Name="Holder",
BackgroundTransparency=1,
AutomaticSize="Y",
ScrollBarThickness=0,
ScrollingDirection="X",
AutomaticCanvasSize="X",
CanvasSize=UDim2.new(0,0,0,0),
Size=UDim2.new(1,0,1,0),


},{

ao("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Left",
Padding=UDim.new(0,aw.UIPadding/2),
}),
}),
}),
ao("Frame",{
AutomaticSize="XY",
BackgroundTransparency=1,
Position=UDim2.new(aw.Topbar.ButtonsType=="Default"and 1 or 0,0,0.5,0),
AnchorPoint=Vector2.new(aw.Topbar.ButtonsType=="Default"and 1 or 0,0.5),
Name="Right",
},{
ao("UIListLayout",{
Padding=UDim.new(0,aw.Topbar.ButtonsType=="Default"and 9 or 0),
FillDirection="Horizontal",
SortOrder="LayoutOrder",
}),
}),
ao("UIPadding",{
PaddingTop=UDim.new(0,aw.UIPadding),
PaddingLeft=UDim.new(
0,
aw.Topbar.ButtonsType=="Default"and aw.UIPadding or aw.UIPadding-2
),
PaddingRight=UDim.new(0,8),
PaddingBottom=UDim.new(0,aw.UIPadding),
}),
}),
}),
})

an.AddSignal(aw.UIElements.Main.Main.Topbar.Left:GetPropertyChangedSignal"AbsoluteSize",function()
local z=0
local A=aw.UIElements.Main.Main.Topbar.Right.UIListLayout.AbsoluteContentSize.X
/av.WindUI.UIScale

z=aw.UIElements.Main.Main.Topbar.Left.AbsoluteSize.X/av.WindUI.UIScale
if aw.Topbar.ButtonsType~="Default"then
z=z+A+aw.UIPadding-4
end

aw.UIElements.Main.Main.Topbar.Center.Position=
UDim2.new(0,z+(aw.UIPadding/av.WindUI.UIScale),0.5,0)
aw.UIElements.Main.Main.Topbar.Center.Size=UDim2.new(
1,
-z
-(aw.UIPadding/av.WindUI.UIScale)
-(aw.Topbar.ButtonsType=="Default"and A+aw.UIPadding or 0),
1,
0
)
end)

if aw.Topbar.ButtonsType~="Default"then
an.AddSignal(aw.UIElements.Main.Main.Topbar.Right:GetPropertyChangedSignal"AbsoluteSize",function()
aw.UIElements.Main.Main.Topbar.Left.Position=UDim2.new(
0,
(aw.UIElements.Main.Main.Topbar.Right.AbsoluteSize.X/av.WindUI.UIScale)+aw.UIPadding-4,
0,
0
)
end)
end

function aw.CreateTopbarButton(z,A,B,C,F,G,H,J)
local L=an.Image(
B,
B,
0,
aw.Folder,
"WindowTopbarIcon",
aw.Topbar.ButtonsType=="Default"and true or false,
G,
"WindowTopbarButtonIcon"
)
L.Size=aw.Topbar.ButtonsType=="Default"
and UDim2.new(0,J or aw.TopBarButtonIconSize,0,J or aw.TopBarButtonIconSize)
or UDim2.new(0,0,0,0)
L.AnchorPoint=Vector2.new(0.5,0.5)
L.Position=UDim2.new(0.5,0,0.5,0)
L.ImageLabel.ImageTransparency=aw.Topbar.ButtonsType=="Default"and 0 or 1

if aw.Topbar.ButtonsType~="Default"then
L.ImageLabel.ImageColor3=an.GetTextColorForHSB(H)
end

local M=an.NewRoundFrame(
aw.Topbar.ButtonsType=="Default"and aw.UICorner-(aw.UIPadding/2)or 999,
"Squircle",
{
Size=aw.Topbar.ButtonsType=="Default"
and UDim2.new(0,aw.Topbar.Height-16,0,aw.Topbar.Height-16)
or UDim2.new(0,14,0,14),
LayoutOrder=F or 999,


ZIndex=9999,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ImageColor3=aw.Topbar.ButtonsType~="Default"and(H or Color3.fromHex"#ff3030")or nil,
ThemeTag=aw.Topbar.ButtonsType=="Default"and{
ImageColor3="Text",
}or nil,
ImageTransparency=aw.Topbar.ButtonsType=="Default"and 1 or 0,
},
{












L,
ao("UIScale",{
Scale=1,
}),
},
true
)

local N=ao("Frame",{
Size=aw.Topbar.ButtonsType~="Default"and UDim2.new(0,24,0,24)
or UDim2.new(0,aw.Topbar.Height-16,0,aw.Topbar.Height-16),
BackgroundTransparency=1,
Parent=aw.UIElements.Main.Main.Topbar.Right,
LayoutOrder=F or 999,
},{
M,
})



aw.TopBarButtons[100-F]={
Name=A,
Object=N,
}

an.AddSignal(M.MouseButton1Click,function()
if C then
C()
end
end)
an.AddSignal(M.MouseEnter,function()
if aw.Topbar.ButtonsType=="Default"then
ap(M,0.15,{ImageTransparency=0.93}):Play()


else

ap(
L.ImageLabel,
0.1,
{ImageTransparency=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ap(L,0.1,{
Size=UDim2.new(
0,
J or aw.TopBarButtonIconSize,
0,
J or aw.TopBarButtonIconSize
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end)

an.AddSignal(M.MouseButton1Down,function()
ap(M.UIScale,0.2,{Scale=0.9},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end)

an.AddSignal(M.MouseLeave,function()
if aw.Topbar.ButtonsType=="Default"then
ap(M,0.1,{ImageTransparency=1}):Play()


else

ap(
L.ImageLabel,
0.1,
{ImageTransparency=1},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ap(
L,
0.1,
{Size=UDim2.new(0,0,0,0)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
end)

an.AddSignal(M.InputEnded,function()
ap(M.UIScale,0.2,{Scale=1},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut):Play()
end)

return M
end

function aw.Topbar.Button(z,A:{
Name:string,
Icon:string,
Callback:any,
LayoutOrder:number,
IconThemed:boolean,
Color:Color3,
IconSize:number,
})
return aw:CreateTopbarButton(
A.Name,
A.Icon,
A.Callback,
A.LayoutOrder or 0,
A.IconThemed,
A.Color,
A.IconSize
)
end



local z=an.Drag(
aw.UIElements.Main,
{aw.UIElements.Main.Main.Topbar,r.Frame},
function(z,A)
if not aw.Closed then
if z and A==r.Frame then
ap(r,0.1,{ImageTransparency=0.35}):Play()
else
ap(r,0.2,{ImageTransparency=0.8}):Play()
end
aw.Position=aw.UIElements.Main.Position
aw.Dragging=z
end
end
)

if not h and aw.Background and typeof(aw.Background)=="table"then
local A=ao"UIGradient"
for B,C in next,aw.Background do
A[B]=C
end

aw.UIElements.BackgroundGradient=an.NewRoundFrame(aw.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
Parent=aw.UIElements.Main.Background,
ImageTransparency=aw.Transparent and av.WindUI.TransparencyValue or 0,
},{
A,
})
end














aw.OpenButtonMain=a.load'A'.New(aw)

task.spawn(function()
if aw.Icon then
local A=ao("Frame",{
Size=UDim2.new(0,22,0,22),
BackgroundTransparency=1,
Parent=aw.UIElements.Main.Main.Topbar.Left,
})

v=an.Image(
aw.Icon,
aw.Title,
aw.IconRadius,
aw.Folder,
"Window",
true,
aw.IconThemed,
"WindowTopbarIcon"
)
v.Parent=A
v.Size=UDim2.new(0,aw.IconSize,0,aw.IconSize)
v.Position=UDim2.new(0.5,0,0.5,0)
v.AnchorPoint=Vector2.new(0.5,0.5)

aw.OpenButtonMain:SetIcon(aw.Icon)











else
aw.OpenButtonMain:SetIcon(aw.Icon)

end
end)

function aw.SetToggleKey(A,B)
aw.ToggleKey=B
end

function aw.SetTitle(A,B)
aw.Title=B
x.Text=B
end

function aw.SetAuthor(A,B)
aw.Author=B
if not u then
u=createAuthor(aw.Author)
end

u.Text=B
end

function aw.SetSize(A,B)
if typeof(B)=="UDim2"then
aw.Size=B

ap(aw.UIElements.Main,0.08,{Size=B},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end

function aw.SetBackgroundImage(A,B)
aw.UIElements.Main.Background.ImageLabel.Image=B
end
function aw.SetBackgroundImageTransparency(A,B)
if i and i:IsA"ImageLabel"then
i.ImageTransparency=math.floor(B*10+0.5)/10
end
aw.BackgroundImageTransparency=math.floor(B*10+0.5)/10
end

function aw.SetBackgroundTransparency(A,B)
local C=math.floor(tonumber(B)*10+0.5)/10
av.WindUI.TransparencyValue=C
aw:ToggleTransparency(C>0)
end

local A
local B
an.Icon"minimize"
an.Icon"maximize"

aw:CreateTopbarButton(
"Fullscreen",
aw.Topbar.ButtonsType=="Mac"and"rbxassetid://127426072704909"or"maximize",
function()
aw:ToggleFullscreen()
end,
(aw.Topbar.ButtonsType=="Default"and 998 or 999),
true,
Color3.fromHex"#60C762",
aw.Topbar.ButtonsType=="Mac"and 9 or nil
)

local function SetSize(C)
ap(aw.UIElements.Main,0.45,{
Size=not aw.IsFullscreen and B or UDim2.new(
0,
(av.WindUI.ScreenGui.AbsoluteSize.X-20)/av.WindUI.UIScale,
0,
(av.WindUI.ScreenGui.AbsoluteSize.Y-20-52)/av.WindUI.UIScale
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

ap(
aw.UIElements.Main,
0.45,
{Position=not aw.IsFullscreen and A or UDim2.new(0.5,0,0.5,26)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end

function aw.ToggleFullscreen(C)
local F=aw.IsFullscreen

z:Set(F)

if not F then
A=aw.UIElements.Main.Position
B=aw.UIElements.Main.Size

aw.CanResize=false
else
if aw.Resizable then
aw.CanResize=true
end
end

aw.IsFullscreen=not F

SetSize(true)
end

an.AddSignal(av.WindUI.ScreenGui:GetPropertyChangedSignal"AbsoluteSize",function()
if aw.IsFullscreen then
SetSize()
end
end)

aw:CreateTopbarButton("Minimize","minus",function()
if aw.Close then
aw:Close()
end






















end,(aw.Topbar.ButtonsType=="Default"and 997 or 998),nil,Color3.fromHex"#F4C948")

function aw.OnOpen(C,F)
aw.OnOpenCallback=F
end
function aw.OnClose(C,F)
aw.OnCloseCallback=F
end
function aw.OnDestroy(C,F)
aw.OnDestroyCallback=F
end

if av.WindUI.UseAcrylic then
aw.AcrylicPaint.AddParent(aw.UIElements.Main)
end

function aw.SetIconSize(C,F)
local G
if typeof(F)=="number"then
G=UDim2.new(0,F,0,F)
aw.IconSize=F
elseif typeof(F)=="UDim2"then
G=F
aw.IconSize=F.X.Offset
end

if v then
v.Size=G
end
end

function aw.Open(C)
if aw.Destroyed then
return
end
task.spawn(function()
if aw.OnOpenCallback then
task.spawn(function()
an.SafeCallback(aw.OnOpenCallback)
end)
end

task.wait(0.06)
aw.Closed=false

aw.UIElements.Main.Size=UDim2.new(aw.Size.X.Scale,aw.Size.X.Offset,0,100)

ap(aw.UIElements.Main,0.8,{

Size=aw.Size,
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

if aw.UIElements.BackgroundGradient then
ap(aw.UIElements.BackgroundGradient,0.2,{
ImageTransparency=0,
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end

aw.UIElements.Main.Background.ImageTransparency=1
ap(aw.UIElements.Main.Background,0.4,{

ImageTransparency=aw.Transparent and av.WindUI.TransparencyValue or 0,
},Enum.EasingStyle.Exponential,Enum.EasingDirection.Out):Play()

if i then
if i:IsA"VideoFrame"then
i.Visible=true
else
ap(i,0.2,{
ImageTransparency=aw.BackgroundImageTransparency,
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end

if aw.OpenButtonMain and aw.IsOpenButtonEnabled then
aw.OpenButtonMain:Visible(false)
end









ap(
b,
0.25,
{ImageTransparency=aw.ShadowTransparency},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()




ap(
r,
0.45,
{Size=UDim2.new(0,aw.DragFrameSize,0,4),ImageTransparency=0.8},
Enum.EasingStyle.Exponential,
Enum.EasingDirection.Out
):Play()
z:Set(true)

if aw.Resizable then
ap(
az.ImageLabel,
0.45,
{ImageTransparency=0.8},
Enum.EasingStyle.Exponential,
Enum.EasingDirection.Out
):Play()
aw.CanResize=true
end

aw.CanDropdown=true
aw.UIElements.Main.Visible=true



aw.UIElements.Main:WaitForChild"Main".Visible=true

av.WindUI:ToggleAcrylic(true)

end)
end
function aw.Close(C)
if aw.Destroyed then
return
end

local F={}

if aw.OnCloseCallback then
task.spawn(function()
an.SafeCallback(aw.OnCloseCallback)
end)
end

av.WindUI:ToggleAcrylic(false)

if aw.UIElements.Main and aw.UIElements.Main:WaitForChild"Main"then
aw.UIElements.Main.Main.Visible=false
end

aw.CanDropdown=false
aw.Closed=true

ap(aw.UIElements.Main,0.9,{

Size=UDim2.new(aw.Size.X.Scale,aw.Size.X.Offset,0,0),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
if aw.UIElements.BackgroundGradient then
ap(aw.UIElements.BackgroundGradient,0.2,{
ImageTransparency=1,
},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut):Play()
end

ap(aw.UIElements.Main.Background,0.3,{

ImageTransparency=1,
},Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut):Play()








if i then
if i:IsA"VideoFrame"then
i.Visible=false
else
ap(i,0.3,{
ImageTransparency=1,
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end
ap(b,0.25,{ImageTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()




ap(
r,
0.3,
{Size=UDim2.new(0,0,0,4),ImageTransparency=1},
Enum.EasingStyle.Exponential,
Enum.EasingDirection.InOut
):Play()
ap(
az.ImageLabel,
0.3,
{ImageTransparency=1},
Enum.EasingStyle.Exponential,
Enum.EasingDirection.Out
):Play()
z:Set(false)
aw.CanResize=false

task.spawn(function()
task.wait(0.4)

if not aw.Closed then
return
end

aw.UIElements.Main.Visible=false

if aw.OpenButtonMain and not aw.Destroyed and not aw.IsPC and aw.IsOpenButtonEnabled then
aw.OpenButtonMain:Visible(true)
end
end)

function F.Destroy(G)
task.spawn(function()
if aw.OnDestroyCallback then
task.spawn(function()
an.SafeCallback(aw.OnDestroyCallback)
end)
end

if aw.AcrylicPaint and aw.AcrylicPaint.Model then
aw.AcrylicPaint.Model:Destroy()
end

aw.Destroyed=true

task.wait(0.4)

av.WindUI.ScreenGui:Destroy()
av.WindUI.NotificationGui:Destroy()
av.WindUI.DropdownGui:Destroy()
av.WindUI.TooltipGui:Destroy()

an.DisconnectAll()

return
end)
end

return F
end
function aw.Destroy(C)
return aw:Close():Destroy()
end
function aw.Toggle(C)
if aw.Closed then
aw:Open()
else
aw:Close()
end
end

function aw.ToggleTransparency(C,F)

aw.Transparent=F
av.WindUI.Transparent=F

aw.UIElements.Main.Background.ImageTransparency=F and av.WindUI.TransparencyValue or 0


end

function aw.LockAll(C)
for F,G in next,aw.AllElements do
if G.Lock then
G:Lock()
end
end
end
function aw.UnlockAll(C)
for F,G in next,aw.AllElements do
if G.Unlock then
G:Unlock()
end
end
end
function aw.GetLocked(C)
local F={}

for G,H in next,aw.AllElements do
if H.Locked then
table.insert(F,H)
end
end

return F
end
function aw.GetUnlocked(C)
local F={}

for G,H in next,aw.AllElements do
if H.Locked==false then
table.insert(F,H)
end
end

return F
end

function aw.GetUIScale(C,F)
return av.WindUI.UIScale
end

function aw.SetUIScale(C,F)
av.WindUI.UIScale=F
ap(av.WindUI.UIScaleObj,0.2,{Scale=F},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
return aw
end

function aw.SetToTheCenter(C)
ap(
aw.UIElements.Main,
0.45,
{Position=UDim2.new(0.5,0,0.5,0)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
return aw
end

function aw.SetCurrentConfig(C,F)
aw.CurrentConfig=F
end

do
local C=40
local F=al.ViewportSize
local G=Vector2.new(aw.Size.X.Offset,aw.Size.Y.Offset)

if not aw.IsFullscreen and aw.AutoScale then
local H=F.X-(C*2)
local J=F.Y-(C*2)

local L=H/G.X
local M=J/G.Y

local N=math.min(L,M)

local O=0.3
local P=1.0

local Q=math.clamp(N,O,P)

local R=aw:GetUIScale()or 1
local S=0.05

if math.abs(Q-R)>S then
aw:SetUIScale(Q)
end
end
end

if aw.OpenButtonMain and aw.OpenButtonMain.Button then
an.AddSignal(aw.OpenButtonMain.Button.TextButton.MouseButton1Click,function()


aw:Open()
end)
end

an.AddSignal(af.InputBegan,function(C,F)
if F then
return
end

if aw.ToggleKey then
if C.KeyCode==aw.ToggleKey then
aw:Toggle()
end
end
end)

task.spawn(function()

aw:Open()
end)

function aw.EditOpenButton(C,F)
return aw.OpenButtonMain:Edit(F)
end

if aw.OpenButton and typeof(aw.OpenButton)=="table"then
aw:EditOpenButton(aw.OpenButton)
end

local C=a.load'aa'
local F=a.load'ab'
local G=C.Init(aw,av.WindUI,av.WindUI.TooltipGui)
G:OnChange(function(H)
aw.CurrentTab=H
end)

aw.TabModule=G

function aw.Tab(H,J)
J.Parent=aw.UIElements.SideBar.Frame
return G.New(J,av.WindUI.UIScale)
end

function aw.SelectTab(H,J)
G:SelectTab(J)
end

function aw.Section(H,J)
return F.New(
J,
aw.UIElements.SideBar.Frame,
aw.Folder,
av.WindUI.UIScale,
aw
)
end

function aw.IsResizable(H,J)
aw.Resizable=J
aw.CanResize=J
end

function aw.SetPanelBackground(H,J)
if typeof(J)=="boolean"then
aw.HidePanelBackground=J

aw.UIElements.MainBar.Background.Visible=J

if G then
for L,M in next,G.Containers do
M.ScrollingFrame.UIPadding.PaddingTop=UDim.new(0,aw.HidePanelBackground and 20 or 10)
M.ScrollingFrame.UIPadding.PaddingLeft=
UDim.new(0,aw.HidePanelBackground and 20 or 10)
M.ScrollingFrame.UIPadding.PaddingRight=
UDim.new(0,aw.HidePanelBackground and 20 or 10)
M.ScrollingFrame.UIPadding.PaddingBottom=
UDim.new(0,aw.HidePanelBackground and 20 or 10)
end
end
end
end

function aw.Divider(H)
local J=ao("Frame",{
Size=UDim2.new(1,0,0,1),
Position=UDim2.new(0.5,0,0,0),
AnchorPoint=Vector2.new(0.5,0),
BackgroundTransparency=0.9,
ThemeTag={
BackgroundColor3="Text",
},
})
local L=ao("Frame",{
Parent=aw.UIElements.SideBar.Frame,

Size=UDim2.new(1,-7,0,5),
BackgroundTransparency=1,
},{
J,
})

return L
end

local H=a.load'o'
function aw.Dialog(J,L)
local M={
Title=L.Title or"Dialog",
Width=L.Width or 320,
Content=L.Content,
Buttons=L.Buttons or{},

TextPadding=14,
}
local N=H.Create(false,"Dialog",aw,av.WindUI,aw.UIElements.Main.Main)

N.UIElements.Main.Size=UDim2.new(0,M.Width,0,0)

local O=ao("Frame",{
Size=UDim2.new(1,0,1,0),
AutomaticSize="Y",
BackgroundTransparency=1,
Parent=N.UIElements.Main,
},{
ao("UIListLayout",{
FillDirection="Vertical",

Padding=UDim.new(0,N.UIPadding),
}),
})

local P=ao("Frame",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
BackgroundTransparency=1,
Parent=O,
},{
ao("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,N.UIPadding),
VerticalAlignment="Center",
}),
ao("UIPadding",{
PaddingTop=UDim.new(0,M.TextPadding/2),
PaddingLeft=UDim.new(0,M.TextPadding/2),
PaddingRight=UDim.new(0,M.TextPadding/2),
}),
})

local Q
if L.Icon then
Q=an.Image(
L.Icon,
M.Title..":"..L.Icon,
0,
aw,
"Dialog",
true,
L.IconThemed
)
Q.Size=UDim2.new(0,22,0,22)
Q.Parent=P
end

N.UIElements.UIListLayout=ao("UIListLayout",{
Padding=UDim.new(0,12),
FillDirection="Vertical",
HorizontalAlignment="Left",
VerticalFlex="SpaceBetween",
Parent=N.UIElements.Main,
})

ao("UISizeConstraint",{
MinSize=Vector2.new(180,20),
MaxSize=Vector2.new(400,math.huge),
Parent=N.UIElements.Main,
})

N.UIElements.Title=ao("TextLabel",{
Text=M.Title,
TextSize=20,
FontFace=Font.new(an.Font,Enum.FontWeight.SemiBold),
TextXAlignment="Left",
TextWrapped=true,
RichText=true,
Size=UDim2.new(1,Q and-26-N.UIPadding or 0,0,0),
AutomaticSize="Y",
ThemeTag={
TextColor3="Text",
},
BackgroundTransparency=1,
Parent=P,
})
if M.Content then
ao("TextLabel",{
Text=M.Content,
TextSize=18,
TextTransparency=0.4,
TextWrapped=true,
RichText=true,
FontFace=Font.new(an.Font,Enum.FontWeight.Medium),
TextXAlignment="Left",
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
LayoutOrder=2,
ThemeTag={
TextColor3="Text",
},
BackgroundTransparency=1,
Parent=O,
},{
ao("UIPadding",{
PaddingLeft=UDim.new(0,M.TextPadding/2),
PaddingRight=UDim.new(0,M.TextPadding/2),
PaddingBottom=UDim.new(0,M.TextPadding/2),
}),
})
end

local R=ao("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Horizontal",
HorizontalAlignment="Center",
HorizontalFlex="Fill",
})

local S=ao("Frame",{
Size=UDim2.new(1,0,0,36),
AutomaticSize="None",
BackgroundTransparency=1,
Parent=N.UIElements.Main,
LayoutOrder=4,
},{
R,






})

local T={}

for U,V in next,M.Buttons do
local W=
ar(V.Title,V.Icon,V.Callback,V.Variant,S,N,true)
table.insert(T,W)
W.Size=UDim2.new(1,0,1,0)
end





















































N:Open()

return N
end

local J=false

aw:CreateTopbarButton("Close","x",function()
if not J then
if not aw.IgnoreAlerts then
J=true

aw:Dialog{

Title="Close Window",
Content="Do you want to close this window? You will not be able to open it again.",
Buttons={
{
Title="Cancel",

Callback=function()
J=false
end,
Variant="Secondary",
},
{
Title="Close Window",

Callback=function()
J=false
aw:Destroy()
end,
Variant="Primary",
},
},
}
else
aw:Destroy()
end
end
end,(aw.Topbar.ButtonsType=="Default"and 999 or 997),nil,Color3.fromHex"#F4695F")

function aw.Tag(L,M)
if aw.UIElements.Main.Main.Topbar.Center.Visible==false then
aw.UIElements.Main.Main.Topbar.Center.Visible=true
end
M.Window=aw
return at:New(M,aw.UIElements.Main.Main.Topbar.Center.Holder)
end

local L=av.WindUI.GenerateGUID()

local function startResizing(M)
if aw.CanResize then
isResizing=true
aA.Active=true
initialSize=aw.UIElements.Main.Size
initialInputPosition=M.Position


ap(az.ImageLabel,0.1,{ImageTransparency=0.35}):Play()

an.AddSignal(M.Changed,function()
if M.UserInputState==Enum.UserInputState.End then
if av.WindUI.CurrentInput and av.WindUI.CurrentInput~=L then
return
end

av.WindUI.CurrentInput=nil

isResizing=false
aA.Active=false


ap(az.ImageLabel,0.17,{ImageTransparency=0.8}):Play()
end
end)
end
end

an.AddSignal(az.InputBegan,function(M)
if
M.UserInputType==Enum.UserInputType.MouseButton1
or M.UserInputType==Enum.UserInputType.Touch
then
if av.WindUI.CurrentInput and av.WindUI.CurrentInput~=L then
return
end
av.WindUI.CurrentInput=L

if aw.CanResize then
startResizing(M)
end
end
end)

an.AddSignal(af.InputChanged,function(M)
if
M.UserInputType==Enum.UserInputType.MouseMovement
or M.UserInputType==Enum.UserInputType.Touch
then
if isResizing and aw.CanResize then
local N=M.Position-initialInputPosition
local O=UDim2.new(0,initialSize.X.Offset+N.X*2,0,initialSize.Y.Offset+N.Y*2)

O=UDim2.new(
O.X.Scale,
math.clamp(O.X.Offset,aw.MinSize.X,aw.MaxSize.X),
O.Y.Scale,
math.clamp(O.Y.Offset,aw.MinSize.Y,aw.MaxSize.Y)
)

ap(aw.UIElements.Main,0.08,{
Size=O,
},Enum.EasingStyle.Quad,Enum.EasingDirection.Out):Play()

aw.Size=O
end
end
end)

an.AddSignal(az.MouseEnter,function()
if av.WindUI.CurrentInput and av.WindUI.CurrentInput~=L then
return
end
if not isResizing then
ap(az.ImageLabel,0.1,{ImageTransparency=0.35}):Play()
end
end)
an.AddSignal(az.MouseLeave,function()
if av.WindUI.CurrentInput and av.WindUI.CurrentInput~=L then
return
end
if not isResizing then
ap(az.ImageLabel,0.17,{ImageTransparency=0.8}):Play()
end
end)



local M=0
local N=0.4
local O
local P=0

function onDoubleClick()
aw:SetToTheCenter()
end

an.AddSignal(r.Frame.MouseButton1Up,function()
local Q=tick()
local R=aw.Position

P=P+1

if P==1 then
M=Q
O=R

task.spawn(function()
task.wait(N)
if P==1 then
P=0
O=nil
end
end)
elseif P==2 then
if Q-M<=N and R==O then
onDoubleClick()
end

P=0
O=nil
M=0
else
P=1
M=Q
O=R
end
end)



if not aw.HideSearchBar then
local Q=a.load'ad'
local R=false





















local S=aq("Search","search",aw.UIElements.SideBarContainer,true)
S.Size=UDim2.new(1,-aw.UIPadding/2,0,39)
S.Position=UDim2.new(0,aw.UIPadding/2,0,0)

an.AddSignal(S.MouseButton1Click,function()
if R then
return
end

Q.new(aw.TabModule,aw.UIElements.Main,function()

R=false
if aw.Resizable then
aw.CanResize=true
end

ap(aB,0.1,{ImageTransparency=1}):Play()
aB.Active=false
end)
ap(aB,0.1,{ImageTransparency=0.65}):Play()
aB.Active=true

R=true
aw.CanResize=false
end)
end



function aw.DisableTopbarButtons(Q,R)
for S,T in next,R do
for U,V in next,aw.TopBarButtons do
if V.Name==T then
V.Object.Visible=false
end
end
end
end



























return aw
end end end

local aa={
Window=nil,
Theme=nil,
Creator=a.load'd',
LocalizationModule=a.load'e',
NotificationModule=a.load'f',
Themes=nil,
Transparent=false,

TransparencyValue=0.15,

UIScale=1,

ConfigManager=nil,
Version="0.0.0",

Services=a.load'k',

OnThemeChangeFunction=nil,

cloneref=nil,
UIScaleObj=nil,

CreateWindow=nil,

CurrentInput=nil,
}

local af=(cloneref or clonereference or function(af)
return af
end)

aa.cloneref=af

local ai=af(game:GetService"HttpService")
local ak=af(game:GetService"Players")
local al=af(game:GetService"CoreGui")
local am=af(game:GetService"RunService")
local an=af(game:GetService"UserInputService")

function aa.GenerateGUID()
return ai:GenerateGUID(false)
end

local ao=aa.GenerateGUID()

an.InputBegan:Connect(function(ap,aq)




task.defer(function()
if
ap.UserInputType==Enum.UserInputType.MouseButton1
or ap.UserInputType==Enum.UserInputType.Touch
then
if aa.CurrentInput and aa.CurrentInput~=ao then
return
end

aa.CurrentInput=ao


end
end)
end)
an.InputEnded:Connect(function(ap,aq)
if ap.UserInputType==Enum.UserInputType.MouseButton1 or ap.UserInputType==Enum.UserInputType.Touch then
if aa.CurrentInput and aa.CurrentInput~=ao then
return
end

aa.CurrentInput=nil
end
end)

local ap=ak.LocalPlayer or nil

local aq=ai:JSONDecode(a.load'l')
if aq then
aa.Version=aq.version
end

local ar=a.load'p'

local as=aa.Creator

local at=as.New




local au=a.load't'

local av=protectgui or(syn and syn.protect_gui)or function()end

local aw=gethui and gethui()or(al or ap:WaitForChild"PlayerGui")

local ax=at("UIScale",{
Scale=aa.UIScale,
})

aa.UIScaleObj=ax

aa.ScreenGui=at("ScreenGui",{
Name="WindUI",
Parent=aw,
IgnoreGuiInset=true,
ScreenInsets="None",
DisplayOrder=-99999,
},{

at("Folder",{
Name="Window",
}),






at("Folder",{
Name="KeySystem",
}),
at("Folder",{
Name="Popups",
}),
at("Folder",{
Name="ToolTips",
}),
})

aa.NotificationGui=at("ScreenGui",{
Name="WindUI/Notifications",
Parent=aw,
IgnoreGuiInset=true,
})
aa.DropdownGui=at("ScreenGui",{
Name="WindUI/Dropdowns",
Parent=aw,
IgnoreGuiInset=true,
})
aa.TooltipGui=at("ScreenGui",{
Name="WindUI/Tooltips",
Parent=aw,
IgnoreGuiInset=true,
})
av(aa.ScreenGui)
av(aa.NotificationGui)
av(aa.DropdownGui)
av(aa.TooltipGui)

as.Init(aa)

function aa.SetParent(ay,az)
if aa.ScreenGui then
aa.ScreenGui.Parent=az
end
if aa.NotificationGui then
aa.NotificationGui.Parent=az
end
if aa.DropdownGui then
aa.DropdownGui.Parent=az
end
if aa.TooltipGui then
aa.TooltipGui.Parent=az
end
end
math.clamp(aa.TransparencyValue,0,1)

local ay=aa.NotificationModule.Init(aa.NotificationGui)

function aa.Notify(az,aA)
aA.Holder=ay.Frame
aA.Window=aa.Window

return aa.NotificationModule.New(aA)
end

function aa.SetNotificationLower(az,aA)
ay.SetLower(aA)
end

function aa.SetFont(az,aA)
as.UpdateFont(aA)
end

function aa.OnThemeChange(az,aA)
aa.OnThemeChangeFunction=aA
end

function aa.AddTheme(az,aA)
aa.Themes[aA.Name]=aA
return aA
end

function aa.SetTheme(az,aA)
if aa.Themes[aA]then
aa.Theme=aa.Themes[aA]
as.SetTheme(aa.Themes[aA])

if aa.OnThemeChangeFunction then
aa.OnThemeChangeFunction(aA)
end

return aa.Themes[aA]
end
return nil
end

function aa.GetThemes(az)
return aa.Themes
end
function aa.GetCurrentTheme(az)
return aa.Theme.Name
end
function aa.GetTransparency(az)
return aa.Transparent or false
end
function aa.GetWindowSize(az)
return aa.Window.UIElements.Main.Size
end
function aa.Localization(az,aA)
return aa.LocalizationModule:New(aA,as)
end

function aa.SetLanguage(az,aA)
if as.Localization then
return as.SetLanguage(aA)
end
return false
end

function aa.ToggleAcrylic(az,aA)
if aa.Window and aa.Window.AcrylicPaint and aa.Window.AcrylicPaint.Model then
aa.Window.Acrylic=aA
aa.Window.AcrylicPaint.Model.Transparency=aA and 0.98 or 1
if aA then
au.Enable()
else
au.Disable()
end
end
end

function aa.Gradient(az,aA,aB)
local b={}
local d={}

for f,g in next,aA do
local h=tonumber(f)
if h then
h=math.clamp(h/100,0,1)

local i=g.Color
if typeof(i)=="string"and string.sub(i,1,1)=="#"then
i=Color3.fromHex(i)
end

local l=g.Transparency or 0

table.insert(b,ColorSequenceKeypoint.new(h,i))
table.insert(d,NumberSequenceKeypoint.new(h,l))
end
end

table.sort(b,function(f,g)
return f.Time<g.Time
end)
table.sort(d,function(f,g)
return f.Time<g.Time
end)

if#b<2 then
table.insert(b,ColorSequenceKeypoint.new(1,b[1].Value))
table.insert(d,NumberSequenceKeypoint.new(1,d[1].Value))
end

local f={
Color=ColorSequence.new(b),
Transparency=NumberSequence.new(d),
}

if aB then
for g,h in pairs(aB)do
f[g]=h
end
end

return f
end

function aa.Popup(az,aA)
aA.WindUI=aa
return a.load'u'.new(aA,aa.ScreenGui.Popups)
end

aa.Themes=a.load'v'(aa,as)

as.Themes=aa.Themes

aa:SetTheme"Dark"
aa:SetLanguage(as.Language)

function aa.CreateWindow(az,aA)
local aB=a.load'ae'

if not am:IsStudio()and writefile then
if not isfolder"WindUI"then
makefolder"WindUI"
end
if aA.Folder then
makefolder(aA.Folder)
else
makefolder(aA.Title)
end
end

aA.WindUI=aa
aA.Window=aa.Window
aA.Parent=aa.ScreenGui.Window

if aa.Window then
warn"You cannot create more than one window"
return
end

local b=true

local d=aa.Themes[aA.Theme or"Dark"]


as.SetTheme(d)

local f=gethwid or function()
return ak.LocalPlayer.UserId
end

local g=f()

if aA.KeySystem then
b=false

local function loadKeysystem()
ar.new(aA,g,function(h)
b=h
end)
end

local h=(aA.Folder or"Temp").."/"..g..".key"

if aA.KeySystem.KeyValidator then
if aA.KeySystem.SaveKey and isfile(h)then
local i=readfile(h)
local l=aA.KeySystem.KeyValidator(i)

if l then
b=true
else
loadKeysystem()
end
else
loadKeysystem()
end
elseif not aA.KeySystem.API then
if aA.KeySystem.SaveKey and isfile(h)then
local i=readfile(h)
local l=(type(aA.KeySystem.Key)=="table")and table.find(aA.KeySystem.Key,i)
or tostring(aA.KeySystem.Key)==tostring(i)

if l then
b=true
else
loadKeysystem()
end
else
loadKeysystem()
end
else
if isfile(h)then
local i=readfile(h)
local l=false

for m,p in next,aA.KeySystem.API do
local r=aa.Services[p.Type]
if r then
local u={}
for v,x in next,r.Args do
table.insert(u,p[x])
end

local v=r.New(table.unpack(u))
local x=v.Verify(i)
if x then
l=true
break
end
end
end

b=l
if not l then
loadKeysystem()
end
else
loadKeysystem()
end
end

repeat
task.wait()
until b
end

local h=aB(aA)

aa.Transparent=aA.Transparent
aa.Window=h

if aA.Acrylic then
au.init()
end













return h
end

return aa
]==========]

-- END BUNDLED WINDUI SOURCE
    end)()
    local make=(function()
-- BEGIN BUNDLED WINDUI
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
    dropdown("TeleportDestination","Main","Teleport destination",function()
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
    end,function(label,map)destination=map[label]end)
    button("Teleport","Main","Teleport",function()if destination then invoke("TeleportToDestination",destination)end end)
    button("RefreshDestinations","Main","Refresh teleport destinations",function()invoke("RefreshTeleportDestinations");nextChoices=0 end)
    api.Controls.SafeModeSection=api.Tabs.Main:Section({Title="Safe Mode",TextSize=17})
    stateToggle("SafeMode","Main","Safe Mode","SetSafeMode","Find a protected server; only whitelisted players may stay.")
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
        false,"Account Progression protects the current floor automatically.")
    input("SafeWhitelist","Main","Whitelist usernames / user IDs",s.SafeWhitelistText,function(text)
        if text~=s.SafeWhitelistText then invoke("SetSafeWhitelist",text)end
    end,"Separate entries with commas or spaces. Auto Trade uses this whitelist too.")
    paragraph("SafeModeStatus","Main","Safe Mode status",function()return s.SafeModeStatus end)
    api.Controls.MultiSpotSection=api.Tabs.Main:Section({Title="Multi Spot",TextSize=17})
    stateToggle("MultiSpot","Main","Multi Spot","SetMultiSpot")
    dropdown("MultiSpotAreas","Main","Boss / mini-boss arenas",function()
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
    end,true,"Current floor only. Clear every enemy before rotating.")
    paragraph("MultiSpotStatus","Main","Arena rotation",function()return s.MultiSpotStatus end)
    api.Controls.FriendJoinerSection=api.Tabs.Main:Section({Title="Friend Joiner",TextSize=17})
    input("JoinFriendUsername","Main","Friend username",s.JoinFriendUsername,function(text)
        if text~=s.JoinFriendUsername then invoke("SetJoinFriendUsername",text)end
    end)
    stateToggle("AutoJoinFriend","Main","Auto Join Friend","SetAutoJoinFriend")
    paragraph("AutoJoinFriendStatus","Main","Friend join status",function()return s.AutoJoinFriendStatus end)
    local restart=guard(function()invoke("RestartScript")end)
    api.Controls.RestartScript=window:CreateTopbarButton("Restart script","rotate-cw",restart,996)

    stateToggle("Enabled","Combat","Kill Aura","SetEnabled")
    stateToggle("AutoFarm","Combat","Auto Farm","SetAutoFarm")
    stateToggle("AutoEquipBestSword","Combat","Auto Equip Best Weapon","SetAutoEquipBestSword")
    stateToggle("AtheonDodge","Combat","Atheon Dodge","SetAtheonDodge")
    stateToggle("AutoSwing","Combat","Swing animation","SetAutoSwing")
    stateToggle("AutoDodge","Challenge Floors","Auto Dodge","SetAutoDodge")
    stateToggle("TransparentMap","Challenge Floors","Transparent map","SetTransparentMap")
    stateToggle("SkillAura","Auto Skill","Skill Aura","SetSkillAura")
    dropdown("SelectedSkill","Auto Skill","Offensive skill",function()
        return {Options=s.SkillChoices or {},Value=s.SelectedSkill}
    end,function(name)if name and name~=s.SelectedSkill then invoke("SetSelectedSkill",name)end end)
    stateToggle("MiscSkillEnabled","Auto Skill","Misc Skill","SetMiscSkillEnabled")
    dropdown("SelectedMiscSkill","Auto Skill","Support skill",function()
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
    dropdown("PerformanceBoosters","Utility","Performance boosters",function()
        local value={};for _,name in ipairs(boostNames)do if s.PerformanceBoosters[name]then value[#value+1]=name end end
        return {Options=boostNames,Value=value}
    end,applyBoost,true)
    local rarities={"Common","Uncommon","Rare"}
    dropdown("AutoDismantle","Utility","Auto Dismantle rarities",function()
        local value={};for _,name in ipairs(rarities)do if s.AutoDismantle[name]then value[#value+1]=name end end
        return {Options=rarities,Value=value}
    end,function(values)
        local picked={};for _,name in ipairs(values or {})do picked[name]=true end
        for _,name in ipairs(rarities)do if (s.AutoDismantle[name]==true)~=(picked[name]==true)then invoke("SetAutoDismantle",name,picked[name]==true)end end
    end,true,"Equipped, locked and favorited items are preserved.")
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

-- END BUNDLED WINDUI
    end)()
    local parent=gui.Parent
    local legacyVisibility=state.SetUIVisible
    local before={};for _,child in ipairs(parent:GetChildren())do before[child]=true end
    local library
    local ownedNames={WindUI=true,["WindUI/Notifications"]=true,["WindUI/Dropdowns"]=true,["WindUI/Tooltips"]=true}
    local function roots(fn)
        if library then
            for _,key in ipairs({"ScreenGui","NotificationGui","DropdownGui","TooltipGui"})do
                local root=library[key]
                if root then pcall(fn,root)end
            end
        end
    end
    local ok,result=pcall(function()
        local run=assert(loadstring(librarySource,"WindUI 1.6.66"))
        local base=getfenv()
        local nativeMake=makefolder
        setfenv(run,setmetatable({gethui=function()return parent end,makefolder=function(path)
            if type(isfolder)=="function"and isfolder(path)then return end
            assert(type(nativeMake)=="function","Executor filesystem is unavailable")
            return nativeMake(path)
        end},{__index=base}))
        library=run()
        roots(function(root)root.DisplayOrder=gui.DisplayOrder+1 end)
        local camera=workspace.CurrentCamera
        local size=camera and camera.ViewportSize or Vector2.new(1280,720)
        state.WindUIPosition=preference("WindUIPosition",nil)
        local controller=make({State=state,WindUI=library,PlaceId=game.PlaceId,
            Size=UDim2.fromOffset(math.min(640,math.max(320,size.X-24)),math.min(520,math.max(280,size.Y-70))),
            MinSize=Vector2.new(300,240),SideBarWidth=size.X<500 and 110 or 155,
            Visibility=function(visible)
                panel.Visible=false
                if state.Running then showUI.Visible=true;showUI.Text=visible and "Hide UI"or "Show UI" else showUI.Visible=false end
                roots(function(root)root.Enabled=visible end)
            end})
        state.WindUI=controller
        state.UI.WindWindow=controller.Window;state.UI.WindControls=controller.Controls
        state.SetUIVisible=controller.SetVisible
        local frame=controller.Window.UIElements and controller.Window.UIElements.Main
        local saved=state.WindUIPosition
        if frame then
            if type(saved)=="table"and #saved==4 then
                local valid=true
                for _,value in ipairs(saved)do if type(value)~="number"or value~=value or math.abs(value)>100000 then valid=false end end
                if valid then
                    local x=saved[1]*size.X+saved[2]
                    local y=saved[3]*size.Y+saved[4]
                    frame.Position=UDim2.fromOffset(math.clamp(x,math.min(150,size.X/2),math.max(size.X-150,size.X/2)),
                        math.clamp(y,math.min(100,size.Y/2),math.max(size.Y-100,size.Y/2)))
                end
            end
            bind(frame:GetPropertyChangedSignal("Position"),function()
                if not state.Running then return end
                local p=frame.Position
                state.WindUIPosition={p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset};requestSave()
            end)
        end
        controller.SetVisible(not state.UIHidden)
        task.spawn(function()
            while state.Running do
                local updated,reason=pcall(controller.Update,os.clock())
                if not updated then state.WindUIError=tostring(reason)end
                task.wait(.25)
            end
        end)
    end)
    if not ok then
        state.WindUIError=tostring(result)
        if state.WindUI then pcall(state.WindUI.Destroy);state.WindUI=nil end
        if library and library.Window then pcall(function()library.Window:Destroy()end)end
        state.SetUIVisible=legacyVisibility
        roots(function(root)root:Destroy()end)
        for _,child in ipairs(parent:GetChildren())do
            if not before[child]and child:IsA("ScreenGui")and ownedNames[child.Name]then child:Destroy()end
        end
        panel.Visible=true;showUI.Visible=false;state.UIHidden=false
        warn("[SB2 WindUI] Using the compatibility window: "..state.WindUIError)
    end
end
