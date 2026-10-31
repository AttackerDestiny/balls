return function(source)
    for _,owner in ipairs({123,456,false})do
        local old={UserId=owner or nil,AutoFarm=true}
        local load=assert(loadstring(source.."\nreturn previous,previousRuntime"))
        setfenv(load,setmetatable({env={SB2KillAura=old},player={UserId=123}},{__index=getfenv()}))
        local inherited,cleanup=load()
        assert(cleanup==old)
        assert((inherited==old)==(owner==123),"Only the current account may inherit runtime preferences")
    end
    print("PASS Account settings isolate previous-user and legacy runtimes while preserving same-user reloads")
end
