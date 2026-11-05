return function(source)
    local e={api={},ctx={},managed={},maintenance={},maintenanceQueued={},maintenanceHead=1,maintenanceTail=1000,maintenanceNext={},maintenanceNextTail=0}
    e.keep=function(obj)return obj.Protected end
    e.restore=function(obj,record)obj.Restored=true end
    e.write=function(obj,k,v)obj[k]=v end
    e.typeof=type
    local now=0;e.os={clock=function()return now end}
    for i=1,1000 do
        local obj={Parent=true,Value=0,IsA=function()return false end}
        e.managed[obj]={Before={},Hidden={Value=1},Parent=true}
        e.maintenance[i]=obj;e.maintenanceQueued[obj]=true
    end
    local first=e.maintenance[1];local last=e.maintenance[1000];last.Protected=true
    local chunk=assert(loadstring(source));setfenv(chunk,setmetatable(e,{__index=getfenv()}));chunk()
    assert(e.api.ProcessManaged()==64 and first.Value==1 and not last.Restored)
    for i=1,16 do assert(e.api.ProcessManaged()<=64)end
    assert(last.Restored and not e.managed[last],"Round-robin reaches late effects and releases protected cues")
    first.Parent=nil
    for i=1,16 do e.api.ProcessManaged()end
    assert(not e.managed[first],"Detached instances retire without a full-table sweep")
    for i=1,20000 do e.api.ProcessManaged()end
    assert(e.maintenanceTail<=1000 and e.maintenanceHead<=1001 and e.maintenanceNextTail<=1000,"Continuous effects must reuse bounded queue indexes over long runs")
    e.maintenance[e.maintenanceHead]=nil
    assert(pcall(e.api.ProcessManaged),"Weak maintenance slots may disappear after streamed effects are collected")
    e.os.clock=function()now+=.001;return now end
    assert(e.api.ProcessManaged()==1,"Slow devices obey the time budget and still make progress")
    print("PASS Visual maintenance: 1000 effects, bounded batches, fair progress, protection, removal, elapsed-time limit")
end
