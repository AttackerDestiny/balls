-- Native room setup is a receipt-driven transaction with a single start dispatch.
return function(ctx)
    local api={}
    local phase="Setup"
    local waiting,completedRoom
    local attempts=0
    local joinRoom,nextJoin,preparedRoom
    local teleportAt
    local retryAt=0
    local starting=false
    local revision=0
    local function stop(message)phase="Stopped";ctx.Status(message)end
    local function retry(message,now)
        if not ctx.InBetween then stop(message.." Toggle Start to retry.");return end
        waiting=nil;attempts=0;phase="Setup";retryAt=now+2
        ctx.Status(message.." Retrying in The Between.")
    end
    function api.Reset()
        revision+=1
        phase="Setup";waiting=nil;attempts=0
        joinRoom,nextJoin,preparedRoom=nil,0,nil;retryAt=0
    end
    local function dispatch(action,field,room,now)
        attempts+=1
        if attempts>8 then retry("Room settings could not be applied.",now);return end
        waiting={Field=field,Before=room and room[field],Until=now+5}
        ctx.Status(room and "Configuring The Between"or "Creating The Between room")
        ctx.Send(action)
    end
    function api.Update(now)
        if phase=="AwaitingTeleport" and now>=teleportAt and ctx.Active()then
            completedRoom=nil;retry("Start was accepted but teleport did not finish.",now)
        end
        if phase~="Setup"or starting or now<retryAt or not ctx.Active()then return end
        local room=ctx.Read()
        local assignment=ctx.Assignment and ctx.Assignment()
        local access,difficulty=ctx.Selection()
        if assignment and assignment.Role=="Alt" then
            local hostRoom=ctx.FindHostRoom(assignment.Host)
            local sameParty=hostRoom and room and room.Id==hostRoom.Id
            local joined=sameParty and (not ctx.HasJoined or ctx.HasJoined(hostRoom))
            local canJoin=hostRoom and (not room or (ctx.InBetween and room.Host==hostRoom.Host and room.PlaceId==ctx.PlaceId))
            if (joined or canJoin) and preparedRoom~=hostRoom.Id then
                preparedRoom=hostRoom.Id
                if ctx.PrepareJoin then ctx.PrepareJoin()end
            end
            if not hostRoom then
                ctx.Status("Waiting for host "..assignment.Host.." in this server")
            elseif joined then
                ctx.Status("Joined host · waiting for the party")
            elseif not canJoin then
                ctx.Status("Leave your current party to join "..assignment.Host)
            elseif (ctx.InBetween and hostRoom.Status and hostRoom.Mode) or (hostRoom.Status==access and hostRoom.Mode==difficulty)then
                if joinRoom~=hostRoom.Id then joinRoom,nextJoin=hostRoom.Id,0 end
                if now>=nextJoin then
                    nextJoin=now+3
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
            elseif now>=waiting.Until then retry("Room request timed out.",now);return
            else return end
        end
        if room then
            if not(room.Id and room.Host~=nil and room.PlaceId~=nil)then ctx.Status("Waiting for party details");return end
            if room.Host~=ctx.UserId or room.PlaceId~=ctx.PlaceId then ctx.Status("Leave your current party to create a Between room");return end
            if room.Id==completedRoom or not(room.Status and room.Mode)then return end
        end
        if not room then attempts=0;dispatch("CreateParty","Id",nil,now);return end
        if room.Mode~=difficulty then dispatch("ToggleMode","Mode",room,now);return end
        if room.Status~=access then dispatch("ToggleStatus","Status",room,now);return end
        local missing=assignment and ctx.MissingAlts(room,assignment.Alts)
        if missing and #missing>0 then
            ctx.Status("Waiting for Alt: "..table.concat(missing,", "))
            return
        end
        starting=true
        local requestRevision=revision
        phase="Starting";ctx.Status("Starting The Between · "..access.." · "..difficulty)
        ctx.Spawn(function()
            if ctx.PrepareStart then ctx.PrepareStart() end
            local current=ctx.Read()
            local selected=ctx.Assignment and ctx.Assignment()
            local desiredAccess,desiredMode=ctx.Selection()
            if requestRevision~=revision or not ctx.Active() or not current or current.Id~=room.Id or current.Host~=ctx.UserId
                or current.PlaceId~=ctx.PlaceId or current.Status~=desiredAccess or current.Mode~=desiredMode
                or selected and (selected.Role~="Host" or #ctx.MissingAlts(current,selected.Alts)>0) then
                starting=false;phase="Setup"
                return
            end
            local ok,accepted=pcall(ctx.Start)
            starting=false
            if ok and accepted==true then
                completedRoom=room.Id
                phase=ctx.InBetween and "AwaitingTeleport" or "Stopped"
                teleportAt=(ctx.Now and ctx.Now()or now)+15
                if ctx.Active()then ctx.Status("Start accepted · waiting for teleport")end
            elseif requestRevision==revision and ctx.Active()then retry("Start failed.",ctx.Now and ctx.Now()or now)
            elseif requestRevision~=revision then phase="Setup"
            else phase="Stopped"end
        end)
    end
    return api
end
