-- New-drop dismantling only, matching the supplied source. No inventory sweep.
return function(ctx)
    local api={}
    local allowed={Common=true,Uncommon=true,Rare=true}
    local queue,queued={},setmetatable({}, {__mode="k"})
    local head,tail,nextSend=1,0,0
    function api.Add(item,now)
        if queued[item]then return end
        local rarity=ctx.Rarity(item)
        if not allowed[rarity]or not ctx.Selected(rarity)then return end
        tail+=1;queue[tail]={Item=item,Rarity=rarity,Ready=now+.75};queued[item]=true
    end
    function api.Update(now)
        if not ctx.Active()or ctx.Busy()or now<nextSend or head>tail then return end
        local entry=queue[head]
        if now<entry.Ready then return end
        queue[head]=nil;head+=1;queued[entry.Item]=nil
        if head>tail then table.clear(queue);head,tail=1,0 end
        local item,rarity=entry.Item,entry.Rarity
        if not ctx.Selected(rarity)or ctx.Rarity(item)~=rarity or ctx.Protected(item)then return end
        -- Native Event has no response. Send once, never retry destruction blindly.
        nextSend=now+.4
        local ok,reason=pcall(ctx.Send,item)
        ctx.Status(ok and ("Dismantle requested · "..item.Name)or ("Dismantle failed · "..tostring(reason)))
    end
    function api.Clear()table.clear(queue);table.clear(queued);head,tail=1,0 end
    return api
end
