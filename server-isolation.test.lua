-- Runs without Roblox: lua server-isolation.test.lua
local make = assert(loadfile("server-isolation.module.luau"))()
local function copy(t)
    if type(t) ~= "table" then return t end
    local r = {}; for k,v in pairs(t) do r[k] = copy(v) end; return r
end
local count = 0
local function test(name, fn)
    fn(); count = count + 1; print("PASS " .. name)
end
local function fixture(resume, job)
    local f = {time=0, wall=1000, others={{UserId=2,Name="Other"}}, blocked={}, blocks=0, hops=0, queues=0, log={}}
    local ctx = {UserId=1, PlaceId=10, JobId=job or "A1",
        Now=function() return f.wall end, Clock=function() return f.time end,
        NewId=function() return "run-1" end, Random=function() return 1 end,
        Preflight=function() end, GetPlayers=function() return f.others end,
        GetBlocked=function() return copy(f.blocked) end,
        IsFriend=function(p) return p.Friend == true end,
        IsPresent=function() return true end,
        Block=function(p) f.blocks=f.blocks+1; f.blocked[p.UserId]=true; return true end,
        Save=function(t) f.saved=copy(t); f.log[#f.log+1]="save"; return true end,
        Queue=function() f.queues=f.queues+1; f.log[#f.log+1]="queue" end,
        Hop=function() f.hops=f.hops+1; f.log[#f.log+1]="hop" end}
    f.ctx=ctx; f.api=make(ctx)
    function f.start(t) return f.api.Start(t or resume) end
    function f.tick(t) f.time=t; f.api.Update() end
    return f
end
test("solo requires a stable eight seconds and stops", function()
    local f=fixture(); f.others={}; assert(f.start()); f.tick(0); f.tick(7)
    assert(f.api.Active); f.tick(8); assert(not f.api.Active and f.blocks==0 and not f.saved.Active)
end)
test("new arrivals reset the solo timer", function()
    local f=fixture(); f.others={}; f.start(); f.tick(0)
    f.others={{UserId=2,Name="Other"}}; f.tick(4); f.others={}; f.tick(5); f.tick(12)
    assert(f.api.Active); f.tick(13); assert(not f.api.Active)
end)
test("skip friends, confirm block, persist before queue and rejoin", function()
    local f=fixture(); f.others={{UserId=3,Name="Friend",Friend=true},f.others[1]}
    f.start(); f.tick(8); assert(f.blocks==1 and f.blocked[2] and not f.blocked[3] and f.hops==0)
    f.tick(10); assert(f.hops==0); f.tick(11)
    assert(f.hops==1 and f.queues==1 and f.saved.Visited.A1 and f.saved.Hops==1 and f.saved.Added[1]==2)
    assert(f.log[#f.log-2]=="save" and f.log[#f.log-1]=="queue" and f.log[#f.log]=="hop")
    f.tick(12); assert(f.blocks==1 and f.hops==1)
end)
test("resume on A2 then finish alone", function()
    local a=fixture(); a.start(); a.tick(8); a.tick(11)
    local b=fixture(a.saved,"A2"); b.blocked=copy(a.blocked); b.others={}; assert(b.start()); b.tick(0); b.tick(8)
    assert(not b.api.Active and b.blocks==0 and b.saved.Hops==1)
end)
test("same or visited job cannot cause another block", function()
    local a=fixture(); a.start(); a.tick(8); a.tick(11)
    local b=fixture(a.saved,"A1"); assert(not b.start() and b.blocks==0)
    local t=copy(a.saved); t.SourceJob="A2"
    local c=fixture(t,"A1"); assert(not c.start() and c.blocks==0 and not c.saved.Active)
end)
test("server-local blocked list can be empty after a successful hop", function()
    local a=fixture(); a.start(); a.tick(8); a.tick(11)
    local b=fixture(a.saved,"A2"); assert(b.start() and b.api.Active and b.blocks==0)
end)
test("a confirmed blocked player leaving does not become a failed block", function()
    local f=fixture(); f.start(); f.tick(8)
    f.others={{UserId=3,Name="Replacement"}}; f.blocked={}
    f.ctx.IsPresent=function(p) return p.UserId~=2 end
    f.tick(11); assert(f.api.Active and f.hops==1 and f.blocks==1)
end)
test("existing block allows first hop; blocked player after rejoin stops", function()
    local f=fixture(); f.blocked[2]=true; f.start(); f.tick(8)
    assert(f.api.Active and f.blocks==0 and f.hops==1)
    local g=fixture(f.saved,"A2"); g.blocked[2]=true; g.start(); g.tick(8)
    assert(not g.api.Active and g.blocks==0 and g.hops==0)
end)
test("failed block or missing confirmation never rejoins", function()
    for _, confirmed in ipairs({false,true}) do
        local f=fixture(); f.ctx.Block=function() f.blocks=f.blocks+1; return confirmed end
        f.start(); f.tick(8); f.tick(11)
        assert(not f.api.Active and f.blocks==1 and f.hops==0)
    end
end)
test("cancel during a yielding operation prevents subsequent side effects", function()
    for _, name in ipairs({"Preflight","GetBlocked","IsFriend","Block","Queue"}) do
        local f=fixture(); local original=f.ctx[name]
        f.ctx[name]=function(...) local r=original(...); f.api.Stop("cancelled"); return r end
        f.start(); f.tick(8); f.tick(11)
        assert(not f.api.Active and f.hops==0, name)
        if name~="Block" and name~="Queue" then assert(f.blocks==0, name) end
    end
end)
test("friends only and departed candidate add no blocks", function()
    local f=fixture(); f.others[1].Friend=true; f.start(); f.tick(8)
    assert(not f.api.Active and f.blocks==0)
    local g=fixture(); g.ctx.IsPresent=function() return false end; g.start(); g.tick(8)
    assert(g.api.Active and g.blocks==0)
end)
test("save and queue failures stop before teleport", function()
    local f=fixture(); f.ctx.Save=function() return false end
    assert(not f.start() and f.blocks==0)
    local g=fixture(); g.ctx.Queue=function() error("unsupported") end
    g.start(); g.tick(8); g.tick(11); assert(not g.api.Active and g.hops==0 and not g.saved.Active)
end)
test("teleport error and timeout do not repeat blocks", function()
    local f=fixture(); f.start(); f.tick(8); f.tick(11); f.api.TeleportFailed("full"); f.tick(50)
    assert(not f.api.Active and f.blocks==1 and f.hops==1 and not f.saved.Active)
    local g=fixture(); g.start(); g.tick(8); g.tick(11); g.tick(46)
    assert(not g.api.Active and g.blocks==1 and g.hops==1)
end)
test("bounded hops, lifetime, floor, and account", function()
    local a=fixture(); a.start(); a.tick(8); a.tick(11)
    local t=copy(a.saved); t.Hops=12
    local b=fixture(t,"A2"); b.blocked=copy(a.blocked); assert(b.start()); b.tick(8); assert(not b.api.Active and b.blocks==0)
    for _, key in ipairs({"PlaceId","UserId","StartedAt"}) do
        local invalid=copy(a.saved); invalid[key]=0
        local f=fixture(invalid,"A2"); assert(not f.start() and f.blocks==0,key)
    end
    local f=fixture(); f.start(); f.wall=1900; f.tick(8); assert(not f.api.Active and f.blocks==0)
end)
test("stop between block and rejoin invalidates queued resume", function()
    local f=fixture(); f.start(); f.tick(8); f.api.Stop(); f.tick(20)
    assert(f.blocks==1 and f.hops==0 and not f.saved.Active)
end)
test("teleport teardown preserves resume; explicit close cancels it", function()
    local f=fixture(); f.start(); f.tick(8); f.tick(11); f.api.Destroy(true)
    assert(not f.api.Active and f.saved.Active); f.tick(50); assert(f.hops==1)
    local g=fixture(); g.start(); g.tick(8); g.tick(11); g.api.Destroy()
    assert(not g.api.Active and not g.saved.Active)
end)
test("resume restores settings before reading this server's block list", function()
    local a=fixture(); local preferences={Enabled=true,AutoFarm=false,SkillAura=true}
    a.ctx.SnapshotSettings=function() return copy(preferences) end
    a.start(); preferences.AutoFarm=true; a.tick(8); a.tick(11)
    assert(a.saved.Features.AutoFarm)
    local b=fixture(a.saved,"A2"); local restored
    b.ctx.RestoreSettings=function(value) restored=copy(value) end
    assert(b.start() and restored.Enabled and restored.AutoFarm and restored.SkillAura)
    local c=fixture(a.saved,"A1"); local sameRestored
    c.ctx.RestoreSettings=function(value) sameRestored=copy(value) end
    assert(not c.start() and sameRestored.AutoFarm and not c.api.Active)
end)
test("whitelisted users do not prevent a protected result", function()
    local f=fixture();f.ctx.IsAllowed=function()return true end;f.start();f.tick(0);f.tick(8)
    assert(not f.api.Active and f.api.Outcome=="Safe" and f.blocks==0)
end)
test("fast timings retain registration-before-rejoin", function()
    local f=fixture();f.ctx.SettleSeconds=.1;f.ctx.BlockSettleSeconds=.15;f.ctx.SoloSeconds=.2
    f.start();f.tick(.11);assert(f.blocks==1 and f.hops==0);f.tick(.27);assert(f.hops==1)
end)
print("All " .. count .. " server-isolation scenarios passed")
