return function(source)
    local root=Instance.new("Folder")
    local hits=Instance.new("Folder",root); hits.Name="HitEffects"
    local part=Instance.new("Part",hits)
    local emitter=Instance.new("ParticleEmitter",part)
    local gui=Instance.new("BillboardGui",part)
    local text=Instance.new("TextLabel",gui); text.Text="3,118 damage / 20 Vel"
    local mobs=Instance.new("Folder",root); mobs.Name="Mobs"
    local function mob(hp)
        local model=Instance.new("Model",mobs)
        local entity=Instance.new("Folder",model); entity.Name="Entity"
        local health=Instance.new("NumberValue",entity); health.Name="Health"; health.Value=hp
        return model
    end
    local called,rendering,cap=0,true,60
    local original=function(payload,extra) called+=1; return payload[1],extra end
    local graphics={ServerEvent=original}
    local uiCalls=0
    local uiOriginal=function(payload,extra) uiCalls+=1; return payload[2],extra end
    local ui={ServerEvent=uiOriginal}
    local state={Running=true}
    local playersHidden=false
    local effectsHidden=false
    local visibility={Set=function(value) playersHidden=value; return true end,SetEffects=function(value) effectsHidden=value; return true end,Destroy=function() playersHidden=false; effectsHidden=false end}
    local api=assert(loadstring(source))()({State=state,Workspace=root,Graphics=graphics,UI=ui,PlayerVisibility=visibility,
        SetRendering=function(value) rendering=value end,GetFPS=function() return cap end,SetFPS=function(value) cap=value end})
    local ok,message=pcall(function()
        assert(api.Set("No damage particles",true) and not emitter.Enabled,"Disable damage emitter")
        assert(gui.Enabled and text.Visible and part.Parent==hits,"Keep damage/Vel text and parent intact")
        local late=Instance.new("Trail",part); task.wait()
        assert(not late.Enabled,"Handle newly spawned hit effects")
        assert(api.Set("No damage particles",false) and emitter.Enabled and late.Enabled,"Restore particle settings")
        assert(api.Set("Delete dead mobs",true))
        local alive,dead=mob(100),mob(0)
        graphics.ServerEvent({"KillFade",alive}); assert(alive.Parent==mobs,"Never delete living mob")
        graphics.ServerEvent({"KillFade",dead}); assert(dead.Parent==nil,"Remove corpse at native KillFade event")
        local first,second=graphics.ServerEvent({"Damage Text"},"keep")
        assert(first=="Damage Text" and second=="keep","Forward damage events and return values")
        assert(api.Set("Delete dead mobs",false) and graphics.ServerEvent==original,"Restore native graphics handler")
        assert(api.Set("No damage text",true))
        local prior=called
        graphics.ServerEvent({"Damage Text"}); assert(called==prior,"Hide only requested damage-text event")
        graphics.ServerEvent({"Other effect"}); assert(called==prior+1,"Keep unrelated graphics events")
        api.Set("Delete dead mobs",true); api.Set("Delete dead mobs",false)
        graphics.ServerEvent({"Damage Text"}); assert(called==prior+1,"Text filter survives corpse-option change")
        api.Set("No damage text",false)
        graphics.ServerEvent({"Damage Text"}); assert(called==prior+2 and graphics.ServerEvent==original,"Show damage text again")
        assert(api.Set("No vel obtained in chat",true))
        ui.ServerEvent({"Notify","VelObtained",20}); assert(uiCalls==0,"Hide only requested Vel notification")
        local first,second=ui.ServerEvent({"Notify","ItemObtained"},"keep")
        assert(uiCalls==1 and first=="ItemObtained" and second=="keep","Keep other chat messages and return values")
        api.Set("No vel obtained in chat",false)
        ui.ServerEvent({"Notify","VelObtained",20}); assert(uiCalls==2 and ui.ServerEvent==uiOriginal,"Show Vel again")
        api.Set("No vel obtained in chat",true); api.Set("No damage text",true)
        assert(api.Set("Hide players",true) and playersHidden,"Enable player visibility control")
        assert(api.Set("Hide effects",true) and effectsHidden,"Enable independent effect visibility control")
        assert(api.Set("Delete dead mobs",true)); api.Set("No damage particles",true)
        api.Set("Disable rendering",true); api.Set("Limit FPS",true)
        assert(not rendering and cap==15,"Apply source resource-saving options")
        state.StopEverything=true
        assert(not api.Set("Limit FPS",false),"Respect master pause")
        api.Destroy(); api.Destroy()
        assert(rendering and cap==60 and emitter.Enabled and graphics.ServerEvent==original and ui.ServerEvent==uiOriginal and not playersHidden and not effectsHidden,"Cleanup restores owned resources")
    end)
    api.Destroy(); root:Destroy()
    assert(ok,message)
    return {Passed=true,TextPreservedByDefault=true,TextToggles=true,AliveMobsPreserved=true,Restoration=true}
end
