-- GUI ownership is shared across executor environments through instance attributes.
return function(context)
    local rootName="SB2KillAuraUI"
    local obsolete={}
    local incumbent
    local timestamp=context.Now()
    local function fresh(candidate)
        local phase=candidate:GetAttribute("SB2Phase")
        local heartbeat=candidate:GetAttribute("SB2Heartbeat")
        return candidate:GetAttribute("SB2Build")==context.Build
            and candidate:GetAttribute("SB2Job")==context.Job
            and (phase=="Loading"or phase=="Running")
            and type(heartbeat)=="number"and timestamp-heartbeat<10
    end
    for _,candidate in ipairs(context.Parent:GetChildren())do
        if candidate.Name==rootName and candidate:IsA("ScreenGui")then
            if incumbent==nil and fresh(candidate)then incumbent=candidate
            else obsolete[#obsolete+1]=candidate end
        end
    end
    local function discardObsolete()
        for index=#obsolete,1,-1 do local candidate=obsolete[index];obsolete[index]=nil;pcall(function()candidate:Destroy()end)end
    end
    if incumbent then discardObsolete();return nil,incumbent end
    local root=context.Create();root.Name=rootName
    for name,value in pairs({SB2Build=context.Build,SB2Job=context.Job,SB2Phase="Loading",SB2Heartbeat=timestamp})do
        root:SetAttribute(name,value)
    end
    root.Parent=context.Parent
    local lease={Root=root}
    local released=false
    local pulse
    local due=timestamp+2
    function lease.Alive()return not released and root.Parent==context.Parent end
    lease.Retire=discardObsolete
    function lease.Ready()if lease.Alive()then root:SetAttribute("SB2Phase","Running")end end
    function lease.Release()
        if released then return end
        released=true
        if pulse then pulse:Disconnect();pulse=nil end
        pcall(function()root:SetAttribute("SB2Phase","Stopped")end)
    end
    pulse=context.Pulse:Connect(function()
        if released then return end
        if root.Parent~=context.Parent then lease.Release();return end
        local now=context.Now()
        if now>=due then due=now+2;root:SetAttribute("SB2Heartbeat",now)end
    end)
    return lease
end
