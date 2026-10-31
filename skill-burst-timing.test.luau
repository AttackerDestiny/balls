return function(source)
    local function fixture(jitter,expires)
        local time=0
        local sends={}
        local mob={Name="Boss"}
        local health={Value=1000000,GetPropertyChangedSignal=function()return {Connect=function()return {Disconnect=function()end}end}end}
        local record={HealthDrops=0}
        local state={SkillHitRequests=0}
        local load=assert(loadstring(source))
        setfenv(load,setmetatable({os={clock=function()return time end},task={
            spawn=function(fn)fn()end,wait=function(n)time+=n+(jitter or 0)end}},{__index=getfenv()}))
        local api=load()({State=state,Record=record,Spacing=.24,Rounds=3,FirstHitAt=.3,ExpiresAt=expires or 2,
            Targets=function()return {mob}end,Valid=function()return {Health=health}end,CanRun=function()return true end,
            Send=function()sends[#sends+1]=time;time+=.01 end})
        assert(api.Start(mob))
        return record,sends
    end
    for _,jitter in ipairs({0,.04,.2})do
        local record,sends=fixture(jitter)
        assert(sends[1]>=.3 and #sends==3 and record.TotalRequests==3)
        for i=2,#sends do assert(sends[i]-sends[i-1]>=.24-1e-6,"Never catch up by spamming late hits")end
    end
    local _,sends=fixture(.1,.7)
    for _,time in ipairs(sends)do assert(time<.7,"Never extend the native firing window")end
    print("PASS Skill burst timing preserves windup spacing and deadlines under frame jitter")
end
