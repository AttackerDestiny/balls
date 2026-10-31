-- Resume builds a fresh runtime after resources were released. Keep the old
-- state paused so deferred work from that runtime cannot restart itself.
return function(ctx)
    local state=ctx.State
    local api={}
    function api.Set(enabled)
        enabled=enabled==true
        if enabled==state.StopEverything then return true end
        if enabled then
            state.ResumeFeatures=ctx.Capture()
            state.StopEverything=true
            state.ResumeRequested=false
            ctx.Stop()
            ctx.Render()
            ctx.Save()
            return true
        end
        local ok,resume=pcall(ctx.LoadResume)
        if not ok or type(resume)~="function" then
            state.LastPauseError=tostring(resume or "Saved script is unavailable")
            ctx.Render()
            return false,state.LastPauseError
        end
        state.ResumeRequested=true
        ctx.Save()
        local resumed,message=pcall(resume)
        if not resumed then
            state.ResumeRequested=false
            state.LastPauseError=tostring(message)
            ctx.Save()
            ctx.Render()
            return false,state.LastPauseError
        end
        return true
    end
    return api
end
