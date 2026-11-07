return function(source)
    local make=assert(loadstring(source))()
    local clipboard,applied,encoded
    local settings={Version=1,Enabled=true,SafeMode=true,SafeFloorId=11,SafeWhitelistText="One, 123",SafeWhitelistIds={123},
        BetweenRooms={{Host="Host",Alt="Alt, 123",Mode="Friends",Difficulty="Hard",Start=true,AutoRetry=true},{Host="Legacy",Alt=""}},
        BetweenPace={Normal=35,Hard={Min=35,Max=38},Elite={Min=0,Max=0}},
        AutoFarm=false,CreditCheck=true,CreditWhitelistText="Friend, 123",BossOnly=true,MultiSpotOrder={"b","a"},AutoCraft={["Rare Upgrade Crystal"]=true},TradeItems={Gem=true},MultiSpotSelected={arena=true},
        SkillPerWeapon={Sword="Summon Pistol"},OffsetProfiles={Boss=20},Theme="Light",AutoHideUI=true,ActiveTab="Settings",
        WindUIPosition={.5,0,.5,0},HealthHUDPosition={.5,0,.7,0},ViewingPlayerInventory=true,SelectedPlayerId=123}
    local spots={["11"]={{Id="saved:multispot:a",Name="Custom",Position={1,2,3}}},["22"]={{Id="saved:multispot:b",Name="Other floor",Position={4,5,6}}}}
    local api=make({Settings=function()return settings end,Spots=function()return spots end,
        Encode=function(value)if value.Format then encoded=value end;return "encoded-config"end,Decode=function(text)assert(text=="encoded-config");return encoded end,
        Copy=function(text)clipboard=text end,Apply=function(value)applied=value end})
    assert(api.Export()=="encoded-config"and clipboard=="encoded-config")
    for key,value in pairs(settings)do assert(encoded.Settings[key]==value,"Every setting must be exported: "..key)end
    assert(api.Import(clipboard)and applied.Settings==settings and #applied.CustomSpots["22"]==1)
    local function invalid(value)applied=nil;assert(not pcall(api.Validate,value));assert(applied==nil)end
    invalid({Format="Wrong",Version=1,Settings=settings,CustomSpots=spots})
    settings.SafeMode="yes";invalid(encoded);settings.SafeMode=true
    settings.Unknown=true;invalid(encoded);settings.Unknown=nil
    settings.BetweenRooms[1].Start="yes";invalid(encoded);settings.BetweenRooms[1].Start=true
    settings.BetweenRooms[1].AutoRetry="yes";invalid(encoded);settings.BetweenRooms[1].AutoRetry=true
    settings.BetweenPace.Hard.Max=34;invalid(encoded);settings.BetweenPace.Hard.Max=38
    spots["../escape"]={};invalid(encoded);spots["../escape"]=nil
    spots["11"][1].Position[1]=math.huge;invalid(encoded);spots["11"][1].Position[1]=1
    assert(not pcall(api.Import,string.rep("x",262145)))
    local noClipboard=make({Settings=function()return settings end,Spots=function()return spots end,Encode=function()return "ok"end})
    assert(not pcall(noClipboard.Export),"Unsupported clipboard must report failure")
    print("PASS Config transfer: all snapshot fields, multi-floor custom spots, clipboard roundtrip, type/path/size validation and unsupported clipboard")
end
