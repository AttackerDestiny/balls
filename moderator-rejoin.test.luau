return function(source)
    local make=assert(loadstring(source))()
    local function fixture()
        local f={State={Running=true},Order={},Requests=0}
        f.Api=make({State=f.State,
            Queue=function()table.insert(f.Order,"queue");if f.QueueError then error("unsupported")end end,
            Spawn=function(fn)f.Worker=coroutine.create(fn);assert(coroutine.resume(f.Worker))end,
            Sleep=function()coroutine.yield()end,
            Teleport=function()f.Requests+=1;if f.Fail then error("refused")end end,
            Kick=function()table.insert(f.Order,"kick")end})
        function f.Step()assert(coroutine.resume(f.Worker))end
        return f
    end
    local f=fixture();assert(not f.Api.Armed and not f.Worker)
    f.Api.Kick("test");assert(table.concat(f.Order,",")=="queue,kick" and f.Requests==0)
    f.Step();assert(f.Requests==1);f.Api.MarkStarted();f.Step();assert(coroutine.status(f.Worker)=="dead")
    f=fixture();f.Fail=true;f.Api.Kick("test");for i=1,4 do f.Step()end
    assert(f.Requests==3 and f.State.ModeratorRejoinError and f.State.ModeratorRejoinStatus:find("manually"))
    f=fixture();f.Api.Kick("test");f.State.StopEverything=true;f.Step();assert(f.Requests==0)
    f=fixture();f.Api.Kick("test");f.State.Running=false;f.Step();assert(f.Requests==0)
    f=fixture();f.QueueError=true;f.Api.Kick("test");f.Api.Kick("duplicate");f.Step()
    assert(f.Requests==1 and #f.Order==2 and f.State.ModeratorRejoinError:find("Resume queue"))
    print("PASS Moderator rejoin: queue before kick, delayed request, success, bounded retries, cancellation, queue failure, deduplication")
end
