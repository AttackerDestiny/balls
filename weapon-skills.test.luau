return function(moduleSource)
    local state={SelectedSkill="Piercing Dash"}
    local key,style="rapier:0","Rapier"
    local character={}
    local cancels=0
    local choices={{Name="Piercing Dash",Allowed=true},{Name="Reaper Frenzy",Allowed=false},{Name="Summon Pistol",Allowed=true}}
    local api=assert(loadstring(moduleSource))()({State=state,Key=function() return key,character end,
        Read=function() return {Style=style,Skills=choices} end,Cancel=function() cancels+=1 end})
    local time=os.clock()+1
    api.Update(time); api.Update(time+.2)
    assert(api.Ready and api.IsCompatible("Piercing Dash"),"Resolve initial equipped class")
    assert(api.Select("Summon Pistol"),"Remember a manual general skill for this weapon class")
    local version=api.Version
    key,style="scythe:0","Scythe"
    choices={{Name="Piercing Dash",Allowed=false},{Name="Reaper Frenzy",Allowed=true},{Name="Summon Pistol",Allowed=true}}
    api.Update(time+.5)
    assert(not api.Ready and api.Version>version and not api.IsCompatible("Piercing Dash"),"Cancel stale casts immediately during weapon changes")
    api.Update(time+.7)
    assert(state.SelectedSkill=="Reaper Frenzy" and api.IsCompatible("Reaper Frenzy"),"Switch to the new weapon's usable skill")
    assert(not api.Select("Piercing Dash"),"Do not permit an incompatible old skill")
    key,style="rapier:0","Rapier"
    choices={{Name="Piercing Dash",Allowed=true},{Name="Reaper Frenzy",Allowed=false},{Name="Summon Pistol",Allowed=true}}
    api.Update(time+1); api.Update(time+1.2)
    assert(state.SelectedSkill=="Summon Pistol","Restore the manual per-weapon selection without carrying it into new classes")
    assert(api.Class("1HSword")=="SingleSword","Normalize the class alias used in the supplied source")
    assert(cancels>=3,"Every equipment transition must invalidate old work")
    return {Passed=true,AutomaticClassSwitch=true,StaleCastInvalidated=true,PerWeaponPreference=true}
end
