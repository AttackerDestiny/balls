local state = {
    AtheonUnlock=restore.AtheonUnlock,
    CreditCheck=restore.CreditCheck,CreditWhitelistText=restore.CreditWhitelistText,
    BossOnly=restore.BossOnly,Build=BUILD, Version=VERSION, Theme=preference("Theme","Dark"), UserId=player.UserId, StopEverything=false,AutoHideUI=preference("AutoHideUI",false)==true,
    Enabled = false, Radius = restore.Radius, SkillRange=restore.SkillRange, Running = true, Nearby = 0,
    HitsSent = 0, LastTarget = "None", LastError = nil,
    AttackInterval = 0.30, ThreatCycle = 0.12, MaxRequestsPerSecond = 48, EffectiveInterval = 0.30,
    Threat = math.clamp(math.floor(restore.Threat), 1, 3), BurstsSent = 0, LastBurstSize = 0,
    AttackBurstInterval = 0.30, AttackBurstActive = false, AttackBurstHistory = {},
    BurstProgress = 0, LastPulseAt = nil, MinimumPulseGap = nil,
    AutoSwing = restore.AutoSwing, SwordSwinging = false, SwingStarts = 0,
    LagPauseUntil = 0, PingMs = nil, Backoff = 1,
    AutoTrade=restore.AutoTrade,TradeMode=restore.TradeMode,TradeItems=type(restore.TradeItems)=="table"and restore.TradeItems or {},
    AutoCraft=type(restore.AutoCraft)=="table"and restore.AutoCraft or {},
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
    HideSkillAnimation = true, HiddenSkillAnimations = 0,
    SkillBurstInterval = 0.30, SkillHitRequests = 0, LastSkillBurstSize = 0, SkillBurstHistory = {},
    AutoExplore = restore.AutoExplore, ExploreHops = 0, Exploring = false,
    AutoDodge = restore.AutoDodge, AtheonDodge=restore.AtheonDodge, TransparentMap = restore.TransparentMap, Dodging = false,
    PerformanceBoosters=restore.PerformanceBoosters,
    AutoJoinFriend=restore.AutoJoinFriend,JoinFriendUsername=restore.JoinFriendUsername,
    SafeMode=restore.SafeMode,SafeFloorId=restore.SafeFloorId,SharedSafeFloorId=restore.SafeFloorId,SafeWhitelistText=restore.SafeWhitelistText,SafeWhitelistIds=restore.SafeWhitelistIds,
    MultiSpot=restore.MultiSpot,MultiSpotSelected=restore.MultiSpotSelected,MultiSpotOrder=restore.MultiSpotOrder,MultiSpotCursor=restore.MultiSpotCursor,MultiSpotPending=restore.MultiSpotPending,
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
function state.FarmClock()
    local ok,value=pcall(workspace.GetServerTimeNow,workspace)
    return ok and value or os.clock()
end
do
    local make=(function()
-- BEGIN BUNDLED FARM COORDINATION
-- END BUNDLED FARM COORDINATION
    end)()
    state.FarmCoordination=make({Now=state.FarmClock,Vector=Vector3.new,UserId=player.UserId,
        Members=function()return Players:GetPlayers()end})
end
env.SB2KillAura = state
local connections = {}
local lastHit = setmetatable({}, { __mode = "k" })
local consecutiveErrors = 0
local nextTargetRefresh = 0
local nextPingCheck = 0
local candidates = {}
local normalScheduler=(function()
-- BEGIN BUNDLED ATTACK SCHEDULER
-- END BUNDLED ATTACK SCHEDULER
end)()(state)
local function finishAttackBurst(reason) normalScheduler.Cancel(reason) end
local createSkillBurst=(function()
-- BEGIN BUNDLED SKILL BURST
-- END BUNDLED SKILL BURST
end)()
local targetPriority=(function()
-- BEGIN BUNDLED TARGET PRIORITY
-- END BUNDLED TARGET PRIORITY
end)()()
local pendingDamage = setmetatable({}, { __mode = "k" })
local stopMovement = function() end
local enemyRegistry=(function()
-- BEGIN BUNDLED ENEMY REGISTRY
-- END BUNDLED ENEMY REGISTRY
end)()({Now=os.clock,Folder=function()return workspace:FindFirstChild("Mobs")end,
    Changed=function()
        state.MultiSpotNextScan=0
        if state.WorkScheduler then state.WorkScheduler.Wake("Movement");state.WorkScheduler.Wake("Combat");state.WorkScheduler.Wake("Skill")end
        if state.WakeSkillAura then state.WakeSkillAura()end
    end})
state.EnemyRegistry=enemyRegistry
local trackedMobs=enemyRegistry.Models
local indexedMobFolder
local combatStatus = "Paused"
local candidatePrimary
local configReady = false
local requestSave = function() end
local enemyHUD

local function refreshMobIndex()
    indexedMobFolder=enemyRegistry.Refresh()
    return indexedMobFolder
end
local function getMobData(mob)
    return enemyRegistry.Data(mob)
end
function state.ReadOwnDamage(health,counter)
    counter=counter or health:FindFirstChild(player.Name)
    if counter and counter:IsA("ValueBase") and type(counter.Value)=="number" then return counter.Value,counter end
    return nil,nil
end
do
    local make=(function()
-- BEGIN BUNDLED CREDIT CHECK
-- END BUNDLED CREDIT CHECK
    end)()
    local makeRoster=(function()
-- BEGIN BUNDLED CREDIT ROSTER
-- END BUNDLED CREDIT ROSTER
    end)()
    local parsedText,members,rosterAt=nil,nil,0
    local function roster()
        local text=state.CreditWhitelistText or ""
        local now=os.clock()
        if members and text==parsedText and now<rosterAt then return members end
        parsedText=text;rosterAt=now+.25
        members=makeRoster(player,Players:GetPlayers(),text)
        return members
    end
    local makePlan=(function()
-- BEGIN BUNDLED CREDIT DAMAGE PLAN
-- END BUNDLED CREDIT DAMAGE PLAN
    end)()
    state.CreditDamagePlanner=makePlan()
    state.CreditController=make({Planner=state.CreditDamagePlanner,Options=function(mob,data,kind)
        local weapons=state.WeaponSkills
        local version=weapons and weapons.Version or 0
        local key=tostring(version)..":"..mob.Name
        local skillKey=tostring(state.SelectedSkill)..":"..version
        local estimate=state.SkillDamageBudget and state.SkillDamageBudget.Estimate(skillKey..":"..mob.Name)or 0
        local ready=state.SkillAura and weapons and weapons.Ready and weapons.IsCompatible(state.SelectedSkill)
        if ready and kind~="Skill"then
            ready=Skills.usingSkill=="none"and Skills.GetCooldown(state.SelectedSkill)>=0
            local definition=ReplicatedStorage.Database.Skills:FindFirstChild(state.SelectedSkill)
            ready=ready and definition and Skills.HasStamina(definition.Cost.Value)and state.SkillActivation and state.SkillActivation.CanHandle(state.SelectedSkill)
        end
        return {NormalKey="Normal:"..key,SkillKey="Skill:"..state.SelectedSkill..":"..key,
            CastKey="Cast:"..state.SelectedSkill..":"..key,ActiveSkill=kind=="Skill"and state.SkillCastRunning,
            NormalEstimate=data.NormalDamagePerHit,SkillEstimate=estimate,
            CanNormal=state.Enabled==true,CanSkill=ready==true}
    end,State=state,Rank=targetPriority.Rank,Now=os.clock,Self=function()return player end,
        Members=roster,MaxHealth=function(data)
            local health=data.Health
            if health:IsA("DoubleConstrainedValue")or health:IsA("IntConstrainedValue")then return health.MaxValue end
            local maximum=health:GetAttribute("MaxValue")or data.Entity:GetAttribute("MaxHealth")
            if type(maximum)=="number"then return maximum end
            local value=data.Entity:FindFirstChild("MaxHealth")
            return value and value:IsA("ValueBase")and tonumber(value.Value)or nil
        end,
        Damage=function(data,person)
            if type(person)=="table"and person.CreditMissing then return nil end
            local counter=data.Health:FindFirstChild(person.Name)or data.Health:FindFirstChild(tostring(person.UserId))
            local value=counter and counter:IsA("ValueBase")and counter.Value
            return type(value)=="number"and value==value and math.max(0,value)or nil
        end})
    function state.SetCreditCheck(on)
        state.CreditCheck=on==true;state.CreditController.Reset()
        state.CreditCheckStatus=state.CreditCheck and "Credit Check · waiting for a boss or mini-boss"or "Credit Check is off"
        if state.WakeSkillAura then state.WakeSkillAura()end
        requestSave()
    end
    function state.SetCreditWhitelist(text)
        local entries,seen={},{}
        for word in tostring(text or ""):gmatch("[%w_]+")do
            if not seen[word:lower()]then entries[#entries+1]=word;seen[word:lower()]=true end
        end
        local value=table.concat(entries,", ")
        if #entries>100 or #value>2000 then error("Use at most 100 Credit Check whitelist entries")end
        state.CreditWhitelistText=value;parsedText=nil;members=nil
        state.CreditController.Reset();requestSave()
    end
end
local function getMobRoot(mob)
    local data = getMobData(mob)
    return data and data.Root
end
