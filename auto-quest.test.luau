return function(source)
    local a,b={},{};local ready={};local busy=false;local active=true;local calls={}
    local worker=assert(loadstring(source))()({Active=function()return active end,Busy=function()return busy end,
        Ready=function()return ready end,Valid=function(q)return q~=b end,
        Claim=function(q)calls[#calls+1]=q end})
    worker.Update(0);assert(#calls==0)
    ready={a,b};worker.Update(1);assert(#calls==1 and calls[1]==a)
    worker.Update(1.1);worker.Update(2);assert(#calls==1,"No duplicate claims while awaiting removal")
    busy=true;worker.Update(11);assert(#calls==1)
    busy=false;worker.Update(12);worker.Update(32);worker.Update(100)
    assert(#calls==3,"Only three bounded retries for an unacknowledged quest")
    ready={};worker.Update(101);ready={a};worker.Update(102);assert(#calls==4,"A genuinely new completion can be claimed")
    active=false;ready={{}};worker.Update(200);assert(#calls==4)
    print("PASS Quest claiming: completion-only, native instance validation, pacing, acknowledgment, bounded retries, repeat completion and stop")
end
