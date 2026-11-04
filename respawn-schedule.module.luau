-- Respawn estimates are based only on observed living -> dead transitions in this runtime/job.
return function(ctx)
    local api={Records={}}
    local nextScan=0
    local descriptors=setmetatable({}, {__mode="k"})
    local names=setmetatable({}, {__mode="k"})
    api.NameNormalizations=0
    local function clean(text)
        api.NameNormalizations+=1
        return tostring(text or ""):lower():gsub("[^%w]","")
    end
    local function descriptor(spot)
        local value=descriptors[spot]
        if value and value.Name==spot.Name and value.Source==spot.EncounterNames then return value end
        value={Name=spot.Name,Source=spot.EncounterNames,Expected={},Count=0}
        if spot.EncounterNames then
            for expected in pairs(spot.EncounterNames)do
                local key=clean(expected);value.Expected[key]=true;value.Count+=1;value.Only=key
            end
        else local key=clean(spot.Name);value.Expected[key]=true;value.Count=1;value.Only=key end
        descriptors[spot]=value
        return value
    end
    local function slotName(spot,sample,definition)
        local cached=sample.Model and names[sample.Model]
        if not cached or cached.Name~=sample.Name then
            cached={Name=sample.Name,Key=clean(sample.Name)}
            if sample.Model then names[sample.Model]=cached end
        end
        if definition.Expected[cached.Key]then return cached.Key end
        if definition.Count==1 and spot.Position and sample.Position then
            local a,b=spot.Position,sample.Position
            if (a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2<=220^2 then return definition.Only end
        end
    end
    function api.Update(now,spots)
        if now<nextScan then return end
        nextScan=now+.1
        local samples
        local floor=ctx.CurrentFloor()
        for _,spot in ipairs(spots)do
            if spot.PlaceId==floor and type(spot.RespawnSeconds)=="number"and spot.RespawnSeconds>0 then
                samples=samples or ctx.Samples()
                local definition=descriptor(spot)
                local record=api.Records[spot.Id]
                if not record then record={Slots={}};api.Records[spot.Id]=record end
                for _,sample in ipairs(samples)do
                    local key=slotName(spot,sample,definition)
                    if key then
                        local slot=record.Slots[key]
                        if not slot or slot.Model~=sample.Model then slot={Model=sample.Model};record.Slots[key]=slot end
                        local living=sample.Health>0 and (sample.HitLives==nil or sample.HitLives>0)
                        if living then slot.WasAlive=true;slot.Dead=false;slot.DueAt=nil
                        elseif slot.WasAlive and not slot.Dead then
                            slot.Dead=true;slot.KilledAt=now;slot.DueAt=ctx.Deadline and ctx.Deadline(now,spot.RespawnSeconds)or now+spot.RespawnSeconds
                        end
                    end
                end
                record.HasLive=false;record.DueAt=nil
                for _,slot in pairs(record.Slots)do
                    if slot.WasAlive and not slot.Dead then record.HasLive=true end
                    if slot.DueAt then record.DueAt=math.min(record.DueAt or math.huge,slot.DueAt)end
                    if slot.KilledAt then record.KilledAt=math.max(record.KilledAt or -math.huge,slot.KilledAt)end
                end
            end
        end
    end
    function api.Get(spot)return api.Records[spot.Id]end
    return api
end
