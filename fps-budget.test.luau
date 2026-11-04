return function(coordinationSource,gateSource)
    local time=100
    local make=assert(loadstring(coordinationSource))()
    local coordinator=make({Now=function()return time end,Vector=function()end})
    local work=0
    local state={AutoFarm=true,FarmCoordination=coordinator,ResolveAutoOffset=function()work+=1;return -20 end}
    local move=assert(loadstring("return function(state)\n"..gateSource.."\nreturn true end"))()
    for frame=0,100 do time=100+frame*.08;move(state)end
    assert(work>=30 and work<=33,"Position calculation must run on the shared movement beats, not every movement poll")
    local before=work;state.DodgeReturnPending=true;move(state)
    assert(work==before+1,"A completed dodge must return immediately without waiting for a movement beat")
    print("PASS FPS movement budget: at most 33 position calculations over 101 polls, with immediate dodge-return bypass")
end
