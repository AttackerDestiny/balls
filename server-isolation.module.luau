-- Best-effort public matchmaking. Being alone does not prove a server is new/private.
-- All yielding/account/teleport operations are injected so cancellation can be tested.
return function(ctx)
    local api = {Active=false, Phase="Idle", Status="Ready", JobId=ctx.JobId}
    local generation, soloSince, settleUntil, hopDeadline = 0, nil, 0, nil
    local ticket, blocked, pendingPlayer, busy
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
    function api.Stop(message,outcome)
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
    end
    function api.Start(resume)
        if api.Active or busy then return false end
        if resume and not valid(resume) then
            ticket = type(resume) == "table" and resume or nil
            api.Stop("Resume expired, changed floor/account, or did not change server")
            return false
        end
        generation = generation + 1
        local token = generation
        api.Active, api.Phase = true, "Preparing"
        api.Outcome="Searching"
        announce("Checking block access and rejoin support...")
        local ok, message = pcall(function()
            if resume and ctx.RestoreSettings then ctx.RestoreSettings(resume.Features) end
            if resume and resume.SourceJob == ctx.JobId then
                ticket = resume
                error("Rejoin returned the same server; search stopped")
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
            if ticket.Visited[ctx.JobId] then error("Matchmaking returned a visited server; search stopped") end
            api.Ticket = ticket
            persist()
            if not live(token) then return end
            settleUntil, soloSince = ctx.Clock() + (ctx.SettleSeconds or 8), nil
            api.Phase = "Waiting"
            announce("Checking this floor's population...")
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
                if ticket.Hops == 0 then ticket.LastBlockedUserId = target.UserId; hop(token); return end
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
    function api.Destroy(preserveResume)
        if preserveResume then
            generation = generation + 1
            api.Active = false
        else api.Stop("Search stopped") end
    end
    return api
end
