-- Yield only while initializing; gameplay object creation stays synchronous.
state.StartupSliceAt=os.clock()
function state.YieldStartup()
    if not state.StartupComplete and os.clock()-state.StartupSliceAt>=.002 then
        task.wait()
        state.StartupSliceAt=os.clock()
    end
end
local controllerViews=(function()
-- BEGIN BUNDLED CONTROLLER VIEW
-- END BUNDLED CONTROLLER VIEW
end)()()
local function create(className, properties, parent)
    if type(parent)=="table"and parent.ControllerView then return controllerViews.New(properties,parent)end
    state.YieldStartup()
    local object = Instance.new(className)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function corner(object, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, object)
end
local function bind(signal, callback)
    if type(signal)=="table"and signal.ControllerSignal then return signal:Connect()end
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

do
    local make=(function()
-- BEGIN BUNDLED ANTI AFK
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
local showUI=create("TextButton",{Name="ShowUI",Text="🪶",Visible=false,Font=Enum.Font.GothamBold,TextSize=26,
    Size=UDim2.fromOffset(44,44),Position=UDim2.new(.5,0,0,48),AnchorPoint=Vector2.new(.5,0),
    BackgroundColor3=Color3.fromRGB(42,42,44),BorderSizePixel=0,TextColor3=Color3.fromRGB(239,239,241)},gui)
corner(showUI,22)
create("UIStroke",{Color=Color3.fromRGB(255,255,255),Transparency=.8,Thickness=1},showUI)
function state.SetUIVisible(visible)
    showUI.Visible=state.Running==true
    state.UIHidden=true
    if visible and state.Running and state.WindUIError and state.RestartScript then state.RestartScript()end
end
bind(showUI.Activated,function()state.SetUIVisible(state.UIHidden)end)
local content=controllerViews.New({Name="ControllerState"})
local function uiButton(name,text,order,height,parent)
    return controllerViews.New({Name=name,Text=text},parent or content)
end
local function uiLabel(name,text)
    return controllerViews.New({Name=name,Text=text},content)
end
local function revealOptions()end
local toggle=uiButton("Toggle","Kill aura · OFF")
local farmToggle=uiButton("AutoFarm","Auto farm · OFF")
local dodgeToggle=uiButton("AutoDodge","Auto dodge · ON")
local savePending, lastSettingsEdit = false, 0
local lastSavedPayload,lastSavedStorageGeneration
local function settingsPayload()
    local position = {X={Scale=0,Offset=0},Y={Scale=0,Offset=0}}
    local healthPosition = enemyHUD and enemyHUD.Position or UDim2.new(0.5, 0, 0.7, 0)
    local features=state
    return {AutoCreateBetween=state.AutoCreateBetween,BetweenAccess=state.BetweenAccess,BetweenDifficulty=state.BetweenDifficulty,AtheonUnlock=state.AtheonUnlock,AutoCraft=state.AutoCraft,AutoTrade=state.AutoTrade,TradeMode=state.TradeMode,TradeItems=state.TradeItems,AutoDismantle=state.AutoDismantle,AutoEquipBestSword=state.AutoEquipBestSword,
        StopEverything=false,
        AutoJoinFriend=state.AutoJoinFriend,JoinFriendUsername=state.JoinFriendUsername,
        SafeMode=state.SafeMode,SafeFloorId=state.SharedSafeFloorId or state.SafeFloorId,SafeWhitelistText=state.SafeWhitelistText,SafeWhitelistIds=state.SafeWhitelistIds,
        MultiSpot=state.MultiSpot,MultiSpotSelected=state.MultiSpotSelected,MultiSpotOrder=state.MultiSpotOrder,MultiSpotCursor=state.MultiSpotCursor,MultiSpotPending=state.MultiSpotPending,
        AccountProgression=state.AccountProgression,ProgressionFloor=state.ProgressionFloor,
        ProgressionBossCleared=state.ProgressionBossCleared,ProgressionComplete=state.ProgressionComplete,
        ProgressionBossClearedName=state.ProgressionBossClearedName,
        ProgressionRestore=state.ProgressionRestore,
        AutomationRunId=state.AutomationRunId,AutomationResumeFeatures=state.AutomationResumeFeatures,
        Version = 1, Enabled = features.Enabled, AutoFarm = features.AutoFarm,BossOnly=state.BossOnly,CreditCheck=state.CreditCheck,CreditWhitelistText=state.CreditWhitelistText,
        AutoSwing = features.AutoSwing, Radius = state.Radius, SkillRange=state.SkillRange,
        UnsafeOffsetProfiles = state.UnsafeOffsetProfiles, Threat = state.Threat,
        SkillAura = features.SkillAura, SelectedSkill = state.SelectedSkill,SkillPerWeapon=state.SkillPerWeapon,SkillPerWeaponVersion=state.SkillPerWeaponVersion,
        MiscSkillEnabled=features.MiscSkillEnabled==true,SelectedMiscSkill=state.SelectedMiscSkill,
        AutoExplore = state.AutoExplore,
        AutoDodge = features.AutoDodge, AtheonDodge=features.AtheonDodge,
        PerformanceBoosters=features.PerformanceBoosters,
        PanelPosition = { position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset },
        WindUIPosition=state.WindUIPosition,AutoHideUI=state.AutoHideUI,Theme=state.Theme,ActiveTab=state.UI and state.UI.ActiveTab,
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
function state.SetThreat()
    state.Threat=3
    state.BurstProgress=0
    requestSave()
end
state.SetThreat(state.Threat)

-- Each attacked mob gets an event-driven health row; only the fill is eased.
local healthHUD=(function()
-- BEGIN BUNDLED ENEMY HEALTH
-- END BUNDLED ENEMY HEALTH
end)()({State=state,Parent=gui,Create=create,Corner=corner,GetData=getMobData,
    TweenService=TweenService,Input=UserInputService,Position=configData.HealthHUDPosition,Save=requestSave,
    Priority=function(mob) return targetPriority.Rank(mob) end,
    Present=function(mob) return mob:IsDescendantOf(workspace) end,
})
enemyHUD=healthHUD.Root
local function trackHealth(mob) healthHUD.Focus(mob) end

local skillToggle=uiButton("SkillAura","")
local skillDropdown=uiButton("SkillDropdown",state.SelectedSkill)
local skillList=controllerViews.New({Name="SkillOptions"})
local AttackStats=require(ReplicatedStorage.Shared.Library.AttackStats)
function state.SetSkillRange(value)
    state.SkillRange=math.clamp(math.floor(tonumber(value)or state.SkillRange),20,120)
end
local function refreshSkillChoices()
    state.SkillChoices=state.WeaponSkills and state.WeaponSkills.Choices()or {}
end
function state.SetSelectedSkill(name)
    return state.WeaponSkills and state.WeaponSkills.Select(name)or false
end
function state.SetSkillAura(enabled)
    if state.StopEverything and enabled==true then return false end
    state.SkillAura=enabled==true
    if state.AuraTouch then state.AuraTouch.Update()end
    if state.WakeSkillAura then state.WakeSkillAura()end
    if not state.SkillAura and state.CancelSkillAura then state.CancelSkillAura("Skill aura disabled")end
    state.SkillStatus=state.SkillAura and "Waiting for a nearby enemy"or "Skill aura is off"
    requestSave()
end
refreshSkillChoices()
local travelHeading=uiLabel("TravelHeading","")
local travelDropdown=uiButton("TeleportDropdown","")
local travelList=controllerViews.New({Name="TravelOptions"})
state.TravelStatus=""
local function setTravelStatus(message)state.TravelStatus=message end
local function setTravelOpen()end
state.SetTravelOpen=setTravelOpen
state.UI={Root=gui,Content=content,SkillOptions=skillList,TravelOptions=travelList,Pages={},TabButtons={}}
for _,name in ipairs({"Main","Combat","Challenge Floors","Auto Skill","Misc","Player","Utility","Speacial"})do
    state.UI.Pages[name]=controllerViews.New({Name=name})
end
for _,name in ipairs({"AutoEquipBestSword","AtheonDodge","MiscSkillToggle","MiscSkillDropdown","MiscSkillOptions",
    "BoostDropdown","BoostOptions","PlayerSelector","PlayerOptions","TeleportPlayer","ViewPlayer","ViewInventory",
    "PlayerInventory","PlayerMessage"})do state.UI[name]=controllerViews.New({Name=name})end
state.UI.BoostButtons={}
function state.SetTab(name)state.UI.ActiveTab=name end
function state.SetAutoEquipBestSword(on)
    state.AutoEquipBestSword=on==true
    if state.ProgressionGearController then state.ProgressionGearController.Reset()end
    requestSave()
end
function state.SetAtheonDodge(on)
    state.AtheonDodge=on==true
    if not state.AtheonDodge and state.AtheonDodgeController then state.AtheonDodgeController.Reset()end
    requestSave()
end
state.SetAutoEquipBestSword(restore.AutoEquipBestSword)
state.SetAtheonDodge(restore.AtheonDodge)
state.MiscMenuMethods={Dismantle="openDismantle",Upgrade="openUpgrade",["The Forge"]="openCrystalForge"}
function state.OpenGameMenu(name)
    if state.StopEverything then return false,"Stop Everything is on"end
    local method=state.MiscMenuMethods[name]
    if not method or type(GameUI[method])~="function"then return false,"Menu is unavailable"end
    local ok,message=pcall(GameUI[method])
    if not ok then state.LastMenuError=tostring(message)end
    return ok,message
end
state.SetTab(preference("ActiveTab","Main"))

do
    local function renderBoost()end
    local createPlayerVisibility=(function()
-- BEGIN BUNDLED HIDE PLAYERS
-- END BUNDLED HIDE PLAYERS
    end)()
    local playerVisibility=createPlayerVisibility({Players=Players,Workspace=workspace,
        EffectServices={require(services.Graphics),require(services.SkillEffects)}})
    state.PlayerVisibility=playerVisibility
    local createBoost=(function()
-- BEGIN BUNDLED PERFORMANCE BOOST
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
