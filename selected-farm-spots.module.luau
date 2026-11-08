-- Selected encounters are an admission policy, independent of local target locks.
return function(state,mobName,point,priority,place)
    if state.AccountProgression or not state.MultiSpot then return true end
    local catalog=state.AutomationCatalog
    if not catalog then return false end
    local canonical=tostring(mobName):lower():gsub("[^%w]","")
    for id,enabled in pairs(state.MultiSpotSelected or {})do
        local entry=enabled and catalog.SpotById[id]
        if entry and entry.PlaceId==place then
            if entry.EncounterNames and priority<=2 then
                for name in pairs(entry.EncounterNames)do if name:lower():gsub("[^%w]","")==canonical then return true end end
            elseif point and entry.Position then
                local squared=0
                for _,axis in ipairs({"X","Y","Z"})do local delta=point[axis]-entry.Position[axis];squared+=delta*delta end
                if squared<=48400 then return true end
            end
        end
    end
    return false
end
