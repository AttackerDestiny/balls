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
end
