-- Reserves expected damage while HP replication catches up; never changes real HP.
return function()
    local api={}
    local samples,order={},{}
    function api.Learn(key,damage,requests,smallestDrop)
        if type(damage)~="number" or damage<=0 or not requests or requests<=0 then return end
        local estimate=damage/requests
        if smallestDrop and smallestDrop>0 then estimate=math.min(estimate,smallestDrop) end
        local old=samples[key]
        if not old then
            if #order>=128 then samples[table.remove(order,1)]=nil end
            order[#order+1]=key
        end
        samples[key]=old and math.min(old,estimate) or estimate
    end
    function api.Estimate(key)return samples[key] or 0 end
    function api.Remaining(item,health,now)
        if not item.ReservationUntil or now>=item.ReservationUntil then
            item.ReservationBase=health;item.ReservedDamage=0
        end
        return math.min(health,(item.ReservationBase or health)-(item.ReservedDamage or 0))
    end
    function api.Reserve(item,health,damage,now,ttl)
        api.Remaining(item,health,now)
        if not damage or damage<=0 then return end
        item.ReservedDamage=(item.ReservedDamage or 0)+damage
        item.ReservationUntil=now+(ttl or .5)
    end
    return api
end
