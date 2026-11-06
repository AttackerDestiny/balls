-- Interpose one native report method; never replace global remote dispatch.
return function(context)
    local protection={Blocked=0}
    local state=context.State
    local native=context.Native
    local active,closed=false,false
    local token
    local function release()
        local hook=token;token=nil
        if hook and native.DamageLocalPlayer==hook.Wrapper then native.DamageLocalPlayer=hook.Original end
    end
    function protection.Set(requested)
        if closed then return false end
        requested=requested==true
        if not requested then release()
        elseif not token or native.DamageLocalPlayer~=token.Wrapper then
            local original=native.DamageLocalPlayer
            if type(original)~="function"then state.LastSelfDamageProtectionError="Native DamageSelf entry point unavailable";return false end
            local wrapper=function(...)
                if active and not closed and state and state.Running and not state.StopEverything then protection.Blocked+=1;return end
                return original(...)
            end
            token={Original=original,Wrapper=wrapper};native.DamageLocalPlayer=wrapper
        end
        active=requested;state.NoSelfDamage=requested
        return true
    end
    function protection.Destroy()
        if closed then return end
        closed=true;active=false;release();state=nil;context.State=nil
    end
    return protection
end
