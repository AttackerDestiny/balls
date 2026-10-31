-- Engine-instance ownership works even when getgenv is isolated per execution.
return function(ctx)
    local retired,existing={},nil
    for _,gui in ipairs(ctx.Parent:GetChildren()) do
        if gui.Name=="SB2KillAuraUI" and gui:IsA("ScreenGui") then
            local heartbeat=gui:GetAttribute("SB2Heartbeat")
            local phase=gui:GetAttribute("SB2Phase")
            if not existing and gui:GetAttribute("SB2Build")==ctx.Build and gui:GetAttribute("SB2Job")==ctx.Job
                and (phase=="Loading" or phase=="Running") and type(heartbeat)=="number"
                and ctx.Now()-heartbeat<10 then existing=gui
            else retired[#retired+1]=gui end
        end
    end
    if existing then
        for _,gui in ipairs(retired) do gui:Destroy() end
        -- Repeated auto-execute is a no-op; do not turn a hidden panel back on.
        return nil,existing
    end
    local root=ctx.Create()
    root.Name="SB2KillAuraUI"
    root:SetAttribute("SB2Build",ctx.Build);root:SetAttribute("SB2Job",ctx.Job)
    root:SetAttribute("SB2Phase","Loading");root:SetAttribute("SB2Heartbeat",ctx.Now())
    root.Parent=ctx.Parent
    local lease={Root=root}
    local connection,lastPulse,disposed=nil,ctx.Now(),false
    function lease.Alive()return not disposed and root.Parent==ctx.Parent end
    function lease.Retire()
        for _,gui in ipairs(retired) do gui:Destroy() end
        retired={}
    end
    function lease.Ready()
        if lease.Alive()then root:SetAttribute("SB2Phase","Running")end
    end
    function lease.Release()
        if disposed then return end
        disposed=true
        if connection then connection:Disconnect()end
        root:SetAttribute("SB2Phase","Stopped")
    end
    connection=ctx.Pulse:Connect(function()
        if not lease.Alive()then lease.Release();return end
        local now=ctx.Now()
        if now-lastPulse>=2 then lastPulse=now;root:SetAttribute("SB2Heartbeat",now)end
    end)
    return lease
end
