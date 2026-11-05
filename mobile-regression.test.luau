-- Offline Luau CLI tests. No client, network, or MCP is used.
return function(sources)
    local passes=0
    local function test(name,fn)fn();passes+=1;print("PASS "..name)end
    local vectorMT={}
    local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z or 0},vectorMT)end
    vectorMT.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    vectorMT.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    vectorMT.__index=function(v,k)if k=="Magnitude"then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end end
    local function signal()
        local callbacks={}
        local value={}
        function value:Connect(fn)
            local c={Connected=true};function c:Disconnect()self.Connected=false end
            callbacks[#callbacks+1]={Connection=c,Fn=fn};return c
        end
        function value:Fire(...)
            local snapshot=table.clone(callbacks)
            for _,entry in ipairs(snapshot)do if entry.Connection.Connected then entry.Fn(...)end end
        end
        return value
    end
    local instanceMT={}
    local function instance(class)
        return setmetatable({Class=class,Props={Name=class},Children={},Signals={},Dead=false},instanceMT)
    end
    instanceMT.__index=function(o,k)
        if k=="Parent"then return rawget(o,"Owner")end
        if k=="GetChildren"then return function(self)return table.clone(self.Children)end end
        if k=="IsA"then return function(self,c)return c==self.Class or c=="ValueBase" and self.Class=="NumberValue"end end
        if k=="FindFirstChild"then return function(self,n)for _,c in ipairs(self.Children)do if c.Name==n then return c end end end end
        if k=="SetAttribute"then return function(self,n,v)self.Props["Attr_"..n]=v end end
        if k=="GetAttribute"then return function(self,n)return self.Props["Attr_"..n]end end
        if k=="GetPropertyChangedSignal"then return function(self,n)self.Signals[n]=self.Signals[n]or signal();return self.Signals[n]end end
        if k=="Destroy"then return function(self)
            if self.Dead then return end
            rawset(self,"Dead",true)
            if self.Signals.Destroying then self.Signals.Destroying:Fire()end
            for _,child in ipairs(table.clone(self.Children))do child:Destroy()end
            self.Parent=nil
        end end
        if k=="Destroying"or k=="InputBegan"or k=="InputChanged"or k=="InputEnded"or k=="Changed"then
            o.Signals[k]=o.Signals[k]or signal();return o.Signals[k]
        end
        return o.Props[k]
    end
    instanceMT.__newindex=function(o,k,v)
        if k=="Parent"then
            local old=rawget(o,"Owner")
            if old then local i=table.find(old.Children,o);if i then table.remove(old.Children,i)end end
            rawset(o,"Owner",v);if v then v.Children[#v.Children+1]=o end
        else
            o.Props[k]=v
            if o.Signals[k]then o.Signals[k]:Fire()end
        end
    end
    local function load(source,environment)
        local chunk=assert(loadstring(source))
        setfenv(chunk,setmetatable(environment or {},{__index=getfenv()}))
        return chunk()
    end
    local env={Vector3={new=vec},Vector2={new=vec},
        UDim2={new=function(xs,xo,ys,yo)return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}}end},
        UDim={new=function(s,o)return {Scale=s,Offset=o}end},
        Color3={fromRGB=function(r,g,b)return {r,g,b}end},TweenInfo={new=function()return {}end},
        Enum={ScrollingDirection={Y=1},SortOrder={LayoutOrder=1},Font={Gotham=1},TextXAlignment={Left=1},
            TextTruncate={AtEnd=1},EasingStyle={Quad=1},EasingDirection={Out=1},UserInputType={MouseButton1=1,Touch=2,MouseMovement=3}}}
    env.UDim2.fromOffset=function(x,y)return env.UDim2.new(0,x,0,y)end
    env.UDim2.fromScale=function(x,y)return env.UDim2.new(x,0,y,0)end
    local function hudFixture()
        local f={Time=0,Parent=instance("ScreenGui"),State={Running=true,HealthUpdates=0},Data={}}
        f.Parent.AbsoluteSize=vec(1280,720)
        local tween={Create=function(_,target,_,props)return {Play=function()for k,v in pairs(props)do target[k]=v end end,Cancel=function()end}end}
        f.Ctx={State=f.State,Parent=f.Parent,Now=function()return f.Time end,Viewport=function()return vec(1280,720)end,
            GetData=function(m)return f.Data[m]end,Corner=function()end,TweenService=tween,Input=instance("Input"),
            Create=function(class,props,parent)local o=instance(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end}
        function f.Mob(name,hp)
            local m=instance("Model");m.Name=name;m.Parent=f.Parent
            local e=instance("Folder");e.Parent=m
            local h=instance("NumberValue");h.Value=hp;h.Name="Health";h.Parent=e
            f.Data[m]={Health=h,Entity=e};return m,h
        end
        f.Factory=load(sources.HUD,env)
        return f
    end
    test("one health row for repeated normal/skill touches and shared health aliases",function()
        local f=hudFixture();local mob,h=f.Mob("Boss",100)
        local native=instance("Frame");native.Name="GameHealth";native.Parent=f.Parent
        local api=f.Factory(f.Ctx)
        for _=1,30 do api.Touch(mob)end
        local alias=f.Mob("Alias",100);f.Data[alias]=f.Data[mob];api.Touch(alias)
        assert(api.Count==1 and #api.Root:GetChildren()==2)
        local other=f.Mob("Boss",100);api.Touch(other)
        assert(api.Count==2,"Distinct same-name mobs still get separate bars")
        api.Destroy();api.Destroy();assert(not native.Dead)
    end)
    test("repeated mobile HUD initialization disposes old rows and listeners",function()
        local f=hudFixture();local mob,h=f.Mob("Boss",100)
        local a=f.Factory(f.Ctx);a.Touch(mob)
        local b=f.Factory(f.Ctx);b.Touch(mob)
        assert(a.Count==0 and b.Count==1 and a.Root.Parent==nil)
        a.Touch(mob);a.Update();assert(a.Count==0)
        local before=f.State.HealthUpdates;h.Value=80;b.Update()
        assert(f.State.HealthUpdates-before==1,"Only the current controller responds")
        local count=0;for _,c in ipairs(f.Parent:GetChildren())do if c.Name=="EnemyHealth"then count+=1 end end
        assert(count==1);b.Root:Destroy();assert(b.Count==0)
    end)
    test("health bursts coalesce into one bounded HUD update",function()
        local f=hudFixture();local mob,h=f.Mob("Boss",10000)
        local api=f.Factory(f.Ctx);api.Touch(mob)
        local before=f.State.HealthUpdates
        for hp=9999,9500,-1 do h.Value=hp end
        assert(f.State.HealthUpdates==before,"Health signals must not allocate a tween for every player hit")
        api.Update();assert(f.State.HealthUpdates==before+1 and f.State.ObservedHealth==9500)
        for hp=9499,9000,-1 do h.Value=hp end
        api.Update();assert(f.State.HealthUpdates==before+1,"Repeated calls in one refresh interval must coalesce")
        f.Time=.13;api.Update();assert(f.State.HealthUpdates==before+2 and f.State.ObservedHealth==9000)
        api.Destroy()
    end)
    local function travelFixture()
        local f={Time=0,Probes=0,Streams=0,Active=true,Character={},Root={Parent=true,Position=vec(0,5,0),Size=vec(2,2,1)},Humanoid={Health=100,HipHeight=2}}
        f.Ctx={Clock=function()return f.Time end,Wait=function(n)f.Time+=n end,
            Character=function()return f.Character,f.Root,f.Humanoid end,Valid=function(p)return p.Y>-200 end,
            Hold=function(_,root,_,p)root.Position=p end,Surface=function()f.Probes+=1;return vec(100,20,100)end,
            Stream=function()f.Streams+=1 end}
        function f.Move(automatic)return load(sources.Travel,env)(f.Ctx).Move(vec(100,20,100),automatic,function()return f.Active end)end
        return f
    end
    test("mobile travel physically approaches before probing and waits for collision",function()
        local f=travelFixture()
        f.Ctx.Stream=function()f.Streams+=1;error("Streaming API unsupported")end
        f.Ctx.Surface=function()
            assert(f.Root.Position.X==100,"Stage near the arena before raycasts")
            f.Probes+=1;if f.Probes>=3 then return vec(100,20,100)end
        end
        local landing=f.Move();assert(f.Probes==3 and landing.Position.Y==0)
        assert(f.Time>=.6,"Verify a stable position rather than just recording an ID")
    end)
    test("unloaded or server-corrected destinations fail for bounded retry",function()
        local f=travelFixture();f.Ctx.Surface=function()f.Probes+=1 end
        assert(not pcall(f.Move)and f.Probes==4)
        local g=travelFixture();g.Ctx.Wait=function(n)g.Time+=n;g.Root.Position=vec(0,0,0)end
        assert(not pcall(g.Move)and g.Time<=2.2)
    end)
    test("explicit map deletion can confirm a stable arena hold without deleted floor collision",function()
        local f=travelFixture();f.Ctx.Surface=function()return nil end;f.Ctx.MapDeleted=function()return true end
        local landing=f.Move(true)
        assert(landing.Position.Y==0 and f.Streams==1 and f.Time>=.3,"Use the configured arena height only when map deletion is explicitly enabled")
    end)
    test("panic/respawn invalidates in-flight arena travel",function()
        for _,respawn in ipairs({false,true})do
            local f=travelFixture();f.Ctx.Stream=function()if respawn then f.Character={}else f.Active=false end end
            local ok=pcall(f.Move);assert(not ok and f.Probes==0)
        end
    end)
    test("manual and Multi Spot travel land exactly 20 below the selected position",function()
        for _,automatic in ipairs({false,true})do
            local f=travelFixture()
            f.Ctx.Surface=function()return vec(100,10,100)end
            local landing=f.Move(automatic)
            assert(landing.Position.Y==0 and landing.SurfaceY==10)
        end
    end)
    test("idle farming stays 20 below the floor regardless of old above mode",function()
        local point
        local state={OffsetMode="Above"}
        local api={FloorY=function()return 100 end}
        load(sources.Idle,{state=state,api=api,player={Character={FindFirstChild=function()return {Position=vec(10,200,30)}end}},
            ctx={Hold=function(p)point=p end},Vector3={new=vec}})
        api.Idle()
        assert(point.X==10 and point.Y==80 and point.Z==30 and state.IdleBelowMap and not state.IdleAboveMap)
        api.Idle(vec(840,798,336))
        assert(point.X==840 and point.Y==778 and point.Z==336,"An idle Multi Spot holds exactly 20 below its selected source position")
    end)
    -- Run the ACTUAL Destroy body from kill-aura with inert cleanup dependencies.
    test("close/reload saves Multi Spot ON before runtime cleanup",function()
        local saved
        local state={Running=true,MultiSpot=true,SafeMode=true,Enabled=true,AutoFarm=true,SkillAura=true}
        function state.SaveNow()saved={MultiSpot=state.MultiSpot,SafeMode=state.SafeMode,Enabled=state.Enabled};return true end
        local noop=function()end
        local ctx={state=state,configReady=true,env={SB2KillAura=state},connections={},trackedMobs={},
            waveDodge={Destroy=noop},healthHUD={Destroy=noop},normalScheduler={Destroy=noop},stopSword=noop,stopMovement=noop,
            runtimeOwner={Release=noop}}
        load(sources.Destroy.."\nreturn true",ctx)
        state.Destroy(false,false)
        assert(saved.MultiSpot and saved.SafeMode and saved.Enabled)
        assert(state.MultiSpot and not state.Running)
        assert(ctx.env.SB2KillAura==nil)
    end)
    local function ownerFixture()
        local f={Parent=instance("PlayerGui"),Time=10,Pulse=signal(),Created=0}
        f.Factory=load(sources.Owner)
        f.Ctx={Parent=f.Parent,Build="new",Job="current-job",Now=function()return f.Time end,Pulse=f.Pulse,
            Create=function()f.Created+=1;return instance("ScreenGui")end}
        return f
    end
    test("repeated auto-execute while loading or running creates one UI",function()
        local f=ownerFixture();local first=f.Factory(f.Ctx)
        for _=1,20 do
            local duplicate,root=f.Factory(f.Ctx)
            assert(not duplicate and root==first.Root)
        end
        first.Ready()
        for _=1,20 do assert(not f.Factory(f.Ctx))end
        assert(f.Created==1 and #f.Parent:GetChildren()==1)
        f.Time=16;f.Pulse:Fire();assert(first.Root:GetAttribute("SB2Heartbeat")==16)
    end)
    test("active UI survives isolated globals; stale build and orphan copies retire",function()
        local f=ownerFixture();local first=f.Factory(f.Ctx);first.Ready()
        -- No env/global reference is supplied: ownership comes from PlayerGui.
        assert(not f.Factory(f.Ctx))
        local stale=instance("ScreenGui");stale.Name="SB2KillAuraUI";stale.Parent=f.Parent
        assert(not f.Factory(f.Ctx) and stale.Dead and first.Alive())
        f.Ctx.Build="newer";local replacement=f.Factory(f.Ctx);replacement.Retire()
        assert(not first.Alive() and replacement.Alive() and #f.Parent:GetChildren()==1)
        replacement.Release();local third=f.Factory(f.Ctx);third.Retire()
        assert(third.Alive() and #f.Parent:GetChildren()==1)
    end)
    test("mobile worker and toggle save survive unavailable privileged input",function()
        local state={Running=true,Enabled=true,AutoFarm=true,SafeMode=false,MultiSpot=true,MultiSpotSelected={},UI={},FloorDestinations={},
            ConfigPath="settings.json",SavedScriptPath="script.luau",Build="fixture"}
        local saved,updates,queued={},0,{}
        function state.SaveNow()saved[#saved+1]=state.MultiSpot;return true end
        local player={Name="Me",UserId=1,OnTeleport=signal()}
        local players={LocalPlayer=player,PlayerAdded=signal()}
        function players:GetPlayers()return {player}end
        local services={HttpService={GenerateGUID=function()return "token"end},StarterGui={},
            GuiService={},TeleportService={TeleportInitFailed=signal()}}
        local game={PlaceId=11,JobId="fixture",GameId=1,ReplicatedStorage={Profiles={FindFirstChild=function()
            return {FindFirstChild=function()return {FindFirstChild=function()return true end}end}
        end},Database={Locations={}}}}
        function game:GetService(name)
            if name=="VirtualInputManager"then error("Not supported on this executor")end
            return services[name]
        end
        local catalog={Floors={},FloorById={},Spots={},SpotById={},Aliases={}}
        function catalog.AddCurrent()end;function catalog.Sort()end
        function catalog.NormalizeSelection(value)return value end
        local search={Active=false,Stop=function()end}
        local safe={Reset=function()end,Update=function()end}
        local multi={Reset=function()end,Update=function()updates+=1 end}
        local globals={}
        local adapter=load(sources.Adapter,{game=game,getgenv=function()return globals end,
            require=function()return {floors={}}end,isfile=function()return false end,
            typeof=type,setthreadidentity=function()error("Identity changes denied")end,
            task={spawn=function(f)queued[#queued+1]=f end,defer=function(f)queued[#queued+1]=f end,
                wait=function()state.Running=false end}})
        local multiContext
        adapter({State=state,Player=player,Players=players,MakeCatalog=function()return catalog end,
            Make=function()return search end,MakeSafe=function()return safe end,MakeMulti=function(ctx)multiContext=ctx;return multi end,
            MakeFriend=load(sources.Friend),MakeUI=function()return {Refresh=function()end}end,Bind=function()end})
        state.SetMultiSpot(false);state.SetMultiSpot(true)
        assert(saved[#saved]==true and state.MultiSpot)
        queued[1]() -- actual background worker: rejected identity must not kill it
        assert(updates==1 and state.MultiSpot and saved[#saved]==true)
        assert(not multiContext.CanMove(),"Loading characters must not consume travel retries")
        local root={Anchored=true};local humanoid={Health=100}
        player.Character={FindFirstChild=function()return root end,FindFirstChildOfClass=function()return humanoid end}
        assert(not multiContext.CanMove())
        root.Anchored=false;humanoid.Health=0;assert(not multiContext.CanMove())
        humanoid.Health=100;assert(multiContext.CanMove())
        state.AutoFarm=false;state.Enabled=true
        assert(not multiContext.CanMove(),"Kill Aura alone cannot authorize Multi Spot movement")
        state.AutoFarm=true
        local progressionUpdates=0
        state.AccountProgression=true;assert(not multiContext.CanMove(),"Progression owns travel without changing the Multi Spot toggle")
        state.ProgressionController={Update=function()progressionUpdates+=1 end}
        state.SafeMode=false;state.MultiSpot=false;state.Running=true
        queued[1]()
        assert(progressionUpdates==1 and updates==1,"Progression-only mode must run without the Multi Spot worker")
    end)
    print("All "..passes.." mobile regression scenarios passed")
    return passes
end
