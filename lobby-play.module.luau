-- Observe readiness, queue recovery once, then pace attempts until the menu leaves.
return function(ctx)
    local api={Attempts=0,Done=false,RestRemaining=0}
    local expires=ctx.Now()+60
    local nextActivation=0
    local prepared=false
    local held=false
    local function call(fn,...)
        local ok,result=pcall(fn,...)
        if not ok then api.Error=tostring(result);api.Done=true end
        return ok,result
    end
    function api.Update()
        if api.Done then return end
        local now=ctx.Now()
        if not ctx.Alive()then api.Done=true;return end
        if ctx.Hold then
            local ok,remaining=call(function()
                local value=ctx.Hold()
                assert(value==nil or type(value)=="number"and value==value and math.abs(value)<math.huge,
                    "Menu rest duration is unavailable")
                return math.max(0,value or 0)
            end)
            if not ok then return end
            api.RestRemaining=remaining
            if remaining>0 then held=true;return end
        end
        if held then held=false;expires=now+60 end
        if now>=expires then api.Done=true;return end
        local button=ctx.Find()
        if not button or not ctx.Ready(button) then
            api.Done=api.Attempts>0
            return
        end
        if now<nextActivation then return end
        nextActivation=now+1
        if not prepared then
            if not call(ctx.Queue) then return end
            prepared=true
        end
        local ok,activated=call(ctx.Activate,button)
        if ok and activated~=false then api.Attempts=api.Attempts+1 end
    end
    return api
end
