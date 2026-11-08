return function(prioritySource,dataSource,validSource,selectionSource,creditSource)
    local function load(source,env)
        local fn=assert(loadstring(source));setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn()
    end
    local vectorMT={__sub=function(a,b)return {Magnitude=math.sqrt((a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2)}end}
    local function vec(x,y,z)return setmetatable({X=x,Y=y or 0,Z=z or 0},vectorMT)end
    local folder={}
    local function mob(name,x,rank,hp)
        local m={Name=name,Parent=folder,Children={},Attributes={Rank=rank},Tags={}}
        local entity={Parent=m,Children={},Attributes={},Tags={}}
        local root={Position=vec(x),Parent=m,IsA=function(_,kind)return kind=="BasePart"end,FindFirstChild=function()end}
        local health={Value=hp or 100,Parent=entity}
        m.Children.Entity=entity;m.Children.HumanoidRootPart=root;entity.Children.Health=health
        function m:FindFirstChild(key)return self.Children[key]end
        function entity:FindFirstChild(key)return self.Children[key]end
        function m:GetAttribute(key)return self.Attributes[key]end
        function entity:GetAttribute(key)return self.Attributes[key]end
        function m:GetTags()return self.Tags end;function entity:GetTags()return self.Tags end
        return m
    end
    local regular=mob("Nearby regular",0)
    local mini=mob("Nearby mini",10,"MiniBoss")
    local boss=mob("Alpha boss",500,"Boss")
    local peer=mob("Alpha boss",100,"Boss")
    local other=mob("Zeta boss",-500,"Boss")
    local dead=mob("A dead boss",-1000,"Boss",0)
    local function account(list)
        local tracked={};for _,m in ipairs(list)do tracked[m]=true end
        local state={AutoFarm=true,FarmRange=math.huge,TargetScans=0}
        local api=load(prioritySource)()
        local source=dataSource.."\n"..validSource.."\nreturn {GetData=getMobData,Select=function(origin,previous,now)\n"
            .."local root={Position=origin}\nlocal mobs=folder\nlocal targetRoot=previous and validMob(previous,mobs)\n"
            .."local nextAcquisition=0\nstate.FollowTarget=previous\n"..selectionSource.."\nreturn state.FollowTarget\nend}"
        local result=load(source,{state=state,game={PlaceId=1},targetPriority=api,folder=folder,trackedMobs=tracked,refreshMobIndex=function()return folder end,
            mobCache=setmetatable({}, {__mode="k"}),os={clock=function()return 0 end}})
        result.State=state;result.Priority=api
        function result.Add(mob)tracked[mob]=true end
        return result
    end
    local accounts={account({regular,mini,boss,peer,other,dead}),account({other,peer,boss,mini,regular,dead}),
        account({dead,boss,mini,other,regular,peer})}
    local origins={vec(-10000),vec(10000),vec(500)}
    local previous={other,boss,regular}
    for i,a in ipairs(accounts)do
        assert(a.Select(origins[i],nil,0)==peer,"Different positions, previous targets and insertion order must pick the same boss")
        assert(not a.Priority.FarmLess(peer,peer),"Identical targets do not sort before themselves")
    end
    -- Replication adds HitLives after the health/root cache was already filled.
    local entity=peer.Children.Entity
    entity.Children.HitLives={Value=0,Parent=entity}
    for i,a in ipairs(accounts)do
        assert(a.GetData(peer).HitLives==entity.Children.HitLives,"Read late HitLives without the half-second cache delay")
        assert(a.Select(origins[i],peer,0)==boss,"An exhausted enemy must not keep any account's previous-target preference")
    end
    entity.Children.HitLives=nil
    for i,a in ipairs(accounts)do assert(not a.GetData(peer).HitLives);assert(a.Select(origins[i],boss,0)==peer,"Accounts converge on the common same-rank target after a spawn becomes eligible")end
    peer.Children.Entity.Children.Health.Value=0;boss.Children.Entity.Children.Health.Value=0
    for i,a in ipairs(accounts)do assert(a.Select(origins[i],peer,0)==other,"All accounts advance to the same next living boss")end
    other.Children.Entity.Children.Immortal={}
    for i,a in ipairs(accounts)do assert(a.Select(origins[i],other,0)==other,"Temporary invulnerability cannot authorize switching targets")end
    other.Children.Entity.Children.Health.Value=0
    for i,a in ipairs(accounts)do assert(a.Select(origins[i],other,0)==mini)end
    accounts[1].State.AutoTradeBusy=true
    assert(accounts[1].Select(origins[1],mini,0)==mini,"Trade pauses preserve the current target lock")
    local equal=mob("Same rank",-500,"MiniBoss")
    local stable=account({mini})
    assert(stable.Select(vec(0),nil,0)==mini)
    stable.Add(equal)
    assert(stable.Select(vec(0),mini,1)==mini,"The canonical same-rank enemy stays selected")
    mini.Children.HumanoidRootPart.Position=vec(5000)
    assert(stable.Select(vec(0),mini,2)==mini,"Movement cannot reorder a locked same-rank fight")
    local force=account({regular})
    assert(force.Select(vec(0),nil,0)==regular)
    force.Add(mini)
    assert(force.Select(vec(0),regular,1)==mini,"A mini-boss preempts a living normal mob")
    local main=mob("ZZ distant main boss",20000,"Elite")
    assert(force.Priority.Rank(main)==3)
    main.Children.Entity.Children.Difficulty={Value="Main Boss"}
    force.Add(main)
    assert(force.Select(vec(0),regular,2)==main,"A main boss preempts a lower-priority fight")
    regular.Children.Entity.Children.Health.Value=0
    assert(force.Select(vec(0),regular,3)==main,"After the current kill, choose the main boss first")
    assert(force.State.TargetPriority==1)
    main.Tags={"MiniBoss","BossBar","FloorBoss"}
    main.Children.Entity.Children.Difficulty.Value="FloorBoss"
    assert(force.Priority.Rank(main)==1,"An explicit main/floor boss marker wins over mixed generic tags")
    local taggedMini=mob("Mixed mini-boss",1,"Mini Boss");taggedMini.Tags={"BossBar","Boss"}
    assert(force.Priority.Rank(taggedMini)==2,"A generic boss bar must not promote a mini-boss to priority 1")
    local entityBoss=mob("Entity-ranked boss",1,"Elite")
    entityBoss.Children.Entity.Attributes.Rank="Boss"
    assert(force.Priority.Rank(entityBoss)==1,"Read Entity Rank even when Model Rank is present")
    main.Children.Entity.Children.Health.Value=0
    assert(force.Select(vec(0),main,3)==mini,"After the main boss dies, return to priority 2")
    assert(force.State.TargetPriority==2)
    mini.Children.Entity.Children.Health.Value=0
    assert(force.Select(vec(0),mini,4)==nil,"No target remains after every eligible mob dies")
    local mainA=mob("A global main",20000,"MainBoss")
    local mainB=mob("Z global main",-20000,"MainBoss")
    local globalMini=mob("Global mini",30000,"MiniBoss")
    local localAdd=mob("Local add",0)
    local synchronized={}
    for i=1,3 do
        local a=account({globalMini,mainB,localAdd,mainA})
        a.State.MultiSpot=true;a.State.MultiSpotAnchor=vec(i*1000);a.State.MultiSpotEncounter={}
        a.State.MultiSpotSelected={All=true}
        a.State.AutomationCatalog={SpotById={All={PlaceId=1,EncounterNames={
            [mainA.Name]=true,[mainB.Name]=true,[globalMini.Name]=true}}}}
        a.State.FarmLockArena=a.State.MultiSpotAnchor
        a.State.FarmTargetLock=i==1 and mainB or globalMini
        local current=a.State.FarmTargetLock
        assert(a.Select(vec(i*10000),current,0)==mainA,"Accounts converge on the common main boss regardless of their previous living lock")
        synchronized[i]=a
    end
    mainB.Children.Entity.Children.Health.Value=0;globalMini.Children.Entity.Children.Health.Value=0
    for _,a in ipairs(synchronized)do assert(a.Select(vec(0),a.State.FarmTargetLock,1)==mainA,"After current enemies die, every account chooses the same next main boss")end
    mainB.Children.Entity.Children.Health.Value=100;globalMini.Children.Entity.Children.Health.Value=100
    mainA.Children.Entity.Children.Health.Value=0
    for _,a in ipairs(synchronized)do assert(a.Select(vec(0),mainA,2)==mainB)end
    mainB.Children.Entity.Children.Health.Value=0
    for _,a in ipairs(synchronized)do assert(a.Select(vec(0),mainB,3)==globalMini,"After main bosses, all accounts choose the same out-of-arena mini-boss")end
    globalMini.Children.Entity.Children.Health.Value=0
    for _,a in ipairs(synchronized)do assert(a.Select(vec(0),globalMini,4)==nil,"Regular mobs outside the selected arena remain excluded")end
    mainA.Children.Entity.Children.Health.Value=100;globalMini.Children.Entity.Children.Health.Value=100
    local restricted=account({mainA,globalMini})
    restricted.State.MultiSpot=true;restricted.State.MultiSpotSelected={Mini=true}
    restricted.State.AutomationCatalog={SpotById={Mini={PlaceId=1,EncounterNames={[globalMini.Name]=true}}}}
    restricted.State.FarmTargetLock=mainA
    assert(restricted.Select(vec(0),mainA,5)==globalMini,"Deselected living main boss must release its lock and never override a selected mini")
    restricted.State.MultiSpotSelected={}
    assert(restricted.Select(vec(0),globalMini,6)==nil,"No selections means no global target fallback")
    local creditFactory=assert(loadstring(creditSource))()
    mainA.Children.Entity.Children.Health.Value=100;mainB.Children.Entity.Children.Health.Value=100
    for i=1,3 do
        local a=account({mainA,mainB})
        a.State.CreditCheck=true;a.State.FarmTargetLock=i==1 and mainA or mainB
        a.State.CreditController=creditFactory({State=a.State,Members=function()return {{Name="A"},{Name="B"}}end,Rank=a.Priority.Rank})
        assert(a.Select(vec(i*1000),a.State.FarmTargetLock,0)==mainA,"Active credit groups must converge despite conflicting living locks")
    end
    for cycle=1,300 do
        local a=account({mainA,mainB})
        a.State.CreditCheck=true;a.State.FarmTargetLock=mainB
        a.State.CreditController=creditFactory({State=a.State,Members=function()return {{Name="A"},{Name="Missing",CreditMissing=true}}end,Rank=a.Priority.Rank})
        assert(a.Select(vec(cycle*100),mainB,cycle)==mainA,"An incomplete credit roster cannot preserve conflicting same-rank boss locks")
    end
    local current=mob("Current enemy",0)
    local futureBoss=mob("Next boss",5,"MainBoss")
    local firstChest=mob("Common Chest",30,"Boss")
    local nextChest=mob("NeonChest   ",60)
    local loot=account({current})
    assert(loot.Select(vec(0),nil,0)==current)
    loot.Add(firstChest);loot.Add(nextChest);loot.Add(futureBoss)
    loot.State.CreditCheck=true
    loot.State.CreditController={FarmTarget=function()error("Chest priority cannot be replaced by credit-group boss selection")end}
    assert(loot.Select(vec(0),current,1)==current,"A new chest waits until the current enemy is finished")
    current.Children.Entity.Children.Health.Value=0
    assert(loot.Select(vec(0),current,2)==firstChest,"Choose a loaded chest before the next main boss")
    assert(loot.Select(vec(0),firstChest,3)==firstChest,"A living chest cannot be preempted by a boss")
    firstChest.Children.Entity.Children.Health.Value=0
    assert(loot.Select(vec(0),firstChest,4)==nextChest,"Any chest variant can become the next target")
    nextChest.Parent=nil;loot.State.CreditController=nil
    assert(loot.Select(vec(0),nextChest,5)==futureBoss,"A despawned chest releases the temporary loot policy")
    local globalChest=mob("Legendary Chest",50000)
    local scoped=account({globalChest,futureBoss})
    scoped.State.MultiSpot=true;scoped.State.MultiSpotSelected={};scoped.State.BossOnly=true
    assert(scoped.Select(vec(0),nil,0)==globalChest,"Any loaded chest is eligible even with Boss Only or an empty arena selection")
    globalChest.Children.Entity.Children.Immortal={};scoped.State.FarmTargetLock=nil;scoped.State.FollowTarget=nil
    assert(not scoped.Select(vec(0),nil,1),"Native invulnerability still prevents chest attacks")
    local trio=account({mob("Arena add",0),mob("DA",5000),mob("RA",6000),mob("KA",7000)})
    assert(trio.Priority.Rank(mob("DA",0))==2 and trio.Priority.Rank(mob("Ra",0))==2 and trio.Priority.Rank(mob("Ka",0))==2,
        "DA/RA/KA are known minibosses even before native markers replicate")
    trio.State.MultiSpot=true;trio.State.MultiSpotSelected={Trio=true}
    trio.State.AutomationCatalog={SpotById={Trio={PlaceId=1,EncounterNames={Da=true,Ra=true,Ka=true}}}}
    local choice=trio.Select(vec(0),nil,0)
    assert(choice and choice.Name=="DA","The selected DA/RA/KA encounter outranks nearby ordinary mobs")
    choice.Name="  dA  "
    assert(trio.State.IsSelectedFarmMob(choice),"Selected encounter aliases tolerate native case and padding differences")
    assert(not trio.Priority.IsChest(mob("Chestnut Treant",0))and trio.Priority.IsChest(mob("TreasureChest",0)),
        "Recognize chest variants without matching chestnut enemies")
    print("PASS Chest focus: finish current enemy, chest before bosses, credit/arena/Boss Only handling, expiry and all chest variants")
    print("PASS DA/RA/KA priority: native-marker fallback and selected-encounter priority over regular mobs")
    print("PASS Credit target convergence: split living locks across three accounts adopt one boss instead of waiting on each other")
    print("PASS Global boss override: main=1, mini=2, cross-arena priority, different account locks converge after current kills, all priority kills and regular arena scope")
    print("PASS Shared farm targets: three account origins, previous targets, iteration order, boss/name/position ordering, death, late HitLives, invulnerability and trade priority")
    print("PASS Forced farm priority: main=1, mini=2, regular=3, higher-rank preemption, stable same-rank locks and native metadata updates")
end
