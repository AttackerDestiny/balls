-- A retry needs a stable party wipe or an observed final chest breaking.
return function(ctx)
    local wipeAt,ready,started
    local chests={}
    local bossHealth
    local api={}
    function api.Observe(mob,health)
        if ready then return end
        local name=mob.Name
        if name=="Rubricatus, The Sentinel of Order" then
            if ctx.Wave()==100 then bossHealth=health end
        elseif health.Value>0 and not chests[mob] and ctx.IsChest(name) then
            if bossHealth and bossHealth.Value<=0 and ctx.Wave()==100 then
                chests[mob]={Health=health}
            end
        end
    end
    function api.Update(now)
        if ready then return ready end
        local wave,mobsLeft=ctx.Wave()
        started=started or (type(wave)=="number" and wave>=1)
        if not started then return end
        if ctx.PartyDefeated() then
            wipeAt=wipeAt or now
            if now-wipeAt>=1 then ready="Wipe";return ready end
        else
            wipeAt=nil
        end
        if wave~=100 then return end
        local rewards,enemyCount=ctx.Chests()
        if not bossHealth or bossHealth.Value>0 or enemyCount>0 then return end
        local count=0
        for chest,health in pairs(rewards)do
            if health.Value>0 then count+=1 end
        end
        -- The final boss must have cleared before admitting the remaining chest mobs.
        if type(mobsLeft)=="number" and mobsLeft<=count then
            for chest,health in pairs(rewards)do
                if health.Value>0 and not chests[chest] then chests[chest]={Health=health} end
            end
        end
        if next(chests)==nil or count>0 or (mobsLeft~=nil and mobsLeft~=0) then return end
        for _,receipt in pairs(chests)do
            if receipt.Health.Value>0 then return end
            receipt.At=receipt.At or now
            if now-receipt.At<1 then return end
        end
        ready="Chest"
        return ready
    end
    return api
end
