return function(source,nativeInstances)
    local humanoid={Health=100}
    local model
    if nativeInstances then
        model=Instance.new("Model");humanoid=Instance.new("Humanoid");humanoid.Parent=model
    end
    local state={Running=true,Enabled=true,AutoFarm=true,TravelSerial=2,TravelBusy=true,PlayerTravelLease={}}
    local saves,queues,returns,cancels=0,0,0,0
    state.SaveNow=function()saves+=1 end
    state.QueueAutomation=function()queues+=1 end
    state.CancelSkillAura=function()cancels+=1 end
    state.CancelMiscSkill=function()cancels+=1 end
    local players={LocalPlayer={Name="Host",UserId=1},GetPlayers=function()return {{Name="Host",UserId=1},{Name="Alt",UserId=2}}end}
    local player={Character=model or {FindFirstChildOfClass=function()return humanoid end},GetAttribute=function()return nil end}
    local bound
    local chunk=assert(loadstring(source))
    setfenv(chunk,setmetatable({state=state,player=player,Players=players,localFloor=true,
        makeRegroup=function(ctx)bound=ctx;return {}end,regroupUsers=function()return {"Host","Alt"}end,
        finishAttackBurst=function()end,stopSword=function()end,stopMovement=function()end,
        ReplicatedStorage={Event={FireServer=function(_,route,args)
            assert(route=="UniqueFloorTypes"and args[1]=="WaveDefense"and args[2]=="Return")
            returns+=1
        end}}},{__index=getfenv()}))
    local ok,reason=pcall(function()
        chunk()
        assert(bound.InBetween()and bound.Present().alt and bound.Present()["2"])
        assert(not bound.Dead())
        bound.Pause();bound.ResetCharacter()
        assert(humanoid.Health==0 and bound.Dead(),"Reset only the supplied character")
        assert(state.TravelSerial==3 and not state.TravelBusy and not state.PlayerTravelLease and cancels==2)
        bound.PrepareReturn();bound.Return()
        assert(saves==1 and queues==1 and returns==1 and state.Enabled and state.AutoFarm,
            "Prepare the reload and preserve combat preferences before native Return")
    end)
    if model then model:Destroy()end
    assert(ok,reason)
    print("PASS Auto Regroup adapter: local reset, native Return payload, teleport queue and preference preservation")
    return {Passed=true,Native=nativeInstances==true}
end
