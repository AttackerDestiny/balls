return function(source)
    local make=assert(loadstring(source))()
    local count=0
    local function test(name,fn)fn();count+=1;print("PASS "..name)end
    local function fixture()
        local f={Now=0,Visible=false,Active=true,Clicks=0,Cancels=0,Prompts=0,ReadyAt=0,ConfirmAt=math.huge}
        local button,cancel={},{}
        f.Run=make({Now=function()return f.Now end,
            Find=function()if f.Visible then return button,cancel end end,
            Prompt=function()f.Prompts+=1;f.Visible=true end,
            Ready=function()return f.Now>=f.ReadyAt end,
            Key=function()return f.MovingUntil and f.Now<f.MovingUntil and tostring(f.Now)or"settled"end,
            Click=function(value)
                if value==cancel then f.Cancels+=1;return end
                f.Clicks+=1
                if f.OnClick then f.OnClick(f)end
            end,
            Sleep=function(dt)f.Now+=dt;if f.OnStep then f.OnStep(f)end end,
            Blocked=function()return f.Now>=f.ConfirmAt end,Settle=function()return .15 end})
        function f.Live()return f.Active end
        return f
    end
    test("Block confirmation retries an ignored early click after the native modal settles",function()
        local f=fixture();f.OnClick=function(v)if v.Now>=.3 then v.ConfirmAt=v.Now;v.Visible=false end end
        assert(f.Run({},f.Live)and f.Clicks==2 and f.Now<1)
    end)
    test("Block confirmation waits for ready and stable button layout",function()
        local f=fixture();f.ReadyAt=.2;f.MovingUntil=.5
        f.OnClick=function(v)assert(v.Now>=.5);v.ConfirmAt=v.Now;v.Visible=false end
        assert(f.Run({},f.Live)and f.Clicks==1)
    end)
    test("A dismissed modal is never clicked again while acknowledgment is pending",function()
        local f=fixture();f.OnClick=function(v)v.Visible=false;v.ConfirmAt=v.Now+.4 end
        assert(f.Run({},f.Live)and f.Clicks==1 and f.Prompts==1)
    end)
    test("Unconfirmed blocking has a bounded retry count and fails closed",function()
        local f=fixture();local ok=pcall(f.Run,{},f.Live)
        assert(not ok and f.Clicks==4 and f.Now>=10 and f.Prompts==1)
    end)
    test("Cancelling closes only the cancel button and cannot authorize a rejoin",function()
        local f=fixture();f.OnStep=function(v)if v.Now>=.08 then v.Active=false end end
        assert(f.Run({},f.Live)==false and f.Clicks==0 and f.Cancels==1)
    end)
    test("An existing confirmed native block needs no redundant click",function()
        local f=fixture();f.Visible=true;f.ConfirmAt=0
        assert(f.Run({},f.Live)and f.Prompts==0 and f.Clicks==0)
    end)
    test("Authoritative block acknowledgment can return on its first observation",function()
        local now,clicks,confirmAt=0,0,math.huge
        local run=make({Now=function()return now end,Find=function()return {}end,
            Ready=function()return true end,Key=function()return "stable"end,Prompt=function()end,
            Click=function()clicks+=1;confirmAt=now+.03 end,Sleep=function(dt)now+=dt end,
            Blocked=function()return now>=confirmAt end,Settle=function()return 0 end})
        assert(run({},function()return true end)and now<=.181 and clicks==1)
    end)
    print("All "..count.." native block confirmation scenarios passed")
end
