-- Native warning discovery feeds bounded geometry snapshots and a reusable escape search.
return function(ctx)
    local api={ThreatCount=0}
    local warnings,bindings={},{}
    local snapshots={}
    local castWindows={}
    local cone
    local closed=false
    local escape={Point=nil,Until=0,SearchAt=0}
    local labels={RedGroundWarning="Circle",LockedAimWarning="Beam"}
    local tags={"AegorSlam Rock","AegorSlam Slam","AegorSpike Spike","RiftDetonation Rift"}
    local final=ctx.FinalWave
    local wave=ctx.RubricatusWave or {}
    local cover=ctx.RubricatusCover
    local finalActive=false
    local laserColor=final and Color3.fromRGB(255,18,38)
    local function bind(signal,fn)bindings[#bindings+1]=signal:Connect(fn)end
    local function register(object,kind,name,radius,finalOnly)
        if closed then return end
        local entry=warnings[object]
        if not entry then
            local count=0;for _ in pairs(warnings)do count+=1 end
            if count>=128 then return end
            entry={Kind=kind,Started=os.clock(),Name=name or object.Name,FinalOnly=finalOnly};warnings[object]=entry
        end
        entry.Radius=radius or entry.Radius;api.HasHazards=true
    end
    local function projectile(object)
        for _,spec in ipairs(ctx.Projectiles or {})do
            local template=spec.Template
            local matches=template and object.ClassName==template.ClassName and object.Name==template.Name
                and object.Material==template.Material and object.Color==template.Color
                and (object.Size-template.Size).Magnitude<.15 and object:FindFirstChild(spec.Marker)~=nil
            if matches then
                local function admit()
                    if not closed and object.Parent and os.clock()<(castWindows[spec.Name]or 0)then register(object,"Projectile",spec.Name,spec.Radius)end
                end
                admit();if not warnings[object]then task.defer(admit)end
            end
        end
    end
    local function inspect(object)
        local name,parent=object.Name,object.Parent
        local group=parent and parent.Name
        if final and (group=="RedLightningDiscEffects" or group=="RedLightningLaserEffects" or group=="RedLightningEffects"
            or parent==ctx.Workspace and name=="Part")and final()then
            if group=="RedLightningDiscEffects" and name:match("^LightningDisc%d+$")and object:IsA("Model")then
                register(object,"Disc","Red Lightning Discs",ctx.DiscRadius or 10,true);return
            elseif group=="RedLightningLaserEffects" then
                if name=="RedBeam"and object:IsA("BasePart")or name=="LockedAimWarning"and (object:IsA("BasePart")or object:IsA("Model"))then
                    register(object,"Laser","Red Lightning Laser",ctx.LaserRadius or 80,true)
                end
                if name=="RedBeam" or name=="LockedAimWarning"then return end
            elseif group=="RedLightningEffects" and name=="LightningWaveAnchor" and object:IsA("BasePart")then
                register(object,"Wave","Red Lightning Wave",nil,true);return
            elseif parent==ctx.Workspace and name=="Part" and object:IsA("BasePart")and object.Color==laserColor then
                task.defer(function()
                    if not closed and object.Parent and final()and object:FindFirstChild("Beam")then register(object,"Box","Rubricatus Lasers",nil,true)end
                end)
            end
        end
        if labels[object.Name]and (object:IsA("Model")or object:IsA("BasePart"))then register(object,labels[object.Name])end
        if object:IsA("BasePart")and object.Name=="Part"then projectile(object)end
    end
    if ctx.Replicate then bind(ctx.Replicate,function(_,phase,name,duration,target)
        if phase~="Initial"and phase~="RunPhase"then return end
        for _,spec in ipairs(ctx.Projectiles or {})do if spec.Name==name then castWindows[name]=os.clock()+10 end end
        if final and final()and phase=="Initial"and name=="RedLightningWave"and typeof(target)=="Vector3"then
            local origin=ctx.RubricatusOrigin and ctx.RubricatusOrigin()
            if not origin then return end
            origin+=Vector3.new(0,wave.OriginHeight or 1.5,0)
            local delta=target-origin
            delta=Vector3.new(delta.X,0,delta.Z)
            if delta.Magnitude<.01 then return end
            local direction=delta.Unit
            cone={Kind="Cone",Name="Red Lightning Wave",Origin=origin+direction*(wave.MuzzleOffset or 2.5),
                Direction=direction,Until=os.clock()+(wave.ChargeTime or .35)+(wave.ExpandTime or .45)+(wave.FireTime or 0)+(wave.FadeTime or .3)+.2}
        end
    end)end
    bind(ctx.Workspace.DescendantAdded,inspect)
    for _,object in ipairs(ctx.Workspace:QueryDescendants("#RedGroundWarning,#LockedAimWarning"))do inspect(object)end
    for _,tag in ipairs(tags)do
        local function tagged(object)if object:IsA("BasePart")and object.Name=="Circle"then register(object,"Circle")end end
        bind(ctx.Collection:GetInstanceAddedSignal(tag),tagged)
        for _,object in ipairs(ctx.Collection:GetTagged(tag))do tagged(object)end
    end
    if final then
        for _,tag in ipairs({"RubricatusAttack Attack","RubricatusSlam Slam"})do
            local function tagged(object)
                if final()and object.Name=="Box"and object:IsA("BasePart")then
                    register(object,"Box",tag,nil,true)
                    local entry=warnings[object]
                    local lifetime=tonumber(object:GetAttribute("Lifetime"))
                    if entry and lifetime then entry.ExpiresAt=entry.Started+math.clamp(lifetime,0,10)+.2 end
                end
            end
            bind(ctx.Collection:GetInstanceAddedSignal(tag),tagged)
            for _,object in ipairs(ctx.Collection:GetTagged(tag))do tagged(object)end
        end
        if final()then
            for _,name in ipairs({"RedLightningDiscEffects","RedLightningLaserEffects","RedLightningEffects"})do
                local folder=ctx.Workspace:FindFirstChild(name)
                if folder then for _,object in ipairs(folder:GetChildren())do inspect(object)end end
            end
        end
    end
    local mobs=ctx.Workspace:FindFirstChild("Mobs")
    local scanExisting=false
    for _,spec in ipairs(ctx.Projectiles or {})do
        local boss=mobs and spec.BossName and mobs:FindFirstChild(spec.BossName)
        local entity=boss and boss:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if health and health.Value>0 then castWindows[spec.Name]=os.clock()+10;scanExisting=true end
    end
    if scanExisting then for _,object in ipairs(ctx.Workspace:GetChildren())do if object:IsA("BasePart")and object.Name=="Part"then projectile(object)end end end
    local function sample(object,entry,time)
        if not object.Parent then entry.RemovedAt=entry.RemovedAt or time;return end
        entry.RemovedAt=nil
        if entry.Kind=="Laser"and object.Shape~=Enum.PartType.Cylinder then entry.CFrame=nil;return end
        local ok,frame,size=pcall(function()
            if entry.Kind=="Disc"then
                local root=object.PrimaryPart
                local target=object:GetAttribute("LockedTarget")
                if not root or typeof(target)~="Vector3"then return end
                entry.Target=target
                return root.CFrame,root.Size
            end
            if object:IsA("Model")then return object:GetBoundingBox()end
            return object.CFrame,object.Size
        end)
        if not ok or not frame or math.max(size.X,size.Z)<=.2 then
            entry.CFrame=nil;entry.Velocity=nil;entry.SampleAt=nil;entry.PreviousPosition=nil;return
        end
        if (entry.Kind=="Projectile"or entry.Kind=="Disc")and entry.CFrame and time>(entry.SampleAt or time)then
            entry.PreviousPosition=entry.CFrame.Position
            local motion=(frame.Position-entry.CFrame.Position)/(time-entry.SampleAt)
            entry.Velocity=motion.Magnitude<=400 and motion or Vector3.zero
        end
        entry.CFrame=frame;entry.Size=size;entry.SampleAt=time
    end
    function api.RefreshThreats()
        if closed then return end
        table.clear(snapshots)
        local time=os.clock()
        local active=final and final()==true
        if active and not finalActive then
            for _,name in ipairs({"RedLightningDiscEffects","RedLightningLaserEffects","RedLightningEffects"})do
                local folder=ctx.Workspace:FindFirstChild(name)
                if folder then for _,object in ipairs(folder:GetChildren())do inspect(object)end end
            end
        end
        finalActive=active
        for object,entry in pairs(warnings)do
            sample(object,entry,time)
            if entry.FinalOnly and not active or (entry.ExpiresAt and time>=entry.ExpiresAt)
                or time-entry.Started>20 or (entry.RemovedAt and time-entry.RemovedAt>.8)then warnings[object]=nil
            elseif entry.CFrame then snapshots[#snapshots+1]=entry end
        end
        if cone and time<cone.Until and final()then snapshots[#snapshots+1]=cone else cone=nil end
        api.ThreatCount=#snapshots;ctx.State.BossThreatCount=#snapshots;api.HasHazards=cone~=nil or next(warnings)~=nil
    end
    local function distanceFromSegment(point,start,segment)
        local length=segment:Dot(segment)
        local fraction=length>.01 and math.clamp((point-start):Dot(segment)/length,0,1)or 0
        return (point-start-segment*fraction).Magnitude
    end
    local function collision(entry,point,margin)
        local frame,size=entry.CFrame,entry.Size
        if entry.Kind=="Wave"or entry.Kind=="Cone"then
            if entry.Kind=="Wave"and cone then return false end
            local delta=point-(entry.Origin or frame.Position)
            if math.abs(delta.Y)>(wave.Height or 6)*.5+margin then return false end
            delta=Vector3.new(delta.X,0,delta.Z)
            if delta.Magnitude>(wave.Range or 100)+margin then return false end
            if not entry.Direction then return true end
            local forward=delta:Dot(entry.Direction)
            return forward>=-margin and (delta-entry.Direction*forward).Magnitude<=math.max(0,forward)*math.tan(math.rad((wave.SpreadAngle or 120)/2))+margin
        end
        if entry.Kind=="Box"or entry.Kind=="Laser"then
            local at=frame:PointToObjectSpace(point)
            if entry.Kind=="Laser"then
                local radius=math.max(entry.Radius,size.Y*.5)+margin
                return math.abs(at.X)<=size.X*.5+margin and at.Y*at.Y+at.Z*at.Z<=radius*radius
            end
            return math.abs(at.X)<=size.X*.5+margin and math.abs(at.Y)<=size.Y*.5+margin and math.abs(at.Z)<=size.Z*.5+margin
        end
        if entry.Kind=="Beam"then
            local at=frame:PointToObjectSpace(point)
            return math.abs(at.X)<size.X*.5+margin and math.abs(at.Z)<size.Z*.5+margin
        end
        if entry.Kind=="Projectile"or entry.Kind=="Disc"then
            local lead=math.clamp(.12+(ctx.State.PingMs or 0)/1000+math.min(.2,ctx.State.AverageFrameTime or 0),.12,.6)
            local radius=(entry.Radius or math.max(size.X,size.Y,size.Z)*.5)+margin
            local position=frame.Position
            if entry.Kind=="Disc"and (point-entry.Target).Magnitude<radius then return true end
            if entry.PreviousPosition and distanceFromSegment(point,entry.PreviousPosition,position-entry.PreviousPosition)<radius then return true end
            return distanceFromSegment(point,position,(entry.Velocity or Vector3.zero)*lead)<radius
        end
        local x=math.abs(frame.RightVector.X)*size.X+math.abs(frame.UpVector.X)*size.Y+math.abs(frame.LookVector.X)*size.Z
        local z=math.abs(frame.RightVector.Z)*size.X+math.abs(frame.UpVector.Z)*size.Y+math.abs(frame.LookVector.Z)*size.Z
        local delta=(point-frame.Position)*Vector3.new(1,0,1)
        local radius=math.max(x,z)*.5+margin
        return delta:Dot(delta)<radius*radius
    end
    function api.IsThreatened(point)
        local margin=5+math.min(3,(ctx.State.PingMs or 0)/100)
        for _,entry in ipairs(snapshots)do if collision(entry,point,margin)then return true,entry.Name end end
        return false
    end
    function api.IsHazardPart(part)
        if ctx.PillarPart and ctx.PillarPart(part)then return true end
        local object=part
        while object and object~=ctx.Workspace do if warnings[object]then return true end;object=object.Parent end
        return false
    end
    function api.Plan(point,desired,region,extraThreat)
        api.Blocked=false;api.RequiresCover=false
        if closed or not ctx.State.AutoDodge then escape.Point=nil;escape.Until=0;return nil end
        api.RefreshThreats()
        local time=os.clock()
        local danger,reason=api.IsThreatened(point)
        local targetDanger,targetReason=api.IsThreatened(desired or point)
        local function safe(candidate)
            if api.IsThreatened(candidate)or (extraThreat and extraThreat(candidate))then return false end
            if region then
                local at=region.CFrame:PointToObjectSpace(candidate)
                if math.abs(at.X)>region.Size.X*.5-8 or math.abs(at.Z)>region.Size.Z*.5-8 then return false end
            end
            return true
        end
        if cover then
            local point,reason=cover.Plan(point,safe)
            if cover.Active then
                api.Blocked=true;api.RequiresCover=true;api.LastReason=reason;escape.Point=nil
                ctx.State.LastBossWarning=reason
                return point,reason
            end
        end
        api.Blocked=danger or targetDanger
        if not api.Blocked and time>=escape.Until then escape.Point=nil;return nil end
        if escape.Point and safe(escape.Point)then return escape.Point,api.LastReason end
        if time<escape.SearchAt then return nil end
        local chosen=safe(point)and point or nil
        for radius=10,220,10 do
            if chosen then break end
            for direction=1,16 do
                local angle=direction*math.pi/8
                local candidate=point+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                if safe(candidate)then chosen=candidate;break end
            end
        end
        escape.Point=chosen
        if not chosen then escape.SearchAt=time+.15;return nil end
        escape.Until=time+.45;api.LastReason=reason or targetReason or "Boss warning"
        ctx.State.LastBossWarning=api.LastReason
        return chosen,api.LastReason
    end
    function api.Destroy()
        if closed then return end
        closed=true;api.HasHazards=false;api.ThreatCount=0
        ctx.State.BossThreatCount=0
        api.Blocked=false;api.RequiresCover=false
        if cover then cover.Destroy()end
        for _,connection in ipairs(bindings)do connection:Disconnect()end
        table.clear(bindings);table.clear(warnings);table.clear(snapshots);table.clear(castWindows);escape.Point=nil;cone=nil
    end
    return api
end
