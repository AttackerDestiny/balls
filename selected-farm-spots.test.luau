return function(source)
    local allows=assert(loadstring(source))()
    local p={X=0,Y=0,Z=0}
    local s={MultiSpot=true,MultiSpotSelected={MiniA=true,MiniB=true,Foreign=true},AutomationCatalog={SpotById={
        MiniA={PlaceId=1,Position=p,EncounterNames={MiniA=true}},
        MiniB={PlaceId=1,Position=p,EncounterNames={MiniB=true}},
        Boss={PlaceId=1,Position=p,EncounterNames={Main=true}},
        Foreign={PlaceId=2,Position=p,EncounterNames={Main=true}},
        Custom={PlaceId=1,Position=p}}}}
    assert(allows(s,"MiniA",p,2,1)and allows(s,"MiniB",p,2,1))
    assert(not allows(s,"Main",p,1,1),"Unselected main boss cannot override two selected minis, even nearby")
    assert(allows(s,"Add",p,3,1),"Clear normal adds in selected arenas")
    assert(not allows(s,"Add",{X=1000,Y=0,Z=0},3,1))
    s.MultiSpotSelected.Boss=true;assert(allows(s,"Main",p,1,1))
    s.MultiSpotSelected.Boss=nil;assert(not allows(s,"Main",nil,1,1),"Deselection immediately excludes a locked or cached enemy")
    s.MultiSpotSelected={};assert(not allows(s,"MiniA",p,2,1),"Empty selections cannot fall back to global bosses")
    s.MultiSpotSelected.Custom=true;assert(allows(s,"Main",p,1,1),"Custom spots accept nearby enemies")
    s.MultiSpot=false;assert(allows(s,"Main",nil,1,1),"Standalone Auto Farm remains unrestricted")
    s.MultiSpot=true;s.AccountProgression=true;assert(allows(s,"Main",nil,1,1))
    print("PASS Selected farm spots: minis-only, deselection, empty selection, adds, custom spots, floor scope and progression")
end
