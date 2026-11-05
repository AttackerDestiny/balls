return function(source)
    local snapshot=assert(loadstring(source))()
    local old={UserId=1,Enabled=true,AutoFarm=true,UI={ActiveTab="Combat"},
        MultiSpotSelected={boss=true},SkillPerWeapon={Spear="Summon Pistol"},
        ResumeFeatures={Enabled=true},RuntimeFunction=function()end,
        EnemyRegistry={Models={{}}},Instance={}}
    local saved=snapshot(old,1)
    assert(saved.UserId==1 and saved.Enabled and saved.ActiveTab=="Combat"and saved.MultiSpotSelected.boss)
    assert(saved.MultiSpotSelected~=old.MultiSpotSelected and saved.ResumeFeatures~=old.ResumeFeatures)
    old.MultiSpotSelected.boss=nil;assert(saved.MultiSpotSelected.boss,"Old cleanup cannot mutate the new runtime's snapshot")
    assert(not saved.EnemyRegistry and not saved.RuntimeFunction and not saved.Instance and not saved.UI,"A reload cannot retain old controllers, functions or UI")
    assert(snapshot(old,2)==nil,"Account changes never import another user's runtime preferences")
    old.ResumeFeatures.Self=old.ResumeFeatures
    assert(snapshot(old,1).ResumeFeatures.Self==nil,"Cyclic config tables cannot recurse indefinitely")
    print("PASS Settings snapshots: independent same-account config, no retained runtime, account isolation and cycle bounds")
end
