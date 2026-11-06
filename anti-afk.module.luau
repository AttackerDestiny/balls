-- Idle events acquire a short pulse lease; no polling worker is created.
return function(ctx)
    local result={Enabled=true,Pulses=0}
    local lease={Running=false,Due=0,Closed=false}
    local clock=ctx.Clock or os.clock
    local state=ctx.State
    state.AntiAfkStatus="Active · waiting for idle"
    local function onIdle()
        local stamp=clock()
        if lease.Closed or lease.Running or state.Running==false or stamp<lease.Due then return end
        lease.Running=true;lease.Due=stamp+20
        local success,reason=pcall(ctx.Pulse)
        lease.Running=false
        if lease.Closed or state.Running==false then return end
        if success then
            result.Pulses+=1
            state.LastAntiAfkError=nil
            state.AntiAfkStatus="Active · idle input sent"
        else
            state.LastAntiAfkError=tostring(reason)
            state.AntiAfkStatus="Idle input unavailable · retrying on next idle event"
        end
    end
    local subscription=ctx.Player.Idled:Connect(onIdle)
    function result.Destroy()
        if lease.Closed then return end
        lease.Closed=true;result.Enabled=false
        subscription:Disconnect();subscription=nil
        state.AntiAfkStatus="Stopped"
    end
    return result
end
