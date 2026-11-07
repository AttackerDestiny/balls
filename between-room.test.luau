return function(source)
    local make=assert(loadstring(source))()
    local room={Id=1,Host=10,PlaceId=20,Status="Private",Mode="Normal"}
    local requests={}
    local worker
    local starts=0
    local accepted=false
    local assignment,hostRoom
    local missing={}
    local controller=make({
        UserId=10,PlaceId=20,
        Active=function()return true end,
        Read=function()return room end,
        Assignment=function()return assignment end,
        MissingAlts=function()return missing end,
        FindHostRoom=function()return hostRoom end,
        Selection=function()return "Friends","Hard" end,
        Status=function()end,
        Send=function(action,id)requests[#requests+1]=id and action..":"..id or action end,
        Spawn=function(fn)assert(not worker);worker=fn end,
        Start=function()starts+=1;return accepted end,
    })
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
    hostRoom={Id="3",Status="Friends"}
    controller.Reset()
    controller.Update(9)
    controller.Update(9.35)
    assert(#requests==3 and requests[3]=="JoinParty:3","Only request the configured host room and pace retries")
    print("PASS The Between starts once after both room settings are confirmed")
end
