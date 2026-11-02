return function(ctx)
    local api={}
    local highRarities={Legendary=true,Tribute=true,Burst=true}
    function api.IncludesRarity(mode,rarity)
        return (mode=="Legendary"or mode=="Tribute")and highRarities[rarity]==true
    end
    function api.MaxVel(balance)
        if type(balance)~="number"or balance~=balance or balance==math.huge or balance<=0 then return 0 end
        -- Clamp before multiplying: avoids float division by 1.1 rounding exact
        -- balances down (e.g. 660000 must permit an offer of 600000).
        return math.floor(math.min(math.floor(balance),110000000)*10/11)
    end
    local trade,lastSignature,stableSince,lastAction=nil,nil,0,nil
    local pending,acceptedRequest,pendingAdd
    function api.Event(kind,data)
        if not ctx.Active()then trade=nil;return end
        if kind=="Request"then
            pending=data
            ctx.Status("Checking incoming trade request")
        elseif kind=="TradeChanged"or kind=="RequestAccept"then
            if kind=="RequestAccept"then pendingAdd=nil;lastSignature=nil;lastAction=nil end
            trade=data;pending=nil;acceptedRequest=nil
        elseif kind=="TradeCancel"or kind=="TradeCompleted"then trade=nil;pending=nil;acceptedRequest=nil;pendingAdd=nil;lastSignature=nil;lastAction=nil end
    end
    function api.Update(now)
        if not ctx.Active()then return false end
        local requester=ctx.Pending and ctx.Pending()or (not ctx.Pending and pending or nil)
        if not requester then acceptedRequest=nil
        elseif not ctx.Allowed(requester)then ctx.Status("Trade request ignored · user is not whitelisted")
        elseif requester~=acceptedRequest then
            ctx.Send("RequestAccept",{});acceptedRequest=requester;pending=nil
            ctx.Status("Accepted whitelisted trade request")
        end
        if not trade then return false end
        local role=trade.Requester==ctx.Player and "Requester"or trade.Partner==ctx.Player and "Partner"
        if not role then return false end
        local peer=role=="Requester"and "Partner"or "Requester"
        if not ctx.Allowed(trade[peer])then ctx.Status("Trade paused · partner is not whitelisted");return false end
        local desired,vel=ctx.Plan()
        local ours=trade[role.."Items"]or{}
        local have,wanted={},{}
        local signature={tostring(vel)}
        for _,item in ipairs(desired)do
            local count=ctx.Count and ctx.Count(item)or 1
            count=type(count)=="number"and count==count and count~=math.huge and math.max(0,math.floor(count))or 0
            local amount=count
            if amount>0 then wanted[item]=amount end
            signature[#signature+1]="want:"..item.Value..":"..amount
        end
        for _,side in ipairs({role,peer})do
            signature[#signature+1]=tostring(trade[side.."Currency"]or 0)
            for _,v in ipairs(trade[side.."Items"]or{})do
                local item=v.item
                signature[#signature+1]=side..":"..tostring(item and item.Value)..":"..tostring(v.count or 1)
            end
        end
        local key=table.concat(signature,"|")
        if key~=lastSignature then lastSignature=key;stableSince=now;lastAction=nil end
        for _,v in ipairs(ours)do if v.item then have[v.item]=(have[v.item]or 0)+(v.count or 1)end end
        for item,count in pairs(have)do
            if not wanted[item]or count>wanted[item]then ctx.Status("Trade paused · offer exceeds selected quantity");return true end
        end
        if pendingAdd then
            if (have[pendingAdd.Item]or 0)<pendingAdd.Expected then
                ctx.Status(now-pendingAdd.At>=10 and "Server has not acknowledged the batch · trade may be full · automatic acceptance paused"or "Waiting for stacked items to register");return true
            end
            pendingAdd=nil
        end
        for _,item in ipairs(desired)do
            local current=have[item]or 0
            local amount=wanted[item]or 0
            if current<amount then
                local batch=math.min(4,amount-current)
                pendingAdd={Item=item,Expected=current+batch,At=now}
                for _=1,batch do ctx.Send("TradeAddItem",{item})end
                ctx.Status("Adding "..item.Name.." · "..current.."/"..amount);return true
            end
        end
        if (trade[role.."Currency"]or 0)~=vel then
            if lastAction~="vel"then lastAction="vel";ctx.Send("TradeChangeCurrency",{vel})end
            ctx.Status("Setting trade Vel");return true
        end
        if now-stableSince<2 then ctx.Status("Waiting for the trade offer to settle");return true end
        if trade[role.."Confirmed"]~=true then
            if lastAction~="confirm"then lastAction="confirm";ctx.Send("TradeConfirm",{})end
        elseif trade[peer.."Confirmed"]==true and trade[role.."Accepted"]~=true then
            if lastAction~="accept"then lastAction="accept";ctx.Send("TradeAccept",{})end
        end
        ctx.Status("Trade offer ready · automatic confirmation active")
        return true
    end
    return api
end
