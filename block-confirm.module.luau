-- Confirmation is a two-stage native-dialog transaction with an authoritative receipt.
return function(ctx)
    local function cancel(target)
        local _,button=ctx.Find(target)
        if button then ctx.Click(button,nil,"Cancel")end
        return false
    end
    return function(target,active)
        local initial,_,pending=ctx.Find(target)
        if not active()then return false end
        local prompted=false
        if not initial and not pending then ctx.Prompt(target);prompted=true end
        local expires=ctx.Now()+8
        local ready
        local observed=initial~=nil
        repeat
            if not active()then return cancel(target)end
            local button,_,waiting=ctx.Find(target)
            pending=waiting
            observed=observed or button~=nil
            if not button and not waiting and not prompted then ctx.Prompt(target);prompted=true end
            if button and ctx.Ready(button)then ready=button;break end
            ctx.Sleep(.03)
        until ctx.Now()>=expires
        if not ready and pending=="Ambiguous"then error("Roblox block dialog target is ambiguous; no rejoin attempted")end
        if not ready and pending=="Busy"then error("Another Roblox block dialog is open; waiting for it to close")end
        if not ready and observed then error("Native block button is not ready or covered; no rejoin attempted")end
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
                        clicked=clicked+1
                        ctx.Click(button,clicked)
                        clickAt=ctx.Now()+math.min(3,.3*4^(clicked-1))
                    end
                end
            end
            ctx.Sleep(.03)
        until ctx.Now()>=began+10
        error("Roblox did not confirm the block; no rejoin attempted")
    end
end
