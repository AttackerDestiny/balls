-- Copy a schema of plain preferences using bounded iterative traversal.
return function(previous,userId)
    if type(previous)~="table"or previous.UserId~=userId then return nil end
    local fields={"AccountProgression","ActiveTab","AtheonDodge","AutoCraft","AutoDismantle","AutoDodge",
        "AutoEquipBestSword","AutoExplore","AutoFarm","AutoHideUI","AutoJoinFriend","AutoSwing","AutoTrade",
        "AutomationResumeFeatures","AutomationRunId","BossOnly","NoSelfDamage","AeganatosDodge","AtheonUnlock","AutoCreateBetween","BetweenRooms","BetweenPace","BetweenAccess","BetweenDifficulty","CreditCheck","CreditWhitelistText","Enabled",
        "HealthHUDPosition","JoinFriendUsername","MiscSkillEnabled","MultiSpot","MultiSpotCursor","MultiSpotOrder",
        "MultiSpotPending","MultiSpotSelected","OffsetProfiles","PerformanceBoosters","ProgressionBossCleared",
        "ProgressionBossClearedName","ProgressionComplete","ProgressionFloor","ProgressionRestore","ResumeFeatures",
        "ResumeRequested","SafeFloorId","SafeMode","SafeWhitelistIds","SafeWhitelistText","AntiSuspicious","AntiSuspiciousLimits","SelectedMiscSkill",
        "SelectedPlayerId","SelectedSkill","SkillAura","SkillPerWeapon","SkillPerWeaponVersion","StopEverything",
        "Theme","TradeItems","TradeMode","UnsafeOffsetProfiles","UserId","ViewingPlayer","ViewingPlayerInventory","WindUIPosition"}
    local result={}
    local budget=4096
    local function primitive(value)
        local kind=type(value)
        return kind=="string"or kind=="number"or kind=="boolean"
    end
    for _,field in ipairs(fields)do
        local value=previous[field]
        if primitive(value)then result[field]=value
        elseif type(value)=="table"then
            local target={};result[field]=target
            local stack={{Source=value,Target=target,Depth=0,Ancestors={[value]=true}}}
            while #stack>0 and budget>0 do
                local work=table.remove(stack)
                for key,item in pairs(work.Source)do
                    if budget==0 then break end
                    if type(key)=="string"or type(key)=="number"then
                        budget-=1
                        if primitive(item)then work.Target[key]=item
                        elseif type(item)=="table"and work.Depth<8 and not work.Ancestors[item]then
                            local child={};work.Target[key]=child
                            local ancestry=table.clone(work.Ancestors);ancestry[item]=true
                            stack[#stack+1]={Source=item,Target=child,Depth=work.Depth+1,Ancestors=ancestry}
                        end
                    end
                end
            end
        end
    end
    if type(previous.UI)=="table"and type(previous.UI.ActiveTab)=="string"then result.ActiveTab=previous.UI.ActiveTab end
    return result
end
