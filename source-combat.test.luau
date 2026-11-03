-- Pure Luau doubles: no client, remotes, inventory changes or live combat.
return function(schedulerSource,burstSource,activationSource,budgetSource,updateSource)
    local function load(source,env)
        local fn=assert(loadstring(source));setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn()
    end
    local function fixture(frame)
        local f={Now=0,Calls={},Data={},Folder={},State={Enabled=true,SkillHitRequests=0,HitsSent=0,FrameRequestCap=4}}
        f.Env={os={clock=function()return f.Now end},task={spawn=function(fn)fn()end,wait=function(dt)
            f.Now+=math.max(dt,frame or 0);if f.OnWait then f.OnWait()end
        end}}
        function f.Mob(name,hp)
            local mob={Name=name,Parent=f.Folder}
            local health={Value=hp or 1000000,Listeners=0}
            function health:GetPropertyChangedSignal()
                return {Connect=function(_,fn)
                    health.Listeners+=1;local alive=true
                    return {Disconnect=function()if alive then alive=false;health.Listeners-=1 end end}
                end}
            end
            f.Data[mob]={Health=health,Entity={FindFirstChild=function()end}}
            return mob
        end
        f.Pacing=load(schedulerSource,f.Env)(f.State)
        f.Pacing.Bind({GetData=function(mob)return f.Data[mob]end,Radius=function()return 30 end,
            Delta=function()return {Dot=function()return 1 end}end,
            Damage=function(mob)table.insert(f.Calls,{Mob=mob,At=f.Now,Kind="Normal"})end,
            Sent=function()f.State.HitsSent+=1 end,Visual=function()end})
        function f.Window(targets,duration,options)
            local record={HealthDrops=0}
            local args={State=f.State,Record=record,SourceWindow=true,Pacing=f.Pacing,Spacing=.3,
                RefreshTargets=true,ExpiresAt=f.Now+duration,Targets=function()return targets end,
                Valid=function(mob)return f.Data[mob]and f.Data[mob].Health.Value>0 and f.Data[mob]end,
                CanRun=function()return not f.State.AutoTradeBusy and not f.State.SafeModePanic and not f.State.Dodging end,
                Send=function(mob)
                    table.insert(f.Calls,{Mob=mob,At=f.Now,Kind="Skill"})
                    if f.OnSend then f.OnSend(mob)end
                end}
            for key,value in pairs(options or {})do args[key]=value end
            local api=load(burstSource,f.Env)(args)
            f.Burst=api
            assert(api.Start(targets[1]));assert(not api.Start(targets[1]),"One cast cannot start twice")
            api.Finish();return record
        end
        return f
    end
    local f=fixture();local a,b=f.Mob("A"),f.Mob("B")
    f.Pacing.Update(0,{a,b},{},f.Folder)
    assert(#f.Calls==2,"The source attacks each nearby mob independently")
    f.Now=.1;f.Pacing.Update(f.Now,{a,b},{},f.Folder);assert(#f.Calls==2)
    f.Pacing.Cancel();f.Now=.2;f.Pacing.Update(f.Now,{a,b},{},f.Folder);assert(#f.Calls==2,"Pause cannot erase a hit cooldown")
    f.Now=.301;f.Pacing.Update(f.Now,{a,b},{},f.Folder);assert(#f.Calls==4)
    f.Now=20;f.Pacing.Update(f.Now,{a,b},{},f.Folder);assert(#f.Calls==6,"A long frame cannot replay missed hits")
    f.State.SkillWantsWindow=true;f.Now=21;f.Pacing.Update(f.Now,{a,b},{},f.Folder);assert(#f.Calls==6)
    f.State.SkillWantsWindow=false;f.State.Enabled=false;f.State.SkillRegistrationTarget=b
    f.Pacing.Update(f.Now,{a,b},{},f.Folder);assert(#f.Calls==7 and f.Calls[7].Mob==b,"Skill-only mode registers just its target")
    for _,key in ipairs({"StopEverything","SafeModePanic","ModeratorBlocking","AutoTradeBusy"})do
        f.State[key]=true;f.Now+=1;f.Pacing.Update(f.Now,{a,b},{},f.Folder);assert(#f.Calls==7,key);f.State[key]=false
    end
    f=fixture();a=f.Mob("Shared timer")
    f.Pacing.Update(0,{a},{},f.Folder)
    f.Window({a},.2);assert(#f.Calls==1,"A skill cannot bypass the normal hit's timer")
    f.Now=.301;f.Window({a},.2);assert(#f.Calls==2 and f.Calls[2].Kind=="Skill","Source pistol-sized window can fire immediately when ready")
    f.Pacing.Update(f.Now,{a},{},f.Folder);assert(#f.Calls==2,"Normal hits cannot bypass the skill hit's timer")
    for _,frame in ipairs({1/60,1/15,1/10,.4})do
        f=fixture(frame);a=f.Mob("Window")
        local record=f.Window({a},1.4)
        assert(#f.Calls>0 and record.FinishedAt and f.Data[a].Health.Listeners==0)
        if frame==1/60 then assert(#f.Calls==5,"A 1.4s source window must not stop at three rounds")end
        for i,call in ipairs(f.Calls)do
            assert(call.At<1.4,"No damage after the activation window")
            if i>1 then assert(call.At-f.Calls[i-1].At>=.3-1e-6,"Never catch up with duplicate hits at low FPS")end
        end
    end
    f=fixture();local many={}
    for i=1,12 do many[i]=f.Mob("Mob"..i)end
    f.State.FrameRequestCap=2;f.Window(many,.29)
    local perTime={};local seen={}
    for _,call in ipairs(f.Calls)do perTime[call.At]=(perTime[call.At]or 0)+1;seen[call.Mob]=true end
    local count=0;for _ in pairs(seen)do count+=1 end
    assert(count==12,"Frame batching must reach all eligible nearby targets without the old eight-target cap")
    for _,value in pairs(perTime)do assert(value<=2,"Respect the mobile frame request cap")end
    for _,key in ipairs({"AutoTradeBusy","SafeModePanic","Dodging","StopEverything"})do
        f=fixture();a=f.Mob(key);f.OnWait=function()f.State[key]=true end
        f.Window({a},1);assert(#f.Calls==1 and f.Data[a].Health.Listeners==0,"Cancel promptly and disconnect observers: "..key)
    end
    f=fixture();a=f.Mob("Weapon changed")
    f.OnWait=function()f.Burst.Cancel("Weapon changed")end
    local cancelled=f.Window({a},1)
    assert(#f.Calls==1 and cancelled.Status=="Weapon changed"and f.Data[a].Health.Listeners==0)
    f=fixture();a=f.Mob("150k",150000);b=f.Mob("Next mob",400000)
    local budget=load(budgetSource)()
    f.OnWait=function()if f.Now>=.15 then f.Data[a].Health.Value=0 end end
    f.Window({a,b},1,{Budget=budget,EstimateDamage=function()return 159000 end})
    local first=0;for _,call in ipairs(f.Calls)do if call.Mob==a then first+=1 end end
    assert(first==1,"Do not waste later skill hits on a lethal 159k reservation")

    local time,untilTime,calls=0,0,0
    local stamina={Value=100,Parent=true}
    local entity={FindFirstChild=function(_,name)if name=="Stamina"then return stamina end end}
    local root={Parent=true,CFrame={LookVector={}}}
    local skills={usingSkill="none",GetCooldown=function()return time-untilTime end,SetCooldown=function(_,cd)untilTime=time+cd end}
    local acknowledge=true
    local activation=load(activationSource,{typeof=type})({State={},Skills=skills,Clock=function()return time end,
        Wait=function(dt)time+=dt end,CanRun=function()return true end,SkillUsed=function()end,
        Emit=function()calls+=1;if acknowledge then stamina.Value-=35 end end})
    local definition={Cost={Value=35},Cooldown={Value=4}}
    local ack,_,lease=activation.Begin("Summon Pistol",definition,entity,root)
    assert(ack and lease.SourceWindow and lease.ExpiresAt==.2 and lease.FirstHitAt==0,"Use the source's exact 0.2s Pistol window")
    assert(not activation.Begin("Summon Pistol",definition,entity,root)and calls==1,"Do not duplicate a cast")
    activation.Release();assert(not activation.Begin("Summon Pistol",definition,entity,root)and calls==1,"Respect native cooldown")
    time=5;stamina.Value=5;assert(not activation.Begin("Summon Pistol",definition,entity,root)and calls==1,"Respect stamina")
    stamina.Value=100;acknowledge=false
    assert(not activation.Begin("Beam Rush",definition,entity,root));activation.Release()
    assert(not activation.CanHandle("Beam Rush"),"Back off after a missing native acknowledgment")

    -- Run the actual adapter selection path up to its shared hit timer.
    local state={Running=true,SkillAura=true,SelectedSkill="Summon Pistol",LagPauseUntil=0,
        WeaponSkills={Ready=true,Version=1,IsCompatible=function()return true end},
        SkillActivation={Profile=function()end,CanHandle=function()return true end},
        AutoRanges={Range=function()return 30 end}}
    local hp={Value=100};local mob={Name="Unregistered"};local credit
    state.ReadOwnDamage=function()return credit end
    local entity={FindFirstChild=function()return hp end}
    local root={}
    local update=load("local nextSkillCheck=0\nlocal skillThread\n"..updateSource.."\nreturn updateSkillAura",{
        state=state,os={clock=function()return time end},player={Character={FindFirstChild=function(_,name)return name=="Entity"and entity or root end}},
        Skills={usingSkill="none",GetCooldown=function()return 0 end,HasStamina=function()return true end},
        ReplicatedStorage={Database={Skills={FindFirstChild=function()return definition end}}},
        GameUI={IsSkillValid=function()return true end,IsMenuOpen=function()return false end},CanRunSkill=function()return true end,
        refreshMobIndex=function()return {}end,trackedMobs={[mob]=true},validMob=function()return root end,
        getMobData=function()return {Health=hp}end,attackDeltaFor=function()return {Magnitude=1}end,
        normalScheduler={Ready=function()return false end}})
    update();assert(state.SkillRegistrationTarget==mob and not state.SkillWantsWindow,"Register enemy damage before casting, as in the source")
    credit=0;time+=1;update();assert(not state.SkillRegistrationTarget and state.SkillPreparing,"An existing zero-valued own-damage counter satisfies registration")
    print("PASS Source aura: independent/shared cooldowns, active windows, registration, low FPS, frame caps, cancellation, overkill, cooldown/stamina acknowledgment and cleanup")
end
