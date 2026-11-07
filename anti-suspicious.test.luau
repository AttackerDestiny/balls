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
    print("PASS Anti Suspicious: rolling Safe Mode departures, reload, randomized seconds, rest commitment and expiry")
end
