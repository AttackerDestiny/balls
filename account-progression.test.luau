return function(source)
    local make=assert(loadstring(source))()
    local count=0
    local function test(name,fn)fn();count+=1;print("PASS "..name)end
    local function fixture()
        local f={State={AccountProgression=true,Running=true,ProgressionFloor=1},FloorId=1,
            Allowed=true,Combat=true,Travelling=false,AtBoss=true,Unlocked={},Trips={},BossTrips={},Saves={},
            Releases=0,Completions=0,Equips=0,Spot={Id="boss",Name="Main boss"}}
        for i=1,12 do f.Unlocked[i]=true end
        f.Api=make({State=f.State,Floor=function(i)if i<=12 then return {Id=i,Number=i}end end,
            CurrentFloor=function()return f.FloorId end,Unlocked=function(floor)return f.Unlocked[floor.Id]end,
            Ready=function()return f.Allowed end,CombatReady=function()return f.Combat end,
            ChangeFloor=function(floor)f.Trips[#f.Trips+1]=floor.Id;return not f.FloorFailure,"Native travel rejected"end,
            BossSpot=function(_,index)f.ScoutIndex=index;return f.NoSpot and nil or f.Spot end,
            Go=function(spot)f.BossTrips[#f.BossTrips+1]=spot;return not f.BossFailure end,
            Moving=function()return f.Travelling end,Arrived=function()return f.AtBoss end,
            Arrival=function()f.Arrivals=(f.Arrivals or 0)+1 end,Boss=function()return f.Boss end,
            NearBossSpot=function()return f.Near~=false end,
            ChestTarget=function()return f.Chest end,
            Complete=function()f.Completions+=1 end,Equipment=function()f.Equips+=1 end,
            Release=function()f.Releases+=1 end,Status=function(value)f.Status=value end,
            Save=function()f.Saves[#f.Saves+1]={Floor=f.State.ProgressionFloor,Cleared=f.State.ProgressionBossCleared,Name=f.State.ProgressionBossClearedName,Complete=f.State.ProgressionComplete}end})
        return f
    end
    test("Progression uses the main boss before moving upward and persists the checkpoint",function()
        local f=fixture();f.Api.Update(0);assert(#f.BossTrips==1 and #f.Trips==0)
        f.Boss={Alive=true,Name="Main boss"};f.Api.Update(1);f.Api.Update(10)
        assert(f.Api.Phase=="Fighting"and #f.Trips==0 and #f.BossTrips==1)
        f.Boss={Defeated=true,Credited=true,Name="Main boss"};f.Api.Update(11)
        assert(f.State.ProgressionBossCleared and f.Saves[1].Floor==1)
        assert(f.Saves[1].Name=="Main boss")
        f.Api.Update(12);assert(f.Trips[1]==2 and f.State.ProgressionFloor==2)
        assert(f.Saves[2].Floor==2 and not f.Saves[2].Cleared)
        assert(not f.Saves[2].Name)
    end)
    test("Progression does not infer a kill from despawn, an empty arena or an uncredited death",function()
        for _,boss in ipairs({false,{Defeated=true,Credited=false},{Alive=true,Name="Boss"}})do
            local f=fixture();f.Api.Update(0);f.Boss=boss or nil;f.Api.Update(1);f.Api.Update(100)
            assert(not f.State.ProgressionBossCleared and #f.Trips==0)
        end
    end)
    test("Progression waits for actual server unlock replication",function()
        local f=fixture();f.State.ProgressionBossCleared=true;f.Unlocked[2]=false
        f.Api.Update(0);f.Api.Update(3);assert(#f.Trips==0 and f.Api.Phase=="Waiting for unlock")
        f.Unlocked[2]=true;f.Api.Update(4);assert(f.Trips[1]==2)
    end)
    test("Loaded chests pause floor advancement while preserving a credited boss receipt",function()
        local f=fixture();f.Api.Update(0)
        f.Boss={Defeated=true,Credited=true,Name="Main boss"}
        f.Chest={Name="Reward Chest"};f.Api.Update(1)
        assert(f.Api.Phase=="Collecting chest"and f.State.ProgressionFloor==1 and f.State.ProgressionBossClearedName=="Main boss"
            and f.State.ProgressionBossCleared and #f.Trips==0)
        f.Chest=nil;f.Api.Update(2)
        assert(f.Trips[1]==2 and f.State.ProgressionFloor==2,"Resume ordinary native floor validation after the chest opens")
    end)
    test("A stale boss-clear checkpoint cannot wait forever for a locked next floor",function()
        local f=fixture();f.State.ProgressionFloor=2;f.FloorId=2;f.State.ProgressionBossCleared=true
        f.State.ProgressionBossClearedName="Borik the BeeKeeper";f.Unlocked[3]=false
        f.Api.Update(0);f.Api.Update(8)
        assert(not f.State.ProgressionBossCleared and not f.State.ProgressionBossClearedName and #f.Trips==0)
        f.Api.Update(8.1);assert(#f.BossTrips==1 and f.State.ProgressionFloor==2)
    end)
    test("Unlock recovery honors protection pauses and never invents a town boss",function()
        local f=fixture();f.State.ProgressionBossCleared=true;f.Unlocked[2]=false
        f.Api.Update(0);f.Allowed=false;f.Api.Update(20);f.Allowed=true;f.Api.Update(21)
        assert(f.State.ProgressionBossCleared);f.Api.Update(29);assert(not f.State.ProgressionBossCleared)
        f=fixture();f.State.ProgressionFloor=6;f.FloorId=6;f.Unlocked[7]=false
        f.Api.Update(0);f.Api.Update(100);assert(#f.BossTrips==0 and f.State.ProgressionFloor==6)
    end)
    test("Progression resumes a saved floor rather than restarting at F1 after a hop",function()
        local f=fixture();f.State.ProgressionFloor=8;f.FloorId=8
        f.Api.Update(0);assert(#f.BossTrips==1 and #f.Trips==0)
        f.State.ProgressionBossCleared=true;f.Api.Update(1);assert(f.Trips[1]==9)
    end)
    test("Progression leaves an existing Helmfirth checkpoint for F7",function()
        local f=fixture();f.State.ProgressionFloor=6;f.FloorId=6;f.Api.Update(0)
        assert(f.Trips[1]==7 and #f.BossTrips==0 and not f.State.ProgressionBossCleared)
    end)
    test("F5 clear skips locked F6 and targets unlocked F7 directly",function()
        local f=fixture();f.State.ProgressionFloor=5;f.FloorId=5
        f.State.ProgressionBossCleared=true;f.Unlocked[6]=false
        f.Api.Update(0);assert(f.Trips[1]==7 and f.State.ProgressionFloor==7)
        assert(f.Saves[1].Floor==7 and #f.BossTrips==0)
    end)
    test("An old F6 checkpoint never travels back to town",function()
        local f=fixture();f.State.ProgressionFloor=6;f.FloorId=5
        f.Api.Update(0);assert(f.Trips[1]==7 and f.State.ProgressionFloor==7)
    end)
    test("Skipping F6 still requires the actual F7 unlock",function()
        local f=fixture();f.State.ProgressionFloor=5;f.FloorId=5
        f.State.ProgressionBossCleared=true;f.Unlocked[7]=false
        f.Api.Update(0);assert(#f.Trips==0 and f.Status:find("F7 unlock",1,true))
        f.Unlocked[7]=true;f.Api.Update(1);assert(f.Trips[1]==7)
    end)
    test("Progression starts from F1 even when enabled on another floor",function()
        local f=fixture();f.FloorId=13;f.Api.Update(0);f.Api.Update(.5)
        assert(#f.Trips==1 and f.Trips[1]==1 and #f.BossTrips==0)
    end)
    test("Progression stops at the F12 boss and never requests F13",function()
        local f=fixture();f.State.ProgressionFloor=12;f.FloorId=12;f.State.ProgressionBossCleared=true
        f.Api.Update(0);f.Api.Update(1);f.Api.Update(100)
        assert(f.State.ProgressionComplete and f.Completions==1 and #f.Trips==0 and f.Api.Phase=="Complete")
        assert(f.State.AccountProgression,"Keep the completed owner until OFF restores other floor modes")
    end)
    test("Progression yields to safety, respawn and Stop Everything",function()
        local f=fixture();f.Allowed=false;f.Api.Update(0);assert(#f.BossTrips==0)
        f.Allowed=true;f.State.StopEverything=true;f.Api.Update(1);assert(#f.BossTrips==0)
        f.State.StopEverything=false;f.State.AccountProgression=false;f.Api.Update(2);assert(#f.BossTrips==0)
        f.State.AccountProgression=true;f.State.Running=false;f.Api.Update(3);assert(#f.BossTrips==0)
    end)
    test("Progression respects a user-paused combat toggle",function()
        local f=fixture();f.Combat=false;f.Api.Update(0)
        assert(#f.BossTrips==0 and f.Api.Phase=="Waiting for combat")
    end)
    test("Respawn or panic at a distant pad re-enters the same boss arena",function()
        local f=fixture();f.Api.Update(0);f.Boss={Alive=true,Name="Boss"};f.Api.Update(1)
        f.Allowed=false;f.Api.Update(2);f.Allowed=true;f.Near=false;f.Api.Update(3)
        assert(#f.BossTrips==2 and #f.Trips==0 and f.State.ProgressionFloor==1)
    end)
    test("Boss travel failures retry the same checkpoint with bounded attempts",function()
        local f=fixture();f.BossFailure=true;f.Api.Update(0);f.Api.Update(1);assert(#f.BossTrips==1)
        f.Api.Update(2);f.Api.Update(6);assert(#f.BossTrips==3 and f.Api.Paused and f.State.AccountProgression)
        f.Api.Update(100);assert(#f.BossTrips==3)
    end)
    test("Progression watches in-flight arrival and does not hold a destination while fighting",function()
        local f=fixture();f.Api.Update(0);f.Travelling=true;f.Api.Update(1);assert(not f.Arrivals)
        f.Travelling=false;f.Boss={Alive=true,Name="Boss"};f.Api.Update(2);f.Api.Update(3)
        assert(f.Arrivals==1 and #f.BossTrips==1)
    end)
    test("Progression times out travel and refuses a corrected/unconfirmed arrival",function()
        local f=fixture();f.Api.Update(0);f.Travelling=true;f.Api.Update(16)
        assert(f.Api.Phase=="Retrying"and f.State.ProgressionFloor==1)
        f=fixture();f.Api.Update(0);f.AtBoss=false;f.Api.Update(1);assert(f.Api.Phase=="Retrying")
    end)
    test("F12 scouts unclassified arenas without farming minibosses as the main boss",function()
        local f=fixture();f.State.ProgressionFloor=12;f.FloorId=12;f.Spot.Scout=true
        f.Api.Update(0);f.Api.Update(1);f.Api.Update(21);f.Api.Update(22)
        assert(#f.BossTrips==2 and f.ScoutIndex==2 and not f.State.ProgressionBossCleared)
    end)
    test("A rejected native floor transfer pauses rather than flooding requests",function()
        local f=fixture();f.FloorId=13;f.FloorFailure=true;f.Api.Update(0);f.Api.Update(10)
        assert(#f.Trips==1 and f.Api.Paused and f.Api.LastError=="Native travel rejected")
    end)
    print("All "..count.." progression scenarios passed")
end
