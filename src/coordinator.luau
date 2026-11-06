-- Runtime work is declared once; each job owns its pace and failure history.
local frameTiming=(function()
-- BEGIN BUNDLED FRAME TIMING
-- END BUNDLED FRAME TIMING
end)()(state)
state.PerformanceBudget=(function()
-- BEGIN BUNDLED PERFORMANCE BUDGET
-- END BUNDLED PERFORMANCE BUDGET
end)()(state)
do
    local attach=(function()
-- BEGIN BUNDLED TRADE HOLD
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
        if not state.Running or state.StopEverything or not gui.Parent then return end
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
