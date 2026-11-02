return function(source)
    local make=assert(loadstring(source))()
    local function fixture()
        local f={Selected={Common=true,Uncommon=true,Rare=true},Sent={},Active=true}
        f.Api=make({Rarity=function(item)if not item.Removed then return item.Rarity end end,
            Selected=function(rarity)return f.Selected[rarity]end,
            Protected=function(item)return item.Protected end,Active=function()return f.Active end,Busy=function()return f.Busy end,
            Send=function(item)table.insert(f.Sent,item);if f.Error then error("rejected")end end,Status=function(text)f.Status=text end})
        return f
    end
    local function item(rarity)return {Name="Drop",Rarity=rarity}end
    for _,rarity in ipairs({"Common","Uncommon","Rare"})do
        local f=fixture();local drop=item(rarity);f.Api.Add(drop,0);f.Api.Add(drop,0)
        f.Api.Update(.7);assert(#f.Sent==0);f.Api.Update(.75);f.Api.Update(10)
        assert(#f.Sent==1 and f.Sent[1]==drop)
    end
    local f=fixture();f.Api.Add(item("Legendary"),0);f.Api.Add(item("Tribute"),0);f.Api.Update(1);assert(#f.Sent==0)
    f=fixture();f.Api.Add(item("Rare"),0);f.Selected.Rare=false;f.Api.Update(1);assert(#f.Sent==0)
    f=fixture();local d=item("Common");f.Api.Add(d,0);d.Protected=true;f.Api.Update(1);assert(#f.Sent==0)
    f=fixture();d=item("Common");f.Api.Add(d,0);d.Removed=true;f.Api.Update(1);assert(#f.Sent==0)
    f=fixture();f.Api.Add(item("Common"),0);f.Api.Add(item("Uncommon"),0)
    f.Busy=true;f.Api.Update(1);assert(#f.Sent==0);f.Busy=false;f.Active=false;f.Api.Update(1);assert(#f.Sent==0)
    f.Active=true;f.Api.Update(1);f.Api.Update(1.1);assert(#f.Sent==1);f.Api.Update(1.5);assert(#f.Sent==2)
    f=fixture();f.Error=true;f.Api.Add(item("Rare"),0);f.Api.Update(1);f.Api.Update(10)
    assert(#f.Sent==1 and f.Status:find("failed"),"Destructive requests must not retry blindly")
    f=fixture();f.Api.Add(item("Common"),0);f.Api.Clear();f.Api.Update(2);assert(#f.Sent==0)
    f=fixture();local old={item("Common"),item("Rare"),item("Legendary")}
    old[2].Protected=true
    f.Api.Scan(old,0);f.Api.Update(0);f.Api.Update(1);f.Api.Update(1.5)
    assert(#f.Sent==1 and f.Sent[1]==old[1],"Existing protected and unselected rarities are retained")
    f.Api.Scan(old,2);f.Api.Update(3);f.Api.Update(4);assert(#f.Sent==1,"Rescanning cannot retry an earlier destructive request")
    old[2].Protected=false;f.Api.Scan(old,5);f.Api.Update(6);assert(#f.Sent==2 and f.Sent[2]==old[2])
    f=fixture();local many={};for i=1,100 do many[i]=item("Common")end
    f.Api.Scan(many,0);f.Api.Update(0)
    -- Only the first batch is queued; mutating a later item proves it is read later.
    many[100].Rarity="Legendary"
    for i=1,100 do f.Api.Update(i)end
    assert(#f.Sent==99,"All batches drain without processing the excluded late item")
    f=fixture();local current=item("Rare");f.Api.Scan({current},0);f.Api.Update(0)
    current.Protected=true;f.Api.Update(1);assert(#f.Sent==0,"Protecting a queued inventory item cancels its request")
    print("PASS Auto dismantle: existing inventory and new drops, batched scans, no repeated requests, three rarity filters, delay, deduplication, protection recheck, cancellation, pacing, no blind retries, cleanup")
end
