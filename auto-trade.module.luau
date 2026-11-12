-- Trade synchronization compares a desired offer with the replicated offer ledger.
return function(ctx)
    local limit,batchSize=400,8
    local api={}
    local session={trade=nil,request=nil,accepted=nil,receipt=nil,signature=nil,stableAt=0,action=nil}
    local rarities={Legendary=true,Tribute=true,Burst=true}
    function api.AlwaysInclude(name)
        return name=="Upgrade Protection Scroll"or name=="Resurrection Crystal"
    end
    function api.IncludesRarity(mode,rarity)
        return (mode=="Legendary"or mode=="Tribute")and rarities[rarity]==true
    end
    function api.MaxVel(balance)
        if type(balance)~="number"or balance~=balance or balance<=0 or balance==math.huge then return 0 end
        local taxable=math.min(110000000,math.floor(balance))
        return math.floor(taxable*10/11)
    end
    local function clear()
        session={trade=nil,request=nil,accepted=nil,receipt=nil,signature=nil,stableAt=0,action=nil}
    end
    function api.Event(kind,data)
        if not ctx.Active()then clear();return end
        if kind=="Request"then session.request=data;ctx.Status("Checking incoming trade request");return end
        if kind=="TradeCancel"or kind=="TradeCompleted"then clear();return end
        if kind=="RequestAccept"then session.receipt=nil;session.signature=nil;session.action=nil end
        if kind=="RequestAccept"or kind=="TradeChanged"then
            session.trade=data;session.request=nil;session.accepted=nil
        end
    end
    local function request()
        local requester=ctx.Pending and ctx.Pending()or (not ctx.Pending and session.request or nil)
        if not requester then session.accepted=nil;return end
        if not ctx.Allowed(requester)then ctx.Status("Trade request ignored · user is not whitelisted");return end
        if session.accepted~=requester then
            ctx.Send("RequestAccept",{})
            session.accepted=requester;session.request=nil
            ctx.Status("Accepted whitelisted trade request")
        end
    end
    local function offer(trade,role,peer,items,currency)
        local desired,actual,available={},{},{}
        local signature={tostring(currency)}
        for _,item in ipairs(items)do
            local amount=ctx.Count and ctx.Count(item)or 1
            if type(amount)~="number"or amount~=amount or amount==math.huge then amount=0 end
            amount=math.max(0,math.floor(amount))
            if amount>0 then available[item]=amount end
        end
        local total=0
        for _,side in ipairs({role,peer})do
            signature[#signature+1]=tostring(trade[side.."Currency"]or 0)
            for _,entry in ipairs(trade[side.."Items"]or {})do
                signature[#signature+1]=side..":"..tostring(entry.item and entry.item.Value)..":"..tostring(entry.count or 1)
                if side==role then
                    local amount=entry.count==nil and 1 or entry.count
                    if not entry.item or type(amount)~="number"or amount~=amount or amount<=0 or amount==math.huge or amount%1~=0 then
                        return nil,nil,nil,"Trade paused · invalid outgoing quantity"
                    end
                    actual[entry.item]=(actual[entry.item]or 0)+amount;total+=amount
                end
            end
        end
        if total>limit then return nil,nil,nil,"Trade paused · outgoing offer exceeds 400 items"end
        local remaining=limit
        -- Keep eligible units already offered, then fill spare slots in inventory order.
        for item,amount in pairs(actual)do
            if not available[item]or amount>available[item]then
                return nil,nil,nil,"Trade paused · offer exceeds selected quantity"
            end
            desired[item]=amount;remaining-=amount
        end
        for _,item in ipairs(items)do
            local have=desired[item]or 0
            local add=math.min(remaining,(available[item]or 0)-have)
            if add>0 then desired[item]=have+add;remaining-=add end
            signature[#signature+1]="want:"..item.Value..":"..tostring(desired[item]or 0)
        end
        return desired,actual,table.concat(signature,"|")
    end
    local function once(action,command,payload)
        if session.action==action then return end
        session.action=action
        ctx.Send(command,payload)
    end
    function api.Update(now)
        if not ctx.Active()then return false end
        request()
        local trade=session.trade
        if not trade then return false end
        local role=trade.Requester==ctx.Player and "Requester"or trade.Partner==ctx.Player and "Partner"
        if not role then return false end
        local peer=role=="Requester"and "Partner"or "Requester"
        if not ctx.Allowed(trade[peer])then ctx.Status("Trade paused · partner is not whitelisted");return false end
        local items,currency=ctx.Plan()
        local desired,actual,signature,problem=offer(trade,role,peer,items,currency)
        if not desired then ctx.Status(problem);return true end
        if session.signature~=signature then
            session.signature=signature;session.stableAt=now;session.action=nil
        end
        local receipt=session.receipt
        if receipt then
            for item,quantity in pairs(receipt.items)do
                if (actual[item]or 0)<quantity then
                    ctx.Status(now>=receipt.deadline and "Server has not acknowledged the batch · automatic acceptance paused"or "Waiting for trade items to register")
                    return true
                end
            end
            session.receipt=nil
        end
        local batch=0
        for _,item in ipairs(items)do
            local have,want=actual[item]or 0,desired[item]or 0
            if batch<batchSize and have<want then
                if not session.receipt then session.receipt={items={},deadline=now+10}end
                local pending=session.receipt.items[item]or have
                for _=1,math.min(batchSize-batch,want-pending)do
                    if not ctx.Active()or not ctx.Allowed(trade[peer])then return true end
                    pending+=1;batch+=1;session.receipt.items[item]=pending
                    ctx.Send("TradeAddItem",{item})
                end
            end
        end
        if batch>0 then ctx.Status("Adding trade items · batch "..batch.." · limit 400");return true end
        if (trade[role.."Currency"]or 0)~=currency then
            once("vel","TradeChangeCurrency",{currency});ctx.Status("Setting trade Vel");return true
        end
        if now-session.stableAt<2 then ctx.Status("Waiting for the trade offer to settle");return true end
        if trade[role.."Confirmed"]~=true then once("confirm","TradeConfirm",{})
        elseif trade[peer.."Confirmed"]==true and trade[role.."Accepted"]~=true then once("accept","TradeAccept",{})end
        ctx.Status("Trade offer ready · automatic confirmation active")
        return true
    end
    return api
end
