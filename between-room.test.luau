return function(source)
    local make=assert(loadstring(source))()
    local room={Id=1,Host=10,PlaceId=20,Status="Private",Mode="Normal"}
    local requests={}
    local worker
    local starts=0
    local accepted=false
    local controller=make({
        UserId=10,PlaceId=20,
        Active=function()return true end,
        Read=function()return room end,
        Selection=function()return "Friends","Hard" end,
        Status=function()end,
        Send=function(action)requests[#requests+1]=action end,
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
    print("PASS The Between starts once after both room settings are confirmed")
end
