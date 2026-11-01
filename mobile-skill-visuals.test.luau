-- Property-denial doubles reproduce mobile executor failures without Roblox.
return function(source)
    local managed,api={}, {EffectsHidden=0}
    local state={}
    local invisible={Invisible=true}
    local chunk=assert(loadstring(source.."\nreturn suppress,restore"))
    setfenv(chunk,setmetatable({state=state,managed=managed,api=api,ctx={},invisible=invisible,maintenance={},maintenanceQueued={},maintenanceTail=0,
        effect=function(instance)return not instance.Protected end},{__index=getfenv()}))
    local suppress,restore=chunk()
    local function instance(class,denied)
        local values={Parent=true,Enabled=true,Transparency=.25,LocalTransparencyModifier=0,Volume=.6,
            Brightness=2,CanTouch=true,CanQuery=true,CanCollide=false,ClearCalls=0}
        local obj={}
        function obj:IsA(name)return name==class or (class=="PointLight"and name=="Light")end
        function obj:Clear()values.ClearCalls+=1;if denied=="Clear"then error("unsupported Clear")end end
        setmetatable(obj,{__index=function(_,key)if key==denied then error("unsupported member")end;return values[key]end,
            __newindex=function(_,key,value)if key==denied then error("denied write")end;values[key]=value end})
        return obj,values
    end
    for _,class in ipairs({"ParticleEmitter","Beam","Trail","BasePart"})do
        local obj,v=instance(class,"LocalTransparencyModifier");suppress(obj)
        assert(managed[obj] and api.EffectsHidden>0)
        assert(v.CanTouch and v.CanQuery and not v.CanCollide)
        if class=="BasePart"then assert(v.Transparency==1)
        else assert(not v.Enabled and v.Transparency==invisible)end
        restore(obj,managed[obj]);assert(v.Enabled and v.Transparency==.25)
    end
    local bad=instance("ParticleEmitter","Clear");suppress(bad);assert(managed[bad])
    local good,v=instance("Sound");suppress(good);assert(v.Volume==0)
    for _,class in ipairs({"Smoke","Fire","Sparkles","PointLight"})do
        local obj,v=instance(class);suppress(obj);assert(not v.Enabled);restore(obj,managed[obj]);assert(v.Enabled)
    end
    local protected,v=instance("ParticleEmitter");protected.Protected=true;suppress(protected)
    assert(v.Enabled and not managed[protected])
    state.StopEverything=true;local stopped,v=instance("Beam");suppress(stopped);assert(v.Enabled)
    print("PASS Mobile VFX: unsupported properties, particle/trail Clear errors, fallback rendering, physics intact, cleanup, protected cues, stop")
end
