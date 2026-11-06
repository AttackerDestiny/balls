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
    "AutoExplore","AutoDodge","NoSelfDamage","AeganatosDodge","AtheonDodge","AtheonUnlock","AutoCreateBetween","BetweenAccess","BetweenDifficulty","AutoJoinFriend","JoinFriendUsername","SafeMode","SafeFloorId",
    "SafeWhitelistText","SafeWhitelistIds","MultiSpot","MultiSpotSelected","MultiSpotOrder","MultiSpotCursor","MultiSpotPending",
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
-- END BUNDLED ATTACK SCHEDULER
end)()(state)
local function finishAttackBurst(reason)return normalScheduler.Cancel(reason)end
local createSkillBurst=(function()
-- BEGIN BUNDLED SKILL BURST
-- END BUNDLED SKILL BURST
end)()
local targetPriority=(function()
-- BEGIN BUNDLED TARGET PRIORITY
-- END BUNDLED TARGET PRIORITY
end)()()
local enemyRegistry=(function()
-- BEGIN BUNDLED ENEMY REGISTRY
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
    return enemyRegistry.Data(mob)
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
-- END BUNDLED CREDIT CHECK
    end)()
    local createRoster=(function()
-- BEGIN BUNDLED CREDIT ROSTER
-- END BUNDLED CREDIT ROSTER
    end)()
    local createPlanner=(function()
-- BEGIN BUNDLED CREDIT DAMAGE PLAN
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
