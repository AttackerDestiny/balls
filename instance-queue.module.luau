-- Bounded priority queue with O(1) removal of streamed-out instances.
return function(capacity)
    local api={Count=0,Dropped=0,Peak=0}
    local records,heads,tails={},{},{}
    local disposed=false
    function api.Contains(value)return records[value]~=nil end
    function api.Push(value,priority)
        if disposed or records[value]then return false end
        if api.Count>=capacity then api.Dropped+=1;return false end
        local kind=priority and 1 or 2
        local node={Value=value,Kind=kind,Previous=tails[kind]}
        if tails[kind]then tails[kind].Next=node else heads[kind]=node end
        tails[kind]=node;records[value]=node;api.Count+=1;api.Peak=math.max(api.Peak,api.Count)
        return true
    end
    function api.Remove(value)
        local node=records[value]
        if not node then return false end
        if node.Previous then node.Previous.Next=node.Next else heads[node.Kind]=node.Next end
        if node.Next then node.Next.Previous=node.Previous else tails[node.Kind]=node.Previous end
        records[value]=nil;node.Value=nil;node.Next=nil;node.Previous=nil;api.Count-=1
        return true
    end
    function api.Pop()
        local node=heads[1]or heads[2]
        if not node then return nil end
        local value=node.Value;api.Remove(value);return value
    end
    function api.Clear()
        table.clear(records);table.clear(heads);table.clear(tails);api.Count=0
    end
    function api.Destroy()api.Clear();disposed=true end
    return api
end
