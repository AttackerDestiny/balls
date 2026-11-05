local frameTiming=(function()
-- BEGIN BUNDLED FRAME TIMING
-- END BUNDLED FRAME TIMING
end)()(state)

state.PerformanceBudget=(function()
-- BEGIN BUNDLED PERFORMANCE BUDGET
-- END BUNDLED PERFORMANCE BUDGET
end)()(state)

do
    local make=(function()
-- BEGIN BUNDLED TRADE HOLD
-- END BUNDLED TRADE HOLD
    end)()
    state.TradeHold=make({
        Active=function()return state.AutoTradeBusy==true end,
        Blocked=function()return state.StopEverything or state.ModeratorBlocking or state.SafeModePanic or state.AutoJoinFriendHolding or state.AutomationTeleporting end,
        Root=function()
            local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
            return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")or nil
        end,
        Anchor=function(root)
            local p=root.Position
            return Vector3.new(p.X,waveDodge.FloorY(p),p.Z)
        end,
        Pause=function()
            state.TravelSerial=(state.TravelSerial or 0)+1;state.TravelBusy=false
            finishAttackBurst("Trading");stopSword(true)
            if state.CancelSkillAura then state.CancelSkillAura("Trading")end
            if state.CancelMiscSkill then state.CancelMiscSkill()end
            if state.MultiSpotController then state.MultiSpotController.Reset()end
            if state.ProgressionController then state.ProgressionController.Reset()end
            state.FollowTarget=nil
            stopMovement("Trading · holding 20 studs below ground",true)
        end,
        Hold=function(anchor)waveDodge.Idle(anchor)end,
        Release=function()stopMovement("Trade ended · resuming farming",true);nextMovementUpdate=0;nextAcquisition=0 end})
end

local workScheduler=(function()
-- BEGIN BUNDLED WORK SCHEDULER
-- END BUNDLED WORK SCHEDULER
end)()({Now=os.clock,Error=function(name,reason)
    state["Last"..name.."Error"]=reason
    if name=="Movement"then
        state.FarmPauseUntil=os.clock()+1;state.FollowTarget=nil
        movementStatus("Recovering movement · retrying")
    elseif name=="Skill"then
        state.SkillRetryAt=os.clock()+1.5
        state.SkillStatus="Skill retry · waiting for game state"
    elseif name=="MiscSkill"then
        state.MiscReserveStamina=false
    end
end})
state.WorkScheduler=workScheduler
local function taskController(name,interval,fn)
    workScheduler.Add(name,interval,fn)
end
taskController("TradeHold",.05,function()if state.TradeHold then state.TradeHold.Update()end end)
taskController("AuraTouch",.1,function()if state.AuraTouch then state.AuraTouch.Update()end end)
taskController("Float",.1,function(now)if state.ArenaFloat then state.ArenaFloat.Update(now)end end)
taskController("Performance",1,function(now)state.PerformanceBudget.Update(now)end)
taskController("Gear",.5,function(now)if state.UpdateBestSword then state.UpdateBestSword(now)end end)
taskController("Weapon",.25,function(now)if state.WeaponSkills then state.WeaponSkills.Update(now)end end)
taskController("Swing",.05,function()updateAutoSwing()end)
taskController("Dodge",.03,function()waveDodge.Update()end)
taskController("HealthGuard",.5,function(now)updateHealthGuard(now)end)
taskController("HealthHUD",.12,function(now)healthHUD.Update(now)end)
taskController("Ranges",.5,function(now)if state.AutoRanges then state.AutoRanges.Update(now)end end)
taskController("Visual",.08,function()if state.SkillVisuals then state.SkillVisuals.Update()end end)
taskController("Discovery",5,function()discoverDestinations(true)end)
taskController("Movement",.08,function(now)updateMovement(now)end)
taskController("Upright",.08,function()state.UprightController.Update()end)
taskController("MiscSkill",.1,function(now)if state.MiscController then state.MiscController.Update(now)end end)
taskController("Skill",0,function()updateSkillAura()end)
taskController("Combat",.03,function()return scan()end)
local frameOrder={"Float","Performance","Gear","Weapon","Swing","Dodge","HealthGuard","HealthHUD",
    "Ranges","Visual","Discovery","Movement","Upright","MiscSkill","Skill"}
local function runFrame()
    local now=os.clock()
    workScheduler.Step("TradeHold",now)
    workScheduler.Step("AuraTouch",now)
    if state.StopEverything then return end
    if state.ModeratorBlocking or state.AutoJoinFriendHolding then
        if state.PanicToSpawn then state.PanicToSpawn()end
        return
    end
    if state.SafeModePanic then
        if state.SafePanicHoldHere then state.PanicInPlace()else state.PanicToSpawn()end
        return
    end
    if state.AutoTradeBusy then return end
    for _,name in ipairs(frameOrder)do
        if not state.Running then return end
        workScheduler.Step(name,now)
    end
    local ok,message=workScheduler.Step("Combat",now)
    if ok==true then
        consecutiveErrors=0;state.LastError=nil;combatStatus=message
    elseif ok==false then
        consecutiveErrors+=1;state.LastError=tostring(message)
        state.Backoff=math.min(8,state.Backoff*2)
        if consecutiveErrors>=3 then
            state.FarmPauseUntil=now+1;consecutiveErrors=0
            combatStatus="Recovering combat · auto farm stays enabled"
            stopSword()
        end
    end
    state.AverageLoopCost+=((os.clock()-now)-state.AverageLoopCost)*.08
end

do
    local makeRecovery=(function()
-- BEGIN BUNDLED RUNTIME RECOVERY
-- END BUNDLED RUNTIME RECOVERY
    end)()
    state.RuntimeRecovery=makeRecovery({State=state,Now=os.clock,Thread=coroutine.running,
        Cancel=function(thread)task.cancel(thread);return true end,
        RecoverSkill=function()
            state.CancelSkillAura("Recovering stalled skill activation")
            state.SkillRetryAt=os.clock()+1
            state.SkillStatus="Skill timed out · retrying automatically"
        end,
        RecoverFrame=function()
            state.CancelSkillAura("Recovering stalled update")
            stopMovement("Recovering stalled update",true)
            state.FollowTarget=nil;state.FarmTargetLock=nil
            nextTargetRefresh,nextMovementUpdate,nextAcquisition=0,0,0
            state.FarmPauseUntil=os.clock()+.5
        end,
        RecoverTravel=function(serial)
            if state.TravelSerial~=serial then return end
            state.TravelSerial=serial+1
            if state.TravelWorker then pcall(task.cancel,state.TravelWorker)end
            state.TravelWorker=nil;state.TravelStartedAt=nil;state.TravelBusy=false
            state.MultiSpotTravelPending=false;state.LastTravelDestination=nil;state.LastTravelPosition=nil
            state.TravelError="Arena travel timed out · retrying without restarting"
            stopMovement(state.TravelError,true);setTravelStatus(state.TravelError)
        end})
    local accumulator,lastErrorAt=0,0
    bind(RunService.Heartbeat,function(delta)
        frameTiming.Sample(delta,os.clock())
        if not state.Running or state.StopEverything or not gui.Parent then return end
        state.RuntimeRecovery.CheckPending(os.clock())
        accumulator+=delta
        local period=state.SafeModePanic and .1 or (state.Enabled or state.SkillAura) and 1/60 or (state.AutoDodge and workspace:FindFirstChild("WaveDefenseStuff") and .04 or .1)
        if accumulator+.0005<period then return end
        accumulator=math.min(period,math.max(0,accumulator-period))
        local ok,message=state.RuntimeRecovery.Run(runFrame)
        if ok==false then
            state.LastCoordinatorError=tostring(message)
            state.FarmPauseUntil=os.clock()+.5
            if os.clock()-lastErrorAt>5 then lastErrorAt=os.clock();warn("[SB2 Coordinator] "..tostring(message)) end
        end
    end)
end
