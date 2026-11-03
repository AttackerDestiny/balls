-- Status only; no gameplay work or world scans.
return function(ctx)
    local disposed,nextUpdate=false,0
    local api={}
    function api.Update(now)
        if disposed or now<nextUpdate then return end
        nextUpdate=now+.2
        local visible=ctx.State.Running and ctx.State.MultiSpot==true
        ctx.Visible(visible==true)
        if visible then ctx.Text(ctx.State.MultiSpotStatus or "Starting arena rotation...")end
    end
    local connection=ctx.Pulse:Connect(function()api.Update(ctx.Now())end)
    function api.Destroy()
        if disposed then return end
        disposed=true;connection:Disconnect();ctx.Destroy()
    end
    api.Update(ctx.Now())
    return api
end
