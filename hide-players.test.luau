return function(source)
    local root=Instance.new("Folder")
    local items=Instance.new("Folder",root); items.Name="CharacterItems"
    local events={}
    local function event() local e=Instance.new("BindableEvent",root); events[#events+1]=e; return e end
    local function character()
        local m=Instance.new("Model",root)
        local body=Instance.new("Part",m); body.Transparency=.2; body.CanCollide=true
        local humanoid=Instance.new("Humanoid",m)
        return m,body,humanoid
    end
    local nextId=0
    local function player()
        nextId+=1
        local a,r=event(),event()
        local c,p,h=character()
        return {UserId=nextId,Character=c,CharacterAdded=a.Event,CharacterRemoving=r.Event,Added=a,Removing=r},p,h
    end
    local mine,myBody=player()
    local other,body=player()
    local joined,left=event(),event()
    local service={LocalPlayer=mine,PlayerAdded=joined.Event,PlayerRemoving=left.Event}
    function service:GetPlayers() return {mine,other} end
    local ownItems=Instance.new("Folder",items); ownItems.Name=tostring(mine.UserId)
    local ownSword=Instance.new("Part",ownItems)
    local otherItems=Instance.new("Folder",items); otherItems.Name=tostring(other.UserId)
    local sword=Instance.new("Part",otherItems)
    local aura=Instance.new("ParticleEmitter",sword)
    local nameplate=Instance.new("SurfaceGui",body)
    local effectsCalled=0
    local original=function(name,data,extra) effectsCalled+=1; return name,extra end
    local effects={DoEffect=original}
    local api=assert(loadstring(source))()({Players=service,Workspace=root,EffectServices={effects}})
    local ok,message=pcall(function()
        api.Set(true)
        assert(math.abs(myBody.Transparency-.2)<1e-6,"Never hide local character")
        assert(body.Transparency==1 and not body.CastShadow and body.CanCollide,"Hide other player without changing collisions")
        assert(sword.Transparency==1 and sword.LocalTransparencyModifier==1 and not aura.Enabled,"Hide detached weapons, pets and auras")
        assert(ownSword.Transparency==0,"Keep own detached equipment visible")
        nameplate.Enabled=true; aura.Enabled=true; task.wait()
        assert(not nameplate.Enabled and not aura.Enabled,"Native graphics must not reenable hidden names or auras")
        effects.DoEffect("Skill",{Character=other.Character})
        assert(effectsCalled==0,"Block other-player skill effects before spawning")
        effects.DoEffect("Skill",{Character=mine.Character})
        effects.DoEffect("Hazard",{Target=other.Character})
        effects.DoEffect("Damage Text",{Character=other.Character})
        assert(effectsCalled==3,"Keep own effects, target-only hazard cues and damage text")
        local first,second=effects.DoEffect("Skill",{Player=mine},"keep")
        assert(first=="Skill" and second=="keep","Preserve callback arguments and return values")
        local late=Instance.new("Part",other.Character); task.wait()
        assert(late.Transparency==1,"Hide streamed character parts")
        local equipment=Instance.new("Part",otherItems); task.wait()
        assert(equipment.Transparency==1,"Hide newly equipped detached parts")
        local newCharacter,newBody=character()
        other.Removing:Fire(other.Character); other.Character=newCharacter; other.Added:Fire(newCharacter); task.wait()
        assert(math.abs(body.Transparency-.2)<1e-6 and newBody.Transparency==1,"Restore old character and hide respawn")
        local newcomer,newcomerBody=player(); joined:Fire(newcomer); task.wait()
        assert(newcomerBody.Transparency==1,"Hide newly joined players")
        api.Set(false)
        assert(math.abs(newBody.Transparency-.2)<1e-6 and math.abs(newcomerBody.Transparency-.2)<1e-6 and math.abs(myBody.Transparency-.2)<1e-6,"Restore all original visibility on disable")
        assert(sword.Transparency==0 and sword.LocalTransparencyModifier==0 and aura.Enabled and nameplate.Enabled and effects.DoEffect==original,"Restore equipment, effects, GUI and native callback")
        api.SetEffects(true)
        assert(math.abs(newBody.Transparency-.2)<1e-6 and sword.Transparency==0 and sword.LocalTransparencyModifier==0,"Effects-only mode must keep characters and equipment visible")
        assert(not aura.Enabled and ownSword.Transparency==0,"Hide other auras while preserving own equipment")
        local newNameplate=Instance.new("SurfaceGui",newBody)
        local newAura=Instance.new("ParticleEmitter",newBody); task.wait()
        assert(newNameplate.Enabled and not newAura.Enabled,"Keep names visible while hiding new effects")
        local beforeEffects=effectsCalled
        effects.DoEffect("Skill",{Character=other.Character})
        assert(effectsCalled==beforeEffects,"Effects-only mode blocks other-player skill visuals")
        api.Set(true); assert(newBody.Transparency==1,"Combine both boosters")
        api.Set(false)
        assert(math.abs(newBody.Transparency-.2)<1e-6 and not aura.Enabled and not newAura.Enabled and newNameplate.Enabled,"Turning Hide players off must retain Hide effects")
        api.SetEffects(false)
        assert(aura.Enabled and newAura.Enabled and effects.DoEffect==original,"Restore all effects when both boosters are off")
        api.Set(true); api.Destroy(); api.Destroy()
        assert(math.abs(newBody.Transparency-.2)<1e-6,"Restore after reload cleanup")
    end)
    api.Destroy(); root:Destroy(); assert(ok,message)
    return {Passed=true,LocalCharacterVisible=true,DetachedEquipment=true,EffectOwnership=true,EffectsOnly=true,CombinedToggles=true,Nameplates=true,RespawnAndJoin=true,PhysicsPreserved=true,Restoration=true}
end
