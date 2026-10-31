return function(burstSource,budgetSource)
    local root=Instance.new("Folder")
    local function mob(name,hp)
        local m=Instance.new("Model",root);m.Name=name
        local h=Instance.new("NumberValue",m);h.Value=hp
        return m,{Health=h}
    end
    local a,ad=mob("NearlyDead",150000)
    local b,bd=mob("NextTarget",400000)
    local data={[a]=ad,[b]=bd}
    local budget=assert(loadstring(budgetSource))()()
    local record={HealthDrops=0,Requested=0}
    local calls={}
    local state={SkillHitRequests=0}
    local api=assert(loadstring(burstSource))()({State=state,Record=record,Spacing=.02,Rounds=3,
        RefreshTargets=true,FocusBudget=true,Budget=budget,EstimateDamage=function()return 159000 end,
        Targets=function()return {a,a,b}end,Valid=function(m)return data[m]end,
        CanRun=function()return true end,Send=function(m)calls[#calls+1]=m end})
    local ok,message=pcall(function()
        assert(api.Start(a))
        local deadline=os.clock()+2
        repeat task.wait(.01)until record.FinishedAt or os.clock()>deadline
        assert(record.FinishedAt and #calls==3,"Keep the three-hit budget")
        assert(calls[1]==a and calls[2]==b and calls[3]==b,"One 159k hit for 150k HP; remaining two go to next mob")
        assert(ad.Health.Value==150000 and bd.Health.Value==400000,"Prediction never writes replicated HP")
        assert(record.Targets[1].Requested==1 and record.Targets[2].Requested==2,"Count retargeted requests per mob")
        assert(record.Retargets==1 and record.SkippedOverkill>=1)
        api.Finish()
    end)
    api.Cancel();root:Destroy();if not ok then error(message)end
    return {Passed=true,Requests=#calls,FirstTarget=1,NextTarget=2,ReplicationDelayHandled=true}
end
