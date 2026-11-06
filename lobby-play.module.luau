-- Observe readiness, queue recovery once, then pace attempts until the menu leaves.
return function(ctx)
    local api={Attempts=0,Done=false}
    local expires=ctx.Now()+60
    local nextActivation=0
    local prepared=false
    local function call(fn,...)
        local ok,result=pcall(fn,...)
        if not ok then api.Error=tostring(result);api.Done=true end
        return ok,result
    end
    function api.Update()
        if api.Done then return end
        local now=ctx.Now()
        if now>=expires or not ctx.Alive() then api.Done=true;return end
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
