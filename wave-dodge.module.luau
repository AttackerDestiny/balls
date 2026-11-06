-- Challenge-floor controller: event observation, geometry, and movement are separate phases.
return function(ctx)
    local state=ctx.State
    local player=game.Players.LocalPlayer
    local api={Active=false,Seen={},History={},Moves=0,RockChanges=0}
    local eventNames={"Lava","Tempest","Blackout","Horde","Rift","Wisp","Meme","Bob"}
    local flat=Vector3.new(1,0,1)
    local closed=false
    local timing={UpdateAt=0,ScanAt=0,LastMove=0,EvadeUntil=0}
    local terrain={Environment=nil,Floor=nil,Refuge=nil,RefugeUntil=0}
    local bob={Until=0,Depth=0,Point=nil,Environment=nil,PlanAt=0}
    local lava={Rocks={},Current=nil}
    local strikes={}
    local event,lastEvent,lastHealth
    local path="SB2Codex/wave-tests_"..player.UserId..".json"
    local audit=getgenv().SB2WaveDodgeAudit
    if not audit then
        audit={Seen={}}
        pcall(function()
            if not isfile(path)then return end
            local text=readfile(path)
            if #text>=65536 then return end
            local value=game:GetService("HttpService"):JSONDecode(text)
            if value.Version==1 and type(value.Seen)=="table"then audit.Seen=value.Seen end
        end)
        getgenv().SB2WaveDodgeAudit=audit
    end
    api.Seen=audit.Seen
    local function persist()
        pcall(function()
            if not isfolder("SB2Codex")then makefolder("SB2Codex")end
            writefile(path,game:GetService("HttpService"):JSONEncode({Version=1,Seen=api.Seen}))
        end)
    end
    local function horizontal(a,b)local delta=(a-b)*flat;return delta:Dot(delta)end
    local function environment()return tostring(workspace:GetAttribute("WaveDefenseEnvironment")or "")end
    local function detect()
        local text=(tostring(workspace:GetAttribute("WaveDefenseArea")or "").." "..environment().." "..tostring(workspace:GetAttribute("SpecialWave")or "")):lower()
        if text:find("darkness",1,true)then return "Blackout"end
        for _,name in ipairs(eventNames)do if text:find(name:lower(),1,true)then return name end end
    end
    local function bounds()
        local container=workspace:FindFirstChild("WaveDefenseStuff")
        return container and container:FindFirstChild("LavaHazardRegion"),container and container:FindFirstChild("WaveDefenseOrigin")
    end
    local function actors(part)
        if player.Character and part:IsDescendantOf(player.Character)then return true end
        for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects"})do
            local folder=workspace:FindFirstChild(name)
            if folder and part:IsDescendantOf(folder)then return true end
        end
        return false
    end
    local function halfSize(part)
        local cf,size=part.CFrame,part.Size
        local x=math.abs(cf.RightVector.X)*size.X+math.abs(cf.UpVector.X)*size.Y+math.abs(cf.LookVector.X)*size.Z
        local y=math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z
        local z=math.abs(cf.RightVector.Z)*size.X+math.abs(cf.UpVector.Z)*size.Y+math.abs(cf.LookVector.Z)*size.Z
        return Vector3.new(x,y,z)/2
    end
    local function exclusions(extra)
        local result={}
        for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","WaveDefenseStuff"})do
            local object=workspace:FindFirstChild(name)
            if object then result[#result+1]=object end
        end
        if player.Character then result[#result+1]=player.Character end
        for _,name in ipairs(extra or {})do local object=workspace:FindFirstChild(name);if object then result[#result+1]=object end end
        return result
    end
    function api.FloorY(point)
        local _,origin=bounds()
        local env=environment()
        if terrain.Environment~=env then terrain.Environment=env;terrain.Floor=nil;terrain.Refuge=nil end
        local offset=math.abs(state.TeleportOffset or 20)
        local reference=origin and origin.Position.Y or point.Y+(state.OffsetMode=="Above"and 32 or math.max(32,offset))
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true;params.FilterDescendantsInstances=exclusions()
        local hit=workspace:Raycast(Vector3.new(point.X,reference+8,point.Z),Vector3.new(0,-math.max(180,offset+160),0),params)
        if hit and hit.Normal.Y>.6 then terrain.Floor=hit.Position.Y end
        if not hit and state.PerformanceBoosters and (state.PerformanceBoosters["Delete map"]or state.PerformanceBoosters["Remove everything"])then return point.Y+20 end
        return terrain.Floor or reference
    end
    function api.BlackoutPoint(point)
        local env=environment();local now=os.clock()
        if terrain.Refuge and terrain.Environment==env and now<terrain.RefugeUntil then return terrain.Refuge end
        local _,origin=bounds()
        local center=origin and origin.Position or point
        local y=origin and origin.Position.Y or api.FloorY(point)
        local minimum=workspace.FallenPartsDestroyHeight+35
        local ignored=exclusions({"ActiveLavaHazard","PillarSpawns"})
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
        local from=Vector3.new(center.X,y+64,center.Z)
        local bottom
        for _=1,12 do
            if from.Y<=minimum then break end
            params.FilterDescendantsInstances=ignored
            local hit=workspace:Raycast(from,Vector3.new(0,minimum-from.Y,0),params)
            if not hit then break end
            local part=hit.Instance
            if not part or not part:IsA("BasePart")then return nil end
            ignored[#ignored+1]=part
            local under=part.Position.Y-halfSize(part).Y
            if part.Anchored and part.CanCollide and not actors(part)then bottom=math.min(bottom or under,under)end
            from=Vector3.new(center.X,math.min(hit.Position.Y,under)-.5,center.Z)
        end
        if not bottom or bottom-20<=minimum then return nil end
        terrain.Environment=env;terrain.Refuge=Vector3.new(center.X,bottom-20,center.Z);terrain.RefugeUntil=now+1
        state.BlackoutMapBottom=bottom;state.BlackoutShelter=terrain.Refuge
        return terrain.Refuge
    end
    local function classify(part,now)
        if state.StopEverything or not part:IsA("BasePart")or actors(part)then return end
        local region,origin=bounds()
        if not origin or horizontal(part.Position,origin.Position)>202500 then return end
        local kind=detect();local extents=halfSize(part)
        if kind=="Tempest"then
            local color=part.Color
            local purple=color.B>.45 and color.R>.3 and color.G<math.max(color.R,color.B)*.8
            local named=part.Name:lower()=="vfx"and part.Size.Y>100 and part.Size.X<35 and part.Size.Z<35
            if not ((part.Material==Enum.Material.Neon and purple and extents.X>1 and extents.Z>1)or named)then return end
            if not strikes[part]then strikes[part]={First=now};if event then event.Warnings+=1 end end
            strikes[part].Last=now;part.LocalTransparencyModifier=0
        elseif kind=="Lava"then
            local container=workspace:FindFirstChild("ActiveLavaHazard")or workspace:FindFirstChild("PillarSpawns")or part
            if not part:IsDescendantOf(container)then return end
            local name=part.Name:lower()
            local isPlatform=name:find("rock",1,true)or name:find("pillar",1,true)or name:find("platform",1,true)or part.Parent.Name=="PillarSpawns"
            local at=region and region.CFrame:PointToObjectSpace(part.Position)
            local inside=not region or (math.abs(at.X)<region.Size.X/2-8 and math.abs(at.Z)<region.Size.Z/2-8)
            local top=part.Position.Y+extents.Y
            if not inside or not isPlatform or top<=origin.Position.Y+2 or top>=origin.Position.Y+90 or extents.X<2 or extents.Z<2 or extents.X>=40 or extents.Z>=40 then return end
            if not lava.Rocks[part]then
                lava.Rocks[part]={First=now,StableAt=now,StablePosition=part.Position,StableSize=part.Size}
                if event then event.Rocks+=1 end
            end
            lava.Rocks[part].Last=now;lava.Rocks[part].HalfHeight=extents.Y;part.LocalTransparencyModifier=0
        end
    end
    local listener=workspace.DescendantAdded:Connect(function(part)
        if closed or not state.AutoDodge or not part:IsA("BasePart")or not detect()then return end
        classify(part,os.clock())
        task.delay(.12,function()if not closed and part.Parent and state.Running then classify(part,os.clock())end end)
    end)
    function api.IsHazardPart(part)
        return lava.Rocks[part]~=nil or strikes[part]~=nil or (ctx.BossDodge and ctx.BossDodge.IsHazardPart(part))
    end
    local function release()
        if api.Active then ctx.Release()end
        api.Active=false;state.Dodging=false
    end
    local function hold(point,reason,now)
        if point.Y<=workspace.FallenPartsDestroyHeight+30 then return false end
        api.Active=true;state.Dodging=true;ctx.Hold(point)
        if now-timing.LastMove>.2 and (not api.LastPosition or (api.LastPosition-point).Magnitude>2)then
            timing.LastMove=now;api.Moves+=1
            if event then event.Moves=(event.Moves or 0)+1 end
            if reason:sub(1,3)=="Bob"and api.Seen.Bob and api.Seen.Bob~=event then api.Seen.Bob.ResidualMoves=(api.Seen.Bob.ResidualMoves or 0)+1 end
            api.History[#api.History+1]={Kind=reason,Position=point,At=now,Wave=workspace:GetAttribute("Wave")}
            if #api.History>40 then table.remove(api.History,1)end
        end
        api.LastPosition=point;return true
    end
    local function danger(point)
        for part in pairs(strikes)do
            if not part.Parent then strikes[part]=nil
            else
                local extent=halfSize(part);local radius=math.max(10,extent.X,extent.Z)+4
                if horizontal(point,part.Position)<radius*radius then return true end
            end
        end
        return false
    end
    local function bobRefuge(point,now)
        local env=environment()
        if bob.Environment~=env then bob.Environment=env;bob.Point=nil;bob.PlanAt=0 end
        if bob.Point and now<bob.PlanAt then return bob.Point end
        bob.PlanAt=now+.25
        local shelter=api.BlackoutPoint(point)
        if not shelter then return nil end
        local y=math.max(workspace.FallenPartsDestroyHeight+36,shelter.Y-bob.Depth)
        if y>=shelter.Y+1 then return nil end
        local region,origin=bounds()
        if not region then return Vector3.new(shelter.X,y,shelter.Z)end
        if ctx.BossDodge then ctx.BossDodge.RefreshThreats()end
        local positions={};local mobs=workspace:FindFirstChild("Mobs")
        if mobs then for _,mob in ipairs(mobs:GetChildren())do
            local entity=mob:FindFirstChild("Entity");local hp=entity and entity:FindFirstChild("Health")
            local root=mob:FindFirstChild("HumanoidRootPart")or mob.PrimaryPart
            if root and hp and hp.Value>0 and #positions<64 then positions[#positions+1]=root.Position+root.AssemblyLinearVelocity*math.min(.3,(state.PingMs or 100)/1000+.1)end
        end end
        local function clearance(candidate)
            if ctx.BossDodge and ctx.BossDodge.IsThreatened(candidate)then return -1 end
            local score=math.huge
            for _,position in ipairs(positions)do score=math.min(score,(candidate-position).Magnitude)end
            return #positions>0 and score or math.sqrt(horizontal(candidate,origin and origin.Position or region.Position))
        end
        local chosen,score=nil,-1
        for _,x in ipairs({-.85,0,.85})do for _,z in ipairs({-.85,0,.85})do
            if x~=0 or z~=0 then
                local raw=region.CFrame:PointToWorldSpace(Vector3.new(region.Size.X*.5*x,0,region.Size.Z*.5*z))
                local candidate=Vector3.new(raw.X,y,raw.Z);local gap=clearance(candidate)
                if gap>score then chosen=candidate;score=gap end
            end
        end end
        if bob.Point then
            local current=Vector3.new(bob.Point.X,y,bob.Point.Z);local gap=clearance(current)
            if gap>=80 and gap>=score*.85 then chosen=current;score=gap end
        end
        bob.Point=chosen or Vector3.new(shelter.X,y,shelter.Z)
        state.BobRefuge=bob.Point;state.BobClearance=score;state.BobExtraDepth=bob.Depth
        return bob.Point
    end
    local function observeEvent(kind,health,now)
        if kind=="Bob"then bob.Until=now+5 end
        if kind=="Bob"and lastEvent~="Bob"then bob.Depth=40;bob.Point=nil;bob.PlanAt=0 end
        if kind~=lastEvent then
            if event then event.EndHealth=health and health.Value;event.Completed=true;event.Ended=now;persist()end
            release();lava.Rocks={};lava.Current=nil;strikes={};api.LastPosition=nil
            if kind then
                local old=api.Seen[kind]
                if old and old.JobId==game.JobId and old.Wave==workspace:GetAttribute("Wave")and not old.Completed then event=old
                else event={Name=kind,Wave=workspace:GetAttribute("Wave"),JobId=game.JobId,Count=(old and old.Count or 0)+1,Started=now,StartHealth=health and health.Value,Damage=0,Moves=0,Rocks=0,Warnings=0,Enabled=state.AutoDodge}end
                api.Seen[kind]=event;event.DodgeVersion=state.Version;persist()
            else event=nil end
            lastEvent=kind;timing.ScanAt=0
        end
        if health then
            if lastHealth and health.Value<lastHealth then
                local loss=lastHealth-health.Value
                if event then event.Damage+=loss end
                if now<bob.Until and api.Seen.Bob and api.Seen.Bob~=event then api.Seen.Bob.ResidualDamage=(api.Seen.Bob.ResidualDamage or 0)+loss end
                if now<bob.Until and health.Value>0 then bob.Depth=math.min(80,bob.Depth+20);bob.PlanAt=0 end
            end
            lastHealth=health.Value
        end
        state.WaveEventsSeen=api.Seen
    end
    local function scanHazards(kind,now)
        if (kind~="Lava"and kind~="Tempest")or now<timing.ScanAt then return end
        timing.ScanAt=now+3
        local container=kind=="Lava"and workspace:FindFirstChild("ActiveLavaHazard")or workspace
        if container then for _,part in ipairs(container:QueryDescendants("BasePart"))do classify(part,now)end end
        for part in pairs(lava.Rocks)do if not part.Parent then lava.Rocks[part]=nil end end
        for part in pairs(strikes)do if not part.Parent then strikes[part]=nil end end
    end
    local function lavaStep(root,humanoid,now,seen)
        local region,origin=bounds();local base=region and region.Position.Y or origin and origin.Position.Y or root.Position.Y
        local replacement,score
        for rock,entry in pairs(lava.Rocks)do
            if not rock.Parent then lava.Rocks[rock]=nil
            else
                local position,size,alpha=rock.Position,rock.Size,rock.Transparency
                entry.SurfaceTop=position.Y+(entry.HalfHeight or size.Y/2)
                if (position-entry.StablePosition).Magnitude>.035 or (size-entry.StableSize).Magnitude>.04 then entry.StableAt=now;entry.StablePosition=position;entry.StableSize=size end
                if entry.WasReady and (entry.SurfaceTop<base+2 or alpha>.1 or not rock.CanCollide or size.Magnitude<(entry.ReadySize or size.Magnitude)*.97)then entry.Dying=true end
                entry.Ready=position.Y>=base-.12 and position.Y<=base+.15 and rock.CanCollide and alpha<.08 and not entry.Dying and now-entry.StableAt>=.24
                if entry.Ready then
                    entry.WasReady=true;entry.ReadySize=math.max(entry.ReadySize or 0,size.Magnitude);entry.ReadySince=entry.ReadySince or now
                    local distance=horizontal(root.Position,position)
                    if rock~=lava.Current and (not score or distance<score)then replacement=rock;score=distance end
                end
            end
        end
        local current=lava.Current and lava.Rocks[lava.Current]
        local solid=current and lava.Current.Parent and lava.Current.CanCollide and lava.Current.Transparency<.9 and (current.SurfaceTop or 0)>base+.75
        local reason=not solid and "Current rock unavailable"or current.Dying and "Current rock disappearing"or "Initial rock"
        local switching=not solid or current.Dying or not current.WasReady
        local chosen=not switching and lava.Current or replacement or solid and lava.Current
        api.RockStatus={Current=lava.Current,ReadyReplacement=chosen~=lava.Current and chosen or nil,CurrentDying=current and current.Dying or false,Reason=reason}
        if chosen then
            if chosen~=lava.Current then
                lava.Current=chosen;api.RockChanges+=1
                api.LastRockSwitch={At=now,Reason=reason,ReplacementReady=lava.Rocks[chosen]and lava.Rocks[chosen].Ready,Position=chosen.Position}
                if event then event.RockChanges=(event.RockChanges or 0)+1 end
            end
            local extent=halfSize(chosen);local top=chosen.Position+Vector3.new(0,extent.Y,0)
            local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={chosen}
            local hit=workspace:Raycast(top+Vector3.new(0,4,0),Vector3.new(0,-extent.Y*2-8,0),params)
            if hit then top=hit.Position end
            hold(top+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.25,0),"Lava rock",now)
            ctx.Status("Lava · "..(lava.Rocks[chosen].Dying and "waiting for a settled rock"or "holding current rock").." · events "..seen.."/8")
        else
            local minimum=(origin and origin.Position.Y or root.Position.Y)+18
            local fallback=api.LastPosition and api.LastPosition.Y>=minimum and api.LastPosition or Vector3.new(root.Position.X,minimum,root.Position.Z)
            hold(fallback,"Waiting for rock",now);ctx.Status("Lava · waiting for a solid rock · events "..seen.."/8")
        end
        return true
    end
    local function tempestStep(root,humanoid,now,seen,desired)
        if not danger(root.Position)and not danger(desired)and now>=timing.EvadeUntil then return false end
        local candidate=api.LastPosition or root.Position
        if danger(candidate)then
            local region=bounds();candidate=nil
            for radius=10,60,5 do
                if candidate then break end
                local best,score
                for direction=1,16 do
                    local angle=direction*math.pi/8
                    local point=root.Position+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                    local localPoint=region and region.CFrame:PointToObjectSpace(point)
                    local inside=not region or math.abs(localPoint.X)<region.Size.X/2-10 and math.abs(localPoint.Z)<region.Size.Z/2-10
                    if inside and not danger(point)then local distance=horizontal(point,root.Position);if not score or distance<score then best=point;score=distance end end
                end
                if best then candidate=best;timing.EvadeUntil=now+.45 end
            end
        end
        if not candidate or danger(candidate)then return false end
        local elevation=api.FloorY(candidate)+(state.AutoFarm and -20 or humanoid.HipHeight+root.Size.Y/2+.25)
        hold(Vector3.new(candidate.X,elevation,candidate.Z),"Lightning evade",now)
        ctx.Status("Tempest · outside strike circles · events "..seen.."/8");return true
    end
    function api.Update()
        if closed or state.StopEverything then return false end
        local now=os.clock()
        if now<timing.UpdateAt then return api.Active end
        local fast=state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.Active and not state.NetworkPressureLimited
        timing.UpdateAt=now+(fast and 1/60 or .04)
        local kind=detect();api.Event=kind;state.OffsetMode=state.FarmAbove and "Above"or "Below"
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local entity=character and character:FindFirstChild("Entity");local health=entity and entity:FindFirstChild("Health")
        observeEvent(kind,health,now)
        local seen=0;for _ in pairs(api.Seen)do seen+=1 end
        local target=state.FollowTarget;local targetRoot=target and target:FindFirstChild("HumanoidRootPart")
        local desired=root and targetRoot and Vector3.new(targetRoot.Position.X,root.Position.Y,targetRoot.Position.Z)or root and root.Position
        if root and humanoid and health and health.Value>0 and not state.TravelBusy and ctx.AtheonDodge then
            local point,reason=ctx.AtheonDodge.Plan(root.Position,desired,api.FloorY)
            if point then hold(point,"Atheon evade: "..tostring(reason),now);ctx.Status("Atheon Dodge · "..tostring(reason));return true end
        end
        if not state.AutoDodge or not root or not humanoid or not health or health.Value<=0 or state.TravelBusy then
            release();ctx.Status((state.AutoDodge and "Ready"or "Off").." · events "..seen.."/8");return false
        end
        scanHazards(kind,now)
        if now<bob.Until and kind~="Blackout"and kind~="Lava"then
            local point=bobRefuge(root.Position,now)
            hold(point or root.Position,point and (kind=="Bob"and "Bob refuge"or "Bob residual-attack refuge")or "Bob waiting for map geometry",now)
            ctx.Status(kind=="Bob"and "Bob · keeping clear of enemies"or "Bob · waiting for residual attacks to end");return true
        end
        if kind~="Blackout"and kind~="Lava"and ctx.BossDodge and not(state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.NearBoss)then
            local region=bounds();local point,reason=ctx.BossDodge.Plan(root.Position,desired,region,kind=="Tempest"and danger or nil)
            if point then hold(point,"Boss evade: "..tostring(reason),now);ctx.Status("Boss attack · outside danger zone");return true end
            if ctx.BossDodge.Blocked then local shelter=api.BlackoutPoint(root.Position);if shelter then hold(shelter,"Boss evade below map bottom",now);return true end end
        end
        if kind=="Blackout"then
            local shelter=api.BlackoutPoint(root.Position)
            hold(shelter or root.Position,shelter and "Blackout below map bottom"or "Blackout waiting for map geometry",now)
            if shelter then state.IdleBelowMap=true;state.IdleAboveMap=false end
            ctx.Status(shelter and "Blackout · sheltering below map bottom"or "Blackout · waiting for map bottom geometry");return true
        end
        if kind=="Lava"then return lavaStep(root,humanoid,now,seen)end
        if kind=="Tempest"and tempestStep(root,humanoid,now,seen,desired)then return true end
        release();ctx.Status((kind and kind.." · watching"or "Ready").." · events "..seen.."/8");return false
    end
    function api.Idle(anchor)
        if state.StopEverything then return end
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local point=anchor or root.Position
        local floor=anchor and anchor.Y or api.FloorY(point)
        ctx.Hold(Vector3.new(point.X,floor-20,point.Z))
        state.IdleFloorY=floor;state.IdleBelowMap=true;state.IdleAboveMap=false
    end
    function api.Destroy()
        if closed then return end
        closed=true;persist();listener:Disconnect()
        if ctx.BossDodge then ctx.BossDodge.Destroy()end
        if ctx.AtheonDodge then ctx.AtheonDodge.Destroy()end
        release();table.clear(lava.Rocks);table.clear(strikes);lava.Current=nil;bob.Point=nil;terrain.Refuge=nil
    end
    return api
end
