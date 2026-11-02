-- Eight seconds with a present outsider in this job triggers one confirmed-block kick.
return function(ctx)
    local api={Armed=false,Attempts=0}
    local seen,busy,retryAt,failures={},false,0,0
    local generation=0
    function api.Reset()generation=generation+1;seen={};retryAt=0;failures=0;api.Armed=false;api.Started=false;api.Attempts=0 end
    local function enabled()return ctx.Active()and ctx.Job()==ctx.InitialJob end
    function api.MarkStarted()if api.Armed and api.Attempts>0 then api.Started=true end end
    function api.Update(now)
        if api.Armed then return end
        if not enabled()then seen={};return end
        local present,target,oldest={}
        for _,person in ipairs(ctx.Players())do
            if not ctx.Allowed(person)then
                present[person.UserId]=true
                seen[person.UserId]=seen[person.UserId]or now
                if not oldest or seen[person.UserId]<oldest then target,oldest=person,seen[person.UserId]end
            end
        end
        for id in pairs(seen)do if not present[id]then seen[id]=nil end end
        if not target then failures=0;retryAt=0;return end
        if busy or failures>=3 or now<retryAt or now-oldest<8 then return end
        busy=true
        local token=generation
        local function active()return token==generation and enabled()and not ctx.Allowed(target)and ctx.Present(target)end
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                if not active()then return end
                if ctx.CheckLimits then ctx.CheckLimits()end
                ctx.Pause()
                if not active()then return end
                assert(ctx.Block(target,active)==true,"Native block was not confirmed · no kick")
                if not active()then return end
                ctx.Prepare(target)
                if not active()then return end
                api.Armed=true
                ctx.Status("Outsider still present after 8s · blocked · kicking and rejoining")
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
