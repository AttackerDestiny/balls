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
    if not state.Running or not state.Enabled or not state.AutoSwing or state.StopEverything or state.RemovingAnimations then return end
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
    if not state.Enabled or not state.AutoSwing or state.StopEverything or state.RemovingAnimations then stopSword(true); return end
    playBurstSwing()
end

do
    local create=(function()
-- BEGIN BUNDLED SKILL ACTIVATION
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
        if state.CreditController and not state.CreditController.AllowAction(mob,data,"SkillStart")then return end
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
    local cast={Id=skillCastSerial,Name=name,Version=weapons.Version,Character=character,Cancelled=false,
        RecoveryDeadline=now+math.max(8,(state.SkillActivation.Window(name)or 4)+3)}
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
        return not cast.Cancelled and not cast.CreditFinished and state.ActiveSkillCast==cast and state.Running and not state.StopEverything
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
            if state.CreditController then for _,item in ipairs(burst.Targets)do
                local entry=getMobData(item.Target);if entry then state.CreditController.Observe(item.Target,entry)end
            end end
            state.SkillActivation.Result(name,burst.Damage,burst.TotalRequests)
            if not cast.Cancelled then for _,item in ipairs(burst.Targets) do
                local entry=getMobData(item.Target)
                local settled=not burst.ObservationReadyAt or os.clock()>=burst.ObservationReadyAt
                if entry and state.ReadOwnDamage(item.Health,item.Counter)~=nil and (item.Damage>0 or (settled and entry.Health.Value>0)) then
                    if item.Damage>0 and item.Requested>0 then
                        if state.CreditDamagePlanner and not cast.CreditFinished then
                            state.CreditDamagePlanner.Learn("Cast:"..name..":"..cast.Version..":"..item.TargetName,item.Damage)
                        end
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
                    if state.CreditController and not state.CreditController.AllowAction(mob,entry,"Skill")then
                        -- End this scripted skill window when a small normal hit
                        -- is preferred, or credit is reached; leave native damage alone.
                        if mob==target and (state.CreditController.ActionReason=="Normal"or state.CreditController.ActionReason=="Qualified")then cast.CreditFinished=true end
                        return false
                    end
                    if state.MultiSpotEncounter and (not state.MultiSpotPriorityActive or state.MultiSpotEncounter[mob])then state.MultiSpotEncounter[mob]=true end
                    if state.CreditController then state.CreditController.Sent(mob,entry,"Skill")end
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
                if not current() and not burst.FinishedAt then cast.Multi.Cancel(cast.CreditFinished and "Credit plan · ending skill hits"or "Equipment or game state changed") end
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
    if not state.Enabled then
        finishAttackBurst("Paused");stopSword()
    end
    state.LastError = nil
    consecutiveErrors = 0
    nextTargetRefresh = 0
    state.Backoff = 1
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
local function updateHealthGuard(now)
    now=now or os.clock()
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
    if not state.Running or state.Destroying then return end
    state.Destroying=true
    local preserveSearch=teleportCleanup==true and (state.AutomationTeleporting
        or ((state.SafeMode or state.MultiSpot or state.AccountProgression)and state.ServerTeleportStarted)
        or (state.SoloServerSearch and state.SoloServerSearch.Active and state.SoloServerSearch.Phase=="Teleporting"))
    local scope=(function()
-- BEGIN BUNDLED RUNTIME SCOPE
-- END BUNDLED RUNTIME SCOPE
    end)()()
    local function cleanup(name,fn)scope.Add(name,fn)end
    local function retire(name,object,method,...)
        if not object then return end
        local args=table.pack(...)
        cleanup(name,function()if object[method]then object[method](table.unpack(args,1,args.n))end end)
    end
    cleanup("Save",function()if configReady and not preserveSearch then state.SaveNow()end end)
    cleanup("Stop",function()state.Enabled=false;state.AutoFarm=false;state.SkillAura=false;state.Running=false end)
    retire("UI",state.WindUI,"Destroy")
    retire("AntiAFK",state.AntiAfk,"Destroy")
    retire("Ownership",runtimeOwner,"Release")
    retire("Search",state.SoloServerSearch,"Destroy",preserveSearch)
    if not preserveSearch then retire("Safe",state.SafeController,"Destroy")end
    retire("MultiSpot",state.MultiSpotController,"Destroy")
    cleanup("Progression",function()if state.ProgressionDestroy then state.ProgressionDestroy()end end)
    cleanup("Block dialog visuals",function()if state.BlockDialogMask then state.BlockDialogMask.Destroy()end end)
    retire("Performance",state.PerformanceBoost,"Destroy")
    cleanup("Skill",function()if state.CancelSkillAura then state.CancelSkillAura("Script replaced")end end)
    cleanup("Weapons",function()if state.WeaponSkillsDestroy then state.WeaponSkillsDestroy()end end)
    cleanup("Sword",function()stopSword(true)end)
    cleanup("Support",function()if state.CancelMiscSkill then state.CancelMiscSkill()end end)
    retire("Players",state.PlayerTools,"Destroy")
    retire("Moderator",state.ModeratorWatch,"Destroy")
    retire("Upright",state.UprightController,"Destroy")
    retire("Dodge",waveDodge,"Destroy")
    retire("Visuals",state.SkillVisuals,"Destroy")
    cleanup("World",function()if state.RestoreWorldVisuals then state.RestoreWorldVisuals()end end)
    cleanup("DamageHook",function()if state.RestoreSkillDamageHook then state.RestoreSkillDamageHook()end end)
    retire("Activation",state.SkillActivation,"Release")
    cleanup("Observation",function()if state.FinishSkillObservation then state.FinishSkillObservation()end end)
    retire("Attacks",normalScheduler,"Destroy")
    cleanup("HealthObserver",function()if guardConnection then guardConnection:Disconnect();guardConnection=nil end end)
    cleanup("Movement",function()stopMovement(nil,replacing==true)end)
    retire("Collision",state.FarmNoclip,"Destroy")
    retire("Recovery",state.RuntimeRecovery,"Destroy")
    retire("Touch",state.AuraTouch,"Destroy")
    retire("SpotHUD",state.MultiSpotHUD,"Destroy")
    retire("HealthHUD",healthHUD,"Destroy")
    retire("Scheduler",state.WorkScheduler,"Destroy")
    retire("Enemies",state.EnemyRegistry,"Destroy")
    cleanup("Connections",function()
        for _,connection in ipairs(connections)do pcall(function()connection:Disconnect()end)end
        table.clear(connections)
    end)
    cleanup("Root",function()if gui then gui:Destroy()end end)
    cleanup("Singleton",function()if env.SB2KillAura==state then env.SB2KillAura=nil end end)
    state.CleanupErrors=scope.Close()
end
bind(toggle.Activated, function() state.SetEnabled(not state.Enabled) end)
bind(gui.Destroying, function() state.Destroy(false, true) end)

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
        local creditData=getMobData(mob)
        if state.CreditController and not state.CreditController.AllowAction(mob,creditData,"Normal")then return false end
        if state.FinishSkillObservation then state.FinishSkillObservation() end
        if not pendingDamage[mob] then
            local data=getMobData(mob)
            local contribution,counter=state.ReadOwnDamage(data.Health)
            pendingDamage[mob]={Health=data.Health,Before=data.Health.Value,Time=os.clock(),Requests=0,
                Distance=attackDeltaFor(data,player.Character.HumanoidRootPart).Magnitude,
                Contribution=contribution,Counter=counter,SkillRequests=state.SkillHitRequests}
        end
        if state.MultiSpotEncounter and (not state.MultiSpotPriorityActive or state.MultiSpotEncounter[mob])then state.MultiSpotEncounter[mob]=true end
        if state.CreditController then state.CreditController.Sent(mob,creditData,"Normal")end
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
        if candidatePrimary ~= primary then candidatePrimary = primary end
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
