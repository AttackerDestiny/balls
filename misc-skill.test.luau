return function(moduleSource)
    local state={MiscSkillEnabled=true,SelectedMiscSkill="Cursed Enhancement",StopEverything=false}
    local snapshot={Health=100,MaxHealth=100,Stamina=20,Cost=60,Cooldown=0,Usable=true,BuffActive=false}
    local calls=0
    local api=assert(loadstring(moduleSource))()({State=state,Read=function() return snapshot end,Cast=function() calls+=1 end})
    local now=os.clock()+1
    api.Update(now)
    assert(not state.MiscReserveStamina and calls==0,"Idle Cursed Enhancement must neither cast nor reserve stamina")
    snapshot.Attacking=true
    api.Update(now+0.3)
    assert(state.MiscReserveStamina and calls==0,"Reserve stamina so attack skills cannot starve the buff")
    snapshot.Stamina=60; api.Update(now+1)
    assert(calls==1,"Cast a ready owned buff with sufficient stamina")
    snapshot.BuffActive=true; api.Update(now+2)
    assert(calls==1 and not state.MiscReserveStamina,"Do not repeatedly cast an active Cursed Enhancement")
    state.SelectedMiscSkill="Heal"; snapshot.Cost=40; snapshot.Health=67
    api.Update(now+3); assert(calls==1,"Do not waste a heal above the source threshold")
    snapshot.Health=66; api.Update(now+4)
    assert(calls==2,"Heal at or below 66 percent")
    snapshot.Cooldown=-5; api.Update(now+5)
    assert(calls==2 and not state.MiscReserveStamina,"Respect native cooldowns")
    snapshot.Cooldown=0; snapshot.Usable=false; api.Update(now+6)
    assert(calls==2,"Never cast a locked skill")
    snapshot.Usable=true; state.StopEverything=true; api.Update(now+7)
    assert(calls==2 and not state.MiscReserveStamina,"Stop Everything must release the reservation and block support casting")
    assert(api.Needed("Summon Tree",{Stamina=66}) and not api.Needed("Summon Tree",{Stamina=67}),"Preserve the source stamina threshold")
    state.StopEverything=false;state.SelectedMiscSkill="Cursed Enhancement";snapshot.BuffActive=false;snapshot.Attacking=false
    api.Update(now+8);assert(calls==2 and not state.MiscReserveStamina,"Release stamina when attacks stop")
    return {Passed=true,StaminaReserved=true,ThresholdsChecked=true,NoBuffStackSpam=true,PauseRespected=true}
end
