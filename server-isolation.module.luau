-- Best-effort public matchmaking. Being alone does not prove a server is new/private.
-- All yielding/account/teleport operations are injected so cancellation can be tested.
return function(ctx)
    local api = {Active=false, Phase="Idle", Status="Ready", JobId=ctx.JobId}
    local generation, soloSince, settleUntil, hopDeadline = 0, nil, 0, nil
    local ticket, blocked, pendingPlayer, busy, retryBlockId
    local sameServerReturn=false
    local function announce(message)
        api.Status = message
        if ctx.Notify then ctx.Notify(api) end
    end
    local function live(token) return api.Active and generation == token end
    local function readable(message)
        local value = tostring(message)
        return string.match(value, ":%d+: (.*)") or value
    end
    local function persist()
        local ok, result = pcall(ctx.Save, ticket)
        if not ok or result ~= true then error("Could not save the search; stopped before rejoining") end
    end
    local function recoverable(message)
        local text=tostring(message or ""):lower()
        return text:find("block dialog did not open",1,true)~=nil
            or text:find("did not confirm the block",1,true)~=nil
            or text:find("block was not confirmed",1,true)~=nil
            or text:find("getblockeduserids",1,true)~=nil
            or text:find("blocked-user list",1,true)~=nil
            or text:find("another native block confirmation",1,true)~=nil
            or text:find("has not been registered",1,true)~=nil
    end
    function api.Stop(message,outcome)
        api.RetryWasTeleporting=api.Phase=="Teleporting"
        api.Retryable=outcome~="Safe"and (api.RetryWasTeleporting or recoverable(message))
        generation = generation + 1
        api.Active, api.Phase = false, "Idle"
        api.Outcome=outcome or "Stopped"
        soloSince, pendingPlayer, hopDeadline = nil, nil, nil
        if ticket then
            ticket.Active = false
            local ok, result = pcall(ctx.Save, ticket)
            if not ok or result ~= true then message = (message or "Stopped") .. " (could not clear resume file)" end
        end
        announce(message or "Stopped; added blocks remain in your Roblox account")
    end
    local function valid(t)
        return type(t) == "table" and t.Version == 1 and t.Active == true
            and t.UserId == ctx.UserId and t.PlaceId == ctx.PlaceId
            and type(t.RunId) == "string" and #t.RunId <= 80
            and type(t.StartedAt) == "number" and t.StartedAt <= ctx.Now()
            and ctx.Now() - t.StartedAt < 900
            and type(t.Hops) == "number" and t.Hops >= 0 and t.Hops <= 12 and t.Hops % 1 == 0
            and type(t.Visited) == "table" and type(t.Added) == "table"
            and type(t.SourceJob) == "string"
            and (t.SameServerReturns==nil or (type(t.SameServerReturns)=="number"and t.SameServerReturns>=0
                and t.SameServerReturns<=3 and t.SameServerReturns%1==0))
    end
    function api.Start(resume)
        if api.Active or busy then return false end
        if resume and not valid(resume) then
            ticket = type(resume) == "table" and resume or nil
            api.Stop("Resume expired, changed floor/account, or did not change server")
            return false
        end
        generation = generation + 1
        retryBlockId=nil;sameServerReturn=false
        local token = generation
        api.Active, api.Phase = true, "Preparing"
        api.Outcome="Searching"
        announce("Checking block access and rejoin support...")
        local ok, message = pcall(function()
            if resume and ctx.RestoreSettings then ctx.RestoreSettings(resume.Features) end
            if resume and (resume.SourceJob==ctx.JobId or resume.Visited[ctx.JobId])then
                ticket=resume;api.Ticket=ticket
                ticket.SameServerReturns=(ticket.SameServerReturns or 0)+1
                assert(ticket.SameServerReturns<=3,"Same-server retry limit reached · matchmaking did not move you")
                sameServerReturn=true
            end
            ctx.Preflight()
            if not live(token) then return end
            blocked = ctx.GetBlocked()
            if type(blocked) ~= "table" then error("Could not read the blocked-user list") end
            if not live(token) then return end
            ticket = resume or {Version=1, Active=true, UserId=ctx.UserId, PlaceId=ctx.PlaceId,
                RunId=ctx.NewId(), StartedAt=ctx.Now(), Hops=0, SourceJob=ctx.JobId, Visited={}, Added={}}
            if not resume and ctx.SnapshotSettings then ticket.Features = ctx.SnapshotSettings() end
            -- GetBlockedUserIds contains only users present in this server.
            -- An absent player disappearing from it is expected after a hop.
            if ticket.Visited[ctx.JobId]and not sameServerReturn then error("Matchmaking returned a visited server; search stopped") end
            api.Ticket = ticket
            persist()
            if not live(token) then return end
            settleUntil, soloSince = ctx.Clock() + (sameServerReturn and math.min(1,.25*(ticket.SameServerReturns-1))or (ctx.SettleSeconds or 8)), nil
            api.Phase = "Waiting"
            announce(sameServerReturn and ("Returned to the same server · retry "..ticket.SameServerReturns.."/3 pending")or "Checking this floor's population...")
        end)
        if not ok and live(token) then api.Stop(readable(message)) end
        return ok and live(token)
    end
    local function hop(token)
        if not live(token) then return end
        -- Queue is guarded by the persisted run ID; stopping makes queued work inert.
        ticket.Hops = ticket.Hops + 1
        ticket.SourceJob = ctx.JobId
        ticket.Visited[ctx.JobId] = true
        if ctx.SnapshotSettings then ticket.Features = ctx.SnapshotSettings() end
        persist()
        if not live(token) then return end
        ctx.Queue(ticket.RunId)
        if not live(token) then return end
        api.Phase, hopDeadline = "Teleporting", ctx.Clock() + 35
        announce("Rejoining this floor (" .. ticket.Hops .. "/12)...")
        ctx.Hop()
    end
    local function step(token)
        if api.Phase == "Preparing" then return end
        if ctx.Now() - ticket.StartedAt >= 900 then api.Stop("15-minute search limit reached"); return end
        if api.Phase == "Teleporting" then
            if ctx.Clock() >= hopDeadline then api.Stop("Rejoin timed out; no further blocks added") end
            return
        end
        local others = {}
        for _,person in ipairs(ctx.GetPlayers()) do
            if not ctx.IsAllowed or not ctx.IsAllowed(person) then others[#others+1]=person end
        end
        if #others == 0 then
            soloSince = soloSince or ctx.Clock()
            if ctx.Clock() - soloSince >= (ctx.SoloSeconds or 8) then
                api.Stop("Protected · only you and whitelisted players", "Safe")
            end
            return
        end
        soloSince = nil
        if ctx.Clock() < settleUntil then return end
        if sameServerReturn then
            if ticket.Hops>=12 then api.Stop("12-hop search limit reached");return end
            local confirmed=ctx.GetBlocked()
            if not live(token)then return end
            for _,person in ipairs(others)do
                if confirmed[person.UserId]then
                    ticket.LastBlockedUserId=person.UserId;hop(token);return
                end
            end
            for _,person in ipairs(others)do
                if person.UserId==ticket.LastBlockedUserId then
                    error("Block was not confirmed after same-server return; no rejoin attempted")
                end
            end
            -- The earlier target left. Any new block still follows the normal
            -- native confirmation path; never add a block merely because we returned.
            sameServerReturn=false
        end
        if api.Phase == "Block settling" then
            if ctx.IsPresent(pendingPlayer) then
                local confirmed = ctx.GetBlocked()
                if not live(token) then return end
                if not confirmed[pendingPlayer.UserId] then error("Block was not confirmed; no rejoin attempted") end
            end
            hop(token)
            return
        end
        if ticket.Hops >= 12 then api.Stop("12-hop search limit reached"); return end
        blocked = ctx.GetBlocked()
        if not live(token) then return end
        local candidates = {}
        for _, target in ipairs(others) do
            if blocked[target.UserId] then
                if ticket.Hops == 0 or retryBlockId==target.UserId then ticket.LastBlockedUserId = target.UserId; hop(token); return end
                error("A blocked player is in the joined server; matchmaking exclusion is not reliable here")
            end
            local friend = ctx.IsFriend(target)
            if not live(token) then return end
            if friend == false then candidates[#candidates + 1] = target end
        end
        if #candidates == 0 then api.Stop("No eligible players to block (friends are skipped)"); return end
        local target = ctx.ChooseTarget and ctx.ChooseTarget(candidates) or candidates[ctx.Random(#candidates)]
        if not ctx.IsPresent(target) then settleUntil = ctx.Clock() + 2; return end
        announce("Blocking @" .. target.Name .. "...")
        retryBlockId=target.UserId
        local success = ctx.Block(target, function() return live(token) end)
        if not live(token) then return end
        if success ~= true then error("Roblox rejected the block; no rejoin attempted") end
        ticket.LastBlockedUserId = target.UserId
        ticket.Added[#ticket.Added + 1] = target.UserId
        persist()
        if not live(token) then return end
        pendingPlayer, api.Phase = target, "Block settling"
        settleUntil = ctx.Clock() + (ctx.BlockSettleSeconds or 3)
        announce("Waiting for the block to register...")
    end
    function api.Update()
        if not api.Active or busy then return end
        busy = true
        local token = generation
        local ok, message = pcall(step, token)
        busy = false
        if not ok and live(token) then api.Stop(readable(message)) end
    end
    function api.TeleportFailed(message)
        if api.Active and api.Phase == "Teleporting" then api.Stop("Rejoin failed: " .. tostring(message)) end
    end
    function api.Retry()
        if api.Active or busy or not api.Retryable then return false end
        if not ticket then return api.Start()end -- Preflight failed before any block/hop.
        if ctx.Now()-ticket.StartedAt>=900 or ticket.Hops>=12 then
            api.Retryable=false;announce("Search limit reached · toggle Safe Mode OFF/ON to begin a new search");return false
        end
        local wasTeleporting=api.RetryWasTeleporting
        generation=generation+1;local token=generation
        api.Active=true;api.Phase="Preparing";api.Outcome="Searching";busy=true
        local ok,message=pcall(function()
            ctx.Preflight()
            if not live(token)then return end
            blocked=ctx.GetBlocked();assert(type(blocked)=="table","Could not read the blocked-user list")
            if not live(token)then return end
            ticket.Active=true;persist()
            if not live(token)then return end
            if wasTeleporting then
                local outsiders=0
                for _,person in ipairs(ctx.GetPlayers())do
                    if not ctx.IsAllowed or not ctx.IsAllowed(person)then outsiders=outsiders+1 end
                end
                if outsiders>0 then
                    assert(ticket.LastBlockedUserId and blocked[ticket.LastBlockedUserId],"Cannot verify previous block · no rejoin attempted")
                    hop(token);return
                end
            end
            settleUntil=ctx.Clock();soloSince=nil;api.Phase="Waiting"
            announce("Retrying Safe Mode · checking this server")
        end)
        busy=false
        if not ok and live(token)then api.Stop(readable(message))end
        return ok and live(token)
    end
    function api.Destroy(preserveResume)
        if preserveResume then
            generation = generation + 1
            api.Active = false
        else api.Stop("Search stopped") end
    end
    return api
end
