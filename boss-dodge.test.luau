return function(source)
    local world=Instance.new("Folder")
    local signals={}
    local collection={}
    function collection:GetTagged() return {} end
    function collection:GetInstanceAddedSignal(tag) local s=Instance.new("BindableEvent",world); signals[tag]=s; return s.Event end
    local state={AutoDodge=true,PingMs=50}
    local signal=Instance.new("BindableEvent",world)
    local template=Instance.new("Part"); template.Name="Part"; template.Size=Vector3.new(6,6,6); template.Material=Enum.Material.Neon
    local burning=Instance.new("Sound",template); burning.Name="Burning"
    local api=assert(loadstring(source))()({Workspace=world,Collection=collection,State=state,Replicate=signal.Event,
        Projectiles={{Name="PurpleFireyOrb",Template=template,Marker="Burning",Radius=8}}})
    local ok,message=pcall(function()
        local warning=Instance.new("Model"); warning.Name="RedGroundWarning"
        local fill=Instance.new("Part",warning); fill.Anchored=true; fill.Size=Vector3.new(30,.1,30); fill.Transparency=.25
        warning.Parent=world; task.wait()
        local point=api.Plan(Vector3.new(0,-20,0),Vector3.new(0,-20,0))
        assert(point and (point*Vector3.new(1,0,1)).Magnitude>=20,"Leave boss ground warnings even from below a mob")
        assert(api.IsHazardPart(fill) and fill.Transparency==.25,"Keep boss warning visuals intact")
        warning:Destroy(); task.wait(.9)
        assert(not api.Plan(Vector3.new(100,-20,0),Vector3.new(100,-20,0)),"Resume farming when the warning and impact tail expire")
        local circle=Instance.new("Part",world); circle.Name="Circle"; circle.Size=Vector3.new(.1,40,40); circle.CFrame=CFrame.Angles(0,0,math.pi/2)
        signals["AegorSlam Slam"]:Fire(circle); task.wait()
        local point=api.Plan(Vector3.new(0,-20,0),Vector3.new(0,-20,0))
        assert(point and point.Magnitude>25 and api.IsHazardPart(circle),"Recognize native tagged slam markers")
        local ordinary=Instance.new("Part",world); ordinary.Name="Circle"
        assert(not api.IsHazardPart(ordinary),"Do not turn arbitrary player effects into boss hazards")
        circle:Destroy(); task.wait(.9)
        local unrelated=template:Clone(); unrelated.Parent=world; task.wait()
        assert(not api.IsHazardPart(unrelated),"Matching visuals alone must not mark player effects as enemy orbs")
        signal:Fire(nil,"RunPhase","PurpleFireyOrb"); task.wait()
        local orb=template:Clone(); orb.Parent=world; task.wait()
        assert(api.IsHazardPart(orb) and api.Plan(Vector3.zero,Vector3.zero),"Track and evade confirmed enemy-skill projectiles")
        state.AutoDodge=false
        assert(not api.Plan(Vector3.zero,Vector3.zero),"Respect Auto Dodge toggle")
        api.Destroy(); api.Destroy()
        return {Passed=true,GroundWarnings=true,TaggedSlams=true,EnemyProjectiles=true,VisualsPreserved=true,Toggle=true}
    end)
    api.Destroy(); world:Destroy(); template:Destroy(); assert(ok,message); return message
end
