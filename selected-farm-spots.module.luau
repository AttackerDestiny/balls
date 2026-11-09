-- Selected encounters are an admission policy, independent of local target locks.
return function(state,mobName,point,priority,place,onlySpot)
    if not onlySpot and (state.AccountProgression or not state.MultiSpot)then return true end
    local canonical=tostring(mobName):lower():gsub("[^%w]","")
    local function belongs(entry)
        if entry.EncounterNames then
            for name in pairs(entry.EncounterNames)do if name:lower():gsub("[^%w]","")==canonical then return true end end
            if priority<=2 then return false end
        end
        if point and entry.Position then
            local squared=0
            for _,axis in ipairs({"X","Y","Z"})do local delta=point[axis]-entry.Position[axis];squared+=delta*delta end
            if squared<=48400 then return true end
        end
        return false
    end
    if onlySpot then return (onlySpot.PlaceId==nil or onlySpot.PlaceId==place)and belongs(onlySpot)end
    local catalog=state.AutomationCatalog
    if not catalog then return false end
    for id,enabled in pairs(state.MultiSpotSelected or {})do
        local entry=enabled and catalog.SpotById[id]
        if entry and entry.PlaceId==place then
            if belongs(entry)then return true end
        end
    end
    return false
end
