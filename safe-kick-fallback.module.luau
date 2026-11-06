-- Delayed recovery is armed only after the outsider's native block is verified.
return function(ctx)
    local api={Armed=false,Attempts=0}
    local arrivals={}
    local epoch=0
    local executing=false
    local attempts=0
    local retryDue=0
    local function enabled()return ctx.Active()and ctx.Job()==ctx.InitialJob end
    function api.Reset()
        epoch=epoch+1;arrivals={};attempts=0;retryDue=0
        api.Armed=false;api.Started=false;api.Attempts=0
    end
    function api.MarkStarted()if api.Armed and api.Attempts>0 then api.Started=true end end
    local function oldest(now)
        local membership={}
        local chosen,since
        for _,person in ipairs(ctx.Players())do
            if not ctx.Allowed(person)then
                local id=person.UserId
                membership[id]=true;arrivals[id]=arrivals[id]or now
                if not since or arrivals[id]<since then chosen,since=person,arrivals[id]end
            end
        end
        for id in pairs(arrivals)do if not membership[id]then arrivals[id]=nil end end
        return chosen,since
    end
    function api.Update(now)
        if api.Armed then return end
        if not enabled()then arrivals={};return end
        local target,since=oldest(now)
        if not target then attempts=0;retryDue=0;return end
        if executing or attempts>=3 or now<retryDue or now-since<8 then return end
        executing=true
        local token=epoch
        local function valid()
            return token==epoch and enabled()and ctx.Present(target)and not ctx.Allowed(target)
        end
        local function recovery()
            ctx.Sleep(.2)
            local attempt=1
            while attempt<=3 and token==epoch and enabled()and not api.Started do
                api.Attempts=attempt
                local sent,reason=pcall(ctx.Rejoin)
                if not sent then ctx.Status("Fallback rejoin · "..tostring(reason))end
                ctx.Sleep(3);attempt=attempt+1
            end
            if enabled()and not api.Started then ctx.Status("Fallback rejoin unavailable · rejoin manually")end
        end
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                if not valid()then return end
                if ctx.CheckLimits then ctx.CheckLimits()end
                ctx.Pause()
                if not valid()then return end
                local confirmed=ctx.Block(target,valid)
                assert(confirmed==true,"Native block was not confirmed · no kick")
                if not valid()then return end
                ctx.Prepare(target)
                if not valid()then return end
                api.Armed=true
                ctx.Status("Outsider still present after 8s · blocked · kicking and rejoining")
                ctx.Spawn(recovery)
                ctx.Kick("Safe Mode: blocked @"..target.Name.." before automatic rejoin.")
            end)
            executing=false;ctx.Finish()
            if not ok then
                attempts=attempts+1;retryDue=ctx.Now()+math.min(8,2^attempts)
                ctx.Status("Safe fallback · "..tostring(reason))
            end
        end)
    end
    return api
end
