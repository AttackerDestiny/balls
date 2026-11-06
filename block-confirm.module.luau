-- Confirmation is a two-stage native-dialog transaction with an authoritative receipt.
return function(ctx)
    local function cancel(target)
        local _,button=ctx.Find(target)
        if button then ctx.Click(button)end
        return false
    end
    return function(target,active)
        local initial=ctx.Find(target)
        if not active()then return false end
        if not initial then ctx.Prompt(target)end
        local expires=ctx.Now()+8
        local ready
        repeat
            if not active()then return cancel(target)end
            local button=ctx.Find(target)
            if button and ctx.Ready(button)then ready=button;break end
            ctx.Sleep(.03)
        until ctx.Now()>=expires
        assert(ready,"Roblox block dialog did not open; no rejoin attempted")
        local began=ctx.Now()
        local geometry=ctx.Key(ready)
        local geometryAt=began
        local clickAt=began+.1
        local clicked=0
        local receiptAt
        repeat
            if not active()then return cancel(target)end
            local now=ctx.Now()
            if ctx.Blocked(target)then
                receiptAt=receiptAt or now
                if now-receiptAt>=ctx.Settle()then return true end
            else
                receiptAt=nil
                local button=ctx.Find(target)
                if button and ctx.Ready(button)and clicked<4 then
                    local key=ctx.Key(button)
                    if key~=geometry then geometry=key;geometryAt=now end
                    if now>=clickAt and now-geometryAt>=.06 then
                        ctx.Click(button)
                        clicked=clicked+1
                        clickAt=ctx.Now()+.3
                    end
                end
            end
            ctx.Sleep(.03)
        until ctx.Now()>=began+10
        error("Roblox did not confirm the block; no rejoin attempted")
    end
end
