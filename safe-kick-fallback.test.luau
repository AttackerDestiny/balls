return function(source)
    local make=assert(loadstring(source))()
    local target={UserId=2,Name="Outsider"}
    local function fixture()
        local f={Clock=0,Active=true,People={target},White={},Threads={},Order={},Blocks=0,Kicks=0,Rejoins=0,Confirmed=true,Job="A"}
        local function spawn(fn)local t=coroutine.create(fn);table.insert(f.Threads,t);assert(coroutine.resume(t))end
        f.Api=make({InitialJob="A",Job=function()return f.Job end,Now=function()return f.Clock end,
            Active=function()return f.Active end,Players=function()return f.People end,Allowed=function(p)return f.White[p.UserId]end,
            Present=function(p)for _,person in ipairs(f.People)do if person==p then return true end end;return false end,
            CheckLimits=function()if f.Limit then error("Search limit")end end,Spawn=spawn,Sleep=function()coroutine.yield()end,Status=function(s)f.Status=s end,
            Pause=function()table.insert(f.Order,"pause")end,Finish=function()f.Finished=true end,
            Block=function(_,active)f.Blocks+=1;table.insert(f.Order,"block");if f.OnBlock then f.OnBlock(active)end;return f.Confirmed end,
            Prepare=function()table.insert(f.Order,"queue");if f.QueueFail then error("Queue failed")end end,
            Kick=function()assert(f.Confirmed);f.Kicks+=1;table.insert(f.Order,"kick")end,
            Rejoin=function()assert(f.Kicks==1);f.Rejoins+=1 end})
        function f.Tick(now)f.Clock=now;f.Api.Update(now)end
        function f.Resume(index)local t=f.Threads[index];if coroutine.status(t)~="dead"then assert(coroutine.resume(t))end end
        return f
    end
    local f=fixture();f.Tick(0);f.Tick(7.99);assert(f.Blocks==0 and f.Kicks==0)
    f.Tick(8);assert(f.Kicks==1 and table.concat(f.Order,",")=="pause,block,queue,kick")
    f.Tick(100);assert(f.Kicks==1);f.Resume(2);assert(f.Rejoins==1)
    f.Api.MarkStarted();f.Resume(2);assert(f.Rejoins==1)
    f=fixture();f.White[2]=true;f.Tick(0);f.Tick(10);assert(f.Blocks==0)
    f=fixture();f.Tick(0);f.People={};f.Tick(7);f.People={target};f.Tick(8);f.Tick(15);assert(f.Kicks==0)
    f.Tick(16);assert(f.Kicks==1)
    f=fixture();f.Confirmed=false;f.Tick(0);f.Tick(8);assert(f.Kicks==0 and f.Status:find("not confirmed"))
    f.Tick(10);f.Tick(14);f.Tick(100);assert(f.Blocks==3 and f.Kicks==0)
    f=fixture();f.Limit=true;f.Tick(0);f.Tick(8);assert(f.Blocks==0 and f.Kicks==0)
    f=fixture();f.QueueFail=true;f.Tick(0);f.Tick(8);assert(f.Kicks==0)
    for _,cancel in ipairs({"white","disabled","departed","reset"})do
        f=fixture();f.OnBlock=function()
            if cancel=="white"then f.White[2]=true elseif cancel=="disabled"then f.Active=false
            elseif cancel=="departed"then f.People={}else f.Api.Reset()end
        end
        f.Tick(0);f.Tick(8);assert(f.Kicks==0,cancel)
    end
    f=fixture();f.Tick(0);f.Job="B";f.Tick(8);assert(f.Blocks==0)
    f=fixture();f.Tick(0);f.Tick(8);for i=1,4 do f.Resume(2)end
    assert(f.Rejoins==3,"Post-kick rejoin has bounded attempts")
    print("PASS Safe 8s fallback: timing, whitelist, departure reset, block-before-kick, queue guard, deduplication, cancellation, job scope, bounded retries")
end
