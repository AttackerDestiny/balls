-- No Roblox client or real teleport is used.
return function(source)
    local make=assert(loadstring(source))()
    local state={Running=true,AtheonUnlock=false}
    local portal,root,busy,fail=nil,nil,false,false
    local moves=0
    local unlocked=false
    local api=make({State=state,Busy=function()return busy end,
        Unlocked=function()return unlocked end,
        Find=function()return portal end,Root=function()return root end,
        Position=function(p)return p.Position end,
        Move=function(r,p)
            if fail then error("transient")end
            assert(r==root and p==portal.Position);moves+=1
        end})
    api.Update(0);assert(moves==0)
    state.AtheonUnlock=true
    unlocked=true;api.Update(.5)
    assert(moves==0 and state.AtheonUnlockStatus=="Atheon is already unlocked","Unlocked accounts skip even a missing portal")
    unlocked=false
    api.Update(1);assert(state.AtheonUnlockStatus=="Waiting for workspace.AtheonPortal")
    portal={Position={1,2,3}};api.Update(2)
    assert(state.AtheonUnlockStatus=="Waiting for a living character")
    root={};busy=true;api.Update(3);assert(moves==0)
    busy=false;api.Update(3);assert(moves==1)
    for now=4,100 do api.Update(now)end
    assert(moves==1,"Enabled helper must not continually pull the player back")
    root={};api.Update(101);assert(moves==2,"Respawn gets a fresh placement")
    portal={Position={4,5,6}};api.Update(102);assert(moves==3)
    state.AtheonUnlock=false;api.Reset();api.Update(103);assert(moves==3)
    state.AtheonUnlock=true;fail=true;api.Update(104);assert(moves==3)
    fail=false;api.Update(105);assert(moves==3,"Failed moves back off")
    api.Update(106);assert(moves==4)
    api.Reset();unlocked=true;root={};api.Update(107)
    assert(moves==4,"Unlock detection must also prevent a fresh character placement")
    unlocked=false;api.Update(108);assert(moves==5)
    api.Reset();fail=true;api.Update(109)
    unlocked=true;fail=false;api.Update(111)
    assert(moves==5 and state.AtheonUnlockStatus=="Atheon is already unlocked","Unlock during retry cancels the pending teleport")
    api.Reset();state.Running=false;api.Update(112);assert(moves==5)
    print("PASS Atheon Unlock: unlock guard, missing portal/character, protection, one placement, respawn, re-enable, retry and shutdown")
end
