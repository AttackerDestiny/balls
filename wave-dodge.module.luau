return function(ctx)
    local state, player = ctx.State, game.Players.LocalPlayer
    local api = { Active = false, Seen = {}, History = {}, Moves = 0, RockChanges = 0 }
    local names = { "Lava", "Tempest", "Blackout", "Horde", "Rift", "Wisp", "Meme", "Bob" }
    local logPath="SB2Codex/wave-tests_"..player.UserId..".json"
    local audit=getgenv().SB2WaveDodgeAudit
    if not audit then
        audit={Seen={}}
        pcall(function()
            if isfile(logPath) then
                local raw=readfile(logPath)
                if #raw<65536 then
                    local data=game:GetService("HttpService"):JSONDecode(raw)
                    if data.Version==1 and type(data.Seen)=="table" then audit.Seen=data.Seen end
                end
            end
        end)
        getgenv().SB2WaveDodgeAudit=audit
    end
    api.Seen=audit.Seen
    local function saveAudit()
        pcall(function()
            if not isfolder("SB2Codex") then makefolder("SB2Codex") end
            writefile(logPath,game:GetService("HttpService"):JSONEncode({Version=1,Seen=api.Seen}))
        end)
    end
    local rocks, strikes = {}, {}
    local lastArea, currentRock, rockSince, nextScan = nil, nil, 0, 0
    local nextUpdate, lastMove, holdUntil = 0, 0, 0
    local cachedFloor, floorEnvironment, idleXZ
    local blackoutPoint,blackoutEnvironment,blackoutUntil=nil,nil,0
    local bobUntil,bobDepth,nextBobPlan=0,0,0
    local bobPoint,bobEnvironment=nil,nil
    local damageBefore, lastHealth, eventRecord
    local function horizontal(a, b)
        local d = (a - b) * Vector3.new(1, 0, 1)
        return d:Dot(d)
    end
    local function currentEvent()
        local a = tostring(workspace:GetAttribute("WaveDefenseArea") or "")
        local b = tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        local text = string.lower(a .. " " .. b .. " " .. tostring(workspace:GetAttribute("SpecialWave") or ""))
        if string.find(text,"darkness",1,true) then return "Blackout" end
        for _, name in ipairs(names) do if string.find(text, string.lower(name), 1, true) then return name end end
        return nil
    end
    local function isActor(part)
        for _, name in ipairs({ "Mobs", "Characters", "CharacterItems", "HitEffects" }) do
            local f = workspace:FindFirstChild(name)
            if f and part:IsDescendantOf(f) then return true end
        end
        return player.Character and part:IsDescendantOf(player.Character)
    end
    local function extent(part)
        local cf, s = part.CFrame, part.Size
        return Vector3.new(
            math.abs(cf.RightVector.X)*s.X + math.abs(cf.UpVector.X)*s.Y + math.abs(cf.LookVector.X)*s.Z,
            math.abs(cf.RightVector.Y)*s.X + math.abs(cf.UpVector.Y)*s.Y + math.abs(cf.LookVector.Y)*s.Z,
            math.abs(cf.RightVector.Z)*s.X + math.abs(cf.UpVector.Z)*s.Y + math.abs(cf.LookVector.Z)*s.Z) / 2
    end
    local function bounds()
        local stuff = workspace:FindFirstChild("WaveDefenseStuff")
        return stuff and stuff:FindFirstChild("LavaHazardRegion"), stuff and stuff:FindFirstChild("WaveDefenseOrigin")
    end
    function api.FloorY(point)
        local region, origin = bounds()
        local environment = tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        if environment ~= floorEnvironment then cachedFloor, idleXZ, floorEnvironment = nil, nil, environment end
        local offset=math.abs(state.TeleportOffset or 20)
        local reference = origin and origin.Position.Y or point.Y + (state.OffsetMode=="Above" and 32 or math.max(32,offset))
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excluded = {}
        for _, n in ipairs({ "Mobs", "Characters", "CharacterItems", "WaveDefenseStuff" }) do
            local f=workspace:FindFirstChild(n); if f then excluded[#excluded+1]=f end
        end
        if player.Character then excluded[#excluded+1]=player.Character end
        params.FilterDescendantsInstances = excluded
        params.RespectCanCollide = true
        local hit=workspace:Raycast(Vector3.new(point.X,reference+8,point.Z),Vector3.new(0,-math.max(180,offset+160),0),params)
        if hit and hit.Normal.Y > 0.6 then cachedFloor = hit.Position.Y end
        return cachedFloor or reference
    end
    function api.BlackoutPoint(point)
        local environment=tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        if blackoutPoint and environment==blackoutEnvironment and os.clock()<blackoutUntil then return blackoutPoint end
        local _,origin=bounds()
        local center=origin and origin.Position or point
        local reference=origin and origin.Position.Y or api.FloorY(point)
        local minimum=workspace.FallenPartsDestroyHeight+35
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.RespectCanCollide=true
        local excluded={}
        for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","WaveDefenseStuff","ActiveLavaHazard","PillarSpawns"}) do
            local folder=workspace:FindFirstChild(name); if folder then excluded[#excluded+1]=folder end
        end
        if player.Character then excluded[#excluded+1]=player.Character end
        local cursor=Vector3.new(center.X,reference+64,center.Z)
        local bottom
        for _=1,12 do
            if cursor.Y<=minimum then break end
            params.FilterDescendantsInstances=excluded
            local hit=workspace:Raycast(cursor,Vector3.new(0,minimum-cursor.Y,0),params)
            if not hit then break end
            local part=hit.Instance
            if not part or not part:IsA("BasePart") then return nil end
            excluded[#excluded+1]=part
            local under=part.Position.Y-extent(part).Y
            if part.Anchored and part.CanCollide and not isActor(part) then bottom=math.min(bottom or under,under) end
            cursor=Vector3.new(center.X,math.min(hit.Position.Y,under)-.5,center.Z)
        end
        if not bottom or bottom-20<=minimum then return nil end
        blackoutPoint=Vector3.new(center.X,bottom-20,center.Z)
        blackoutEnvironment=environment; blackoutUntil=os.clock()+1
        state.BlackoutMapBottom=bottom; state.BlackoutShelter=blackoutPoint
        return blackoutPoint
    end
    local function bobRefuge(point,now)
        local environment=tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        if environment~=bobEnvironment then bobPoint=nil; nextBobPlan=0; bobEnvironment=environment end
        if bobPoint and now<nextBobPlan then return bobPoint end
        nextBobPlan=now+.25
        local shelter=api.BlackoutPoint(point)
        if not shelter then return nil end
        local y=math.max(workspace.FallenPartsDestroyHeight+36,shelter.Y-bobDepth)
        if y>=shelter.Y+1 then return nil end
        local region,origin=bounds()
        if not region then return Vector3.new(shelter.X,y,shelter.Z) end
        if ctx.BossDodge then ctx.BossDodge.RefreshThreats() end
        local enemies={}
        local mobs=workspace:FindFirstChild("Mobs")
        if mobs then for _,mob in ipairs(mobs:GetChildren()) do
            local entity=mob:FindFirstChild("Entity"); local hp=entity and entity:FindFirstChild("Health")
            local root=mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
            if root and hp and hp.Value>0 and #enemies<64 then enemies[#enemies+1]=root.Position+root.AssemblyLinearVelocity*math.min(.3,(state.PingMs or 100)/1000+.1) end
        end end
        local function clearance(p)
            if ctx.BossDodge and ctx.BossDodge.IsThreatened(p) then return -1 end
            local value=math.huge
            for _,enemy in ipairs(enemies) do value=math.min(value,(p-enemy).Magnitude) end
            if #enemies==0 then value=math.sqrt(horizontal(p,origin and origin.Position or region.Position)) end
            return value
        end
        local best,bestScore=nil,-1
        for _,x in ipairs({-.85,0,.85}) do for _,z in ipairs({-.85,0,.85}) do
            if x~=0 or z~=0 then
                local raw=region.CFrame:PointToWorldSpace(Vector3.new(region.Size.X*.5*x,0,region.Size.Z*.5*z))
                local p=Vector3.new(raw.X,y,raw.Z)
                local score=clearance(p)
                if score>bestScore then best,bestScore=p,score end
            end
        end end
        if bobPoint then
            local current=Vector3.new(bobPoint.X,y,bobPoint.Z)
            local score=clearance(current)
            if score>=80 and score>=bestScore*.85 then best,bestScore=current,score end
        end
        bobPoint=best or Vector3.new(shelter.X,y,shelter.Z)
        state.BobRefuge=bobPoint; state.BobClearance=bestScore; state.BobExtraDepth=bobDepth
        return bobPoint
    end
    local function classify(part, now)
        if state.StopEverything then return end
        if not part:IsA("BasePart") or isActor(part) then return end
        local region, origin = bounds()
        if not origin or horizontal(part.Position,origin.Position)>450*450 then return end
        local name = string.lower(part.Name)
        local area=currentEvent()
        if area == "Tempest" then
            local c, e = part.Color, extent(part)
            local purple = c.B > 0.45 and c.R > 0.3 and c.G < math.max(c.R,c.B)*0.8
            if (part.Material==Enum.Material.Neon and purple and e.X>1 and e.Z>1)
                or (name=="vfx" and part.Size.Y>100 and part.Size.X<35 and part.Size.Z<35) then
                if not strikes[part] then strikes[part]={ First=now, Last=now }; if eventRecord then eventRecord.Warnings+=1 end end
                strikes[part].Last=now
                part.LocalTransparencyModifier=0
            end
        elseif area=="Lava" and part:IsDescendantOf(workspace:FindFirstChild("ActiveLavaHazard") or workspace:FindFirstChild("PillarSpawns") or part) then
            local e=extent(part)
            local floor=origin.Position.Y
            local top=part.Position.Y+e.Y
            local rockName = string.find(name,"rock",1,true) or string.find(name,"pillar",1,true) or string.find(name,"platform",1,true)
            local inside = not region or (math.abs(region.CFrame:PointToObjectSpace(part.Position).X)<region.Size.X/2-8 and math.abs(region.CFrame:PointToObjectSpace(part.Position).Z)<region.Size.Z/2-8)
            if inside and top>floor+2 and top<floor+90 and e.X>=2 and e.Z>=2 and e.X<40 and e.Z<40 and (rockName or part.Parent.Name=="PillarSpawns") then
                if not rocks[part] then rocks[part]={First=now,Last=now,StableAt=now,StablePosition=part.Position,StableSize=part.Size,PeakY=part.Position.Y,LastY=part.Position.Y,LastAlpha=part.Transparency}; if eventRecord then eventRecord.Rocks+=1 end end
                rocks[part].Last=now
                rocks[part].HalfHeight=e.Y
                part.LocalTransparencyModifier=0
            end
        end
    end
    local added=workspace.DescendantAdded:Connect(function(part)
        if state.AutoDodge and part:IsA("BasePart") and currentEvent() then
            classify(part,os.clock())
            task.delay(0.12,function() if part.Parent and state.Running then classify(part,os.clock()) end end)
        end
    end)
    function api.IsHazardPart(part)
        return rocks[part]~=nil or strikes[part]~=nil or (ctx.BossDodge and ctx.BossDodge.IsHazardPart(part))
    end
    local function recordMove(kind, point)
        api.Moves+=1
        if eventRecord then eventRecord.Moves=(eventRecord.Moves or 0)+1 end
        if string.sub(kind,1,3)=="Bob" and api.Seen.Bob and api.Seen.Bob~=eventRecord then
            api.Seen.Bob.ResidualMoves=(api.Seen.Bob.ResidualMoves or 0)+1
        end
        if eventRecord then eventRecord.Moves+=1 end
        api.History[#api.History+1]={Kind=kind,Position=point,At=os.clock(),Wave=workspace:GetAttribute("Wave")}
        if #api.History>40 then table.remove(api.History,1) end
    end
    local function hold(point,kind,now)
        if point.Y<=workspace.FallenPartsDestroyHeight+30 then return false end
        api.Active, state.Dodging = true, true
        ctx.Hold(point)
        if now-lastMove>0.2 and (not api.LastPosition or (api.LastPosition-point).Magnitude>2) then recordMove(kind,point); lastMove=now end
        api.LastPosition=point
        return true
    end
    local function threatened(point)
        for part in pairs(strikes) do
            if part.Parent then
                local e=extent(part)
                local radius=math.max(10,e.X,e.Z)+4
                if horizontal(point,part.Position)<radius*radius then return true end
            end
        end
        return false
    end
    function api.Update()
        if state.StopEverything then return false end
        local now=os.clock()
        if now<nextUpdate then return api.Active end
        local fast=state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.Active and not state.NetworkPressureLimited
        nextUpdate=now+(fast and 1/60 or .04)
        local area=currentEvent()
        api.Event=area
        state.OffsetMode=state.FarmAbove and "Above" or "Below"
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local entity=character and character:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if area=="Bob" then bobUntil=now+5 end
        if area=="Bob" and lastArea~="Bob" then bobDepth=40; bobPoint=nil; nextBobPlan=0 end
        if area~=lastArea then
            if eventRecord then eventRecord.EndHealth=health and health.Value; eventRecord.Completed=true; eventRecord.Ended=now; saveAudit() end
            if api.Active then ctx.Release() end
            api.Active, state.Dodging=false,false
            rocks, strikes, currentRock={}, {}, nil
            api.LastPosition=nil
            if area then
                local old=api.Seen[area]
                if old and old.JobId==game.JobId and old.Wave==workspace:GetAttribute("Wave") and not old.Completed then eventRecord=old
                else eventRecord={Name=area,Wave=workspace:GetAttribute("Wave"),JobId=game.JobId,Count=(old and old.Count or 0)+1,Started=now,StartHealth=health and health.Value,Damage=0,Moves=0,Rocks=0,Warnings=0,Enabled=state.AutoDodge} end
                api.Seen[area]=eventRecord
                eventRecord.DodgeVersion=state.Version
                saveAudit()
            else eventRecord=nil end
            lastArea=area
            nextScan=0
        end
        if health then
            if lastHealth and health.Value<lastHealth then
                if eventRecord then eventRecord.Damage+=lastHealth-health.Value end
                if now<bobUntil and api.Seen.Bob and api.Seen.Bob~=eventRecord then
                    api.Seen.Bob.ResidualDamage=(api.Seen.Bob.ResidualDamage or 0)+lastHealth-health.Value
                end
                if now<bobUntil and health.Value>0 then bobDepth=math.min(80,bobDepth+20); nextBobPlan=0 end
            end
            lastHealth=health.Value
        end
        state.WaveEventsSeen=api.Seen
        local seen=0; for _ in pairs(api.Seen) do seen+=1 end
        if root and humanoid and health and health.Value>0 and not state.TravelBusy and ctx.AtheonDodge then
            local target=state.FollowTarget
            local tr=target and target:FindFirstChild("HumanoidRootPart")
            local desired=tr and Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z) or root.Position
            local point,reason=ctx.AtheonDodge.Plan(root.Position,desired,api.FloorY)
            if point then
                hold(point,"Atheon evade: "..tostring(reason),now)
                ctx.Status("Atheon Dodge · "..tostring(reason))
                return true
            end
        end
        if not state.AutoDodge or not root or not humanoid or not health or health.Value<=0 or state.TravelBusy then
            if api.Active then ctx.Release() end
            api.Active,state.Dodging=false,false
            ctx.Status((state.AutoDodge and "Ready" or "Off").." · events "..seen.."/8")
            return false
        end
        if area=="Lava" or area=="Tempest" then
            if now>=nextScan then
                nextScan=now+3
                local container=area=="Lava" and workspace:FindFirstChild("ActiveLavaHazard") or workspace
                if container then for _,part in ipairs(container:QueryDescendants("BasePart")) do classify(part,now) end end
                for part in pairs(rocks) do if not part.Parent then rocks[part]=nil end end
                for part in pairs(strikes) do if not part.Parent then strikes[part]=nil end end
            end
        end
        if now<bobUntil and area~="Blackout" and area~="Lava" then
            local point=bobRefuge(root.Position,now)
            if point then hold(point,area=="Bob" and "Bob refuge" or "Bob residual-attack refuge",now)
            else hold(root.Position,"Bob waiting for map geometry",now) end
            ctx.Status(area=="Bob" and "Bob · keeping clear of enemies" or "Bob · waiting for residual attacks to end")
            return true
        end
        if area~="Blackout" and area~="Lava" and ctx.BossDodge and not (state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.NearBoss) then
            local region=bounds()
            local target=state.FollowTarget
            local tr=target and target:FindFirstChild("HumanoidRootPart")
            local desired=tr and Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z) or root.Position
            local point,reason=ctx.BossDodge.Plan(root.Position,desired,region,area=="Tempest" and threatened or nil)
            if point then
                hold(point,"Boss evade: "..tostring(reason),now)
                ctx.Status("Boss attack · outside danger zone")
                return true
            elseif ctx.BossDodge.Blocked then
                local fallback=api.BlackoutPoint(root.Position)
                if fallback then hold(fallback,"Boss evade below map bottom",now); return true end
            end
        end
        if area=="Blackout" then
            local point=api.BlackoutPoint(root.Position)
            if point then
                hold(point,"Blackout below map bottom",now)
                state.IdleBelowMap=true; state.IdleAboveMap=false
                ctx.Status("Blackout · sheltering below map bottom")
            else
                hold(root.Position,"Blackout waiting for map geometry",now)
                ctx.Status("Blackout · waiting for map bottom geometry")
            end
            return true
        elseif area=="Lava" then
            local region,origin=bounds()
            local baseY=region and region.Position.Y or (origin and origin.Position.Y or root.Position.Y)
            local best,score
            for part,data in pairs(rocks) do
                if not part.Parent then rocks[part]=nil
                else
                    local position,size,alpha=part.Position,part.Size,part.Transparency
                    local atSurface=position.Y>=baseY-0.12 and position.Y<=baseY+0.15
                    data.SurfaceTop=position.Y+(data.HalfHeight or size.Y/2)
                    local moved=(position-data.StablePosition).Magnitude>0.035 or (size-data.StableSize).Magnitude>0.04
                    if moved then data.StableAt=now; data.StablePosition=position; data.StableSize=size end
                    if data.WasReady and (data.SurfaceTop<baseY+2 or alpha>0.1
                        or not part.CanCollide or size.Magnitude<(data.ReadySize or size.Magnitude)*0.97) then data.Dying=true end
                    data.Ready=atSurface and part.CanCollide and alpha<0.08 and not data.Dying and now-data.StableAt>=0.24
                    if data.Ready then
                        data.WasReady=true; data.ReadySize=math.max(data.ReadySize or 0,size.Magnitude)
                        data.ReadySince=data.ReadySince or now
                        local value=horizontal(root.Position,position)
                        if part~=currentRock and (not score or value<score) then best,score=part,value end
                    end
                    data.LastY,data.LastAlpha=position.Y,alpha
                end
            end
            local current= currentRock and rocks[currentRock]
            local currentSolid=current and currentRock.Parent and currentRock.CanCollide and currentRock.Transparency<0.9 and (current.SurfaceTop or 0)>baseY+0.75
            local switch=not currentSolid or current.Dying or not current.WasReady
            local reason=not currentSolid and "Current rock unavailable" or (current and current.Dying and "Current rock disappearing" or "Initial rock")
            if not switch then best=currentRock
            elseif not best and currentSolid then best=currentRock end
            api.RockStatus={Current=currentRock,ReadyReplacement=best~=currentRock and best or nil,CurrentDying=current and current.Dying or false,Reason=reason}
            if best then
                if best~=currentRock then
                    currentRock,rockSince=best,now; api.RockChanges+=1
                    api.LastRockSwitch={At=now,Reason=reason,ReplacementReady=rocks[best] and rocks[best].Ready,Position=best.Position}
                    if eventRecord then eventRecord.RockChanges=(eventRecord.RockChanges or 0)+1 end
                end
                local e=extent(best)
                local top=best.Position+Vector3.new(0,e.Y,0)
                local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={best}
                local hit=workspace:Raycast(top+Vector3.new(0,4,0),Vector3.new(0,-e.Y*2-8,0),params)
                if hit then top=hit.Position end
                hold(top+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+0.25,0),"Lava rock",now)
                ctx.Status("Lava · "..((rocks[best] and rocks[best].Dying) and "waiting for a settled rock" or "holding current rock").." · events "..seen.."/8")
                return true
            end
            -- Do not let auto farm drive into the floor while rocks are loading.
            local _,origin=bounds()
            local minimumY=(origin and origin.Position.Y or root.Position.Y)+18
            local fallback=api.LastPosition and api.LastPosition.Y>=minimumY and api.LastPosition or Vector3.new(root.Position.X,minimumY,root.Position.Z)
            hold(fallback,"Waiting for rock",now)
            ctx.Status("Lava · waiting for a solid rock · events "..seen.."/8")
            return true
        elseif area=="Tempest" then
            local target=state.FollowTarget
            local tr=target and target:FindFirstChild("HumanoidRootPart")
            local desired=tr and Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z) or root.Position
            if threatened(root.Position) or threatened(desired) or now<holdUntil then
                local point=api.LastPosition or root.Position
                if threatened(point) then
                    local best,score
                    local region,origin=bounds()
                    for radius=10,60,5 do
                        for i=1,16 do
                            local angle=i*math.pi/8
                            local p=root.Position+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                            local inArena=not region or (math.abs(region.CFrame:PointToObjectSpace(p).X)<region.Size.X/2-10 and math.abs(region.CFrame:PointToObjectSpace(p).Z)<region.Size.Z/2-10)
                            if inArena and not threatened(p) then local value=horizontal(p,root.Position); if not score or value<score then best,score=p,value end end
                        end
                        if best then break end
                    end
                    if best then point=best; holdUntil=now+0.45 end
                end
                if not threatened(point) then
                    point=Vector3.new(point.X,api.FloorY(point)+(state.AutoFarm and -20 or humanoid.HipHeight+root.Size.Y/2+0.25),point.Z)
                    hold(point,"Lightning evade",now)
                    ctx.Status("Tempest · outside strike circles · events "..seen.."/8")
                    return true
                end
            end
        end
        if api.Active then ctx.Release() end
        api.Active,state.Dodging=false,false
        ctx.Status((area and area.." · watching" or "Ready").." · events "..seen.."/8")
        return false
    end
    function api.Idle(anchor)
        if state.StopEverything then return end
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local point=anchor or root.Position
        local floor=anchor and anchor.Y or api.FloorY(point)
        ctx.Hold(Vector3.new(point.X,floor-20,point.Z))
        state.IdleFloorY=floor
        state.IdleBelowMap=true
        state.IdleAboveMap=false
    end
    function api.Destroy()
        saveAudit()
        added:Disconnect()
        if ctx.BossDodge then ctx.BossDodge.Destroy() end
        if ctx.AtheonDodge then ctx.AtheonDodge.Destroy() end
        if api.Active then ctx.Release() end
        api.Active=false
        state.Dodging=false
    end
    return api
end
