-- A respawn record advances only after a living sample is observed dead.
return function(ctx)
    local api={Records={},NameNormalizations=0}
    local due=0
    local definitions=setmetatable({}, {__mode="k"})
    local normalized=setmetatable({}, {__mode="k"})
    local function name(text)
        api.NameNormalizations+=1
        return tostring(text or ""):lower():gsub("[^%w]","")
    end
    local function describe(spot)
        local old=definitions[spot]
        if old and old.Name==spot.Name and old.Source==spot.EncounterNames then return old end
        local definition={Name=spot.Name,Source=spot.EncounterNames,Keys={},Count=0}
        if spot.EncounterNames then
            for key in pairs(spot.EncounterNames)do local value=name(key);definition.Keys[value]=true;definition.Only=value;definition.Count+=1 end
        else definition.Only=name(spot.Name);definition.Keys[definition.Only]=true;definition.Count=1 end
        definitions[spot]=definition;return definition
    end
    local function match(spot,sample,definition)
        local found=sample.Model and normalized[sample.Model]
        if not found or found.Name~=sample.Name then
            found={Name=sample.Name,Key=name(sample.Name)}
            if sample.Model then normalized[sample.Model]=found end
        end
        if definition.Keys[found.Key]then return found.Key end
        if definition.Count~=1 or not spot.Position or not sample.Position then return nil end
        local a,b=spot.Position,sample.Position
        if (a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2<=48400 then return definition.Only end
    end
    local function observe(record,key,sample,seconds,now)
        local slot=record.Slots[key]
        if not slot or slot.Model~=sample.Model then slot={Model=sample.Model};record.Slots[key]=slot end
        if sample.Health>0 and (sample.HitLives==nil or sample.HitLives>0)then
            slot.WasAlive=true;slot.Dead=false;slot.DueAt=nil
        elseif slot.WasAlive and not slot.Dead then
            slot.Dead=true;slot.KilledAt=now
            slot.DueAt=ctx.Deadline and ctx.Deadline(now,seconds)or now+seconds
        end
    end
    function api.Update(now,spots)
        if now<due then return end
        due=now+.1
        local floor=ctx.CurrentFloor();local samples
        for _,spot in ipairs(spots)do
            local seconds=spot.RespawnSeconds
            if spot.PlaceId==floor and type(seconds)=="number"and seconds>0 then
                if not samples then samples=ctx.Samples()end
                local record=api.Records[spot.Id]
                if not record then record={Slots={}};api.Records[spot.Id]=record end
                local definition=describe(spot)
                for _,sample in ipairs(samples)do
                    local key=match(spot,sample,definition)
                    if key then observe(record,key,sample,seconds,now)end
                end
                record.HasLive=false;record.DueAt=nil
                for _,slot in pairs(record.Slots)do
                    record.HasLive=record.HasLive or (slot.WasAlive and not slot.Dead)or false
                    if slot.DueAt then record.DueAt=math.min(record.DueAt or math.huge,slot.DueAt)end
                    if slot.KilledAt then record.KilledAt=math.max(record.KilledAt or -math.huge,slot.KilledAt)end
                end
            end
        end
    end
    function api.Get(spot)return api.Records[spot.Id]end
    return api
end
