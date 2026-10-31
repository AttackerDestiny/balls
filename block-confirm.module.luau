-- Native dialog confirmation only: never reopen after dismissal or click report.
return function(ctx)
    return function(target,active)
        local button,cancel=ctx.Find(target)
        if not active()then return false end
        if not button then ctx.Prompt(target)end
        local deadline=ctx.Now()+8
        repeat
            button,cancel=ctx.Find(target)
            if not active()then if cancel then ctx.Click(cancel)end;return false end
            if button and ctx.Ready(button)then break end
            ctx.Sleep(.04)
        until ctx.Now()>=deadline
        assert(button and ctx.Ready(button),"Roblox block dialog did not open; no rejoin attempted")
        local firstReady=ctx.Now()
        local stableSince,key=firstReady,ctx.Key(button)
        local nextClick,clicks,confirmedAt=firstReady+.16,0,nil
        deadline=firstReady+10
        repeat
            if not active()then
                button,cancel=ctx.Find(target);if cancel then ctx.Click(cancel)end
                return false
            end
            local now=ctx.Now()
            if ctx.Blocked(target)then
                confirmedAt=confirmedAt or now
                if now-confirmedAt>=ctx.Settle()then return true end
            else confirmedAt=nil end
            button,cancel=ctx.Find(target)
            if button and ctx.Ready(button)and clicks<4 then
                local currentKey=ctx.Key(button)
                if currentKey~=key then key=currentKey;stableSince=now end
                if now>=nextClick and now-stableSince>=.08 then
                    ctx.Click(button);clicks+=1;nextClick=ctx.Now()+.3
                end
            end
            ctx.Sleep(.04)
        until ctx.Now()>=deadline
        error("Roblox did not confirm the block; no rejoin attempted")
    end
end
