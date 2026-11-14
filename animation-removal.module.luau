-- Animator subscriptions are scoped to one enabled session and never retain tracks.
return function(ctx)
    local api={Stopped=0}
    local session=nil
    local closed=false
    local function playerAnimation(animator)
        local node=animator.Parent
        local character=false
        while node and node~=ctx.Root do
            if node.Name=="Mobs"then return false end
            if node:IsA("Model")then
                local owner=ctx.Players:GetPlayerFromCharacter(node)
                if node:FindFirstChild("Entity")and not owner then return false end
                if owner then character=true end
            end
            node=node.Parent
        end
        return node==ctx.Root and character
    end
    local function stop(animator,track)
        if closed or not session or ctx.State.StopEverything then return end
        if not playerAnimation(animator)then return end
        if pcall(function()track:Stop(0)end)then api.Stopped+=1 end
    end
    local function forget(animator)
        if not session then return end
        local connection=session.Animators[animator]
        if connection then connection:Disconnect();session.Animators[animator]=nil end
    end
    local function watch(animator)
        if not session or not animator:IsA("Animator")or session.Animators[animator]or not playerAnimation(animator)then return end
        session.Animators[animator]=animator.AnimationPlayed:Connect(function(track)stop(animator,track)end)
        for _,track in ipairs(animator:GetPlayingAnimationTracks())do stop(animator,track)end
    end
    local function release()
        if not session then return end
        for _,connection in ipairs(session.Roots)do connection:Disconnect()end
        for animator in pairs(session.Animators)do forget(animator)end
        session=nil
    end
    function api.Set(enabled)
        if closed then return false end
        enabled=enabled==true
        if enabled==(session~=nil)then return true end
        release();ctx.State.RemovingAnimations=enabled
        if enabled then
            session={Animators={},Roots={}}
            session.Roots[1]=ctx.Root.DescendantAdded:Connect(watch)
            session.Roots[2]=ctx.Root.DescendantRemoving:Connect(forget)
            for _,animator in ipairs(ctx.Root:QueryDescendants("Animator"))do watch(animator)end
        end
        return true
    end
    function api.Destroy()
        if closed then return end
        api.Set(false);closed=true
    end
    return api
end
