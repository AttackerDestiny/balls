return function(source)
    local passed=0
    local function test(name,fn)fn();passed+=1;print("PASS "..name)end
    local function fixture(replies)
        local f={Now=0,Calls=0,Queues=0,Pads=0,Unlocked=true}
        local state={Running=true,AccountProgression=true,PingMs=64}
        state.PanicToSpawn=function()f.Pads+=1;return true end
        state.QueueAutomation=function()f.Queues+=1 end
        state.IsAutomationFloorUnlocked=function()return f.Unlocked end
        local fn=assert(loadstring(source))
        setfenv(fn,setmetatable({state=state,catalog={FloorById={[3]={Id=3}}},
            os={clock=function()return f.Now end},
            task={wait=function(dt)f.Now+=dt;if f.Stop then state.AccountProgression=false end end},
            fail=function(value)f.Error=value;state.AutomationTeleporting=false end,
            game={ReplicatedStorage={Function={InvokeServer=function(_,name,args)
                assert(name=="Teleport"and args[1]=="Teleport"and args[2]==3)
                f.Calls+=1;return replies and replies[f.Calls]
            end}}}},{__index=getfenv()}));fn();f.State=state;return f
    end
    test("Floor travel settles at the real pad before its native request",function()
        local f=fixture();assert(f.State.ChangeAutomationFloor(3))
        assert(f.Now>=.5 and f.Calls==1 and f.Queues==1 and f.Pads==2)
    end)
    test("A first native refusal receives one bounded pad-settle retry",function()
        local f=fixture({"Return to the teleporter"});assert(f.State.ChangeAutomationFloor(3))
        assert(f.Calls==2 and f.Queues==1 and f.Now>=1 and not f.State.LastFloorTravelError)
    end)
    test("Persistent native floor errors retain their reason and stop after two requests",function()
        local f=fixture({"Floor unavailable","Floor unavailable"});local ok,reason=f.State.ChangeAutomationFloor(3)
        assert(not ok and reason:find("Floor unavailable",1,true)and f.Calls==2)
        assert(f.State.LastFloorTravelError==reason and f.Error)
    end)
    test("A progression stop or locked floor cannot issue another floor request",function()
        local f=fixture();f.Stop=true;assert(not f.State.ChangeAutomationFloor(3)and f.Calls==0)
        f=fixture();f.Unlocked=false;assert(not f.State.ChangeAutomationFloor(3)and f.Calls==0 and f.Queues==0)
    end)
    print("All "..passed.." floor transition scenarios passed")
end
