-- Safe-floor protection and retry ownership are independent from the search worker.
return function(ctx)
    local state,search=ctx.State,ctx.Search
    local api={Seeking=false}
    local session={adopted=false,retries=0,retryAt=nil,protectedAt=nil}
    local clock=ctx.Clock or os.clock
    local protectedMessage="Protected · only you and whitelisted players"
    local function destination()
        return ctx.TargetFloor and ctx.TargetFloor()or state.SafeFloorId
    end
    local function populationSafe()
        if ctx.CurrentFloor()~=destination()then return false end
        for _,person in ipairs(ctx.Players())do if not ctx.Allowed(person)then return false end end
        return true
    end
    local function panic()
        api.Seeking=true
        if ctx.Panic then ctx.Panic()end
    end
    local function protected()
        session.adopted=false;session.retries=0;session.retryAt=nil;session.protectedAt=nil
        api.Seeking=false;api.Paused=false;api.PauseReason=nil
        if ctx.ReleasePanic then ctx.ReleasePanic()end
        if ctx.Protected then ctx.Protected()end
        ctx.Status(protectedMessage)
    end
    function api.AdoptSearch()session.adopted=true end
    function api.Pause(reason)
        api.Paused=true;api.PauseReason=reason;session.retryAt=nil
        panic();ctx.Status("Holding position · "..tostring(reason))
    end
    function api.ObserveProtected()
        if ctx.Suspended and ctx.Suspended()then return end
        local canObserve=state.SafeMode and state.Running and not state.StopEverything and not state.ModeratorBlocking
            and not state.SafeWhitelistResolving and not ctx.Travelling()
        if not canObserve or not populationSafe()then session.protectedAt=nil;return end
        local now=clock()
        session.protectedAt=session.protectedAt or now
        if now-session.protectedAt<.6 then return end
        if search.Active then search.Stop(protectedMessage,"Safe")end
        protected()
    end
    local function recover()
        if populationSafe()then protected();return false end
        panic()
        if not(search.Retryable and type(search.Retry)=="function")then
            ctx.Status("Holding position · "..tostring(api.PauseReason))
            return true
        end
        local now=clock()
        local delay=search.Outcome=="Restart" and 2 or math.min(2,.25*2^session.retries)
        session.retryAt=session.retryAt or now+delay
        if now<session.retryAt then
            ctx.Status("Retrying Safe Mode · "..tostring(api.PauseReason))
            return true
        end
        session.retries=math.min(3,session.retries+1);session.retryAt=nil;api.Paused=false
        session.adopted=search.Retry()==true
        if session.adopted then search.Update()else api.Pause(search.Status)end
        return true
    end
    function api.Update()
        if ctx.Suspended and ctx.Suspended()then return end
        if not state.SafeMode or not state.Running or state.StopEverything or state.ModeratorBlocking then return end
        if state.AccountProgression and state.AutomationTeleporting then api.Seeking=true;return end
        if state.SafeWhitelistResolving then
            api.Seeking=true
            for _,person in ipairs(ctx.Players())do if not ctx.Allowed(person)then panic();break end end
            ctx.Status("Checking whitelist entries...")
            return
        end
        local floor=destination()
        if ctx.CurrentFloor()~=floor then
            panic()
            if not ctx.Travelling()then ctx.ChangeFloor(floor)end
            return
        end
        if api.Paused and recover()then return end
        if search.Active then
            session.adopted=true;panic();search.Update();return
        end
        if session.adopted and search.Outcome~="Safe"then
            session.adopted=false;api.Pause(search.Status);ctx.Save();return
        end
        session.adopted=false
        if populationSafe()then protected();return end
        panic()
        session.adopted=search.Start()==true
        if session.adopted then search.Update()else api.Pause(search.Status);ctx.Save()end
    end
    function api.Joined(person)
        if ctx.Suspended and ctx.Suspended()then return end
        if state.SafeMode and not ctx.Allowed(person)then state.SafePendingUserId=person.UserId;panic()end
    end
    function api.Reset()
        session={adopted=false,retries=0}
        api.Seeking=false;api.Paused=false;api.PauseReason=nil
        if search.Active then search.Stop("Safe Mode settings changed")end
        if not state.SafeMode and ctx.ReleasePanic then ctx.ReleasePanic()end
    end
    function api.Destroy()api.Reset()end
    return api
end
