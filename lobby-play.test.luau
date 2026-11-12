return function(source)
    local make=assert(loadstring(source))()
    local now,ready,alive,clicks,queues=0,false,true,0,0
    local function new(queue)
        return make({Now=function()return now end,Alive=function()return alive end,
            Find=function()return {}end,Ready=function()return ready end,
            Queue=queue or function()queues+=1 end,Activate=function()clicks+=1 end})
    end
    local api=new();api.Update();assert(clicks==0 and queues==0)
    ready=true;api.Update();assert(clicks==1 and queues==1)
    now=.25;api.Update();assert(clicks==1)
    now=1;api.Update();assert(clicks==2 and queues==1)
    ready=false;now=1.25;api.Update();assert(api.Done)
    ready=true;now=2;api.Update();assert(clicks==2,"No click after the native menu transition")
    print("PASS Auto Play waits for readiness, queues once and stops after menu transition")
    now=0;local stopped=new();alive=false;stopped.Update();assert(stopped.Done and clicks==2)
    alive=true;ready=false;local timed=new();now=61;timed.Update();assert(timed.Done and clicks==2)
    print("PASS Auto Play cancels with its runtime and has a bounded idle lifetime")
    now=0;ready=true;local failed=new(function()error("queue unavailable")end)
    failed.Update();assert(failed.Done and failed.Error and clicks==2)
    print("PASS Auto Play does not start login when its resume queue fails")

    local function resting(deadline)
        local f={Now=0,Deadline=deadline,Alive=true,Ready=true,Finds=0,Clicks=0,Queues=0,HoldReads=0}
        function f.New()
            f.Api=make({Now=function()return f.Now end,Alive=function()return f.Alive end,
                Hold=function()
                    f.HoldReads+=1
                    if f.HoldError then error("rest ledger unavailable")end
                    return f.Deadline-f.Now
                end,
                Find=function()f.Finds+=1;return {}end,Ready=function()return f.Ready end,
                Queue=function()f.Queues+=1 end,Activate=function()f.Clicks+=1 end})
            return f.Api
        end
        f.New();return f
    end
    local rest=resting(2400)
    rest.Api.Update();rest.Now=120;rest.Api.Update()
    assert(not rest.Api.Done and rest.Api.RestRemaining==2280 and rest.Finds==0 and rest.Queues==0 and rest.Clicks==0,
        "A long rest holds before the ordinary menu timeout, readiness checks and activation")
    rest.Now=2400;rest.Api.Update()
    assert(rest.Api.RestRemaining==0 and rest.Queues==1 and rest.Clicks==1 and not rest.Api.Done,
        "Rest expiry queues the script before activating Play")
    print("PASS Auto Play waits through a long rest and activates only after its deadline")
    local readiness=resting(120)
    readiness.Ready=false;readiness.Api.Update();readiness.Now=120;readiness.Api.Update()
    readiness.Now=179.5;readiness.Ready=true;readiness.Api.Update()
    assert(readiness.Clicks==1 and not readiness.Api.Done,"Rest release grants a fresh sixty seconds for menu readiness")
    local expired=resting(120)
    expired.Ready=false;expired.Api.Update();expired.Now=120;expired.Api.Update()
    expired.Now=180;expired.Api.Update()
    assert(expired.Api.Done and expired.Queues==0 and expired.Clicks==0,"The post-rest readiness budget remains bounded")
    print("PASS Auto Play starts its full readiness timeout after rest ends")
    local reload=resting(600)
    reload.Api.Update();reload.Now=250;reload.New();reload.Api.Update()
    assert(reload.Api.RestRemaining==350 and reload.Queues==0 and reload.Clicks==0,
        "Reloading reads the original absolute rest deadline instead of extending the duration")
    reload.Now=600;reload.Api.Update()
    assert(reload.Queues==1 and reload.Clicks==1)
    print("PASS Auto Play retains the absolute rest deadline across reload")
    local cancelled=resting(600)
    cancelled.Api.Update();cancelled.Alive=false;cancelled.Now=200;cancelled.Api.Update()
    assert(cancelled.Api.Done and cancelled.HoldReads==1 and cancelled.Queues==0 and cancelled.Clicks==0,
        "Runtime cancellation ends a rest without reading it again or activating Play")
    local unreadable=resting(600)
    unreadable.HoldError=true;unreadable.Api.Update();unreadable.Now=601;unreadable.Api.Update()
    assert(unreadable.Api.Done and unreadable.Api.Error:find("rest ledger unavailable",1,true)
        and unreadable.Finds==0 and unreadable.Queues==0 and unreadable.Clicks==0,
        "A rest read failure stops Auto Play rather than skipping protection")
    print("PASS Auto Play cancels its rest and fails closed when the rest ledger cannot be read")
end
