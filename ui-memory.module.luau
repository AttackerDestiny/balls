-- Incremental registry collection and unconditional owned-signal disposal.
return function(creator)
    local api={Pruned=0}
    local closed=false
    local indices={}
    local objectKey
    local rules={
        Signals=function(value)return value.Connected==false end,
        FontObjects=function(value)return value.Parent==nil end,
        LocalizationObjects=function(value)return not value.Object or value.Object.Parent==nil end,
    }
    local function compact(name,predicate)
        local values=creator[name]
        if type(values)~="table"then return end
        local cursor=indices[name]or 1
        local examined=0
        while cursor<=#values and examined<128 do
            examined+=1
            if predicate(values[cursor])then
                local last=#values
                values[cursor]=values[last];values[last]=nil;api.Pruned+=1
            else cursor+=1 end
        end
        indices[name]=cursor>#values and 1 or cursor
    end
    local function release()
        if not creator then return end
        local signals=creator.Signals or {}
        for index=#signals,1,-1 do
            local connection=signals[index];signals[index]=nil
            pcall(function()connection:Disconnect()end)
        end
        for _,name in ipairs({"Objects","FontObjects","LocalizationObjects"})do
            if type(creator[name])=="table"then table.clear(creator[name])end
        end
    end
    if creator then creator.DisconnectAll=release end
    function api.Update()
        if closed or not creator then return end
        for name,predicate in pairs(rules)do compact(name,predicate)end
        local objects=creator.Objects
        if type(objects)~="table"then return end
        for _=1,128 do
            local valid,key=pcall(next,objects,objectKey)
            if not valid then key=next(objects)end
            objectKey=key
            if key==nil then break end
            if key.Parent==nil then objects[key]=nil;api.Pruned+=1 end
        end
    end
    function api.Destroy()
        if closed then return end
        closed=true;release();table.clear(indices);objectKey=nil
    end
    return api
end
