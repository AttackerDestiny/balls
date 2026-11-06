return function(ctx)
    local state, player = ctx.State, game.Players.LocalPlayer
    local api = { Active = false, Seen = {}, History = {}, Moves = 0 }
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
    local lastArea
    local nextUpdate, lastMove = 0, 0
    local shelter=Vector3.new(10,-19,-5)
    local darknessShelter=Vector3.new(14,73,2)
    local cachedFloor, floorEnvironment, idleXZ
    local blackoutPoint,blackoutEnvironment,blackoutUntil=nil,nil,0
    local damageBefore, lastHealth, eventRecord
    local function horizontal(a, b)
        local d = (a - b) * Vector3.new(1, 0, 1)
        return d:Dot(d)
    end
    local function currentEvent()
        local a = tostring(workspace:GetAttribute("WaveDefenseArea") or "")
        local b = tostring(workspace:GetAttribute("WaveDefenseEnvironment") or "")
        local special=workspace:GetAttribute("SpecialWave")
        local text = string.lower(a .. " " .. b .. " " .. tostring(special or ""))
        if string.find(text,"darkness",1,true) then return "Blackout" end
        for _, name in ipairs(names) do if string.find(text, string.lower(name), 1, true) then return name end end
        if type(special)=="string" and special~="" then return special end
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
        if not hit and state.PerformanceBoosters and (state.PerformanceBoosters["Delete map"]or state.PerformanceBoosters["Remove everything"])then
            return point.Y+20 -- Missing deleted geometry must not accumulate vertical drift.
        end
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
    function api.IsHazardPart(part)
        return ctx.BossDodge and ctx.BossDodge.IsHazardPart(part)
    end
    local function requiresKills(area)
        local note=tostring(workspace:GetAttribute("CountdownNote") or ""):lower()
        if note:find("survive",1,true) then return false end
        if (tonumber(workspace:GetAttribute("WaveProgressLeft")) or 0)>0 then return true end
        if area=="Horde" or area=="Rift" or area=="Wisp" or area=="Meme" or area=="Bob" then return true end
        return area~="Lava" and area~="Tempest" and area~="Blackout"
            and (tonumber(workspace:GetAttribute("MobsLeft")) or 0)>0
    end
    local function darknessTarget(root,humanoid)
        if not state.AutoFarm or not (state.Enabled or state.SkillAura) or not ctx.Mobs then return end
        local orb=workspace:FindFirstChild("DarknerOrb")
        local part=orb and orb:FindFirstChild("Part")
        local light=part and part:FindFirstChildOfClass("PointLight")
        if not light or not light.Enabled or light.Range<=0 then return end
        local best,position,distance
        for mob in pairs(ctx.Mobs)do
            local data=ctx.MobData(mob)
            if data and data.Health.Value>0 and (not data.HitLives or data.HitLives.Value>0)
                and not data.Entity:FindFirstChild("Immortal") then
                local mobPosition=data.Root.Position
                local above=mobPosition+Vector3.new(0,(data.BodyAbove or data.Root.Size.Y/2)+humanoid.HipHeight+root.Size.Y/2+1,0)
                if (mobPosition-part.Position).Magnitude<light.Range and (above-part.Position).Magnitude<light.Range then
                    if mob==state.BlackoutTarget then return mob,above end
                    local gap=(mobPosition-root.Position).Magnitude
                    if not distance or gap<distance then best,position,distance=mob,above,gap end
                end
            end
        end
        return best,position
    end
    local function recordMove(kind, point)
        api.Moves+=1
        if eventRecord then eventRecord.Moves=(eventRecord.Moves or 0)+1 end
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
        if area~=lastArea then
            if eventRecord then eventRecord.EndHealth=health and health.Value; eventRecord.Completed=true; eventRecord.Ended=now; saveAudit() end
            if api.Active then ctx.Release() end
            api.Active, state.Dodging=false,false
            state.BlackoutTarget=nil
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
        end
        if health then
            if lastHealth and health.Value<lastHealth then
                if eventRecord then eventRecord.Damage+=lastHealth-health.Value end

            end
            lastHealth=health.Value
        end
        state.WaveEventsSeen=api.Seen
        local seen=0; for _ in pairs(api.Seen) do seen+=1 end
        if root and health and health.Value>0 and not state.TravelBusy and ctx.AeganatosDodge then
            local point,reason=ctx.AeganatosDodge.Plan(root.Position,state.AutoOffsetDestination or root.Position)
            if point then
                if state.SkillCastRunning and state.CancelSkillAura then state.CancelSkillAura("Aeganatos dodge has movement priority")end
                hold(point,"Aeganatos evade: "..tostring(reason),now)
                ctx.Status("Aeganatos Dodge · "..tostring(reason));return true
            end
        end
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
            state.BlackoutTarget=nil
            ctx.Status((state.AutoDodge and "Ready" or "Off").." · events "..seen.."/8")
            return false
        end
        local killObjective=area and requiresKills(area)
        if area and (area=="Blackout" or not killObjective) then
            local mob,above
            if area=="Blackout" and killObjective then mob,above=darknessTarget(root,humanoid) end
            state.BlackoutTarget=mob
            local point=above or (area=="Blackout" and darknessShelter or shelter)
            if hold(point,area.." shelter",now) then
                -- Keep the dodge hold in charge of position while allowing hits on this target.
                if mob and (root.Position-point).Magnitude<=2 then
                    state.FollowTarget=mob
                    state.Dodging=false
                end
                ctx.Status(area..(mob and " · attacking inside white light" or " · sheltering"))
                return true
            end
        end
        state.BlackoutTarget=nil
        if ctx.BossDodge and not (state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.NearBoss) then
            local region=bounds()
            local target=state.FollowTarget
            local tr=target and target:FindFirstChild("HumanoidRootPart")
            local desired=tr and Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z) or root.Position
            local point,reason=ctx.BossDodge.Plan(root.Position,desired,region)
            if point then
                hold(point,"Boss evade: "..tostring(reason),now)
                ctx.Status("Boss attack · outside danger zone")
                return true
            elseif ctx.BossDodge.Blocked then
                local fallback=api.BlackoutPoint(root.Position)
                if fallback then hold(fallback,"Boss evade below map bottom",now); return true end
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
        ctx.Hold(Vector3.new(point.X,floor-20,point.Z),true)
        state.IdleFloorY=floor
        state.IdleBelowMap=true
        state.IdleAboveMap=false
    end
    function api.Destroy()
        saveAudit()
        if ctx.BossDodge then ctx.BossDodge.Destroy() end
        if ctx.AtheonDodge then ctx.AtheonDodge.Destroy() end
        if ctx.AeganatosDodge then ctx.AeganatosDodge.Destroy()end
        if api.Active then ctx.Release() end
        api.Active=false
        state.BlackoutTarget=nil
        state.Dodging=false
    end
    return api
end
