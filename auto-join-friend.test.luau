return function(source)
    local make=assert(loadstring(source))()
    local function fixture()
        local f={State={Running=true,AutoJoinFriend=true,JoinFriendUsername=" @Friend_One "},Joins=0,Resolves=0,Queues=0,Now=0}
        f.Api=make({State=f.State,LocalUserId=1,Now=function()return f.Now end,
            PendingTimedOut=function()f.State.ServerTeleportStarted=false;f.Timeouts=(f.Timeouts or 0)+1 end,
            Spawn=function(fn)if f.Defer then f.Worker=fn else fn()end end,
            Resolve=function(name)assert(name=="Friend_One"or name=="Other");f.Resolves+=1;if f.OnResolve then f.OnResolve()end;return f.Id or 2 end,
            Present=function()return f.Present end,Queue=function()f.Queues+=1;if f.QueueFails then error("No queue")end end,
            Join=function(id)assert(id==2);f.Joins+=1;if f.OnJoin then f.OnJoin()end;if f.JoinError then error(f.JoinError)end;return f.Response end})
        local update=f.Api.Update
        function f.Api.Update(now)f.Now=now;return update(now)end
        return f
    end
    local f=fixture();f.Api.Update(0);f.Api.Update(1);assert(f.Joins==1 and f.Queues==1 and f.Resolves==1)
    f.Api.Update(20);assert(f.Joins==2 and f.Resolves==1)
    f.Present=true;f.Api.Update(40);assert(f.Joins==2 and f.State.AutoJoinFriendStatus:find("staying"))
    f=fixture();f.State.SafeMode=true;f.Api.Update(0);assert(f.Joins==0 and f.State.AutoJoinFriendStatus:find("whitelist"))
    f.State.SafeWhitelistIds={["2"]=true};f.Api.Update(20);assert(f.Joins==1)
    for _,key in ipairs({"ModeratorBlocking","SafeModePanic","AutoRegroupHolding","TravelBusy","AutomationTeleporting","AccountProgression","StopEverything"})do
        f=fixture();f.State[key]=true;f.Api.Update(0);assert(f.Joins==0 and f.Resolves==0,key)
    end
    f=fixture();f.OnResolve=function()f.State.AutoJoinFriend=false;f.Api.Reset()end;f.Api.Update(0);assert(f.Joins==0)
    f=fixture();f.OnResolve=function()f.State.SafeModePanic=true end;f.Api.Update(0);assert(f.Joins==0)
    f=fixture();f.Id=1;f.Api.Update(0);assert(f.Joins==0)
    f=fixture();f.State.JoinFriendUsername="Display Name";f.Api.Update(0);assert(f.Resolves==0)
    f=fixture();f.QueueFails=true;f.Api.Update(0);assert(f.Joins==0 and f.State.AutoJoinFriendStatus:find("Retrying"))
    f=fixture();f.Response="Player is offline";f.Api.Update(0);assert(f.State.AutoJoinFriendStatus==f.Response)
    f.State.JoinFriendUsername="Other";f.Api.Reset();f.Api.Update(1);assert(f.Resolves==2)
    f=fixture();assert(f.State.AutoJoinFriendStatus=="Checking friend...")
    f.State.AutoJoinFriend=false;f.Api.Reset();assert(f.State.AutoJoinFriendStatus=="Auto Join Friend is off")
    f.State.AutoJoinFriend=true;f.Api.Reset();assert(f.State.AutoJoinFriendStatus=="Checking friend...")
    for _,key in ipairs({"ModeratorBlocking","SafeModePanic","AutoRegroupHolding","TravelBusy","AutomationTeleporting","AccountProgression","StopEverything"})do
        f=fixture();f.State[key]=true;f.Api.Update(0)
        assert(f.State.AutoJoinFriendStatus~="Auto Join Friend is off"and f.State.AutoJoinFriendStatus~="Checking friend...",key)
    end
    f=fixture();f.Response="Player is offline"
    f.Api.Update(0);assert(f.Api.Failures==1 and not f.Api.CooldownUntil)
    f.Api.Update(20);assert(f.Joins==2 and f.Api.Failures==2 and f.Api.CooldownUntil==620)
    for n=21,619 do f.Api.Update(n)end
    assert(f.Joins==2 and f.Queues==2,"After two failed joins there are no new join or queue requests for ten minutes")
    f.Api.Update(620)
    assert(f.Joins==3 and f.Api.Failures==1 and not f.Api.CooldownUntil,"Retry starts a new two-attempt cycle when cooldown expires")
    f.Api.Update(640);assert(f.Api.CooldownUntil==1240)
    f.Present=true;f.Api.Update(641)
    assert(f.Api.Failures==0 and not f.Api.CooldownUntil and f.State.AutoJoinFriendStatus:find("staying"),
        "A confirmed same-server arrival clears a failure streak even during cooldown")
    f.Present=false;f.Api.Update(642);assert(f.Joins==5,"A successful arrival cannot leave the old cooldown deadline behind")
    f=fixture();f.JoinError="Native friend teleport failed"
    f.Api.Update(0);f.Api.Update(20)
    assert(f.Api.Failures==2 and f.Api.CooldownUntil==620,"Native join exceptions count as failed attempts")
    for _,reason in ipairs({"Friend join cancelled for protection or travel","Wait for a living character at the teleport pad","Teleport pad is unavailable"})do
        f=fixture();f.JoinError=reason
        for n=0,4 do f.Api.Update(n*20)end
        assert(f.Api.Failures==0 and not f.Api.CooldownUntil,"Cancelled or unready movement is not a failed join: "..reason)
    end
    f=fixture();f.QueueFails=true
    for n=0,4 do f.Api.Update(n*20)end
    assert(f.Api.Failures==0 and not f.Api.CooldownUntil,"Queue preparation errors do not consume native join attempts")
    f=fixture();f.OnJoin=function()f.State.AutoRegroupHolding=true end
    f.Api.Update(0)
    assert(f.Api.Failures==0,"A yielding join cancelled by Auto Regroup does not count as a failure")
    f=fixture();f.Response="Player is offline";f.Api.Update(0);f.Api.Update(20)
    f.State.JoinFriendUsername="Other";f.Api.Reset();f.Api.Update(21)
    assert(f.Joins==3 and f.Api.Failures==1 and not f.Api.CooldownUntil,"A different target starts a fresh attempt cycle")
    f.State.AutoJoinFriend=false;f.Api.Reset();assert(f.Api.Failures==0 and not f.Api.CooldownUntil)
    f.State.AutoJoinFriend=true;f.Api.Reset();f.Api.Update(22);assert(f.Joins==4,"Re-enabling a cancelled feature clears the old cooldown")
    f=fixture();f.OnJoin=function()f.Now+=5 end
    f.Api.Update(0);f.Api.Update(20)
    assert(f.Api.CooldownUntil==625,"Cooldown is measured from async completion, not stale dispatch time")
    f=fixture();f.OnJoin=function()f.State.ServerTeleportStarted=true end
    f.Api.Update(0);f.Api.Update(20)
    assert(f.Joins==1 and f.Api.Failures==0,"A native start receipt waits for the pending teleport; it is not counted as successful arrival")
    f.State.ServerTeleportStarted=false;f.Api.TeleportFailed("TeleportInitFailed");f.Api.TeleportFailed("OnTeleport Failed")
    assert(f.Api.Failures==1,"The two native failure events cannot double-count one pending teleport")
    f.Api.Update(21);f.Api.Update(51)
    assert(f.Joins==2 and f.Timeouts==1 and f.Api.Failures==2 and f.Api.CooldownUntil==651,
        "A native start that never finishes eventually counts as a failure")
    f=fixture();f.OnJoin=function()
        f.State.ServerTeleportStarted=true
        f.Api.TeleportFailed("Early native failure")
        f.State.ServerTeleportStarted=false
        f.Now+=5
    end
    f.Api.Update(0)
    assert(f.Api.Failures==1 and not f.Api.CooldownUntil,
        "A native failure while the adapter is still waiting is counted once when that join returns")
    f=fixture();f.Defer=true;f.Api.Update(0)
    f.State.AutoJoinFriend=false;f.Api.Reset();f.Worker()
    assert(f.Api.Failures==0 and f.Joins==0,"A queued cancelled generation cannot consume attempts")
    print("PASS Auto Join Friend: native IDs, two-failure cooldown, pending teleport receipts/timeouts, cancellation, target changes and protection gates")
end
