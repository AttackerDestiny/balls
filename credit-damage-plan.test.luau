return function(planSource,creditSource)
    local make=assert(loadstring(planSource))()
    local planner=make()
    local kind,plan=planner.Choose(300000,50000,250000,true,true)
    assert(kind=="Skill"and plan.Skill==1 and plan.Normal==1 and plan.Damage==300000)
    kind,plan=planner.Choose(50000,50000,250000,true,true)
    assert(kind=="Normal"and plan.Skill==0 and plan.Normal==1,"Use the small normal hit instead of another large skill")
    kind,plan=planner.Choose(300000,50000,350000,true,true)
    assert(kind=="Normal"and plan.Excess==0,"Avoid a larger skill when normals reach the threshold precisely")
    kind,plan=planner.Choose(300000,50000,250000,false,true)
    assert(kind=="Skill"and plan.Skill==2 and plan.Normal==0,"Never enable a disabled aura to satisfy a plan")
    assert(planner.Choose(100,0,0,true,true)=="Normal","Unknown normal damage requires calibration")
    assert(planner.Choose(100,50,0,true,true)=="Skill","Probe an unknown usable skill only after learning normal damage")
    planner.Learn("Normal:v1:Boss",50000);planner.Learn("Normal:v1:Boss",100000)
    assert(planner.Estimate("Normal:v1:Boss")==50000 and planner.Estimate("Normal:v2:Boss")==0,"Critical hits cannot replace the lower observed estimate and weapon changes invalidate estimates")

    local now,own,other=0,0,0
    local me,peer={Name="Me"},{Name="Peer"}
    local mob={};local data={}
    local state={CreditCheck=true,PingMs=100}
    local api=assert(loadstring(creditSource))()({State=state,Planner=planner,Rank=function()return 1 end,Now=function()return now end,
        Self=function()return me end,Members=function()return {me,peer}end,
        MaxHealth=function()return 6000000 end,Damage=function(_,p)return p==me and own or other end,
        Options=function()return {NormalKey="Normal:v1:Boss",SkillKey="Skill:v1:Boss",CanNormal=true,CanSkill=true}end})
    planner.Learn("Skill:v1:Boss",250000)
    assert(api.AllowAction(mob,data,"Skill")and not api.AllowAction(mob,data,"Normal"))
    api.Sent(mob,data,"Skill")
    assert(not api.AllowAction(mob,data,"Skill")and api.ActionReason=="Waiting","An in-flight hit must not end the skill window before credit replicates")
    own=250000
    assert(not api.AllowAction(mob,data,"Skill")and api.ActionReason=="Normal")
    assert(api.AllowAction(mob,data,"Normal"));api.Sent(mob,data,"Normal")
    own=300000
    assert(not api.AllowAction(mob,data,"Skill")and api.ActionReason=="Qualified")
    assert(not api.AllowAction(mob,data,"Normal"),"Pause both damage modes while peers need credit")
    other=300000
    assert(api.AllowAction(mob,data,"Skill")and api.AllowAction(mob,data,"Normal"),"Once everyone qualifies, all damage modes are unrestricted")
    -- Learn a first normal hit from replicated contribution, not total mob HP loss.
    planner=make();own=0;other=0
    api=assert(loadstring(creditSource))()({State=state,Planner=planner,Rank=function()return 1 end,Now=function()return now end,
        Self=function()return me end,Members=function()return {me,peer}end,
        MaxHealth=function()return 6000000 end,Damage=function(_,p)return p==me and own or other end,
        Options=function()return {NormalKey="n",SkillKey="s",CanNormal=true,CanSkill=true}end})
    assert(api.AllowAction(mob,data,"Normal"));api.Sent(mob,data,"Normal")
    own=50000;api.Observe(mob,data)
    assert(planner.Estimate("n")==50000 and api.AllowAction(mob,data,"Skill"))
    -- One whole skill can contain several smaller damage ticks.
    own,other=0,0;planner=make();planner.Learn("n",50000);planner.Learn("cast",250000)
    local active=false
    api=assert(loadstring(creditSource))()({State=state,Planner=planner,Rank=function()return 1 end,Now=function()return now end,
        Self=function()return me end,Members=function()return {me,peer}end,
        MaxHealth=function()return 6000000 end,Damage=function(_,p)return p==me and own or other end,
        Options=function()return {NormalKey="n",SkillKey="tick",CastKey="cast",CanNormal=true,CanSkill=true,ActiveSkill=active}end})
    assert(api.AllowAction(mob,data,"SkillStart"))
    active=true
    for i=1,5 do
        assert(api.AllowAction(mob,data,"Skill"));api.Sent(mob,data,"Skill");own+=50000
    end
    assert(own==250000 and not api.AllowAction(mob,data,"Skill")and api.ActionReason=="Normal")
    active=false;assert(api.AllowAction(mob,data,"Normal"));api.Sent(mob,data,"Normal");own+=50000
    assert(not api.AllowAction(mob,data,"Normal"));other=300000;assert(api.AllowAction(mob,data,"Skill"))
    print("PASS Credit damage planning: 250k skill + 50k normal, minimal excess, disabled modes, observed damage, weapon keys, acknowledgment and unrestricted group finish")
end
