-- Pause captures resumable settings; resume always constructs a new runtime.
return function(ctx)
    local state=ctx.State
    local function present()ctx.Render();ctx.Save()end
    local function rejected(reason)
        state.ResumeRequested=false
        state.LastPauseError=tostring(reason)
        present()
        return false,state.LastPauseError
    end
    local function pause()
        state.ResumeFeatures=ctx.Capture()
        state.StopEverything=true;state.ResumeRequested=false
        ctx.Stop();present()
        return true
    end
    local function resume()
        local available,launch=pcall(ctx.LoadResume)
        if not available or type(launch)~="function"then
            state.LastPauseError=tostring(launch or "Saved script is unavailable")
            ctx.Render()
            return false,state.LastPauseError
        end
        state.ResumeRequested=true;ctx.Save()
        local launched,reason=pcall(launch)
        if not launched then return rejected(reason)end
        return true
    end
    return {Set=function(enabled)
        local requested=enabled==true
        if requested==state.StopEverything then return true end
        if requested then return pause()end
        return resume()
    end}
end
