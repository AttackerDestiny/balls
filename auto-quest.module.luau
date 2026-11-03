-- Native completion list only. No progress writes or incomplete-quest requests.
return function(ctx)
    local api={Claims=0}
    local sent=setmetatable({}, {__mode="k"})
    local nextUpdate=0
    function api.Update(now)
        if not ctx.Active()or now<nextUpdate then return end
        nextUpdate=now+.5
        local ready=ctx.Ready()
        local present={}
        for _,quest in ipairs(ready)do present[quest]=true end
        for quest in pairs(sent)do if not present[quest]then sent[quest]=nil end end
        if ctx.Busy()then return end
        for _,quest in ipairs(ready)do
            local record=sent[quest]
            if (not record or record.Attempts<3 and now>=record.Next)and ctx.Valid(quest)then
                record=record or {Attempts=0}
                record.Attempts+=1;record.Next=now+10*record.Attempts;sent[quest]=record
                local ok,reason=pcall(ctx.Claim,quest)
                if ok then api.Claims+=1 else api.Error=tostring(reason)end
                return -- At most one native request per half-second update.
            end
        end
    end
    return api
end
