return function(moduleSource)
    local create=assert(loadstring(moduleSource))()
    local entity=Instance.new("Folder")
    local stamina=Instance.new("NumberValue",entity);stamina.Name="Stamina";stamina.Value=100
    local definition=Instance.new("Folder")
    local cost=Instance.new("NumberValue",definition);cost.Name="Cost";cost.Value=35
    local cooldown=Instance.new("NumberValue",definition);cooldown.Name="Cooldown";cooldown.Value=4
    local root=Instance.new("Part",entity)
    local time,untilTime,calls=0,0,0
    local skills={usingSkill="none",GetCooldown=function()return time-untilTime end,SetCooldown=function(_,value)untilTime=time+value end}
    local enabled,acknowledge=true,true
    local expectedName="Beam Rush"
    local api=create({State={PingMs=25},Skills=skills,Clock=function()return time end,Wait=function(dt)time+=dt end,
        CanRun=function()return enabled end,SkillUsed=function()end,
        Emit=function(name,options)
            calls+=1
            assert(name==expectedName and typeof(options.Direction)=="Vector3","Use selected skill and explicit direction")
            if acknowledge then stamina.Value-=35 end
        end})
    local ok,result=pcall(function()
        assert(api.Begin("Beam Rush",definition,entity,root),"Wait for an acknowledged activation")
        assert(calls==1 and skills.usingSkill=="Beam Rush","Only one active skill can own the cast")
        assert(not api.Begin("Beam Rush",definition,entity,root) and calls==1,"Do not duplicate an active skill")
        api.Release();assert(skills.usingSkill=="none","Release native skill ownership")
        time=5;stamina.Value=5
        assert(not api.Begin("Beam Rush",definition,entity,root) and calls==1,"Respect stamina")
        stamina.Value=100;enabled=false
        assert(not api.Begin("Beam Rush",definition,entity,root) and calls==1,"Respect dodge/travel interruption")
        enabled=true;acknowledge=false
        assert(not api.Begin("Beam Rush",definition,entity,root),"Reject an unacknowledged start")
        api.Release()
        assert(not api.CanHandle("Beam Rush"),"Back off briefly after missing acknowledgment")
        api.Reset()
        assert(api.CanHandle("Beam Rush") and api.CanHandle("Reaper Frenzy") and api.CanHandle("Whirlwind Spin"),"Weapon changes must clear failed attempts and support scythe/dual-wield")
        assert(not api.CanHandle("Unsupported skill"),"Unknown skills require an explicit resolver")
        time=10; expectedName="Summon Pistol"; acknowledge=true; stamina.Value=100
        local ack,_,pistol=api.Begin(expectedName,definition,entity,root,nil,nil,Vector3.yAxis)
        assert(ack and pistol.Direction==Vector3.yAxis,"Aim gun at the target's actual vertical direction")
        assert(pistol.SourceWindow and pistol.FirstHitAt==pistol.Started and math.abs(pistol.ExpiresAt-pistol.Started-.2)<.001,"Pistol uses the supplied source's immediate 0.2s active window")
        api.Release(); time=20; expectedName="Summon Rifle"; stamina.Value=100
        local ack,_,rifle=api.Begin(expectedName,definition,entity,root)
        assert(ack and rifle.SourceWindow and rifle.HoldWindow and rifle.ExpiresAt-rifle.Started==3 and rifle.RefreshTargets and rifle.MinimumInterval==.3,"Rifle uses the full active window with the source per-target cooldown and live retargeting")
        return {Passed=true,NoDuplicateCasts=true,ResourcesRespected=true,WeaponReset=true,GunTiming=true,VerticalAim=true,ScytheWindow=api.Window("Reaper Frenzy")}
    end)
    api.Release();entity:Destroy();definition:Destroy()
    if not ok then error(result)end
    return result
end
