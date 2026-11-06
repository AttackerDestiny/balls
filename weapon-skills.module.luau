-- Equipment changes invalidate casts; a settled snapshot selects one usable skill.
return function(ctx)
    local state=ctx.State
    local api={Ready=false,Version=0,Style="",Skills={}}
    local defaults={SingleSword="Sweeping Strike",["2HSword"]="Downward Smash",DualWield="Whirlwind Spin",
        Rapier="Piercing Dash",Katana="Leaping Slash",Spear="Beam Rush",Scythe="Reaper Frenzy"}
    local aliases={singlesword="SingleSword",["1hsword"]="SingleSword",["2hsword"]="2HSword",
        dualwield="DualWield",rapier="Rapier",katana="Katana",spear="Spear",scythe="Scythe"}
    local preferences=state.SkillPerWeaponVersion==2 and type(state.SkillPerWeapon)=="table"and state.SkillPerWeapon or {}
    state.SkillPerWeapon=preferences;state.SkillPerWeaponVersion=2
    local available={}
    local observed={Key=nil,Character=nil}
    local pending,settleAt,pollAt,refreshAt=true,0,0,0
    function api.Class(style)
        local label=tostring(style or "")
        return aliases[label:lower():gsub("[^%w]","")]or label
    end
    local function cancel(reason)if ctx.Cancel then ctx.Cancel(reason)end end
    function api.Notify(reason,now)
        pending=true;settleAt=(now or os.clock())+.18
        api.Ready=false;api.Version+=1;state.SkillWeaponVersion=api.Version
        state.SkillStatus=reason or "Updating equipped weapon skills"
        cancel(reason or "Equipment changed")
    end
    function api.Choices()return api.Skills end
    function api.IsCompatible(name)return api.Ready and available[name]~=nil end
    local function publish(name)
        state.SelectedSkill=name or "";state.SkillWeaponStyle=api.Style
        if ctx.Changed then ctx.Changed(state.SelectedSkill,api.Skills)end
    end
    function api.Select(name)
        if not api.IsCompatible(name)then return false end
        if state.SelectedSkill~=name then cancel("Selected skill changed")end
        preferences[api.Style]=name;publish(name);return true
    end
    local function resolve(snapshot)
        local oldStyle=api.Style
        api.Style=api.Class(snapshot.Style)
        local list={};available={}
        for _,entry in ipairs(snapshot.Skills)do
            if entry.Allowed and not available[entry.Name]then available[entry.Name]=entry;list[#list+1]=entry.Name end
        end
        table.sort(list);api.Skills=list
        local choice
        if available["Summon Pistol"]then choice="Summon Pistol"
        elseif available[preferences[api.Style]]then choice=preferences[api.Style]
        elseif (oldStyle==""or oldStyle==api.Style)and available[state.SelectedSkill]then choice=state.SelectedSkill
        elseif available[defaults[api.Style]]then choice=defaults[api.Style]
        else choice=list[1]end
        if (choice or "")~=state.SelectedSkill then cancel("Available skill changed")end
        if oldStyle==""and choice and choice~="Summon Pistol"then preferences[api.Style]=choice end
        api.Ready=true;publish(choice)
    end
    function api.Update(now)
        now=now or os.clock()
        if not pending and now<pollAt then return end
        pollAt=now+.25
        local key,character=ctx.Key()
        if key~=observed.Key or character~=observed.Character then
            observed.Key,observed.Character=key,character;api.Notify("Equipped weapon changed",now)
        end
        if not pending and now>=refreshAt then pending=true;settleAt=now end
        if not pending or now<settleAt then return end
        resolve(ctx.Read());pending=false;refreshAt=now+2
    end
    return api
end
