-- Build an owned-gear ordering, then reconcile one replicated equipment operation.
return function(ctx)
    local api={Dirty=true}
    local request
    local readAt=0
    local failures=0
    local function value(item,name,snapshot)
        local base=tonumber(item.Stats[name])
        if not base then return 0 end
        if item.Scale then base=base*item.Scale*snapshot.Level end
        if item.MatchBest then base=base+(snapshot.Highest[name]or 0)*item.MatchBest end
        base=math.floor(base)
        local grades=ctx.Rarity.RarityUpgrades
        local maximum=grades[item.Rarity]or grades.Common
        if maximum and item.Upgrade>0 then
            local levels=ctx.Rarity.UpgradeLevelMultipliers
            local factor=name=="Damage"and (tonumber(item.Stats.DamageUpgrade)or levels[maximum]or levels.default)or levels.default
            base=math.floor(base+base*item.Upgrade*factor/maximum)
        end
        return base
    end
    local function candidates(snapshot)
        local buckets={weapons={},armor={},accessories={}}
        local worn={}
        for _,id in pairs(snapshot.Equip)do worn[id]=true end
        local function compare(a,b)
            if a.Score~=b.Score then return a.Score>b.Score end
            if a.Utility~=b.Utility then return a.Utility>b.Utility end
            if worn[a.Id]~=worn[b.Id]then return worn[a.Id]==true end
            return a.Id<b.Id
        end
        for _,item in ipairs(snapshot.Items)do
            if item.Level<=snapshot.Level and not item.Skin then
                item.Damage=value(item,"Damage",snapshot)
                item.Defense=value(item,"Defense",snapshot)
                item.Utility=0
                for _,stat in ipairs({"Critical","Lifesteal","HealthRegeneration","StaminaRegeneration"})do
                    item.Utility=item.Utility+(tonumber(item.Stats[stat])or 0)
                end
                local group
                if item.Type=="Weapon"then item.Score=item.Damage;group=buckets.weapons
                elseif item.Type=="Clothing"and item.Damage==0 and item.Defense>0 then item.Score=item.Defense;group=buckets.armor
                elseif item.Type=="Accessory"and (item.Damage>0 or item.Defense>0 or item.Utility>0)then
                    item.Score=item.Damage/math.max(1,snapshot.Highest.Damage or 1)
                        +item.Defense/math.max(1,snapshot.Highest.Defense or 1)+item.Utility/100
                    group=buckets.accessories
                end
                if group then group[#group+1]=item end
            end
        end
        for _,group in pairs(buckets)do table.sort(group,compare)end
        return buckets
    end
    function api.Plan(snapshot)
        local ranked=candidates(snapshot)
        local operations={}
        local lookup={}
        for _,item in ipairs(snapshot.Items)do lookup[item.Id]=item end
        local function add(action,item,slot)
            operations[#operations+1]={Action=action,Item=item,Slot=slot}
        end
        local weapon=ranked.weapons[1]
        if weapon and not(ctx.SkipWeapons and ctx.SkipWeapons())then
            local left=snapshot.Equip.Left
            if left and left~=0 and lookup[left]then add("Unequip",lookup[left],"Left")end
            if snapshot.Equip.Right~=weapon.Id then add("EquipWeapon",weapon,"Right")end
        end
        if ctx.WeaponsOnly and ctx.WeaponsOnly()then return operations end
        local armor=ranked.armor[1]
        if armor and snapshot.Equip.Clothing~=armor.Id then add("Wear",armor,"Clothing")end
        local wanted={}
        for index=1,math.min(2,#ranked.accessories)do wanted[ranked.accessories[index].Id]=true end
        local existing={}
        for _,slot in ipairs({"Accessory1","Accessory2"})do
            local id=snapshot.Equip[slot]
            if id and id~=0 then
                existing[id]=true
                if not wanted[id]and next(wanted)and lookup[id]then add("Unequip",lookup[id],slot)end
            end
        end
        for index=1,math.min(2,#ranked.accessories)do
            local item=ranked.accessories[index]
            if not existing[item.Id]then add("Wear",item,"Accessory")end
        end
        return operations
    end
    local function acknowledged(snapshot,operation)
        if operation.Action=="Unequip"then return snapshot.Equip[operation.Slot]~=operation.Item.Id end
        if operation.Slot=="Accessory"then
            return snapshot.Equip.Accessory1==operation.Item.Id or snapshot.Equip.Accessory2==operation.Item.Id
        end
        return snapshot.Equip[operation.Slot]==operation.Item.Id
    end
    local function reject(reason)
        failures=failures+1;api.Error=reason
        if failures>=3 then api.Paused=true end
        ctx.Status(reason)
    end
    function api.Invalidate()api.Dirty=true end
    function api.HasWork()return api.Dirty or request~=nil end
    function api.Reset()
        request=nil;readAt=0;failures=0;api.Paused=false;api.Error=nil;api.Dirty=true
    end
    function api.Update(now)
        if api.Paused or now<readAt or not ctx.Active()or ctx.Busy()then return end
        readAt=now+.3
        if not request and not api.Dirty then return end
        local snapshot=ctx.Read()
        if not snapshot then return end
        if request then
            local completed=acknowledged(snapshot,request)
            if not completed and now<request.Deadline then return end
            if completed then failures=0;api.Error=nil
            else reject("Equipment was not acknowledged: "..request.Item.Name)end
            request=nil
            if api.Paused then return end
        end
        local operation=api.Plan(snapshot)[1]
        if not operation then
            api.Dirty=false;readAt=now+1;ctx.Status("Best usable gear equipped");return
        end
        if not ctx.Active()or ctx.Busy()then return end
        local sent,reason=ctx.Equip(operation)
        if not sent then reject(tostring(reason or "Equipment request failed"));readAt=now+2;return end
        operation.Deadline=now+4;request=operation
        ctx.Status("Equipping "..operation.Item.Name)
    end
    return api
end
