-- Crystal conversion is a transaction: input and output replication acknowledge it.
return function(ctx)
    local api={Paused=false}
    local transaction
    local eligibleAt=0
    local outputs={
        {"Legendary Upgrade Crystal","Rare Upgrade Crystal"},
        {"Rare Upgrade Crystal","Uncommon Upgrade Crystal"},
    }
    local function acknowledge(now)
        if not transaction then return true end
        local receipt=transaction
        local spent=ctx.Count(receipt.input)<=receipt.inputCount-receipt.quantity
        local produced=ctx.Count(receipt.output)>=receipt.outputCount+1
        if spent and produced then
            transaction=nil
            api.Paused=false
            eligibleAt=now+.2
            ctx.Status("Crystal crafted")
            return true
        end
        if now>=receipt.deadline then
            api.Paused=true
            ctx.Status("Craft not acknowledged · waiting without duplicate requests")
        end
        return false
    end
    function api.Reset()
        api.Paused=false
        eligibleAt=0
    end
    function api.Update(now)
        if not ctx.Active() or not acknowledge(now) then return end
        if api.Paused or ctx.Busy() or now<eligibleAt then return end
        eligibleAt=now+.5
        for index=1,#outputs do
            local output,input=outputs[index][1],outputs[index][2]
            if ctx.Selected(output) then
                local amount=ctx.Recipe(output,input)
                if type(amount)=="number" and amount>0 and amount%1==0 then
                    local count=ctx.Count(input)
                    if count>=amount then
                        transaction={input=input,output=output,quantity=amount,inputCount=count,
                            outputCount=ctx.Count(output),deadline=now+10}
                        local sent,reason=pcall(ctx.Send,output)
                        api.Paused=not sent
                        ctx.Status(sent and ("Crafting "..output)or ("Craft request failed · "..tostring(reason)))
                        return
                    end
                end
            end
        end
    end
    return api
end
