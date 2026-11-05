-- Stop local animation playback without retaining tracks or destroying rigs.
return function(ctx)
    local api={Stopped=0}
    local enabled,disposed=false,false
    local added,removed
    local connections={}
    local function stop(track)
        if not enabled or disposed or ctx.State.StopEverything then return end
        local ok=pcall(function()track:Stop(0)end)
        if ok then api.Stopped+=1 end
    end
    local function attach(animator)
        if not enabled or not animator:IsA("Animator")or connections[animator]then return end
        connections[animator]=animator.AnimationPlayed:Connect(stop)
        for _,track in ipairs(animator:GetPlayingAnimationTracks())do stop(track)end
    end
    local function detach(animator)
        local connection=connections[animator]
        if connection then connection:Disconnect();connections[animator]=nil end
    end
    function api.Set(value)
        if disposed then return false end
        value=value==true
        if enabled==value then return true end
        enabled=value;ctx.State.RemovingAnimations=enabled
        if added then added:Disconnect();added=nil end
        if removed then removed:Disconnect();removed=nil end
        for animator in pairs(connections)do detach(animator)end
        if enabled then
            added=ctx.Root.DescendantAdded:Connect(attach)
            removed=ctx.Root.DescendantRemoving:Connect(detach)
            for _,animator in ipairs(ctx.Root:QueryDescendants("Animator"))do attach(animator)end
        end
        return true
    end
    function api.Destroy()
        if disposed then return end
        api.Set(false);disposed=true
    end
    return api
end
