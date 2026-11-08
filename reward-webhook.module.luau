-- Private Discord settings and a bounded, event-driven reward sender.
return function(ctx)
    local api={RarityChoices={"Common","Uncommon","Rare","Legendary","Tribute","Burst"}}
    local function endpoint(text)
        if type(text)~="string"or #text>300 then return nil end
        local url=text:match("^%s*(.-)%s*$")
        url=url:gsub("^https://discordapp%.com/","https://discord.com/")
        return url:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+$")
    end
    local function selectRarities(values)
        local selected={}
        for _,name in ipairs(api.RarityChoices)do if values[name]==true then selected[name]=true end end
        return selected
    end
    local saved=ctx.Saved or {}
    local url=endpoint(saved.Url)
    api.Enabled=saved.Enabled==true and url~=nil and ctx.Send~=nil
    api.HidePlayer=saved.HidePlayer==true
    api.Rarities=selectRarities(type(saved.Rarities)=="table" and saved.Rarities or {Legendary=true,Tribute=true,Burst=true})
    local revision=0
    local rows,count,testPending={},0,false
    local scheduled,busy=false,false
    local function reset()
        revision+=1;rows={};count=0;testPending=false
    end
    local function status()
        if not ctx.Send then return "HTTP requests are unavailable in this executor"end
        if not url then return "Enter a Discord webhook URL"end
        return api.Enabled and "Reward webhook enabled" or "Webhook URL saved · alerts off"
    end
    api.Status=status()
    local function save()
        local ok,stored=pcall(ctx.Save,{Version=1,Url=url,Enabled=api.Enabled,HidePlayer=api.HidePlayer,Rarities=api.Rarities})
        api.Status=ok and stored and status() or "Webhook updated for this session · local save unavailable"
    end
    function api.SetUrl(text)
        local value=endpoint(text)
        if not value then api.Status="Enter a valid Discord webhook URL";return false end
        if value~=url then url=value;api.Enabled=false;reset();save()end
        return true
    end
    function api.Clear()
        url=nil;api.Enabled=false;reset();save()
    end
    function api.SetEnabled(value)
        api.Enabled=value==true and url~=nil and ctx.Send~=nil
        reset();save()
    end
    function api.SetRarities(values)
        api.Rarities=selectRarities(values or {});reset();save()
    end
    function api.SetHidePlayer(value)
        api.HidePlayer=value==true;save()
    end
    function api.Watches(rarity)
        return ctx.Alive() and api.Enabled and ctx.Send~=nil and api.Rarities[rarity]==true
    end
    local function available(stamp,isTest)
        return revision==stamp and ctx.Alive() and (isTest or api.Enabled and not ctx.Paused())
    end
    local function deliver(stamp,destination,isTest,batch)
        local lines={}
        for _,row in pairs(batch)do lines[#lines+1]=row.Rarity.." · "..row.Name.." ×"..row.Amount end
        table.sort(lines)
        local embed={title=isTest and "Feather webhook test"or "Swordburst 2 rewards",
            description=isTest and "Webhook is connected."or table.concat(lines,"\n"),color=8021215}
        if not api.HidePlayer and not isTest then embed.footer={text=ctx.PlayerName}end
        local payload={username="Feather",embeds={embed},allowed_mentions={parse={}}}
        for attempt=1,2 do
            if not available(stamp,isTest)then return end
            local ok,response=pcall(ctx.Send,destination.."?wait=true",payload)
            if not available(stamp,isTest)then return end
            local code=ok and type(response)=="table" and tonumber(response.StatusCode or response.Status)
            if code and code>=200 and code<300 then
                api.Status=isTest and "Test message delivered" or "Reward message delivered";return
            end
            if code~=429 or attempt==2 then
                api.Status=code and ("Discord request failed (HTTP "..code..")")or "Webhook request failed"
                return
            end
            local parsed,body=pcall(ctx.Decode,response.Body or "")
            local delay=parsed and type(body)=="table" and tonumber(body.retry_after)
            if not delay or delay~=delay or delay<0 or delay>120 then api.Status="Discord rate limited the webhook";return end
            ctx.Sleep(math.max(.25,delay))
        end
    end
    local function schedule()
        if scheduled or busy or not ctx.Alive()then return end
        scheduled=true
        ctx.Schedule(3,function()
            scheduled=false
            if not ctx.Alive()then return end
            local isTest=testPending
            local batch=rows
            if isTest then testPending=false else rows={};count=0 end
            if not isTest and next(batch)==nil then return end
            busy=true
            deliver(revision,url,isTest,batch)
            busy=false
            if testPending or count>0 then schedule()end
        end)
    end
    function api.Add(name,rarity,amount)
        if not api.Watches(rarity)or ctx.Paused()or type(name)~="string"or #name>120
            or type(amount)~="number"or amount%1~=0 or amount<=0 or amount>=1e12 then return end
        local key=rarity.."\0"..name
        if not rows[key]then
            if count>=20 then return end
            count+=1;rows[key]={Name=name,Rarity=rarity,Amount=0}
        end
        rows[key].Amount+=amount
        schedule()
    end
    function api.Test()
        if not url or not ctx.Send then api.Status=status();return end
        if testPending or busy then return end
        testPending=true;api.Status="Test message queued";schedule()
    end
    return api
end
