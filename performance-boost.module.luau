-- Effective booster policy is derived from individual selections plus one aggregate mode.
return function(ctx)
    local state=ctx.State
    local api={Names={"No damage text","No damage particles","Delete dead mobs","No vel obtained in chat","Hide players","Hide effects","Delete map","Remove animations","Disable rendering","Limit FPS","Remove everything"}}
    local selected,known={},{}
    for _,name in ipairs(api.Names)do known[name]=true;selected[name]=ctx.Options and ctx.Options[name]==true end
    state.PerformanceBoosters=selected
    local owned={Closed=false,Visible=false,Rendering=false,FPS=false}
    local initialCap
    if ctx.GetFPS then local ok,value=pcall(ctx.GetFPS);if ok and type(value)=="number"then initialCap=value end end
    local transparent=NumberSequence.new(1)
    local particles={Folder=nil,Connections={},Values={}}
    local function desired(name)return selected[name]==true or selected["Remove everything"]==true end
    local function live(name)return not owned.Closed and not ctx.Paused and state and state.Running and not state.StopEverything and desired(name)end
    local function releaseParticle(item)
        local before=particles.Values[item]
        if not before then return end
        particles.Values[item]=nil
        pcall(function()item.Enabled=before[1];item.Transparency=before[2]end)
    end
    local function hideParticle(item)
        if not live("No damage particles")or particles.Values[item]then return end
        if not(item:IsA("ParticleEmitter")or item:IsA("Beam")or item:IsA("Trail"))then return end
        particles.Values[item]={item.Enabled,item.Transparency}
        item.Enabled=false;item.Transparency=transparent
        if item:IsA("ParticleEmitter")then pcall(function()item:Clear()end)end
    end
    local function detachParticles()
        for _,connection in ipairs(particles.Connections)do connection:Disconnect()end
        table.clear(particles.Connections)
        for item in pairs(particles.Values)do releaseParticle(item)end
        particles.Folder=nil
    end
    local function syncParticles()
        local folder=desired("No damage particles")and ctx.Workspace:FindFirstChild("HitEffects")or nil
        if folder==particles.Folder then return end
        detachParticles();particles.Folder=folder
        if not folder then return end
        particles.Connections={folder.DescendantAdded:Connect(hideParticle),folder.DescendantRemoving:Connect(releaseParticle)}
        for _,item in ipairs(folder:QueryDescendants("ParticleEmitter,Beam,Trail"))do hideParticle(item)end
    end
    local function corpse(payload)
        local mob=payload[2]
        local folder=ctx.Workspace:FindFirstChild("Mobs")
        if typeof(mob)~="Instance"or not folder or not mob:IsA("Model")or not mob:IsDescendantOf(folder)then return false end
        local entity=mob:FindFirstChild("Entity")
        local health=entity and entity:FindFirstChild("Health")
        if not health or health.Value>0 then return false end
        mob:Destroy();return true
    end
    local hooks={}
    local function hook(key,service,predicate,enabled)
        local lease=hooks[key]
        if not enabled then
            if lease and service.ServerEvent==lease.Wrapper then service.ServerEvent=lease.Before end
            hooks[key]=nil;return
        end
        if lease and service.ServerEvent==lease.Wrapper then return end
        local previous=service.ServerEvent
        local wrapper=function(payload,...)
            if not owned.Closed and predicate(payload)then return end
            return previous(payload,...)
        end
        service.ServerEvent=wrapper;hooks[key]={Before=previous,Wrapper=wrapper,Service=service}
    end
    local function graphicsPolicy(payload)
        if type(payload)~="table"then return false end
        if payload[1]=="Damage Text"and live("No damage text")then return true end
        return payload[1]=="KillFade"and live("Delete dead mobs")and corpse(payload)
    end
    local function uiPolicy(payload)return type(payload)=="table"and payload[2]=="VelObtained"and live("No vel obtained in chat")end
    local function syncFPS()
        local limited=selected["Limit FPS"]and not selected["Remove everything"]
        if limited or owned.FPS then
            assert(ctx.SetFPS and initialCap~=nil,"FPS cap control is unavailable")
            ctx.SetFPS(limited and (owned.Visible and 60 or 15)or initialCap)
        end
        owned.FPS=limited==true
    end
    local effects={
        ["Disable rendering"]=function()ctx.SetRendering(not desired("Disable rendering"));owned.Rendering=desired("Disable rendering")end,
        ["Limit FPS"]=syncFPS,
        ["Hide players"]=function()assert(ctx.PlayerVisibility and ctx.PlayerVisibility.Set(desired("Hide players")),"Player visibility is unavailable")end,
        ["Hide effects"]=function()assert(ctx.PlayerVisibility and ctx.PlayerVisibility.SetEffects(desired("Hide effects")),"Effect visibility is unavailable")end,
        ["Delete map"]=function()if state.MapDeletion then state.MapDeletion.Set(desired("Delete map"))end end,
        ["Remove animations"]=function()if state.AnimationRemoval then state.AnimationRemoval.Set(desired("Remove animations"))end end,
        ["No damage particles"]=syncParticles,
    }
    local function sync(name)
        if name=="Remove everything"then
            for _,key in ipairs({"Disable rendering","Limit FPS","Hide players","Hide effects","Delete map","Remove animations","No damage particles"})do effects[key]()end
        elseif effects[name]then effects[name]()end
        if name=="Remove everything"or name=="No damage text"or name=="Delete dead mobs"then
            hook("Graphics",ctx.Graphics,graphicsPolicy,desired("No damage text")or desired("Delete dead mobs"))
        end
        if name=="Remove everything"or name=="No vel obtained in chat"then hook("UI",ctx.UI,uiPolicy,desired("No vel obtained in chat"))end
    end
    local rootConnection=ctx.Workspace.ChildAdded:Connect(function(item)
        if item.Name=="HitEffects"and live("No damage particles")then syncParticles()end
    end)
    function api.SetUIVisible(value)
        value=value==true
        if owned.Closed or owned.Visible==value then return end
        owned.Visible=value
        if owned.FPS then local ok,reason=pcall(syncFPS);if not ok then state.LastBoostError=tostring(reason)end end
    end
    function api.Set(name,value)
        if owned.Closed or ctx.Paused or not known[name]or state.StopEverything then return false end
        local old=selected[name];selected[name]=value==true
        local applied,reason=pcall(sync,name)
        if not applied then selected[name]=old;pcall(sync,name);state.LastBoostError=tostring(reason);return false end
        if ctx.Changed then ctx.Changed()end
        return true
    end
    function api.Destroy()
        if owned.Closed then return end
        owned.Closed=true;rootConnection:Disconnect();detachParticles()
        for key,lease in pairs(hooks)do hook(key,lease.Service,nil,false)end
        for _,object in pairs({state.MapDeletion,state.AnimationRemoval,ctx.PlayerVisibility})do if object then pcall(object.Destroy)end end
        if owned.Rendering then pcall(ctx.SetRendering,true)end
        if owned.FPS then pcall(ctx.SetFPS,initialCap)end
        state=nil;ctx.State=nil;ctx.Changed=nil;ctx.PlayerVisibility=nil
    end
    if not ctx.Paused and not state.StopEverything then
        for _,name in ipairs(api.Names)do if selected[name]then selected[name]=false;api.Set(name,true)end end
    end
    return api
end
