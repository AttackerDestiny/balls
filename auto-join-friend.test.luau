return function(source)
    local make=assert(loadstring(source))()
    local function fixture()
        local f={State={Running=true,AutoJoinFriend=true,JoinFriendUsername=" @Friend_One "},Joins=0,Resolves=0,Queues=0}
        f.Api=make({State=f.State,LocalUserId=1,Spawn=function(fn)fn()end,
            Resolve=function(name)assert(name=="Friend_One"or name=="Other");f.Resolves+=1;if f.OnResolve then f.OnResolve()end;return f.Id or 2 end,
            Present=function()return f.Present end,Queue=function()f.Queues+=1;if f.QueueFails then error("No queue")end end,
            Join=function(id)assert(id==2);f.Joins+=1;return f.Response end})
        return f
    end
    local f=fixture();f.Api.Update(0);f.Api.Update(1);assert(f.Joins==1 and f.Queues==1 and f.Resolves==1)
    f.Api.Update(20);assert(f.Joins==2 and f.Resolves==1)
    f.Present=true;f.Api.Update(40);assert(f.Joins==2 and f.State.AutoJoinFriendStatus:find("staying"))
    f=fixture();f.State.SafeMode=true;f.Api.Update(0);assert(f.Joins==0 and f.State.AutoJoinFriendStatus:find("whitelist"))
    f.State.SafeWhitelistIds={["2"]=true};f.Api.Update(20);assert(f.Joins==1)
    for _,key in ipairs({"ModeratorBlocking","SafeModePanic","TravelBusy","AutomationTeleporting","AccountProgression","StopEverything"})do
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
    for _,key in ipairs({"ModeratorBlocking","SafeModePanic","TravelBusy","AutomationTeleporting","AccountProgression","StopEverything"})do
        f=fixture();f.State[key]=true;f.Api.Update(0)
        assert(f.State.AutoJoinFriendStatus~="Auto Join Friend is off"and f.State.AutoJoinFriendStatus~="Checking friend...",key)
    end
    print("PASS Auto Join Friend: native IDs, pacing, same-server stop, whitelist, travel priority, cancellation, self, invalid names, queue failure, server errors")
end
