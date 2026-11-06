return function(source)
    local expected={
        {542351431,"Boss",-2939,-234,1216,90},{548231754,"Boss",-2010,443,-8956,90},
        {555980327,"Boss",-393,4168,-369,90},{572487908,"Boss",-2319,2073,95,90},
        {580239979,"Boss",2182,1236,-717,90},{582198062,"Boss",3329,730,-475,90},
        {548878321,"Boss",1550,4081,7720,90},{548878321,"Miniboss",3772,5743,-9686,45},
        {573267292,"Boss",12392,429,-3415,90},{573267292,"Miniboss",1926,2889,-11348,45},
        {573267292,"Second miniboss",-3613,2905,-7708,45},
        {2659143505,"Boss",104,931,23842,90},{2659143505,"Miniboss",50,261,18107,45},
        {5287433115,"Duality Reaper",6154,846,-4251,45},{5287433115,"Za, the Eldest",1753,921,-6389,45},
        {5287433115,"Miniboss",5129,1614,2104,45},{5287433115,"Boss",5187,2343,6239,90},
        {6144637080,"Limor the Devourer",450,-337,7912,45},{6144637080,"Radioactive Experiment",-3754,167,3570,90},
        {6144637080,"Suspended Unborn",-2439,60,5389,90},{6144637080,"C-618 Uriotol, The Forgotten Hunter",1685,288,3749,45},
        {6144637080,"Warlord",1031,108,5474,45},
        {134019705603409,"Aeganatos, The Sunken Sovereign",1500,792,127,60},
        {134019705603409,"Leviathan",12,1313,-823,45},
        {134019705603409,"Kraken",353,-319,120,45}}
    local floors,seen={},{}
    for _,row in ipairs(expected)do if not seen[row[1]]then seen[row[1]]=true;floors[#floors+1]={PlaceId=row[1],Name="Floor"}end end
    local fn=assert(loadstring(source));setfenv(fn,setmetatable({Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end}},{__index=getfenv()}))
    local catalog=fn()({Floors=floors,Unlocked=function()return true end})
    assert(#catalog.Spots==#expected)
    for _,row in ipairs(expected)do
        local spot=catalog.SpotById[tostring(row[1]).."/"..row[2]]
        assert(spot and spot.Position.X==row[3]and spot.Position.Y==row[4]and spot.Position.Z==row[5])
        assert(spot.PositionLocked and spot.RespawnSeconds==row[6])
        local area={Id="mob:"..spot.Name,Name=spot.Name,Kind=spot.Kind,Position={X=0,Y=0,Z=0}}
        catalog.AddCurrent({[area.Id]=area},row[1])
        assert(spot.Position.Y==row[4]and spot.DestinationId=="source:"..row[2],"Discovery cannot move a supplied arena")
    end
    assert(#catalog.Spots==#expected,"Native aliases cannot duplicate supplied defaults")
    print("PASS All 25 supplied arenas: exact XYZ, respawn metadata, stable IDs, grouped arena and locked discoveries")
end
