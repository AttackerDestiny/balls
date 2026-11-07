return function(jobId)
    -- Accounts using the same range in the same run pick the same second.
    local hash=0
    for i=1,#jobId do hash=(hash*31+jobId:byte(i))%65521 end
    local lastWave,peak
    return function(range,wave,runTime,remaining,survival,finalHealth)
        if not range or range.Max==0 then return false end
        local first,last=range.Min*60,range.Max*60
        local goal=first+hash%(last-first+1)
        local h,m,s=tostring(runTime or ""):match("^(%d+):(%d+):(%d+)$")
        local elapsed=h and (tonumber(h)*3600+tonumber(m)*60+tonumber(s))
        if not elapsed or type(wave)~="number" or wave<1 or wave>100 then return false,goal end
        if wave~=lastWave then lastWave=wave;peak=0 end
        remaining=math.max(0,tonumber(remaining) or 0)
        peak=math.max(peak,remaining)
        if survival or remaining==0 then return false,goal,elapsed end
        local progress=(peak-remaining)/math.max(1,peak)
        local release=(wave-1+progress)*goal/100
        if wave==100 and remaining==1 and finalHealth and finalHealth<=.15 then release=goal end
        return elapsed<release,goal,elapsed,release
    end
end
