-- Own the native enemy-skill reporting entry point; do not hook arbitrary remotes.
return function(ctx)
    local api={Blocked=0}
    local state=ctx.State
    local native=ctx.Native
    local owned,previous
    local enabled,disposed=false,false
    local function restore()
        if owned and native.DamageLocalPlayer==owned then native.DamageLocalPlayer=previous end
        owned=nil
    end
    function api.Set(value)
        if disposed then return false end
        value=value==true
        if value then
            if not owned or native.DamageLocalPlayer~=owned then
                local original=native.DamageLocalPlayer
                if type(original)~="function"then state.LastSelfDamageProtectionError="Native DamageSelf entry point unavailable";return false end
                previous=original
                owned=function(...)
                    if enabled and not disposed and state and state.Running and not state.StopEverything then
                        api.Blocked+=1
                        return
                    end
                    return original(...)
                end
                native.DamageLocalPlayer=owned
            end
        else restore()end
        enabled=value;state.NoSelfDamage=value
        return true
    end
    function api.Destroy()
        if disposed then return end
        enabled=false;disposed=true;restore()
        state=nil;ctx.State=nil
    end
    return api
end
