-- Activation owns one native skill lease until explicit release.
return function(ctx)
    local api={}
    local durations={['Sweeping Strike']=1.4,['Downward Smash']=1,['Leaping Slash']=1.8,['Piercing Dash']=1,
        ['Beam Rush']=2.8,['Whirlwind Spin']=1,['Reaper Frenzy']=3.5,['Infinity Slash']=1,['Summon Pistol']=.2,
        ['Meteor Shot']=1,['Everfrost Strike']=1.5,['Cursed Three Fold Slash']=3.3,['Water Blast']=1.2,
        ['Spearitual Strike']=1,['Summon Rifle']=3,['Summon Minigun']=3}
    local profiles={['Summon Pistol']={FirstHitDelay=0},['Summon Rifle']={FirstHitDelay=0}}
    local cooldowns={}
    local lease
    local clock=ctx.Clock or os.clock
    local wait=ctx.Wait or task.wait
    function api.Window(name)return durations[name]or (ctx.ResolveWindow and ctx.ResolveWindow(name))end
    function api.Profile(name)return profiles[name]end
    function api.CanHandle(name)return api.Window(name)~=nil and clock()>=(cooldowns[name]or 0)end
    function api.Reset()table.clear(cooldowns)end
    local function permitted(current)return ctx.CanRun()and (not current or current())end
    function api.Release(name)
        if not lease or (name and name~=lease.Name)then return end
        if ctx.Skills.usingSkill==lease.Name then ctx.Skills.usingSkill="none"end
        lease=nil
    end
    function api.Result(name,damage,requests)ctx.State.LastSkillActivationResult={Name=name,Damage=damage,Requests=requests}end
    local function resources(name,definition,entity)
        if ctx.Skills.usingSkill and ctx.Skills.usingSkill~="none"then return nil,"Another skill is active"end
        if ctx.Skills.GetCooldown(name)<0 then return nil,"Waiting for cooldown"end
        local stamina=entity:FindFirstChild("Stamina")
        if not stamina or stamina.Value<definition.Cost.Value then return nil,"Waiting for stamina"end
        local buffs=entity:FindFirstChild("Buffs")
        local reduction=buffs and buffs:FindFirstChild("SkillReduction")
        return {Stamina=stamina,Before=stamina.Value,Cost=definition.Cost.Value,
            Cooldown=definition.Cooldown.Value*math.clamp(1-(reduction and reduction.Value or 0),0,1)}
    end
    function api.Begin(name,definition,entity,root,current,onEmit,aim)
        if not api.CanHandle(name)then return false,"Waiting for a supported activation window"end
        if not permitted(current)then return false,"Cast interrupted"end
        local budget,reason=resources(name,definition,entity)
        if not budget then return false,reason end
        local started=clock()
        local direction=typeof(aim)=="Vector3"and aim.Magnitude>.001 and aim.Unit or root.CFrame.LookVector
        lease={Name=name,Started=started,ExpiresAt=started+api.Window(name),FirstHitAt=started+(profiles[name]and profiles[name].FirstHitDelay or 0),
            SourceWindow=true,HoldWindow=true,RefreshTargets=true,MinimumInterval=.3,Direction=direction}
        local emitted=lease
        ctx.Skills.usingSkill=name;ctx.Skills.SetCooldown(name,budget.Cooldown)
        pcall(ctx.SkillUsed,name,budget.Cooldown)
        ctx.Emit(name,{Direction=direction});ctx.State.SkillActiveUntil=emitted.ExpiresAt
        if onEmit then onEmit(emitted)end
        local expires=clock()+math.clamp(.35+(ctx.State.PingMs or 100)/500,.4,1.2)
        while true do
            if budget.Cost<=0 or budget.Before-budget.Stamina.Value>=math.max(1,budget.Cost*.5)then return true,nil,emitted end
            if not budget.Stamina.Parent or not root.Parent or not permitted(current)then return false,"Cast interrupted"end
            wait(.02)
            if clock()>=expires then break end
        end
        cooldowns[name]=clock()+2
        return false,"Skill start not acknowledged; retrying after cooldown"
    end
    return api
end
