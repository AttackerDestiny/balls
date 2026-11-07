-- Challenge-floor controller: event observation, geometry, and movement are separate phases.
return function(ctx)
    local state=ctx.State
    local player=game.Players.LocalPlayer
    local api={Active=false,Seen={},History={},Moves=0}
    local eventNames={"Lava","Tempest","Blackout","Horde","Rift","Wisp","Meme","Bob"}
    local flat=Vector3.new(1,0,1)
    local closed=false
    local timing={UpdateAt=0,ScanAt=0,LastMove=0,EvadeUntil=0}
    local terrain={Environment=nil,Floor=nil,Refuge=nil,RefugeUntil=0}
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
        local special=workspace:GetAttribute("SpecialWave");if type(special)=="string"and special~=""then return special end
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
    function api.IsHazardPart(part)return ctx.BossDodge and ctx.BossDodge.IsHazardPart(part)end
    local function release()
        if api.Active then ctx.Release()end
        api.Active=false;state.Dodging=false;state.BlackoutTarget=nil
    end
    local function hold(point,kind,now)
        if point.Y<=workspace.FallenPartsDestroyHeight+30 then return false end
        api.Active=true;state.Dodging=true;ctx.Hold(point)
        if now-timing.LastMove>.2 and (not api.LastPosition or (api.LastPosition-point).Magnitude>2)then
            timing.LastMove=now;api.Moves+=1
            if event then event.Moves=(event.Moves or 0)+1 end
            api.History[#api.History+1]={Kind=kind,Position=point,At=now,Wave=workspace:GetAttribute("Wave")}
            if #api.History>40 then table.remove(api.History,1)end
        end
        api.LastPosition=point;return true
    end
    local function observe(kind,health,now)
        if kind~=lastEvent then
            if event then event.EndHealth=health and health.Value;event.Completed=true;event.Ended=now;persist()end
            release();api.LastPosition=nil
            if kind then
                local previous=api.Seen[kind]
                if previous and previous.JobId==game.JobId and previous.Wave==workspace:GetAttribute("Wave")and not previous.Completed then event=previous
                else event={Name=kind,Wave=workspace:GetAttribute("Wave"),JobId=game.JobId,Count=(previous and previous.Count or 0)+1,Started=now,
                    StartHealth=health and health.Value,Damage=0,Moves=0,Rocks=0,Warnings=0,Enabled=state.AutoDodge}end
                api.Seen[kind]=event;event.DodgeVersion=state.Version;persist()
            else event=nil end
            lastEvent=kind
        end
        if health then
            if lastHealth and health.Value<lastHealth and event then event.Damage+=lastHealth-health.Value end
            lastHealth=health.Value
        end
        state.WaveEventsSeen=api.Seen
    end
    local function needsKills(kind)
        local note=tostring(workspace:GetAttribute("CountdownNote")or ""):lower()
        if note:find("survive",1,true)then return false end
        if (tonumber(workspace:GetAttribute("WaveProgressLeft"))or 0)>0 then return true end
        if kind=="Horde"or kind=="Rift"or kind=="Wisp"or kind=="Meme"or kind=="Bob"then return true end
        return kind~="Lava"and kind~="Tempest"and kind~="Blackout"and (tonumber(workspace:GetAttribute("MobsLeft"))or 0)>0
    end
    local function whiteLightTarget(root,humanoid,now)
        local orb=workspace:FindFirstChild("DarknerOrb");local part=orb and orb:FindFirstChild("Part")
        local light=part and part:FindFirstChildOfClass("PointLight")
        if not light then return nil,Vector3.new(14,73,2) end
        local center=part.Position
        local duration=tonumber(orb:GetAttribute("LightDuration"))or light.Range
        local radius=light.Enabled and math.max(0,math.min(duration,light.Range))or 0
        local clearance=math.max(0,radius-3)
        if not state.AutoFarm or not(state.Enabled or state.SkillAura)or not ctx.Mobs then return nil,center end
        local function attackPoint(mob)
            local data=ctx.MobData(mob)
            if not data or data.Health.Value<=0 or (data.HitLives and data.HitLives.Value<=0)
                or data.Entity:FindFirstChild("Immortal") then return end
            local point=data.Root.Position
            local distance=(point-center).Magnitude
            if distance>radius+6 then return end
            local elevated=point+Vector3.new(0,(data.BodyAbove or data.Root.Size.Y/2)+humanoid.HipHeight+root.Size.Y/2+1,0)
            local offset=elevated-center
            if offset.Magnitude>clearance then elevated=center+offset.Unit*clearance end
            return elevated,distance
        end
        local previous=state.BlackoutTarget
        local point=previous and attackPoint(previous)
        if point then return previous,point,center,radius end
        if now<timing.ScanAt then return nil,center end
        timing.ScanAt=now+.12
        local best,bestPoint,distance
        for mob in pairs(ctx.Mobs)do
            local candidate,gap=attackPoint(mob)
            if candidate and (not distance or gap<distance)then
                best,bestPoint,distance=mob,candidate,gap
            end
        end
        return best,bestPoint or center,center,radius
    end
    function api.Update()
        if closed or state.StopEverything then return false end
        local now=os.clock();if now<timing.UpdateAt then return api.Active end
        local fast=state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.Active and not state.NetworkPressureLimited
        timing.UpdateAt=now+(fast and 1/60 or .04)
        local kind=detect();api.Event=kind;state.OffsetMode="Below";state.FarmAbove=false
        local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local entity=character and character:FindFirstChild("Entity");local health=entity and entity:FindFirstChild("Health")
        observe(kind,health,now)
        local seen=0;for _ in pairs(api.Seen)do seen+=1 end
        local usable=root and humanoid and health and health.Value>0 and not state.TravelBusy
        if usable and ctx.AeganatosDodge then
            local point,reason=ctx.AeganatosDodge.Plan(root.Position,state.AutoOffsetDestination or root.Position)
            if point then
                if state.SkillCastRunning and state.CancelSkillAura then state.CancelSkillAura("Aeganatos dodge")end
                hold(point,"Aeganatos evade: "..tostring(reason),now);ctx.Status("Aeganatos Dodge · "..tostring(reason));return true
            end
        end
        local target=state.FollowTarget;local targetRoot=target and target:FindFirstChild("HumanoidRootPart")
        local desired=root and targetRoot and Vector3.new(targetRoot.Position.X,root.Position.Y,targetRoot.Position.Z)or root and root.Position
        if usable and ctx.AtheonDodge then
            local point,reason=ctx.AtheonDodge.Plan(root.Position,desired,api.FloorY)
            if point then hold(point,"Atheon evade: "..tostring(reason),now);ctx.Status("Atheon Dodge · "..tostring(reason));return true end
        end
        if not state.AutoDodge or not usable then release();ctx.Status((state.AutoDodge and "Ready"or "Off").." · events "..seen.."/8");return false end
        if kind and (kind=="Blackout"or not needsKills(kind))then
            local mob,point,center,radius
            if kind=="Blackout"then mob,point,center,radius=whiteLightTarget(root,humanoid,now)
            else point=Vector3.new(10,-19,-5)end
            state.BlackoutTarget=mob
            if hold(point,kind.." shelter",now)then
                if mob and (root.Position-point).Magnitude<=1.25 and (root.Position-center).Magnitude<=radius then
                    state.FollowTarget=mob;state.Dodging=false
                end
                ctx.Status(kind..(mob and " · attacking inside white light"or " · sheltering"));return true
            end
        end
        state.BlackoutTarget=nil
        if ctx.BossDodge and not(state.AtheonDodge and ctx.AtheonDodge and ctx.AtheonDodge.NearBoss)then
            local region=bounds();local point,reason=ctx.BossDodge.Plan(root.Position,desired,region)
            if point then hold(point,"Boss evade: "..tostring(reason),now);ctx.Status("Boss attack · outside danger zone");return true end
            if ctx.BossDodge.Blocked then local refuge=api.BlackoutPoint(root.Position);if refuge then hold(refuge,"Boss evade below map bottom",now);return true end end
        end
        release();ctx.Status((kind and kind.." · watching"or "Ready").." · events "..seen.."/8");return false
    end
    function api.Idle(anchor)
        if closed or state.StopEverything then return end
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart");if not root then return end
        local point=anchor or root.Position;local floor=anchor and anchor.Y or api.FloorY(point)
        ctx.Hold(Vector3.new(point.X,floor-20,point.Z),true)
        state.IdleFloorY=floor;state.IdleBelowMap=true;state.IdleAboveMap=false
    end
    function api.Destroy()
        if closed then return end
        closed=true;persist()
        for _,controller in pairs({ctx.BossDodge,ctx.AtheonDodge,ctx.AeganatosDodge})do if controller then controller.Destroy()end end
        release()
    end
    return api
end
