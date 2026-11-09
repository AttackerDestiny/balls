return function(source)
    local state={Running=true,AutoRegroupHolding=true,SafeModePanic=true}
    local calls={}
    local priority=true
    local release=false
    local chunk=assert(loadstring(source.."\nreturn runFrame"))
    setfenv(chunk,setmetatable({state=state,workScheduler={Step=function(name)
        calls[name]=(calls[name]or 0)+1
        if name=="AutoRegroup"and release then state.AutoRegroupHolding=false end
    end},priorityOnly=function()return priority end,jobs={{"TradeHold"},{"AuraTouch"}},frameOrder={"AutoRegroup","BetweenRevive"}},
        {__index=getfenv()}))
    local run=chunk()
    run()
    assert(calls.AutoRegroup==1 and not calls.BetweenRevive,
        "A committed reset must reach its return scheduler even if Safe Mode now owns ordinary movement")
    state.StopEverything=true;run();assert(calls.AutoRegroup==1,"An explicit stop still suspends return work")
    state.StopEverything=false;state.ModeratorBlocking=true;run()
    assert(calls.AutoRegroup==1,"Moderator protection retains priority")
    state.ModeratorBlocking=false;state.AutoRegroupHolding=false;run()
    assert(calls.AutoRegroup==1,"A new regroup cannot start through a protection gate")
    state.AutoRegroupHolding=true;release=true;run()
    assert(calls.AutoRegroup==2 and not calls.BetweenRevive,"After releasing regroup, ordinary safety remains authoritative")
    print("PASS Regroup coordinator: committed exit, protection holds, explicit stop and moderator priority")
end
