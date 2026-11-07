-- Recovery starts only after the normal confirmed-block rejoin was dispatched.
return function(ctx)
    local api={Armed=false,Attempts=0,Started=false}
    local pendingId,pendingRest
    local epoch=0
    local executing=false
    local failures,retryDue=0,0
    local function enabled()return ctx.Active()and ctx.Job()==ctx.InitialJob end
    local function started()return api.Started or ctx.Started and ctx.Started()end
    function api.Reset()
        epoch+=1;pendingId=nil;pendingRest=nil;failures=0;retryDue=0
        api.Armed=false;api.Started=false;api.Attempts=0
    end
    function api.MarkStarted()api.Started=true end
    function api.Requested(userId,restSeconds)
        if executing or api.Armed then return end
        pendingId=userId;pendingRest=restSeconds;api.Started=false
        api.Update(ctx.Now())
    end
    function api.TeleportFailed()
        if pendingId and not api.Armed then api.Started=false;api.Update(ctx.Now())end
    end
    function api.Update(now)
        if api.Armed or not enabled()or started()or not pendingId then return end
        local target
        for _,person in ipairs(ctx.Players())do
            if person.UserId==pendingId and not ctx.Allowed(person)then target=person;break end
        end
        if not target then pendingId=nil;pendingRest=nil;failures=0;retryDue=0;return end
        if executing or failures>=3 or now<retryDue then return end
        executing=true
        local token=epoch
        local restSeconds,restUntil,kicked=pendingRest
        local function valid()
            return token==epoch and enabled()and ctx.Present(target)and not ctx.Allowed(target)
        end
        local function recovery()
            ctx.Sleep(.2)
            if restUntil then
                if not kicked then return end
                while token==epoch and enabled()and not started()do
                    local remaining=restUntil-ctx.WallTime()
                    if remaining<=0 then break end
                    ctx.Sleep(math.min(remaining,30))
                end
            end
            for attempt=1,3 do
                if token~=epoch or not enabled()or started()then return end
                api.Attempts=attempt
                local sent,reason=pcall(ctx.Rejoin)
                if not sent then ctx.Status("Fallback rejoin · "..tostring(reason))end
                ctx.Sleep(3)
            end
            if enabled()and not started()then ctx.Status("Fallback rejoin unavailable · rejoin manually")end
        end
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                ctx.Sleep(0)
                if not valid()or started()then return end
                if ctx.CheckLimits then ctx.CheckLimits(restSeconds)end
                ctx.Pause()
                if not valid()then return end
                assert(ctx.Block(target,valid)==true,"Native block was not confirmed · no kick")
                if not valid()then return end
                ctx.Prepare(target,restSeconds)
                if not valid()or started()then return end
                if restSeconds then
                    restUntil=ctx.CommitRest(restSeconds)
                    assert(restUntil,"Rest deadline could not be saved · no kick")
                end
                api.Armed=true
                ctx.Status(restUntil and "Blocked · kicking for Anti Suspicious rest"or "Blocked · rejoin not started · kicking and rejoining")
                ctx.Spawn(recovery)
                ctx.Kick("Safe Mode: blocked @"..target.Name.." before automatic rejoin.")
                kicked=true
            end)
            executing=false;ctx.Finish()
            if not ok then
                failures+=1;retryDue=ctx.Now()+math.min(8,2^failures)
                ctx.Status("Safe fallback · "..tostring(reason))
            end
        end)
    end
    return api
end
