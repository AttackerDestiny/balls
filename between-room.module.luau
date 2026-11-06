-- Each native toggle cycles one value. Wait for replication before sending another.
return function(ctx)
    local api={}
    local pending,changes,stopped=nil,0,false
    function api.Reset()
        pending=nil;changes=0;stopped=false
    end
    function api.Update(now)
        if stopped or not ctx.Active() then return end
        local room=ctx.Read()
        if pending then
            if pending.Field=="Id" and room or room and room[pending.Field]~=pending.Before then
                pending=nil
            elseif now>=pending.Deadline then
                stopped=true
                ctx.Status("Room request timed out. Toggle Auto Create Room to retry.")
                return
            else return end
        end
        if room and (not room.Id or room.Host==nil or room.PlaceId==nil) then
            ctx.Status("Waiting for party details")
            return
        end
        if room and (room.Host~=ctx.UserId or room.PlaceId~=ctx.PlaceId) then
            ctx.Status("Leave your current party to create a Between room")
            return
        end
        local access,difficulty=ctx.Selection()
        local action,field
        if not room then changes=0;action,field="CreateParty","Id"
        elseif not room.Status or not room.Mode then return
        elseif room.Mode~=difficulty then action,field="ToggleMode","Mode"
        elseif room.Status~=access then action,field="ToggleStatus","Status"
        else
            changes=0
            ctx.Status("Room ready · "..access.." · "..difficulty)
            return
        end
        changes+=1
        if changes>8 then
            stopped=true
            ctx.Status("Room settings could not be applied. Check the native party menu.")
            return
        end
        pending={Field=field,Before=room and room[field],Deadline=now+5}
        ctx.Status(room and "Configuring The Between" or "Creating The Between room")
        ctx.Send(action)
    end
    return api
end
