-- Rank only owned, level-usable items using the native inventory display formula.
return function(ctx)
    local api={Dirty=true}
    local pending,nextRead,failures=nil,0,0
    local swordClasses={['1HSword']=true,['2HSword']=true,Rapier=true,Katana=true}
    local function effective(item,stat,snapshot)
        local value=tonumber(item.Stats[stat])
        if not value then return 0 end
        if item.Scale then value*=item.Scale*snapshot.Level end
        if item.MatchBest then value+=(snapshot.Highest[stat] or 0)*item.MatchBest end
        value=math.floor(value)
        local maximum=ctx.Rarity.RarityUpgrades[item.Rarity] or ctx.Rarity.RarityUpgrades.Common
        if maximum and item.Upgrade>0 then
            local multiplier=ctx.Rarity.UpgradeLevelMultipliers[maximum] or ctx.Rarity.UpgradeLevelMultipliers.default
            if stat=="Damage" then multiplier=tonumber(item.Stats.DamageUpgrade) or multiplier
            else multiplier=ctx.Rarity.UpgradeLevelMultipliers.default end
            value=math.floor(value+item.Upgrade/maximum*multiplier*value)
        end
        return value
    end
    function api.Plan(snapshot)
        local swords,armor,accessories={},{},{}
        local equipped={};for _,id in pairs(snapshot.Equip)do equipped[id]=true end
        for _,item in ipairs(snapshot.Items)do
            if item.Level<=snapshot.Level and not item.Skin then
                local damage,defense=effective(item,"Damage",snapshot),effective(item,"Defense",snapshot)
                item.Damage,item.Defense=damage,defense
                item.Utility=(tonumber(item.Stats.Critical)or 0)+(tonumber(item.Stats.Lifesteal)or 0)
                    +(tonumber(item.Stats.HealthRegeneration)or 0)+(tonumber(item.Stats.StaminaRegeneration)or 0)
                if item.Type=="Weapon" and swordClasses[item.Class] then item.Score=damage;swords[#swords+1]=item
                elseif item.Type=="Clothing" and damage==0 and defense>0 then item.Score=defense;armor[#armor+1]=item
                elseif item.Type=="Accessory" and (damage>0 or defense>0 or item.Utility>0)then
                    item.Score=damage/math.max(1,snapshot.Highest.Damage or 1)
                        +defense/math.max(1,snapshot.Highest.Defense or 1)+item.Utility/100
                    accessories[#accessories+1]=item
                end
            end
        end
        local function less(a,b)
            if a.Score~=b.Score then return a.Score>b.Score end
            if a.Utility~=b.Utility then return a.Utility>b.Utility end
            if equipped[a.Id]~=equipped[b.Id]then return equipped[a.Id]==true end
            return a.Id<b.Id
        end
        table.sort(swords,less);table.sort(armor,less);table.sort(accessories,less)
        local operations={}
        local function add(action,item,slot)
            operations[#operations+1]={Action=action,Item=item,Slot=slot}
        end
        local sword=swords[1]
        if sword and snapshot.Equip.Right~=sword.Id then add("EquipWeapon",sword,"Right")end
        if sword and sword.Class=="1HSword" then
            for _,item in ipairs(swords)do
                if item.Id~=sword.Id and item.Class==sword.Class then
                    if snapshot.Equip.Left~=item.Id then add("EquipWeapon",item,"Left")end
                    break
                end
            end
        end
        if armor[1] and snapshot.Equip.Clothing~=armor[1].Id then add("Wear",armor[1],"Clothing")end
        local desired={};for i=1,math.min(2,#accessories)do desired[accessories[i].Id]=true end
        local worn={};for _,slot in ipairs({"Accessory1","Accessory2"})do
            local id=snapshot.Equip[slot]
            if id and id~=0 then
                worn[id]=true
                if not desired[id] and next(desired) then
                    for _,item in ipairs(snapshot.Items)do if item.Id==id then add("Unequip",item,slot);break end end
                end
            end
        end
        for i=1,math.min(2,#accessories)do if not worn[accessories[i].Id]then add("Wear",accessories[i],"Accessory")end end
        return operations
    end
    function api.Invalidate()api.Dirty=true end
    function api.HasWork()return api.Dirty or pending~=nil end
    function api.Reset()pending=nil;nextRead=0;failures=0;api.Paused=false;api.Error=nil;api.Dirty=true end
    function api.Update(now)
        if api.Paused or not ctx.Active() or ctx.Busy() or now<nextRead then return end
        nextRead=now+.3
        if not pending and not api.Dirty then return end
        local snapshot=ctx.Read()
        if not snapshot then return end
        if pending then
            local found=false
            if pending.Action=="Unequip" then found=snapshot.Equip[pending.Slot]~=pending.Item.Id
            elseif pending.Slot=="Accessory"then
                found=snapshot.Equip.Accessory1==pending.Item.Id or snapshot.Equip.Accessory2==pending.Item.Id
            else found=snapshot.Equip[pending.Slot]==pending.Item.Id end
            if not found and now<pending.Deadline then return end
            if not found then
                failures+=1;api.Error="Equipment was not acknowledged: "..pending.Item.Name
                if failures>=3 then api.Paused=true;ctx.Status(api.Error);return end
            else failures=0;api.Error=nil end
            pending=nil
        end
        local op=api.Plan(snapshot)[1]
        if not op then api.Dirty=false;nextRead=now+1;ctx.Status("Best usable gear equipped");return end
        if not ctx.Active() or ctx.Busy() then return end
        local ok,message=ctx.Equip(op)
        if not ok then
            failures+=1;api.Error=tostring(message or "Equipment request failed");nextRead=now+2
            if failures>=3 then api.Paused=true end
            ctx.Status(api.Error);return
        end
        pending=op;pending.Deadline=now+4
        ctx.Status("Equipping "..op.Item.Name)
    end
    return api
end
