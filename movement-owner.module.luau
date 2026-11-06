-- Evaluate controller policies anew; movement ownership has no stale lease.
return function(state)
    local api={Owner="Manual",ChangedAt=0,Transitions=0}
    local rules={
        {"Stopped",function()return state.Running==false or state.StopEverything end},
        {"Moderator",function()return state.ModeratorBlocking end},
        {"Safety",function()return state.SafeModePanic end},
        {"Friend",function()return state.AutoJoinFriendHolding end},
        {"Floor travel",function()return state.AutomationTeleporting end},
        {"Trade",function()return state.AutoTradeBusy end},
        {"Arena travel",function()return state.TravelBusy or state.MultiSpotOwnsTravel end},
        {"Dodge",function()return state.Dodging end},
        {"Recovery",function(now)return state.Recovering or now<(state.FarmPauseUntil or 0)end},
        {"Farm",function()return state.AutoFarm end},
    }
    function api.Resolve(now)
        local owner="Manual"
        for _,rule in ipairs(rules)do if rule[2](now)then owner=rule[1];break end end
        if owner~=api.Owner then api.Owner=owner;api.Transitions+=1;api.ChangedAt=now end
        state.MovementOwner=owner;return owner
    end
    function api.CanFarm(now)
        local owner=api.Resolve(now)
        return owner=="Manual"or owner=="Farm"
    end
    return api
end
