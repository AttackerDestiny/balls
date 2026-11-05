return function(source)
    local factory=assert(loadstring(source))()
    local creator={Signals={},Objects={},FontObjects={},LocalizationObjects={}}
    local living={Parent=true}
    for i=1,1000 do
        creator.Signals[i]={Connected=i%2==0,Disconnect=function(self)self.Connected=false end}
        local object=i%2==0 and living or {Parent=nil}
        creator.FontObjects[i]=object
        creator.LocalizationObjects[i]={Object=object}
        creator.Objects[object]={Object=object}
    end
    local api=factory(creator)
    for _=1,30 do api.Update()end
    assert(#creator.Signals==500 and #creator.FontObjects==500 and #creator.LocalizationObjects==500,"Destroyed controls and disconnected signals cannot accumulate")
    local count=0;for object in pairs(creator.Objects)do assert(object.Parent);count+=1 end
    assert(count==1 and api.Pruned>=2000,"Theme registries must release destroyed objects")
    local connections=table.clone(creator.Signals)
    api.Destroy();api.Destroy();api.Update()
    for _,connection in ipairs(connections)do assert(not connection.Connected,"Shutdown must not skip alternating entries")end
    assert(#creator.Signals==0 and #creator.FontObjects==0 and next(creator.Objects)==nil)
    print("PASS UI memory: repeated stale-control cleanup, bounded scans, live references retained and complete signal disposal")
end
