return function(moduleSource)
    local create=assert(loadstring(moduleSource))()
    local state={StopEverything=false,Enabled=true,AutoFarm=true,SkillAura=false,AutoDodge=false}
    local calls={Stopped=0,Resumed=0,Saved=0}
    local canLoad=true
    local api=create({State=state,
        Capture=function() return {Enabled=state.Enabled,AutoFarm=state.AutoFarm,SkillAura=state.SkillAura,AutoDodge=state.AutoDodge} end,
        Stop=function() calls.Stopped+=1; state.Enabled=false; state.AutoFarm=false end,
        Render=function() end,Save=function() calls.Saved+=1 end,
        LoadResume=function()
            if not canLoad then error("Missing source") end
            return function() calls.Resumed+=1 end
        end,
    })
    assert(api.Set(true) and state.StopEverything and not state.Enabled and not state.AutoFarm,"Pause must stop work immediately")
    assert(state.ResumeFeatures.Enabled and state.ResumeFeatures.AutoFarm,"Remember enabled features")
    assert(state.ResumeFeatures.SkillAura==false and state.ResumeFeatures.AutoDodge==false,"Do not enable features that were off")
    api.Set(true)
    assert(calls.Stopped==1 and state.ResumeFeatures.Enabled,"Repeated pause must not overwrite the snapshot")
    canLoad=false
    assert(not api.Set(false) and state.StopEverything and not state.ResumeRequested,"A missing resume source must leave everything paused")
    canLoad=true
    assert(api.Set(false) and calls.Resumed==1 and state.ResumeRequested,"Resume must launch the saved runtime")
    assert(state.StopEverything,"Old deferred workers must remain paused while the replacement starts")
    return {Passed=true,FalsePreferencesPreserved=true,Idempotent=true,SafeResumeFailure=true}
end
