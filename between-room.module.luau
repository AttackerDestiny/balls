-- Native room setup is a receipt-driven transaction with a single start dispatch.
return function(ctx)
    local api={}
    local phase="Setup"
    local waiting,completedRoom
    local attempts=0
    local function stop(message)phase="Stopped";ctx.Status(message)end
    function api.Reset()phase="Setup";waiting=nil;attempts=0 end
    local function dispatch(action,field,room,now)
        attempts+=1
        if attempts>8 then stop("Room settings could not be applied. Check the native party menu.");return end
        waiting={Field=field,Before=room and room[field],Until=now+5}
        ctx.Status(room and "Configuring The Between"or "Creating The Between room")
        ctx.Send(action)
    end
    function api.Update(now)
        if phase~="Setup"or not ctx.Active()then return end
        local room=ctx.Read()
        if waiting then
            local changed=waiting.Field=="Id"and room or room and room[waiting.Field]~=waiting.Before
            if changed then waiting=nil
            elseif now>=waiting.Until then stop("Room request timed out. Toggle Auto Create Room to retry.");return
            else return end
        end
        if room then
            if not(room.Id and room.Host~=nil and room.PlaceId~=nil)then ctx.Status("Waiting for party details");return end
            if room.Host~=ctx.UserId or room.PlaceId~=ctx.PlaceId then ctx.Status("Leave your current party to create a Between room");return end
            if room.Id==completedRoom or not(room.Status and room.Mode)then return end
        end
        local access,difficulty=ctx.Selection()
        if not room then attempts=0;dispatch("CreateParty","Id",nil,now);return end
        if room.Mode~=difficulty then dispatch("ToggleMode","Mode",room,now);return end
        if room.Status~=access then dispatch("ToggleStatus","Status",room,now);return end
        phase="Starting";ctx.Status("Starting The Between · "..access.." · "..difficulty)
        ctx.Spawn(function()
            local ok,accepted=pcall(ctx.Start)
            if ok and accepted==true then completedRoom=room.Id;phase="Stopped";if ctx.Active()then ctx.Status("Start accepted · waiting for teleport")end
            elseif ctx.Active()then stop("Start failed. Check the native party menu and toggle Auto Create Room to retry.")
            else phase="Stopped"end
        end)
    end
    return api
end
