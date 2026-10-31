-- Bounded login-screen helper; no frame connection or floor-runtime polling.
return function(ctx)
    local api={Attempts=0,Done=false}
    local deadline,nextTry,queued=ctx.Now()+60,0,false
    function api.Update()
        if api.Done then return end
        local now=ctx.Now()
        if not ctx.Alive() or now>=deadline then api.Done=true;return end
        local button=ctx.Find()
        if not button or not ctx.Ready(button) then
            if api.Attempts>0 then api.Done=true end
            return
        end
        if now<nextTry then return end
        nextTry=now+1
        if not queued then
            local ok,err=pcall(ctx.Queue)
            if not ok then api.Error=tostring(err);api.Done=true;return end
            queued=true
        end
        local ok,err=pcall(ctx.Activate,button)
        if not ok then api.Error=tostring(err);api.Done=true;return end
        if err~=false then api.Attempts+=1 end
    end
    return api
end
