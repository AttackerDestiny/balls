-- Fixed-capacity pooled FIFO lanes release instance references on unlink.
return function(limit)
    assert(type(limit)=="number"and limit>=1,"A positive capacity is required")
    local api={Count=0,Dropped=0,Peak=0}
    local first,last={0,0},{0,0}
    local slots,locations,reusable={},{},{}
    local allocated,closed=0,false
    local function erase(value)
        local slot=locations[value]
        if not slot then return false end
        local node=slots[slot];local lane=node.Lane
        if node.Before==0 then first[lane]=node.After else slots[node.Before].After=node.After end
        if node.After==0 then last[lane]=node.Before else slots[node.After].Before=node.Before end
        locations[value]=nil;node.Value=nil;node.Before=0;node.After=0
        reusable[#reusable+1]=slot;api.Count-=1
        return true
    end
    function api.Contains(value)return locations[value]~=nil end
    function api.Push(value,urgent)
        if closed or value==nil or locations[value]then return false end
        if api.Count>=limit then api.Dropped+=1;return false end
        local slot=table.remove(reusable)
        if not slot then allocated+=1;slot=allocated;slots[slot]={}end
        local lane=urgent and 1 or 2;local node=slots[slot]
        node.Value=value;node.Lane=lane;node.Before=last[lane];node.After=0
        if last[lane]==0 then first[lane]=slot else slots[last[lane]].After=slot end
        last[lane]=slot;locations[value]=slot
        api.Count+=1;api.Peak=math.max(api.Peak,api.Count)
        return true
    end
    api.Remove=erase
    function api.Pop()
        local slot=first[1]~=0 and first[1]or first[2]
        if slot==0 then return nil end
        local result=slots[slot].Value;erase(result);return result
    end
    function api.Clear()
        table.clear(locations);table.clear(reusable)
        for slot=1,allocated do
            local node=slots[slot];node.Value=nil;node.Before=0;node.After=0
            reusable[slot]=slot
        end
        first[1],first[2],last[1],last[2]=0,0,0,0;api.Count=0
    end
    function api.Destroy()
        closed=true;api.Clear();table.clear(slots);table.clear(reusable);allocated=0
    end
    return api
end
