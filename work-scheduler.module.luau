-- Jobs own independent deadlines, diagnostics and retry state.
return function(context)
    local api={Tasks={},Failures=0}
    local open=true
    local function period(job)
        local value=job.Interval
        if type(value)=="function"then value=value()end
        assert(type(value)=="number"and value>=0 and value<math.huge,"Invalid task interval")
        return value
    end
    function api.Add(name,interval,callback,options)
        assert(open,"Scheduler already closed")
        assert(type(callback)=="function"and not api.Tasks[name],"Invalid or duplicate task")
        local job={Name=name,Interval=interval,Run=callback,Options=options or {},Due=0,Calls=0,Failures=0,ConsecutiveFailures=0}
        period(job);api.Tasks[name]=job;return job
    end
    function api.Wake(name)
        local job=open and api.Tasks[name]
        if job then job.Due=0 end
    end
    function api.Step(name,timestamp,...)
        if not open then return end
        local job=assert(api.Tasks[name],"Unknown task: "..tostring(name))
        local at=timestamp or context.Now()
        if at<job.Due then return end
        job.Due=at+period(job)
        if job.Options.Enabled and not job.Options.Enabled()then return end
        local started=context.Now();job.Calls+=1;job.LastRun=at
        local ok,result=pcall(job.Run,at,...)
        job.Cost=math.max(0,context.Now()-started)
        if ok then job.LastError=nil;job.ConsecutiveFailures=0
        else
            local attempt=job.ConsecutiveFailures+1
            job.Failures+=1;job.ConsecutiveFailures=attempt;api.Failures+=1
            job.LastError=tostring(result);job.Due=at+math.min(2,.1*2^math.min(4,attempt-1))
            if context.Error then
                local handled,reason=pcall(context.Error,name,job.LastError,job)
                if not handled then job.RecoveryError=tostring(reason)end
            end
        end
        return ok,result
    end
    function api.Destroy()
        if not open then return end
        open=false
        for _,job in pairs(api.Tasks)do job.Run=nil;job.Options=nil end
        table.clear(api.Tasks)
    end
    return api
end
