-- Supplied-source activation: activate once and keep the skill name active
-- for its duration. Damage uses the same per-target cooldown as Kill Aura.
return function(ctx)
    local api={}
    local windows={['Sweeping Strike']=1.4,['Downward Smash']=1,['Leaping Slash']=1.8,['Piercing Dash']=1,['Beam Rush']=2.8,
        ['Whirlwind Spin']=1,['Reaper Frenzy']=3.5,['Infinity Slash']=1,['Summon Pistol']=.2,['Meteor Shot']=1,
        ['Everfrost Strike']=1.5,['Cursed Three Fold Slash']=3.3,['Water Blast']=1.2,['Spearitual Strike']=1,
        ['Summon Rifle']=3,['Summon Minigun']=3}
    local retry={}
    local gunProfiles={['Summon Pistol']={FirstHitDelay=0},['Summon Rifle']={FirstHitDelay=0}}
    local owner
    local clock=ctx.Clock or os.clock
    local wait=ctx.Wait or task.wait
    function api.Window(name) return windows[name] or (ctx.ResolveWindow and ctx.ResolveWindow(name)) end
    function api.Profile(name) return gunProfiles[name] end
    function api.CanHandle(name) return api.Window(name)~=nil and clock()>=(retry[name] or 0) end
    function api.Reset() table.clear(retry) end
    function api.Begin(name,definition,entity,root,current,onEmit,aimDirection)
        if not api.CanHandle(name) then return false,"Waiting for a supported activation window" end
        local function valid() return ctx.CanRun() and (not current or current()) end
        if not valid() then return false,"Cast interrupted" end
        if ctx.Skills.usingSkill and ctx.Skills.usingSkill~="none" then return false,"Another skill is active" end
        if ctx.Skills.GetCooldown(name)<0 then return false,"Waiting for cooldown" end
        local stamina=entity:FindFirstChild("Stamina")
        local cost=definition.Cost.Value
        if not stamina or stamina.Value<cost then return false,"Waiting for stamina" end
        local buffs=entity:FindFirstChild("Buffs")
        local reduction=buffs and buffs:FindFirstChild("SkillReduction")
        local cooldown=definition.Cooldown.Value*math.clamp(1-(reduction and reduction.Value or 0),0,1)
        local before=stamina.Value
        local profile=gunProfiles[name]
        local started=clock()
        local lease={Name=name,Started=started,ExpiresAt=started+api.Window(name),
            FirstHitAt=started+(profile and profile.FirstHitDelay or 0),SourceWindow=true,
            HoldWindow=true,RefreshTargets=true,MinimumInterval=.3}
        owner=lease
        ctx.Skills.usingSkill=name
        ctx.Skills.SetCooldown(name,cooldown)
        pcall(ctx.SkillUsed,name,cooldown)
        local direction=typeof(aimDirection)=="Vector3" and aimDirection.Magnitude>.001 and aimDirection.Unit or root.CFrame.LookVector
        lease.Direction=direction
        ctx.Emit(name,{Direction=direction})
        ctx.State.SkillActiveUntil=lease.ExpiresAt
        if onEmit then onEmit(lease) end
        local deadline=clock()+math.clamp(.35+(ctx.State.PingMs or 100)/500,.4,1.2)
        repeat
            if cost<=0 or before-stamina.Value>=math.max(1,cost*.5) then
                return true,nil,lease
            end
            if not stamina.Parent or not root.Parent or not valid() then return false,"Cast interrupted" end
            wait(.02)
        until clock()>=deadline
        retry[name]=clock()+2
        return false,"Skill start not acknowledged; retrying after cooldown"
    end
    function api.Release(name)
        if owner and (not name or name==owner.Name) then
            if ctx.Skills.usingSkill==owner.Name then ctx.Skills.usingSkill="none" end
            owner=nil
        end
    end
    function api.Result(name,damage,requests)
        ctx.State.LastSkillActivationResult={Name=name,Damage=damage,Requests=requests}
    end
    return api
end
