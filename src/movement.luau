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
-- END BUNDLED UPRIGHT
end)()({State=state,Player=player,
    Controlled=function() return state.Running and (state.AutoFarm or state.TravelBusy or state.TravelHold or state.Dodging) end,
    Orientation=function() return orientationAlign end,
})

do
    local buildWarnings=(function()
-- BEGIN BUNDLED BOSS DODGE
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
        local values={}
        if skill then
            local ok,native=pcall(require,skill)
            if ok and type(native)=="table"and type(native.Defaults)=="table"then
                for key,value in pairs(native.Defaults)do if type(value)=="number"then values[key]=value end end
            end
            for key,value in pairs(skill:GetAttributes())do if type(value)=="number"then values[key]=value end end
        end
        return values
    end
    local function finalWave()return game.PlaceId==78945654064532 and workspace:GetAttribute("Wave")==100 end
    local function origin()
        local mobs=workspace:FindFirstChild("Mobs")
        local boss=mobs and mobs:FindFirstChild(rubricatusName)
        return boss and boss:GetPivot().Position
    end
    local function pillarPart(part)
        if not finalWave()or not part:IsA("BasePart")then return false end
        local node=part
        while node and node~=workspace do
            local name=node.Name:lower()
            if name=="pillarspawns"or name:match("^pillar%d*$")then return true end
            node=node.Parent
        end
        return false
    end
    local makeCover=(function()
-- BEGIN BUNDLED RUBRICATUS COVER
-- END BUNDLED RUBRICATUS COVER
    end)()
    local cover=game.PlaceId==78945654064532 and makeCover({State=state,FinalWave=finalWave,Origin=origin,
        Replicate=events and events.OnClientEvent,
        Pillars=function()
            local result={}
            -- Search pillar containers only; never scan all arena descendants.
            for _,root in ipairs(workspace:GetChildren())do
                local name=root.Name:lower()
                if name=="pillarspawns"or name:match("^pillar%d*$")then
                    if root:IsA("BasePart")then result[#result+1]=root
                    else
                        for _,part in ipairs(root:QueryDescendants("BasePart"))do
                            result[#result+1]=part;if #result==32 then break end
                        end
                    end
                    if #result>=32 then break end
                end
            end
            return result
        end,
        Covered=function(part,from,to)
            local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
            params.RespectCanCollide=true;params.FilterDescendantsInstances={part}
            local hit=workspace:Raycast(from,to-from,params)
            return hit and hit.Instance==part
        end})or nil
    state.BossDodge=buildWarnings({State=state,Workspace=workspace,Collection=game:GetService("CollectionService"),
        Projectiles=projectiles,Replicate=events and events.OnClientEvent,
        FinalWave=game.PlaceId==78945654064532 and finalWave or nil,RubricatusCover=cover,PillarPart=pillarPart,
        RubricatusWave=attributes("RedLightningWave"),DiscRadius=attributes("RedLightningDiscs").Radius,
        LaserRadius=attributes("RedLightningLaser").Radius,
        RubricatusOrigin=origin})
end
do
    local createPlanner=(function()
-- BEGIN BUNDLED ATHEON DODGE
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
-- END BUNDLED WAVE DODGE
end)()({State=state,BossDodge=state.BossDodge,AtheonDodge=state.AtheonDodgeController,AeganatosDodge=state.AeganatosDodgeController,
    Replicate=game.PlaceId==78945654064532 and ReplicatedStorage:FindFirstChild("ReplicateSkill")and ReplicatedStorage.ReplicateSkill.OnClientEvent or nil,
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
    local excluded={Mobs=true,Characters=true,CharacterItems=true,HitEffects=true,WaveDefenseStuff=true,MobSpawnEffects=true,PillarSpawns=true}
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
-- END BUNDLED MAP DELETION
    end)()
    state.MapDeletion=makeDeletion({State=state,Root=workspace,Players=Players,Now=os.clock,Defer=task.defer,Wait=task.wait,
        ClearTerrain=function()workspace.Terrain:Clear()end,Protected=function(part)return not mapPart(part)end})
    local makeAnimations=(function()
-- BEGIN BUNDLED ANIMATION REMOVAL
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
-- END BUNDLED INSTANCE QUEUE
    end)()
    local create=(function()
-- BEGIN BUNDLED SKILL VISUALS
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
local customSpotPrefix=presetBook.SpotPrefix or "custom-spots_"
if importedConfig and filePersistence then
    for floor,areas in pairs(importedConfig.CustomSpots or {})do
        local path=configFolder.."/"..customSpotPrefix..floor..".json"
        if not presetBook.ActiveId or not isfile(path)then
            writefile(path,HttpService:JSONEncode({Version=1,PlaceId=tonumber(floor),Areas=areas}))
        end
    end
end
local customSpotPath=configFolder.."/"..customSpotPrefix..tostring(game.PlaceId)..".json"
local lastCustomSpots
local function loadCustomSpots()
    if not filePersistence then return end
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
loadCustomSpots()
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
    if presetBook.ActiveId then loadCustomSpots()end
    local count=0;for id in pairs(destinations)do if id:sub(1,16)=="saved:multispot:"then count+=1 end end
    if count>=20 then state.MultiSpotStatus="Saved spot limit reached (20 per floor)";return false end
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
-- END BUNDLED AURA TOUCH
    end)()
    state.AuraTouch=make({Active=function()return state.Running and not state.StopEverything and (state.Enabled or state.SkillAura or state.CreditCheck)end,
        Items=function()
            local items=workspace:FindFirstChild("CharacterItems")
            return items and items:FindFirstChild(tostring(player.UserId))
        end})
end
