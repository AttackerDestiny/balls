-- Suppress rendering while retaining animation timelines, hitboxes and callbacks.
return function(ctx)
    local state,player=ctx.State,game.Players.LocalPlayer
    local api={AnimationsHidden=0,EffectsHidden=0}
    local assets,names,effectNames,sounds,ordinaryAnimations={},{},{},{},{}
    local managed,tracks={},{}
    local maintenance,maintenanceQueued=setmetatable({}, {__mode="v"}),setmetatable({}, {__mode="k"})
    local maintenanceHead,maintenanceTail=1,0
    local maintenanceNext,maintenanceNextTail=setmetatable({}, {__mode="v"}),0
    local ordinaryTracks=setmetatable({}, {__mode="k"})
    local connections={}
    local disposed=false
    local animator,played,nextCheck=nil,nil,0
    local pendingQueue=assert(ctx.Queue,"Bounded visual queue is required")
    local invisible=NumberSequence.new(1)
    local hiddenWeight=0.0001 -- A zero-weight track can stop before its damage markers.
    local gunUntil,gunOrigin=0,nil
    local gunModels=setmetatable({}, {__mode="k"})
    local function normalize(value) return string.lower((string.gsub(value or "","[^%w]",""))) end
    local function assetId(value) return string.match(value or "","%d+") end
    local generic={part=true,meshpart=true,model=true,folder=true,attachment=true,rock=true,rocks=true,groundrocks=true,floor=true,terrain=true,baseplate=true,spawnlocation=true,humanoidrootpart=true,uppertorso=true,lowertorso=true,vfx=true,handle=true,trail=true,beam=true,light=true,animation=true,particleemitter=true,pointlight=true,spotlight=true,surfacelight=true,sound=true,smoke=true,texture=true,decal=true}
    local locomotion={idle=true,walk=true,run=true,jump=true,fall=true,climb=true,swim=true,swimidle=true,sit=true,toolnone=true}
    for _,definition in ipairs(game.ReplicatedStorage.Database.Skills:GetChildren()) do names[normalize(definition.Name)]=true end
    for _,root in ipairs({ctx.Services.Skills,ctx.Services.SkillEffects}) do
        for _,instance in ipairs(root:QueryDescendants("Animation,BasePart,ParticleEmitter,Beam,Trail,Model,Sound")) do
            if instance:IsA("Animation")then
                local id=assetId(instance.AnimationId);if id then assets[id]=true end
            else
                if instance:IsA("Sound")then local id=assetId(instance.SoundId);if id then sounds[id]=true end end
                local key=normalize(instance.Name)
                if #key>=5 and not generic[key]then effectNames[key]=true end
            end
            if state.YieldStartup then state.YieldStartup()end
        end
    end
    for _,style in pairs(ctx.Actions.animations) do
        if type(style)=="table" then for key,track in pairs(style) do
            if type(key)=="string" and typeof(track)=="Instance" and track:IsA("AnimationTrack") and track.Animation then
                local id=assetId(track.Animation.AnimationId)
                if id then if names[normalize(key)] then assets[id]=true else ordinaryAnimations[id]=true end end
            end
        end end
    end
    local function keep(instance)
        if (instance:IsA("BillboardGui") or instance:IsA("SurfaceGui"))
            and #instance:QueryDescendants("TextLabel,TextButton")>0 then return true end
        if ctx.Preserve and ctx.Preserve(instance) then return true end
        local mobs=workspace:FindFirstChild("Mobs")
        local characters=workspace:FindFirstChild("Characters")
        local items=workspace:FindFirstChild("CharacterItems")
        local ownItems=items and items:FindFirstChild(tostring(player.UserId))
        if items and instance:IsDescendantOf(items) and not (ownItems and instance:IsDescendantOf(ownItems)) then return true end
        if mobs and instance:IsDescendantOf(mobs) then return true end
        if characters and instance:IsDescendantOf(characters) and not (player.Character and instance:IsDescendantOf(player.Character)) then return true end
        return false
    end
    local function effect(instance)
        if managed[instance] then return true end
        if keep(instance) then return false end
        local gunNearby=false
        local part=instance:IsA("BasePart") and instance or instance:FindFirstAncestorWhichIsA("BasePart")
        if part then
            for model,expires in pairs(gunModels) do
                if not model.Parent or os.clock()>expires then gunModels[model]=nil
                else local gun=model:FindFirstChild("Gun"); if gun and gun:IsA("BasePart") and (part.Position-gun.Position).Magnitude<160 then gunNearby=true; break end end
            end
        end
        if (gunOrigin and os.clock()<gunUntil) or gunNearby then
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if part and (gunNearby or (gunOrigin and (part.Position-gunOrigin).Magnitude<160) or (root and (part.Position-root.Position).Magnitude<160)) then
                local sphere=part:IsA("Part") and part.Name=="Part" and not part.CanCollide and part.Shape==Enum.PartType.Ball
                    and part.Transparency>=.95 and part.Size.X>=8 and part.Size.X<=16
                if instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("ParticleEmitter") then return true end
                if instance:IsA("Decal") and (sphere or string.find(instance.Texture,"3170098415",1,true) or string.find(instance.Texture,"3170224154",1,true)) then return true end
                if sphere and (instance:IsA("Light") or instance:IsA("Sound")) then return true end
                if instance:IsA("BasePart") and not instance.CanCollide and instance.Material==Enum.Material.Neon
                    and (instance.BrickColor==BrickColor.new("Bright yellow")
                        or (instance:IsA("Part") and instance.Name=="Part" and instance.BrickColor==BrickColor.new("Bright blue")
                            and (instance.Shape==Enum.PartType.Ball or (instance.Size.Z>instance.Size.X*3 and instance.Size.Z>instance.Size.Y*3)))) then return true end
            end
        end
        if instance:IsA("Sound") and sounds[assetId(instance.SoundId)] then return true end
        local own=player.Character and instance:IsDescendantOf(player.Character)
        if own and instance:IsA("BasePart") and (instance.Parent==player.Character or instance.Parent:IsA("Accessory") or instance.Parent:IsA("Tool")) then return false end
        if own and (instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") or instance:IsA("Light") or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles")) then return true end
        local node=instance
        while node and node~=workspace do
            local key=normalize(node.Name)
            local rifle=key=="ar" and node:IsA("Model") and node:FindFirstChild("Gun")
                and (node:FindFirstChild("Portal1") or node:FindFirstChild("Portal2"))
            if node.Name=="HitEffects" or names[key] or effectNames[key] or key=="pistol" or key=="rifle" or key=="summonrifle" or rifle then return true end
            node=node.Parent
        end
        return false
    end
    -- Mobile executors may reject LocalTransparencyModifier on effect classes.
    -- Treat each property independently so one unsupported member cannot stall VFX cleanup.
    local function write(instance,property,value)
        return pcall(function()instance[property]=value end)
    end
    local function restore(instance,record)
        for property,value in pairs(record.Before) do write(instance,property,value) end
    end
    local function suppress(instance)
        if disposed or state.StopEverything then return end
        if managed[instance] or not effect(instance) then return end
        if maintenanceTail-maintenanceHead+1+maintenanceNextTail>=8192 then return end
        local properties
        if instance:IsA("BasePart") then
            if ctx.ExcludeMapPart then ctx.ExcludeMapPart(instance) end
            properties={LocalTransparencyModifier=1,Transparency=1}
        elseif instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then properties={Enabled=false,Transparency=invisible,LocalTransparencyModifier=1}
        elseif instance:IsA("Light") then properties={Enabled=false,Brightness=0}
        elseif instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then properties={Enabled=false}
        elseif instance:IsA("Sound") then properties={Volume=0}
        elseif instance:IsA("Decal") or instance:IsA("Texture") then properties={Transparency=1}
        elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then properties={Enabled=false}
        elseif instance:IsA("Highlight") then properties={Enabled=false,FillTransparency=1,OutlineTransparency=1} end
        if not properties then return end
        local record={Before={},Hidden=properties,Parent=instance.Parent}
        for property,value in pairs(properties) do
            local readable,before=pcall(function()return instance[property]end)
            if readable and write(instance,property,value) then record.Before[property]=before
            else record.Hidden[property]=nil end
        end
        if not next(record.Hidden)then return end
        managed[instance]=record
        if not maintenanceQueued[instance]then
            maintenanceTail+=1;maintenance[maintenanceTail]=instance;maintenanceQueued[instance]=true
        end
        if instance:IsA("ParticleEmitter") or instance:IsA("Trail") then pcall(function()instance:Clear()end) end
        api.EffectsHidden+=1
    end
    local function isSkill(track)
        if ordinaryTracks[track] then return false end
        local key=normalize(track.Name)
        if locomotion[key] or string.sub(key,1,5)=="swing" then return false end
        local id=track.Animation and assetId(track.Animation.AnimationId)
        if id and assets[id] then return true end
        if id and ordinaryAnimations[id] then return false end
        if names[key] then return true end
        if track.Priority.Value>=Enum.AnimationPriority.Action.Value then return true end
        return (state.SkillCastRunning or (ctx.SkillState and ctx.SkillState.usingSkill~="none")) and not locomotion[key]
    end
    api.IsSkillAnimation=isSkill
    function api.MarkGunCast(name,origin)
        if name=="Summon Pistol" or name=="Summon Rifle" then gunUntil=os.clock()+5; gunOrigin=origin end
    end
    function api.AllowSwingTrack(track)
        ordinaryTracks[track]=true
        local before=tracks[track]
        if before and track.IsPlaying then track:AdjustWeight(before.Weight,0) end
        tracks[track]=nil
    end
    local function hideTrack(track)
        if disposed or state.StopEverything then return end
        if not isSkill(track) then return end
        if not tracks[track] then
            tracks[track]={Weight=track.WeightTarget}
            api.AnimationsHidden+=1
        end
        if math.abs(track.WeightTarget-hiddenWeight)>0.00001 or track.WeightCurrent>0.001 then track:AdjustWeight(hiddenWeight,0) end
    end
    local function enqueue(instance,priority)
        if disposed or state.StopEverything or pendingQueue.Contains(instance)or managed[instance]then return end
        local name=instance.ClassName
        if not (instance:IsA("BasePart") or instance:IsA("Light") or name=="ParticleEmitter" or name=="Beam" or name=="Trail"
            or name=="Smoke" or name=="Fire" or name=="Sparkles" or name=="Texture" or name=="Sound" or name=="Decal" or name=="BillboardGui" or name=="SurfaceGui" or name=="Highlight") then return end
        pendingQueue.Push(instance,priority)
    end
    function api.ProcessPending()
        local deadline=os.clock()+.0006
        local count=0
        while count<64 and (count==0 or os.clock()<deadline) do
            local instance=pendingQueue.Pop()
            if not instance then break end
            if instance.Parent then pcall(suppress,instance) end
            count+=1
        end
        api.Pending=pendingQueue.Count
        state.VisualQueueSize=api.Pending
    end
    local immediateCount,immediateSince=0,0
    local function added(instance)
        if disposed or state.StopEverything or not state.Running then return end
        if instance:IsA("Model") and (instance.Name=="AR" or instance.Name=="Pistol") then
            gunModels[instance]=os.clock()+5
            for _,part in ipairs(instance:QueryDescendants("BasePart,ParticleEmitter,Beam,Trail,Smoke,Fire,Sparkles,Sound,Decal,Texture")) do enqueue(part,true) end
        end
        if instance:IsA("TextLabel") or instance:IsA("TextButton") then
            local gui=instance:FindFirstAncestorWhichIsA("BillboardGui") or instance:FindFirstAncestorWhichIsA("SurfaceGui")
            local record=gui and managed[gui]
            if record then
                restore(gui,record)
                managed[gui]=nil
            end
            return
        end
        -- Streaming also adds attachments, constraints, value objects and UI
        -- layout nodes. They cannot render effects and must not grow the queue.
        if not(instance:IsA("BasePart")or instance:IsA("ParticleEmitter")or instance:IsA("Beam")or instance:IsA("Trail")
            or instance:IsA("Smoke")or instance:IsA("Fire")or instance:IsA("Sparkles")or instance:IsA("Light")
            or instance:IsA("Decal")or instance:IsA("Texture")or instance:IsA("BillboardGui")or instance:IsA("SurfaceGui")
            or instance:IsA("Highlight")or instance:IsA("Sound"))then return end
        -- Hide proven effects on arrival, before waiting for the next mobile frame.
        -- Cap synchronous work during bursty casts; overflow uses the bounded queue.
        local now=os.clock()
        if now-immediateSince>=.05 then immediateSince=now;immediateCount=0 end
        if immediateCount<24 then
            immediateCount+=1
            pcall(suppress,instance)
        end
        enqueue(instance,state.SkillCastRunning or state.MiscCastRunning or instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail")
            or instance:IsA("Sound") or effectNames[normalize(instance.Name)]~=nil)
    end
    connections[#connections+1]=workspace.DescendantAdded:Connect(added)
    connections[#connections+1]=workspace.DescendantRemoving:Connect(function(instance)
        pendingQueue.Remove(instance)
        local record=managed[instance]
        if record then restore(instance,record); managed[instance]=nil end
    end)
    for _,instance in ipairs(workspace:QueryDescendants("ParticleEmitter,Beam,Trail,Smoke,Fire,Sparkles,Light,BasePart,Decal,Texture,BillboardGui,SurfaceGui,Highlight,Sound")) do
        enqueue(instance,false)
        if state.YieldStartup then state.YieldStartup()end
    end
    for _,model in ipairs(workspace:QueryDescendants("#AR,#Pistol")) do if model:IsA("Model") then gunModels[model]=os.clock()+5 end end
    function api.IsEffect(instance) return effect(instance) end
    function api.ProcessManaged()
        local dynamic=not ctx.DynamicHazards or ctx.DynamicHazards()
        local deadline=os.clock()+.0006
        local available=math.min(64,maintenanceTail-maintenanceHead+1)
        local count=0
        while count<available and (count==0 or os.clock()<deadline)do
            local instance=maintenance[maintenanceHead]
            maintenance[maintenanceHead]=nil;maintenanceHead+=1
            if instance then maintenanceQueued[instance]=nil end
            local record=instance and managed[instance]
            if record then
                pcall(function()
                    if not instance.Parent then managed[instance]=nil
                    elseif (instance:IsA("BillboardGui") or instance:IsA("SurfaceGui")) and keep(instance) then
                        restore(instance,record)
                        managed[instance]=nil
                    elseif (dynamic or instance.Parent~=record.Parent) and keep(instance) then
                        restore(instance,record)
                        managed[instance]=nil
                    else
                        record.Parent=instance.Parent
                        for property,value in pairs(record.Hidden) do
                            local ok,current=pcall(function()return instance[property]end)
                            if ok then
                                if typeof(value)=="NumberSequence" then
                                    local points=current.Keypoints
                                    if #points~=2 or points[1].Value~=1 or points[2].Value~=1 then write(instance,property,value) end
                                elseif current~=value then write(instance,property,value) end
                            end
                        end
                    end
                end)
                if managed[instance]then
                    maintenanceNextTail+=1;maintenanceNext[maintenanceNextTail]=instance;maintenanceQueued[instance]=true
                end
            end
            count+=1
        end
        if maintenanceHead>maintenanceTail then
            table.clear(maintenance)
            maintenance,maintenanceNext=maintenanceNext,maintenance
            maintenanceHead,maintenanceTail=1,maintenanceNextTail;maintenanceNextTail=0
        end
        return count
    end
    function api.Update()
        if disposed or state.StopEverything then return end
        api.ProcessPending()
        local now=os.clock()
        if now<nextCheck then return end
        nextCheck=now+0.08
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local current=humanoid and humanoid:FindFirstChildOfClass("Animator")
        if current~=animator then
            if played then played:Disconnect(); played=nil end
            animator=current
            if animator then played=animator.AnimationPlayed:Connect(function(track)
                hideTrack(track)
                task.defer(function() if state.Running and track.IsPlaying then hideTrack(track) end end)
            end) end
        end
        if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do hideTrack(track) end end
        for track,record in pairs(tracks) do
            if not track.IsPlaying then tracks[track]=nil
            elseif track.WeightCurrent>0.001 or math.abs(track.WeightTarget-hiddenWeight)>0.00001 then track:AdjustWeight(hiddenWeight,0) end
        end
        api.ProcessManaged()
        state.HiddenSkillAnimations=api.AnimationsHidden
        state.HiddenSkillEffects=api.EffectsHidden
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        if played then played:Disconnect() end
        for _,connection in ipairs(connections) do connection:Disconnect() end
        for track,record in pairs(tracks) do if track.IsPlaying then track:AdjustWeight(record.Weight,0) end end
        for instance,record in pairs(managed) do if instance.Parent then restore(instance,record) end end
        table.clear(managed); table.clear(tracks)
        table.clear(maintenance);table.clear(maintenanceNext);maintenanceNextTail=0;table.clear(maintenanceQueued);maintenanceHead,maintenanceTail=1,0
        pendingQueue.Destroy()
        table.clear(gunModels)
        api.Pending=0; state.VisualQueueSize=0
    end
    api.Update()
    return api
end
