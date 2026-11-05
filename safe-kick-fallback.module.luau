-- After a confirmed-block rejoin request, allow one scheduler turn for Started.
return function(ctx)
    local api={Armed=false,Attempts=0}
    local pendingId,busy,retryAt,failures=nil,false,0,0
    local generation=0
    function api.Reset()generation=generation+1;pendingId=nil;retryAt=0;failures=0;api.Armed=false;api.Started=false;api.Attempts=0 end
    local function enabled()return ctx.Active()and ctx.Job()==ctx.InitialJob end
    function api.MarkStarted()api.Started=true end
    function api.Requested(userId)
        if busy or api.Armed then return end
        pendingId=userId;api.Started=false;api.Update(ctx.Now())
    end
    function api.TeleportFailed()
        if pendingId and not api.Armed then api.Started=false;api.Update(ctx.Now())end
    end
    function api.Update(now)
        if api.Armed then return end
        if not enabled()or api.Started or not pendingId then return end
        local target
        for _,person in ipairs(ctx.Players())do
            if person.UserId==pendingId and not ctx.Allowed(person)then target=person;break end
        end
        if not target then pendingId=nil;failures=0;retryAt=0;return end
        if busy or failures>=3 or now<retryAt then return end
        busy=true
        local token=generation
        local function active()return token==generation and enabled()and not ctx.Allowed(target)and ctx.Present(target)end
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                ctx.Sleep(0) -- wall-clock/task scheduling, never eight seconds or a frame count.
                if not active()or api.Started or (ctx.Started and ctx.Started())then return end
                if ctx.CheckLimits then ctx.CheckLimits()end
                ctx.Pause()
                if not active()then return end
                assert(ctx.Block(target,active)==true,"Native block was not confirmed · no kick")
                if not active()then return end
                ctx.Prepare(target)
                if not active()or api.Started or (ctx.Started and ctx.Started())then return end
                api.Armed=true
                ctx.Status("Blocked · rejoin not started · kicking and rejoining")
                -- Arm recovery before Kick: it may throw or return after disconnect.
                ctx.Spawn(function()
                    ctx.Sleep(.2)
                    for attempt=1,3 do
                        if token~=generation or not enabled()or api.Started then return end
                        api.Attempts=attempt
                        local sent,message=pcall(ctx.Rejoin)
                        if not sent then ctx.Status("Fallback rejoin · "..tostring(message))end
                        ctx.Sleep(3)
                    end
                    if enabled()and not api.Started then ctx.Status("Fallback rejoin unavailable · rejoin manually")end
                end)
                ctx.Kick("Safe Mode: blocked @"..target.Name.." before automatic rejoin.")
            end)
            busy=false;ctx.Finish()
            if not ok then
                failures=failures+1;retryAt=ctx.Now()+math.min(8,2^failures)
                ctx.Status("Safe fallback · "..tostring(reason))
            end
        end)
    end
    return api
end
