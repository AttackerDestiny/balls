-- A replacement is prepared completely before the current owner retires.
return function(ctx)
    local phase="Idle"
    local function failure(reason)
        phase="Idle"
        ctx.Status("Restart failed · try again")
        ctx.Error(tostring(reason))
    end
    return function()
        if phase~="Idle"then return end
        phase="Preparing";ctx.Status("Restarting...")
        ctx.Spawn(function()
            local ready,replacement=pcall(function()
                ctx.Save()
                local compiled=ctx.Compile(ctx.Fetch())
                assert(type(compiled)=="function","Loader did not compile")
                return compiled
            end)
            if not ready then failure(replacement);return end
            phase="Replacing"
            local complete,reason=pcall(function()ctx.Destroy();replacement()end)
            phase="Idle"
            if not complete then failure(reason)end
        end)
    end
end
