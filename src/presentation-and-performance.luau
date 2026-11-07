-- Controllers publish values through plain adapters; only WindUI renders them.
local controllerViews=(function()
-- BEGIN BUNDLED CONTROLLER VIEW
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
    "AutoJoinFriend","JoinFriendUsername","SafeMode","SafeWhitelistText","SafeWhitelistIds","MultiSpot","MultiSpotSelected",
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
-- END BUNDLED HIDE PLAYERS
    end)()
    local attachBoosts=(function()
-- BEGIN BUNDLED PERFORMANCE BOOST
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
