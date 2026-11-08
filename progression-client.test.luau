-- Execute the real engine adapter with deterministic engine doubles.
return function(clientSource,controllerSource,gearSource,payloadSource)
    local passed=0
    local function test(name,fn)fn();passed+=1;print("PASS "..name)end
    local function signal()
        local api={Handlers={}}
        function api:Connect(fn)
            local connection={Connected=true};function connection:Disconnect()self.Connected=false end
            self.Handlers[#self.Handlers+1]={Fn=fn,Connection=connection};return connection
        end
        function api:Fire(...)
            for _,row in ipairs(self.Handlers)do if row.Connection.Connected then row.Fn(...)end end
        end
        return api
    end
    local mt={}
    local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    mt.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    mt.__index=function(v,key)if key=="Magnitude"then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end end
    local function node(name,class,value,children)
        local api={Name=name,ClassName=class or"Folder",Value=value,Children=children or{},Parent=true,
            ChildAdded=signal(),Changed=signal(),DescendantAdded=signal(),DescendantRemoving=signal(),Activated=signal(),Text=""}
        function api:FindFirstChild(key)for _,child in ipairs(self.Children)do if child.Name==key then return child end end end
        function api:GetChildren()return self.Children end
        function api:QueryDescendants()return {}end
        function api:IsA(kind)return self.ClassName==kind or kind=="ValueBase"and self.ClassName:sub(-5)=="Value"end
        function api:GetPropertyChangedSignal()return self.Changed end
        function api:GetAttribute(key)return self.Attributes and self.Attributes[key]end
        function api:GetAttributeChangedSignal()return signal()end
        function api:FindFirstChildOfClass(kind)for _,child in ipairs(self.Children)do if child.ClassName==kind then return child end end end
        for _,child in ipairs(api.Children)do child.Parent=api;api[child.Name]=child end
        return api
    end
    local function fixture()
        local f={Saves=0,Stops=0,MultiResets=0,SafeResets=0,Trips={},Calls={},Mobs={},Data={},Ranks={},Now=0}
        local inventory=node("Inventory")
        local equip=node("Equip","Folder",nil,{node("Right","IntValue",0),node("Accessory1","IntValue",0),node("Accessory2","IntValue",0)})
        local profile=node("Tester","Folder",nil,{inventory,equip,node("Stats","Folder",nil,{node("Exp","IntValue",2000)})})
        local profiles=node("Profiles","Folder",nil,{profile})
        local definitions=node("Items")
        local root=node("HumanoidRootPart","Part");root.Position=vec(0,0,0);root.Anchored=false
        local humanoid=node("Humanoid","Humanoid");humanoid.Health=100
        local player=node("Tester","Player");player.Character=node("Character","Model",nil,{root,humanoid})
        player.Attributes={HighestDamage=100,HighestDefense=100}
        local game={PlaceId=1,ReplicatedStorage={Profiles=profiles,Database={Items=definitions},Shared={Library={RarityData={}}},Function={}}}
        function game.ReplicatedStorage.Function:InvokeServer(...)
            f.Calls[#f.Calls+1]={...};return f.Reply
        end
        local spot={Id="boss",PlaceId=1,DestinationId="source:Boss",Kind="Boss",Position=vec(0,20,0)}
        local state={Running=true,AccountProgression=false,ProgressionFloor=1,AutoFarm=false,Enabled=false,AutoSwing=false,
            SafeMode=true,SafeFloorId=13,MultiSpot=true,MultiSpotSelected={original=true},UI={},FloorDestinations={},
            AutomationCatalog={Floors={{Id=1,Number=1},{Id=12,Number=12}},Spots={spot},AddCurrent=function()end}}
        state.MultiSpotController={Reset=function()f.MultiResets+=1 end}
        state.SafeController={Reset=function()f.SafeResets+=1 end,Seeking=false}
        function state.SetAutoFarm(on)state.AutoFarm=on;if on then state.Enabled=true end end
        function state.SetEnabled(on)state.Enabled=on;if on then state.AutoSwing=true end end
        function state.SetAutoSwing(on)state.AutoSwing=on end
        function state.SaveNow()f.Saves+=1;return true end
        function state.IsAutomationFloorUnlocked()return true end
        function state.ChangeAutomationFloor(id)f.Trips[#f.Trips+1]=id;return true end
        function state.RegisterAutomationDestination()end
        function state.TeleportToDestination(id)
            state.LastTravelDestination=id;state.LastTravelPosition=root.Position;return true
        end
        local rarity={RarityUpgrades={Common=10},UpgradeLevelMultipliers={default=.4}}
        local factory=assert(loadstring(clientSource))
        setfenv(factory,setmetatable({game=game,require=function()return rarity end,
            Color3={fromRGB=function()return {}end},os={clock=function()return f.Now end},
            task={spawn=function(fn)local thread=coroutine.create(fn);assert(coroutine.resume(thread));return thread end,
                delay=function()end,cancel=function()end}},{__index=getfenv()}))
        local attach=factory()
        f.Api=attach({State=state,Player=player,Parent=node("Speacial"),
            MakeController=function(ctx)f.ControllerCtx=ctx;return assert(loadstring(controllerSource))()(ctx)end,
            MakeGear=function(ctx)f.GearCtx=ctx;return assert(loadstring(gearSource))()(ctx)end,
            Button=function(name,text)local value=node(name,"TextButton");value.Text=text;return value end,
            Label=function(name,text)local value=node(name,"TextLabel");value.Text=text;return value end,
            Bind=function(event,fn)return event:Connect(fn)end,
            Mobs=function()return f.Mobs end,Data=function(mob)return f.Data[mob]end,Rank=function(mob)return f.Ranks[mob]end,
            IsChest=function(mob)return mob.Name=="Reward Chest"end,
            OwnDamage=function(health)local counter=health:FindFirstChild("Tester");return counter and counter.Value end,
            SkillsBusy=function()return false end,StopCombat=function()f.Stops+=1 end})
        f.State,f.Game,f.Profile,f.Player,f.Inventory,f.Definitions=state,game,profile,player,inventory,definitions
        function f.AddBoss(rank)
            local health=node("Health","IntValue",100)
            local mob=node("Boss","Model");f.Mobs[mob]=true;f.Ranks[mob]=rank or 1
            f.Data[mob]={Health=health,Root={Position=vec(0,20,0)}}
            return mob,health
        end
        return f
    end
    test("Progression is opt-in and constructs its control on Speacial without enabling combat",function()
        local f=fixture();assert(not f.State.AutoFarm and not f.State.Enabled and not f.State.AccountProgression)
        assert(f.State.UI.ProgressionToggle.Name=="AccountProgression"and f.Stops==0 and f.Saves==0)
    end)
    test("Starting and stopping progression restores farm preferences and preserves Safe Mode/Multi Spot choices",function()
        local f=fixture();f.State.SetAccountProgression(true)
        assert(f.State.AutoFarm and f.State.Enabled and f.State.ProgressionRestore.Enabled==false)
        assert(f.State.MultiSpot and f.State.MultiSpotSelected.original and f.State.SafeFloorId==1)
        assert(f.State.ProgressionRestore.SafeFloorId==13)
        f.State.SetAccountProgression(false)
        assert(not f.State.AutoFarm and not f.State.Enabled and not f.State.AutoSwing and f.State.ProgressionRestore==nil)
        assert(f.State.MultiSpot and f.State.MultiSpotSelected.original and f.State.SafeFloorId==13)
    end)
    test("Reload resumes the saved checkpoint and retains the original combat preferences",function()
        local f=fixture();f.State.AccountProgression=true;f.State.ProgressionFloor=8
        f.State.ProgressionRestore={Enabled=false,AutoFarm=false};f.State.Enabled=true;f.State.AutoFarm=true
        f.State.SetAccountProgression(true,true)
        assert(f.State.ProgressionFloor==8 and f.State.ProgressionRestore.Enabled==false)
        assert(f.SafeResets==0,"Resuming progression must not restart an in-flight Safe Mode search")
        f.State.SetAccountProgression(false);assert(not f.State.Enabled and not f.State.AutoFarm)
    end)
    test("Reset saved progression repairs a paused checkpoint and preserves original mode preferences",function()
        local f=fixture();f.State.SetAccountProgression(true)
        local original=f.State.ProgressionRestore
        f.State.ProgressionFloor=9;f.State.ProgressionBossCleared=true
        f.State.ProgressionBossClearedName="Old boss";f.State.ProgressionComplete=true
        f.Api.Pause("F9 is locked");f.Api.Attempts=3
        f.State.ProgressionTravelOwned=true;f.State.TravelBusy=true;f.State.TravelSerial=12
        local boss,health=f.AddBoss(1);f.ControllerCtx.Boss({Position=vec(0,20,0)})
        local safe,multi=f.SafeResets,f.MultiResets
        assert(f.State.ResetSavedProgression())
        assert(f.State.AccountProgression and f.State.ProgressionFloor==1 and not f.State.ProgressionBossCleared
            and not f.State.ProgressionBossClearedName and not f.State.ProgressionComplete)
        assert(not f.Api.Paused and not f.Api.LastError and f.Api.Attempts==0 and f.Api.Phase=="Idle")
        assert(not f.State.ProgressionTravelOwned and not f.State.TravelBusy and f.State.TravelSerial==13)
        assert(not f.State.ProgressionBossMob and not health.Changed.Handlers[1].Connection.Connected)
        assert(f.State.ProgressionRestore==original and f.SafeResets==safe and f.MultiResets==multi)
        assert(f.State.AutoFarm and f.State.Enabled and #f.Trips==0 and #f.Calls==0,
            "Reset itself must not send progression, damage or equipment requests")
        f.State.SetAccountProgression(false)
        assert(not f.State.AutoFarm and not f.State.Enabled and not f.State.AutoSwing,
            "OFF still restores the preferences from before progression was enabled")
    end)
    test("Reset while OFF only changes checkpoint data and saves it",function()
        local f=fixture();f.State.ProgressionFloor=9;f.State.ProgressionBossCleared=true
        f.State.ProgressionBossClearedName="Old boss";f.State.ProgressionComplete=true
        f.State.Enabled=true;f.State.TravelBusy=true;f.State.TravelHold=true;f.State.TravelSerial=4
        assert(f.State.ResetSavedProgression())
        assert(not f.State.AccountProgression and f.State.Enabled and not f.State.AutoFarm and not f.State.AutoSwing)
        assert(f.State.TravelBusy and f.State.TravelHold and f.State.TravelSerial==4 and f.Stops==0)
        assert(f.Saves==1 and f.SafeResets==0 and f.MultiResets==0)
        local position={X={Scale=0,Offset=0},Y={Scale=0,Offset=0}}
        local load=assert(loadstring(payloadSource.."\nreturn settingsPayload()"))
        setfenv(load,setmetatable({state=f.State,enemyHUD={Position=position}},{__index=getfenv()}))
        local saved=load()
        assert(saved.ProgressionFloor==1 and not saved.ProgressionBossCleared and not saved.ProgressionBossClearedName
            and not saved.ProgressionComplete and not saved.AccountProgression)
    end)
    test("Reset respects Stop Everything, preserves unrelated travel and retires with the runtime",function()
        local f=fixture();f.State.SetAccountProgression(true)
        f.State.StopEverything=true;f.State.Enabled=false;f.State.AutoFarm=false
        f.State.ProgressionFloor=9;f.State.TravelBusy=true;f.State.TravelSerial=4
        assert(f.State.ResetSavedProgression())
        assert(f.State.StopEverything and f.State.AccountProgression and not f.State.Enabled and not f.State.AutoFarm)
        assert(f.State.TravelBusy and f.State.TravelSerial==4,"Only progression-owned travel may be cancelled")
        f.State.ProgressionDestroy();local saves=f.Saves
        assert(not f.State.ResetSavedProgression()and f.Saves==saves,"A retired UI action cannot change saved settings")
    end)
    test("Native boss observation rejects minibosses and requires a real credited health-zero event",function()
        local f=fixture();f.State.SetAccountProgression(true)
        f.AddBoss(2);assert(not f.ControllerCtx.Boss({Position=vec(0,20,0)}))
        local boss,health=f.AddBoss(1)
        assert(f.ControllerCtx.Boss({Position=vec(0,20,0)}).Alive and f.State.ProgressionBossMob==boss)
        local counter=node("Tester","IntValue",25);health.Children[1]=counter;health.ChildAdded:Fire(counter)
        health.Value=0;health.Changed:Fire()
        local result=f.ControllerCtx.Boss({Position=vec(0,20,0)})
        assert(result.Defeated and result.Credited)
    end)
    test("Progression can collect a chest without crediting it as the main boss",function()
        local f=fixture();f.State.SetAccountProgression(true)
        local chest=f.AddBoss(1);chest.Name="Reward Chest"
        assert(not f.ControllerCtx.Boss({Position=vec(0,20,0)})and not f.State.ProgressionBossMob)
        f.State.GetFarmChestTarget=function()return chest end
        assert(f.ControllerCtx.ChestTarget(0)==chest)
        f.State.ProgressionTravelOwned=true;assert(not f.ControllerCtx.ChestTarget(1))
        f.State.ProgressionTravelOwned=false;f.State.TravelBusy=true;assert(not f.ControllerCtx.ChestTarget(2))
    end)
    test("A boss-tagged Gorilla cannot replace or satisfy the expected Rahjin target",function()
        local f=fixture();f.State.SetAccountProgression(true)
        local gorilla=f.AddBoss(1);gorilla.Name="Gorilla Berserker"
        local spot={Position=vec(0,20,0),EncounterNames={["Rahjin the Thief King"]=true}}
        assert(not f.ControllerCtx.Boss(spot)and not f.State.ProgressionBossMob)
        -- Even an already observed side boss must be rejected after identity changes.
        assert(f.ControllerCtx.Boss({Position=spot.Position}).Alive)
        assert(not f.ControllerCtx.Boss(spot)and not f.State.ProgressionBossMob)
        local rahjin=f.AddBoss(1);rahjin.Name="Rahjin the Thief King"
        assert(f.ControllerCtx.Boss(spot).Alive and f.State.ProgressionBossMob==rahjin)
    end)
    test("Progression chooses its canonical main-boss spot before loaded side bosses",function()
        local f=fixture()
        local side={Id="side",PlaceId=1,Kind="Boss",Name="Gorilla Berserker",Position=vec(0,20,0)}
        local main={Id="1/Boss",PlaceId=1,Kind="Boss",MainBoss=true,Position=vec(100,20,0)}
        f.State.AutomationCatalog.Spots={side,main};f.State.AutomationCatalog.SpotById={["1/Boss"]=main}
        assert(f.ControllerCtx.BossSpot({Id=1},1)==main)
        f.State.AutomationCatalog.SpotById=nil
        assert(f.ControllerCtx.BossSpot({Id=1},1)==main)
    end)
    test("Old side-boss or unproven clear checkpoints are repaired before progression resumes",function()
        for _,name in ipairs({"Gorilla Berserker","","Rahjin the Thief King"})do
            local f=fixture();f.State.ProgressionBossCleared=true;f.State.ProgressionBossClearedName=name
            f.State.AutomationCatalog.SpotById={["1/Boss"]={EncounterNames={["Rahjin the Thief King"]=true}}}
            f.State.SetAccountProgression(true,true)
            assert(f.State.ProgressionBossCleared==(name=="Rahjin the Thief King"))
        end
    end)
    test("Streaming loss is not a boss kill and dead uncredited bodies do not advance",function()
        local f=fixture();f.State.SetAccountProgression(true);local boss,health=f.AddBoss()
        f.ControllerCtx.Boss({Position=vec(0,20,0)});boss.Parent=nil;health.Parent=nil
        assert(not f.ControllerCtx.Boss({Position=vec(0,20,0)}))
        f.Mobs[boss]=nil;local other,h=f.AddBoss()
        f.ControllerCtx.Boss({Position=vec(0,20,0)});h.Value=0;h.Changed:Fire()
        local result=f.ControllerCtx.Boss({Position=vec(0,20,0)});assert(result.Defeated and not result.Credited)
        other.Parent=nil;f.Now=2;assert(not f.ControllerCtx.Boss({Position=vec(0,20,0)}))
    end)
    test("A health reset with remaining hit lives is not a completed boss kill",function()
        local f=fixture();f.State.SetAccountProgression(true);local boss,health=f.AddBoss()
        local lives=node("HitLives","IntValue",2);f.Data[boss].HitLives=lives
        f.ControllerCtx.Boss({Position=vec(0,20,0)})
        local counter=node("Tester","IntValue",25);health.Children[1]=counter;health.ChildAdded:Fire(counter)
        health.Value=0;health.Changed:Fire();assert(not f.ControllerCtx.Boss({Position=vec(0,20,0)}).Defeated)
        lives.Value=0;lives.Changed:Fire();assert(f.ControllerCtx.Boss({Position=vec(0,20,0)}).Defeated)
    end)
    test("Equipment adapter uses the native owned-instance RPC and respects cancellation",function()
        local f=fixture();f.State.SetAccountProgression(true)
        local native=node("Sword","IntValue",10);native.Parent=f.Inventory
        local op={Action="EquipWeapon",Item={Native=native},Slot="Right"}
        assert(f.GearCtx.Equip(op));local call=f.Calls[1]
        assert(call[1]=="Equipment"and call[2][1]=="EquipWeapon"and call[2][2]==native and call[2][3]=="Right")
        assert(f.GearCtx.Equip({Action="Unequip",Item={Native=native},Slot="Left"}))
        assert(f.Calls[2][2][1]=="Unequip"and f.Calls[2][2][2]==native)
        f.State.SetAccountProgression(false);assert(not f.GearCtx.Equip(op) and #f.Calls==2)
    end)
    test("Standalone Auto Equip Best Gear includes armor and accessories without progression",function()
        local f=fixture();f.State.AccountProgression=false;f.State.AutoEquipBestSword=true
        assert(f.GearCtx.Active()and not f.GearCtx.WeaponsOnly()and not f.GearCtx.SkipWeapons())
        f.State.AutoEquipBestSword=false;assert(not f.GearCtx.Active())
    end)
    test("Equipment observers retire removed values and disconnect on runtime cleanup",function()
        local f=fixture();local gear=f.State.ProgressionGearController
        for i=1,1000 do
            local upgrade=node("Upgrade","IntValue",i)
            f.Inventory.DescendantAdded:Fire(upgrade);f.Inventory.DescendantAdded:Fire(upgrade)
            assert(#upgrade.Changed.Handlers==1,"Duplicate stream events cannot add duplicate observers")
            gear.Dirty=false;upgrade.Changed:Fire();assert(gear.Dirty)
            f.Inventory.DescendantRemoving:Fire(upgrade);gear.Dirty=false;upgrade.Changed:Fire()
            assert(not gear.Dirty and not upgrade.Changed.Handlers[1].Connection.Connected,"Removed inventory values must not retain active callbacks")
        end
        local latest=node("Upgrade","IntValue",1);f.Inventory.DescendantAdded:Fire(latest)
        f.State.ProgressionDestroy();assert(not latest.Changed.Handlers[1].Connection.Connected)
    end)
    test("Gear snapshot keeps weapon auras and excludes vanity accessories",function()
        local f=fixture()
        local function add(name,typ)
            local native=node(name,"IntValue",#f.Inventory.Children+1,{node("Skin","StringValue","Aura")})
            native.Parent=f.Inventory;f.Inventory.Children[#f.Inventory.Children+1]=native
            local def=node(name,"Folder",nil,{node("Type","StringValue",typ),node("Class","StringValue","1HSword"),node("Stats","Folder",nil,{node("Damage","IntValue",10)})})
            f.Definitions.Children[#f.Definitions.Children+1]=def
        end
        add("Sword","Weapon");add("Vanity","Accessory")
        local snapshot=f.GearCtx.Read();assert(not snapshot.Items[1].Skin and snapshot.Items[2].Skin)
    end)
    test("Completed progression stays at F12 until OFF restores other floor modes",function()
        local f=fixture();f.State.SetAccountProgression(true);f.Game.PlaceId=12;f.State.ProgressionFloor=12;f.State.ProgressionBossCleared=true
        f.Api.Update(0);f.Api.Update(1)
        assert(f.State.ProgressionComplete and f.State.AccountProgression and not f.State.Enabled and not f.State.AutoFarm)
        assert(#f.Trips==0 and f.State.SafeFloorId==12)
        f.State.SetAccountProgression(false);f.State.SetAccountProgression(true)
        assert(f.State.ProgressionFloor==1 and not f.State.ProgressionComplete)
    end)
    test("Settings save the progression checkpoint before runtime cleanup",function()
        local f=fixture();f.State.SetAccountProgression(true);f.State.ProgressionFloor=9;f.State.ProgressionBossCleared=true;f.State.ProgressionBossClearedName="Floor 9 boss"
        local position={X={Scale=0,Offset=0},Y={Scale=0,Offset=0}}
        local load=assert(loadstring(payloadSource.."\nreturn settingsPayload()"))
        setfenv(load,setmetatable({state=f.State,panel={Position=position},enemyHUD={Position=position}},{__index=getfenv()}))
        local saved=load()
        assert(saved.AccountProgression and saved.ProgressionFloor==9 and saved.ProgressionBossCleared)
        assert(saved.ProgressionBossClearedName=="Floor 9 boss")
        assert(saved.ProgressionRestore.Enabled==false and saved.MultiSpot and saved.SafeFloorId==1)
        f.State.ProgressionDestroy();assert(f.State.AccountProgression and f.State.ProgressionFloor==9)
    end)
    print("All "..passed.." progression adapter scenarios passed")
end
