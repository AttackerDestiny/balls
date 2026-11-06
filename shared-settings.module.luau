-- Merge only this account's changed preference fields into the latest shared file.
return function(ctx)
    local file="SB2Codex/shared-settings.json"
    local fields={"CreditCheck","CreditWhitelistText","AutoCraft","AutoTrade","TradeMode","TradeItems","AutoDismantle","AutoEquipBestSword","Enabled","AutoFarm","BossOnly","AutoSwing","SkillAura","SelectedSkill","SkillPerWeapon","SkillPerWeaponVersion",
        "MiscSkillEnabled","SelectedMiscSkill","AutoDodge","AtheonDodge","TransparentMap","PerformanceBoosters","AutoJoinFriend","JoinFriendUsername","SafeMode","SafeFloorId","SafeWhitelistText","SafeWhitelistIds","MultiSpot","MultiSpotSelected","MultiSpotOrder","Theme","AccountProgression","PanelPosition","HealthHUDPosition","WindUIPosition","AutoHideUI"}
    local function project(settings)
        local result={Version=1}
        for _,name in ipairs(fields)do result[name]=settings[name]end
        return result
    end
    local function decode(path)
        local bytes=ctx.Read(path)
        assert(#bytes<=32768,"Settings file exceeds its size limit")
        local value=ctx.Decode(bytes)
        assert(type(value)=="table"and value.Version==1,"Invalid shared settings")
        return project(value)
    end
    local function rank(settings)
        local whitelist=type(settings.SafeWhitelistText)=="string"and settings.SafeWhitelistText:find("%S")
        local points=whitelist and 1000 or 0
        for key,weight in pairs({SafeMode=10,AccountProgression=5,Enabled=1,AutoFarm=1})do if settings[key]==true then points+=weight end end
        return points
    end
    local function migrate()
        local best=ctx.Current or {}
        if ctx.List and rank(best)<1000 then
            local ok,paths=pcall(ctx.List,"SB2Codex")
            if ok and type(paths)=="table"then
                table.sort(paths)
                for i=1,math.min(200,#paths)do
                    if paths[i]:match("settings_%d+%.json$")then
                        local readable,candidate=pcall(decode,paths[i])
                        if readable and rank(candidate)>rank(best)then best=candidate end
                    end
                end
            end
        end
        local value=project(best);ctx.Write(file,ctx.Encode(value));return value
    end
    local api={Values=ctx.IsFile(file)and decode(file)or migrate()}
    if api.Values.SafeFloorId==nil and ctx.Current and type(ctx.Current.SafeFloorId)=="number"then
        api.Values.SafeFloorId=ctx.Current.SafeFloorId;ctx.Write(file,ctx.Encode(api.Values))
    end
    local function fingerprint(settings)
        local result={}
        for _,name in ipairs(fields)do result[name]=ctx.Encode({Value=settings[name]})end
        return result
    end
    local localRevision=fingerprint(api.Values)
    function api.ReadSafeFloor()
        if ctx.IsFile(file)then return tonumber(decode(file).SafeFloorId)end
        return nil
    end
    function api.Save(settings)
        local nextLocal=project(settings)
        local revision=fingerprint(nextLocal)
        local edits={}
        for _,name in ipairs(fields)do if revision[name]~=localRevision[name]then edits[#edits+1]=name end end
        local exists=ctx.IsFile(file)
        if exists and #edits==0 then return end
        local merged=exists and decode(file)or project(api.Values)
        for _,name in ipairs(edits)do merged[name]=nextLocal[name]end
        ctx.Write(file,ctx.Encode(merged))
        localRevision=revision;api.Values=merged
    end
    return api
end
