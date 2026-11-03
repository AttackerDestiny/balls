-- Source-provided arena coordinates; current-floor discoveries may refine them.
return function(ctx)
    local source = {
        [542351431]={
            ["Boss"]=Vector3.new(-2939,-234,1216),
        },
        [548231754]={
            ["Boss"]=Vector3.new(-2010,443,-8956),
        },
        [555980327]={
            ["Boss"]=Vector3.new(-393,4168,-369),
        },
        [572487908]={
            ["Boss"]=Vector3.new(-2319,2073,95),
        },
        [580239979]={
            ["Boss"]=Vector3.new(2182,1236,-717),
        },
        [582198062]={
            ["Boss"]=Vector3.new(3329,730,-475),
        },
        [548878321]={
            ["Boss"]=Vector3.new(1550,4081,7720),
            ["Miniboss"]=Vector3.new(3772,5743,-9686),
        },
        [573267292]={
            ["Boss"]=Vector3.new(12392,429,-3415),
            ["Miniboss"]=Vector3.new(1926,2889,-11348),
            ["Second miniboss"]=Vector3.new(-3613,2905,-7708),
        },
        [2659143505]={
            ["Boss"]=Vector3.new(104,931,23842),
            ["Miniboss"]=Vector3.new(50,261,18107),
        },
        [5287433115]={
            ["Duality Reaper"]=Vector3.new(6154,846,-4251),
            ["Za, the Eldest"]=Vector3.new(1753,921,-6389),
            ["Miniboss"]=Vector3.new(5129,1614,2104),
            ["Boss"]=Vector3.new(5187,2343,6239),
        },
        [6144637080]={
            ["Limor the Devourer"]=Vector3.new(450,-337,7912),
            ["Radioactive Experiment"]=Vector3.new(-3754,167,3570),
            ["Suspended Unborn"]=Vector3.new(-2439,60,5389),
            ["C-618 Uriotol, The Forgotten Hunter"]=Vector3.new(1685,288,3749),
            ["Warlord"]=Vector3.new(1031,108,5474),
        },
        [13965775911]={["Atheon arena"]=Vector3.new(840,798,336)},
        [134019705603409]={Leviathan=Vector3.new(15.89453125,1320.01953125,-797.10546875)},
    }
    local supplied = {
        [542351431]={
            ["Boss"]={Name="Rahjin the Thief King",Kind="Boss",RespawnSeconds=90,EncounterNames={["Rahjin the Thief King"]=true}},
        },
        [548231754]={
            ["Boss"]={Name="Borik the BeeKeeper",Kind="Boss",RespawnSeconds=90,EncounterNames={["Borik the BeeKeeper"]=true}},
        },
        [555980327]={
            ["Boss"]={Name="Ra'thae the Ice King",Kind="Boss",RespawnSeconds=90,EncounterNames={["Ra'thae the Ice King"]=true}},
        },
        [572487908]={
            ["Boss"]={Name="Irath The Lion",Kind="Boss",RespawnSeconds=90,EncounterNames={["Irath The Lion"]=true}},
        },
        [580239979]={
            ["Boss"]={Name="Sa'jun the Centurian Chieftain",Kind="Boss",RespawnSeconds=90,EncounterNames={["Sa'jun the Centurian Chieftain"]=true}},
        },
        [582198062]={
            ["Boss"]={Name="Smashroom the Mushroom Behemoth",Kind="Boss",RespawnSeconds=90,EncounterNames={["Smashroom the Mushroom Behemoth"]=true}},
        },
        [548878321]={
            ["Boss"]={Name="Formaug the Jungle Giant",Kind="Boss",RespawnSeconds=90,EncounterNames={["Formaug the Jungle Giant"]=true}},
            ["Miniboss"]={Name="Hippogriff",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Hippogriff"]=true}},
        },
        [573267292]={
            ["Boss"]={Name="Mortis the Flaming Sear",Kind="Boss",RespawnSeconds=90,EncounterNames={["Mortis the Flaming Sear"]=true}},
            ["Miniboss"]={Name="Polyserpant",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Polyserpant"]=true}},
            ["Second miniboss"]={Name="Gargoyle Reaper",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Gargoyle Reaper"]=true}},
        },
        [2659143505]={
            ["Boss"]={Name="Grim the Overseer",Kind="Boss",RespawnSeconds=90,EncounterNames={["Grim the Overseer"]=true}},
            ["Miniboss"]={Name="Baal, The Tormentor",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Baal, The Tormentor"]=true}},
        },
        [5287433115]={
            ["Duality Reaper"]={Name="Duality Reaper",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Duality Reaper"]=true}},
            ["Za, the Eldest"]={Name="Za, the Eldest",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Za, the Eldest"]=true}},
            ["Miniboss"]={Name="DA, RA, KA",Kind="Mini boss",RespawnSeconds=45,EncounterNames={Da=true,Ra=true,Ka=true}},
            ["Boss"]={Name="Saurus, the All-Seeing",Kind="Boss",RespawnSeconds=90,EncounterNames={["Saurus, the All-Seeing"]=true}},
        },
        [6144637080]={
            ["Limor the Devourer"]={Name="Limor the Devourer",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Limor the Devourer"]=true}},
            ["Radioactive Experiment"]={Name="Radioactive Experiment",Kind="Boss",RespawnSeconds=90,EncounterNames={["Radioactive Experiment"]=true}},
            ["Suspended Unborn"]={Name="Suspended Unborn",Kind="Boss",RespawnSeconds=90,EncounterNames={["Suspended Unborn"]=true}},
            ["C-618 Uriotol, The Forgotten Hunter"]={Name="C-618 Uriotol, The Forgotten Hunter",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["C-618 Uriotol, The Forgotten Hunter"]=true}},
            ["Warlord"]={Name="Warlord",Kind="Mini boss",RespawnSeconds=45,EncounterNames={["Warlord"]=true}},
        },
    }
    local numbers = {[542351431]=1,[548231754]=2,[555980327]=3,[572487908]=4,[580239979]=5,[566212942]=6,
        [582198062]=7,[548878321]=8,[573267292]=9,[2659143505]=10,[5287433115]=11,[6144637080]=12,[13965775911]=13,[134019705603409]=14}
    local catalog={Floors={},FloorById={},Spots={},SpotById={},Aliases={}}
    -- Identities and positions verified in the new-account live progression test.
    local mainBossNames={
        [542351431]={["Rahjin the Thief King"]=true},
        [548231754]={["Borik the BeeKeeper"]=true},
    }
    local function accepts(spot,name)
        if not spot.EncounterNames then return true end
        local cleaned=tostring(name or ""):lower():gsub("[^%w]","")
        for expected in pairs(spot.EncounterNames)do
            if expected:lower():gsub("[^%w]","")==cleaned then return true end
        end
        return false
    end
    for _,floor in ipairs(ctx.Floors) do
        local n=numbers[floor.PlaceId]
        if n then
            local item={Id=floor.PlaceId,Number=n,Name=floor.Name,Label=floor.PlaceId==134019705603409 and floor.Name or ("F"..n.." · "..floor.Name),Unlocked=ctx.Unlocked(floor)}
            catalog.Floors[#catalog.Floors+1]=item;catalog.FloorById[item.Id]=item
        end
    end
    table.sort(catalog.Floors,function(a,b)return a.Number<b.Number end)
    local extraKinds={Leviathan='Boss',['Suspended Unborn']='Arena',['Limor the Devourer']='Arena',['Radioactive Experiment']='Arena',
        ['Za, the Eldest']='Mini boss',['Wa, the Curious']='Arena',['Duality Reaper']='Mini boss',['Atheon arena']='Arena'}
    for placeId,areas in pairs(source) do
        local floor=catalog.FloorById[placeId]
        if floor then for original,point in pairs(areas) do
            local key=original:match('^%s*(.-)%s*$')
            local info=supplied[placeId]and supplied[placeId][key]
            local kind=info and info.Kind or key=='Boss' and 'Boss' or (key=='Miniboss' or key=='Second miniboss') and 'Mini boss' or extraKinds[key]
            if kind then
                local name=info and info.Name or key=='Boss' and 'Boss arena' or key=='Miniboss' and 'Mini-boss arena' or key
                local spot={Id=tostring(placeId)..'/'..key,PlaceId=placeId,Name=name,Kind=kind,Position=point,
                    DestinationId='source:'..key,Floor=floor,Label=floor.Label..' · '..name,
                    RespawnSeconds=info and info.RespawnSeconds,MainBoss=key=='Boss',PositionLocked=info~=nil or placeId==13965775911,
                    EncounterNames=info and info.EncounterNames or placeId==13965775911 and {Atheon=true,['Corrupted Atheon']=true}
                        or (placeId==134019705603409 and key=='Leviathan' and {Leviathan=true})
                        or (key=='Boss' and mainBossNames[placeId]) or nil}
                catalog.Spots[#catalog.Spots+1]=spot;catalog.SpotById[spot.Id]=spot
            end
        end end
    end
    function catalog.AddCurrent(areas,placeId)
        local floor=catalog.FloorById[placeId];if not floor then return end
        for id,area in pairs(areas or {})do
            if id:sub(1,16)=="saved:multispot:" then
                local key=tostring(placeId).."/"..id
                local spot=catalog.SpotById[key]
                if not spot then
                    spot={Id=key,PlaceId=placeId,Name=area.Name,Kind="Arena",Position=area.Position,
                        DestinationId=id,Floor=floor,Label=floor.Label.." · "..area.Name,PositionLocked=true}
                    catalog.Spots[#catalog.Spots+1]=spot;catalog.SpotById[key]=spot
                else spot.Position=area.Position end
            end
        end
        for _,kind in ipairs({'Boss','Mini boss'}) do
            local generic=catalog.SpotById[tostring(placeId)..'/'..(kind=='Boss' and 'Boss' or 'Miniboss')]
            -- Keep the user's explicit F9 first-arena location even if only the second mini-boss is loaded.
            if generic and not generic.PositionLocked then
                local closest,distance
                for id,area in pairs(areas or {}) do
                    if id:sub(1,4)=='mob:' and area.Kind==kind and accepts(generic,id:sub(5)) then
                        local d=(area.Position-generic.Position).Magnitude
                        if not distance or d<distance then closest,distance=area,d end
                    end
                end
                if closest then generic.Position=closest.Position;generic.DestinationId=closest.Id;generic.SourceRefined=true end
            end
        end
        for id,area in pairs(areas or {}) do
            if area.Kind=='Boss' or area.Kind=='Mini boss' then
                local key=tostring(placeId)..'/'..id
                if id:sub(1,7)~='source:' then
                    local name=id:sub(1,4)=='mob:' and id:sub(5) or area.Name
                    local primary
                    if placeId==13965775911 and (name=='Atheon' or name=='Corrupted Atheon') then
                        primary=catalog.SpotById[tostring(placeId)..'/Atheon arena']
                    end
                    for _,spot in ipairs(catalog.Spots) do
                        if not primary and spot.PlaceId==placeId and (spot.Name:lower()==name:lower() or (spot.EncounterNames and spot.EncounterNames[name])) then primary=spot;break end
                    end
                    if primary then
                        if not primary.PositionLocked then
                            primary.Position=area.Position;primary.DestinationId=id;primary.Kind=area.Kind;primary.SourceRefined=true
                        end
                    else
                        local nearest
                        for _,spot in ipairs(catalog.Spots) do
                            if spot.PlaceId==placeId and accepts(spot,name)
                                and (spot.Kind==area.Kind or (spot.PositionLocked and spot.Kind=='Arena')) then
                                local distance=(spot.Position-area.Position).Magnitude
                                if distance<=220 and (not nearest or distance<nearest) then primary,nearest=spot,distance end
                            end
                        end
                    end
                    if primary then
                        catalog.Aliases[key]=primary.Id;catalog.SpotById[key]=primary
                    elseif not supplied[placeId] then
                        local spot={Id=key,PlaceId=placeId,Name=name,Kind=area.Kind,Position=area.Position,
                            DestinationId=id,Floor=floor,Label=floor.Label..' · '..name}
                        catalog.Spots[#catalog.Spots+1]=spot;catalog.SpotById[key]=spot
                    end
                end
            end
        end
    end
    function catalog.NormalizeSelection(selected)
        local result={}
        for id,on in pairs(selected or {}) do
            if on then result[catalog.Aliases[id] or id]=true end
        end
        return result
    end
    function catalog.Sort()
        table.sort(catalog.Spots,function(a,b)
            if a.Floor.Number~=b.Floor.Number then return a.Floor.Number<b.Floor.Number end
            if a.Kind~=b.Kind then
                local ranks={Boss=1,['Mini boss']=2,Arena=3}
                return (ranks[a.Kind] or 4)<(ranks[b.Kind] or 4)
            end
            if a.Name~=b.Name then return a.Name<b.Name end
            return a.Id<b.Id
        end)
    end
    catalog.Sort()
    return catalog
end
