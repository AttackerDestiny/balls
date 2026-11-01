return function(source)
    local function fixture()
        local f={State={Running=true},Safe={},Search={},Order={},Calls=0,Clock=0,Result="offline",Active=true}
        function f.Panic()table.insert(f.Order,"pad");return not f.NoPad end
        f.State.PanicToSpawn=f.Panic
        f.State.ReleaseSafePanic=function()f.Released=true end
        local chunk=assert(loadstring(source.."\nreturn joinFriendAtPad"))
        setfenv(chunk,setmetatable({state=f.State,safe=f.Safe,api=f.Search,
            game={ReplicatedStorage={Function={InvokeServer=function(_,route,args)
                assert(route=="Teleport"and args[1]=="FriendTeleport"and args[2]==2)
                f.Calls+=1;table.insert(f.Order,"request");return f.Calls==1 and f.First or f.Result
            end}}},os={clock=function()return f.Clock end},
            task={wait=function(seconds)f.Clock+=seconds;table.insert(f.Order,"settle");if f.OnWait then f.OnWait()end end}},{__index=getfenv()}))
        f.Join=chunk();return f
    end
    local f=fixture();f.Join(2,function()return f.Active end)
    assert(table.concat(f.Order,",")=="pad,settle,pad,request" and f.Released and not f.State.AutoJoinFriendHolding)
    f=fixture();f.First="You must be on a teleport pad to teleport!";f.Join(2,function()return true end)
    assert(f.Calls==2 and f.Released)
    f=fixture();f.NoPad=true;assert(not pcall(f.Join,2,function()return true end));assert(f.Calls==0 and f.Released)
    f=fixture();f.OnWait=function()f.Active=false end
    assert(not pcall(f.Join,2,function()return f.Active end));assert(f.Calls==0 and not f.State.AutoJoinFriendHolding)
    f=fixture();f.State.SafeMode=true;f.OnWait=function()f.Safe.Seeking=true end
    assert(not pcall(f.Join,2,function()return true end));assert(f.Calls==0 and not f.Released)
    print("PASS Friend join pad: physical arrival, settle before native request, bounded pad retry, missing pad, cancellation, protection ownership")
end
