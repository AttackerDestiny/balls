-- Respawn estimates are based only on observed living -> dead transitions in this runtime/job.
return function(ctx)
    local api={Records={}}
    local nextScan=0
    local function clean(text)return tostring(text or ""):lower():gsub("[^%w]","")end
    local function slotName(spot,sample)
        local name=clean(sample.Name)
        local count,only=0,nil
        for expected in pairs(spot.EncounterNames or {[spot.Name]=true})do
            count+=1;only=clean(expected)
            if name==clean(expected)then return only end
        end
        -- Native short names can differ from the catalog; match single-boss arenas by position.
        if count==1 and spot.Position and sample.Position then
            local a,b=spot.Position,sample.Position
            if (a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2<=220^2 then return only end
        end
    end
    function api.Update(now,spots)
        if now<nextScan then return end
        nextScan=now+.1
        local samples=ctx.Samples()
        for _,spot in ipairs(spots)do
            if spot.PlaceId==ctx.CurrentFloor()and type(spot.RespawnSeconds)=="number"and spot.RespawnSeconds>0 then
                local record=api.Records[spot.Id]
                if not record then record={Slots={}};api.Records[spot.Id]=record end
                for _,sample in ipairs(samples)do
                    local key=slotName(spot,sample)
                    if key then
                        local slot=record.Slots[key]
                        if not slot or slot.Model~=sample.Model then slot={Model=sample.Model};record.Slots[key]=slot end
                        local living=sample.Health>0 and (sample.HitLives==nil or sample.HitLives>0)
                        if living then slot.WasAlive=true;slot.Dead=false;slot.DueAt=nil
                        elseif slot.WasAlive and not slot.Dead then
                            slot.Dead=true;slot.KilledAt=now;slot.DueAt=now+spot.RespawnSeconds
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
