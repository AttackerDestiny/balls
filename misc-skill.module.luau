return function(ctx)
    local state=ctx.State
    local api={Names={"Cursed Enhancement","Heal","Mending Spirit","Summon Tree"}}
    local nextCheck,nextAttempt=0,0
    function api.Needed(name,snapshot)
        if name=="Heal" or name=="Mending Spirit" then return snapshot.Health/snapshot.MaxHealth<=.66 end
        if name=="Summon Tree" then return snapshot.Stamina<=66 end
        if name=="Cursed Enhancement" then return snapshot.Attacking==true and not snapshot.BuffActive end
        return false
    end
    function api.Update(now)
        now=now or os.clock()
        if not state.MiscSkillEnabled or state.StopEverything then state.MiscReserveStamina=false; return end
        if state.MiscCastRunning then state.MiscReserveStamina=true; return end
        if now<nextCheck then return end
        nextCheck=now+.2
        local snapshot=ctx.Read(state.SelectedMiscSkill)
        if not snapshot or not snapshot.Usable or snapshot.Health<=0 or snapshot.MaxHealth<=0
            or snapshot.Cooldown<0 or not api.Needed(state.SelectedMiscSkill,snapshot) then
            state.MiscReserveStamina=false; return
        end
        state.MiscReserveStamina=true
        if snapshot.Blocked or snapshot.Busy or snapshot.Stamina<snapshot.Cost or now<nextAttempt then return end
        nextAttempt=now+1
        ctx.Cast(state.SelectedMiscSkill,snapshot)
    end
    return api
end
