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
        [134019705603409]={
            ["Aeganatos, The Sunken Sovereign"]=Vector3.new(1500,792,127),
            Leviathan=Vector3.new(12,1313,-823),
            Kraken=Vector3.new(353,-319,120),
        },
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
        [134019705603409]={
            ["Aeganatos, The Sunken Sovereign"]={Name="Aeganatos, The Sunken Sovereign",Kind="Boss",RespawnSeconds=60,EncounterNames={["Aeganatos, The Sunken Sovereign"]=true}},
            Leviathan={Name="Leviathan",Kind="Boss",RespawnSeconds=45,EncounterNames={Leviathan=true}},
            Kraken={Name="Kraken",Kind="Boss",RespawnSeconds=45,EncounterNames={Kraken=true}},
        },
    }
    local numbers = {[542351431]=1,[548231754]=2,[555980327]=3,[572487908]=4,[580239979]=5,[566212942]=6,
        [582198062]=7,[548878321]=8,[573267292]=9,[2659143505]=10,[5287433115]=11,[6144637080]=12,[13965775911]=13,[134019705603409]=14,[78945654064532]=15}
    local catalog={Floors={},FloorById={},Spots={},SpotById={},Aliases={}}
    local function clean(name)return tostring(name or ""):lower():gsub("[^%w]","")end
    local function accepts(spot,name)
        if not spot.EncounterNames then return true end
        local identity=clean(name)
        for expected in pairs(spot.EncounterNames)do if clean(expected)==identity then return true end end
        return false
    end
    local function register(spot)
        catalog.Spots[#catalog.Spots+1]=spot
        catalog.SpotById[spot.Id]=spot
        return spot
    end
    local function alias(key,spot)
        catalog.Aliases[key]=spot.Id
        catalog.SpotById[key]=spot
    end
    local function label(floor,name)return floor.Label.." · "..name end
    for _,definition in ipairs(ctx.Floors)do
        local number=numbers[definition.PlaceId]
        if number then
            local floor={Id=definition.PlaceId,Number=number,Name=definition.Name,Unlocked=ctx.Unlocked(definition)}
            floor.Label=(floor.Id==134019705603409 or floor.Id==78945654064532) and floor.Name or "F"..number.." · "..floor.Name
            catalog.Floors[#catalog.Floors+1]=floor;catalog.FloorById[floor.Id]=floor
        end
    end
    table.sort(catalog.Floors,function(a,b)return a.Number<b.Number end)
    local specialKinds={Leviathan="Boss",["Suspended Unborn"]="Arena",["Limor the Devourer"]="Arena",
        ["Radioactive Experiment"]="Arena",["Za, the Eldest"]="Mini boss",["Wa, the Curious"]="Arena",
        ["Duality Reaper"]="Mini boss",["Atheon arena"]="Arena"}
    for place,points in pairs(source)do
        local floor=catalog.FloorById[place]
        if floor then
            for raw,position in pairs(points)do
                local key=raw:match("^%s*(.-)%s*$")
                local info=supplied[place]and supplied[place][key]
                local kind=info and info.Kind or (key=="Boss"and "Boss")
                    or ((key=="Miniboss"or key=="Second miniboss")and "Mini boss")or specialKinds[key]
                if kind then
                    local name=info and info.Name or (key=="Boss"and "Boss arena")or (key=="Miniboss"and "Mini-boss arena")or key
                    local encounters=info and info.EncounterNames
                    if not encounters and place==13965775911 then encounters={Atheon=true,["Corrupted Atheon"]=true}end
                    if not encounters and place==134019705603409 and key=="Leviathan"then encounters={Leviathan=true}end
                    register({Id=tostring(place).."/"..key,PlaceId=place,Name=name,Kind=kind,Position=position,
                        DestinationId="source:"..key,Floor=floor,Label=label(floor,name),
                        RespawnSeconds=info and info.RespawnSeconds,MainBoss=key=="Boss",
                        PositionLocked=info~=nil or place==13965775911,EncounterNames=encounters})
                end
            end
        end
    end
    local function customAreas(areas,place,floor)
        for id,area in pairs(areas)do
            if id:sub(1,16)=="saved:multispot:"then
                local key=tostring(place).."/"..id
                local existing=catalog.SpotById[key]
                if existing then existing.Position=area.Position
                else register({Id=key,PlaceId=place,Name=area.Name,Kind="Arena",Position=area.Position,
                    DestinationId=id,Floor=floor,Label=label(floor,area.Name),PositionLocked=true})end
            end
        end
    end
    local function refineGeneric(areas,place)
        for _,kind in ipairs({"Boss","Mini boss"})do
            local key=kind=="Boss"and "Boss"or "Miniboss"
            local spot=catalog.SpotById[tostring(place).."/"..key]
            if spot and not spot.PositionLocked then
                local nearest,distance
                for id,area in pairs(areas)do
                    if id:sub(1,4)=="mob:"and area.Kind==kind and accepts(spot,id:sub(5))then
                        local current=(area.Position-spot.Position).Magnitude
                        if not distance or current<distance then nearest,distance=area,current end
                    end
                end
                if nearest then spot.Position=nearest.Position;spot.DestinationId=nearest.Id;spot.SourceRefined=true end
            end
        end
    end
    local function matchArea(area,id,place)
        local name=id:sub(1,4)=="mob:"and id:sub(5)or area.Name
        local primary
        if place==13965775911 and (name=="Atheon"or name=="Corrupted Atheon")then
            primary=catalog.SpotById[tostring(place).."/Atheon arena"]
        end
        if not primary then
            for _,spot in ipairs(catalog.Spots)do
                if spot.PlaceId==place and (spot.Name:lower()==name:lower()or spot.EncounterNames and spot.EncounterNames[name])then
                    primary=spot;break
                end
            end
        end
        if primary then
            if not primary.PositionLocked then
                primary.Position=area.Position;primary.DestinationId=id;primary.Kind=area.Kind;primary.SourceRefined=true
            end
            return primary,name
        end
        local closest
        for _,spot in ipairs(catalog.Spots)do
            if spot.PlaceId==place and accepts(spot,name)
                and (spot.Kind==area.Kind or spot.PositionLocked and spot.Kind=="Arena")then
                local distance=(spot.Position-area.Position).Magnitude
                if distance<=220 and (not closest or distance<closest)then primary,closest=spot,distance end
            end
        end
        return primary,name
    end
    function catalog.AddCurrent(areas,place)
        local floor=catalog.FloorById[place]
        if not floor then return end
        areas=areas or {}
        customAreas(areas,place,floor)
        refineGeneric(areas,place)
        for id,area in pairs(areas)do
            if (area.Kind=="Boss"or area.Kind=="Mini boss")and id:sub(1,7)~="source:"then
                local key=tostring(place).."/"..id
                local spot,name=matchArea(area,id,place)
                if spot then alias(key,spot)
                elseif not supplied[place]then
                    register({Id=key,PlaceId=place,Name=name,Kind=area.Kind,Position=area.Position,
                        DestinationId=id,Floor=floor,Label=label(floor,name)})
                end
            end
        end
    end
    function catalog.NormalizeSelection(selection)
        local normalized={}
        for id,on in pairs(selection or {})do if on then normalized[catalog.Aliases[id]or id]=true end end
        return normalized
    end
    local kindOrder={Boss=1,["Mini boss"]=2,Arena=3}
    function catalog.Sort()
        table.sort(catalog.Spots,function(a,b)
            if a.Floor.Number~=b.Floor.Number then return a.Floor.Number<b.Floor.Number end
            if a.Kind~=b.Kind then return (kindOrder[a.Kind]or 4)<(kindOrder[b.Kind]or 4)end
            if a.Name~=b.Name then return a.Name<b.Name end
            return a.Id<b.Id
        end)
    end
    catalog.Sort()
    return catalog
end
