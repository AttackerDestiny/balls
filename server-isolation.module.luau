-- Confirmed native blocks plus bounded public matchmaking; no private-server claim.
return function(ctx)
    local api={Active=false,Phase="Idle",Status="Ready",JobId=ctx.JobId}
    local run={epoch=0,solo=nil,settle=0,deadline=nil,busy=false,sameReturn=false}
    local ticket
    local pending
    local function publish(message)
        api.Status=message
        if ctx.Notify then ctx.Notify(api)end
    end
    local function current(epoch)return api.Active and run.epoch==epoch end
    local function message(reason)
        local text=tostring(reason)
        return text:match(":%d+: (.*)")or text
    end
    local transient={"block dialog did not open","did not confirm the block","block was not confirmed",
        "rejected the block","getblockeduserids","blocked-user list","another native block confirmation","has not been registered"}
    local function retryable(reason)
        local text=tostring(reason or ""):lower()
        for _,phrase in ipairs(transient)do if text:find(phrase,1,true)then return true end end
        return false
    end
    local function save()
        local ok,saved=pcall(ctx.Save,ticket)
        assert(ok and saved==true,"Could not save the search; stopped before rejoining")
    end
    local function outsiders()
        local result={}
        for _,person in ipairs(ctx.GetPlayers())do
            if not ctx.IsAllowed or not ctx.IsAllowed(person)then result[#result+1]=person end
        end
        return result
    end
    function api.Stop(reason,outcome)
        api.RetryWasTeleporting=api.Phase=="Teleporting"
        api.Retryable=outcome~="Safe"and (outcome=="Restart" or api.RetryWasTeleporting or retryable(reason))
        run.epoch=run.epoch+1;run.solo=nil;run.deadline=nil;pending=nil
        api.Active=false;api.Phase="Idle";api.Outcome=outcome or "Stopped"
        if ticket then
            ticket.Active=false
            local ok,saved=pcall(ctx.Save,ticket)
            if not ok or saved~=true then reason=(reason or "Stopped").." (could not clear resume file)"end
        end
        publish(reason or "Stopped; added blocks remain in your Roblox account")
    end
    local function valid(resume)
        if type(resume)~="table"then return false end
        local age=type(resume.StartedAt)=="number"and ctx.Now()-resume.StartedAt
        local hops=resume.Hops
        local returns=resume.SameServerReturns
        return resume.Version==1 and resume.Active==true and resume.UserId==ctx.UserId and resume.PlaceId==ctx.PlaceId
            and type(resume.RunId)=="string"and #resume.RunId<=80
            and age and age>=0
            and type(hops)=="number"and hops>=0 and hops<=12 and hops%1==0
            and type(resume.Visited)=="table"and type(resume.Added)=="table"and type(resume.SourceJob)=="string"
            and (returns==nil or type(returns)=="number"and returns>=0 and returns<=3 and returns%1==0)
    end
    local function guard(epoch,fn)
        local ok,result=pcall(fn)
        if not ok and current(epoch)then api.Stop(message(result))end
        return ok and current(epoch)
    end
    local function blocked(epoch)
        local result=ctx.GetBlocked()
        assert(type(result)=="table","Could not read the blocked-user list")
        if not current(epoch)then return nil end
        return result
    end
    local function hop(epoch)
        if not current(epoch)then return end
        ticket.Hops=ticket.Hops+1;ticket.SourceJob=ctx.JobId;ticket.Visited[ctx.JobId]=true
        if ctx.SnapshotSettings then ticket.Features=ctx.SnapshotSettings()end
        save()
        if not current(epoch)then return end
        ctx.Queue(ticket.RunId)
        if not current(epoch)then return end
        api.Phase="Teleporting";run.deadline=ctx.Clock()+35
        publish("Rejoining this floor ("..ticket.Hops.."/12)...")
        ctx.Hop()
    end
    function api.Start(resume)
        if api.Active or run.busy then return false end
        if resume and not valid(resume)then
            ticket=type(resume)=="table"and resume or nil
            api.Stop("Resume expired, changed floor/account, or did not change server")
            return false
        end
        ticket=resume;api.Ticket=ticket
        run.epoch=run.epoch+1;run.sameReturn=false
        local epoch=run.epoch
        api.Active=true;api.Phase="Preparing";api.Outcome="Searching"
        publish("Checking block access and rejoin support...")
        return guard(epoch,function()
            if resume and ctx.RestoreSettings then ctx.RestoreSettings(resume.Features)end
            if resume and ctx.Now()-resume.StartedAt>=900 then
                api.Stop("Search window ended","Restart");return
            end
            if resume and (resume.SourceJob==ctx.JobId or resume.Visited[ctx.JobId])then
                if (ticket.SameServerReturns or 0)>=3 then
                    api.Stop("Matchmaking keeps returning this server","Restart");return
                end
                ticket.SameServerReturns=(ticket.SameServerReturns or 0)+1
                run.sameReturn=true
            end
            ctx.Preflight()
            if not current(epoch)or not blocked(epoch)then return end
            ticket=resume or {Version=1,Active=true,UserId=ctx.UserId,PlaceId=ctx.PlaceId,
                RunId=ctx.NewId(),StartedAt=ctx.Now(),Hops=0,SourceJob=ctx.JobId,Visited={},Added={}}
            if not resume and ctx.SnapshotSettings then ticket.Features=ctx.SnapshotSettings()end
            assert(not ticket.Visited[ctx.JobId]or run.sameReturn,"Matchmaking returned a visited server; search stopped")
            api.Ticket=ticket;save()
            if not current(epoch)then return end
            local settling=run.sameReturn and math.min(1,.25*(ticket.SameServerReturns-1))or (ctx.SettleSeconds or 8)
            run.settle=ctx.Clock()+settling;run.solo=nil;api.Phase="Waiting"
            publish(run.sameReturn and ("Returned to the same server · retry "..ticket.SameServerReturns.."/3 pending")or "Checking this floor's population...")
        end)
    end
    local function confirmPending(epoch)
        if api.Phase~="Block settling"then return false end
        if ctx.IsPresent(pending)then
            local confirmed=blocked(epoch)
            if not confirmed then return true end
            assert(confirmed[pending.UserId],"Block was not confirmed; no rejoin attempted")
        end
        hop(epoch);return true
    end
    local function chooseAndBlock(epoch,people)
        local list=blocked(epoch)
        if not list then return end
        for _,person in ipairs(people)do
            if list[person.UserId]then ticket.LastBlockedUserId=person.UserId;hop(epoch);return end
        end
        local eligible={}
        for _,person in ipairs(people)do
            local friend=ctx.IsFriend(person)
            if not current(epoch)then return end
            if friend==false then eligible[#eligible+1]=person end
        end
        if #eligible==0 then api.Stop("No eligible players to block (friends are skipped)");return end
        local person=ctx.ChooseTarget and ctx.ChooseTarget(eligible)or eligible[ctx.Random(#eligible)]
        if not ctx.IsPresent(person)then return end
        publish("Blocking @"..person.Name.."...")
        local receipt=ctx.Block(person,function()return current(epoch)and ctx.IsPresent(person)end)
        if not current(epoch)then return end
        if not receipt and not ctx.IsPresent(person)then return end
        assert(receipt==true,"Roblox rejected the block; no rejoin attempted")
        ticket.LastBlockedUserId=person.UserId;ticket.Added[#ticket.Added+1]=person.UserId
        save()
        if not current(epoch)then return end
        pending=person;api.Phase="Block settling";run.settle=ctx.Clock()+(ctx.BlockSettleSeconds or 3)
        publish("Waiting for the block to register...")
        if ctx.BlockSettleSeconds==0 and #outsiders()>0 then confirmPending(epoch)end
    end
    local function update(epoch)
        if api.Phase=="Preparing"then return end
        if api.Phase=="Teleporting"then
            if ctx.Clock()>=run.deadline then api.Stop("Rejoin timed out; no further blocks added")end
            return
        end
        local people=outsiders()
        if #people==0 then
            run.solo=run.solo or ctx.Clock()
            if ctx.Clock()-run.solo>=(ctx.SoloSeconds or 8)then api.Stop("Protected · only you and whitelisted players","Safe")end
            return
        end
        run.solo=nil
        if ctx.Clock()<run.settle then return end
        if ctx.Now()-ticket.StartedAt>=900 or ticket.Hops>=12 then api.Stop("Search window ended","Restart");return end
        if confirmPending(epoch)then return end
        chooseAndBlock(epoch,people)
    end
    function api.Update()
        if not api.Active or run.busy then return end
        run.busy=true
        guard(run.epoch,function()update(run.epoch)end)
        run.busy=false
    end
    function api.TeleportFailed(reason)
        if api.Active and api.Phase=="Teleporting"then api.Stop("Rejoin failed: "..tostring(reason))end
    end
    function api.Retry()
        if api.Active or run.busy or not api.Retryable then return false end
        if not ticket or api.Outcome=="Restart" then return api.Start()end
        if ctx.Now()-ticket.StartedAt>=900 or ticket.Hops>=12 then
            api.Stop("Search window ended","Restart");return false
        end
        local retryHop=api.RetryWasTeleporting
        run.epoch=run.epoch+1
        local epoch=run.epoch
        api.Active=true;api.Phase="Preparing";api.Outcome="Searching";run.busy=true
        local ok=guard(epoch,function()
            ctx.Preflight()
            if not current(epoch)then return end
            local confirmed=blocked(epoch)
            if not confirmed then return end
            ticket.Active=true;save()
            if not current(epoch)then return end
            if retryHop and ticket.LastBlockedUserId and confirmed[ticket.LastBlockedUserId] and #outsiders()>0 then
                hop(epoch);return
            end
            run.settle=ctx.Clock();run.solo=nil;api.Phase="Waiting"
            publish("Retrying Safe Mode · checking this server")
        end)
        run.busy=false
        return ok
    end
    function api.Destroy(preserveResume)
        if preserveResume then run.epoch=run.epoch+1;api.Active=false
        else api.Stop("Search stopped")end
    end
    return api
end
