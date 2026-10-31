return function(moduleSource)
    local folder=Instance.new("Folder")
    local mobs,data={},{}
    for i=1,3 do
        local mob=Instance.new("Model",folder); mob.Name="SkillFixture"..i
        local hp=Instance.new("NumberValue",mob); hp.Value=i==1 and 10 or 100
        local credit=Instance.new("NumberValue",hp)
        mobs[i]=mob; data[mob]={Health=hp,Credit=credit}
    end
    local state={SkillHitRequests=0}
    local record={HealthDrops=0,Requested=0}
    local api=assert(loadstring(moduleSource))()({State=state,Record=record,Spacing=.02,
        Targets=function() return {mobs[1],mobs[2],mobs[2],mobs[3]} end,
        Valid=function(mob) return mob~=mobs[3] and data[mob].Health.Value>0 and data[mob] or nil end,
        CanRun=function() return true end,
        Contribution=function(health,counter)
            if counter then return counter.Value,counter end
            local value=health:FindFirstChildOfClass("NumberValue")
            return value.Value,value
        end,
        Send=function(_,entry) entry.Health.Value-=10;entry.Credit.Value+=10 end})
    local ok,result=pcall(function()
        assert(api.Start(mobs[1],table.pack()),"A native hit should start the burst")
        assert(not api.Start(mobs[2],table.pack()),"Later native callbacks must not duplicate the burst")
        local deadline=os.clock()+2
        repeat task.wait(.02) until record.FinishedAt or os.clock()>deadline
        data[mobs[2]].Health.Value-=7 -- Another player's damage in the same window.
        api.Finish()
        assert(record.FinishedAt,"Burst must finish")
        assert(record.TargetCount==2,"Only unique in-range targets should be included")
        assert(record.Targets[1].Requested==1,"Dead targets must stop receiving requests")
        assert(record.Targets[2].Requested==3,"Other targets must continue after the first dies")
        assert(data[mobs[3]].Health.Value==100,"Out-of-range targets must remain untouched")
        assert(record.Damage==40 and state.SkillHitRequests==4,"Track actual health changes per target")
        data[mobs[2]].Health.Value-=10
        api.Finish()
        assert(record.Damage==40,"Later normal damage must not be attributed to the completed skill burst")
        local cancelledCalls=0
        local cancelledRecord={HealthDrops=0,Requested=0}
        local cancelledApi=assert(loadstring(moduleSource))()({State={SkillHitRequests=0},Record=cancelledRecord,Spacing=.04,
            Targets=function() return {mobs[2]} end,Valid=function(mob) return data[mob] end,CanRun=function() return true end,
            Send=function() cancelledCalls+=1 end})
        cancelledApi.Start(mobs[2],table.pack())
        task.wait(.01); cancelledApi.Cancel("Weapon changed")
        local count=cancelledCalls; task.wait(.12)
        assert(cancelledCalls==count and cancelledRecord.ObservationFinished,"A weapon swap must prevent later rounds from the old cast")
        local shots=0
        local firstHitAt=os.clock()+.08
        local pistolRecord={HealthDrops=0,Requested=0}
        local pistol=assert(loadstring(moduleSource))()({State={SkillHitRequests=0},Record=pistolRecord,Spacing=.24,Rounds=1,FirstHitAt=firstHitAt,
            Targets=function() return {mobs[2]} end,Valid=function(mob) return data[mob] end,CanRun=function() return true end,
            Send=function() assert(os.clock()>=firstHitAt,"Do not fire during windup"); shots+=1 end})
        pistol.Start(mobs[2],table.pack())
        task.wait(.025); assert(shots==0,"Wait for pistol readiness")
        local deadline=os.clock()+1
        repeat task.wait(.02) until pistolRecord.FinishedAt or os.clock()>deadline
        assert(shots==1 and pistolRecord.Desired==1 and pistolRecord.Status=="Skill shot sent","Pistol must complete cleanly after one valid shot")
        pistol.Finish()
        local rifleStart=os.clock()
        local rifleCalls,replacementCalls=0,0
        local rifleRecord={HealthDrops=0,Requested=0}
        local rifle=assert(loadstring(moduleSource))()({State={SkillHitRequests=0},Record=rifleRecord,Spacing=.02,Rounds=12,
            RepeatWindow=true,RefreshTargets=true,ExpiresAt=rifleStart+.16,
            Targets=function() return {mobs[2],mobs[3]} end,
            Valid=function(mob)
                if mob==mobs[2] and rifleCalls==0 then return data[mob] end
                if mob==mobs[3] and os.clock()-rifleStart>=.05 then return data[mob] end
            end,
            CanRun=function() return true end,
            Send=function(mob) assert(os.clock()<rifleStart+.16,"Stop shooting at window expiry"); rifleCalls+=1; if mob==mobs[3] then replacementCalls+=1 end end})
        rifle.Start(mobs[2],table.pack())
        local deadline=os.clock()+1
        repeat task.wait(.02) until rifleRecord.FinishedAt or os.clock()>deadline
        assert(rifleCalls>3 and replacementCalls>0 and rifleRecord.TargetCount==2,"Rifle must keep firing and acquire a replacement after an empty interval")
        rifle.Finish()
        return {Passed=true,Targets=record.TargetCount,Requests=record.TotalRequests,ObservedDamage=record.Damage,WeaponCancellation=true,PistolWindup=true,RifleRetargeting=true,RifleExpiry=true}
    end)
    api.Finish(); folder:Destroy()
    if not ok then error(result) end
    return result
end
