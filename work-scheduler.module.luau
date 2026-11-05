-- Independent wall-clock tasks: no catch-up bursts or shared failure latch.
return function(ctx)
    local api={Tasks={},Failures=0}
    local disposed=false
    function api.Add(name,interval,run,options)
        assert(not disposed,"Scheduler already closed")
        assert(not api.Tasks[name],"Duplicate task: "..name)
        local task={Name=name,Interval=interval,Run=run,Options=options or {},Due=0,Calls=0,Failures=0}
        api.Tasks[name]=task
        return task
    end
    function api.Step(name,now,...)
        if disposed then return end
        local task=assert(api.Tasks[name],"Unknown task: "..name)
        now=now or ctx.Now()
        if now<task.Due then return end
        task.Due=now+(type(task.Interval)=="function"and task.Interval()or task.Interval)
        if task.Options.Enabled and not task.Options.Enabled()then return end
        task.Calls+=1
        local started=ctx.Now()
        local ok,result=pcall(task.Run,now,...)
        task.Cost=ctx.Now()-started
        if ok then task.LastError=nil;task.ConsecutiveFailures=0
        else
            task.LastError=tostring(result);task.Failures+=1;api.Failures+=1
            task.ConsecutiveFailures=(task.ConsecutiveFailures or 0)+1
            task.Due=now+math.min(2,.1*2^math.min(4,task.ConsecutiveFailures-1))
            if ctx.Error then ctx.Error(name,task.LastError,task)end
        end
        return ok,result
    end
    function api.Wake(name)
        local task=api.Tasks[name]
        if task then task.Due=0 end
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        for _,task in pairs(api.Tasks)do task.Run=nil;task.Options={}end
        table.clear(api.Tasks)
    end
    return api
end
