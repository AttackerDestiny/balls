return function(source)
    local make=assert(loadstring(source))()
    local wave,left,enemyCount,wipe=99,1,0,false
    local rewards={}
    local ctx={Wave=function()return wave,left end,PartyDefeated=function()return wipe end,
        Chests=function()return rewards,enemyCount end,IsChest=function(name)return name=="Reward Chest"end}
    local retry=make(ctx)
    local chest,health={Name="Reward Chest"},{Value=1}
    local boss,bossHealth={Name="Rubricatus, The Sentinel of Order"},{Value=1}
    rewards[chest]=health
    assert(not retry.Update(0))
    health.Value=0;wave=100;left=0
    assert(not retry.Update(2),"A chest from the previous wave cannot count")
    enemyCount=1;left=2;health.Value=1
    retry.Observe(boss,bossHealth)
    assert(not retry.Update(3),"An active final boss prevents arming the chest")
    bossHealth.Value=0;health.Value=0;enemyCount=0;left=0
    assert(not retry.Update(4),"Final boss clearance without an observed final chest is insufficient")
    health.Value=1;left=1
    assert(not retry.Update(5),"Wait for the final chest to open")
    rewards[chest]=nil;left=0
    assert(not retry.Update(6),"Streaming out an unopened chest is insufficient")
    health.Value=0
    assert(not retry.Update(7) and retry.Update(8)=="Chest","Wait for collection to settle before retry")

    retry=make(ctx)
    bossHealth.Value=1
    retry.Observe(boss,bossHealth);bossHealth.Value=0;health.Value=1;left=1
    retry.Observe(chest,health);health.Value=0;left=0
    assert(not retry.Update(9) and retry.Update(10)=="Chest","A chest opened between polls is still recorded")

    retry=make(ctx)
    wave=51;wipe=true
    assert(not retry.Update(11))
    wipe=false;assert(not retry.Update(11.5),"A revived player cancels the pending wipe")
    wipe=true
    assert(not retry.Update(12))
    wave=nil
    assert(retry.Update(13)=="Wipe","Resetting the wave counter does not interrupt wipe confirmation")
    print("PASS Between Auto Retry: stable wipe, final chest, late and fast loot, streaming and settlement")
end
