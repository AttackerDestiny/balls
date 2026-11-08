return function(source,activeSource,findSource)
    local at=1
    local state={Running=true,AutoCreateBetween=true,SafeMode=true,SafeController={Seeking=false}}
    local assignment={Role="Alt",Host="ConfiguredHost",Alts={},Room={AutoRetry=false}}
    local checks=0
    local scope={state=state,assignment=assignment,localFloor=true,os={clock=function()return at end},
        retry={Update=function()checks+=1;return nil end},
        partyDefeated=function()error("Alt Start cannot depend on a wipe")end}
    local active=assert(loadstring(activeSource.."\nreturn roomActive"))
    setfenv(active,setmetatable(scope,{__index=getfenv()}));active=active()
    assert(active()and checks==0,"Enabled alts must search throughout an active run, with Auto Retry OFF")
    for _,key in ipairs({"Running","AutoCreateBetween"})do
        state[key]=false;assert(not active());state[key]=true
    end
    for _,key in ipairs({"StopEverything","AutomationTeleporting","ServerTeleportStarted"})do
        state[key]=true;assert(not active());state[key]=false
    end
    state.SafeController.Seeking=true;assert(not active());state.SafeController.Seeking=false
    assignment.Role="Host";assignment.Room.AutoRetry=false
    assert(not active(),"Host wipe/reward confirmation remains required")
    assignment.Room.AutoRetry=true
    assert(not active()and checks==1,"An active host run cannot restart merely because Start is on")
    assignment.Role="Alt"

    local current,hostRoom
    local calls,prepared,searches=0,0,0
    local joined=false
    local make=assert(loadstring(source))()
    local controller=make({UserId=11,PlaceId=20,InBetween=true,Now=function()return at end,Active=active,
        Assignment=function()return assignment end,Read=function()return current end,
        Selection=function()return "Friends","Normal"end,
        FindHostRoom=function(name)assert(name==assignment.Host);searches+=1;return hostRoom end,
        HasJoined=function()return joined end,PrepareJoin=function()prepared+=1 end,
        Status=function()end,Send=function(action,id)
            assert(action=="JoinParty"and id==hostRoom.Id,"Only join the configured host's current room")
            calls+=1
        end,Spawn=function()error("Alts cannot launch Start workers")end,
        Start=function()error("An alt cannot start a room")end})
    controller.Update(at);assert(calls==0 and searches==1,"Keep searching while the host has no room")
    hostRoom={Id="first",Host=10,PlaceId=20,Status="Friends",Mode="Normal"}
    at=2;controller.Update(at)
    for n=1,600 do at=2+n*.1;controller.Update(at)end
    assert(calls>=20 and calls<=21 and prepared==1,"Continuous joining is paced at three seconds, not every frame")
    local before=calls
    for n=1,300 do at+=3.1;controller.Update(at)end
    assert(calls==before+300,"Failed joins have no finite attempt limit or growing worker queue")
    current=hostRoom;joined=false;at+=3.1;controller.Update(at)
    assert(calls==before+301,"A matching PartyID alone cannot stop retrying")
    joined=true;at+=3.1;controller.Update(at)
    assert(calls==before+301,"A native membership receipt stops requests")
    joined=false;at+=3.1;controller.Update(at)
    assert(calls==before+302,"Losing membership resumes joining")
    hostRoom=nil;at+=3.1;controller.Update(at)
    assert(calls==before+302,"A disappearing host pauses requests without disabling the loop")
    hostRoom={Id="second",Host=10,PlaceId=20,Status="Friends",Mode="Elite"}
    at+=.35;controller.Update(at)
    assert(calls==before+303 and prepared==2,"Rediscover a replacement host room even after its mode changes")
    state.AutoCreateBetween=false;at+=10;controller.Update(at)
    assert(calls==before+303,"Start OFF stops joins immediately")
    state.AutoCreateBetween=true;controller.Update(at)
    assert(calls==before+304,"Start ON resumes joining")

    local player={UserId=10}
    local attributes={Host=10,PlaceId=20,Status="Friends",Mode="Normal"}
    local native={Name="new-room",GetAttribute=function(_,key)return attributes[key]end}
    local hostSnapshot=nil
    local discover=assert(loadstring(findSource.."\nreturn findHostRoom"))
    setfenv(discover,setmetatable({destination=20,findPlayer=function(name)return name=="ConfiguredHost"and player end,
        roomSnapshot=function()return hostSnapshot end,
        ReplicatedStorage={FindFirstChild=function()return {GetChildren=function()return {native}end}end}},{__index=getfenv()}))
    discover=discover()
    assert(discover("ConfiguredHost").Id=="new-room","Find a native room before the host's PartyID replicates")
    attributes.Host=99;assert(not discover("ConfiguredHost"),"Never discover a different host's room")
    attributes.Host=10;attributes.PlaceId=99;assert(not discover("ConfiguredHost"),"Only discover The Between rooms")
    assert(not discover("MissingHost"),"A missing host cannot select an unrelated native room")
    print("PASS Between alt join: Start-only activation, unlimited paced attempts, roster receipts, rediscovery and stop/safety gates")
end
