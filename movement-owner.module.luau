-- Resolve ownership from active controller state; no competing persistent leases.
return function(state)
    local api={Owner="Manual",ChangedAt=0,Transitions=0}
    function api.Resolve(now)
        local owner
        if state.StopEverything or state.Running==false then owner="Stopped"
        elseif state.ModeratorBlocking then owner="Moderator"
        elseif state.SafeModePanic then owner="Safety"
        elseif state.AutoJoinFriendHolding then owner="Friend"
        elseif state.AutomationTeleporting then owner="Floor travel"
        elseif state.AutoTradeBusy then owner="Trade"
        elseif state.TravelBusy or state.MultiSpotOwnsTravel then owner="Arena travel"
        elseif state.Dodging then owner="Dodge"
        elseif state.Recovering or now<(state.FarmPauseUntil or 0)then owner="Recovery"
        elseif state.AutoFarm then owner="Farm"
        else owner="Manual"end
        if owner~=api.Owner then api.Owner=owner;api.ChangedAt=now;api.Transitions+=1 end
        state.MovementOwner=owner
        return owner
    end
    function api.CanFarm(now)
        local owner=api.Resolve(now)
        return owner=="Farm"or owner=="Manual"
    end
    return api
end
