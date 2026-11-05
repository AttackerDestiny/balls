state.MovementOwnership=(function()
-- BEGIN BUNDLED MOVEMENT OWNER
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
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return end
    local newValue = (state.OffsetMode=="Above" and 1 or -1)*math.max(1,math.floor(math.abs(value)*10+0.5)/10)
    if offsetInitialized and newValue == state.TeleportOffset then return end
    state.TeleportOffset = newValue
    offsetInitialized = true
    -- Recalibration is an intentional destination change, not a server correction.
    teleportTarget, lastTeleportPosition = nil, nil
    lastTeleportTime, nextMovementUpdate = 0, 0
    state.OffsetGraceUntil = os.clock() + 0.4
    correctionStrikes, correctionTarget = 0, nil
end
local activeOffsetMob, offsetSample
state.OffsetAvoidTypes={}
state.AutoOffsetSolver=(function()
-- BEGIN BUNDLED AUTO OFFSET
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
    local make=(function()
-- BEGIN BUNDLED GROUND FOLLOW
-- END BUNDLED GROUND FOLLOW
    end)()
    local enemy=services:FindFirstChild("EnemySkills")
    state.NativeEnemySkills=enemy and require(enemy)
    state.GroundFollow=make({
        MapDeleted=function()return state.PerformanceBoosters["Delete map"]or state.PerformanceBoosters["Remove everything"]end,
        Floor=function(mob,data)
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
            local excluded={mob}
            for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects"})do
                local folder=workspace:FindFirstChild(name);if folder then excluded[#excluded+1]=folder end
            end
            if player.Character then excluded[#excluded+1]=player.Character end
            params.FilterDescendantsInstances=excluded
            local hit=workspace:Raycast(data.Root.Position+Vector3.new(0,32,0),Vector3.new(0,-2048,0),params)
            if hit and hit.Normal.Y>.6 then return hit.Position.Y end
        end,
        GroundHint=function(mob)
            local native=state.NativeEnemySkills
            local rig=native and native.RiggedEnemies and native.RiggedEnemies[mob]
            local smash=rig and rig.ActiveSkills.LavaSmash
            if smash and not smash.Destroyed then
                return smash.LastCFrame and smash.LastCFrame.Position or smash.SurfacePosition
            end
        end})
end
function state.ResolveAutoOffset(mob)
    state.FixedFarmPosition=nil
    local data=getMobData(mob)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not data or not root then return nil end
    if state.AutoFarm and mob.Name=="Suspended Unborn"then
        -- Supplied arena (-2439,60,5389), with the requested +10 height.
        local destination=Vector3.new(-2439,70,5389)
        if state.FarmCoordination then destination=state.FarmCoordination.Spread(destination,mob)end
        activeOffsetMob,offsetSample=nil,nil
        state.FixedFarmPosition=destination
        state.AutoOffsetTarget,state.AutoOffsetDestination=mob,destination
        state.FarmTargetAirborne=false
        state.TeleportOffset=destination.Y-data.Root.Position.Y
        state.OffsetStatus="Suspended Unborn · fixed arena position +10 studs"
        data.LastGroundedFarmDestination=destination
        return state.TeleportOffset
    end
    local now,mobRoot=os.clock(),data.Root
    local key=state.GetOffsetKey(mob,data)
    if not data.BodyBelow or not data.BodyAbove or data.OffsetRootSize ~= mobRoot.Size then
        local bottom,top = -mobRoot.Size.Y/2,mobRoot.Size.Y/2
        local reach = math.max(12, mobRoot.Size.Magnitude * 2)
        -- Whole-model bounds can contain effects at the world origin. Only use
        -- visible body parts near the root, once per mob/size.
        for _, part in ipairs(mob:QueryDescendants("BasePart")) do
            local name = string.lower(part.Name)
            if part.Transparency < 0.95 and (part.Position - mobRoot.Position).Magnitude <= reach
                and not string.find(name, "hitbox", 1, true) and not string.find(name, "effect", 1, true)
                and not string.find(name, "attack", 1, true) and not string.find(name, "trail", 1, true)
                and not string.find(name,"weapon",1,true) and not string.find(name,"sword",1,true)
                and not string.find(name,"blade",1,true) and name~="handle"
                and not part:FindFirstAncestorWhichIsA("Tool") and not part:FindFirstAncestorWhichIsA("Accessory") then
                local cf, size = part.CFrame, part.Size
                local halfHeight = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
                bottom = math.min(bottom, part.Position.Y - mobRoot.Position.Y - halfHeight)
                top=math.max(top,part.Position.Y-mobRoot.Position.Y+halfHeight)
            end
        end
        data.BodyBelow,data.BodyAbove = -bottom,top
        data.OffsetRootSize = mobRoot.Size
    end
    local head=character:FindFirstChild("Head")
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    local playerAbove=head and math.max(root.Size.Y/2,head.Position.Y+head.Size.Y/2-root.Position.Y) or 3
    local playerBelow=math.max(3,humanoid and humanoid.HipHeight+root.Size.Y/2 or 3)
    local grounded,airborne=state.GroundFollow.Resolve(mob,data,now)
    state.FarmTargetAirborne=airborne
    if airborne then
        local destination=data.LastGroundedFarmDestination
            or (state.FarmAbove and root.Position)
            or (grounded and Vector3.new(grounded.X,grounded.Y-data.BodyBelow-20,grounded.Z)) or root.Position
        state.AutoOffsetTarget,state.AutoOffsetDestination=mob,destination
        state.OffsetStatus="Waiting for enemy to land"
        return destination.Y-mobRoot.Position.Y
    end
    if state.AutoFarm and state.FarmCoordination then
        local sharedCenter=mobRoot.Position+Vector3.new(0,(2-mobRoot.Size.Y)*.5,0)
        local plan,reason=state.AutoOffsetSolver({Enemy=mobRoot,Player={Size=Vector3.new(2,2,1)},Center=sharedCenter,
            Mode="Below",Reach=state.AutoRanges.BodyRange(data),Margin=3,
            BodyBelow=data.BodyBelow,BodyAbove=data.BodyAbove,PlayerAbove=3,PlayerBelow=3,
            DestroyHeight=workspace.FallenPartsDestroyHeight})
        if not plan then
            state.AutoOffsetTarget,state.AutoOffsetDestination=nil,nil
            state.OffsetStatus=reason
            return nil
        end
        local destination=state.FarmCoordination.Spread(plan.Destination,mob,sharedCenter,plan.Reach)
        state.AutoOffsetTarget,state.AutoOffsetDestination=mob,destination
        data.LastGroundedFarmDestination=destination
        activeOffsetMob,offsetSample=nil,nil
        state.TeleportOffset=destination.Y-mobRoot.Position.Y
        state.OffsetStatus="Separated farm hold · slot "..tostring(state.FarmCoordination.Slot or 1)
        return state.TeleportOffset
    end
    local center=root.Position+state.AutoRanges.Delta(data,root)
    local reach=state.FarmAbove and state.AutoRanges.Range(state.Enabled and "Kill" or "Skill",data,state.SelectedSkill) or state.AutoRanges.BodyRange(data)
    local plan,reason=state.AutoOffsetSolver({Enemy=mobRoot,Player=root,Center=center,
        Mode=state.OffsetMode or "Below",Reach=reach,Margin=1.5+math.min(1,(state.PingMs or 150)/500),
        AdaptiveAbove=state.FarmAbove,BodyBelow=data.BodyBelow,BodyAbove=data.BodyAbove,PlayerAbove=playerAbove,PlayerBelow=playerBelow,
        DestroyHeight=workspace.FallenPartsDestroyHeight})
    local verifiedReach=state.AutoRanges.Range(state.Enabled and "Kill" or "Skill",data,state.SelectedSkill)
    if plan and plan.Radius>verifiedReach-(state.FarmAbove and .2 or 1) then plan=nil; reason="Outer position exceeds the learned attack reach" end
    if not plan then
        data.SkipUntil=now+8
        state.OffsetStatus=reason
        state.LastOffsetRejected={Target=mob.Name,Reason=reason,At=now}
        state.AutoOffsetTarget,state.AutoOffsetDestination=nil,nil
        if state.FollowTarget==mob then state.FollowTarget=nil end
        return nil
    end
    local playerHealth=character:FindFirstChild("Entity")
    playerHealth=playerHealth and playerHealth:FindFirstChild("Health")
    if activeOffsetMob~=mob or not offsetSample or offsetSample.Key~=key then
        activeOffsetMob=mob
        offsetSample={Offset=plan.Offset,Key=key,Requests=data.OffsetRequests or 0,At=now,
            SafeSince=now,PlayerHealth=playerHealth and playerHealth.Value,OwnDamage=state.ReadOwnDamage(data.Health),Misses=0,Confirmed=false}
        state.OffsetStatus="Source outer reach · checking clearance"
    end
    if math.abs(plan.Offset-offsetSample.Offset)>.75 then
        offsetSample.SafeSince=now; offsetSample.Confirmed=false; offsetSample.Offset=plan.Offset
    end
    if now-offsetSample.At>=1.2 then
        local requests=data.OffsetRequests or 0
        local contribution=state.ReadOwnDamage(data.Health)
        local damageConfirmed=contribution~=nil and contribution>(offsetSample.OwnDamage or 0)
        if requests>offsetSample.Requests and damageConfirmed then
            offsetSample.Misses=0
            local noDamage=now-(state.LastIncomingDamageAt or -math.huge)>=4
                and (not playerHealth or not offsetSample.PlayerHealth or playerHealth.Value>=offsetSample.PlayerHealth)
            if noDamage and now-offsetSample.SafeSince>=4 then
                offsetSample.Confirmed=true
                state.OffsetStatus="Holding damage-free source position"
                local saved=(plan.Mode=="Above" and 1 or -1)*math.floor(math.abs(plan.Offset)*4+.5)/4
                if state.OffsetProfiles[key]~=saved and now-(data.LastProfileSaveAt or -math.huge)>=10 then
                    local count=0; for _ in pairs(state.OffsetProfiles) do count+=1 end
                    if count<32 or state.OffsetProfiles[key] then state.OffsetProfiles[key]=saved; data.LastProfileSaveAt=now; requestSave() end
                end
            else state.OffsetStatus="Checking damage and player health" end
        elseif requests-offsetSample.Requests>=3 and not state.SkillCastRunning and not state.Recovering
            and now>=state.LagPauseUntil and (not state.PingMs or state.PingMs<=500) then
            offsetSample.Misses+=1
            state.OffsetStatus="No damage · holding outer clearance"
            if offsetSample.Misses>=3 then
                data.SkipUntil=now+8
                state.FollowTarget=nil
                state.AutoOffsetTarget,state.AutoOffsetDestination=nil,nil
                return nil
            end
        end
        offsetSample.Requests,offsetSample.At=requests,now
        offsetSample.OwnDamage=contribution
        offsetSample.PlayerHealth=playerHealth and playerHealth.Value
    end
    state.OffsetDebug={Target=mob.Name,Mode=plan.Mode,Distance=math.abs(plan.Offset),Minimum=plan.Minimum,
        Radius=plan.Radius,Reach=plan.Reach,CenterCorrection=center.Y-mobRoot.Position.Y,
        BodyBelow=data.BodyBelow,BodyAbove=data.BodyAbove,MissWindows=offsetSample.Misses,Confirmed=offsetSample.Confirmed}
    state.AutoOffsetTarget,state.AutoOffsetDestination=mob,plan.Destination
    data.LastGroundedFarmDestination=plan.Destination
    state.SetTeleportOffset(plan.Offset)
    return plan.Offset
end

local function attackDeltaFor(data,root)
    if state.AutoRanges then return state.AutoRanges.Delta(data,root) end
    return data.Root.Position+Vector3.new(0,(root.Size.Y-data.Root.Size.Y)*.5,0)-root.Position
end
local function attackRadiusFor(mob)
    local data=getMobData(mob)
    if not data then return 20 end
    if state.AutoRanges then return state.AutoRanges.Range("Kill",data) end
    local size=data.Root.Size
    return math.min(120,math.max(size.X,size.Z)*.5+20)
end
local function pivotRoot(root, position)
    local character = root.Parent
    local facing=root.CFrame.LookVector*Vector3.new(1,0,1)
    if facing.Magnitude<.001 then facing=Vector3.new(0,0,-1) end
    local targetRoot=CFrame.lookAt(position,position+facing.Unit,Vector3.yAxis)
    character:PivotTo(targetRoot * root.CFrame:ToObjectSpace(character:GetPivot()))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end
stopMovement = function(message, keepPosition)
    local floatingRoot=state.ArenaFloat and state.ArenaFloat.Root
    if state.ArenaFloat then state.ArenaFloat.Release() end
    state.TravelHold=false
    state.TravelHoldPosition=nil
    if state.Recovering and not movementRoot then return end
    if characterPartConnection then characterPartConnection:Disconnect(); characterPartConnection = nil end
    local oldRoot, oldHumanoid = movementRoot, movementHumanoid
    if not oldRoot and floatingRoot then
        oldRoot=floatingRoot
        oldHumanoid=floatingRoot.Parent and floatingRoot.Parent:FindFirstChildOfClass("Humanoid")
    end
    local oldRotate, oldPlatform = previousAutoRotate, previousPlatformStand
    local oldPosition, oldOrientation, oldAttachment = positionAlign, orientationAlign, movementAttachment
    local oldCollisions = collisionParts
    collisionParts = {}
    local function cleanup()
        if oldPosition then oldPosition:Destroy() end
        if oldOrientation then oldOrientation:Destroy() end
        if oldAttachment then oldAttachment:Destroy() end
        for part, value in pairs(oldCollisions) do if part.Parent then part.CanCollide = value end end
        if oldHumanoid and oldHumanoid.Parent then
            oldHumanoid.AutoRotate = oldRotate~=false
            oldHumanoid.PlatformStand = oldPlatform==true
            if oldHumanoid.Health > 0 and not oldPlatform then oldHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
        if oldRoot and oldRoot.Parent then oldRoot.AssemblyLinearVelocity = Vector3.zero end
        state.Recovering = false
    end
    local surface
    if not keepPosition and oldRoot and oldRoot.Parent and (oldPosition or floatingRoot) and oldHumanoid and oldHumanoid.Health > 0 then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { oldRoot.Parent, workspace:FindFirstChild("Mobs") or oldRoot.Parent }
        params.RespectCanCollide = true
        local floor = workspace:Raycast(oldRoot.Position + Vector3.new(0, 35, 0), Vector3.new(0, -70, 0), params)
        local exitY = floor and floor.Position.Y + oldHumanoid.HipHeight + oldRoot.Size.Y / 2 + 1.5 or lastSurfaceY
        if exitY and math.abs(oldRoot.Position.Y - exitY) > 1 then surface = Vector3.new(oldRoot.Position.X, exitY, oldRoot.Position.Z) end
    end
    if surface and not oldPosition then pivotRoot(oldRoot,surface);surface=nil end
    if surface then
        state.Recovering = true
        oldPosition.Enabled = true
        oldPosition.Position = surface
        pivotRoot(oldRoot, surface)
        local exitCollisionConnection = RunService.Stepped:Connect(function()
            for part in pairs(oldCollisions) do if part.Parent then part.CanCollide = false end end
        end)
        env.SB2FarmRecoveryUntil = os.clock() + 0.3
        task.delay(0.3, function()
            exitCollisionConnection:Disconnect()
            cleanup()
            if state.Running then movementStatus(state.LastFarmStopReason or message or "Stopped · character controls restored") end
        end)
    else
        cleanup()
    end
    movementRoot, movementHumanoid, previousAutoRotate, previousPlatformStand = nil, nil, nil, nil
    movementAttachment, positionAlign, orientationAlign = nil, nil, nil
    lastTeleportPosition, teleportTarget = nil, nil
    correctionStrikes, correctionTarget, holdPaused = 0, nil, false
    state.Exploring, state.LastExploreDestination = false, nil
    state.Moving = false
    if message then movementStatus(state.Recovering and "Returning above ground…" or message) end
end
do
    local make=(function()
-- BEGIN BUNDLED FARM NOCLIP
-- END BUNDLED FARM NOCLIP
    end)()
    state.FarmNoclip=make({Player=player,Pulse=RunService.Stepped,
        Enabled=function()return state.Running and state.AutoFarm and not state.StopEverything and not state.ModeratorBlocking end})
end
function state.SetAutoFarm(enabled, reason)
    if state.StopEverything and enabled==true then return false end
    if (enabled == true) == state.AutoFarm then return end
    state.LastAutoFarmChange={Enabled=enabled==true,Reason=reason or "API",At=os.clock(),Line=debug.info(2,"l")}
    if state.AutoFarm and enabled ~= true then state.ProtectionUntil = os.clock() + 8 end
    state.AutoFarm = enabled == true
    state.FarmTargetLock=nil
    if state.AutoFarm then state.LastFarmStopReason = nil end
    state.LastMovementError = nil
    farmToggle.Text = state.AutoFarm and "Auto farm  ·  ON" or "Auto farm  ·  OFF"
    farmToggle.BackgroundColor3 = state.AutoFarm and Color3.fromRGB(114, 88, 229) or Color3.fromRGB(45, 48, 63)
    stopMovement(state.AutoFarm and "Searching for the nearest living mob" or "Auto farm is off")
    state.FollowTarget = nil
    activeOffsetMob, offsetSample = nil, nil
    state.AutoOffsetTarget = nil
    nextTargetRefresh = 0
    nextMovementUpdate = 0
    targetMissingSince, nextAcquisition = nil, 0
    if state.AutoFarm and state.SetEnabled then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:Move(Vector3.zero, false) end
    end
    if state.FarmNoclip then state.FarmNoclip.Update()end
    requestSave()
end
function state.SetFarmRange(range)
    if type(range) ~= "number" or range ~= range then range = state.FarmRange end
    state.FarmRange = math.huge
    state.FollowTarget = nil
    nextTargetRefresh = 0
    movementStatus("Detection range updated")
    nextMovementUpdate = 0
    requestSave()
end
bind(farmToggle.Activated, function() state.SetAutoFarm(not state.AutoFarm,"UI toggle") end)
state.SetAutoFarm(false)
refreshMobIndex()
function state.SetBossOnly(on)
    state.BossOnly=on==true
    state.FarmTargetLock=nil;state.FollowTarget=nil;state.FarmPriorityScanAt=0
    nextAcquisition=0
    requestSave()
end
local function validMob(mob, mobs)
    if state.ModeratorBlocking or state.AutoTradeBusy then return nil end
    if not mob or mob.Parent ~= mobs then return nil end
    if state.AutoFarm and state.BossOnly and targetPriority.Rank(mob)>2 then return nil end
    if state.AccountProgression and (state.ProgressionPhase~="Fighting" or state.ProgressionEquipping
        or mob~=state.ProgressionBossMob)then return nil end
    local data = getMobData(mob)
    if state.MultiSpotAnchor and data and not (state.AutoFarm and targetPriority.Rank(mob)<=2) and not (state.MultiSpotEncounter and state.MultiSpotEncounter[mob]) and (data.Root.Position-state.MultiSpotAnchor).Magnitude>220 then return nil end
    if data and data.Health.Value > 0 and (not data.HitLives or data.HitLives.Value>0) and os.clock()>=(data.SkipUntil or 0) and not data.Entity:FindFirstChild("Immortal") then return data.Root end
    return nil
end
function state.IsFarmEnemyAlive()
    if not state.AutoFarm then return false end
    local mob=state.FarmTargetLock or state.FollowTarget
    if not mob or mob.Parent~=refreshMobIndex()then return false end
    local data=getMobData(mob)
    return not data or (data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0))
end
-- Share one paced, position-independent boss choice across movement and arena rotation.
function state.GetFarmPriorityTarget(now)
    if not state.AutoFarm or state.Running==false or state.AccountProgression or state.StopEverything or state.SafeModePanic or state.AutomationTeleporting or state.ModeratorBlocking or state.AutoTradeBusy then return nil end
    local mobs=refreshMobIndex()
    if not mobs then return nil end
    if state.CreditController and state.CreditCheck then
        local focus=state.CreditController.FarmTarget(nil,trackedMobs,function(mob)return validMob(mob,mobs)end,targetPriority.FarmLess)
        if focus then return focus end
    end
    local cached=state.FarmPriorityTarget
    if now<(state.FarmPriorityScanAt or 0)and cached and validMob(cached,mobs)then return cached end
    if now<(state.FarmPriorityScanAt or 0)and not cached then return nil end
    state.FarmPriorityScanAt=now+.15
    local best
    for mob in pairs(trackedMobs)do
        if targetPriority.Rank(mob)<=2 and validMob(mob,mobs)
            and (not best or targetPriority.FarmLess(mob,best))then best=mob end
    end
    if state.IsFarmEnemyAlive()then
        local locked=state.FarmTargetLock or state.FollowTarget
        if targetPriority.Rank(locked)<=2 and (not best or targetPriority.Rank(locked)<=targetPriority.Rank(best))then best=locked end
    end
    -- A temporary invulnerability/streaming gap is not a kill and must not
    -- downgrade an already observed main boss to a mini-boss or normal mob.
    if cached and cached.Parent==mobs and targetPriority.Rank(cached)<=2 then
        local data=getMobData(cached)
        if (not data or (data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0)))
            and (not best or targetPriority.Rank(cached)<targetPriority.Rank(best))then best=cached end
    end
    state.FarmPriorityTarget=best
    return best
end
function state.IsAttackingEnemy()
    if not state.Running or state.StopEverything or state.SafeModePanic or state.TravelBusy or state.MultiSpotOwnsTravel or state.Dodging
        or state.Recovering or state.ProtectionRetreating then return false end
    local stamp=state.LastEnemyAttackAt
    if not stamp or os.clock()-stamp>.8 then return false end
    local kind=state.LastEnemyAttackKind
    if not ((kind=="Normal" and state.Enabled) or (kind=="Skill" and state.SkillAura)) then return false end
    local mob=state.LastEnemyAttackTarget
    if not validMob(mob,indexedMobFolder) then return false end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local entity=character:FindFirstChild("Entity")
    local health=entity and entity:FindFirstChild("Health")
    if not health or health.Value<=0 then return false end
    local data=getMobData(mob)
    local range=kind=="Normal" and attackRadiusFor(mob) or state.AutoRanges.Range("Skill",data,state.LastEnemyAttackSkill)
    return attackDeltaFor(data,root).Magnitude<=range
end
local function pauseHold(message)
    if movementRoot and movementRoot.Parent and positionAlign and not holdPaused then positionAlign.Position = movementRoot.Position end
    holdPaused = true
    movementStatus(message)
end
local function clearStaleFarmControllers(root)
    for _,child in ipairs(root:GetChildren())do
        if (child.Name=="SB2FarmPosition"and child:IsA("AlignPosition"))
            or (child.Name=="SB2FarmOrientation"and child:IsA("AlignOrientation"))
            or (child.Name=="SB2FarmAttachment"and child:IsA("Attachment"))then child:Destroy()end
    end
end
local function ensureMovementController(character, root, humanoid, destination)
    if state.ArenaFloat and state.ArenaFloat.Root then state.ArenaFloat.Release() end
    if movementRoot and positionAlign and positionAlign.Parent then return end
    clearStaleFarmControllers(root)
    movementRoot, movementHumanoid = root, humanoid
    previousAutoRotate, previousPlatformStand = humanoid.AutoRotate, humanoid.PlatformStand
    humanoid.AutoRotate = false
    humanoid.PlatformStand = false
    humanoid.Sit = false
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    local function trackPart(part)
        if part:IsA("BasePart") then
            if collisionParts[part] == nil then
                local original=state.FarmNoclip and state.FarmNoclip.Original(part)
                if original==nil then original=part.CanCollide end
                collisionParts[part]=original
            end
            part.CanCollide = false
        end
    end
    for _, part in ipairs(character:QueryDescendants("BasePart")) do trackPart(part) end
    characterPartConnection = character.DescendantAdded:Connect(trackPart)
    movementAttachment = create("Attachment", { Name = "SB2FarmAttachment" }, root)
    positionAlign = create("AlignPosition", {
        Name = "SB2FarmPosition", Mode = Enum.PositionAlignmentMode.OneAttachment,
        Attachment0 = movementAttachment, Position = destination, ApplyAtCenterOfMass = true,
        MaxForce = math.max(1, root.AssemblyMass) * workspace.Gravity * 8,
        MaxVelocity = 60, Responsiveness = 40, RigidityEnabled = false,
    }, root)
    orientationAlign = create("AlignOrientation", {
        Name = "SB2FarmOrientation", Mode = Enum.OrientationAlignmentMode.OneAttachment,
        Attachment0 = movementAttachment, CFrame = state.UprightController.Rotation(root.CFrame),
        MaxTorque = math.max(1, root.AssemblyMass) * 10000, MaxAngularVelocity = 20,
        Responsiveness = 40, RigidityEnabled = true,
    }, root)
    state.Moving = true
end

state.UprightController=(function()
-- BEGIN BUNDLED UPRIGHT
-- END BUNDLED UPRIGHT
end)()({State=state,Player=player,
    Controlled=function() return state.Running and (state.AutoFarm or state.TravelBusy or state.TravelHold or state.Dodging) end,
    Orientation=function() return orientationAlign end,
})

do
    local create=(function()
-- BEGIN BUNDLED BOSS DODGE
-- END BUNDLED BOSS DODGE
    end)()
    local enemy=services:FindFirstChild("EnemySkills")
    local enemySkills=enemy and enemy:FindFirstChild("Skills")
    local waveSkills=enemySkills and enemySkills:FindFirstChild("Wave Defense")
    local bosses=waveSkills and waveSkills:FindFirstChild("Bosses")
    local projectiles={}
    for _,entry in ipairs({{"Nythrane, the Hollow Flame","PurpleFireyOrb","Burning",2.5,0},{"Vaelith, the Riftborn","RiftDetonation","Zap",1,8}}) do
        local boss=bosses and bosses:FindFirstChild(entry[1]); local skill=boss and boss:FindFirstChild(entry[2])
        local template=skill and skill:FindFirstChild("Part")
        if template and template:IsA("BasePart") then projectiles[#projectiles+1]={BossName=entry[1],Name=entry[2],Template=template,Marker=entry[3],Radius=math.max(entry[5],math.max(template.Size.X,template.Size.Y,template.Size.Z)*.5*entry[4])} end
    end
    local replicate=ReplicatedStorage:FindFirstChild("ReplicateSkill")
    state.BossDodge=create({State=state,Workspace=workspace,Collection=game:GetService("CollectionService"),
        Projectiles=projectiles,Replicate=replicate and replicate.OnClientEvent})
end
do
    local make=(function()
-- BEGIN BUNDLED ATHEON DODGE
-- END BUNDLED ATHEON DODGE
    end)()
    local enemy=services:FindFirstChild("EnemySkills")
    local native=state.NativeEnemySkills or (enemy and require(enemy))
    state.AtheonDodgeController=make({State=state,Native=native or {RiggedEnemies={}},
        Collection=game:GetService("CollectionService"),Warnings=state.BossDodge,
        FireAssets=function(skill)
            local result={}
            local a,b=skill.SurfacePosition,skill.FocusPosition
            if not a or not b then error("Dash path unavailable") end
            local flat=Vector3.new(1,0,1)
            local line=(b-a)*flat;local length=line:Dot(line)
            local name=skill.IsCorrupted and "CorruptedFlames" or "Flames"
            for _,part in ipairs(workspace:QueryDescendants("#Flames,#CorruptedFlames")) do
                if part.Name==name and part:IsA("BasePart") then
                    local delta=(part.Position-a)*flat
                    local alpha=length>.01 and math.clamp(delta:Dot(line)/length,0,1) or 0
                    if (delta-line*alpha).Magnitude<=(tonumber(skill.Width) or 50)+32 then
                        result[#result+1]=part;if #result>=8 then break end
                    end
                end
            end
            return result
        end,
        Grounded=function(boss)
            local data=getMobData(boss)
            if not data then return false end
            local _,airborne=state.GroundFollow.Resolve(boss,data,os.clock())
            return not airborne
        end,
        Position=function(boss)
            local root=boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
            return root and root.Position
        end,
        Bosses=function()
            local list={}
            local mobs=workspace:FindFirstChild("Mobs")
            if mobs then
                for _,name in ipairs({"Atheon","Corrupted Atheon"}) do
                    local boss=mobs:FindFirstChild(name)
                    local entity=boss and boss:FindFirstChild("Entity")
                    local health=entity and entity:FindFirstChild("Health")
                    if health and health.Value>0 then list[#list+1]=boss end
                end
            end
            return list
        end,
        Valid=function(point)return point.Y>workspace.FallenPartsDestroyHeight+35 and point.Magnitude<1000000 end})
end
local waveDodge = (function()
-- BEGIN BUNDLED WAVE DODGE
-- END BUNDLED WAVE DODGE
end)()({
    State = state,
    BossDodge = state.BossDodge,
    AtheonDodge = state.AtheonDodgeController,
    Hold = function(destination)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then return end
        if movementRoot and movementRoot ~= root then stopMovement(nil, true) end
        ensureMovementController(character, root, humanoid, destination)
        positionAlign.Enabled, orientationAlign.Enabled = true, true
        positionAlign.Position = destination
        if (root.Position-destination).Magnitude > 1.25 then pivotRoot(root, destination); state.TeleportsSent+=1 end
    end,
    Release = function()
        teleportTarget, correctionTarget = nil, nil
        correctionStrikes = 0
        nextMovementUpdate,nextAcquisition=0,0
        state.LastDodgeFinishedAt=os.clock()
        state.DodgeReturnPending=state.AutoFarm
        if state.WakeSkillAura then state.WakeSkillAura() end
        state.OffsetGraceUntil = os.clock()+0.6
        if not state.AutoFarm then
            if state.MultiSpot and state.MultiSpotAnchor and state.FinishMultiSpotArrival then
                state.FinishMultiSpotArrival()
            elseif state.TravelHold and state.TravelHoldPosition then
                local character=player.Character; local root=character and character:FindFirstChild("HumanoidRootPart"); local humanoid=character and character:FindFirstChildOfClass("Humanoid")
                if root and humanoid then ensureMovementController(character,root,humanoid,state.TravelHoldPosition); positionAlign.Position=state.TravelHoldPosition; pivotRoot(root,state.TravelHoldPosition) end
            else stopMovement("Dodge complete",true) end
        end
    end,
    Status = function(message)
        state.DodgeStatus = message
    end,
})
state.WaveDodge = waveDodge
function state.SetAutoDodge(enabled)
    if state.StopEverything and enabled==true then return false end
    state.AutoDodge = enabled == true
    dodgeToggle.Text = state.AutoDodge and "Auto dodge · ON" or "Auto dodge · OFF"
    dodgeToggle.BackgroundColor3 = state.AutoDodge and Color3.fromRGB(91,72,164) or Color3.fromRGB(45,48,63)
    requestSave()
end
bind(dodgeToggle.Activated, function() state.SetAutoDodge(not state.AutoDodge) end)
state.SetAutoDodge(restore.AutoDodge)

do
    local oldZoom = player.CameraMaxZoomDistance
    local restoringZoom = false
    local function applyZoom()
        if restoringZoom or state.StopEverything or not state.Running then return end
        if player.CameraMaxZoomDistance < 1000000 then player.CameraMaxZoomDistance=1000000 end
    end
    applyZoom()
    bind(player:GetPropertyChangedSignal("CameraMaxZoomDistance"), applyZoom)
    local original = {}
    local excludedNames={Mobs=true,Characters=true,CharacterItems=true,HitEffects=true,WaveDefenseStuff=true,MobSpawnEffects=true}
    local excludedRoots={}
    for name in pairs(excludedNames)do excludedRoots[name]=workspace:FindFirstChild(name)end
    bind(workspace.ChildAdded,function(root)if excludedNames[root.Name]then excludedRoots[root.Name]=root end end)
    bind(workspace.ChildRemoved,function(root)if excludedRoots[root.Name]==root then excludedRoots[root.Name]=nil end end)
    local function mapPart(part)
        if state.StopEverything then return false end
        if not part:IsA("BasePart") then return false end
        if state.SkillVisuals and state.SkillVisuals.IsEffect(part) then return false end
        if player.Character and part:IsDescendantOf(player.Character) then return false end
        for _,root in pairs(excludedRoots)do
            if part:IsDescendantOf(root)then return false end
        end
        return not waveDodge.IsHazardPart(part)
    end
    state.ExcludeMapPart=function(part)
        if original[part]~=nil then part.LocalTransparencyModifier=original[part]; original[part]=nil end
    end
    local function applyPart(part)
        if not mapPart(part) then return end
        if state.TransparentMap and not state.StopEverything then
            if original[part]==nil then
                local value=part.LocalTransparencyModifier
                original[part]=math.abs(value-0.7)<0.0001 and 0 or value
            end
            part.LocalTransparencyModifier=0.7
        elseif original[part]~=nil then part.LocalTransparencyModifier=original[part]; original[part]=nil end
    end
    local scanGeneration=0
    function state.SetTransparentMap(enabled)
    if state.StopEverything and enabled==true then return false end
        state.TransparentMap=enabled==true
        scanGeneration+=1
        local generation=scanGeneration
        if state.TransparentMap then
            task.defer(function()
                local slice=os.clock()
                for _,part in ipairs(workspace:QueryDescendants("BasePart")) do
                    if generation~=scanGeneration or not state.Running then return end
                    if part.Parent then applyPart(part)end
                    if os.clock()-slice>=.001 then task.wait();slice=os.clock()end
                end
            end)
        end
        if not state.TransparentMap then
            for part,value in pairs(original) do if part.Parent then part.LocalTransparencyModifier=value end; original[part]=nil end
        end
        requestSave()
    end
    local pendingParts,queuedParts={},setmetatable({}, {__mode="k"})
    local pendingHead,pendingTail,streamWorker=1,0,false
    bind(workspace.DescendantAdded,function(part)
        if not state.TransparentMap or not part:IsA("BasePart")or queuedParts[part]then return end
        pendingTail+=1;pendingParts[pendingTail]=part;queuedParts[part]=true
        if streamWorker then return end
        streamWorker=true
        task.defer(function()
            while state.Running and not restoringZoom and pendingHead<=pendingTail do
                local deadline=os.clock()+.001
                local count=0
                while pendingHead<=pendingTail and count<48 and os.clock()<deadline do
                    local current=pendingParts[pendingHead];pendingParts[pendingHead]=nil;pendingHead+=1;queuedParts[current]=nil
                    if current.Parent and state.TransparentMap then pcall(applyPart,current)end
                    count+=1
                end
                task.wait()
            end
            table.clear(pendingParts);table.clear(queuedParts);pendingHead,pendingTail=1,0;streamWorker=false
        end)
    end)
    bind(workspace.DescendantRemoving,function(part)
        if original[part]~=nil then part.LocalTransparencyModifier=original[part]; original[part]=nil end
    end)
    state.RestoreWorldVisuals=function()
        scanGeneration+=1
        restoringZoom=true
        player.CameraMaxZoomDistance=oldZoom
        for part,value in pairs(original) do if part.Parent then part.LocalTransparencyModifier=value end end
    end
    local makeDeletion=(function()
-- BEGIN BUNDLED MAP DELETION
-- END BUNDLED MAP DELETION
    end)()
    state.MapDeletion=makeDeletion({State=state,Root=workspace,Players=Players,Now=os.clock,Defer=task.defer,Wait=task.wait,
        ClearTerrain=function()workspace.Terrain:Clear()end,
        Protected=function(part)return not mapPart(part)end})
    state.MapDeletion.Set(state.PerformanceBoosters["Delete map"]==true or state.PerformanceBoosters["Remove everything"]==true)
    local makeAnimations=(function()
-- BEGIN BUNDLED ANIMATION REMOVAL
-- END BUNDLED ANIMATION REMOVAL
    end)()
    state.AnimationRemoval=makeAnimations({State=state,Root=workspace})
    state.AnimationRemoval.Set(state.PerformanceBoosters["Remove animations"]==true or state.PerformanceBoosters["Remove everything"]==true)
    state.SetTransparentMap(restore.TransparentMap)
end

do
    local makeQueue=(function()
-- BEGIN BUNDLED INSTANCE QUEUE
-- END BUNDLED INSTANCE QUEUE
    end)()
    local create=(function()
-- BEGIN BUNDLED SKILL VISUALS
-- END BUNDLED SKILL VISUALS
    end)()
    state.VisualPendingQueue=makeQueue(8192)
    state.SkillVisuals=create({Queue=state.VisualPendingQueue,
        State=state,Services=services,Actions=Actions,SkillState=Skills,ExcludeMapPart=state.ExcludeMapPart,
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
local destinations = {}
local destinationsDirty=false
local function finitePoint(point)
    return typeof(point) == "Vector3" and point.X == point.X and point.Y == point.Y and point.Z == point.Z
        and math.abs(point.X) < 1000000 and math.abs(point.Y) < 1000000 and math.abs(point.Z) < 1000000
end
local function rememberDestination(id, name, kind, point)
    if not finitePoint(point) then return end
    local old=destinations[id]
    if old and old.Name==name and old.Kind==kind and (old.Position-point).Magnitude<.01 then return end
    destinations[id] = { Id = id, Name = name, Kind = kind, Position = point }
    destinationsDirty=true
end
-- Verified on the current Floor 7 map; independent of whether Frogazoid exists.
if game.PlaceId == 582198062 then
    rememberDestination("mob:Frogazoid", "Frogazoid", "Mini boss", Vector3.new(-154.811, 1214.301, -758.796))
end
-- Only user-created spots use a position file; built-in arenas stay in source.
if importedConfig and filePersistence then
    for id,areas in pairs(importedConfig.CustomSpots or {})do
        writefile(configFolder.."/custom-spots_"..id..".json",HttpService:JSONEncode({Version=1,PlaceId=tonumber(id),Areas=areas}))
    end
end
local customSpotPath=configFolder.."/custom-spots_"..tostring(game.PlaceId)..".json"
local lastCustomSpots
if filePersistence then
    pcall(function()
        if not isfile(customSpotPath)then return end
        local raw=readfile(customSpotPath)
        assert(#raw<=32768,"Custom spots file exceeds size limit")
        local data=HttpService:JSONDecode(raw)
        if data.Version~=1 or data.PlaceId~=game.PlaceId or type(data.Areas)~="table"then return end
        for index,area in ipairs(data.Areas)do
            if index>20 then break end
            if type(area.Id)=="string"and area.Id:sub(1,16)=="saved:multispot:"and type(area.Name)=="string"and type(area.Position)=="table"then
                local p=area.Position
                if type(p[1])=="number"and type(p[2])=="number"and type(p[3])=="number"then
                    rememberDestination(area.Id,area.Name,"Arena",Vector3.new(p[1],p[2],p[3]))
                end
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
    for id,area in pairs(destinations)do
        if id:sub(1,16)=="saved:multispot:"then
            local p=area.Position
            areas[#areas+1]={Id=id,Name=area.Name,Position={p.X,p.Y,p.Z}}
        end
    end
    if #areas==0 then return end
    table.sort(areas,function(a,b)return a.Id<b.Id end)
    local ok,reason=pcall(function()
        local raw=HttpService:JSONEncode({Version=1,PlaceId=game.PlaceId,Areas=areas})
        if raw~=lastCustomSpots then writefile(customSpotPath,raw);lastCustomSpots=raw end
    end)
    state.CustomSpotSaveError=not ok and tostring(reason)or nil
end
local function rankMob(mob)
    local priority=targetPriority.Rank(mob)
    return priority==1 and "Boss" or priority==2 and "Mini boss" or nil
end
local function discoverDestinations(onlyMobs)
    if workspace:FindFirstChild("WaveDefenseStuff") then
        local stage=tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        if state.DestinationEnvironment~=stage then
            for id in pairs(destinations) do if string.sub(id,1,4)=="mob:" or id=="wave:rift" then destinations[id]=nil; destinationsDirty=true end end
            state.DestinationEnvironment=stage
        end
        local marker=workspace.WaveDefenseStuff:FindFirstChild("RiftBossSpawn")
        if marker and string.find(string.lower(stage),"rift",1,true) then rememberDestination("wave:rift","Rift boss spawn","Boss",marker.Position) end
    end
    if not onlyMobs then
    local mapContainers = { workspace }
    for _, folderName in ipairs({ "Models", "OptimizedGame" }) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then mapContainers[#mapContainers + 1] = folder end
    end
    for _, models in ipairs(mapContainers) do
        for _, model in ipairs(models:GetChildren()) do
            if model:IsA("Model") or model:IsA("BasePart") then
                local key = string.lower((string.gsub(model.Name, "[^%w]", "")))
                local kind
                if key == "bossroom" or key == "bossarena" or key == "bossspawn" or key == "aspawnboss" then kind = "Boss"
                elseif key == "minibossroom" or key == "minibossarena" or key == "minibossspawn" or key == "aspawnminiboss" then kind = "Mini boss"
                elseif key == "entryroom" or key == "dungeonentrance" then kind = "Dungeon"
                elseif key == "exitteleportroom" or key == "exitportal" then kind = "Exit"
                elseif string.match(key, "^bigdungeonroom%d+$") then kind = "Dungeon" end
                if kind then
                    local displayName = model.Name == "BossRoom" and "Boss room" or model.Name
                    if key == "aspawnboss" then displayName = "Boss spawn area"
                    elseif key == "aspawnminiboss" then displayName = "Mini-boss spawn area" end
                    local room = string.match(key, "^bigdungeonroom(%d+)$")
                    if room then displayName = "Room " .. room end
                    rememberDestination("map:" .. model.Name, displayName, kind, model:GetPivot().Position)
                end
            end
        end
    end
    local checkpoints = workspace:FindFirstChild("CheckpointPortals")
    if checkpoints then
        local points = {}
        for _, model in ipairs(checkpoints:GetChildren()) do
            if model:IsA("Model") or model:IsA("BasePart") then points[#points + 1] = model:GetPivot().Position end
        end
        table.sort(points, function(a, b) if a.X ~= b.X then return a.X < b.X end; return a.Z < b.Z end)
        for index, point in ipairs(points) do rememberDestination("checkpoint:" .. index, "Checkpoint " .. index, "Checkpoint", point) end
    end
    local spawns = workspace:QueryDescendants("SpawnLocation")
    if #spawns > 0 then
        local total = Vector3.zero
        for _, spawn in ipairs(spawns) do total += spawn.Position end
        rememberDestination("spawn", "Floor spawn", "Spawn", total / #spawns)
    end
    end
    for mob in pairs(trackedMobs) do
        if mob.Parent then
            local kind, root = rankMob(mob), mob:FindFirstChild("HumanoidRootPart")
            if kind and root then
                local id = "mob:" .. mob.Name
                -- Keep the first observed spawn area instead of following a boss that chases players.
                if not destinations[id] or workspace:FindFirstChild("WaveDefenseStuff") then rememberDestination(id, mob.Name, kind, root.Position) end
            end
        end
    end
    state.FloorDestinations = destinations
    saveDestinations()
end
local floorName = "Floor " .. tostring(game.PlaceId)
pcall(function()
    for _, floor in ipairs(require(ReplicatedStorage.Database.Locations).floors) do
        if floor.PlaceId == game.PlaceId then floorName = floor.Name; break end
    end
end)
state.FloorName = floorName
function state.ReadAutomationEncounter(spot)
    local tracked=state.MultiSpotEncounter or {}
    state.MultiSpotEncounter=tracked
    local now=os.clock()
    local function scan()
        state.MultiSpotNextScan=now+1
        for mob in pairs(trackedMobs) do
            if mob.Parent and (not state.BossOnly or targetPriority.Rank(mob)<=2)then
                local data=getMobData(mob)
                local root=data and data.Root or mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart or mob:FindFirstChild("RootPart")
                if root and ((spot.EncounterNames and spot.EncounterNames[mob.Name]) or (root.Position-spot.Position).Magnitude<=220)
                    and (not data or (data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0))) then
                    tracked[mob]=true
                end
                if not data then state.MultiSpotNextScan=math.min(state.MultiSpotNextScan,now+.1) end
            end
        end
    end
    local function count()
        local alive,seen=0,false
        for mob in pairs(tracked) do
            if not mob.Parent then
                tracked[mob]=nil;seen=true
            else
            if not state.BossOnly or targetPriority.Rank(mob)<=2 then
                local data=getMobData(mob)
                -- Missing streamed health is not proof that a previously seen mob died.
                if not data or (data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0))then alive+=1
                else tracked[mob]=nil end
            seen=true
            end
            end
        end
        return alive,seen
    end
    local scanned=now>=(state.MultiSpotNextScan or 0)
    if scanned then scan() end
    local alive,seen=count()
    -- A cached zero must never authorize travel without checking for new adds.
    if alive==0 and not scanned then
        scan();local refreshed,observed=count();alive=refreshed;seen=seen or observed
    end
    return alive,seen
end
do
    local make=(function()
-- BEGIN BUNDLED RESPAWN SCHEDULE
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
    local existing=destinations[spot.DestinationId]
    if existing then
        if spot.MainBoss or spot.PositionLocked then rememberDestination(spot.DestinationId,existing.Name,spot.Kind,spot.Position)end
        if spot.DestinationId:sub(1,4)=="mob:" then existing.Name=spot.DestinationId:sub(5) end
        return true
    end
    rememberDestination(spot.DestinationId,spot.Name,spot.Kind,spot.Position)
    return true
end
travelHeading.Text = "TELEPORTS · " .. floorName
travelHeading.TextTruncate = Enum.TextTruncate.AtEnd

do
    local make=(function()
-- BEGIN BUNDLED ARENA TRAVEL
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
    if not state.AutoFarm or not state.MultiSpot or state.MultiSpotPriorityActive or not state.MultiSpotAnchor or state.StopEverything or state.SafeModePanic
        or state.TravelBusy or state.MultiSpotOwnsTravel or state.Dodging or state.Recovering then state.MultiSpotEmptySince=nil;return false end
    local spot=state.MultiSpotController and state.MultiSpotController.Current
    if not spot or state.ReadAutomationEncounter(spot)~=0 then state.MultiSpotEmptySince=nil;return false end
    if state.MultiSpotEmptyAnchor~=state.MultiSpotAnchor then
        state.MultiSpotEmptyAnchor=state.MultiSpotAnchor;state.MultiSpotEmptySince=nil
    end
    local now=os.clock()
    state.MultiSpotEmptySince=state.MultiSpotEmptySince or now
    if now-state.MultiSpotEmptySince<5 then return false end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or root.Anchored or not humanoid or humanoid.Health<=0 then return false end
    waveDodge.Idle(state.MultiSpotAnchor)
    return true
end
function state.TeleportToDestination(id,urgent,automatic)
    if state.SafeModePanic or state.StopEverything or state.TravelBusy or not state.Running then return false,"Another movement has priority" end
    discoverDestinations()
    local area=destinations[id]
    if not area then setTravelStatus("Area not located on this floor yet");return false,"Arena is not available" end
    state.TravelSerial=(state.TravelSerial or 0)+1
    local serial=state.TravelSerial
    state.TravelBusy=true;state.MultiSpotTravelPending=automatic==true
    state.TravelStartedAt=os.clock()
    state.LastTravelDestination=nil;state.LastTravelPosition=nil
    state.TravelError=nil
    setTravelOpen(false)
    -- Prevent continuous skills from taking a new lease before travel gets a turn.
    if automatic and state.CancelSkillAura then state.CancelSkillAura("Moving to next selected arena") end
    stopMovement("Travelling · farming will resume",true)
    task.spawn(function()
        state.TravelWorker=coroutine.running()
        local function current()return state.Running and not state.SafeModePanic and not state.StopEverything and state.TravelSerial==serial end
        local ok,message=pcall(function()
            local deadline=os.clock()+4
            while current() and (state.Recovering or state.SkillCastRunning) and os.clock()<deadline do task.wait(.05) end
            if not current() then return end
            assert(not state.Recovering and not state.SkillCastRunning,"Wait for the current movement or skill to finish")
            setTravelStatus("Loading "..area.Name.."...")
            local landing=state.ArenaTravel.Move(area.Position,automatic==true,current)
            if not current() then return end
            local destination=landing.Position
            state.LastTravelLanding={SourcePosition=area.Position,SurfaceY=landing.SurfaceY,Requested=destination,Actual=destination,Depth=landing.SurfaceY-destination.Y}
            state.LastTravelDestination=id;state.LastTravelPosition=destination
            state.MultiSpotLandingPosition=automatic and destination or nil
            state.TeleportsSent+=1
            state.TravelHold=automatic==true or not (state.AutoFarm and state.Enabled)
            state.TravelHoldPosition=state.TravelHold and destination or nil
            if area.Kind=="Boss" or area.Kind=="Mini boss" then
                state.TravelFocus={Kind=area.Kind,Name=id:sub(1,4)=="mob:" and area.Name or nil,Until=os.clock()+8}
                state.FollowTarget=nil
            end
            setTravelStatus("Arrived: "..area.Name.." · 20 studs below position")
            if automatic and state.MultiSpotController and state.MultiSpotController.Current then
                local _,seen=state.ReadAutomationEncounter(state.MultiSpotController.Current)
                if seen then state.MultiSpotController.EncounterSeen=true end
            end
            lastSurfaceY=landing.SurfaceY+4
        end)
        if state.TravelSerial~=serial then return end
        if not ok then stopMovement("Travel will retry",true);state.TravelError=tostring(message);setTravelStatus(state.TravelError) end
        state.TravelBusy=false;state.MultiSpotTravelPending=false;state.TravelStartedAt=nil;state.TravelWorker=nil
        if ok and automatic and state.MultiSpotOwnsTravel and state.MultiSpotController then
            local confirmed,reason=pcall(state.MultiSpotController.Update,state.FarmClock())
            if not confirmed then state.MultiSpotController.Pause(tostring(reason)) end
        end
    end)
    return true
end
local function refreshTravelChoices()
    discoverDestinations()
    for _, child in ipairs(travelList:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
    local choices, hasMini = {}, false
    local order = { Boss = 1, ["Mini boss"] = 2, Spawn = 3, Checkpoint = 4, Dungeon = 5, Exit = 6 }
    for _, area in pairs(destinations) do choices[#choices + 1] = area; if area.Kind == "Mini boss" then hasMini = true end end
    table.sort(choices, function(a, b) local x,y=order[a.Kind] or 7,order[b.Kind] or 7; if x ~= y then return x < y end; return a.Name < b.Name end)
    local function option(text, index, callback)
        local button = create("TextButton", {
            Name = "Destination" .. index, Text = text, Font = Enum.Font.Gotham, TextSize = 11,
            Size = UDim2.new(1, -4, 0, 30), LayoutOrder = index, BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(41, 44, 59), TextColor3 = Color3.fromRGB(226, 229, 243),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, travelList)
        corner(button, 6)
        button.Activated:Connect(callback)
    end
    for index, area in ipairs(choices) do
        option(area.Kind .. " · " .. area.Name, index, function() state.TeleportToDestination(area.Id) end)
    end
    if not hasMini then
        option("Mini boss · area not discovered yet", 100, function() setTravelStatus("Visit the mini-boss area once, then save it below") end)
        option("Save current spot as mini-boss area", 101, function()state.SaveCurrentMiniBossArea()end)
    end
end
function state.SaveCurrentMiniBossArea()
    if state.StopEverything then return false end
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then rememberDestination("saved:mini", "Saved mini-boss area", "Mini boss", root.Position); saveDestinations(); refreshTravelChoices(); setTravelStatus("Mini-boss area saved for " .. floorName) end
end
function state.SaveMultiSpot()
    if state.StopEverything or state.TravelBusy or state.AutomationTeleporting then return false end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local point=root.Position
    local surface=waveDodge.FloorY(point)
    if type(surface)=="number"then point=Vector3.new(point.X,surface,point.Z)end
    if not finitePoint(point)then return false end
    local count=0
    for id in pairs(destinations)do if id:sub(1,16)=="saved:multispot:"then count+=1 end end
    if count>=20 then state.MultiSpotStatus="Saved spot limit reached (20 per floor)";return false end
    local id="saved:multispot:"..HttpService:GenerateGUID(false)
    rememberDestination(id,"Saved Spot "..(count+1),"Arena",point)
    state.FloorDestinations=destinations
    saveDestinations()
    if state.AutomationCatalog then state.AutomationCatalog.AddCurrent(destinations,game.PlaceId);state.AutomationCatalog.Sort()end
    state.MultiSpotStatus="Saved Spot "..(count+1).." saved · select it in arenas"
    if state.RefreshAutomationUI then state.RefreshAutomationUI()end
    return true
end
state.RefreshTeleportDestinations = refreshTravelChoices
bind(travelDropdown.Activated, function()
    if state.StopEverything or state.TravelBusy then return end
    if not travelList.Visible then refreshTravelChoices() end
    skillList.Visible = false
    setTravelOpen(not travelList.Visible)
end)
refreshTravelChoices()
local nextAreaDiscovery = 0

local nextExploreAt, exploreAngle = 0, 0
local exploredCenters = {}
local function freshExplorePoint(position)
    for _, center in ipairs(exploredCenters) do
        local delta = (position - center) * Vector3.new(1, 0, 1)
        if delta:Dot(delta) < 420 * 420 then return false end
    end
    return true
end
local function exploreEmptyArea(character, root, humanoid, now)
    if now < nextExploreAt then movementStatus("Exploring · waiting for the new area to load"); return end
    local destination, hint
    local best = 1500 * 1500
    for mob in pairs(trackedMobs) do
        local mobRoot = validMob(mob, indexedMobFolder)
        if mobRoot then
            local delta = (mobRoot.Position - root.Position) * Vector3.new(1, 0, 1)
            local distance = delta:Dot(delta)
            if distance > 540 * 540 and distance < best and freshExplorePoint(mobRoot.Position) and mobRoot.Position.Y > workspace.FallenPartsDestroyHeight + 60 then
                best = distance
                destination = mobRoot.Position + Vector3.new(0, state.TeleportOffset, 0)
                hint = mob
            end
        end
    end
    if hint then
        local hintRoot = getMobRoot(hint)
        if hintRoot then
            local offset = state.ResolveAutoOffset(hint)
            if not offset then return end
            destination = state.AutoOffsetDestination or hintRoot.Position + Vector3.new(0, offset, 0)
        end
    end
    if not destination then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { character, indexedMobFolder or character, workspace:FindFirstChild("Characters") or character }
        params.RespectCanCollide = true
        params.IgnoreWater = false
        for index = 1, 12 do
            local angle = exploreAngle + (index - 1) * math.pi / 6
            local point = root.Position + Vector3.new(math.cos(angle) * 560, 0, math.sin(angle) * 560)
            local floor = workspace:Raycast(point + Vector3.new(0, 400, 0), Vector3.new(0, -900, 0), params)
            if floor and floor.Normal.Y >= 0.65 and floor.Material ~= Enum.Material.Water and floor.Position.Y > workspace.FallenPartsDestroyHeight + 60 and freshExplorePoint(floor.Position) then
                destination = floor.Position + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 1.5, 0)
                exploreAngle = angle + 2.399963
                break
            end
        end
    end
    if not destination then nextExploreAt = now + 2; movementStatus("Exploring paused · no safe destination found"); return end
    exploredCenters[#exploredCenters + 1] = root.Position
    if #exploredCenters > 8 then table.remove(exploredCenters, 1) end
    ensureMovementController(character, root, humanoid, destination)
    positionAlign.Position = destination
    positionAlign.Enabled, orientationAlign.Enabled = true, true
    pivotRoot(root, destination)
    teleportTarget, correctionTarget = nil, nil
    correctionStrikes = 0
    lastTeleportTime, lastTeleportPosition = now, destination
    state.OffsetGraceUntil = now + 1
    state.FollowTarget = hint
    state.Exploring = true
    state.LastExploreDestination = destination
    state.ExploreConfirmAt = now + 0.6
    state.ExploreHops += 1
    state.TeleportsSent += 1
    nextExploreAt = now + 4
    nextAcquisition = now + (hint and 0.25 or 0.75)
    targetMissingSince = now
    state.AttackingTarget = nil
    trackHealth(nil)
    movementStatus("Exploring · moved beyond the previous spawn area")
end

local function updateMovement(now)
    now=now or os.clock()
    if now < nextMovementUpdate then return end
    nextMovementUpdate = now + 0.08
    if not state.MovementOwnership.CanFarm(now)then return end
    if not state.AutoFarm then
        if state.Moving or state.TravelHold or (state.ArenaFloat and state.ArenaFloat.Root)then stopMovement("Manual controls restored")end
        return
    end
    state.TravelHold=false; state.TravelHoldPosition=nil
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local entity = character and character:FindFirstChild("Entity")
    local health = entity and entity:FindFirstChild("Health")
    local mobs = refreshMobIndex()
    if not root or not humanoid or humanoid.Health <= 0 or (health and health.Value <= 0) or not mobs then
        state.FollowTarget = nil
        stopMovement("Waiting for a living character")
        return
    end
    if root ~= movementRoot and movementRoot then stopMovement(); return end
    if state.Exploring and state.LastExploreDestination and now >= (state.ExploreConfirmAt or 0) then
        if (root.Position - state.LastExploreDestination).Magnitude > 18 then
            state.ExploreFailures = (state.ExploreFailures or 0) + 1
            if state.ExploreFailures >= 2 then state.FarmPauseUntil=os.clock()+1; state.ExploreFailures=0; state.FollowTarget=nil; pauseHold("Reacquiring after a corrected position"); return end
        else state.ExploreFailures = 0 end
        state.LastExploreDestination = nil
    end
    if (state.SkillCastRunning or Skills.usingSkill ~= "none") and not (state.SkillCastRunning and state.SuppressSkillMotion) then
        if positionAlign then positionAlign.Enabled = false end
        if orientationAlign then orientationAlign.Enabled = false end
        state.SkillMovementSuspended = true
        movementStatus("Casting " .. tostring(state.SelectedSkill))
        return
    end
    if state.SkillMovementSuspended then
        state.SkillMovementSuspended = false
        teleportTarget = nil
        state.OffsetGraceUntil = now + 0.5
    end
    if now < state.LagPauseUntil or (state.PingMs and state.PingMs > 500) then pauseHold("Paused in place · waiting for lag"); return end
    if root.Anchored or humanoid.SeatPart then stopMovement("Paused · character cannot move"); return end
    if character:GetAttribute("Disabled") then pauseHold("Paused in place · character disabled"); return end
    if holdPaused then
        holdPaused = false
        teleportTarget = nil
        state.OffsetGraceUntil = now + 0.5
    end
    local targetRoot=validMob(state.FollowTarget,mobs)
    if targetRoot and (targetRoot.Position-root.Position).Magnitude>state.FarmRange+math.abs(state.TeleportOffset)+4 then targetRoot=nil end
    if now>=nextAcquisition and (not state.FarmCoordination or state.FarmCoordination.Ready("target"))then
        nextAcquisition=now+0.15
        local locked=state.FarmTargetLock
        if state.FarmLockArena~=state.MultiSpotAnchor or state.FarmLockProgression~=state.ProgressionBossMob then locked=nil end
        if locked and locked.Parent==mobs then
            local data=getMobData(locked)
            -- Missing streamed data, invulnerability or a rejected offset is
            -- not a confirmed kill. Wait for this enemy instead of retargeting.
            if data and (data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0))then locked=nil end
        else locked=nil end
        if not state.AccountProgression and state.CreditController then
            locked=state.CreditController.FarmTarget(locked,trackedMobs,function(mob)return validMob(mob,mobs)end,targetPriority.FarmLess)
        end
        if locked and not state.AccountProgression and state.GetFarmPriorityTarget then
            local priority=state.GetFarmPriorityTarget(now)
            if priority and targetPriority.Rank(priority)<targetPriority.Rank(locked)then locked=priority end
        end
        if locked then
            state.FarmTargetLock=locked
            state.FarmLockArena=state.MultiSpotAnchor;state.FarmLockProgression=state.ProgressionBossMob
            state.FollowTarget=locked
            targetRoot=validMob(locked,mobs)
            state.TargetPriority=targetPriority.Rank(locked)
        else
        local preferred=targetRoot and state.FollowTarget or nil
        local best=preferred
        state.TargetScans+=1
        for mob in pairs(trackedMobs) do
            local mobRoot=validMob(mob,mobs)
            if mobRoot and (mobRoot.Position-root.Position).Magnitude<=state.FarmRange then
                if not best or targetPriority.FarmLess(mob,best) then best=mob end
            end
        end
        state.FollowTarget=best
        targetRoot=best and validMob(best,mobs)
        state.TargetPriority=best and targetPriority.Rank(best) or nil
        state.FarmTargetLock=best
        state.FarmLockArena=state.MultiSpotAnchor
        state.FarmLockProgression=state.ProgressionBossMob
        end
    end
    if not targetRoot then
        if state.AccountProgression and state.ProgressionAnchor then
            state.FollowTarget=nil;waveDodge.Idle(state.ProgressionAnchor)
            movementStatus("Account Progression · waiting for the main boss");return
        end
        if state.MultiSpot and state.MultiSpotAnchor then
            state.FollowTarget=nil
            if not state.HoldMultiSpotIdle() then waveDodge.Idle() end
            movementStatus("Multi Spot · waiting for selected arena mobs");return
        end
        state.AutoOffsetTarget,state.AutoOffsetDestination = nil,nil
        activeOffsetMob, offsetSample = nil, nil
        targetMissingSince = targetMissingSince or now
        if now - targetMissingSince > 0.9 then
            waveDodge.Idle()
            movementStatus("No loaded enemy · unlimited detection · idle -20")
        else waveDodge.Idle(); movementStatus("Waiting below the map · 20 studs") end
        return
    end
    state.MultiSpotEmptySince=nil
    targetMissingSince = nil
    state.IdleBelowMap = false
    state.Exploring = false
    state.LastExploreDestination = nil
    if correctionTarget ~= state.FollowTarget then correctionTarget = state.FollowTarget; correctionStrikes = 0 end
    if state.FarmCoordination and not state.DodgeReturnPending and not state.FarmCoordination.Ready("move")then return end
    local autoOffset = state.ResolveAutoOffset(state.FollowTarget)
    if not autoOffset or not state.AutoFarm or state.TravelBusy then return end
    local destination = state.AutoOffsetDestination or targetRoot.Position + Vector3.new(0, autoOffset, 0)
    lastSurfaceY = targetRoot.Position.Y + 3
    if destination.Y <= workspace.FallenPartsDestroyHeight + 30 then stopMovement("Paused · destination is too low"); return end
    if teleportTarget == state.FollowTarget and positionAlign and now > (state.OffsetGraceUntil or 0) and now - lastTeleportTime > 0.2 then
        local errorDistance = (root.Position - positionAlign.Position).Magnitude
        local tolerance = math.max(5, math.min(12, targetRoot.AssemblyLinearVelocity.Magnitude * 0.25 + 3))
        if errorDistance > tolerance and now - correctionWindow > 0.35 then
            if now - correctionWindow > 2.5 then correctionStrikes = 0 end
            correctionStrikes += 1
            correctionWindow = now
            state.TeleportCorrections = (state.TeleportCorrections or 0) + 1
            if correctionStrikes >= 3 then
                state.FarmPauseUntil = os.clock()+1
                correctionStrikes = 0
                state.FollowTarget = nil
                pauseHold("Reacquiring after position corrections")
                return
            end
            teleportTarget = nil
        elseif errorDistance < 2 and now - correctionWindow > 2.5 then correctionStrikes = 0 end
    end
    ensureMovementController(character, root, humanoid, destination)
    positionAlign.Position = destination
    positionAlign.Enabled = true
    orientationAlign.Enabled = true
    local changedTarget = teleportTarget ~= state.FollowTarget
    if changedTarget or (now - lastTeleportTime >= state.TeleportInterval and (destination - root.Position).Magnitude > 3.5) then
        pivotRoot(root, destination)
        if changedTarget then state.OffsetGraceUntil = now + 0.35 end
        teleportTarget = state.FollowTarget
        lastTeleportTime, lastTeleportPosition = now, destination
        state.TeleportsSent += 1
        if state.DodgeReturnPending then
            state.LastDodgeReturnDelay=os.clock()-(state.LastDodgeFinishedAt or os.clock())
            state.DodgeReturnPending=false
        end
    end
    if now >= nextMovementStatusUpdate or changedTarget then
        nextMovementStatusUpdate = now + 0.2
        movementStatus(state.FixedFarmPosition and "Suspended Unborn · fixed arena position +10 studs"or string.format("Auto offset %.1f %s %s", math.abs(state.TeleportOffset),state.OffsetMode=="Above" and "above" or "below",state.FollowTarget.Name))
    end
end

do
    local make=(function()
-- BEGIN BUNDLED AURA TOUCH
-- END BUNDLED AURA TOUCH
    end)()
    state.AuraTouch=make({Active=function()return state.Running and not state.StopEverything and (state.Enabled or state.SkillAura or state.CreditCheck)end,
        Items=function()
            local items=workspace:FindFirstChild("CharacterItems")
            return items and items:FindFirstChild(tostring(player.UserId))
        end})
end

