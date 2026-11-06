-- Support intent is separate from casting: only requested effects reserve stamina.
return function(context)
    local state=context.State
    local api={Names={"Cursed Enhancement","Heal","Mending Spirit","Summon Tree"}}
    local sampledAt,castAfter=0,0
    local predicates={
        ["Cursed Enhancement"]=function(s)return s.Attacking==true and not s.BuffActive end,
        Heal=function(s)return s.MaxHealth>0 and s.Health<=s.MaxHealth*.66 end,
        ["Mending Spirit"]=function(s)return s.MaxHealth>0 and s.Health<=s.MaxHealth*.66 end,
        ["Summon Tree"]=function(s)return s.Stamina<=66 end,
    }
    function api.Needed(name,snapshot)
        local predicate=predicates[name]
        return predicate~=nil and predicate(snapshot)or false
    end
    function api.Update(now)
        now=now or os.clock()
        if not state.MiscSkillEnabled or state.StopEverything then state.MiscReserveStamina=false;return end
        if state.MiscCastRunning then state.MiscReserveStamina=true;return end
        if now<sampledAt then return end
        sampledAt=now+.2
        local snapshot=context.Read(state.SelectedMiscSkill)
        local wanted=snapshot and snapshot.Usable and snapshot.Health>0 and snapshot.MaxHealth>0
            and snapshot.Cooldown>=0 and api.Needed(state.SelectedMiscSkill,snapshot)
        state.MiscReserveStamina=wanted==true
        if not wanted or snapshot.Blocked or snapshot.Busy or snapshot.Stamina<snapshot.Cost or now<castAfter then return end
        castAfter=now+1
        context.Cast(state.SelectedMiscSkill,snapshot)
    end
    return api
end
