-- Remove destroyed UI references and disconnect every owned signal on shutdown.
return function(creator)
    local api={Pruned=0}
    if not creator then function api.Update()end;return api end
    local cursors={}
    local function array(name,dead)
        local list=creator[name]
        if type(list)~="table"then return end
        local index=cursors[name]or 1
        for _=1,128 do
            if index>#list then index=1;break end
            if dead(list[index])then list[index]=list[#list];list[#list]=nil;api.Pruned+=1
            else index+=1 end
        end
        cursors[name]=index
    end
    local objectCursor
    function api.Update()
        array("Signals",function(connection)return connection.Connected==false end)
        array("FontObjects",function(object)return object.Parent==nil end)
        array("LocalizationObjects",function(record)return not record.Object or record.Object.Parent==nil end)
        local objects=creator.Objects
        if type(objects)=="table"then
            for _=1,128 do
                local ok,key=pcall(next,objects,objectCursor)
                if not ok then key=next(objects)end
                if not key then objectCursor=nil;break end
                objectCursor=key
                if key.Parent==nil then objects[key]=nil;api.Pruned+=1 end
            end
        end
    end
    creator.DisconnectAll=function()
        for i=#creator.Signals,1,-1 do
            pcall(function()creator.Signals[i]:Disconnect()end)
            creator.Signals[i]=nil
        end
        for _,name in ipairs({"Objects","FontObjects","LocalizationObjects"})do
            if type(creator[name])=="table"then table.clear(creator[name])end
        end
    end
    return api
end
