-- A passive HUD projection never owns world state or movement.
return function(ctx)
    local nextPaint=0
    local alive=true
    local api={}
    function api.Update(stamp)
        if not alive or stamp<nextPaint then return end
        nextPaint=stamp+.2
        local show=ctx.State.Running==true and ctx.State.MultiSpot==true
        ctx.Visible(show)
        if show then ctx.Text(ctx.State.MultiSpotStatus or "Starting arena rotation...")end
    end
    local subscription=ctx.Pulse:Connect(function()api.Update(ctx.Now())end)
    function api.Destroy()
        if not alive then return end
        alive=false
        subscription:Disconnect();subscription=nil
        ctx.Destroy()
    end
    api.Update(ctx.Now())
    return api
end
