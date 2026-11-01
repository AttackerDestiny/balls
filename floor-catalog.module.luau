-- Source-provided arena coordinates; current-floor discoveries may refine them.
return function(ctx)
    local source = {
        [542351431] = { -- floor 1
            Boss = Vector3.new(-2977.1355, -229.28125, 1221.8555),
            Portal = Vector3.new(-2940.8562, -207.597794, 982.687012),
            Miniboss = Vector3.new(139.343933, 225.040985, -132.926147)
        },
        [548231754] = { -- floor 2
            Boss = Vector3.new(-2013.0431, 445.54346, -8953.9512),
            Portal = Vector3.new(-2181.09204, 466.482727, -8955.31055)
        },
        [555980327] = { -- floor 3
            Boss = Vector3.new(448.331146, 4279.3374, -385.050385),
            Portal = Vector3.new(-381.196564, 4184.99902, -327.238312)
        },
        [572487908] = { -- floor 4
            Boss = Vector3.new(-2318.12964, 2280.41992, -514.067749),
            Portal = Vector3.new(-2319.54028, 2091.30078, -106.37648),
            Miniboss = Vector3.new(-1361.35596, 5173.21387, -390.738007)
        },
        [580239979] = { -- floor 5
            Boss = Vector3.new(2189.17822, 1308.125, -121.071182),
            Portal = Vector3.new(2188.29614, 1255.37036, -407.864594)
        },
        [582198062] = { -- floor 7
            Boss = Vector3.new(3347.78955, 800.043884, -804.310425),
            Portal = Vector3.new(3336.35645, 747.824036, -614.307983)
        },
        [548878321] = { -- floor 8
            Boss = Vector3.new(1848.35413, 4110.43945, 7723.38623),
            Portal = Vector3.new(1665.46252, 4094.20312, 7722.29443),
            Miniboss = Vector3.new(-811.7854, 3179.59814, -949.255676)
        },
        [573267292] = { -- floor 9
            Boss = Vector3.new(12241.4648, 461.776215, -3655.09009),
            Portal = Vector3.new(12357.0059, 439.948914, -3470.23218),
            Miniboss = Vector3.new(1928, 2889, -11349),
            ['Second miniboss'] = Vector3.new(1973.94238, 2986.00952, -4486.8125)
        },
        [2659143505] = { -- floor 10
            Boss = Vector3.new(45.494194, 1003.77246, 25432.9902),
            Portal = Vector3.new(110.383698, 940.75531, 24890.9922),
            Miniboss = Vector3.new(-894.185791, 467.646698, 6505.85254)
        },
        [5287433115] = { -- floor 11
            Boss = Vector3.new(4916.49414, 2312.97021, 7762.28955),
            Portal = Vector3.new(5224.18994, 2602.94019, 6438.44678),
            Miniboss = Vector3.new(4801.12695, 1646.30347, 2083.19116),
            ['Za, the Eldest'] = Vector3.new(4001.55908, 421.515015, -3794.19727),
            ['Wa, the Curious'] = Vector3.new(4821.5874, 3226.32788, 5868.81787),
            ['Duality Reaper  '] = Vector3.new(4763.06934, 501.713593, -4344.83838),
            ['Neon chest       '] = Vector3.new(5204.35449, 2294.14502, 5778.00195)
        },
        [13965775911] = { -- Atheon / floor 13 (user-provided arena)
            ['Atheon arena'] = Vector3.new(840, 798, 336)
        },
        [6144637080] = { -- floor 12
            ['Suspended Unborn'] = Vector3.new(-5324.62305, 427.934784, 3754.23682),
            ['Limor the Devourer'] = Vector3.new(-1093.02625, -169.141785, 7769.1875),
            ['Radioactive Experiment'] = Vector3.new(-4643.86816, 425.090515, 3782.8252)
        }
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
    local extraKinds={['Suspended Unborn']='Arena',['Limor the Devourer']='Arena',['Radioactive Experiment']='Arena',
        ['Za, the Eldest']='Mini boss',['Wa, the Curious']='Arena',['Duality Reaper']='Mini boss',['Atheon arena']='Arena'}
    for placeId,areas in pairs(source) do
        local floor=catalog.FloorById[placeId]
        if floor then for original,point in pairs(areas) do
            local key=original:match('^%s*(.-)%s*$')
            local kind=key=='Boss' and 'Boss' or (key=='Miniboss' or key=='Second miniboss') and 'Mini boss' or extraKinds[key]
            if kind then
                local name=key=='Boss' and 'Boss arena' or key=='Miniboss' and 'Mini-boss arena' or key
                local spot={Id=tostring(placeId)..'/'..key,PlaceId=placeId,Name=name,Kind=kind,Position=point,
                    DestinationId='source:'..key,Floor=floor,Label=floor.Label..' · '..name,
                    MainBoss=key=='Boss',PositionLocked=(placeId==573267292 and key=='Miniboss') or placeId==13965775911,
                    EncounterNames=placeId==13965775911 and {Atheon=true,['Corrupted Atheon']=true}
                        or (key=='Boss' and mainBossNames[placeId]) or nil}
                catalog.Spots[#catalog.Spots+1]=spot;catalog.SpotById[spot.Id]=spot
            end
        end end
    end
    function catalog.AddCurrent(areas,placeId)
        local floor=catalog.FloorById[placeId];if not floor then return end
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
                        if not primary and spot.PlaceId==placeId and spot.Name:lower()==name:lower() then primary=spot;break end
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
                    else
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
