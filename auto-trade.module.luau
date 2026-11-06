-- Trade synchronization compares a desired offer with the replicated offer ledger.
return function(ctx)
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
        local desired,actual={},{}
        local signature={tostring(currency)}
        for _,item in ipairs(items)do
            local amount=ctx.Count and ctx.Count(item)or 1
            if type(amount)~="number"or amount~=amount or amount==math.huge then amount=0 end
            amount=math.max(0,math.floor(amount))
            if amount>0 then desired[item]=amount end
            signature[#signature+1]="want:"..item.Value..":"..amount
        end
        for _,side in ipairs({role,peer})do
            signature[#signature+1]=tostring(trade[side.."Currency"]or 0)
            for _,entry in ipairs(trade[side.."Items"]or {})do
                signature[#signature+1]=side..":"..tostring(entry.item and entry.item.Value)..":"..tostring(entry.count or 1)
                if side==role and entry.item then actual[entry.item]=(actual[entry.item]or 0)+(entry.count or 1)end
            end
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
        local desired,actual,signature=offer(trade,role,peer,items,currency)
        if session.signature~=signature then
            session.signature=signature;session.stableAt=now;session.action=nil
        end
        for item,quantity in pairs(actual)do
            if not desired[item]or quantity>desired[item]then ctx.Status("Trade paused · offer exceeds selected quantity");return true end
        end
        local receipt=session.receipt
        if receipt then
            if (actual[receipt.item]or 0)<receipt.quantity then
                ctx.Status(now>=receipt.deadline and "Server has not acknowledged the batch · trade may be full · automatic acceptance paused"or "Waiting for stacked items to register")
                return true
            end
            session.receipt=nil
        end
        for _,item in ipairs(items)do
            local have,want=actual[item]or 0,desired[item]or 0
            if have<want then
                local batch=math.min(4,want-have)
                session.receipt={item=item,quantity=have+batch,deadline=now+10}
                for _=1,batch do ctx.Send("TradeAddItem",{item})end
                ctx.Status("Adding "..item.Name.." · "..have.."/"..want)
                return true
            end
        end
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
