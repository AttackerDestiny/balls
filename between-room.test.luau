return function(source,snapshotSource)
    local make=assert(loadstring(source))()
    local room={Id=1,Host=10,PlaceId=20,Status="Private",Mode="Normal"}
    local requests={}
    local worker
    local starts=0
    local accepted=false
    local enabled=false
    local assignment,hostRoom
    local missing={}
    local ctx={
        UserId=10,PlaceId=20,
        Active=function()return enabled end,
        Read=function()return room end,
        Assignment=function()return assignment end,
        MissingAlts=function()return missing end,
        FindHostRoom=function()return hostRoom end,
        Selection=function()return "Friends","Hard" end,
        Status=function()end,
        Send=function(action,id)
            assert(action~="LeaveParty" and action~="Return","Retry cannot send a lobby exit request")
            requests[#requests+1]=id and action..":"..id or action
        end,
        Spawn=function(fn)assert(not worker);worker=fn end,
        Start=function()starts+=1;return accepted end,
    }
    local controller=make(ctx)
    controller.Update(-1)
    assert(#requests==0,"Disabled rooms must not send requests")
    enabled=true
    controller.Update(0)
    controller.Update(.5)
    assert(#requests==1 and requests[1]=="ToggleMode" and not worker)
    room.Mode="Hard"
    controller.Update(1)
    assert(requests[2]=="ToggleStatus" and not worker)
    room.Status="Friends"
    controller.Update(2)
    controller.Update(3)
    assert(worker and starts==0)
    local run=worker;worker=nil;run()
    controller.Update(4)
    assert(starts==1 and not worker,"A rejected start must not retry automatically")
    accepted=true
    controller.Reset()
    controller.Update(5)
    run=worker;worker=nil;run()
    controller.Reset()
    controller.Update(6)
    assert(starts==2 and not worker,"An accepted start must not be sent twice for the same room")
    room.Id=2
    assignment={Role="Host",Alts={"First","Second"}}
    missing={"Second"}
    controller.Update(7)
    assert(not worker,"Host must wait for the last Alt")
    missing={}
    controller.Update(8)
    missing={"Second"}
    run=worker;worker=nil;run()
    assert(starts==2,"Check the roster again immediately before Start")
    room=nil
    assignment={Role="Alt",Host="HostAccount"}
    hostRoom={Id="3",Status="Friends",Mode="Normal"}
    controller.Reset()
    controller.Update(9)
    assert(#requests==2,"Wait for the host room to finish configuring")
    hostRoom.Mode="Hard"
    controller.Update(9.35)
    controller.Update(9.7)
    assert(#requests==3 and requests[3]=="JoinParty:3","Only request the configured host room and pace retries")
    assignment={Role="Host",Alts={"First","Second"}}
    room={Id="old",Host=10,PlaceId=20,Status="Friends",Mode="Hard"}
    controller=make(ctx)
    controller.Update(10)
    assert(#requests==3 and not worker,"Keep the retained party while waiting for its alts")
    missing={}
    controller.Update(10.35)
    run=worker;worker=nil;run()
    assert(starts==3,"The retained party can restart in place")

    controller=make(ctx)
    missing={"Second"}
    room=nil
    controller.Update(11)
    assert(requests[4]=="CreateParty")
    room={Id="new",Host=10,PlaceId=20,Status="Friends",Mode="Hard"}
    controller.Update(12)
    assert(not worker,"Wait for the roster again in the recreated room")
    missing={}
    controller.Update(13)
    run=worker;worker=nil;run()
    assert(starts==4,"Start the fresh room once its roster is present")
    controller.Reset()
    room.Id="another"
    controller.Update(14)
    controller.Reset()
    run=worker;worker=nil;run()
    assert(starts==4,"Removing or changing an assignment cancels a start waiting to dispatch")

    local nativeParty
    local snapshot=assert(loadstring(snapshotSource.."\nreturn roomSnapshot,missingRoomAlts"))
    local env={localFloor=true,player={GetAttribute=function()return 23 end},
        ReplicatedStorage={FindFirstChild=function()return {FindFirstChild=function()return nativeParty end}end}}
    setfenv(snapshot,setmetatable(env,{__index=getfenv()}))
    local read,missingRoomAlts=snapshot()
    assert(not read(),"A stale PartyID cannot prevent room creation inside The Between")
    nativeParty={GetAttribute=function(_,name)return name=="Host"and 10 or nil end}
    assert(read().Host==10 and read().Id=="23","Recognize a real retained party")
    nativeParty=nil;env.localFloor=false
    assert(read().Id=="23","Keep waiting for the replicated party details in the lobby")

    local members,players={Host=10,PlaceId=20,Status="Friends",Mode="Hard"},{}
    local names={}
    for index=1,7 do
        local id=10+index
        names[index]=index==7 and tostring(id) or "alt"..index
        if index~=7 then
            players[index]={Name="Alt"..index,UserId=id,PartyId=index%2==0 and 23 or nil,
                GetAttribute=function(person,key)assert(key=="PartyID");return person.PartyId end}
        end
        if index%2==1 then members[tostring(id)]=true end
    end
    nativeParty={GetAttribute=function(_,name)return members[name]end}
    env.Players={GetPlayers=function()return players end}
    ctx.Read=read;ctx.MissingAlts=missingRoomAlts
    assignment={Role="Host",Alts=names}
    controller=make(ctx)
    assert(#missingRoomAlts(read(),names)==0,"Recognize all seven alts using independently replicated markers")
    controller.Update(20)
    players[6].PartyId=999
    run=worker;worker=nil;run()
    assert(starts==4 and missingRoomAlts(read(),names)[1]=="alt6","An alt in a different party cancels the pending start")
    players[6].PartyId=23
    controller.Update(21)
    run=worker;worker=nil;run()
    controller.Update(22)
    assert(starts==5 and not worker,"Start once after all seven alts have joined")
    print("PASS The Between: confirmed settings, mixed roster receipts, seven alts, and final roster recheck")
end
