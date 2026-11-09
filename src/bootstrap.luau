local embeddedSource=...
local BUILD="2026-11-09.built-in-idle-protection-v3.0.37"
local VERSION="3.0.37"
if not game:IsLoaded()then game.Loaded:Wait()end
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Stats=game:GetService("Stats")
local HttpService=game:GetService("HttpService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
repeat if not player then task.wait(.1);player=Players.LocalPlayer end until player
local env=getgenv()
local previousRuntime=env.SB2KillAura
local previous=(function()
-- BEGIN BUNDLED SETTINGS SNAPSHOT
-- END BUNDLED SETTINGS SNAPSHOT
end)()(previousRuntime,player.UserId)
local storageBootstrap=(function()
-- BEGIN BUNDLED STORAGE BOOTSTRAP
-- END BUNDLED STORAGE BOOTSTRAP
end)()({Build=BUILD,Source=embeddedSource,UserId=player.UserId,PlaceId=game.PlaceId,
    Prefix="local SB2_SOURCE=["..string.rep("=",12).."[\n",
    Suffix="]"..string.rep("=",12).."]\nreturn assert(loadstring(SB2_SOURCE, \"SB2\"))(SB2_SOURCE)\n",
    IsFile=isfile,Read=readfile,Write=writefile,IsFolder=isfolder,MakeFolder=makefolder,
    Encode=function(value)return HttpService:JSONEncode(value)end})
env.SB2StorageBootstrap=storageBootstrap
local playerGui=player:WaitForChild("PlayerGui")
local runtimeOwner=(function()
-- BEGIN BUNDLED RUNTIME OWNER
-- END BUNDLED RUNTIME OWNER
end)()({Build=BUILD,Job=game.JobId,Parent=playerGui,Pulse=RunService.Heartbeat,Now=os.clock,
    Create=function()
        local root=Instance.new("ScreenGui")
        root.ResetOnSpawn=false;root.DisplayOrder=100;root.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        return root
    end})
if not runtimeOwner then return end
local loadToken={}
env.SB2LoadToken=loadToken
local function startupCurrent()
    return env.SB2LoadToken==loadToken and runtimeOwner.Alive()
end
if game.PlaceId==659222129 and game.GameId==212154879 then
    local makeLobby=(function()
-- BEGIN BUNDLED LOBBY PLAY
-- END BUNDLED LOBBY PLAY
    end)()
    local function findPlay()
        local node=playerGui:FindFirstChild("ScreenGui")
        for _,name in ipairs({"Frame","Buttons","Play"})do node=node and node:FindFirstChild(name)end
        return node
    end
    local function playReady(button)
        if not(button:IsA("GuiButton")and button.Active and button.Visible)then return false end
        if button.Position.Y.Scale==0 and button.Position.Y.Offset<0 then return false end
        local node=button.Parent
        while node and node~=playerGui do
            if(node:IsA("GuiObject")and not node.Visible)or(node:IsA("ScreenGui")and not node.Enabled)then return false end
            node=node.Parent
        end
        local camera=workspace.CurrentCamera
        if not camera then return false end
        local point,extent=button.AbsolutePosition,button.AbsoluteSize
        return extent.X>0 and extent.Y>0 and point.X>=0 and point.Y>=0
            and point.X+extent.X<=camera.ViewportSize.X and point.Y+extent.Y<=camera.ViewportSize.Y
    end
    local function queueLobby()
        local ready,reason=storageBootstrap.Ensure();assert(ready,reason)
        local queue=queue_on_teleport or queueonteleport or(syn and syn.queue_on_teleport)or(fluxus and fluxus.queue_on_teleport)
        assert(type(queue)=="function","Auto Play requires teleport queue support")
        assert(type(readfile)=="function"and type(isfile)=="function"and isfile("SB2Codex/kill-aura.luau"),"Saved source is unavailable")
        queue(string.format([==[
if not game:IsLoaded()then game.Loaded:Wait()end
local p=game:GetService("Players").LocalPlayer
while not p do task.wait();p=game:GetService("Players").LocalPlayer end
if p.UserId==%s and game.GameId==212154879 and isfile("SB2Codex/kill-aura.luau")then
    local code=readfile("SB2Codex/kill-aura.luau")
    if code:find(%q,1,true)then assert(loadstring(code))()end
end
]==],tostring(player.UserId),BUILD))
    end
    local lobby=makeLobby({Now=os.clock,Alive=startupCurrent,Find=findPlay,Ready=playReady,Queue=queueLobby,
        Activate=function(button)
            assert(type(getconnections)=="function","Native Play activation is unavailable")
            local count=0
            for _,listener in ipairs(getconnections(button.MouseButton1Click))do
                if listener.Enabled~=false and type(listener.Function)=="function"then task.spawn(listener.Function);count+=1 end
            end
            return count>0
        end})
    env.SB2LobbyPlay=lobby
    while not lobby.Done and startupCurrent()do lobby.Update();if not lobby.Done then task.wait(.25)end end
    runtimeOwner.Release();runtimeOwner.Root:Destroy()
    return
end
local configFolder="SB2Codex"
local configPath=configFolder.."/settings_"..player.UserId..".json"
local configData,configLoadError={},nil
local filePersistence=type(readfile)=="function"and type(writefile)=="function"and type(isfile)=="function"
local presetBook=(function()
    local makeTransfer=(function()
-- BEGIN BUNDLED CONFIG TRANSFER
-- END BUNDLED CONFIG TRANSFER
    end)()
    local make=(function()
-- BEGIN BUNDLED CONFIG PRESETS
-- END BUNDLED CONFIG PRESETS
    end)()
    local book=make({Folder=configFolder,UserId=tostring(player.UserId),InBetween=game.PlaceId==78945654064532,
        Available=filePersistence,Exists=isfile,Read=readfile,Write=writefile,List=listfiles,Validate=makeTransfer({}).Validate,
        Encode=function(value)return HttpService:JSONEncode(value)end,Decode=function(bytes)return HttpService:JSONDecode(bytes)end})
    local manual=env.SB2ManualPreset
    env.SB2ManualPreset=nil
    book.Activate(type(manual)=="table"and manual.UserId==player.UserId and manual.Id or nil)
    book.MakeTransfer=makeTransfer
    return book
end)()
if presetBook.SettingsPath then configPath=presetBook.SettingsPath end
if previousRuntime and previousRuntime.PresetId~=presetBook.ActiveId then previous=nil end
local resumeConfigPath=env.SB2AutomationResumeConfigPath
env.SB2AutomationResumeConfigPath=nil
if resumeConfigPath and resumeConfigPath~=configPath then
    env.SB2AutomationResumeFeatures=nil;env.SB2SoloResumeTicket=nil
end
if filePersistence and isfile(configPath)then
    local ok,value=pcall(function()
        local text=readfile(configPath)
        assert(#text<=32768,"Settings file exceeds its size limit")
        local decoded,settings=pcall(HttpService.JSONDecode,HttpService,text)
        if decoded and type(settings)=="table"and settings.Version==1 then return settings end
        if not isfile(configPath..".bak")then writefile(configPath..".bak",text)end
        error("Invalid settings backed up; defaults restored")
    end)
    if ok then configData=value else configLoadError=tostring(value)end
end
local sharedSettings,sharedPreferences=nil,{}
if filePersistence then
    local attachShared=(function()
-- BEGIN BUNDLED SHARED SETTINGS
-- END BUNDLED SHARED SETTINGS
    end)()
    local ok,value=pcall(attachShared,{File=presetBook.SharedSettingsPath,Current=presetBook.Seed and presetBook.Seed.Settings or configData,
        IsFile=isfile,Read=readfile,Write=writefile,List=not presetBook.ActiveId and listfiles or nil,
        Encode=function(data)return HttpService:JSONEncode(data)end,Decode=function(text)return HttpService:JSONDecode(text)end})
    if ok then sharedSettings=value;sharedPreferences=value.Values else configLoadError=tostring(value)end
end
local importedConfig=env.SB2ConfigImport
env.SB2ConfigImport=nil
if type(importedConfig)~="table"or importedConfig.UserId~=player.UserId then importedConfig=nil end
importedConfig=importedConfig or presetBook.Seed
local function preference(key,fallback)
    if presetBook.ActiveId and sharedPreferences[key]~=nil then return sharedPreferences[key]end
    if importedConfig then local value=importedConfig.Settings[key];if value~=nil then return value end;return fallback end
    local sources={sharedPreferences,previous and previous.StopEverything and previous.ResumeFeatures or {},previous or {},configData}
    if key=="StopEverything"and previous and previous.ResumeRequested then return false end
    for _,source in ipairs(sources)do if source[key]~=nil then return source[key]end end
    return fallback
end
local function numericPreference(key,fallback,minimum,maximum)
    local number=tonumber(preference(key,fallback))
    if not number or number~=number or math.abs(number)==math.huge then number=fallback end
    return math.clamp(number,minimum,maximum)
end
local restore={Radius=30,SkillRange=30,FarmRange=math.huge,Threat=3}
local booleanDefaults={Enabled=false,AutoSwing=true,AutoTrade=false,AutoEquipBestSword=true,AutoFarm=false,BossOnly=false,
    CreditCheck=false,SkillAura=false,MiscSkillEnabled=false,ViewingPlayer=false,ViewingPlayerInventory=false,
    AutoExplore=true,AutoDodge=true,NoSelfDamage=false,AeganatosDodge=false,AtheonDodge=false,AtheonUnlock=false,AutoCreateBetween=false,AutoJoinFriend=false,SafeMode=false,MultiSpot=false,
    AccountProgression=false,ProgressionBossCleared=false,ProgressionComplete=false,AntiSuspicious=false,AutoRegroup=false}
for key,fallback in pairs(booleanDefaults)do restore[key]=preference(key,fallback)==true end
local textDefaults={BetweenAccess="Private",BetweenDifficulty="Normal",TradeMode="Selected",CreditWhitelistText="",SelectedMiscSkill="Cursed Enhancement",JoinFriendUsername="",SafeWhitelistText="",AutoRegroupUsers=""}
for key,fallback in pairs(textDefaults)do restore[key]=preference(key,fallback)end
for _,key in ipairs({"BetweenRooms","BetweenPace","AntiSuspiciousLimits","TradeItems","AutoCraft","AutoDismantle","PerformanceBoosters","SafeWhitelistIds","MultiSpotSelected","MultiSpotOrder"})do
    local value=preference(key,{})
    restore[key]=type(value)=="table"and value or {}
end
local betweenResume=env.SB2BetweenResumeRooms
env.SB2BetweenResumeRooms=nil
if game.PlaceId==78945654064532 and type(betweenResume)=="table" and betweenResume.UserId==player.UserId
    and type(betweenResume.Rooms)=="table" then restore.BetweenRooms=betweenResume.Rooms end
for _,key in ipairs({"SelectedPlayerId","MultiSpotCursor","MultiSpotPending","ProgressionBossClearedName","ProgressionRestore","AutomationRunId","AutomationResumeFeatures"})do
    restore[key]=preference(key,nil)
end
restore.Skill=preference("SelectedSkill","Piercing Dash")
if type(restore.Skill)~="string"then restore.Skill="Piercing Dash"end
restore.SafeFloorId=tonumber(preference("SafeFloorId",game.PlaceId))or game.PlaceId
restore.ProgressionFloor=math.floor(numericPreference("ProgressionFloor",1,1,12))
if type(restore.ProgressionRestore)~="table"then restore.ProgressionRestore=nil end
if restore.ProgressionFloor~=12 then restore.ProgressionComplete=false end
if previousRuntime and previousRuntime.Destroy then
    local ok,reason=pcall(previousRuntime.Destroy,true)
    if not ok then previousRuntime.Running=false;env.SB2LastReplacementError=tostring(reason);warn("[SB2] Continuing after cleanup failure: "..tostring(reason))end
end
previousRuntime=nil
runtimeOwner.Retire()
local recoveryUntil=env.SB2FarmRecoveryUntil
if type(recoveryUntil)=="number"and recoveryUntil>os.clock()then task.wait(math.min(3,recoveryUntil-os.clock()))end
local releaseStartupHold
if game.PlaceId~=78945654064532 then
    local moveBelow=(function()
-- BEGIN BUNDLED STARTUP BELOW
-- END BUNDLED STARTUP BELOW
    end)()
    local ok,moved,reason=pcall(moveBelow,{Now=os.clock,Sleep=task.wait,
        Alive=function()return env.SB2LoadToken==loadToken and runtimeOwner.Alive()end,
        Root=function()
            local character=player.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            return humanoid and humanoid.Health>0 and character:FindFirstChild("HumanoidRootPart")or nil
        end,
        Position=function(root)return root.Position end,
        Surface=function(root,point)
            local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
            local excluded={root.Parent}
            for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","MobSpawnEffects"})do
                local folder=workspace:FindFirstChild(name);if folder then excluded[#excluded+1]=folder end
            end
            params.FilterDescendantsInstances=excluded
            local hit=workspace:Raycast(point+Vector3.new(0,64,0),Vector3.new(0,-256,0),params)
            if not hit then
                hit=workspace:Raycast(point+Vector3.new(0,192,0),Vector3.new(0,-384,0),params)
            end
            if hit then return hit.Position.Y end
            local humanoid=root.Parent:FindFirstChildOfClass("Humanoid")
            return point.Y-(humanoid and humanoid.HipHeight or 2)-root.Size.Y/2
        end,
        Move=function(root,x,y,z,floor)
            local character=root.Parent
            local humanoid=character:FindFirstChildOfClass("Humanoid")
            local destination=Vector3.new(x,y,z)
            local standing=Vector3.new(x,math.max(root.Position.Y,floor+humanoid.HipHeight+root.Size.Y/2+.5),z)
            local pin=Instance.new("Attachment");pin.Name="SB2StartupAttachment"
            local hold=Instance.new("AlignPosition")
            hold.Name="SB2StartupPosition";hold.Mode=Enum.PositionAlignmentMode.OneAttachment
            hold.Attachment0=pin;hold.Position=destination;hold.ApplyAtCenterOfMass=true;hold.RigidityEnabled=true
            local observers={};local released=false
            local function release(restore)
                if released then return end
                released=true;releaseStartupHold=nil
                for index=#observers,1,-1 do observers[index]:Disconnect();observers[index]=nil end
                hold:Destroy();pin:Destroy()
                if restore and root.Parent==character and player.Character==character and humanoid.Health>0
                    and(root.Position-destination).Magnitude<8 then
                    root.CFrame=CFrame.new(standing)*root.CFrame.Rotation;root.AssemblyLinearVelocity=Vector3.zero
                end
            end
            releaseStartupHold=release
            local function manualMotion()if humanoid.MoveDirection.Magnitude>.05 or humanoid.Jump then release(true)end end
            for _,property in ipairs({"MoveDirection","Jump"})do observers[#observers+1]=humanoid:GetPropertyChangedSignal(property):Connect(manualMotion)end
            observers[#observers+1]=player.CharacterRemoving:Connect(function(removing)if removing==character then release(false)end end)
            observers[#observers+1]=runtimeOwner.Root.Destroying:Connect(function()release(true)end)
            pin.Parent=root;hold.Parent=root
            if(root.Position-destination).Magnitude>.01 then root.CFrame=CFrame.new(destination)*root.CFrame.Rotation end
            root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        end})
    if not ok and releaseStartupHold then releaseStartupHold(true)end
    env.SB2StartupBelowResult={Build=BUILD,Moved=ok and moved==true,Error=not ok and tostring(moved)or (not moved and reason or nil)}
else
    env.SB2StartupBelowResult={Build=BUILD,Moved=false,Reason="The Between"}
end
if not startupCurrent()then return end
local profile=ReplicatedStorage:WaitForChild("Profiles"):WaitForChild(player.Name)
for _,name in ipairs({"Inventory","Locations"})do profile:WaitForChild(name)end
local services=ReplicatedStorage:WaitForChild("CardinalClient"):WaitForChild("MainModule")
require(services)
services=services:WaitForChild("Services")
if not startupCurrent()then runtimeOwner.Release();return end
local Combat=require(services.Combat)
local Actions=require(services.Actions)
local Skills=require(services.Skills)
local GameUI=require(services.UI)
local CanRunSkill=require(ReplicatedStorage.Shared.Util.CanRunSkill)
if not startupCurrent()then runtimeOwner.Release();return end
