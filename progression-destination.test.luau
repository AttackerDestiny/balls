return function(source)
    local oldPoint,newPoint={},{}
    local destinations={["source:Boss"]={Name="Boss area",Kind="Boss",Position=oldPoint}}
    local state={}
    local chunk=assert(loadstring(source))
    setfenv(chunk,setmetatable({state=state,game={PlaceId=1},destinations=destinations,
        rememberDestination=function(id,name,kind,position)destinations[id]={Name=name,Kind=kind,Position=position}end},{__index=getfenv()}))
    chunk()
    assert(state.RegisterAutomationDestination({PlaceId=1,DestinationId="source:Boss",MainBoss=true,Kind="Boss",Position=newPoint}))
    assert(destinations["source:Boss"].Position==newPoint,"A stale side-boss coordinate must be replaced before native travel")
    print("PASS Canonical progression destinations repair stale cached arena positions")
end
