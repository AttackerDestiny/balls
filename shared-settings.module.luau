-- Shared preferences only; account progress and resume tickets remain private.
return function(ctx)
    local api={Values={}}
    local path="SB2Codex/shared-settings.json"
    local keys={"AtheonUnlock","CreditCheck","CreditWhitelistText","AutoCraft","AutoTrade","TradeMode","TradeItems","AutoDismantle","AutoEquipBestSword","Enabled","AutoFarm","BossOnly","AutoSwing","SkillAura","SelectedSkill","SkillPerWeapon","SkillPerWeaponVersion",
        "MiscSkillEnabled","SelectedMiscSkill","AutoDodge","AtheonDodge","TransparentMap","PerformanceBoosters",
        "AutoJoinFriend","JoinFriendUsername","SafeMode","SafeFloorId","SafeWhitelistText","SafeWhitelistIds","MultiSpot","MultiSpotSelected","MultiSpotOrder",
        "Theme","AccountProgression","PanelPosition","HealthHUDPosition","WindUIPosition","AutoHideUI"}
    local function select(value)
        local result={Version=1}
        for _,key in ipairs(keys)do result[key]=value[key]end
        return result
    end
    local function read(file)
        local raw=ctx.Read(file);assert(#raw<=32768,"Settings file exceeds its size limit")
        local value=ctx.Decode(raw);assert(type(value)=="table"and value.Version==1,"Invalid shared settings")
        return value
    end
    local function score(value)
        return (type(value.SafeWhitelistText)=="string"and value.SafeWhitelistText:find("%S")and 1000 or 0)
            +(value.SafeMode==true and 10 or 0)+(value.AccountProgression==true and 5 or 0)
            +(value.Enabled==true and 1 or 0)+(value.AutoFarm==true and 1 or 0)
    end
    if ctx.IsFile(path)then api.Values=select(read(path))
    else
        local seed=ctx.Current or{}
        if type(ctx.List)=="function"and score(seed)<1000 then
            local ok,files=pcall(ctx.List,"SB2Codex")
            if ok and type(files)=="table"then
                table.sort(files)
                for index,file in ipairs(files)do
                    if index>200 then break end
                    if file:match("settings_%d+%.json$")then
                        local valid,value=pcall(read,file)
                        if valid and score(value)>score(seed)then seed=value end
                    end
                end
            end
        end
        api.Values=select(seed);ctx.Write(path,ctx.Encode(api.Values))
    end
    if api.Values.SafeFloorId==nil and ctx.Current and type(ctx.Current.SafeFloorId)=="number"then
        api.Values.SafeFloorId=ctx.Current.SafeFloorId
        ctx.Write(path,ctx.Encode(api.Values))
    end
    function api.ReadSafeFloor()
        if not ctx.IsFile(path)then return nil end
        return tonumber(read(path).SafeFloorId)
    end
    local function signatures(value)
        local result={}
        for _,key in ipairs(keys)do result[key]=ctx.Encode({Value=value[key]})end
        return result
    end
    -- Keep this runtime's last local values, separately from other accounts' edits.
    local last=signatures(api.Values)
    function api.Save(value)
        local shared=select(value)
        local current=signatures(shared)
        local changed={}
        for _,key in ipairs(keys)do if current[key]~=last[key]then changed[#changed+1]=key end end
        local exists=ctx.IsFile(path)
        if #changed==0 and exists then return end
        local merged=exists and select(read(path))or select(api.Values)
        for _,key in ipairs(changed)do merged[key]=shared[key]end
        ctx.Write(path,ctx.Encode(merged))
        last=current;api.Values=merged
    end
    return api
end
