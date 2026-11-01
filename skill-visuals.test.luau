return function(moduleSource)
    local fixture=Instance.new("Folder")
    local added,removed=Instance.new("BindableEvent"),Instance.new("BindableEvent")
    local definitions=Instance.new("Folder",fixture)
    local definition=Instance.new("Folder",definitions); definition.Name="Beam Rush"
    local skills,effects=Instance.new("Folder",fixture),Instance.new("Folder",fixture)
    local animation=Instance.new("Animation",effects); animation.AnimationId="rbxassetid://123"
    local character=Instance.new("Model",fixture)
    local body=Instance.new("Part",character); body.Name="Torso"
    local root=Instance.new("Part",character); root.Name="HumanoidRootPart"; root.Position=Vector3.new(1000,0,0)
    local visual=Instance.new("Model",fixture); visual.Name="Beam Rush"
    local hitbox=Instance.new("Part",visual); hitbox.Name="Hitbox"; hitbox.Size=Vector3.new(5,6,7)
    local emitter=Instance.new("ParticleEmitter",hitbox)
    local beam=Instance.new("Beam",hitbox)
    local sound=Instance.new("Sound",visual); sound.Volume=.6
    local hazard=Instance.new("Part",fixture); hazard.Name="Beam Rush"
    local damageGui=Instance.new("BillboardGui",hitbox)
    local damageText=Instance.new("TextLabel",damageGui); damageText.Text="2,602"
    local velGui=Instance.new("SurfaceGui",hitbox)
    local velText=Instance.new("TextLabel",velGui); velText.Text="20 Vel obtained"
    local tracer=Instance.new("Part",fixture); tracer.Name="Part"; tracer.Anchored=true; tracer.CanCollide=false
    tracer.Material=Enum.Material.Neon; tracer.BrickColor=BrickColor.new("Bright yellow")
    local rifleTracer=Instance.new("Part",fixture); rifleTracer.Name="Part"; rifleTracer.CanCollide=false
    rifleTracer.Size=Vector3.new(.9,.9,55)
    rifleTracer.Position=Vector3.new(1002,0,0)
    rifleTracer.Material=Enum.Material.Neon; rifleTracer.BrickColor=BrickColor.new("Bright blue")
    local rifle=Instance.new("Model",fixture); rifle.Name="AR"
    local gun=Instance.new("Part",rifle); gun.Name="Gun"
    local portal=Instance.new("Part",rifle); portal.Name="Portal1"
    local items=Instance.new("Folder",fixture); items.Name="CharacterItems"
    local otherItems=Instance.new("Folder",items); otherItems.Name="2"
    local otherEffect=Instance.new("Model",otherItems); otherEffect.Name="Beam Rush"
    local otherPart=Instance.new("Part",otherEffect)
    local fakeWorkspace={DescendantAdded=added.Event,DescendantRemoving=removed.Event}
    function fakeWorkspace:FindFirstChild(name) if name=="CharacterItems" then return items end return nil end
    function fakeWorkspace:QueryDescendants() return {hitbox,emitter,beam,sound,hazard,body,damageGui,velGui,tracer,gun,portal,otherPart} end
    local environment=setmetatable({workspace=fakeWorkspace,game={Players={LocalPlayer={Character=character,UserId=1}},ReplicatedStorage={Database={Skills=definitions}}}},{__index=getfenv()})
    local chunk=assert(loadstring(moduleSource)); setfenv(chunk,environment)
    local state={Running=true}
    local api=chunk()({State=state,Services={Skills=skills,SkillEffects=effects},Actions={animations={}},Preserve=function(instance) return instance==hazard end})
    local ok,result=pcall(function()
        assert(hitbox.LocalTransparencyModifier==1 and emitter.LocalTransparencyModifier==1 and beam.LocalTransparencyModifier==1,"Skill visuals must be hidden")
        assert(not emitter.Enabled and not beam.Enabled and sound.Volume==0,"Explicit particle bursts and skill sound must be hidden")
        assert(hitbox.CanTouch and hitbox.CanQuery and hitbox.Size==Vector3.new(5,6,7),"Rendering suppression must preserve hitbox physics")
        assert(hazard.LocalTransparencyModifier==0 and body.LocalTransparencyModifier==0,"Hazard cues and character body must stay visible")
        assert(otherPart.LocalTransparencyModifier==0,"Other players' equipment visibility belongs to the separate Hide players control")
        assert(damageGui.Enabled and velGui.Enabled,"Keep floating damage and Vel text visible even inside skill-effect containers")
        api.MarkGunCast("Summon Pistol",Vector3.zero)
        added:Fire(tracer); task.wait(.02); api.ProcessPending()
        assert(tracer.LocalTransparencyModifier==1 and tracer.Anchored and not tracer.CanCollide,"Hide anonymous gun tracers without changing their physics")
        api.MarkGunCast("Summon Rifle",Vector3.zero)
        added:Fire(rifleTracer); task.wait(.02); api.ProcessPending()
        assert(rifleTracer.LocalTransparencyModifier==1 and not rifleTracer.CanCollide,"Hide native blue rifle projectiles as well as yellow pistol projectiles")
        local remoteGun=Instance.new("Model",fixture); remoteGun.Name="AR"
        local gunPart=Instance.new("Part",remoteGun); gunPart.Name="Gun"; gunPart.Position=Vector3.new(2000,0,0)
        local portal=Instance.new("Part",remoteGun); portal.Name="Portal1"
        added:Fire(remoteGun)
        local remoteTracer=rifleTracer:Clone(); remoteTracer.LocalTransparencyModifier=0; remoteTracer.Position=Vector3.new(2002,0,0); remoteTracer.Parent=fixture
        added:Fire(remoteTracer); task.wait(.02); api.ProcessPending()
        assert(remoteTracer.LocalTransparencyModifier==1,"Follow every active rifle model, including gun effects away from the original player position")
        local sphere=Instance.new("Part",fixture); sphere.Name="Part"; sphere.Shape=Enum.PartType.Ball; sphere.Size=Vector3.new(10,10,10)
        sphere.Position=Vector3.new(1002,0,0); sphere.Transparency=1; sphere.CanCollide=false
        local decal=Instance.new("Decal",sphere); decal.Texture="rbxassetid://999999"
        local light=Instance.new("PointLight",sphere); light.Brightness=2
        local impactSound=Instance.new("Sound",sphere); impactSound.Volume=.5
        added:Fire(decal); added:Fire(light); added:Fire(impactSound); task.wait(.02); api.ProcessPending()
        assert(decal.Transparency==1 and light.Brightness==0 and impactSound.Volume==0 and not sphere.CanCollide,"Hide impact-sphere decals and glow without touching hitbox physics")
        assert(gun.LocalTransparencyModifier==1 and portal.LocalTransparencyModifier==1,"Hide the native rifle model named AR")
        assert(api.IsSkillAnimation({Name="Animation",Animation=animation,Priority=Enum.AnimationPriority.Action3}),"Generic native skill animation names must be recognized")
        assert(not api.IsSkillAnimation({Name="Idle",Animation=animation,Priority=Enum.AnimationPriority.Idle}),"Locomotion must remain available")
        assert(not api.IsSkillAnimation({Name="Swing1",Priority=Enum.AnimationPriority.Action}),"Normal sword swing must stay available")
        local ordinary={Name="Animation",Animation=animation,Priority=Enum.AnimationPriority.Action3}
        api.AllowSwingTrack(ordinary)
        assert(not api.IsSkillAnimation(ordinary),"Continuous swings must remain visible after changing animation packs")
        api.Destroy()
        assert(hitbox.LocalTransparencyModifier==0 and emitter.Enabled and beam.Enabled and math.abs(sound.Volume-.6)<.001,"Stopping the script must restore rendering properties")
        return {Passed=true,HitboxesPreserved=true,HazardsVisible=true,PropertiesRestored=true}
    end)
    fixture:Destroy(); added:Destroy(); removed:Destroy()
    if not ok then error(result) end
    return result
end
