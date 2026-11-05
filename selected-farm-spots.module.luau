-- Match bosses by encounter identity, and arena adds/custom spots by proximity.
return function(state,name,position,rank,placeId)
    if not state.MultiSpot or state.AccountProgression then return true end
    local catalog=state.AutomationCatalog
    if not catalog then return false end
    for id,on in pairs(state.MultiSpotSelected or {})do
        local spot=on and catalog.SpotById[id]
        if spot and spot.PlaceId==placeId then
            local named=spot.EncounterNames
            if named and rank<=2 then
                if named[name]then return true end
                for expected in pairs(named)do if expected:lower()==name:lower()then return true end end
            elseif position and spot.Position then
                local dx,dy,dz=position.X-spot.Position.X,position.Y-spot.Position.Y,position.Z-spot.Position.Z
                if dx*dx+dy*dy+dz*dz<=220^2 then return true end
            end
        end
    end
    return false
end
