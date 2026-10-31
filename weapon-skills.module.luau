-- Re-resolve equipped item IDs/classes as the supplied source does, rather
-- than carrying a skill's old weapon reference across equipment changes.
return function(ctx)
    local state=ctx.State
    local api={Ready=false,Version=0,Style="",Skills={}}
    local allowed,dirty={},true
    local lastKey,lastCharacter,settleUntil,nextPoll,nextRecheck=nil,nil,0,0,0
    local preferred=type(state.SkillPerWeapon)=="table" and state.SkillPerWeapon or {}
    if state.SkillPerWeaponVersion~=2 then preferred={} end
    state.SkillPerWeapon=preferred
    state.SkillPerWeaponVersion=2
    local defaults={SingleSword="Sweeping Strike",["2HSword"]="Downward Smash",DualWield="Whirlwind Spin",
        Rapier="Piercing Dash",Katana="Leaping Slash",Spear="Beam Rush",Scythe="Reaper Frenzy"}
    function api.Class(value)
        local key=string.lower((string.gsub(tostring(value or ""),"[^%w]","")))
        if key=="1hsword" or key=="singlesword" then return "SingleSword" end
        if key=="2hsword" then return "2HSword" end
        for name in pairs(defaults) do if string.lower(name)==key then return name end end
        return tostring(value or "")
    end
    function api.Notify(reason,now)
        api.Version+=1; api.Ready=false; dirty=true
        settleUntil=(now or os.clock())+.18
        state.SkillWeaponVersion=api.Version
        state.SkillStatus=reason or "Updating equipped weapon skills"
        if ctx.Cancel then ctx.Cancel(reason or "Equipment changed") end
    end
    function api.Choices() return api.Skills end
    function api.IsCompatible(name) return api.Ready and allowed[name]~=nil end
    function api.Select(name)
        if not api.IsCompatible(name) then return false end
        if name~=state.SelectedSkill and ctx.Cancel then ctx.Cancel("Selected skill changed") end
        state.SelectedSkill=name
        preferred[api.Style]=name
        if ctx.Changed then ctx.Changed(name,api.Skills) end
        return true
    end
    function api.Update(now)
        now=now or os.clock()
        if now<nextPoll and not dirty then return end
        nextPoll=now+.25
        local key,character=ctx.Key()
        if key~=lastKey or character~=lastCharacter then
            lastKey,lastCharacter=key,character
            api.Notify("Equipped weapon changed",now)
        end
        if not dirty and now>=nextRecheck then dirty=true; settleUntil=now end
        if not dirty or now<settleUntil then return end
        local snapshot=ctx.Read()
        allowed={}; api.Skills={}
        local previousStyle=api.Style
        api.Style=api.Class(snapshot.Style)
        for _,skill in ipairs(snapshot.Skills) do
            if skill.Allowed then allowed[skill.Name]=skill; api.Skills[#api.Skills+1]=skill.Name end
        end
        table.sort(api.Skills)
        local selected=preferred[api.Style]
        if not allowed[selected] then
            selected=(previousStyle=="" or previousStyle==api.Style) and allowed[state.SelectedSkill] and state.SelectedSkill or nil
        end
        if not selected then selected=allowed[defaults[api.Style]] and defaults[api.Style] or api.Skills[1] end
        if selected~=(state.SelectedSkill~="" and state.SelectedSkill or nil) and ctx.Cancel then ctx.Cancel("Available skill changed") end
        state.SelectedSkill=selected or ""
        state.SkillWeaponStyle=api.Style
        api.Ready=true; dirty=false; nextRecheck=now+2
        if selected and previousStyle=="" then preferred[api.Style]=selected end
        if ctx.Changed then ctx.Changed(state.SelectedSkill,api.Skills) end
    end
    return api
end
