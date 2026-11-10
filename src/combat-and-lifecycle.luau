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
        if waveDodge.RecordDamage then waveDodge.RecordDamage(observation)end
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
    owned("UI",state.WindUI);owned("AntiAFK",state.AntiAfk);owned("Reward webhook",state.WebhookController)
    method("Search",search,"Destroy",preserveSearch)
    if not preserveSearch then owned("Safe",state.SafeController)end
    owned("MultiSpot",state.MultiSpotController)
    owned("Farm desync",state.FarmDesyncController)
    owned("AutoRegroup",state.AutoRegroupController)
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
