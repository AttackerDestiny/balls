return function(source)
    local files,writes={},0
    local captured
    local areas={builtin={Id="source:Boss",Name="Boss",Kind="Boss",Position={X=1,Y=2,Z=3}}}
    local fn=assert(loadstring(source.."\nreturn saveDestinations"))
    setfenv(fn,setmetatable({destinations=areas,filePersistence=true,state={},game={PlaceId=11},customSpotPath="custom-spots_11.json",
        HttpService={JSONEncode=function(_,value)captured=value;return tostring(#value.Areas)..":"..value.Areas[1].Id end},
        writefile=function(path,raw)files[path]=raw;writes+=1 end},{__index=getfenv()}))
    local save=fn();save();assert(writes==0,"No position file is created for built-in spots")
    areas["saved:multispot:test"]={Name="Saved Spot 1",Position={X=10,Y=20,Z=30}}
    save();assert(writes==1 and files["custom-spots_11.json"])
    assert(#captured.Areas==1 and captured.Areas[1].Id=="saved:multispot:test"and captured.Areas[1].Position[2]==20,
        "Persist only custom coordinates, without applying another teleport offset")
    save();assert(writes==1,"Unchanged discoveries cannot rewrite custom spot files")
    print("PASS Custom spot persistence: no built-in file, custom-only payload, unchanged-write suppression and original height")
end
