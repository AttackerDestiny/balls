-- Local visual overlays preserve native hitbox geometry, timers and animation markers.
return function(ctx)
    local state=ctx.State
    local player=game.Players.LocalPlayer
    local api={AnimationsHidden=0,EffectsHidden=0,Pending=0}
    local disposed=false
    local pending=assert(ctx.Queue,"Bounded visual queue is required")
    local managed,tracks={},{}
    local maintenance=setmetatable({}, {__mode="v"})
    local maintenanceNext=setmetatable({}, {__mode="v"})
    local maintenanceQueued=setmetatable({}, {__mode="k"})
    local maintenanceHead,maintenanceTail,maintenanceNextTail=1,0,0
    local ordinaryTracks=setmetatable({}, {__mode="k"})
    local invisible=NumberSequence.new(1)
    local catalogs={Animation={},Sound={},Name={},Skill={},Ordinary={}}
    local gunModels=setmetatable({}, {__mode="k"})
    local gunOrigin,gunUntil=nil,0
    local connections={}
    local animator,animationConnection
    local nextAnimation=0
    local hiddenWeight=.0001
    local function normalize(value)return tostring(value or ""):lower():gsub("[^%w]","")end
    local function id(value)return tostring(value or ""):match("%d+")end
    local generic={part=true,meshpart=true,model=true,folder=true,attachment=true,rock=true,rocks=true,groundrocks=true,floor=true,terrain=true,baseplate=true,spawnlocation=true,humanoidrootpart=true,uppertorso=true,lowertorso=true,vfx=true,handle=true,trail=true,beam=true,light=true,animation=true,particleemitter=true,pointlight=true,spotlight=true,surfacelight=true,sound=true,smoke=true,texture=true,decal=true}
    local locomotion={idle=true,walk=true,run=true,jump=true,fall=true,climb=true,swim=true,swimidle=true,sit=true,toolnone=true}
    for _,definition in ipairs(game.ReplicatedStorage.Database.Skills:GetChildren())do catalogs.Skill[normalize(definition.Name)]=true end
    for _,service in ipairs({ctx.Services.Skills,ctx.Services.SkillEffects})do
        for _,object in ipairs(service:QueryDescendants("Animation,BasePart,ParticleEmitter,Beam,Trail,Model,Sound"))do
            if object:IsA("Animation")then local key=id(object.AnimationId);if key then catalogs.Animation[key]=true end
            else
                if object:IsA("Sound")then local key=id(object.SoundId);if key then catalogs.Sound[key]=true end end
                local key=normalize(object.Name);if #key>=5 and not generic[key]then catalogs.Name[key]=true end
            end
            if state.YieldStartup then state.YieldStartup()end
        end
    end
    for _,pack in pairs(ctx.Actions.animations)do if type(pack)=="table"then
        for name,track in pairs(pack)do
            if type(name)=="string"and typeof(track)=="Instance"and track:IsA("AnimationTrack")and track.Animation then
                local key=id(track.Animation.AnimationId)
                if key then local collection=catalogs.Skill[normalize(name)]and catalogs.Animation or catalogs.Ordinary;collection[key]=true end
            end
        end
    end end
    local function keep(object)
        if (object:IsA("BillboardGui")or object:IsA("SurfaceGui"))and #object:QueryDescendants("TextLabel,TextButton")>0 then return true end
        if ctx.Preserve and ctx.Preserve(object)then return true end
        local mobs=workspace:FindFirstChild("Mobs")
        if mobs and object:IsDescendantOf(mobs)then return true end
        local characters=workspace:FindFirstChild("Characters")
        if characters and object:IsDescendantOf(characters)and not(player.Character and object:IsDescendantOf(player.Character))then return true end
        local items=workspace:FindFirstChild("CharacterItems")
        local own=items and items:FindFirstChild(tostring(player.UserId))
        return items and object:IsDescendantOf(items)and not(own and object:IsDescendantOf(own))or false
    end
    local function gunEffect(object)
        local part=object:IsA("BasePart")and object or object:FindFirstAncestorWhichIsA("BasePart")
        if not part then return false end
        local near=false
        for model,expires in pairs(gunModels)do
            if not model.Parent or os.clock()>expires then gunModels[model]=nil
            else local gun=model:FindFirstChild("Gun");if gun and gun:IsA("BasePart")and (part.Position-gun.Position).Magnitude<160 then near=true;break end end
        end
        if not near and gunOrigin and os.clock()<gunUntil then
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            near=(part.Position-gunOrigin).Magnitude<160 or root and (part.Position-root.Position).Magnitude<160
        end
        if not near then return false end
        if object:IsA("Trail")or object:IsA("Beam")or object:IsA("ParticleEmitter")then return true end
        local sphere=part:IsA("Part")and part.Name=="Part"and not part.CanCollide and part.Shape==Enum.PartType.Ball and part.Transparency>=.95 and part.Size.X>=8 and part.Size.X<=16
        if object:IsA("Decal")then return sphere or object.Texture:find("3170098415",1,true)~=nil or object.Texture:find("3170224154",1,true)~=nil end
        if sphere and (object:IsA("Light")or object:IsA("Sound"))then return true end
        if object:IsA("BasePart")and not object.CanCollide and object.Material==Enum.Material.Neon then
            if object.BrickColor==BrickColor.new("Bright yellow")then return true end
            if object:IsA("Part")and object.Name=="Part"and object.BrickColor==BrickColor.new("Bright blue")then
                return object.Shape==Enum.PartType.Ball or object.Size.Z>object.Size.X*3 and object.Size.Z>object.Size.Y*3
            end
        end
        return false
    end
    local function effect(object)
        if managed[object]then return true end
        if keep(object)then return false end
        if gunEffect(object)then return true end
        if object:IsA("Sound")and catalogs.Sound[id(object.SoundId)]then return true end
        local own=player.Character and object:IsDescendantOf(player.Character)
        if own and object:IsA("BasePart")and (object.Parent==player.Character or object.Parent:IsA("Accessory")or object.Parent:IsA("Tool"))then return false end
        if own and (object:IsA("ParticleEmitter")or object:IsA("Beam")or object:IsA("Trail")or object:IsA("Light")or object:IsA("Smoke")or object:IsA("Fire")or object:IsA("Sparkles"))then return true end
        local node=object
        while node and node~=workspace do
            local key=normalize(node.Name)
            if node.Name=="HitEffects"or catalogs.Skill[key]or catalogs.Name[key]or key=="pistol"or key=="rifle"or key=="summonrifle"then return true end
            if key=="ar"and node:IsA("Model")and node:FindFirstChild("Gun")and (node:FindFirstChild("Portal1")or node:FindFirstChild("Portal2"))then return true end
            node=node.Parent
        end
        return false
    end
    -- Isolated property access handles mobile executors that reject optional members.
    local function write(object,property,value)
        return pcall(function()object[property]=value end)
    end
    local function restore(object,record)
        for property,value in pairs(record.Before)do write(object,property,value)end
    end
    local function suppress(object)
        if disposed or state.StopEverything or managed[object]or not effect(object)then return end
        if maintenanceTail-maintenanceHead+1+maintenanceNextTail>=8192 then return end
        local hidden
        if object:IsA("BasePart")then
            if ctx.ExcludeMapPart then ctx.ExcludeMapPart(object)end
            hidden={Transparency=1,LocalTransparencyModifier=1}
        elseif object:IsA("ParticleEmitter")or object:IsA("Beam")or object:IsA("Trail")then hidden={Enabled=false,Transparency=invisible,LocalTransparencyModifier=1}
        elseif object:IsA("Light")then hidden={Brightness=0,Enabled=false}
        elseif object:IsA("Sound")then hidden={Volume=0}
        elseif object:IsA("Decal")or object:IsA("Texture")then hidden={Transparency=1}
        elseif object:IsA("Highlight")then hidden={Enabled=false,FillTransparency=1,OutlineTransparency=1}
        elseif object:IsA("Smoke")or object:IsA("Fire")or object:IsA("Sparkles")or object:IsA("BillboardGui")or object:IsA("SurfaceGui")then hidden={Enabled=false}end
        if not hidden then return end
        local before={}
        for property,value in pairs(hidden)do
            local readable,original=pcall(function()return object[property]end)
            if readable and write(object,property,value)then before[property]=original else hidden[property]=nil end
        end
        if not next(hidden)then return end
        managed[object]={Before=before,Hidden=hidden,Parent=object.Parent}
        if not maintenanceQueued[object]then maintenanceTail+=1;maintenance[maintenanceTail]=object;maintenanceQueued[object]=true end
        if object:IsA("ParticleEmitter")or object:IsA("Trail")then pcall(function()object:Clear()end)end
        api.EffectsHidden+=1
    end
    local function isSkill(track)
        if ordinaryTracks[track]then return false end
        local name=normalize(track.Name)
        if locomotion[name]or name:sub(1,5)=="swing"then return false end
        local asset=track.Animation and id(track.Animation.AnimationId)
        if asset and catalogs.Animation[asset]then return true end
        if asset and catalogs.Ordinary[asset]then return false end
        if catalogs.Skill[name]or track.Priority.Value>=Enum.AnimationPriority.Action.Value then return true end
        return (state.SkillCastRunning or ctx.SkillState and ctx.SkillState.usingSkill~="none")and not locomotion[name]
    end
    api.IsSkillAnimation=isSkill
    function api.MarkGunCast(name,origin)
        if name=="Summon Pistol"or name=="Summon Rifle"then gunOrigin=origin;gunUntil=os.clock()+5 end
    end
    function api.AllowSwingTrack(track)
        ordinaryTracks[track]=true
        local weight=tracks[track];tracks[track]=nil
        if weight and track.IsPlaying then track:AdjustWeight(weight.Weight,0)end
    end
    local function hideTrack(track)
        if disposed or state.StopEverything or not isSkill(track)then return end
        if not tracks[track]then tracks[track]={Weight=track.WeightTarget};api.AnimationsHidden+=1 end
        if math.abs(track.WeightTarget-hiddenWeight)>.00001 or track.WeightCurrent>.001 then track:AdjustWeight(hiddenWeight,0)end
    end
    local eligible={ParticleEmitter=true,Beam=true,Trail=true,Smoke=true,Fire=true,Sparkles=true,Texture=true,Sound=true,Decal=true,BillboardGui=true,SurfaceGui=true,Highlight=true}
    local function candidate(object)return object:IsA("BasePart")or object:IsA("Light")or eligible[object.ClassName]end
    local function queue(object,priority)
        if not disposed and not state.StopEverything and not managed[object]and candidate(object)then pending.Push(object,priority)end
    end
    function api.ProcessPending()
        local deadline=os.clock()+.0006
        local processed=0
        while processed<64 and (processed==0 or os.clock()<deadline)do
            local object=pending.Pop();if not object then break end
            if object.Parent then pcall(suppress,object)end
            processed+=1
        end
        api.Pending=pending.Count;state.VisualQueueSize=api.Pending
    end
    local burst={At=0,Count=0}
    local function added(object)
        if disposed or state.StopEverything or not state.Running then return end
        if object:IsA("Model")and (object.Name=="AR"or object.Name=="Pistol")then
            gunModels[object]=os.clock()+5
            for _,child in ipairs(object:QueryDescendants("BasePart,ParticleEmitter,Beam,Trail,Smoke,Fire,Sparkles,Sound,Decal,Texture"))do queue(child,true)end
        end
        if object:IsA("TextLabel")or object:IsA("TextButton")then
            local gui=object:FindFirstAncestorWhichIsA("BillboardGui")or object:FindFirstAncestorWhichIsA("SurfaceGui")
            if gui and managed[gui]then restore(gui,managed[gui]);managed[gui]=nil end
            return
        end
        if not candidate(object)then return end
        local stamp=os.clock();if stamp-burst.At>=.05 then burst.At=stamp;burst.Count=0 end
        if burst.Count<24 then burst.Count+=1;pcall(suppress,object)end
        queue(object,state.SkillCastRunning or state.MiscCastRunning or object:IsA("ParticleEmitter")or object:IsA("Beam")or object:IsA("Trail")or object:IsA("Sound")or catalogs.Name[normalize(object.Name)])
    end
    connections[1]=workspace.DescendantAdded:Connect(added)
    connections[2]=workspace.DescendantRemoving:Connect(function(object)
        pending.Remove(object)
        local record=managed[object];managed[object]=nil
        if record then restore(object,record)end
    end)
    for _,object in ipairs(workspace:QueryDescendants("ParticleEmitter,Beam,Trail,Smoke,Fire,Sparkles,Light,BasePart,Decal,Texture,BillboardGui,SurfaceGui,Highlight,Sound"))do
        queue(object,false)
        if state.YieldStartup then state.YieldStartup()end
    end
    for _,model in ipairs(workspace:QueryDescendants("#AR,#Pistol"))do if model:IsA("Model")then gunModels[model]=os.clock()+5 end end
    function api.IsEffect(object)return effect(object)end
    function api.ProcessManaged()
        local dynamic=not ctx.DynamicHazards or ctx.DynamicHazards()
        local deadline=os.clock()+.0006
        local available=math.min(64,maintenanceTail-maintenanceHead+1)
        local processed=0
        while processed<available and (processed==0 or os.clock()<deadline)do
            local object=maintenance[maintenanceHead];maintenance[maintenanceHead]=nil;maintenanceHead+=1
            if object then maintenanceQueued[object]=nil end
            local record=object and managed[object]
            if record then
                local protect=false
                pcall(function()protect=object.Parent==nil or (dynamic or object.Parent~=record.Parent)and keep(object)or (object:IsA("BillboardGui")or object:IsA("SurfaceGui"))and keep(object)end)
                if protect then restore(object,record);managed[object]=nil
                else
                    record.Parent=object.Parent
                    for property,value in pairs(record.Hidden)do
                        local ok,current=pcall(function()return object[property]end)
                        if ok then
                            if typeof(value)=="NumberSequence"then
                                local points=current.Keypoints
                                if #points~=2 or points[1].Value~=1 or points[2].Value~=1 then write(object,property,value)end
                            elseif current~=value then write(object,property,value)end
                        end
                    end
                end
                if managed[object]then maintenanceNextTail+=1;maintenanceNext[maintenanceNextTail]=object;maintenanceQueued[object]=true end
            end
            processed+=1
        end
        if maintenanceHead>maintenanceTail then
            table.clear(maintenance);maintenance,maintenanceNext=maintenanceNext,maintenance
            maintenanceHead=1;maintenanceTail=maintenanceNextTail;maintenanceNextTail=0
        end
        return processed
    end
    function api.Update()
        if disposed or state.StopEverything then return end
        api.ProcessPending()
        local stamp=os.clock();if stamp<nextAnimation then return end;nextAnimation=stamp+.08
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local current=humanoid and humanoid:FindFirstChildOfClass("Animator")
        if animator~=current then
            if animationConnection then animationConnection:Disconnect()end
            animator=current;animationConnection=nil
            if current then animationConnection=current.AnimationPlayed:Connect(function(track)
                hideTrack(track);task.defer(function()if not disposed and state.Running and track.IsPlaying then hideTrack(track)end end)
            end)end
        end
        if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks())do hideTrack(track)end end
        for track,record in pairs(tracks)do
            if not track.IsPlaying then tracks[track]=nil
            elseif track.WeightCurrent>.001 or math.abs(track.WeightTarget-hiddenWeight)>.00001 then track:AdjustWeight(hiddenWeight,0)end
        end
        api.ProcessManaged();state.HiddenSkillAnimations=api.AnimationsHidden;state.HiddenSkillEffects=api.EffectsHidden
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        if animationConnection then animationConnection:Disconnect();animationConnection=nil end
        for _,connection in ipairs(connections)do connection:Disconnect()end;table.clear(connections)
        for track,record in pairs(tracks)do pcall(function()if track.IsPlaying then track:AdjustWeight(record.Weight,0)end end)end
        for object,record in pairs(managed)do if object.Parent then restore(object,record)end end
        table.clear(managed);table.clear(tracks);table.clear(gunModels);table.clear(ordinaryTracks)
        table.clear(maintenance);table.clear(maintenanceNext);table.clear(maintenanceQueued)
        maintenanceHead,maintenanceTail,maintenanceNextTail=1,0,0
        pending.Destroy();api.Pending=0;state.VisualQueueSize=0
    end
    api.Update()
    return api
end
