-- Strict portable-data schema; imported bytes are decoded only, never executed.
return function(ctx)
    local schema={}
    local groups={
        boolean={"NoSelfDamage","AeganatosDodge","AtheonUnlock","AutoCreateBetween","AutoRegroup","CreditCheck","Enabled","AutoFarm","BossOnly","AutoSwing","AutoTrade","AutoEquipBestSword","SafeMode","AntiSuspicious","MultiSpot","AccountProgression","ProgressionBossCleared","ProgressionComplete","AutoOffset","SkillAura","MiscSkillEnabled","AutoExplore","AutoDodge","AtheonDodge","TransparentMap","AutoJoinFriend","ViewingPlayer","ViewingPlayerInventory","AutoHideUI","StopEverything"},
        number={"Version","SafeFloorId","ProgressionFloor","Radius","SkillRange","Threat","SkillPerWeaponVersion","SelectedPlayerId"},
        string={"BetweenAccess","BetweenDifficulty","AutoRegroupUsers","CreditWhitelistText","TradeMode","JoinFriendUsername","SafeWhitelistText","MultiSpotCursor","MultiSpotPending","ProgressionBossClearedName","AutomationRunId","SelectedSkill","SelectedMiscSkill","Theme","ActiveTab"},
        table={"BetweenRooms","BetweenPace","AntiSuspiciousLimits","AutoCraft","TradeItems","AutoDismantle","SafeWhitelistIds","MultiSpotSelected","MultiSpotOrder","ProgressionRestore","AutomationResumeFeatures","OffsetProfiles","UnsafeOffsetProfiles","SkillPerWeapon","PerformanceBoosters","PanelPosition","HealthHUDPosition","WindUIPosition"},
    }
    for kind,names in pairs(groups)do for _,name in ipairs(names)do schema[name]=kind end end
    schema.FarmDesync="boolean" -- Accept older exports before stripping the retired field.
    local function data(value,depth,path)
        assert(depth<=12,"Config nesting is too deep")
        local kind=type(value)
        if kind=="number"then assert(value==value and math.abs(value)<1e15,"Invalid config number");return end
        if kind~="table"then assert(kind=="string"or kind=="boolean","Invalid config value");return end
        assert(not path[value],"Config cannot contain cycles")
        path[value]=true
        local total=0
        for key,child in pairs(value)do
            total+=1;assert(total<=4096,"Config table is too large")
            assert(type(key)=="string"or type(key)=="number","Invalid config key")
            data(child,depth+1,path)
        end
        path[value]=nil
    end
    local function tuple(value,count,limit)
        assert(type(value)=="table"and #value==count,"Invalid position")
        for _,coordinate in ipairs(value)do assert(type(coordinate)=="number"and (not limit or math.abs(coordinate)<=limit),"Invalid coordinate")end
    end
    local function settings(value)
        assert(type(value)=="table"and value.Version==1,"Invalid settings")
        for key,item in pairs(value)do assert(schema[key]and type(item)==schema[key],"Invalid setting: "..tostring(key))end
        for _,name in ipairs({"PanelPosition","HealthHUDPosition","WindUIPosition"})do if value[name]then tuple(value[name],4)end end
        for _,name in ipairs({"AutoCraft","TradeItems","AutoDismantle","MultiSpotSelected","PerformanceBoosters"})do
            for option,on in pairs(value[name]or {})do assert(type(option)=="string"and type(on)=="boolean","Invalid selection: "..name)end
        end
        for _,id in ipairs(value.MultiSpotOrder or {})do assert(type(id)=="string","Invalid spot priority")end
        local rooms=value.BetweenRooms or {}
        local access={Private=true,Friends=true,["Game Party"]=true}
        local difficulties={Normal=true,Hard=true,Elite=true}
        assert(#rooms<=20,"Too many Between rooms")
        for index,room in pairs(rooms)do
            assert(type(index)=="number" and index%1==0 and index>=1 and index<=#rooms
                and type(room)=="table" and type(room.Host)=="string" and #room.Host<=64
                and type(room.Alt)=="string" and #room.Alt<=256
                and (room.Mode==nil or access[room.Mode])
                and (room.Difficulty==nil or difficulties[room.Difficulty])
                and (room.Start==nil or type(room.Start)=="boolean")
                and (room.AutoRetry==nil or type(room.AutoRetry)=="boolean"),"Invalid Between room")
        end
        local function minute(v)return type(v)=="number" and v%1==0 and v>=0 and v<=100 end
        for mode,range in pairs(value.BetweenPace or {})do
            assert(difficulties[mode] and (minute(range) or (type(range)=="table"
                and minute(range.Min) and minute(range.Max) and range.Min<=range.Max)),"Invalid Between completion time")
        end
        local limits=value.AntiSuspiciousLimits
        if limits then
            local function integer(v,max)return type(v)=="number" and v%1==0 and v>=1 and v<=max end
            assert(integer(limits.Hops,100) and integer(limits.Window,200) and integer(limits.Min,200)
                and integer(limits.Max,200) and limits.Min<=limits.Max,"Invalid Anti Suspicious limits")
        end
    end
    local function arenas(value)
        assert(type(value)=="table","Missing custom spots")
        local count=0
        for floor,spots in pairs(value)do
            count+=1;assert(count<=64 and tostring(floor):match("^%d+$"),"Invalid spot floor")
            assert(type(spots)=="table"and #spots<=20,"Too many custom spots")
            for _,spot in ipairs(spots)do
                assert(type(spot)=="table"and type(spot.Id)=="string"and spot.Id:sub(1,16)=="saved:multispot:","Invalid custom spot")
                assert(type(spot.Name)=="string"and #spot.Name<=200,"Invalid spot name/position")
                tuple(spot.Position,3,1e7)
            end
        end
    end
    local api={}
    local snapshotLimit=262144
    local libraryLimit=64*1024*1024
    local function snapshot(value)
        data(value,0,{})
        settings(value.Settings);arenas(value.CustomSpots)
    end
    local excludedSettings={"ProgressionFloor","ProgressionBossCleared","ProgressionBossClearedName","ProgressionComplete","ProgressionRestore","FarmDesync"}
    local function portable(item)
        local filtered
        for _,field in ipairs(excludedSettings)do
            if item.Settings[field]~=nil then
                filtered=filtered or table.clone(item.Settings)
                filtered[field]=nil
            end
        end
        if not filtered then return item end
        local copy=table.clone(item);copy.Settings=filtered
        return copy
    end
    function api.Validate(package)
        assert(type(package)=="table"and package.Format=="FeatherConfig"and package.Version==1,"Not a Feather config")
        for key in pairs(package)do
            assert(key=="Format" or key=="Version" or key=="Settings" or key=="CustomSpots" or key=="Presets","Invalid config field")
        end
        snapshot({Settings=package.Settings,CustomSpots=package.CustomSpots})
        local library=package.Presets
        if library~=nil then
            assert(type(library)=="table" and type(library.Items)=="table" and type(library.Auto)=="boolean","Invalid preset library")
            local count=#library.Items
            assert(count>=1 and count<=200,"Invalid preset count")
            for _,key in ipairs({"Active","Manual","Outside","Between"})do
                local id=library[key]
                assert(type(id)=="number" and id%1==0 and id>=0 and id<=count,"Invalid preset selection: "..key)
            end
            local total=0
            for id,item in pairs(library.Items)do
                assert(type(id)=="number" and id%1==0 and id>=1 and id<=count and type(item)=="table","Invalid preset entry")
                snapshot(item);total+=1
            end
            assert(total==count,"Invalid preset list")
        end
        -- Drop account checkpoints and retired preferences from portable settings.
        local clean=portable(package)
        if library then
            clean=table.clone(clean);clean.Presets=table.clone(library)
            clean.Presets.Items={}
            for id,item in ipairs(library.Items)do clean.Presets.Items[id]=portable(item)end
        end
        return clean
    end
    local function withinStorage(package)
        local function check(item)
            assert(#ctx.Encode(item.Settings)<=32768,"Settings exceed their storage limit")
            local stored={Format="FeatherConfig",Version=1,Settings=item.Settings,CustomSpots=item.CustomSpots}
            assert(#ctx.Encode(stored)<=snapshotLimit,"A preset exceeds 256 KB")
        end
        check(package)
        if package.Presets then for _,item in ipairs(package.Presets.Items)do check(item)end end
    end
    function api.Export()
        local active={Settings=ctx.Settings(),CustomSpots=ctx.Spots()}
        local package=api.Validate({Format="FeatherConfig",Version=1,Settings=active.Settings,CustomSpots=active.CustomSpots,
            Presets=ctx.Presets and ctx.Presets(active)})
        withinStorage(package)
        local bytes=ctx.Encode(package)
        assert(#bytes<=(package.Presets and libraryLimit or snapshotLimit),"Config exceeds its size limit")
        assert(type(ctx.Copy)=="function","Clipboard is unavailable in this executor")
        ctx.Copy(bytes)
        return bytes
    end
    function api.Import(bytes)
        assert(type(bytes)=="string"and #bytes<=libraryLimit,"Config exceeds its size limit")
        local package=api.Validate(ctx.Decode(bytes))
        assert(package.Presets or #bytes<=snapshotLimit,"Config exceeds 256 KB")
        withinStorage(package)
        return ctx.Apply(package)or true
    end
    return api
end
