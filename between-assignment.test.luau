return function(source)
    local state={}
    local host={Name="Host",UserId=1}
    local alt={Name="Alt1",UserId=2}
    local room={Host="Host",Alt="Host, 1, Alt1",Start=true,AutoRetry=true}
    local rooms={room}
    local scope={state=state,rooms=rooms,player=host,
        hostName=function(entry)return entry.Host:match("^[%w_]+$")end,
        matches=function(person,name)return person.Name:lower()==name:lower()or tostring(person.UserId)==name end,
        findPlayer=function(name)
            if name:lower()=="host"or name=="1"then return host end
            if name:lower()=="alt1"or name=="2"then return alt end
        end}
    local chunk=assert(loadstring(source.."\nreturn function()updateAssignment();return assignment end"))
    setfenv(chunk,setmetatable(scope,{__index=getfenv()}))
    local update=chunk()
    local assignment=update()
    assert(assignment.Role=="Host"and #assignment.Alts==1 and assignment.Alts[1]=="Alt1"and state.AutoCreateBetween,
        "Repeating the host by username or ID in Alt cannot invalidate a legitimate room")
    local names={};for i=1,17 do names[i]="Alt"..i end
    room.Alt=table.concat(names,", ")
    assignment=update()
    assert(assignment.Role=="Invalid"and not state.AutoCreateBetween and state.BetweenRoomErrors[1]
        and state.BetweenRoomStatus:find("17 alts",1,true)and state.BetweenRoomStatus:find("at most 7",1,true),
        "An oversized room must show its exact blocker, never silently disable or truncate the requested users")
    local original=room.Alt
    assert(room.Alt==original,"Validation must preserve the user's configured roster")
    for i=8,17 do names[i]=nil end
    room.Alt=table.concat(names,", ")
    assignment=update()
    assert(assignment.Role=="Host"and #assignment.Alts==7 and state.AutoCreateBetween and not state.BetweenRoomError
        and not state.BetweenRoomErrors[1],"A corrected seven-alt roster clears validation without restarting")
    scope.player=alt;assignment=update()
    assert(assignment.Role=="Alt"and state.AutoCreateBetween,"Matching alt assignments remain valid")
    rooms[2]={Host="Elsewhere",Alt="Alt1",Start=true}
    assignment=update()
    assert(assignment.Role=="Invalid"and state.BetweenRoomErrors[1]and state.BetweenRoomErrors[2],
        "Conflicting active rooms remain fail-closed and identify both setups")
    rooms[2]=nil;room.Start=false
    assignment=update()
    assert(assignment.Role=="Unassigned"and not state.AutoCreateBetween and not state.BetweenRoomError)
    local testAccount={Name="Sb2WaBanTest",UserId=99}
    scope.player=testAccount;room.Host="Host";room.Start=true
    room.Alt="andrew_ei7h4, MonyTally, brandon_1sks4, dana_axmr, levi_9hj32y, cameron_9e3, lindsay_nxi4"
    local original=room.Alt
    assignment=update()
    assert(assignment.Role=="Unassigned"and not state.AutoCreateBetween and state.BetweenRoomStatus:find("Sb2WaBanTest",1,true)
        and state.BetweenRoomErrors[1]:find("not in this room",1,true),
        "An enabled room must explain when the current account is missing from its Alt list")
    assert(room.Alt==original,"Diagnostics cannot append an eighth alt or replace another user")
    room.Alt=room.Alt:gsub("brandon_1sks4","Sb2WaBanTest")
    assignment=update()
    assert(assignment.Role=="Alt"and #assignment.Alts==7 and state.AutoCreateBetween and not state.BetweenRoomError
        and not state.BetweenRoomErrors[1],"Correcting the configured slot enables joining without changing a derived flag")
    room.Start=false;assignment=update()
    assert(not state.BetweenRoomError and not next(state.BetweenRoomErrors),"Start OFF clears the unassigned-room warning")
    print("PASS Between assignment: host deduplication, native seven-alt limit, explicit errors, roster preservation and corrected setup")
end
