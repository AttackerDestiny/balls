-- In-memory players, callbacks and kicks only. Never blocks/kicks a real account.
return function(source)
    local passed=0
    local function test(name,fn)fn();passed+=1;print("PASS "..name)end
    local function fixture(present)
        local f={State={Running=true},Queue={},Order={},Blocks=0,Kicks=0,Saves=0,Paused=0,Result=true}
        local listeners={}
        local signal={}
        function signal:Connect(fn)
            local c={Connected=true};function c:Disconnect()self.Connected=false end
            listeners[#listeners+1]={Fn=fn,C=c};return c
        end
        function signal:Fire(p)for _,v in ipairs(listeners)do if v.C.Connected then v.Fn(p)end end end
        local localPlayer={UserId=12671,Name="Local fixture"}
        local players={LocalPlayer=localPlayer,PlayerAdded=signal}
        function players:GetPlayers()return present or {localPlayer,{UserId=999999999999,Name="Regular fixture"}}end
        local chunk=assert(loadstring(source))
        setfenv(chunk,setmetatable({task={defer=function(fn,...)f.Queue[#f.Queue+1]={Fn=fn,Args={...}}end},os={time=function()return 123 end}},{__index=getfenv()}))
        f.Api=chunk()({State=f.State,Players=players,
            Pause=function()f.Paused+=1;f.Order[#f.Order+1]="pause"end,
            Save=function()f.Saves+=1;f.Order[#f.Order+1]="save";if f.SaveFails then error("storage unavailable")end end,
            Block=function(player,active)
                assert(f.State.ModeratorBlocking and f.Paused==1 and active())
                f.Blocks+=1;f.Order[#f.Order+1]="block"
                if f.OnBlock then return f.OnBlock(player,active)end
                return f.Result
            end,
            Kick=function(message)
                assert(f.State.ModeratorBlockConfirmed,"Never kick before an explicit block acknowledgment")
                f.Kicks+=1;f.Order[#f.Order+1]="kick";f.Message=message
            end})
        function f.Flush()
            while #f.Queue>0 do local v=table.remove(f.Queue,1);v.Fn(unpack(v.Args))end
        end
        f.Signal=signal;return f
    end
    local listed={UserId=4402987,Name="Listed fixture"}
    test("Moderator detection ignores the local and unlisted accounts",function()
        local f=fixture();f.Flush();assert(f.Kicks==0 and f.Blocks==0 and f.Paused==0)
    end)
    test("A moderator join pauses immediately and confirms the block before kicking",function()
        local f=fixture();f.Flush();f.Signal:Fire(listed)
        assert(f.Paused==1 and f.State.ModeratorBlocking and f.Kicks==0 and f.Blocks==0)
        f.Flush();assert(f.Blocks==1 and f.Kicks==1 and f.Message:find(listed.Name,1,true))
        assert(table.concat(f.Order,",")=="pause,save,block,save,kick")
    end)
    test("A listed moderator already present is also blocked before disconnect",function()
        local f=fixture({listed});f.Flush();assert(f.Blocks==1 and f.Kicks==1)
    end)
    test("Unconfirmed or rejected blocking leaves automation paused without kicking",function()
        for _,result in ipairs({false,"queued"})do
            local f=fixture();f.Result=result;f.Signal:Fire(listed);f.Flush()
            assert(f.Blocks==1 and f.Kicks==0 and f.Api.Failed and f.State.ModeratorBlocking)
        end
    end)
    test("A native block error never falls through to an unblocked kick",function()
        local f=fixture();f.OnBlock=function()error("Native confirmation unavailable")end
        f.Signal:Fire(listed);f.Flush()
        assert(f.Kicks==0 and f.State.ModeratorBlockError:find("Native confirmation unavailable",1,true))
    end)
    test("Cleanup during blocking cancels the pending moderator kick",function()
        local f=fixture();f.OnBlock=function()f.Api.Destroy();return true end
        f.Signal:Fire(listed);f.Flush();assert(f.Kicks==0 and not f.Api.Enabled)
    end)
    test("Stop Everything cancels blocking and prevents moderator side effects",function()
        local f=fixture();f.State.StopEverything=true;f.Signal:Fire(listed);f.Flush();assert(f.Blocks==0)
        f=fixture();f.OnBlock=function()f.State.StopEverything=true;return true end
        f.Signal:Fire(listed);f.Flush();assert(f.Kicks==0)
    end)
    test("Duplicate moderator detections disconnect only once and cleanup removes the watcher",function()
        local f=fixture();f.Signal:Fire(listed);f.Signal:Fire({UserId=7858636,Name="Second fixture"});f.Flush()
        assert(f.Blocks==1 and f.Kicks==1)
        f.Api.Destroy();f.Signal:Fire({UserId=13444058,Name="After cleanup"});f.Flush();assert(f.Kicks==1)
    end)
    test("A settings-write failure cannot skip native block confirmation",function()
        local f=fixture();f.SaveFails=true;f.Signal:Fire(listed);f.Flush()
        assert(f.Blocks==1 and f.Kicks==1 and f.State.ModeratorBlockConfirmed)
    end)
    print("All "..passed.." moderator block-before-kick scenarios passed")
    return {Passed=true,NoRealKick=true,Count=passed}
end
