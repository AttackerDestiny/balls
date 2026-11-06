local embeddedSource=...
if not game:IsLoaded()then game.Loaded:Wait()end
-- Swordburst 2: automation controllers with the modern WindUI interface.
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
local previous=(function()
-- BEGIN BUNDLED SETTINGS SNAPSHOT
-- END BUNDLED SETTINGS SNAPSHOT
end)()(previousRuntime,player.UserId)
local BUILD="2026-11-06.common-farm-target-v2.0.21"
local VERSION="2.0.21"
local storageBootstrap=(function()
-- BEGIN BUNDLED STORAGE BOOTSTRAP
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
-- END BUNDLED SHARED SETTINGS
    end)()
    local ok,value=pcall(make,{Current=configData,IsFile=isfile,Read=readfile,Write=writefile,List=listfiles,
        Encode=function(v)return HttpService:JSONEncode(v)end,Decode=function(v)return HttpService:JSONDecode(v)end})
    if ok then sharedSettings=value;sharedPreferences=value.Values else configLoadError=tostring(value)end
end
local importedConfig=env.SB2ConfigImport
if importedConfig and importedConfig.UserId~=player.UserId then importedConfig=nil end
env.SB2ConfigImport=nil
local function preference(key, fallback)
    if importedConfig then
        local value=importedConfig.Settings[key]
        if value~=nil then return value end
        return fallback
    end
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
    AtheonUnlock=preference("AtheonUnlock",false)==true,
    AutoCreateBetween=preference("AutoCreateBetween",false)==true,
    BetweenAccess=preference("BetweenAccess","Private"),
    BetweenDifficulty=preference("BetweenDifficulty","Normal"),
    AutoCraft=preference("AutoCraft",{}),
    AutoDismantle=preference("AutoDismantle",{}),
    AutoEquipBestSword=preference("AutoEquipBestSword",true)==true,
    AutoFarm=preference("AutoFarm",false)==true,BossOnly=preference("BossOnly",false)==true,CreditCheck=preference("CreditCheck",false)==true,CreditWhitelistText=preference("CreditWhitelistText",""),
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
    PerformanceBoosters=preference("PerformanceBoosters",{}),
    AutoJoinFriend=preference("AutoJoinFriend",false)==true,JoinFriendUsername=preference("JoinFriendUsername",""),
    SafeMode=preference("SafeMode",false)==true,SafeFloorId=tonumber(preference("SafeFloorId",game.PlaceId)) or game.PlaceId,
    SafeWhitelistText=preference("SafeWhitelistText",""),SafeWhitelistIds=preference("SafeWhitelistIds",{}),
    MultiSpot=preference("MultiSpot",false)==true,MultiSpotSelected=preference("MultiSpotSelected",{}),MultiSpotOrder=preference("MultiSpotOrder",{}),
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
    local retired,reason=pcall(previousRuntime.Destroy,true)
    if not retired then
        previousRuntime.Running=false
        env.SB2LastReplacementError=tostring(reason)
        warn("[SB2] Previous runtime cleanup failed; continuing replacement: "..tostring(reason))
    end
end
previousRuntime=nil
runtimeOwner.Retire()
if env.SB2FarmRecoveryUntil and env.SB2FarmRecoveryUntil > os.clock() then
    task.wait(math.min(3, env.SB2FarmRecoveryUntil - os.clock()))
end

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
            local standingY=math.max(root.Position.Y,floor+humanoid.HipHeight+root.Size.Y/2+.5)
            local attachment=Instance.new("Attachment")
            attachment.Name="SB2StartupAttachment"
            local hold=Instance.new("AlignPosition")
            hold.Name="SB2StartupPosition"
            hold.Mode=Enum.PositionAlignmentMode.OneAttachment
            hold.Attachment0=attachment
            hold.Position=destination
            hold.ApplyAtCenterOfMass=true
            hold.RigidityEnabled=true
            local connections={}
            releaseStartupHold=function(restoreGround)
                releaseStartupHold=nil
                for _,connection in ipairs(connections)do connection:Disconnect()end
                hold:Destroy()
                attachment:Destroy()
                if restoreGround and root.Parent==character and player.Character==character
                    and humanoid.Health>0 and (root.Position-destination).Magnitude<8 then
                    root.CFrame=CFrame.new(x,standingY,z)*root.CFrame.Rotation
                    root.AssemblyLinearVelocity=Vector3.zero
                end
            end
            local function releaseForInput()
                if releaseStartupHold and (humanoid.MoveDirection.Magnitude>.05 or humanoid.Jump)then
                    releaseStartupHold(true)
                end
            end
            connections[1]=humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(releaseForInput)
            connections[2]=humanoid:GetPropertyChangedSignal("Jump"):Connect(releaseForInput)
            connections[3]=player.CharacterRemoving:Connect(function(removing)
                if removing==character and releaseStartupHold then releaseStartupHold(false)end
            end)
            connections[4]=runtimeOwner.Root.Destroying:Connect(function()
                if releaseStartupHold then releaseStartupHold(true)end
            end)
            attachment.Parent=root
            hold.Parent=root
            if (root.Position-destination).Magnitude>.01 then
                root.CFrame=CFrame.new(destination)*root.CFrame.Rotation
            end
            root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        end})
    if not ok and releaseStartupHold then releaseStartupHold(true)end
    env.SB2StartupBelowResult={Build=BUILD,Moved=ok and moved==true,Error=not ok and tostring(moved)or (not moved and reason or nil)}
else
    env.SB2StartupBelowResult={Build=BUILD,Moved=false,Reason="The Between"}
end
if env.SB2LoadToken~=loadToken or not runtimeOwner.Alive()then return end

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
