return function(source,adapterSource)
    local make=assert(loadstring(source))()
    local jobs,sent,sleeps={},{},{}
    local alive,paused=true,false
    local saved,response
    local worker=make({Alive=function()return alive end,Paused=function()return paused end,PlayerName="LocalUser",
        Schedule=function(delay,fn)assert(delay==3);jobs[#jobs+1]=fn end,
        Sleep=function(delay)sleeps[#sleeps+1]=delay end,Decode=function()return {retry_after=1.5}end,
        Save=function(value)saved=value;return true end,
        Send=function(url,payload)
            sent[#sent+1]={Url=url,Payload=payload}
            return response and response() or {StatusCode=200}
        end})
    local url="https://discord.com/api/webhooks/123/test-token"
    local function run()table.remove(jobs,1)()end
    worker.Add("Gem","Legendary",1)
    assert(#jobs==0 and not worker.Enabled)
    assert(not worker.SetUrl("https://example.com/api/webhooks/123/test-token"))
    assert(not worker.SetUrl(url.."?wait=false"))
    assert(worker.SetUrl(" "..url.." ") and saved.Url==url and worker.Url==nil and not worker.Enabled)
    worker.Test();run()
    assert(#sent==1 and sent[1].Url==url.."?wait=true" and worker.Status=="Test message delivered")
    worker.SetEnabled(true)
    worker.Add("Gem","Legendary",2);worker.Add("Gem","Legendary",3);worker.Add("Low","Rare",1)
    worker.Add("Sword","Tribute",1);worker.Add("Gem","Legendary",-2)
    assert(#jobs==1 and #sent==1)
    response=function()if #sent==2 then return {StatusCode=429,Body="rate-limited"}end;return {StatusCode=204}end
    run()
    local embed=sent[3].Payload.embeds[1]
    assert(sleeps[1]==1.5 and embed.description=="Legendary · Gem ×5\nTribute · Sword ×1")
    assert(embed.footer.text=="LocalUser" and #sent[3].Payload.allowed_mentions.parse==0)
    worker.SetHidePlayer(true);worker.SetRarities({Rare=true})
    worker.Add("Low","Rare",1);run()
    assert(sent[4].Payload.embeds[1].footer==nil and saved.Rarities.Rare)
    worker.Add("Low","Rare",1);paused=true;run();paused=false
    worker.Add("Low","Rare",1);worker.SetEnabled(false);run()
    assert(#sent==4,"Queued alerts cannot send while paused or disabled")
    worker.Test();worker.Clear();run()
    assert(#sent==4 and not saved.Url,"Clearing a URL invalidates queued requests")
    worker.SetUrl(url);worker.Test();alive=false;run();assert(#sent==4)
    print("PASS Reward webhook: validated private URL, batching, rarity filter, rate-limit retry, test and cancellation")

    local function signal()
        local event={}
        function event:Connect(callback)
            self.Callback=callback
            return {Disconnect=function()self.Callback=nil end}
        end
        function event:Fire(...)if self.Callback then self.Callback(...)end end
        return event
    end
    local inventory={ChildAdded=signal(),DescendantAdded=signal(),DescendantRemoving=signal()}
    local function item(name)
        return {Name=name,Parent=inventory,IsA=function(_,class)return class=="IntValue"end,
            FindFirstChild=function(value)return value.Count end}
    end
    local function stack(parent,amount)
        local change=signal()
        parent.Count={Name="Count",Value=amount,Parent=parent,IsA=function(_,class)return class=="ValueBase"end,
            GetPropertyChangedSignal=function()return change end}
        return change
    end
    local old=item("Old Gem");local oldChanged=stack(old,10)
    function inventory:GetChildren()return {old}end
    local definition={FindFirstChild=function()return {Value="Legendary"}end}
    local state={Running=true}
    local adapter=assert(loadstring(adapterSource))
    table.clear(jobs);table.clear(sent)
    setfenv(adapter,setmetatable({state=state,configFolder="SB2Codex",player={Name="LocalUser"},
        task={delay=function(_,fn)jobs[#jobs+1]=fn end,defer=function(fn)fn()end},
        HttpService={JSONEncode=function(_,payload)return payload end},
        request=function(packet)sent[#sent+1]=packet;return {StatusCode=200}end,
        ReplicatedStorage={Profiles={LocalUser={Inventory=inventory}},Database={Items={FindFirstChild=function()return definition end}}},
    },{__index=getfenv()}))
    adapter()
    assert(not inventory.ChildAdded.Callback)
    state.SetWebhookUrl(url);state.SetWebhookEnabled(true)
    assert(#jobs==0,"Existing inventory establishes a baseline")
    old.Count.Value=7;oldChanged:Fire();old.Count.Value=9;oldChanged:Fire()
    local fresh=item("New Gem");inventory.ChildAdded:Fire(fresh)
    stack(fresh,4);inventory.DescendantAdded:Fire(fresh.Count);run()
    assert(sent[1].Body.embeds[1].description=="Legendary · New Gem ×4\nLegendary · Old Gem ×2")
    state.WebhookController.Destroy()
    assert(not oldChanged.Callback and not inventory.ChildAdded.Callback and not inventory.DescendantAdded.Callback)
    print("PASS Reward webhook inventory: baseline, stack deltas, late Count replication and cleanup")
end
