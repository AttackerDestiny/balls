return function(moduleSource)
    local folder=Instance.new("Folder")
    local targets,data,sent={},{},{}
    for i=1,2 do
        local mob=Instance.new("Model",folder); mob.Name="Fixture"..i
        local root=Instance.new("Part",mob); root.Position=Vector3.new(i,0,0)
        local entity=Instance.new("Folder",mob)
        local health=Instance.new("NumberValue",entity); health.Value=1000
        targets[i]=mob; data[mob]={Root=root,Entity=entity,Health=health,RegisteredDamage=true}; sent[mob]=0
    end
    local state={Threat=3,AttackInterval=.04,MaxRequestsPerSecond=60,PingMs=0,BurstsSent=0,AttackBurstHistory={},HitsSent=0}
    local api=assert(loadstring(moduleSource))()(state)
    local roll=100
    api.Bind({GetData=function(m) return data[m] end,Radius=function() return 20 end,
        RandomInteger=function() return roll end,
        Damage=function(m) sent[m]+=1; data[m].Health.Value-=10 end,
        Sent=function() state.HitsSent+=1 end,Visual=function() end})
    local ok,result=pcall(function()
        local d=data[targets[1]]
        roll=1; assert(api.SelectThreat(d,1,20)==1,"Stable auto threat must allow one hit")
        roll=30; assert(api.SelectThreat(d,1,20)==2,"Stable auto threat must allow two hits")
        roll=100; assert(api.SelectThreat(d,1,20)==3,"Stable auto threat must allow three hits")
        d.RegisteredDamage=false
        assert(api.SelectThreat(d,1,20)==1,"New targets need a registration hit first")
        d.RegisteredDamage=true; d.AttackBackoff=2
        assert(api.SelectThreat(d,1,20)==1,"Missed attacks must favor short bursts")
        d.AttackBackoff=1; state.PingMs=460
        assert(api.SelectThreat(d,1,20)==1,"Lag must cap the burst")
        state.PingMs=400
        assert(api.SelectThreat(d,1,20)==2,"High ping must limit the burst to two")
        state.PingMs=0
        assert(api.SelectThreat(d,19,20)==1,"Boundary targets need a short burst")
        d.HitLives={Value=2}
        assert(api.SelectThreat(d,1,20)==2,"HitLives must limit requests")
        d.HitLives=nil; d.NormalDamagePerHit=1200
        assert(api.SelectThreat(d,1,20)==1,"Do not request three hits when one will finish the mob")
        d.NormalDamagePerHit=nil
        local now=os.clock()
        api.Update(now,targets,{Position=Vector3.zero},folder)
        assert(sent[targets[1]]==1 and sent[targets[2]]==1,"Both nearby targets need independent hit timers")
        api.Update(now+.1,targets,{Position=Vector3.zero},folder)
        assert(state.HitsSent==2,"Per-target cooldown must prevent duplicate early hits")
        state.SkillWantsWindow=true
        api.Update(now+.25,targets,{Position=Vector3.zero},folder)
        api.Update(now+.5,targets,{Position=Vector3.zero},folder)
        assert(sent[targets[1]]==3 and sent[targets[2]]==3,"Existing bursts must finish while skill waits")
        api.Update(now+.8,targets,{Position=Vector3.zero},folder)
        assert(state.HitsSent==6 and not state.AttackBurstActive,"Skill window must prevent new normal bursts")
        state.SkillWantsWindow=false
        api.Update(now+1.1,targets,{Position=Vector3.zero},folder)
        data[targets[1]].Root.Position=Vector3.new(100,0,0)
        data[targets[2]].Root.Position=Vector3.new(100,0,0)
        api.Update(now+1.2,{}, {Position=Vector3.zero},folder)
        api.Update(now+1.7,{}, {Position=Vector3.zero},folder)
        assert(not state.AttackBurstActive,"Lost targets must release the skill window")
        data[targets[1]].Root.Position=Vector3.zero; data[targets[2]].Root.Position=Vector3.zero
        api.Update(now+2.1,targets,{Position=Vector3.zero},folder)
        assert(state.AttackBurstActive,"Start a fresh normal burst")
        local beforeReady=state.HitsSent
        state.SkillWantsWindow=true; api.Cancel("Handing off to ready skill")
        api.Update(now+2.4,targets,{Position=Vector3.zero},folder)
        assert(not state.AttackBurstActive and state.HitsSent==beforeReady,"A ready skill must preempt queued normals without adding damage requests")
        state.ReserveGunStamina=true
        api.Update(now+3,targets,{Position=Vector3.zero},folder)
        assert(state.HitsSent==beforeReady+1 and state.CurrentThreat==1,"Keep one basic hit flowing while recovering gun stamina")
        api.Update(now+3.1,targets,{Position=Vector3.zero},folder)
        assert(state.HitsSent==beforeReady+1,"Stamina pacing must not flood basic requests")
        api.Update(now+3.55,targets,{Position=Vector3.zero},folder)
        assert(state.HitsSent==beforeReady+2,"Continue light basic attacks during stamina recovery")
        state.ReserveGunStamina=false
        api.Update(now+4,targets,{Position=Vector3.zero},folder)
        assert(state.HitsSent==beforeReady+2,"Release all basic requests when the ready skill takes ownership")
        return {Passed=true,IndependentTargets=2,RequestsBeforeSkill=6,ReadySkillPreemption=true,StaminaPacing=true}
    end)
    api.Destroy(); folder:Destroy()
    if not ok then error(result) end
    return result
end
