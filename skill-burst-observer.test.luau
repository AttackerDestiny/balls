return function(source)
    local chunk=assert(loadstring(source))
    setfenv(chunk,setmetatable({task={spawn=function()end}},{__index=getfenv()}))
    local make=chunk()
    local connected=0
    local signal={Connect=function()
        connected+=1
        return {Disconnect=function()connected-=1 end}
    end}
    local health={Value=100,GetPropertyChangedSignal=function()return signal end}
    local target={Name="Boss"};local data={Health=health}
    local broken=false
    local record={HealthDrops=0}
    local api=make({State={},Record=record,Targets=function()return {target}end,Valid=function()return data end,
        Spacing=.3,Contribution=function()if broken then error("Counter streamed out")end;return 0 end})
    assert(api.Start(target)and connected==1)
    broken=true;api.Finish();api.Finish();api.Cancel()
    assert(connected==0 and record.ObservationError,"Observation failures must release every engine listener exactly once")
    print("PASS Skill observation cleanup: native counter errors cannot retain completed casts through engine signals")
end
