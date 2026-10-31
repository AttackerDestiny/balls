return function(ctx)
    local state,search=ctx.State,ctx.Search
    local api={Seeking=false}
    local started=false
    local function targetFloor()return ctx.TargetFloor and ctx.TargetFloor() or state.SafeFloorId end
    function api.Update()
        if not state.SafeMode or not state.Running or state.ModeratorBlocking then return end
        if state.AccountProgression and state.AutomationTeleporting then api.Seeking=true;return end
        if api.Paused then
            local protected=ctx.CurrentFloor()==targetFloor()
            for _,person in ipairs(ctx.Players()) do if not ctx.Allowed(person) then protected=false;break end end
            if protected then api.Paused=false;api.PauseReason=nil
            else
                api.Seeking=true;if ctx.Panic then ctx.Panic() end
                ctx.Status("Holding at spawn · "..tostring(api.PauseReason));return
            end
        end
        if state.SafeWhitelistResolving then
            api.Seeking=true
            for _,person in ipairs(ctx.Players()) do
                if not ctx.Allowed(person) then if ctx.Panic then ctx.Panic() end;break end
            end
            ctx.Status("Checking whitelist entries...");return
        end
        if ctx.CurrentFloor()~=targetFloor() then
            api.Seeking=true
            if ctx.Panic then ctx.Panic() end
            if not ctx.Travelling() then ctx.ChangeFloor(targetFloor()) end
            return
        end
        if search.Active then
            started=true;api.Seeking=true
            if ctx.Panic then ctx.Panic() end
            search.Update();return
        end
        if started and search.Outcome~="Safe" then
            started=false;api.Pause(search.Status);ctx.Save();return
        end
        started=false
        local outsiders={}
        for _,person in ipairs(ctx.Players()) do
            if not ctx.Allowed(person) then outsiders[#outsiders+1]=person end
        end
        if #outsiders==0 then
            api.Seeking=false
            if ctx.ReleasePanic then ctx.ReleasePanic() end
            ctx.Status("Protected · only you and whitelisted players")
            return
        end
        api.Seeking=true
        if ctx.Panic then ctx.Panic() end
        started=search.Start()==true
        if not started then api.Pause(search.Status);ctx.Save() end
    end
    function api.Pause(reason)
        api.Paused=true;api.PauseReason=reason;api.Seeking=true
        if ctx.Panic then ctx.Panic() end
        ctx.Status("Holding at spawn · "..tostring(reason))
    end
    function api.Joined(person)
        if state.SafeMode and not ctx.Allowed(person) then
            state.SafePendingUserId=person.UserId
            if ctx.Panic then ctx.Panic() end
        end
    end
    function api.Reset()
        started=false;api.Seeking=false;api.Paused=false;api.PauseReason=nil
        if search.Active then search.Stop("Safe Mode settings changed") end
        if not state.SafeMode and ctx.ReleasePanic then ctx.ReleasePanic() end
    end
    function api.Destroy() api.Reset() end
    return api
end
