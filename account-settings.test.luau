return function(source)
    for _,owner in ipairs({123,456,false})do
        local old={UserId=owner or nil,AutoFarm=true}
        local load=assert(loadstring(source.."\nreturn previous,previousRuntime"))
        setfenv(load,setmetatable({env={SB2KillAura=old},player={UserId=123}},{__index=getfenv()}))
        local inherited,cleanup=load()
        assert(cleanup==old)
        assert((inherited~=nil)==(owner==123),"Only the current account may inherit runtime preferences")
        if inherited then assert(inherited~=old and inherited.AutoFarm,"Preferences must be copied without retaining the old runtime")end
    end
    print("PASS Account settings isolate previous-user and legacy runtimes while preserving same-user reloads")
end
