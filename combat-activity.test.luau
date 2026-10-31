return function(source)
    local now=1
    local folder={}
    local mob={Parent=folder,Alive=true,Distance=10}
    local state={Running=true,Enabled=true,SkillAura=true,AutoRanges={Range=function()return 30 end}}
    local selfHealth={Value=100}
    local load=assert(loadstring(source));setfenv(load,setmetatable({state=state,indexedMobFolder=folder,
        os={clock=function()return now end},player={Character={FindFirstChild=function(_,name)
            if name=="Entity" then return {FindFirstChild=function()return selfHealth end}end
            return {}
        end}},
        validMob=function(target,parent)return target and target.Parent==parent and target.Alive and {} or nil end,
        getMobData=function()return {}end,attackRadiusFor=function()return 30 end,
        attackDeltaFor=function()return {Magnitude=mob.Distance}end},{__index=getfenv()}));load()
    assert(not state.IsAttackingEnemy(),"A target without an actual attack must not activate the buff")
    state.LastEnemyAttackAt=1;state.LastEnemyAttackKind="Normal";state.LastEnemyAttackTarget=mob
    assert(state.IsAttackingEnemy())
    now=2;assert(not state.IsAttackingEnemy(),"Stale attacks expire")
    now=1.1;mob.Alive=false;assert(not state.IsAttackingEnemy())
    mob.Alive=true;mob.Parent=nil;assert(not state.IsAttackingEnemy())
    mob.Parent=folder;mob.Distance=40;assert(not state.IsAttackingEnemy())
    mob.Distance=10;state.Enabled=false;assert(not state.IsAttackingEnemy())
    state.Enabled=true
    for _,flag in ipairs({"StopEverything","SafeModePanic","TravelBusy","MultiSpotOwnsTravel","Dodging","Recovering","ProtectionRetreating"})do
        state[flag]=true;assert(not state.IsAttackingEnemy());state[flag]=false
    end
    state.LastEnemyAttackKind="Skill";assert(state.IsAttackingEnemy())
    state.SkillAura=false;assert(not state.IsAttackingEnemy())
    state.SkillAura=true;selfHealth.Value=0;assert(not state.IsAttackingEnemy())
    print("PASS Live-enemy attack activity gate")
end
