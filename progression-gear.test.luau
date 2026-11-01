return function(source)
    local make=assert(loadstring(source))()
    local count=0
    local function test(name,fn)fn();count+=1;print("PASS "..name)end
    local rarity={RarityUpgrades={Common=10,Legendary=20},UpgradeLevelMultipliers={default=.4,[20]=1}}
    local function item(id,kind,class,damage,defense,extra)
        local value={Id=id,Name="Item"..id,Type=kind,Class=class,Level=1,Rarity="Common",Upgrade=0,Stats={Damage=damage,Defense=defense}}
        for k,v in pairs(extra or {})do value[k]=v end
        return value
    end
    local function fixture(items)
        local f={Snapshot={Level=10,Items=items or {},Equip={},Highest={Damage=100,Defense=100}},Calls={},Active=true,Busy=false,Reads=0}
        f.Api=make({SkipWeapons=function()return f.SkipWeapons end,WeaponsOnly=function()return f.WeaponsOnly end,Rarity=rarity,Read=function()f.Reads+=1;return f.Snapshot end,
            Active=function()return f.Active end,Busy=function()return f.Busy end,
            Equip=function(op)f.Calls[#f.Calls+1]=op;return not f.Fail,"Rejected"end,Status=function(value)f.Status=value end})
        return f
    end
    test("Best sword uses upgraded native damage and excludes unusable levels and non-swords",function()
        local a=item(1,"Weapon","1HSword",100,nil,{Rarity="Legendary",Upgrade=20})
        local f=fixture({a,item(2,"Weapon","Spear",180),item(3,"Weapon","2HSword",999,nil,{Level=11}),item(4,"Weapon","Bow",1000)})
        local op=f.Api.Plan(f.Snapshot)[1];assert(op.Item.Id==1 and op.Slot=="Right"and a.Damage==200)
    end)
    test("Standalone Best Sword equips only the best usable swords and preserves armor/accessories",function()
        local f=fixture({item(1,"Weapon","1HSword",100),item(2,"Weapon","1HSword",90),
            item(3,"Clothing","Armor",nil,500),item(4,"Accessory","",nil,500)})
        f.WeaponsOnly=true
        local ops=f.Api.Plan(f.Snapshot);assert(#ops==1)
        for _,op in ipairs(ops)do assert(op.Action=="EquipWeapon")end
        f.Snapshot.Equip.Right=1;f.Snapshot.Equip.Left=0
        assert(#f.Api.Plan(f.Snapshot)==0)
        f.WeaponsOnly=false;assert(#f.Api.Plan(f.Snapshot)>0)
    end)
    test("Best Sword OFF blocks sword equips while progression can still select armor",function()
        local f=fixture({item(1,"Weapon","1HSword",100),item(2,"Clothing","Armor",nil,100)})
        f.SkipWeapons=true;f.WeaponsOnly=true;assert(#f.Api.Plan(f.Snapshot)==0)
        f.WeaponsOnly=false;local ops=f.Api.Plan(f.Snapshot)
        assert(#ops==1 and ops[1].Action=="Wear")
        f.SkipWeapons=false;assert(f.Api.Plan(f.Snapshot)[1].Action=="EquipWeapon")
    end)
    test("Armor uses defense upgrades rather than rarity or item level alone",function()
        local f=fixture({item(1,"Clothing","Armor",nil,100,{Upgrade=10}),item(2,"Clothing","Armor",nil,130)})
        local op=f.Api.Plan(f.Snapshot)[1];assert(op.Item.Id==1 and op.Slot=="Clothing")
    end)
    test("Scale and MatchBest affect only stats that actually exist",function()
        local scaled=item(1,"Weapon","1HSword",10,nil,{Scale=.5})
        local match=item(2,"Weapon","Spear",0,nil,{MatchBest=2})
        local f=fixture({scaled,match});local op=f.Api.Plan(f.Snapshot)[1]
        assert(op.Item.Id==2 and match.Damage==200 and match.Defense==0 and scaled.Damage==50)
    end)
    test("Single-weapon mode clears the left slot and never equips into it",function()
        local f=fixture({item(1,"Weapon","1HSword",100),item(2,"Weapon","1HSword",90)})
        f.Snapshot.Equip.Right=1;f.Snapshot.Equip.Left=2
        local ops=f.Api.Plan(f.Snapshot)
        assert(#ops==1 and ops[1].Action=="Unequip"and ops[1].Slot=="Left")
        f.Api.Update(0);f.Api.Update(1);assert(#f.Calls==1)
        f.Snapshot.Equip.Left=0;f.Api.Update(1.5)
        assert(#f.Calls==1 and not f.Api.HasWork())
        f.SkipWeapons=true;f.Snapshot.Equip.Left=2;assert(#f.Api.Plan(f.Snapshot)==0)
    end)
    test("Spears compete by effective damage and over-level spears remain excluded",function()
        local f=fixture({item(1,"Weapon","1HSword",100),item(2,"Weapon","Spear",120),
            item(3,"Weapon","Spear",999,nil,{Level=11}),item(4,"Weapon","2HSword",999)})
        local ops=f.Api.Plan(f.Snapshot)
        assert(#ops==1 and ops[1].Item.Id==2 and ops[1].Slot=="Right")
        f.Snapshot.Equip.Left=2
        f.Api.Update(0);assert(f.Calls[1].Action=="Unequip")
        f.Api.Update(1);assert(#f.Calls==1)
        f.Snapshot.Equip.Left=0;f.Api.Update(2)
        assert(#f.Calls==2 and f.Calls[2].Action=="EquipWeapon"and f.Calls[2].Slot=="Right")
    end)
    test("Accessories replace only worse slots and retain an already desired accessory",function()
        local f=fixture({item(1,"Accessory","",nil,100),item(2,"Accessory","",nil,90),item(3,"Accessory","",nil,80)})
        f.Snapshot.Equip={Accessory1=2,Accessory2=3}
        local ops=f.Api.Plan(f.Snapshot)
        assert(#ops==2 and ops[1].Action=="Unequip"and ops[1].Item.Id==3)
        assert(ops[2].Action=="Wear"and ops[2].Item.Id==1)
    end)
    test("Vanity accessories and under-level items cannot displace usable combat gear",function()
        local f=fixture({item(1,"Accessory","",nil,9999,{Skin=true}),item(2,"Accessory","",nil,9999,{Level=100})})
        f.Snapshot.Equip.Accessory1=55;assert(#f.Api.Plan(f.Snapshot)==0)
    end)
    test("Equal scores keep equipped items and avoid swap loops",function()
        local f=fixture({item(1,"Weapon","1HSword",100),item(2,"Weapon","1HSword",100)})
        f.Snapshot.Equip.Right=2;assert(#f.Api.Plan(f.Snapshot)==0)
    end)
    test("Equipment waits for replication acknowledgment before issuing another request",function()
        local f=fixture({item(1,"Weapon","1HSword",100),item(2,"Clothing","Armor",nil,100)})
        f.Api.Update(0);f.Api.Update(1);f.Api.Update(3);assert(#f.Calls==1)
        f.Snapshot.Equip.Right=1;f.Api.Update(3.5);assert(#f.Calls==2 and f.Calls[2].Slot=="Clothing")
    end)
    test("Equipment rejection and missing acknowledgment are bounded and resettable",function()
        local f=fixture({item(1,"Weapon","1HSword",100)});f.Fail=true
        f.Api.Update(0);f.Api.Update(2);f.Api.Update(4);f.Api.Update(100)
        assert(#f.Calls==3 and f.Api.Paused);f.Api.Reset();assert(not f.Api.Paused)
        f=fixture({item(1,"Weapon","1HSword",100)})
        f.Api.Update(0);f.Api.Update(4);f.Api.Update(8);f.Api.Update(12);assert(#f.Calls==3 and f.Api.Paused)
    end)
    test("No active progression or a skill/travel owner means no equipment request",function()
        local f=fixture({item(1,"Weapon","1HSword",100)})
        f.Active=false;f.Api.Update(0);f.Active=true;f.Busy=true;f.Api.Update(1)
        assert(#f.Calls==0 and f.Reads==0)
    end)
    test("Stable equipment skips repeated inventory scans until invalidation",function()
        local f=fixture({item(1,"Weapon","1HSword",100)});f.Snapshot.Equip.Right=1
        f.Api.Update(0);f.Api.Update(1);f.Api.Update(2);assert(f.Reads==1 and not f.Api.HasWork())
        f.Api.Invalidate();f.Api.Update(3);assert(f.Reads==2)
    end)
    print("All "..count.." progression gear scenarios passed")
end
