-- Native room setup is a receipt-driven transaction with a single start dispatch.
return function(ctx)
    local api={}
    local phase="Setup"
    local waiting,completedRoom
    local attempts=0
    local joinRoom,joinStatus,joinAttempts,nextJoin
    local starting=false
    local function stop(message)phase="Stopped";ctx.Status(message)end
    function api.Reset()
        phase="Setup";waiting=nil;attempts=0
        joinRoom,joinStatus,joinAttempts,nextJoin=nil,nil,0,0
    end
    local function dispatch(action,field,room,now)
        attempts+=1
        if attempts>8 then stop("Room settings could not be applied. Check the native party menu.");return end
        waiting={Field=field,Before=room and room[field],Until=now+5}
        ctx.Status(room and "Configuring The Between"or "Creating The Between room")
        ctx.Send(action)
    end
    function api.Update(now)
        if phase~="Setup"or starting or not ctx.Active()then return end
        local room=ctx.Read()
        local assignment=ctx.Assignment and ctx.Assignment()
        if assignment and assignment.Role=="Alt" then
            local hostRoom=ctx.FindHostRoom(assignment.Host)
            if room then
                ctx.Status(hostRoom and room.Id==hostRoom.Id and "Joined host · waiting for the party"
                    or "Leave your current party to join "..assignment.Host)
            elseif not hostRoom then
                ctx.Status("Waiting for host "..assignment.Host.." in this server")
            elseif hostRoom.Status and hostRoom.Status~="Public" then
                if joinRoom~=hostRoom.Id or joinStatus~=hostRoom.Status then
                    joinRoom,joinStatus,joinAttempts,nextJoin=hostRoom.Id,hostRoom.Status,0,0
                end
                if joinAttempts>=3 then
                    ctx.Status("Could not join the host. Check room access and toggle Auto Create to retry.")
                elseif now>=nextJoin then
                    joinAttempts+=1;nextJoin=now+3
                    ctx.Status("Joining "..assignment.Host)
                    ctx.Send("JoinParty",hostRoom.Id)
                end
            end
            return
        elseif assignment and assignment.Role~="Host" then
            ctx.Status(assignment.Message or "Set a Host and Alt assignment for this account")
            return
        end
        if waiting then
            local changed=waiting.Field=="Id"and room or room and room[waiting.Field]~=waiting.Before
            if changed then waiting=nil
            elseif now>=waiting.Until then stop("Room request timed out. Toggle Auto Create to retry.");return
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
        local missing=assignment and ctx.MissingAlts(room,assignment.Alts)
        if missing and #missing>0 then
            ctx.Status("Waiting for Alt: "..table.concat(missing,", "))
            return
        end
        starting=true
        phase="Starting";ctx.Status("Starting The Between · "..access.." · "..difficulty)
        ctx.Spawn(function()
            if ctx.PrepareStart then ctx.PrepareStart() end
            local current=ctx.Read()
            local selected=ctx.Assignment and ctx.Assignment()
            local desiredAccess,desiredMode=ctx.Selection()
            if not ctx.Active() or not current or current.Id~=room.Id or current.Host~=ctx.UserId
                or current.PlaceId~=ctx.PlaceId or current.Status~=desiredAccess or current.Mode~=desiredMode
                or selected and (selected.Role~="Host" or #ctx.MissingAlts(current,selected.Alts)>0) then
                starting=false;phase="Setup"
                return
            end
            local ok,accepted=pcall(ctx.Start)
            starting=false
            if ok and accepted==true then completedRoom=room.Id;phase="Stopped";if ctx.Active()then ctx.Status("Start accepted · waiting for teleport")end
            elseif ctx.Active()then stop("Start failed. Check the native party menu and toggle Auto Create to retry.")
            else phase="Stopped"end
        end)
    end
    return api
end
