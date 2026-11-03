-- One idle listener, no polling loop, movement or combat remote requests.
return function(ctx)
    local api={Enabled=true,Pulses=0}
    local state=ctx.State
    local stopped,busy=false,false
    local nextPulse=0
    local clock=ctx.Clock or os.clock
    state.AntiAfkStatus="Active · waiting for idle"
    local connection=ctx.Player.Idled:Connect(function()
        if stopped or busy or state.Running==false or clock()<nextPulse then return end
        busy=true;nextPulse=clock()+20
        local ok,message=pcall(ctx.Pulse)
        busy=false
        if stopped or state.Running==false then return end
        if ok then
            api.Pulses+=1;state.LastAntiAfkError=nil
            state.AntiAfkStatus="Active · idle input sent"
        else
            state.LastAntiAfkError=tostring(message)
            state.AntiAfkStatus="Idle input unavailable · retrying on next idle event"
        end
    end)
    function api.Destroy()
        if stopped then return end
        stopped=true;api.Enabled=false;connection:Disconnect()
        state.AntiAfkStatus="Stopped"
    end
    return api
end
