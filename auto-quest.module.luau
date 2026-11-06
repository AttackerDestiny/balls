-- Completion membership is the lifetime of a claim receipt.
return function(ctx)
    local api={Claims=0}
    local receipts=setmetatable({}, {__mode="k"})
    local due=0
    function api.Update(now)
        if now<due or not ctx.Active() then return end
        due=now+.5
        local completed=ctx.Ready()
        local live={}
        for index=1,#completed do live[completed[index]]=true end
        for quest in pairs(receipts)do if not live[quest]then receipts[quest]=nil end end
        if ctx.Busy() then return end
        for index=1,#completed do
            local quest=completed[index]
            local receipt=receipts[quest]
            local retry=not receipt or (receipt.count<3 and now>=receipt.retry)
            if retry and ctx.Valid(quest) then
                local attempts=receipt and receipt.count+1 or 1
                receipts[quest]={count=attempts,retry=now+attempts*10}
                local sent,reason=pcall(ctx.Claim,quest)
                if sent then api.Claims=api.Claims+1 else api.Error=tostring(reason)end
                break
            end
        end
    end
    return api
end
