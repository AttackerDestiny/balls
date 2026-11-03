return function(prioritySource,dataSource,validSource,selectionSource)
    local function load(source,env)
        local fn=assert(loadstring(source));setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn()
    end
    local vectorMT={__sub=function(a,b)return {Magnitude=math.sqrt((a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2)}end}
    local function vec(x,y,z)return setmetatable({X=x,Y=y or 0,Z=z or 0},vectorMT)end
    local folder={}
    local function mob(name,x,rank,hp)
        local m={Name=name,Parent=folder,Children={}}
        local entity={Parent=m,Children={}}
        local root={Position=vec(x),Parent=m,IsA=function(_,kind)return kind=="BasePart"end,FindFirstChild=function()end}
        local health={Value=hp or 100,Parent=entity}
        m.Children.Entity=entity;m.Children.HumanoidRootPart=root;entity.Children.Health=health
        function m:FindFirstChild(key)return self.Children[key]end
        function entity:FindFirstChild(key)return self.Children[key]end
        function m:GetAttribute(key)if key=="Rank"then return rank end end
        function entity:GetAttribute()end
        function m:GetTags()return {}end;function entity:GetTags()return {}end
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
        local state={FarmRange=math.huge,TargetScans=0}
        local api=load(prioritySource)()
        local source=dataSource.."\n"..validSource.."\nreturn {GetData=getMobData,Select=function(origin,previous,now)\n"
            .."local root={Position=origin}\nlocal mobs=folder\nlocal targetRoot=previous and validMob(previous,mobs)\n"
            .."local nextAcquisition=0\nstate.FollowTarget=previous\n"..selectionSource.."\nreturn state.FollowTarget\nend}"
        local result=load(source,{state=state,targetPriority=api,folder=folder,trackedMobs=tracked,
            mobCache=setmetatable({}, {__mode="k"}),os={clock=function()return 0 end}})
        result.State=state;result.Priority=api;return result
    end
    local accounts={account({regular,mini,boss,peer,other,dead}),account({other,peer,boss,mini,regular,dead}),
        account({dead,boss,mini,other,regular,peer})}
    local origins={vec(-10000),vec(10000),vec(500)}
    local previous={other,boss,regular}
    for i,a in ipairs(accounts)do
        assert(a.Select(origins[i],previous[i],0)==peer,"Different positions, previous targets and insertion order must pick the same boss")
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
    for i,a in ipairs(accounts)do assert(a.Select(origins[i],boss,0)==peer,"Removed HitLives cannot remain in the enemy cache")end
    peer.Children.Entity.Children.Health.Value=0;boss.Children.Entity.Children.Health.Value=0
    for i,a in ipairs(accounts)do assert(a.Select(origins[i],peer,0)==other,"All accounts advance to the same next living boss")end
    other.Children.Entity.Children.Immortal={}
    for i,a in ipairs(accounts)do assert(a.Select(origins[i],other,0)==mini,"Immortal bosses remain excluded; mini-bosses precede regular mobs")end
    accounts[1].State.AutoTradeBusy=true
    assert(accounts[1].Select(origins[1],mini,0)==nil,"Trade protection still prevents selecting a farm target")
    print("PASS Shared farm targets: three account origins, previous targets, iteration order, boss/name/position ordering, death, late HitLives, invulnerability and trade priority")
end
