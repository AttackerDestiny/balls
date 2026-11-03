-- Optional Studio fixture; the pure offline counterpart is source-combat.test.
return function(moduleSource)
    local folder=Instance.new("Folder")
    local targets,data,sent={},{},{}
    for i=1,2 do
        local mob=Instance.new("Model",folder);mob.Name="Fixture"..i
        local root=Instance.new("Part",mob);root.Position=Vector3.new(i,0,0)
        local entity=Instance.new("Folder",mob)
        local health=Instance.new("NumberValue",entity);health.Value=1000
        targets[i]=mob;data[mob]={Root=root,Entity=entity,Health=health};sent[mob]=0
    end
    local state={Enabled=true,AttackInterval=.3,HitsSent=0}
    local api=assert(loadstring(moduleSource))()(state)
    api.Bind({GetData=function(mob)return data[mob]end,Radius=function()return 20 end,
        Damage=function(mob)sent[mob]+=1 end,Sent=function()state.HitsSent+=1 end,Visual=function()end})
    local ok,result=pcall(function()
        local now=os.clock()
        api.Update(now,targets,{Position=Vector3.zero},folder)
        assert(sent[targets[1]]==1 and sent[targets[2]]==1)
        api.Update(now+.1,targets,{Position=Vector3.zero},folder);assert(state.HitsSent==2)
        api.Update(now+.301,targets,{Position=Vector3.zero},folder);assert(state.HitsSent==4)
        state.SkillWantsWindow=true
        api.Update(now+1,targets,{Position=Vector3.zero},folder);assert(state.HitsSent==4)
        state.SkillWantsWindow=false
        api.Mark(targets[1],now+1)
        api.Update(now+1.1,targets,{Position=Vector3.zero},folder)
        assert(sent[targets[1]]==2 and sent[targets[2]]==3,"The skill and normal scheduler share per-target hit timers")
        data[targets[1]].Health.Value=0;data[targets[2]].Root.Position=Vector3.new(100,0,0)
        api.Update(now+2,targets,{Position=Vector3.zero},folder);assert(state.HitsSent==5)
        api.Cancel();assert(not state.AttackBurstActive)
        return {Passed=true,IndependentTargets=true,SharedSkillCooldown=true,NativeRangeAndHealth=true}
    end)
    api.Destroy();folder:Destroy()
    if not ok then error(result)end
    return result
end
