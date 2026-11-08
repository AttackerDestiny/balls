return function(source)
    local make=assert(loadstring(source))()
    local clipboard,applied,encoded,library
    local settings={Version=1,Enabled=true,AutoRegroup=true,AutoRegroupUsers="Host, Alt",SafeMode=true,SafeFloorId=11,SafeWhitelistText="One, 123",SafeWhitelistIds={123},
        AntiSuspicious=true,AntiSuspiciousLimits={Hops=10,Window=10,Min=40,Max=60},
        BetweenRooms={{Host="Host",Alt="Alt, 123",Mode="Friends",Difficulty="Hard",Start=true,AutoRetry=true},{Host="Legacy",Alt=""}},
        BetweenPace={Normal=35,Hard={Min=35,Max=38},Elite={Min=0,Max=0}},
        AutoFarm=false,CreditCheck=true,CreditWhitelistText="Friend, 123",BossOnly=true,MultiSpotOrder={"b","a"},AutoCraft={["Rare Upgrade Crystal"]=true},TradeItems={Gem=true},MultiSpotSelected={arena=true},
        SkillPerWeapon={Sword="Summon Pistol"},OffsetProfiles={Boss=20},Theme="Light",AutoHideUI=true,ActiveTab="Settings",
        WindUIPosition={.5,0,.5,0},HealthHUDPosition={.5,0,.7,0},ViewingPlayerInventory=true,SelectedPlayerId=123}
    local spots={["11"]={{Id="saved:multispot:a",Name="Custom",Position={1,2,3}}},["22"]={{Id="saved:multispot:b",Name="Other floor",Position={4,5,6}}}}
    local api=make({Settings=function()return settings end,Spots=function()return spots end,
        Presets=function()return library end,
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
    settings.AntiSuspiciousLimits.Max=201;invalid(encoded);settings.AntiSuspiciousLimits.Max=60
    settings.BetweenPace.Hard.Max=34;invalid(encoded);settings.BetweenPace.Hard.Max=38
    spots["../escape"]={};invalid(encoded);spots["../escape"]=nil
    spots["11"][1].Position[1]=math.huge;invalid(encoded);spots["11"][1].Position[1]=1
    assert(not pcall(api.Import,string.rep("x",262145)))
    library={Items={{Settings=settings,CustomSpots=spots},{Settings={Version=1},CustomSpots={}}},
        Auto=true,Active=1,Manual=1,Outside=1,Between=2}
    api.Export()
    assert(api.Import(clipboard) and applied.Presets.Outside==1 and applied.Presets.Between==2)
    api.Export()
    encoded.Presets.Between=3;invalid(encoded);encoded.Presets.Between=2
    library.Items[2].Settings.Enabled="yes";invalid(encoded);library.Items[2].Settings.Enabled=nil
    local noClipboard=make({Settings=function()return settings end,Spots=function()return spots end,Encode=function()return "ok"end})
    assert(not pcall(noClipboard.Export),"Unsupported clipboard must report failure")
    local private={ProgressionFloor=9,ProgressionBossCleared=true,ProgressionBossClearedName="Old boss",
        ProgressionComplete=true,ProgressionRestore={Enabled=true,AutoFarm=true}}
    settings.AccountProgression=true
    for key,value in pairs(private)do settings[key]=value end
    library.Between=2
    api.Export()
    for key,value in pairs(private)do
        assert(encoded.Settings[key]==nil and encoded.Presets.Items[1].Settings[key]==nil,
            "Root and preset exports must exclude account progression: "..key)
        assert(settings[key]==value,"Export must preserve the current account's checkpoint")
    end
    assert(encoded.Settings.AccountProgression and encoded.Presets.Items[1].Settings.AccountProgression,
        "Progression ON/OFF is still a portable feature preference")
    local old={Format="FeatherConfig",Version=1,Settings=settings,CustomSpots=spots,
        Presets={Items={{Settings=settings,CustomSpots=spots}},Auto=false,Active=1,Manual=1,Outside=1,Between=0}}
    encoded=old
    assert(api.Import("encoded-config"))
    for key,value in pairs(private)do
        assert(applied.Settings[key]==nil and applied.Presets.Items[1].Settings[key]==nil,
            "Legacy configs cannot import another account's progression")
        assert(old.Settings[key]==value,"Validation cannot mutate decoded snapshots or live settings")
    end
    print("PASS Config transfer: portable preferences, private progression filtering, custom spots, legacy import, type/path/size validation")
end
