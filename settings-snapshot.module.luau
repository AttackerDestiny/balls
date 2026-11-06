-- A reload retains settings, never the previous runtime's instances or closures.
return function(previous,userId)
    if not previous or previous.UserId~=userId then return nil end
    local fields={"AutoCreateBetween","BetweenAccess","BetweenDifficulty","AtheonUnlock","AccountProgression","ActiveTab","AtheonDodge","AutoCraft","AutoDismantle","AutoDodge",
        "AutoEquipBestSword","AutoExplore","AutoFarm","AutoHideUI","AutoJoinFriend","AutoSwing","AutoTrade",
        "AutomationResumeFeatures","AutomationRunId","BossOnly","CreditCheck","CreditWhitelistText","Enabled",
        "HealthHUDPosition","JoinFriendUsername","MiscSkillEnabled","MultiSpot","MultiSpotCursor","MultiSpotOrder",
        "MultiSpotPending","MultiSpotSelected","OffsetProfiles","PerformanceBoosters","ProgressionBossCleared",
        "ProgressionBossClearedName","ProgressionComplete","ProgressionFloor","ProgressionRestore","ResumeFeatures",
        "ResumeRequested","SafeFloorId","SafeMode","SafeWhitelistIds","SafeWhitelistText","SelectedMiscSkill",
        "SelectedPlayerId","SelectedSkill","SkillAura","SkillPerWeapon","SkillPerWeaponVersion","StopEverything",
        "Theme","TradeItems","TradeMode","UnsafeOffsetProfiles","UserId","ViewingPlayer","ViewingPlayerInventory","WindUIPosition"}
    local count=0
    local function copy(value,depth,seen)
        local kind=type(value)
        if kind=="boolean"or kind=="string"or kind=="number"then return value end
        if kind~="table"or depth>8 or seen[value]then return nil end
        local result={};seen[value]=true
        for key,item in pairs(value)do
            if count>=4096 then break end
            if type(key)=="number"or type(key)=="string"then
                count+=1
                result[key]=copy(item,depth+1,seen)
            end
        end
        seen[value]=nil
        return result
    end
    local snapshot={}
    for _,key in ipairs(fields)do snapshot[key]=copy(previous[key],0,{})end
    snapshot.ActiveTab=previous.UI and previous.UI.ActiveTab or snapshot.ActiveTab
    snapshot.FarmPosition=previous.OffsetMode
    return snapshot
end
