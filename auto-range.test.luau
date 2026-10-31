return function(moduleSource)
    local create=assert(loadstring(moduleSource))()
    local now=100
    local small={Root={Size=Vector3.new(8,10,6),Position=Vector3.zero}}
    local large={Root={Size=Vector3.new(240,80,100),Position=Vector3.zero}}
    local other={Root={Size=Vector3.new(80,40,30),Position=Vector3.zero}}
    local state={Radius=30,SkillRange=30,SelectedSkill="Piercing Dash"}
    local api=create({State=state,Clock=function() return now end,PrimaryData=function() return large end,
        SetKill=function(v) state.Radius=v end,SetSkill=function(v) state.SkillRange=v end})
    assert(api.Range("Kill",small)==24 and api.Range("Kill",large)==120,"Source body-size reach must obey the new 120 cap")
    api.Record("Kill",18,100,small)
    api.Record("Kill",23,0,small); api.Record("Kill",23.5,0,small)
    assert(api.Range("Kill",small)==20,"Repeated misses at the edge must contract only that target")
    assert(api.Range("Kill",large)==120 and api.Range("Kill",other)==60,"A small mob must not shrink a boss or another mob")
    assert(api.Range("Skill",small,"Piercing Dash")==24,"Kill misses must not poison skill range")
    api.Record("Skill",17,300,small,"Piercing Dash")
    api.Record("Skill",23,0,small,"Piercing Dash"); api.Record("Skill",23,0,small,"Piercing Dash")
    assert(api.Range("Skill",small,"Piercing Dash")==20 and api.Range("Skill",small,"Beam Rush")==24,"Skills need separate observations")
    for _=1,4 do api.Record("Kill",5,0,other) end
    assert(api.Range("Kill",other)==60,"Close misses must not be mistaken for distance rejection")
    local below={Size=Vector3.new(2,2,1),Position=Vector3.new(0,-30,0)}
    assert(api.Delta(small,below).Magnitude==26 and api.Delta(small,below).Magnitude>api.Range("Skill",small,"Beam Rush"),"Vertical skill range must use corrected 3D distance, not half height")
    below.Position=Vector3.new(0,-18,0)
    assert(api.Delta(small,below).Magnitude==14,"Below-mob range must include the source height correction")
    local motion=Instance.new("BodyVelocity")
    motion.Velocity=Vector3.new(10,0,0)
    small.Root=Instance.new("Part"); small.Root.Size=Vector3.new(8,10,6); small.Root.Position=Vector3.zero
    motion.Parent=small.Root; small.Motion=motion
    assert(api.Delta(small,below).X==1,"Moving mobs get the source one-stud lead using the correct velocity property")
    small.Root:Destroy()
    api.Update()
    assert(state.Radius==120 and state.SkillRange==120,"HUD must show the current target reach with the 120 cap")
    now+=13
    assert(api.Range("Kill",small)==24,"Stale misses cannot hold a reduced range down permanently")
    return {Passed=true,IndependentTargets=true,IndependentSkills=true,HeightCorrected=true,Cap=120}
end
