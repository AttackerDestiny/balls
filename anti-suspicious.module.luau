-- Account-scoped rolling history and an absolute rest deadline.
return function(ctx)
    local maxWindow=200*60
    local maxHops=100
    local ledger={Version=1,Armed=false,Hops={}}
    local function prune(hops,now)
        local recent={}
        for i=math.max(1,#hops-maxHops+1),#hops do
            local at=hops[i]
            if type(at)=="number" and at<=now and at>now-maxWindow then recent[#recent+1]=at end
        end
        return recent
    end
    local ok,saved=pcall(ctx.Load)
    if ctx.StrictLoad then
        assert(ok,"Could not read saved Anti Suspicious rest: "..tostring(saved))
        if saved~=nil then
            assert(type(saved)=="table"and saved.Version==1 and type(saved.Hops)=="table","Invalid saved Anti Suspicious rest")
            local deadline=saved.Until
            assert(deadline==nil or type(deadline)=="number"and deadline==deadline
                and math.abs(deadline)<math.huge and deadline<=ctx.Now()+maxWindow,"Invalid saved Anti Suspicious deadline")
        end
    end
    if ok and type(saved)=="table" and saved.Version==1 and type(saved.Hops)=="table" then
        local now=ctx.Now()
        ledger.Armed=saved.Armed==true
        ledger.Hops=prune(saved.Hops,now)
        if type(saved.Until)=="number" and saved.Until>now and saved.Until<=now+maxWindow then
            ledger.Until=saved.Until
        end
    end
    local api={}
    local retryAt=0
    local function persist(nextLedger)
        local ok,result=pcall(ctx.Save,nextLedger)
        local written=ok and result~=false
        if written then ledger=nextLedger end
        return written
    end
    function api.Deadline()
        local untilAt=ledger.Until
        return untilAt and untilAt>ctx.Now() and untilAt or nil
    end
    function api.ObserveProtected()
        if not ctx.Enabled() or ledger.Armed or api.Deadline() or ctx.Now()<retryAt then return end
        local nextLedger={Version=1,Armed=true,Hops=ledger.Hops}
        if not persist(nextLedger) then retryAt=ctx.Now()+30 end
    end
    function api.Departure()
        if not ctx.Enabled() or not ledger.Armed or api.Deadline() then return end
        local now,limits=ctx.Now(),ctx.Limits()
        local hops=prune(ledger.Hops,now)
        if #hops>=maxHops then table.remove(hops,1)end
        hops[#hops+1]=now
        if not persist({Version=1,Armed=true,Hops=hops})then return end
        local count=0
        for _,at in ipairs(hops)do if at>now-limits.Window*60 then count+=1 end end
        if count>=limits.Hops then return ctx.Random(limits.Min*60,limits.Max*60) end
    end
    function api.Commit(seconds)
        local deadline=ctx.Now()+seconds
        if persist({Version=1,Armed=false,Hops={},Until=deadline})then return deadline end
    end
    return api
end
