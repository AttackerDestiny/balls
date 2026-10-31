-- React only to native enemy warning names/tags confirmed in EnemySkills.
return function(ctx)
    local api={ThreatCount=0}
    local roots,connections={},{}
    local disposed=false
    local lastPoint,holdUntil=nil,0
    local nextSearch=0
    local named={RedGroundWarning="Circle",LockedAimWarning="Beam"}
    local tags={"AegorSlam Rock","AegorSlam Slam","AegorSpike Spike","RiftDetonation Rift"}
    local projectileActive={}
    local function track(root,kind)
        if disposed or roots[root] then return end
        local count=0; for _ in pairs(roots) do count+=1 end
        if count>=48 then return end
        roots[root]={Kind=kind,Started=os.clock(),Name=root.Name}
        api.HasHazards=true
    end
    local function projectileMatch(part,spec)
        local template=spec.Template
        return template and part.ClassName==template.ClassName and part.Name==template.Name
            and part.Material==template.Material and part.Color==template.Color
            and (part.Size-template.Size).Magnitude<.15 and part:FindFirstChild(spec.Marker)~=nil
    end
    local function projectileAdded(part)
        for _,spec in ipairs(ctx.Projectiles or {}) do
            if projectileMatch(part,spec) then
                local function register()
                    if not disposed and part.Parent and os.clock()<(projectileActive[spec.Name] or 0) then
                        track(part,"Projectile")
                        local r=roots[part]
                        if r then r.Name=spec.Name; r.Radius=spec.Radius end
                    end
                end
                register(); if not roots[part] then task.defer(register) end
            end
        end
    end
    if ctx.Replicate then connections[#connections+1]=ctx.Replicate:Connect(function(_,phase,name)
        if phase=="Initial" or phase=="RunPhase" then
            for _,spec in ipairs(ctx.Projectiles or {}) do if name==spec.Name then projectileActive[name]=os.clock()+10 end end
        end
    end) end
    connections[#connections+1]=ctx.Workspace.DescendantAdded:Connect(function(instance)
        if named[instance.Name] and (instance:IsA("Model") or instance:IsA("BasePart")) then track(instance,named[instance.Name]) end
        if instance:IsA("BasePart") and instance.Name=="Part" then projectileAdded(instance) end
    end)
    for _,instance in ipairs(ctx.Workspace:QueryDescendants("#RedGroundWarning,#LockedAimWarning")) do track(instance,named[instance.Name]) end
    for _,tag in ipairs(tags) do
        local function added(part) if part:IsA("BasePart") and part.Name=="Circle" then track(part,"Circle") end end
        for _,part in ipairs(ctx.Collection:GetTagged(tag)) do added(part) end
        connections[#connections+1]=ctx.Collection:GetInstanceAddedSignal(tag):Connect(added)
    end
    -- Preserve protection when the script is reloaded during an existing cast.
    local mobs=ctx.Workspace:FindFirstChild("Mobs")
    local prime=false
    for _,spec in ipairs(ctx.Projectiles or {}) do
        local boss=mobs and spec.BossName and mobs:FindFirstChild(spec.BossName)
        local entity=boss and boss:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if health and health.Value>0 then projectileActive[spec.Name]=os.clock()+10; prime=true end
    end
    if prime then for _,part in ipairs(ctx.Workspace:GetChildren()) do if part:IsA("BasePart") and part.Name=="Part" then projectileAdded(part) end end end
    local boxes={}
    local function refresh()
        table.clear(boxes)
        local now=os.clock()
        for root,record in pairs(roots) do
            if root.Parent then
                local ok,cf,size=pcall(function() if root:IsA("Model") then return root:GetBoundingBox() end return root.CFrame,root.Size end)
                if ok and math.max(size.X,size.Z)>.2 then
                    if record.Kind=="Projectile" and record.CFrame and record.SampleAt and now>record.SampleAt then
                        local velocity=(cf.Position-record.CFrame.Position)/(now-record.SampleAt)
                        record.Velocity=velocity.Magnitude<=400 and velocity or Vector3.zero
                    end
                    record.CFrame,record.Size,record.SampleAt=cf,size,now
                end
                record.RemovedAt=nil
            else record.RemovedAt=record.RemovedAt or now end
            if now-record.Started>20 or (record.RemovedAt and now-record.RemovedAt>.8) then roots[root]=nil
            elseif record.CFrame then boxes[#boxes+1]=record end
        end
        api.ThreatCount=#boxes; ctx.State.BossThreatCount=#boxes
        api.HasHazards=next(roots)~=nil
    end
    local function threatened(point)
        local margin=5+math.min(3,(ctx.State.PingMs or 0)/100)
        for _,record in ipairs(boxes) do
            local cf,size=record.CFrame,record.Size
            if record.Kind=="Projectile" then
                local lead=math.clamp(.12+(ctx.State.PingMs or 0)/1000,.12,.4)
                local segment=(record.Velocity or Vector3.zero)*lead
                local alpha=segment:Dot(segment)>.01 and math.clamp((point-cf.Position):Dot(segment)/segment:Dot(segment),0,1) or 0
                local d=point-(cf.Position+segment*alpha)
                local radius=(record.Radius or math.max(size.X,size.Y,size.Z)*.5)+margin
                if d:Dot(d)<radius*radius then return true,record.Name end
            elseif record.Kind=="Beam" then
                local p=cf:PointToObjectSpace(point)
                if math.abs(p.X)<size.X*.5+margin and math.abs(p.Z)<size.Z*.5+margin then return true,record.Name end
            else
                local half=Vector3.new(math.abs(cf.RightVector.X)*size.X+math.abs(cf.UpVector.X)*size.Y+math.abs(cf.LookVector.X)*size.Z,
                    0,math.abs(cf.RightVector.Z)*size.X+math.abs(cf.UpVector.Z)*size.Y+math.abs(cf.LookVector.Z)*size.Z)*.5
                local radius=math.max(half.X,half.Z)+margin
                local delta=(point-cf.Position)*Vector3.new(1,0,1)
                if delta:Dot(delta)<radius*radius then return true,record.Name end
            end
        end
        return false
    end
    function api.RefreshThreats() if not disposed then refresh() end end
    function api.IsThreatened(point) return threatened(point) end
    function api.IsHazardPart(part)
        local node=part
        while node and node~=ctx.Workspace do if roots[node] then return true end; node=node.Parent end
        return false
    end
    function api.Plan(point,desired,region,extraThreat)
        if disposed or not ctx.State.AutoDodge then return nil end
        refresh()
        local now=os.clock()
        local unsafe,name=threatened(point)
        local wanted,wantedName=threatened(desired or point)
        api.Blocked=unsafe or wanted
        if not unsafe and not wanted and now>=holdUntil then lastPoint=nil; return nil end
        local function valid(p)
            if threatened(p) or (extraThreat and extraThreat(p)) then return false end
            if region then local q=region.CFrame:PointToObjectSpace(p); if math.abs(q.X)>region.Size.X*.5-8 or math.abs(q.Z)>region.Size.Z*.5-8 then return false end end
            return true
        end
        if lastPoint and valid(lastPoint) then return lastPoint,api.LastReason end
        if now<nextSearch then return nil end
        lastPoint=nil
        if valid(point) then lastPoint=point
        else
            for radius=10,220,10 do
                for i=1,16 do
                    local angle=i*math.pi/8
                    local p=point+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
                    if valid(p) then lastPoint=p; break end
                end
                if lastPoint then break end
            end
        end
        if lastPoint then
            holdUntil=now+.45; api.LastReason=name or wantedName or "Boss warning"
            ctx.State.LastBossWarning=api.LastReason
            return lastPoint,api.LastReason
        end
        nextSearch=now+.15
        return nil
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        api.HasHazards=false
        for _,connection in ipairs(connections) do connection:Disconnect() end
        table.clear(roots); table.clear(boxes); lastPoint=nil
    end
    return api
end
