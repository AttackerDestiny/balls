return function(source)
    local make=assert(loadstring(source))()
    local own,a,b={},{},{}
    local current=own;local writes=0
    local api=make({OwnProfile=own,Function=function()return function()end end,
        Read=function(_,index)assert(index==2);return current end,
        Write=function(_,index,value)assert(index==2);writes+=1;current=value end})
    assert(api.Set(a)and current==a)
    assert(api.Set(b)and current==b)
    assert(api.Set(nil)and current==own)
    local count=writes;assert(api.Set(nil)and writes==count)
    assert(api.Set(a));local other={};current=other
    assert(not api.Set(b)and current==other,"Another script's profile must not be overwritten")
    assert(api.Set(nil)and current==other,"Cleanup only restores a profile owned by this renderer")
    local invalid=make({OwnProfile=own,Function=function()return function()end end,
        Read=function()return other end,Write=function()error("must not write")end})
    assert(not invalid.Set(a),"Reject a different native upvalue layout")
    local unsupported=make({OwnProfile=own,Function=function()error("unsupported")end})
    assert(not unsupported.Set(a))
    print("PASS Native inventory view: selected profile, target changes, own-profile restore, repeated cleanup, external ownership and unsupported layouts")
end
