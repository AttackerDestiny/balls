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
    local amounts=make({})
    for _,case in ipairs({{0,0},{1,0},{10,9},{11,10},{110000,100000},{660000,600000},{109999999,99999999},{110000000,100000000},{999999999,100000000}})do
        local balance,expected=case[1],case[2]
        local offer=amounts.MaxVel(balance)
        assert(offer==expected and offer*11<=balance*10 and offer<=100000000)
        if offer<100000000 then assert((offer+1)*11>balance*10)end
    end
    assert(amounts.MaxVel(nil)==0 and amounts.MaxVel(0/0)==0 and amounts.MaxVel(math.huge)==0 and amounts.MaxVel(-5)==0)
    for _,quantity in ipairs({1,64,128,129,200,512})do
        local stack={Name="Legendary Upgrade Crystal",Value=123}
        local snapshot={Requester=me,Partner=friend,RequesterItems={},PartnerItems={},RequesterCurrency=0,PartnerCurrency=0}
        local requests,confirms=0,0
        local stacks=make({Player=me,Active=function()return true end,Allowed=function(p)return p==friend end,
            Plan=function()return {stack},0 end,Count=function()return quantity end,Status=function()end,
            Send=function(action)
                if action=="TradeAddItem"then requests+=1 elseif action=="TradeConfirm"then confirms+=1 end
            end})
        stacks.Event("RequestAccept",snapshot)
        local target=math.min(quantity,400)
        for tick=1,math.ceil(target/8)+4 do
            local before=requests;stacks.Update(tick)
            assert(requests-before<=8 and requests<=target)
            stacks.Update(tick+.1);assert(requests-before<=8,"No next batch without acknowledgment")
            snapshot.RequesterItems={};for i=1,requests do snapshot.RequesterItems[i]={item=stack}end
            stacks.Event("TradeChanged",snapshot)
        end
        assert(requests==target and confirms==1,"Stacks fill to the selected quantity or the 400-unit trade cap")
    end
    local filters=make({})
    for _,rarity in ipairs({"Legendary","Tribute","Burst"})do
        assert(filters.IncludesRarity("Legendary",rarity))
        assert(filters.IncludesRarity("Tribute",rarity),"Legacy Tribute settings use Legendary+")
    end
    for _,rarity in ipairs({"Common","Uncommon","Rare","Empty","Unknown"})do assert(not filters.IncludesRarity("Legendary",rarity))end
    assert(not filters.IncludesRarity("Selected","Tribute"))
    local multiCalls,confirmCalls=0,0
    local a,b={Name="A",Value=10},{Name="B",Value=11}
    local snap={Requester=me,Partner=friend,RequesterItems={},PartnerItems={},RequesterCurrency=0,PartnerCurrency=0}
    local multi=make({Player=me,Active=function()return true end,Allowed=function(p)return p==friend end,
        Plan=function()return {a,b},0 end,Count=function()return 100 end,Status=function()end,
        Send=function(action,args)
            if action=="TradeAddItem"then multiCalls+=1;snap.RequesterItems[#snap.RequesterItems+1]={item=args[1]}
            elseif action=="TradeConfirm"then confirmCalls+=1 end
        end})
    multi.Event("RequestAccept",snap)
    for tick=1,55 do multi.Update(tick);multi.Event("TradeChanged",snap)end
    assert(multiCalls==200 and confirmCalls==1,"The total across stacks can exceed 128")
    local attempts,confirmed,status=0,0,""
    local full=make({Player=me,Active=function()return true end,Allowed=function(p)return p==friend end,
        Plan=function()return {a},0 end,Count=function()return 200 end,Status=function(text)status=text end,
        Send=function(action)if action=="TradeAddItem"then attempts+=1 elseif action=="TradeConfirm"then confirmed+=1 end end})
    full.Event("RequestAccept",{Requester=me,Partner=friend,RequesterItems={},PartnerItems={}})
    full.Update(0);full.Update(20)
    assert(attempts==8 and confirmed==0 and status:find("not acknowledged"),"A full or unresponsive server cannot cause spam or partial auto-acceptance")
    local function fixture(items,counts,existing,peerItems)
        local f={Calls={},Status="",Active=true,Allowed=true}
        f.Trade={Requester=me,Partner=friend,RequesterItems=existing or {},PartnerItems=peerItems or {},RequesterCurrency=0,PartnerCurrency=0}
        f.Worker=make({Player=me,Active=function()return f.Active end,Allowed=function(p)return p==friend and f.Allowed end,
            Plan=function()return items,0 end,Count=function(value)return counts[value]end,Status=function(text)f.Status=text end,
            Send=function(action,args)f.Calls[#f.Calls+1]={action,args};if f.OnSend then f.OnSend(action,args)end end})
        f.Worker.Event("RequestAccept",f.Trade)
        function f.Ack()
            for _,call in ipairs(f.Calls)do if call[1]=="TradeAddItem"and not call.Acked then
                f.Trade.RequesterItems[#f.Trade.RequesterItems+1]={item=call[2][1]};call.Acked=true
            end end
            f.Worker.Event("TradeChanged",f.Trade)
        end
        return f
    end
    local capped=fixture({a,b},{[a]=158,[b]=500},nil,{{item=a,count=400}})
    for tick=1,55 do capped.Worker.Update(tick*.15);capped.Ack()end
    local units,adds,confirmA=0,0,0
    for _,entry in ipairs(capped.Trade.RequesterItems)do units+=entry.count or 1;if entry.item==a then confirmA+=1 end end
    for _,call in ipairs(capped.Calls)do if call[1]=="TradeAddItem"then adds+=1 end end
    assert(units==400 and adds==400 and confirmA==158,"A 158-unit stack leaves exactly 242 slots, independent of the peer's 400-unit offer")
    capped.Worker.Update(20)
    assert(capped.Calls[#capped.Calls][1]=="TradeConfirm","A full capped offer can confirm while excess inventory remains")
    local reserved=fixture({a,b},{[a]=500,[b]=100},{{item=b,count=100}})
    for tick=1,42 do reserved.Worker.Update(tick);reserved.Ack()end
    local aCount,bCount=0,0
    for _,entry in ipairs(reserved.Trade.RequesterItems)do if entry.item==a then aCount+=entry.count or 1 else bCount+=entry.count or 1 end end
    assert(aCount==300 and bCount==100,"Eligible units already offered retain their slots before the remaining budget is allocated")
    local distinct,counts={},{}
    for i=1,12 do local value={Name="Sword"..i,Value=100+i};distinct[i]=value;counts[value]=1 end
    local fast=fixture(distinct,counts)
    fast.Worker.Update(0);assert(#fast.Calls==8,"One batch covers eight distinct items instead of only one")
    fast.Trade.RequesterItems={{item=distinct[1]}};fast.Worker.Event("TradeChanged",fast.Trade);fast.Worker.Update(.15)
    assert(#fast.Calls==8,"Partial multi-item acknowledgment cannot release the batch")
    fast.Trade.RequesterItems={};fast.Ack();fast.Worker.Update(.3)
    assert(#fast.Calls==12,"The next batch starts only after every earlier addition is acknowledged")
    local duplicate=fixture({a,a},{[a]=500})
    for tick=1,55 do duplicate.Worker.Update(tick);duplicate.Ack()end
    assert(#duplicate.Trade.RequesterItems==400,"Duplicate plan entries cannot reserve or send a second stack")
    for _,amount in ipairs({-1,0,1.5,math.huge,0/0,"2"})do
        local invalid=fixture({a},{[a]=500},{{item=a,count=amount}})
        invalid.Worker.Update(0);assert(#invalid.Calls==0 and invalid.Status:find("invalid outgoing"),"Malformed outgoing counts cannot authorize adding or acceptance")
    end
    local over=fixture({a},{[a]=500},{{item=a,count=401}})
    over.Worker.Update(0);assert(#over.Calls==0 and over.Status:find("exceeds 400"))
    local stopped=fixture(distinct,counts)
    stopped.OnSend=function()stopped.Active=false end
    stopped.Worker.Update(0);assert(#stopped.Calls==1,"Protection or toggle changes stop the remainder of a batch")
    print("PASS Trade: whitelist, exact items and Vel acknowledgment, stable offers, native confirm/accept stages, deduplication, changed offers, pause")
end
