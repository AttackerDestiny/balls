return function(source)
    local make=assert(loadstring(source))()
    local me,friend,outsider={},{},{}
    local item={Value=1,Name="Selected"}
    local calls={};local active=true;local want={item}
    local worker=make({Player=me,Active=function()return active end,Allowed=function(p)return p==friend end,
        Plan=function()return want,50 end,Status=function()end,
        Send=function(action,args)calls[#calls+1]={action,args}end})
    worker.Event("Request",outsider);worker.Update(0);assert(#calls==0)
    worker.Event("Request",friend);worker.Update(0);assert(calls[1][1]=="RequestAccept");table.clear(calls)
    local t={Requester=me,Partner=friend,RequesterItems={},PartnerItems={},RequesterCurrency=0,PartnerCurrency=0}
    worker.Event("TradeChanged",t);worker.Update(0);worker.Update(1)
    assert(#calls==1 and calls[1][1]=="TradeAddItem")
    t.RequesterItems={{item=item}};worker.Event("TradeChanged",t);worker.Update(2)
    assert(calls[2][1]=="TradeChangeCurrency"and calls[2][2][1]==50)
    t.RequesterCurrency=50;worker.Event("TradeChanged",t);worker.Update(3);worker.Update(4)
    assert(#calls==2);worker.Update(5);assert(calls[3][1]=="TradeConfirm")
    t.RequesterConfirmed=true;t.PartnerConfirmed=true;worker.Event("TradeChanged",t);worker.Update(6)
    assert(calls[4][1]=="TradeAccept");worker.Update(7);assert(#calls==4)
    t.PartnerCurrency=100;t.RequesterConfirmed=false;worker.Event("TradeChanged",t);worker.Update(8)
    assert(#calls==4,"Changed offers require a new settle window")
    t.Partner=outsider;worker.Event("TradeChanged",t);worker.Update(20);assert(#calls==4)
    t.Partner=friend;want={};worker.Event("TradeChanged",t);worker.Update(25);assert(#calls==4,"Unselected outgoing items prevent final acceptance")
    active=false;worker.Update(30);assert(#calls==4)
    -- A request present before the toggle/listener starts is recovered from native UI.
    local visible=friend;local recovered={}
    local recovery=make({Player=me,Active=function()return active end,Allowed=function(p)return p==friend end,
        Pending=function()return visible end,Plan=function()return {},0 end,Status=function()end,
        Send=function(action)recovered[#recovered+1]=action end})
    active=true;recovery.Update(0);recovery.Update(1);assert(#recovered==1 and recovered[1]=="RequestAccept")
    visible=nil;recovery.Update(2);visible=outsider;recovery.Update(3);assert(#recovered==1)
    visible=friend;recovery.Update(4);assert(#recovered==2)
    visible=nil;recovery.Event("RequestAccept",{Requester=me,Partner=friend,RequesterItems={},PartnerItems={},RequesterCurrency=0,PartnerCurrency=1})
    recovery.Update(5);recovery.Update(8);assert(recovered[3]=="TradeConfirm","Accepted snapshot starts automation before later trade changes")
    print("PASS Trade: whitelist, exact items and Vel acknowledgment, stable offers, native confirm/accept stages, deduplication, changed offers, pause")
end
