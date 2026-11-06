-- Per-cast reservations are observations, never mutations of replicated health.
return function()
    local api={}
    local values,slots={},{}
    local cursor=1
    function api.Estimate(key)return values[key]or 0 end
    function api.Learn(key,damage,requests,smallest)
        if type(damage)~="number"or damage~=damage or damage<=0 or damage==math.huge or not requests or requests<=0 then return end
        local amount=damage/requests
        if smallest and smallest>0 then amount=math.min(amount,smallest)end
        if values[key]then values[key]=math.min(values[key],amount);return end
        if slots[cursor]then values[slots[cursor]]=nil end
        slots[cursor]=key;cursor=cursor%128+1;values[key]=amount
    end
    local function rebase(item,health,now)
        if not item.ReservationUntil or item.ReservationUntil<=now then
            item.ReservationBase=health;item.ReservedDamage=0
        end
    end
    function api.Remaining(item,health,now)
        rebase(item,health,now)
        return math.min(health,(item.ReservationBase or health)-(item.ReservedDamage or 0))
    end
    function api.Reserve(item,health,damage,now,ttl)
        rebase(item,health,now)
        if not damage or damage<=0 then return end
        item.ReservedDamage=(item.ReservedDamage or 0)+damage
        item.ReservationUntil=now+(ttl or .5)
    end
    return api
end
