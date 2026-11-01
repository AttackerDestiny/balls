local SB2_SOURCE=[============[
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
local BUILD="2026-11-01.friend-status-v1.8.0"
local VERSION="1.8.0"
local storageBootstrap=(function()
-- BEGIN BUNDLED STORAGE BOOTSTRAP
-- Executor paths are relative to its workspace; never add a second "workspace".
-- Existing account settings/tickets are preserved. The runnable entry passes its
-- own embedded body so this can persist a complete, dependency-free loader.
return function(ctx)
    local api={Ready=false,Generation=0,Created={}}
    local folder="SB2Codex"
    local sourcePath=folder.."/kill-aura.luau"
    local saved=false
    local fullSource=type(ctx.Source)=="string"and ctx.Prefix..ctx.Source..ctx.Suffix or nil
    local function ensureFile(path,value)
        if not ctx.IsFile(path)then
            ctx.Write(path,value);api.Generation+=1;api.Created[path]=true
        end
    end
    function api.Ensure()
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
            if not saved or not ctx.IsFile(sourcePath)then
                if not ctx.IsFile(sourcePath)or ctx.Read(sourcePath)~=fullSource then
                    ctx.Write(sourcePath,fullSource);api.Generation+=1;api.Created[sourcePath]=true
                end
                saved=true
            end
            ensureFile(folder.."/settings_"..ctx.UserId..".json",ctx.Encode({Version=1}))
            ensureFile(folder.."/solo-search_"..ctx.UserId..".json",ctx.Encode({Version=1,Active=false,UserId=ctx.UserId,PlaceId=ctx.PlaceId}))
            ensureFile(folder.."/destinations_"..ctx.PlaceId..".json",ctx.Encode({Version=1,PlaceId=ctx.PlaceId,Areas={}}))
        end)
        api.Ready=ok;api.Error=not ok and tostring(message)or nil
        return ok,api.Error
    end
    api.Ensure()
    return api
end

-- END BUNDLED STORAGE BOOTSTRAP
end)()({Source=embeddedSource,UserId=player.UserId,PlaceId=game.PlaceId,
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
    local keys={"Enabled","AutoFarm","AutoSwing","SkillAura","SelectedSkill","SkillPerWeapon","SkillPerWeaponVersion",
        "MiscSkillEnabled","SelectedMiscSkill","AutoDodge","AtheonDodge","TransparentMap","PerformanceBoosters",
        "AutoJoinFriend","JoinFriendUsername","SafeMode","SafeWhitelistText","SafeWhitelistIds","MultiSpot","MultiSpotSelected",
        "AccountProgression","PanelPosition","HealthHUDPosition"}
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
    local last=ctx.Encode(api.Values)
    function api.Save(value)
        local shared=select(value);local encoded=ctx.Encode(shared)
        if encoded~=last or not ctx.IsFile(path)then ctx.Write(path,encoded);last=encoded end
        api.Values=shared
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
    AutoFarm=preference("AutoFarm",false)==true,
    FarmRange=10000,
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
    AttackInterval = 0.04, ThreatCycle = 0.12, MaxRequestsPerSecond = 48, EffectiveInterval = 0.04,
    Threat = math.clamp(math.floor(restore.Threat), 1, 3), BurstsSent = 0, LastBurstSize = 0,
    AttackBurstInterval = 0.30, AttackBurstActive = false, AttackBurstHistory = {},
    BurstProgress = 0, LastPulseAt = nil, MinimumPulseGap = nil,
    AutoSwing = restore.AutoSwing, SwordSwinging = false, SwingStarts = 0,
    LagPauseUntil = 0, PingMs = nil, Backoff = 1,
    AutoFarm = false, FarmRange = math.clamp(restore.FarmRange, 20, 10000), Recovering = false,
    TeleportOffset = -6, AutoOffset = true, OffsetStatus = "Waiting for a target",
    FarmAbove=false,OffsetMode="Below",
    OffsetProfiles = {}, UnsafeOffsetProfiles = {}, ProtectionStatus = "Retreat on health loss",
    ProtectionRetreats = 0, TeleportInterval = 0.18, TeleportsSent = 0,
    AverageFrameTime = 1 / 60, AverageLoopCost = 0, TargetScans = 0,
    Moving = false, FollowTarget = nil, MovementStatus = "Auto farm is off",
    ConfigPath = configPath, ConfigLoadError = configLoadError, ConfigLoadedFromDisk = configData.Version == 1,
    SavedScriptPath = configFolder .. "/kill-aura.luau",StorageBootstrap=storageBootstrap,
    MiscSkillEnabled=false, SelectedMiscSkill=type(restore.SelectedMiscSkill)=="string" and restore.SelectedMiscSkill or "Cursed Enhancement",
    MiscSkillRequests=0, MiscSkillCasts=0, MiscCastRunning=false, MiscReserveStamina=false,
    SkillPerWeapon=preference("SkillPerWeapon",{}), SkillPerWeaponVersion=preference("SkillPerWeaponVersion",0), SkillWeaponVersion=0,
    SkillAura = false, SelectedSkill = restore.Skill, SkillCasts = 0, SkillStatus = "Skill aura is off",
    AttackingTarget = nil, HealthUpdates = 0,
    HideSkillAnimation = true, SuppressSkillMotion = true, HiddenSkillAnimations = 0,
    SkillBurstHits = 3, SkillBurstInterval = 0.24, SkillHitRequests = 0, LastSkillBurstSize = 0, SkillBurstHistory = {},
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
return function(state)
    local nextReserveHit,reserving=0,false
    local api={}
    local active=setmetatable({}, {__mode="k"})
    local nextHit=setmetatable({}, {__mode="k"})
    local observers={}
    local tokens,refill=6,os.clock()
    local ctx
    function api.Bind(value) ctx=value end
    function api.SelectThreat(data,distance,range,hasCredit)
        if state.ReserveGunStamina then state.CurrentThreat=1; state.ThreatReason="Recovering gun stamina"; return 1,state.ThreatReason end
        local maximum=math.clamp(math.floor(state.Threat),1,3)
        local cap,reason=maximum,"Stable target"
        if maximum==3 then
            if not hasCredit and not data.RegisteredDamage then cap=1; reason="Registering target"
            elseif (data.AttackBackoff or 1)>1 or (data.AttackMisses or 0)>0 then cap=1; reason="Checking missed hits"
            elseif (state.PingMs or 0)>450 or (state.AverageFrameTime or 0)>1/35 then cap=1; reason="Network/frame pressure"
            elseif (state.PingMs or 0)>380 then cap=2; reason="High latency"
            end
            if distance>range-1.5 then cap=1; reason="Edge of reach"
            elseif distance>range-4 then cap=math.min(cap,2); reason="Near reach boundary" end
        end
        if data.HitLives then cap=math.min(cap,math.max(1,math.floor(data.HitLives.Value))) end
        if data.NormalDamagePerHit and data.NormalDamagePerHit>0 then
            cap=math.min(cap,math.max(1,math.ceil(data.Health.Value/data.NormalDamagePerHit)))
        end
        local desired=cap
        if maximum==3 and cap>1 then
            local roll=(ctx.RandomInteger or math.random)(1,100)
            desired=math.min(cap,roll<=15 and 1 or roll<=45 and 2 or 3)
            reason=reason.." · varied burst"
        end
        state.CurrentThreat, state.ThreatReason=desired,reason
        return desired,reason
    end
    local function snapshot(record,reason)
        if record.Finished then return end
        record.Finished=true
        record.Status=reason
        record.After=record.Health.Value
        record.HealthDamage=math.max(0,record.Before-record.After)
        local credited=ctx.Contribution and ctx.Contribution(record.Health,record.Counter)
        record.Damage=credited~=nil and math.max(0,credited-(record.BeforeContribution or 0)) or record.HealthDamage
        record.FinishedAt=os.clock()
        if record.Connection then record.Connection:Disconnect(); observers[record.Connection]=nil end
        state.LastBurstSize=record.Requested
        if record.Requested==record.Desired then state.BurstsSent+=1 end
        state.AttackBurstHistory[#state.AttackBurstHistory+1]=record
        if #state.AttackBurstHistory>8 then table.remove(state.AttackBurstHistory,1) end
    end
    function api.Cancel(reason)
        for mob,record in pairs(active) do snapshot(record,reason or "Paused"); active[mob]=nil end
        state.AttackBurstActive=false
    end
    function api.Destroy()
        api.Cancel("Script closed")
        for connection in pairs(observers) do connection:Disconnect() end
        observers={}
    end
    function api.Update(now,candidates,root,folder)
        local reserve=state.ReserveGunStamina==true
        if reserve~=reserving then
            api.Cancel("Switching gun stamina pacing"); reserving=reserve; nextReserveHit=0
        end
        if reserve and now<nextReserveHit then return end
        local batch=math.clamp(state.FrameRequestCap or 4,1,4)
        if reserve then batch=1 end
        local gap=math.max(0.24,state.AttackInterval or 0,0.24+math.min(0.04,(state.PingMs or 0)/10000))
        state.EffectiveInterval=gap
        tokens=math.min(batch,tokens+math.max(0,now-refill)*(state.MaxRequestsPerSecond or 48))
        refill=now
        local activeCount=0
        for mob,record in pairs(active) do
            if mob.Parent~=folder or record.Health.Value<=0 then snapshot(record,"Target defeated or removed"); active[mob]=nil
            else
                if now<(record.NextRangeCheck or 0) then activeCount+=1; continue end
                record.NextRangeCheck=now+.1
                local data=ctx.GetData(mob)
                local range=ctx.Radius(mob)
                local delta=data and (ctx.Delta and ctx.Delta(data,root) or data.Root.Position-root.Position)
                if not delta or delta:Dot(delta)>range*range then
                    record.OutOfReachAt=record.OutOfReachAt or now
                    if now-record.OutOfReachAt>0.4 then snapshot(record,"Target moved out of reach"); active[mob]=nil
                    else activeCount+=1 end
                else activeCount+=1 end
            end
        end
        local sent,visual=0,false
        for _,mob in ipairs(candidates) do
            if sent>=batch or tokens<1 then break end
            if now<(nextHit[mob] or 0) then continue end
            if not active[mob] and ((state.SkillWantsWindow and not reserve) or activeCount>=8) then continue end
            local data=mob.Parent==folder and ctx.GetData(mob)
            local record=active[mob]
            if data and data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0) and not data.Entity:FindFirstChild("Immortal") then
                local delta=ctx.Delta and ctx.Delta(data,root) or data.Root.Position-root.Position
                local range=ctx.Radius(mob)
                if delta:Dot(delta)<=range*range then
                    if now>=(nextHit[mob] or 0) and tokens>=1 and sent<batch
                        and (record or ((not state.SkillWantsWindow or reserve) and activeCount<8)) then
                        if not record then
                            record={Target=mob,TargetName=mob.Name,Requested=0,Health=data.Health,Before=data.Health.Value,HealthDrops=0,Values={},Status="Sending burst"}
                            if ctx.Contribution then record.BeforeContribution,record.Counter=ctx.Contribution(data.Health) end
                            record.Desired,record.ThreatReason=api.SelectThreat(data,delta.Magnitude,range,record.BeforeContribution~=nil)
                            local before=data.Health.Value
                            record.Connection=data.Health:GetPropertyChangedSignal("Value"):Connect(function()
                                local hp=data.Health.Value
                                if hp<before then record.HealthDrops+=1; if #record.Values<8 then record.Values[#record.Values+1]=hp end end
                                before=hp
                            end)
                            observers[record.Connection]=true
                            active[mob]=record; activeCount+=1
                        end
                        record.OutOfReachAt=nil
                        ctx.Damage(mob)
                        nextHit[mob]=now+gap*math.max(1,data.AttackBackoff or 1)
                        record.Requested+=1
                        state.LastAttackBurst=record
                        ctx.Sent(mob,data,now)
                        if reserve then nextReserveHit=now+.5 end
                        if not visual then ctx.Visual(); visual=true end
                        sent+=1; tokens-=1
                        if record.Requested>=record.Desired then
                            active[mob]=nil; activeCount-=1
                            local complete=record
                            task.delay(math.clamp((state.PingMs or 150)/1000+0.05,0.2,0.6),function() snapshot(complete,"Burst complete") end)
                        end
                    end
                elseif record then
                    record.OutOfReachAt=record.OutOfReachAt or now
                    if now-record.OutOfReachAt>0.4 then snapshot(record,"Target moved out of reach"); active[mob]=nil; activeCount-=1 end
                end
            elseif record then snapshot(record,"Target unavailable"); active[mob]=nil; activeCount-=1 end
        end
        state.AttackBurstActive=activeCount>0
        return #candidates>0 and string.format("Active · %d targets · %d requests",#candidates,state.HitsSent) or "Active · waiting for mobs"
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
    record.Desired=rounds
    record.Targets={}
    record.TotalRequests=0
    local function captureTargets(first)
        local current={}
        local included={}
        for _,mob in ipairs(ctx.Targets(first)) do
            local data=ctx.Valid(mob)
            local item=seen[mob]
            if data and not item and #record.Targets<(ctx.RefreshTargets and 16 or 8) then
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
                if #current>=8 then break end
            end
        end
        record.TargetCount=#record.Targets
        return current
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
            record.FinishedAt=os.clock()
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
        local cached=cache[mob]
        if cached and os.clock()<cached.Until then return cached.Rank end
        local entity=mob:FindFirstChild("Entity")
        local difficulty=entity and entity:FindFirstChild("Difficulty")
        local rank=clean(mob:GetAttribute("Rank") or (entity and entity:GetAttribute("Rank")) or (difficulty and difficulty.Value))
        local boss,mini=false,false
        for _,instance in ipairs(entity and {mob,entity} or {mob}) do
            for _,tag in ipairs(instance:GetTags()) do
                local key=clean(tag)
                if string.find(key,"mini",1,true) and string.find(key,"boss",1,true) then mini=true
                elseif key=="boss" or key=="bossbar" or key=="mainboss" or key=="floorboss" then boss=true end
            end
        end
        local priority=3
        if mini or string.find(rank,"mini",1,true) or clean(mob.Name)=="frogazoid" then priority=2
        elseif boss or string.find(rank,"boss",1,true) then priority=1 end
        cache[mob]={Rank=priority,Until=os.clock()+.2}
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
        if os.clock()>=(cached.MetaAt or 0) then cached.HitLives=cached.Entity:FindFirstChild("HitLives"); cached.Motion=cached.Root:FindFirstChild("BodyVelocity"); cached.MetaAt=os.clock()+.5 end
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

local gui=runtimeOwner.Root
local panel=create("Frame",{Name="Panel",Size=UDim2.fromOffset(300,500),Position=UDim2.new(1,-324,.5,-250),
    BackgroundColor3=Color3.fromRGB(20,22,31),BorderSizePixel=0},gui)
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
bind(showUI.Activated,function()state.SetUIVisible(true)end)
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
    return {
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
        FarmRange = state.FarmRange, AutoOffset = true, OffsetProfiles = state.OffsetProfiles,
        UnsafeOffsetProfiles = state.UnsafeOffsetProfiles, Threat = state.Threat,
        SkillAura = features.SkillAura, SelectedSkill = state.SelectedSkill,SkillPerWeapon=state.SkillPerWeapon,SkillPerWeaponVersion=state.SkillPerWeaponVersion,
        MiscSkillEnabled=features.MiscSkillEnabled==true,SelectedMiscSkill=state.SelectedMiscSkill,
        AutoExplore = state.AutoExplore,
        AutoDodge = features.AutoDodge, AtheonDodge=features.AtheonDodge, TransparentMap = features.TransparentMap,
        PerformanceBoosters=features.PerformanceBoosters,
        PanelPosition = { position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset },
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
        row.Frame=create("Frame",{Name="Target_"..serial,Size=UDim2.fromOffset(280,52),BackgroundColor3=Color3.fromRGB(20,23,34),BackgroundTransparency=.12,BorderSizePixel=0},root)
        row.Frame:SetAttribute("TargetName",mob.Name)
        corner(row.Frame,7)
        create("UIStroke",{Color=Color3.fromRGB(72,78,104),Thickness=1,Transparency=.25},row.Frame)
        row.Name=create("TextLabel",{Name="Name",Text=mob.Name,BackgroundTransparency=1,Position=UDim2.fromOffset(10,4),Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.fromRGB(226,229,243),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
        row.Track=create("Frame",{Name="Track",BackgroundColor3=Color3.fromRGB(49,52,71),BorderSizePixel=0},row.Frame)
        corner(row.Track,3)
        row.Fill=create("Frame",{Name="Fill",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(87,202,143),BorderSizePixel=0},row.Track)
        corner(row.Fill,3)
        row.Numbers=create("TextLabel",{Name="Values",BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(169,177,199),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
        local maximum=data.Entity:FindFirstChild("MaxHealth")
        local constrained=data.Health:IsA("IntConstrainedValue") or data.Health:IsA("DoubleConstrainedValue")
        local initial=true
        local function render()
            if disposed or not root.Parent or not state.Running or rows[mob]~=row then return end
            local hp=math.max(0,row.Health.Value)
            row.ObservedMax=math.max(row.ObservedMax,hp)
            local maxHP=math.max(1,constrained and row.Health.MaxValue or maximum and maximum.Value or row.ObservedMax)
            local fraction=math.clamp(hp/maxHP,0,1)
            local color=Color3.fromRGB(230*(1-fraction)+70*fraction,80*(1-fraction)+200*fraction,100)
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
        state.SetEnabled(true)
    end
    if state.FarmNoclip then state.FarmNoclip.Update()end
    requestSave()
end
function state.SetFarmRange(range)
    if type(range) ~= "number" or range ~= range then range = state.FarmRange end
    state.FarmRange = math.clamp(math.floor(range), 20, 10000)
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
    if state.ModeratorBlocking then return nil end
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
        local dynamic=not ctx.DynamicHazards or ctx.DynamicHazards()
        for instance,record in pairs(managed) do
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
        end
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
        or state.TravelBusy or state.MultiSpotOwnsTravel or state.Dodging or state.Recovering then return false end
    local spot=state.MultiSpotController and state.MultiSpotController.Current
    if not spot or state.ReadAutomationEncounter(spot)~=0 then return false end
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
        option("Save current spot as mini-boss area", 101, function()
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then rememberDestination("saved:mini", "Saved mini-boss area", "Mini boss", root.Position); saveDestinations(); refreshTravelChoices(); setTravelStatus("Mini-boss area saved for " .. floorName) end
        end)
    end
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
        nextAcquisition=now+0.2
        local preferred=targetRoot and state.FollowTarget or nil
        local best=preferred
        state.TargetScans+=1
        for mob in pairs(trackedMobs) do
            local mobRoot=validMob(mob,mobs)
            if mobRoot and (mobRoot.Position-root.Position).Magnitude<=state.FarmRange then
                if not best or targetPriority.Less(mob,best,root.Position,preferred) then best=mob end
            end
        end
        state.FollowTarget=best
        targetRoot=best and validMob(best,mobs)
        state.TargetPriority=best and targetPriority.Rank(best) or nil
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
            movementStatus("No target in "..state.FarmRange.." studs · idle -20")
        else waveDodge.Idle(); movementStatus("Waiting below the map · 20 studs") end
        return
    end
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
-- Adapted from the supplied source's active-skill window: activate once,
-- then send the selected skill's existing damage bursts without spawning VFX.
return function(ctx)
    local api={}
    local windows={['Sweeping Strike']=1.4,['Downward Smash']=1,['Leaping Slash']=1.8,['Piercing Dash']=1,['Beam Rush']=2.8,
        ['Whirlwind Spin']=1,['Reaper Frenzy']=3.5,['Infinity Slash']=1,['Summon Pistol']=.5,['Meteor Shot']=1,
        ['Everfrost Strike']=1.5,['Cursed Three Fold Slash']=3.3,['Water Blast']=1.2,['Spearitual Strike']=1,
        ['Summon Rifle']=3,['Summon Minigun']=3}
    local retry={}
    local gunProfiles={['Summon Pistol']={FirstHitDelay=.3,Rounds=1},
        ['Summon Rifle']={FirstHitDelay=0,Rounds=12,RepeatWindow=true,RefreshTargets=true,MinimumInterval=.26}}
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
            FirstHitAt=started+(profile and profile.FirstHitDelay or 0),Rounds=profile and profile.Rounds or 3,
            HoldWindow=profile~=nil,RepeatWindow=profile and profile.RepeatWindow,RefreshTargets=profile and profile.RefreshTargets,
            MinimumInterval=profile and profile.MinimumInterval}
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
            if before-stamina.Value>=math.max(1,cost*.5) then
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
        end,
    })
end
local skillThread,nextSkillCheck=nil,0
function state.WakeSkillAura()nextSkillCheck=0 end
local skillCastSerial=0
function state.CancelSkillAura(reason)
    state.ReserveGunStamina=false
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
    state.CombatReadyAt=os.clock()+.24
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
    if not Skills.HasStamina(definition.Cost.Value) then
        state.ReserveGunStamina=true; state.SkillWantsWindow=true
        state.SkillStatus="Recovering stamina for "..name
        return
    end
    state.SkillWantsWindow=true
    if state.AttackBurstActive then finishAttackBurst("Handing off to ready skill") end
    state.SkillPreparing=true
    local sharedGap=.24+math.min(.04,(state.PingMs or 0)/10000)
    local windup=gunProfile and gunProfile.FirstHitDelay or 0
    if now-(state.LastPulseAt or 0)<math.max(0,sharedGap-windup) then return end
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
    end
    skillThread=task.defer(function()
        local burst={Skill=name,Target=target.Name,Desired=3,Requested=0,HealthDrops=0,Before=0,Direct=true,Status="Activating equipped weapon skill"}
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
            burst.Spacing=math.max(state.SkillBurstInterval,.24+math.min(.04,(state.PingMs or 0)/10000),lease.MinimumInterval or 0)
            burst.ActivationAt=lease.Started; burst.FirstHitAt=lease.FirstHitAt; burst.AimDirection=lease.Direction
            cast.Multi=createSkillBurst({State=state,Record=burst,Spacing=burst.Spacing,Contribution=state.ReadOwnDamage,
                Rounds=lease.Rounds,FirstHitAt=lease.FirstHitAt,RepeatWindow=lease.RepeatWindow,
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
                    for mob in pairs(trackedMobs) do list[#list+1]=mob end
                    table.sort(list,function(a,b) return targetPriority.Less(a,b,root.Position,target) end)
                    return list
                end,
                Distance=function(_,entry) return (entry.Root.Position-root.Position).Magnitude end,
                RangeDistance=function(_,entry) return attackDeltaFor(entry,root).Magnitude end,
                CanRun=function() return current() and os.clock()<lease.ExpiresAt end,
                Send=function(mob,entry)
                    if not current() then return end
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
                if state.SkillActivation.Window(name)<.65 and current() then startDamage(window) end
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
            local gap=.24+math.min(.04,(state.PingMs or 0)/10000)
            state.CombatReadyAt=math.max(state.CombatReadyAt or 0,(burst.LastRequestAt or burst.FinishedAt or os.clock())+gap)
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
        state.SetUIVisible(not panel.Visible)
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
    if not state.Enabled then stopSword(); return "Paused" end
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

local nextPresentationUpdate=0
local function runFrame()
        if state.StopEverything then return end
        if state.ModeratorBlocking then
            if state.PanicToSpawn then state.PanicToSpawn()end
            return
        end
        if state.AutoJoinFriendHolding or state.SafeModePanic then
            if state.PanicToSpawn then state.PanicToSpawn() end
            return
        end
        local started = os.clock()
        if state.ArenaFloat then state.ArenaFloat.Update(started) end
        state.PerformanceBudget.Update(started)
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



function state.PanicToSpawn()
    local first=not state.SafeModePanic
    state.SafeModePanic=true
    if first then
        state.SafePanicStartedAt=os.clock()
        state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false
        finishAttackBurst("Safe Mode panic");stopSword(true)
        if state.CancelSkillAura then state.CancelSkillAura("Safe Mode panic") end
        if state.CancelMiscSkill then state.CancelMiscSkill() end
        if state.MultiSpotController then state.MultiSpotController.Reset() end
        stopMovement("Safe Mode · holding at spawn",true)
        state.FollowTarget=nil;state.TravelFocus=nil
    end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return false end
    local pad=state.SafePanicSpawnPart
    if not pad or not pad.Parent then
        local reference=destinations.spawn and destinations.spawn.Position or root.Position
        local bestDistance
        for _,candidate in ipairs(workspace:QueryDescendants("SpawnLocation")) do
            local distance=(candidate.Position-reference).Magnitude
            if not bestDistance or distance<bestDistance then pad,bestDistance=candidate,distance end
        end
        state.SafePanicSpawnPart=pad
    end
    local position
    if pad then position=pad.Position+Vector3.new(0,pad.Size.Y/2+humanoid.HipHeight+root.Size.Y/2+.5,0)
    elseif destinations.spawn then position=destinations.spawn.Position+Vector3.new(0,4,0) end
    if not position then return false end
    if root~=movementRoot then stopMovement(nil,true) end
    ensureMovementController(character,root,humanoid,position)
    if positionAlign then positionAlign.Position=position end
    if first or (root.Position-position).Magnitude>3 then pivotRoot(root,position) end
    state.TravelHold=true;state.TravelHoldPosition=position;state.SafePanicPosition=position
    return true
end
function state.ReleaseSafePanic()
    if not state.SafeModePanic then return end
    state.SafeModePanic=false;state.SafePanicPosition=nil
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
    local ticket, blocked, pendingPlayer, busy
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
    function api.Stop(message,outcome)
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
    end
    function api.Start(resume)
        if api.Active or busy then return false end
        if resume and not valid(resume) then
            ticket = type(resume) == "table" and resume or nil
            api.Stop("Resume expired, changed floor/account, or did not change server")
            return false
        end
        generation = generation + 1
        local token = generation
        api.Active, api.Phase = true, "Preparing"
        api.Outcome="Searching"
        announce("Checking block access and rejoin support...")
        local ok, message = pcall(function()
            if resume and ctx.RestoreSettings then ctx.RestoreSettings(resume.Features) end
            if resume and resume.SourceJob == ctx.JobId then
                ticket = resume
                error("Rejoin returned the same server; search stopped")
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
            if ticket.Visited[ctx.JobId] then error("Matchmaking returned a visited server; search stopped") end
            api.Ticket = ticket
            persist()
            if not live(token) then return end
            settleUntil, soloSince = ctx.Clock() + (ctx.SettleSeconds or 8), nil
            api.Phase = "Waiting"
            announce("Checking this floor's population...")
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
                if ticket.Hops == 0 then ticket.LastBlockedUserId = target.UserId; hop(token); return end
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
    local function targetFloor()return ctx.TargetFloor and ctx.TargetFloor() or state.SafeFloorId end
    function api.Update()
        if not state.SafeMode or not state.Running or state.ModeratorBlocking then return end
        if state.AccountProgression and state.AutomationTeleporting then api.Seeking=true;return end
        if api.Paused then
            local protected=ctx.CurrentFloor()==targetFloor()
            for _,person in ipairs(ctx.Players()) do if not ctx.Allowed(person) then protected=false;break end end
            if protected then api.Paused=false;api.PauseReason=nil
            else
                api.Seeking=true;if ctx.Panic then ctx.Panic() end
                ctx.Status("Holding at spawn · "..tostring(api.PauseReason));return
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
        if not started then api.Pause(search.Status);ctx.Save() end
    end
    function api.Pause(reason)
        api.Paused=true;api.PauseReason=reason;api.Seeking=true
        if ctx.Panic then ctx.Panic() end
        ctx.Status("Holding at spawn · "..tostring(reason))
    end
    function api.Joined(person)
        if state.SafeMode and not ctx.Allowed(person) then
            state.SafePendingUserId=person.UserId
            if ctx.Panic then ctx.Panic() end
        end
    end
    function api.Reset()
        started=false;api.Seeking=false;api.Paused=false;api.PauseReason=nil
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
        [582198062]=7,[548878321]=8,[573267292]=9,[2659143505]=10,[5287433115]=11,[6144637080]=12,[13965775911]=13}
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
            local item={Id=floor.PlaceId,Number=n,Name=floor.Name,Label="F"..n.." · "..floor.Name,Unlocked=ctx.Unlocked(floor)}
            catalog.Floors[#catalog.Floors+1]=item;catalog.FloorById[item.Id]=item
        end
    end
    table.sort(catalog.Floors,function(a,b)return a.Number<b.Number end)
    local extraKinds={['Suspended Unborn']='Arena',['Limor the Devourer']='Arena',['Radioactive Experiment']='Arena',
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
            tostring(s.AutoJoinFriend),tostring(s.AutoJoinFriendStatus),tostring(s.SafeModeStatus),tostring(s.MultiSpotStatus),tostring(count)},"|")
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
    end
    local function refreshFloors()
        for _,child in ipairs(floors:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
        for i,item in ipairs(catalog.Floors) do
            local button=ctx.Button("SafeFloor"..i,(item.Id==s.SafeFloorId and "[x] " or "")..item.Label..(item.Unlocked and "" or " · locked"),i,30,floors)
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
        SettleSeconds=.4,SoloSeconds=.6,BlockSettleSeconds=.15,
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
            state.MultiSpotAnchor=spot.Position;state.MultiSpotEncounter={};state.MultiSpotNextScan=0;state.FollowTarget=nil;state.LastTravelDestination=nil
            state.MultiSpotOwnsTravel=true
            return state.TeleportToDestination(spot.DestinationId,false,true)
        end,
        Encounter=function(spot)return state.ReadAutomationEncounter(spot)end,
        ClearEncounter=function()state.MultiSpotEncounter={};state.MultiSpotNextScan=0 end,
        Release=function()
            if state.ArenaFloat then state.ArenaFloat.Release() end
            if state.MultiSpotOwnsTravel and state.TravelBusy then state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false end
            state.MultiSpotOwnsTravel=false;state.MultiSpotAnchor=nil;state.MultiSpotEncounter=nil;state.MultiSpotNextScan=0
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
            task.wait((api.Active or state.SafeModePanic) and .05 or (state.MultiSpot or state.AccountProgression) and .1 or state.SafeMode and .5 or 1)
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
            ctx.Sleep(.04)
        until ctx.Now()>=deadline
        assert(button and ctx.Ready(button),"Roblox block dialog did not open; no rejoin attempted")
        local firstReady=ctx.Now()
        local stableSince,key=firstReady,ctx.Key(button)
        local nextClick,clicks,confirmedAt=firstReady+.16,0,nil
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
            button,cancel=ctx.Find(target)
            if button and ctx.Ready(button)and clicks<4 then
                local currentKey=ctx.Key(button)
                if currentKey~=key then key=currentKey;stableSince=now end
                if now>=nextClick and now-stableSince>=.08 then
                    ctx.Click(button);clicks+=1;nextClick=ctx.Now()+.3
                end
            end
            ctx.Sleep(.04)
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
    attach({Make=make,MakeSafe=makeSafe,MakeMulti=makeMulti,MakeCatalog=makeCatalog,MakeUI=makeUI,MakeFriend=makeFriend,BlockPoint=blockPoint,MakeBlockConfirm=makeBlockConfirm,
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
    local swordClasses={['1HSword']=true,['2HSword']=true,Rapier=true,Katana=true}
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
        local swords,armor,accessories={},{},{}
        local equipped={};for _,id in pairs(snapshot.Equip)do equipped[id]=true end
        for _,item in ipairs(snapshot.Items)do
            if item.Level<=snapshot.Level and not item.Skin then
                local damage,defense=effective(item,"Damage",snapshot),effective(item,"Defense",snapshot)
                item.Damage,item.Defense=damage,defense
                item.Utility=(tonumber(item.Stats.Critical)or 0)+(tonumber(item.Stats.Lifesteal)or 0)
                    +(tonumber(item.Stats.HealthRegeneration)or 0)+(tonumber(item.Stats.StaminaRegeneration)or 0)
                if item.Type=="Weapon" and swordClasses[item.Class] then item.Score=damage;swords[#swords+1]=item
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
        table.sort(swords,less);table.sort(armor,less);table.sort(accessories,less)
        local operations={}
        local function add(action,item,slot)
            operations[#operations+1]={Action=action,Item=item,Slot=slot}
        end
        local sword=swords[1]
        if sword and snapshot.Equip.Right~=sword.Id then add("EquipWeapon",sword,"Right")end
        if sword and sword.Class=="1HSword" then
            for _,item in ipairs(swords)do
                if item.Id~=sword.Id and item.Class==sword.Class then
                    if snapshot.Equip.Left~=item.Id then add("EquipWeapon",item,"Left")end
                    break
                end
            end
        end
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
    local gear=ctx.MakeGear({Rarity=require(game.ReplicatedStorage.Shared.Library.RarityData),
        Active=function()return not disposed and state.Running and state.AccountProgression and not state.ProgressionComplete and not state.StopEverything and not state.ModeratorBlocking end,
        Busy=function()return state.SafeModePanic or state.TravelBusy or state.AutomationTeleporting
            or state.Dodging or state.Recovering or state.SkillCastRunning or state.MiscCastRunning or ctx.SkillsBusy()end,
        Read=function()
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
        end,
        Equip=function(op)
            if disposed or not state.AccountProgression or op.Item.Native.Parent~=inventory then return false,"Equipment changed"end
            ctx.StopCombat("Updating progression gear")
            local args={op.Action,op.Item.Native}
            if op.Action=="EquipWeapon"then args[3]=op.Slot end
            local reply=game.ReplicatedStorage.Function:InvokeServer("Equipment",args)
            if reply==false then return false,"Equipment request was rejected"end
            return true
        end,
        Status=function(value)state.ProgressionGearStatus=value;text(ui.ProgressionGear,value)end})
    state.ProgressionGearController=gear
    local function invalidate()if not disposed then gear.Invalidate()end end
    ctx.Bind(inventory.DescendantAdded,function(child)
        invalidate()
        if child.Name=="Upgrade" and child:IsA("ValueBase")then ctx.Bind(child.Changed,invalidate)end
    end)
    ctx.Bind(inventory.DescendantRemoving,invalidate)
    for _,upgrade in ipairs(inventory:QueryDescendants("#Upgrade"))do
        if upgrade:IsA("ValueBase")then ctx.Bind(upgrade.Changed,invalidate)end
    end
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
            return root and not root.Anchored and humanoid and humanoid.Health>0
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
        Equipment=function(now)
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
                    gear.Paused=true;gear.Error="Equipment request timed out · toggle progression OFF/ON to retry"
                    text(ui.ProgressionGear,gear.Error)
                end)
            end
        end,
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
]============]
return assert(loadstring(SB2_SOURCE, "SB2"))(SB2_SOURCE)
