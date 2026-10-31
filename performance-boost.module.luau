-- Source performance options; text is visible unless explicitly hidden.
return function(ctx)
    local state=ctx.State
    local api={Names={"No damage text","No damage particles","Delete dead mobs","No vel obtained in chat","Hide players","Hide effects","Disable rendering","Limit FPS"}}
    local options,known={},{}
    for _,name in ipairs(api.Names) do known[name]=true; options[name]=ctx.Options and ctx.Options[name]==true end
    state.PerformanceBoosters=options
    local disposed=false
    local hitFolder,added,removed
    local particles={}
    local invisible=NumberSequence.new(1)
    local graphics=ctx.Graphics
    local original,wrapper
    local uiOriginal,uiWrapper
    local renderOwned,fpsOwned=false,false
    local oldCap
    if ctx.GetFPS then local ok,value=pcall(ctx.GetFPS); if ok and type(value)=="number" then oldCap=value end end
    local function active(name) return not disposed and not ctx.Paused and state.Running and not state.StopEverything and options[name] end
    local function restoreParticles()
        for instance,record in pairs(particles) do pcall(function() instance.Enabled=record.Enabled; instance.Transparency=record.Transparency end) end
        table.clear(particles)
    end
    local function suppress(instance)
        if not active("No damage particles") or particles[instance] then return end
        if not (instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail")) then return end
        particles[instance]={Enabled=instance.Enabled,Transparency=instance.Transparency}
        instance.Enabled=false; instance.Transparency=invisible
        if instance:IsA("ParticleEmitter") then instance:Clear() end
    end
    local function detachParticles()
        if added then added:Disconnect(); added=nil end
        if removed then removed:Disconnect(); removed=nil end
        restoreParticles(); hitFolder=nil
    end
    local function attachParticles()
        local folder=ctx.Workspace:FindFirstChild("HitEffects")
        if folder==hitFolder then return end
        detachParticles(); hitFolder=folder
        if not folder then return end
        added=folder.DescendantAdded:Connect(suppress)
        removed=folder.DescendantRemoving:Connect(function(instance)
            local record=particles[instance]
            if record then pcall(function() instance.Enabled=record.Enabled; instance.Transparency=record.Transparency end); particles[instance]=nil end
        end)
        for _,instance in ipairs(folder:QueryDescendants("ParticleEmitter,Beam,Trail")) do suppress(instance) end
    end
    local function hookGraphics()
        if wrapper and graphics.ServerEvent==wrapper then return end
        original=graphics.ServerEvent
        local previous=original
        wrapper=function(payload,...)
            if active("No damage text") and type(payload)=="table" and payload[1]=="Damage Text" then return end
            if active("Delete dead mobs") and type(payload)=="table" and payload[1]=="KillFade" then
                local mob=payload[2]
                local mobs=ctx.Workspace:FindFirstChild("Mobs")
                if typeof(mob)=="Instance" and mob:IsA("Model") and mobs and mob:IsDescendantOf(mobs) then
                    local entity=mob:FindFirstChild("Entity")
                    local health=entity and entity:FindFirstChild("Health")
                    if health and health.Value<=0 then mob:Destroy(); return end
                end
            end
            return previous(payload,...)
        end
        graphics.ServerEvent=wrapper
    end
    local function unhookGraphics()
        if wrapper and graphics.ServerEvent==wrapper then graphics.ServerEvent=original end
        -- A newer wrapper may still call ours; keep its captured original valid.
    end
    local function hookUI()
        if uiWrapper and ctx.UI.ServerEvent==uiWrapper then return end
        uiOriginal=ctx.UI.ServerEvent
        local previous=uiOriginal
        uiWrapper=function(payload,...)
            if active("No vel obtained in chat") and type(payload)=="table" and payload[2]=="VelObtained" then return end
            return previous(payload,...)
        end
        ctx.UI.ServerEvent=uiWrapper
    end
    local function unhookUI()
        if uiWrapper and ctx.UI.ServerEvent==uiWrapper then ctx.UI.ServerEvent=uiOriginal end
    end
    local rootAdded=ctx.Workspace.ChildAdded:Connect(function(instance)
        if instance.Name=="HitEffects" and active("No damage particles") then attachParticles() end
    end)
    function api.Set(name,enabled)
        if disposed or ctx.Paused or not known[name] or state.StopEverything then return false end
        enabled=enabled==true
        if name=="Disable rendering" then
            local ok,message=pcall(ctx.SetRendering,not enabled)
            if not ok then state.LastBoostError=tostring(message); return false end
            renderOwned=enabled
        elseif name=="Limit FPS" then
            if not ctx.SetFPS or oldCap==nil then state.LastBoostError="FPS cap control is unavailable"; return false end
            local ok,message=pcall(ctx.SetFPS,enabled and 15 or oldCap)
            if not ok then state.LastBoostError=tostring(message); return false end
            fpsOwned=enabled
        elseif name=="Hide players" then
            if not ctx.PlayerVisibility or not ctx.PlayerVisibility.Set(enabled) then return false end
        elseif name=="Hide effects" then
            if not ctx.PlayerVisibility or not ctx.PlayerVisibility.SetEffects(enabled) then return false end
        end
        options[name]=enabled
        if name=="No damage particles" then if enabled then attachParticles() else detachParticles() end end
        if name=="Delete dead mobs" or name=="No damage text" then
            if options["Delete dead mobs"] or options["No damage text"] then hookGraphics() else unhookGraphics() end
        end
        if name=="No vel obtained in chat" then if enabled then hookUI() else unhookUI() end end
        if ctx.Changed then ctx.Changed() end
        return true
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        rootAdded:Disconnect(); detachParticles(); unhookGraphics(); unhookUI()
        if ctx.PlayerVisibility then ctx.PlayerVisibility.Destroy() end
        if renderOwned then pcall(ctx.SetRendering,true); renderOwned=false end
        if fpsOwned then pcall(ctx.SetFPS,oldCap); fpsOwned=false end
    end
    if not ctx.Paused and not state.StopEverything then
        for _,name in ipairs(api.Names) do
            if options[name] then options[name]=false; api.Set(name,true) end
        end
    end
    return api
end
