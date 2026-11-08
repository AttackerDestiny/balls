return function(source,usersSource)
    local make=assert(loadstring(source))()
    local function fixture()
        local f={State={Running=true,AutoRegroup=true},Users={"Alt","Host"},Roster={alt=true,host=true},InBetween=true,
            Resets=0,Returns=0,Pauses=0,Releases=0,Prepared=0,Dead=false}
        f.Api=make({State=f.State,InBetween=function()return f.InBetween end,Users=function()return f.Users end,
            Present=function()return f.Roster end,Pause=function()f.Pauses+=1 end,Release=function()f.Releases+=1 end,
            ResetCharacter=function()f.Resets+=1 end,Dead=function()return f.Dead end,
            PrepareReturn=function()f.Prepared+=1 end,Return=function()f.Returns+=1 end})
        return f
    end
    local f=fixture();f.Roster.alt=nil
    f.Api.Update(0);f.Api.Update(14);assert(f.Resets==0,"Initial player replication gets a grace period")
    f.Api.Update(15);f.Api.Update(19);assert(f.Resets==0)
    f.Roster.alt=true;f.Api.Update(19.5);f.Roster.alt=nil
    f.Api.Update(20);f.Api.Update(24.9);assert(f.Resets==0,"A reappearing player cancels the pending regroup")
    f.Api.Update(25);assert(f.Resets==1 and f.Pauses==1 and f.State.AutoRegroupHolding)
    f.Api.Update(25.5);assert(f.Returns==0,"Give the reset a chance to finish")
    f.Dead=true;f.Api.Update(26);f.Api.Update(26.5)
    assert(f.Resets==1 and f.Returns==1 and f.Prepared==1,"Reset once, then use the native lobby return")
    f.Api.Update(27);assert(f.Returns==1,"Return requests are paced")
    f.Api.Update(36.5);f.Api.Update(46.5);f.Api.Update(56.5)
    assert(f.Returns==3 and f.Api.Phase=="Failed","A stalled lobby return has bounded attempts")
    f.State.AutoRegroup=false;f.Api.Update(57)
    assert(not f.State.AutoRegroupHolding and f.Releases==1,"OFF cancels and releases owned work")
    for _,flag in ipairs({"StopEverything","ModeratorBlocking","SafeModePanic","AutomationTeleporting","ServerTeleportStarted","AutoJoinFriendHolding","AutoTradeBusy"})do
        f=fixture();f.State[flag]=true;f.Roster={};f.Api.Update(0);f.Api.Update(100)
        assert(f.Resets==0 and f.Returns==0,"Protection and travel pause regroup: "..flag)
    end
    f=fixture();f.Roster={};f.InBetween=false;f.Api.Update(0);f.Api.Update(100)
    assert(f.Resets==0,"Regroup never resets accounts in the lobby or normal floors")
    f=fixture();f.Users={};f.Api.Update(0);f.Api.Update(100);assert(f.Resets==0,"No configured users means no destructive action")
    f=fixture();f.Roster={};f.Api.Update(0);f.Api.Update(15)
    f.State.StopEverything=true;f.Api.Update(100);f.State.StopEverything=false;f.Api.Update(101)
    assert(f.Resets==0,"A paused observation cannot satisfy missing-user confirmation")
    f.Api.Update(106);assert(f.Resets==1)
    f=fixture();f.Api.Update(0);f.Api.Update(20)
    assert(f.Resets==0,"Listed dead or respawning users still count as present in the server")
    f=fixture();f.Roster={};f.Api.Update(0);f.Api.Update(15);f.Api.Update(20)
    assert(f.Resets==1,"Missing two or more users triggers the same regroup")
    f.Api.Destroy();f.Api.Destroy();f.Api.Update(100)
    assert(f.Resets==1 and f.Returns==0 and f.Releases==1,"Retired controllers cannot reset or return")

    local state={AutoRegroupUsers=""}
    local player={Name="Alt",UserId=2}
    local assignment={Room={Host="Host",Alt="Alt, Other"}}
    local chunk=assert(loadstring(usersSource.."\nreturn regroupUsers"))
    setfenv(chunk,setmetatable({state=state,player=player,assignment=assignment,rooms={},
        hostName=function(room)return room.Host end,matches=function(person,name)return person.Name:lower()==name:lower()or tostring(person.UserId)==name end},{__index=getfenv()}))
    local users=chunk()
    assert(table.concat(users(),", ")=="Alt, Host, Other","Default roster includes both host and alts")
    state.AutoRegroupUsers="@Host, HOST; Alt, 123"
    assert(table.concat(users(),", ")=="123, Alt, Host","Overrides normalize names, IDs and duplicates")
    print("PASS Auto Regroup: default roster, missing-user grace, multi-user loss, reset/return order, pacing, protection and cleanup")
end
