-- A receipt is never retried: native item destruction has no request acknowledgment.
return function(ctx)
    local api={}
    local rarities={Common=true,Uncommon=true,Rare=true}
    local fifo={}
    local membership=setmetatable({}, {__mode="k"})
    local attempted=setmetatable({}, {__mode="k"})
    local cursor,tail=1,0
    local inventory,inventoryCursor,inventoryTime
    local cooldown=0
    function api.Add(item,now)
        if membership[item] or attempted[item] then return end
        local rarity=ctx.Rarity(item)
        if rarities[rarity] and ctx.Selected(rarity) then
            tail=tail+1
            fifo[tail]={item=item,rarity=rarity,due=now+.75}
            membership[item]=true
        end
    end
    function api.Scan(items,now)
        inventory,inventoryCursor,inventoryTime=items,1,now
    end
    local function processInventory()
        if not inventory then return end
        local last=math.min(#inventory,inventoryCursor+31)
        while inventoryCursor<=last do
            api.Add(inventory[inventoryCursor],inventoryTime)
            inventoryCursor=inventoryCursor+1
        end
        if inventoryCursor>#inventory then inventory=nil end
    end
    local function take(now)
        local entry=fifo[cursor]
        if not entry or now<entry.due then return nil end
        fifo[cursor]=nil
        cursor=cursor+1
        membership[entry.item]=nil
        if cursor>tail then fifo={};cursor,tail=1,0 end
        return entry
    end
    function api.Update(now)
        if not ctx.Active() or ctx.Busy() then return end
        processInventory()
        if now<cooldown then return end
        local entry=take(now)
        if not entry then return end
        local item=entry.item
        if not ctx.Selected(entry.rarity) or ctx.Rarity(item)~=entry.rarity or ctx.Protected(item) then return end
        attempted[item]=true
        cooldown=now+.4
        local sent,reason=pcall(ctx.Send,item)
        ctx.Status(sent and ("Dismantle requested · "..item.Name)or ("Dismantle failed · "..tostring(reason)))
    end
    function api.Clear()
        fifo={};cursor,tail=1,0;inventory=nil;inventoryCursor=nil
        table.clear(membership);table.clear(attempted)
    end
    return api
end
