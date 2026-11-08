return function(registry)
    local loaded={}
    local constructors={g=function()end,h=function()end,i=function()end}
    local chunk=assert(loadstring(registry))
    setfenv(chunk,setmetatable({a={load=function(id)
        assert(constructors[id],"Removed or unknown provider must never be loaded")
        loaded[id]=(loaded[id]or 0)+1
        return {New=constructors[id]}
    end}},{__index=getfenv()}))
    local providers=chunk()
    assert(providers.platoboost.New==constructors.g and providers.pandadevelopment.New==constructors.h
        and providers.luarmor.New==constructors.i,"Unrelated provider bindings must remain intact")
    assert(not providers.junkiedevelopment and loaded.g==1 and loaded.h==1 and loaded.i==1,
        "The unused deprecated adapter cannot be loaded through the registry")
    local count=0;for _ in pairs(providers)do count+=1 end
    assert(count==3)
    print("PASS WindUI providers: obsolete adapter absent, remaining registry and constructor bindings intact")
end
