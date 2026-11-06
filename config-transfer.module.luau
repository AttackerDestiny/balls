-- Portable preferences and custom arenas; never execute imported text as code.
return function(ctx)
    local api={}
    local kinds={}
    for _,key in ipairs({"AutoCreateBetween","AtheonUnlock","CreditCheck","Enabled","AutoFarm","BossOnly","AutoSwing","AutoTrade","AutoEquipBestSword","SafeMode","MultiSpot","AccountProgression","ProgressionBossCleared","ProgressionComplete","AutoOffset","SkillAura","MiscSkillEnabled","AutoExplore","AutoDodge","AtheonDodge","AutoJoinFriend","ViewingPlayer","ViewingPlayerInventory","AutoHideUI","StopEverything"})do kinds[key]="boolean"end
    for _,key in ipairs({"Version","SafeFloorId","ProgressionFloor","Radius","SkillRange","Threat","SkillPerWeaponVersion","SelectedPlayerId"})do kinds[key]="number"end
    for _,key in ipairs({"BetweenAccess","BetweenDifficulty","CreditWhitelistText","TradeMode","JoinFriendUsername","SafeWhitelistText","MultiSpotCursor","MultiSpotPending","ProgressionBossClearedName","AutomationRunId","SelectedSkill","SelectedMiscSkill","Theme","ActiveTab"})do kinds[key]="string"end
    for _,key in ipairs({"AutoCraft","TradeItems","AutoDismantle","SafeWhitelistIds","MultiSpotSelected","MultiSpotOrder","ProgressionRestore","AutomationResumeFeatures","OffsetProfiles","UnsafeOffsetProfiles","SkillPerWeapon","PerformanceBoosters","PanelPosition","HealthHUDPosition","WindUIPosition"})do kinds[key]="table"end
    local function plain(value,depth)
        assert(depth<=12,"Config nesting is too deep")
        local kind=type(value)
        if kind=="number"then assert(value==value and math.abs(value)<1e15,"Invalid config number")
        elseif kind=="table"then
            local count=0
            for key,item in pairs(value)do
                count+=1;assert(count<=4096,"Config table is too large")
                assert(type(key)=="string"or type(key)=="number","Invalid config key")
                plain(item,depth+1)
            end
        else assert(kind=="string"or kind=="boolean","Invalid config value")end
    end
    function api.Validate(value)
        assert(type(value)=="table"and value.Format=="FeatherConfig"and value.Version==1,"Not a Feather config")
        assert(type(value.Settings)=="table"and value.Settings.Version==1,"Invalid settings")
        plain(value,0)
        for key,item in pairs(value.Settings)do assert(kinds[key]and type(item)==kinds[key],"Invalid setting: "..tostring(key))end
        for _,key in ipairs({"PanelPosition","HealthHUDPosition","WindUIPosition"})do
            local position=value.Settings[key]
            if position then
                assert(#position==4,"Invalid UI position")
                for _,coordinate in ipairs(position)do assert(type(coordinate)=="number","Invalid UI position")end
            end
        end
        for _,key in ipairs({"AutoCraft","TradeItems","AutoDismantle","MultiSpotSelected","PerformanceBoosters"})do
            for name,on in pairs(value.Settings[key]or {})do assert(type(name)=="string"and type(on)=="boolean","Invalid selection: "..key)end
        end
        for _,id in ipairs(value.Settings.MultiSpotOrder or {})do assert(type(id)=="string","Invalid spot priority")end
        assert(type(value.CustomSpots)=="table","Missing custom spots")
        local floors=0
        for id,spots in pairs(value.CustomSpots)do
            floors+=1;assert(floors<=64 and tostring(id):match("^%d+$"),"Invalid spot floor")
            assert(type(spots)=="table"and #spots<=20,"Too many custom spots")
            for _,spot in ipairs(spots)do
                assert(type(spot)=="table"and type(spot.Id)=="string"and spot.Id:sub(1,16)=="saved:multispot:","Invalid custom spot")
                assert(type(spot.Name)=="string"and #spot.Name<=200 and type(spot.Position)=="table"and #spot.Position==3,"Invalid spot name/position")
                for _,coordinate in ipairs(spot.Position)do assert(type(coordinate)=="number"and math.abs(coordinate)<=1e7,"Invalid coordinate")end
            end
        end
        return value
    end
    function api.Export()
        local value=api.Validate({Format="FeatherConfig",Version=1,Settings=ctx.Settings(),CustomSpots=ctx.Spots()})
        assert(#ctx.Encode(value.Settings)<=32768,"Settings exceed their storage limit")
        local text=ctx.Encode(value);assert(#text<=262144,"Config exceeds 256 KB")
        assert(type(ctx.Copy)=="function","Clipboard is unavailable in this executor")
        ctx.Copy(text);return text
    end
    function api.Import(text)
        assert(type(text)=="string"and #text<=262144,"Config exceeds 256 KB")
        local value=api.Validate(ctx.Decode(text))
        assert(#ctx.Encode(value.Settings)<=32768,"Settings exceed their storage limit")
        ctx.Apply(value)
        return true
    end
    return api
end
