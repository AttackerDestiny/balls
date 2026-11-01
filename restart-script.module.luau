return function(ctx)
    local busy=false
    return function()
        if busy then return end
        busy=true;ctx.Status("Restarting...")
        ctx.Spawn(function()
            local ok,reason=pcall(function()
                ctx.Save()
                -- Download and compile before retiring the current runtime.
                local run=ctx.Compile(ctx.Fetch())
                assert(type(run)=="function","Loader did not compile")
                ctx.Destroy()
                run()
            end)
            busy=false
            if not ok then ctx.Status("Restart failed · try again");ctx.Error(tostring(reason))end
        end)
    end
end
