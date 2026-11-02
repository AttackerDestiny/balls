-- Existing inventory and new drops; bounded scans and send-time protections.
return function(ctx)
    local api={}
    local allowed={Common=true,Uncommon=true,Rare=true}
    local queue,queued={},setmetatable({}, {__mode="k"})
    local head,tail,nextSend=1,0,0
    local scan,scanIndex,scanAt=nil,1,0
    local requested=setmetatable({}, {__mode="k"})
    function api.Add(item,now)
        if queued[item]or requested[item]then return end
        local rarity=ctx.Rarity(item)
        if not allowed[rarity]or not ctx.Selected(rarity)then return end
        tail+=1;queue[tail]={Item=item,Rarity=rarity,Ready=now+.75};queued[item]=true
    end
    function api.Scan(items,now)
        scan,scanIndex,scanAt=items,1,now
    end
    function api.Update(now)
        if not ctx.Active()or ctx.Busy()then return end
        if scan then
            for _=1,32 do
                local item=scan[scanIndex]
                if not item then scan=nil;break end
                scanIndex+=1;api.Add(item,scanAt)
            end
        end
        if now<nextSend or head>tail then return end
        local entry=queue[head]
        if now<entry.Ready then return end
        queue[head]=nil;head+=1;queued[entry.Item]=nil
        if head>tail then table.clear(queue);head,tail=1,0 end
        local item,rarity=entry.Item,entry.Rarity
        if not ctx.Selected(rarity)or ctx.Rarity(item)~=rarity or ctx.Protected(item)then return end
        -- Native Event has no response. Send once, never retry destruction blindly.
        nextSend=now+.4
        requested[item]=true
        local ok,reason=pcall(ctx.Send,item)
        ctx.Status(ok and ("Dismantle requested · "..item.Name)or ("Dismantle failed · "..tostring(reason)))
    end
    function api.Clear()table.clear(queue);table.clear(queued);table.clear(requested);scan=nil;head,tail=1,0 end
    return api
end
