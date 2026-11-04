return function(source,schedulerSource,skillSendSource)
    local make=assert(loadstring(source))()
    local me,other,third={Name="Me"},{Name="Other"},{Name="Third"}
    local members={me,other}
    local now=0
    local state={CreditCheck=true,PingMs=100}
    local mob={Rank=1};local data={Max=1000,Damage={[me]=0,[other]=0}}
    local api=make({State=state,Now=function()return now end,Rank=function(m)return m.Rank end,Self=function()return me end,
        Members=function()return members end,MaxHealth=function(d)return d.Max end,Damage=function(d,p)return d.Damage[p]end})
    assert(api.Allow(mob,data));api.Sent(mob,data)
    assert(not api.Allow(mob,data),"Normal and skill send paths must share one in-flight credit hit")
    data.Damage[me]=49;assert(api.Allow(mob,data));api.Sent(mob,data)
    data.Damage[me]=50;assert(not api.Allow(mob,data),"Pause exactly at 5% of maximum HP")
    data.Max=1000;data.Damage[other]=49;assert(not api.Allow(mob,data),"Do not use remaining HP or another account's partial credit")
    data.Damage[other]=50;assert(api.Allow(mob,data),"Finish only after everyone qualifies")
    members={me,other,third};assert(not api.Allow(mob,data),"A newly present whitelisted member must qualify")
    members={me,other};assert(api.Allow(mob,data),"A departed member cannot stall the current server")
    state.CreditCheck=false;assert(api.Allow(mob,data));state.CreditCheck=true
    mob.Rank=3;data.Max=nil;assert(api.Allow(mob,data),"Regular mobs are unaffected")
    mob.Rank=2;assert(not api.Allow(mob,data),"Missing max HP must not guess a threshold")
    data.Max=1000;data.Damage[me]=0;data.Damage[other]=0;api.Reset()
    assert(api.Allow(mob,data));api.Sent(mob,data);now=1;assert(api.Allow(mob,data),"Lost hit acknowledgment has a bounded retry wait")
    api.Sent(mob,data);data.Damage[me]=10;assert(api.Allow(mob,data))
    data.Damage[me]=0;api.Sent(mob,data);data.Damage[me]=-1;assert(api.Allow(mob,data),"A reset contribution counter releases stale in-flight state")
    members={};for i=1,21 do members[i]={Name=tostring(i)}end
    assert(not api.Allow(mob,data),"Impossible group sizes must never authorize a finishing hit")
    local another={Rank=2};members={me,other};data.Damage[me]=0;api.Reset();api.Sent(mob,data)
    assert(api.Allow(another,data),"Separate enemies must have separate acknowledgment tracking")

    -- Execute the real normal-hit scheduler against a credit-gated send callback.
    local create=assert(loadstring(schedulerSource))()
    local sends,marked=0,0
    local folder={};mob.Parent=folder
    data.Health={Value=1000};data.Entity={FindFirstChild=function()end}
    local delta={Dot=function()return 0 end}
    data.Damage[me]=50;data.Damage[other]=0
    local scheduler=create({FrameRequestCap=4,MaxRequestsPerSecond=48,Enabled=true})
    scheduler.Bind({GetData=function()return data end,Delta=function()return delta end,Radius=function()return 30 end,
        Damage=function(m)if not api.Allow(m,data)then return false end;sends+=1 end,
        Sent=function()marked+=1 end,Visual=function()end})
    scheduler.Update(now,{mob},{},folder)
    assert(sends==0 and marked==0 and scheduler.Next(mob)==0,"Credit-paused sends cannot consume hit cooldowns or record damage")
    data.Damage[other]=50;scheduler.Update(now+.1,{mob},{},folder)
    assert(sends==1 and marked==1,"Qualified group resumes the normal scheduler")
    data.Damage[me]=50;data.Damage[other]=50
    local absent={Name="MissingFriend",CreditMissing=true}
    members={me,other,absent};assert(api.Allow(mob,data)and state.CreditCheckStatus:find("inactive",1,true))
    assert(api.AllowAction(mob,data,"Normal")and api.AllowAction(mob,data,"Skill"),"A missing whitelisted account bypasses both the credit hold and damage planner")
    members={me};assert(api.Allow(mob,data),"A solo account does not need shared credit checking")
    members={me,other,third};data.Damage[third]=nil
    assert(not api.Allow(mob,data)and state.CreditCheckStatus:find("no replicated damage counter: Third",1,true))
    data.Damage[third]=49;assert(not api.Allow(mob,data)and state.CreditCheckStatus:find("below required: Third 49/50",1,true))
    data.Damage[third]=50;assert(api.Allow(mob,data));members={me,other}
    local calls=0
    local send=assert(loadstring("return "..skillSendSource))
    setfenv(send,setmetatable({state={CreditController=api},current=function()return true end,
        Combat={DealDamage=function()calls+=1 end},name="Summon Pistol",healthHUD={Touch=function()end}},{__index=getfenv()}))
    send=send();data.Damage[me]=50;data.Damage[other]=0
    assert(send(mob,data)==false and calls==0,"The actual active-skill send adapter must reject hits while others need credit")
    data.Damage[other]=50;send(mob,data);assert(calls==1,"The active-skill adapter resumes after group qualification")
    print("PASS Credit Check: 5% maximum HP, bosses/minis only, independent members, missing counters, shared normal/skill gate, acknowledgment, departure and finishing")
end
