-- Strict portable-data schema; imported bytes are decoded only, never executed.
return function(ctx)
    local schema={}
    local groups={
        boolean={"NoSelfDamage","AeganatosDodge","AtheonUnlock","AutoCreateBetween","CreditCheck","Enabled","AutoFarm","BossOnly","AutoSwing","AutoTrade","AutoEquipBestSword","SafeMode","MultiSpot","AccountProgression","ProgressionBossCleared","ProgressionComplete","AutoOffset","SkillAura","MiscSkillEnabled","AutoExplore","AutoDodge","AtheonDodge","TransparentMap","AutoJoinFriend","ViewingPlayer","ViewingPlayerInventory","AutoHideUI","StopEverything"},
        number={"Version","SafeFloorId","ProgressionFloor","Radius","SkillRange","Threat","SkillPerWeaponVersion","SelectedPlayerId"},
        string={"BetweenAccess","BetweenDifficulty","CreditWhitelistText","TradeMode","JoinFriendUsername","SafeWhitelistText","MultiSpotCursor","MultiSpotPending","ProgressionBossClearedName","AutomationRunId","SelectedSkill","SelectedMiscSkill","Theme","ActiveTab"},
        table={"BetweenRooms","BetweenPace","AutoCraft","TradeItems","AutoDismantle","SafeWhitelistIds","MultiSpotSelected","MultiSpotOrder","ProgressionRestore","AutomationResumeFeatures","OffsetProfiles","UnsafeOffsetProfiles","SkillPerWeapon","PerformanceBoosters","PanelPosition","HealthHUDPosition","WindUIPosition"},
    }
    for kind,names in pairs(groups)do for _,name in ipairs(names)do schema[name]=kind end end
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
    function api.Validate(package)
        assert(type(package)=="table"and package.Format=="FeatherConfig"and package.Version==1,"Not a Feather config")
        data(package,0,{})
        settings(package.Settings);arenas(package.CustomSpots)
        return package
    end
    local function withinStorage(package)
        assert(#ctx.Encode(package.Settings)<=32768,"Settings exceed their storage limit")
    end
    function api.Export()
        local package=api.Validate({Format="FeatherConfig",Version=1,Settings=ctx.Settings(),CustomSpots=ctx.Spots()})
        withinStorage(package)
        local bytes=ctx.Encode(package)
        assert(#bytes<=262144,"Config exceeds 256 KB")
        assert(type(ctx.Copy)=="function","Clipboard is unavailable in this executor")
        ctx.Copy(bytes)
        return bytes
    end
    function api.Import(bytes)
        assert(type(bytes)=="string"and #bytes<=262144,"Config exceeds 256 KB")
        local package=api.Validate(ctx.Decode(bytes));withinStorage(package)
        ctx.Apply(package)
        return true
    end
    return api
end
