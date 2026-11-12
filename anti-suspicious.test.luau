return function(source)
    local make=assert(loadstring(source))()
    local now,saved,enabled,fail=1000,nil,true,false
    local limits={Hops=10,Window=10,Min=40,Max=60}
    local ctx={Now=function()return now end,Enabled=function()return enabled end,Limits=function()return limits end,
        Load=function()return saved end,Save=function(value)if fail then return false end;saved=value end,
        Random=function(lo,hi)assert(lo==2400 and hi==3600);return lo+37 end}
    local api=make(ctx)
    assert(not api.Departure() and not saved,"The initial search does not count")
    api.ObserveProtected()
    for i=1,9 do
        now+=50
        assert(not api.Departure())
        api.ObserveProtected()
    end
    api=make(ctx)
    now+=50
    assert(api.Departure()==2437,"Track departures across protected servers and script reload")
    assert(not api.Deadline(),"Do not start a rest if the kick is never committed")
    fail=true;assert(not api.Commit(2437),"A failed write cannot authorize a rest kick")
    fail=false;assert(api.Commit(2437)==now+2437)
    api=make(ctx)
    assert(api.Deadline()==now+2437 and not api.Departure())
    now+=2437
    assert(not api.Deadline() and not api.Departure(),"A completed rest requires a new protected server")
    api.ObserveProtected()
    for i=1,10 do now+=61;assert(not api.Departure() or i==10)end
    now+=600
    assert(not api.Departure(),"Entries outside the rolling window expire")
    enabled=false
    assert(not api.Departure())
    local deadline=now+2437
    local function strict(load)
        return make({StrictLoad=true,Now=function()return now end,Load=load})
    end
    local menu=strict(function()return {Version=1,Hops={},Until=deadline}end)
    assert(menu.Deadline()==deadline,"The menu uses the original absolute deadline across reloads")
    now+=60
    assert(strict(function()return {Version=1,Hops={},Until=deadline}end).Deadline()==deadline)
    assert(not strict(function()return nil end).Deadline(),"A missing ledger has no rest")
    assert(not pcall(strict,function()error("Read failed")end),"An unreadable rest must stop Auto Play")
    for _,value in ipairs({{Version=2,Hops={}},{Version=1,Hops={},Until=math.huge},
        {Version=1,Hops={},Until=0/0},{Version=1,Hops={},Until=now+12001}})do
        assert(not pcall(strict,function()return value end),"Malformed or impossible menu-rest data cannot authorize Start")
    end
    print("PASS Anti Suspicious: rolling Safe Mode departures, reload, randomized seconds, rest commitment and expiry")
end
