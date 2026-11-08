return function(source,snapshotSource,resumeSource)
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
    local snapshot=assert(loadstring(snapshotSource.."\nreturn roomSnapshot,missingRoomAlts,joinedHostRoom"))
    local env={localFloor=true,player={GetAttribute=function()return 23 end},
        ReplicatedStorage={FindFirstChild=function()return {FindFirstChild=function()return nativeParty end}end}}
    setfenv(snapshot,setmetatable(env,{__index=getfenv()}))
    local read,missingRoomAlts,joinedHostRoom=snapshot()
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
    env.localFloor=true;members["10"]=true
    assert(#missingRoomAlts(read(),names)==3,"An old PartyID is insufficient when the retained native roster is available")
    env.player.UserId=12
    members["10"]=nil
    assert(not joinedHostRoom(read()),"An unknown native roster cannot confirm an alt joined inside The Between")
    members["10"]=true
    assert(not joinedHostRoom(read()),"A missing native member keeps an alt joining despite a stale PartyID")
    members["12"]=true
    assert(joinedHostRoom(read()),"A positive native roster receipt stops the join loop")
    members["12"]=nil;members["10"]=nil;env.localFloor=false
    assert(joinedHostRoom(read()),"Preserve the lobby's PartyID fallback before its native roster appears")
    env.localFloor=true

    ctx.Read=function()return room end
    ctx.MissingAlts=function()return missing end
    ctx.InBetween=true
    local prepared=0
    ctx.PrepareJoin=function()prepared+=1 end
    ctx.HasJoined=function(view)return view.Joined==true end
    room={Id="old",Host=10,PlaceId=20,Status="Friends",Mode="Hard"}
    hostRoom={Id="replacement",Host=10,PlaceId=20,Status="Friends",Mode="Elite"}
    assignment={Role="Alt",Host="HostAccount"}
    controller=make(ctx)
    local sent=#requests
    for n=0,4 do controller.Update(30+n*3)end
    assert(#requests==sent+5 and requests[#requests]=="JoinParty:replacement" and prepared==1,
        "An alt keeps joining a replacement from the same host without leaving the server")
    room=hostRoom
    controller.Update(45)
    assert(#requests==sent+6,"A stale PartyID on a retained room still needs a native join receipt")
    room.Joined=true
    controller.Update(48)
    assert(#requests==sent+6 and prepared==1)
    room={Id="other",Host=99,PlaceId=20}
    controller.Update(51)
    assert(#requests==sent+6,"A different host's party is left alone")

    assignment={Role="Host",Alts=names}
    room={Id="retry",Host=10,PlaceId=20,Status="Friends",Mode="Hard"}
    missing={};accepted=false;controller=make(ctx)
    controller.Update(60);run=worker;worker=nil;run()
    controller.Update(61);assert(not worker)
    accepted=true
    controller.Update(62);run=worker;worker=nil;run()
    assert(starts==7,"The host retries a failed Start inside The Between")
    controller.Update(76);assert(not worker)
    controller.Update(77);assert(not worker)
    controller.Update(79);assert(worker,"A stalled teleport can retry after a fresh roster check")

    local carried={{Host="HostAccount",Alt="Alt1",Start=true,AutoRetry=true}}
    local function loadResume(place,user)
        local resume=assert(loadstring(resumeSource.."\nreturn restore.BetweenRooms"))
        local original={}
        local scope={env={SB2BetweenResumeRooms={UserId=1,Rooms=carried}},game={PlaceId=place},player={UserId=user},restore={BetweenRooms=original}}
        setfenv(resume,setmetatable(scope,{__index=getfenv()}))
        local result=resume()
        assert(scope.env.SB2BetweenResumeRooms==nil)
        return result,original
    end
    assert(loadResume(78945654064532,1)==carried)
    local result,original=loadResume(78945654064532,2);assert(result==original)
    result,original=loadResume(20,1);assert(result==original)
    print("PASS The Between: roster recheck, replacement and retained party joins, native Start retry and preset handoff")
end
