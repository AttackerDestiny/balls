return function(source)
    local make=assert(loadstring(source))()
    local activeConnections=0
    local function signal()
        local handlers={}
        return {Connect=function(_,fn)
            activeConnections+=1
            local c={Connected=true,Disconnect=function(self)
                if self.Connected then activeConnections-=1;self.Connected=false end
            end}
            handlers[#handlers+1]={c,fn};return c
        end,Fire=function(_,value)for _,item in ipairs(handlers)do if item[1].Connected then item[2](value)end end end}
    end
    local now=0
    local function folder()return {ChildAdded=signal(),ChildRemoved=signal(),Children={},GetChildren=function(self)return self.Children end}end
    local current=folder()
    local function mob()
        local m={Parent=current,Children={},DescendantAdded=signal(),DescendantRemoving=signal(),Reads=0}
        function m:IsA(kind)return kind=="Model"end
        function m:FindFirstChild(name)self.Reads+=1;return self.Children[name]end
        return m
    end
    local m=mob();current.Children={m}
    local changes=0
    local api=make({Now=function()return now end,Folder=function()return current end,Changed=function()changes+=1 end})
    assert(api.Refresh()==current and api.Models[m]and api.Count==1)
    assert(api.Data(m)==nil)
    local reads=m.Reads
    for _=1,100 do api.Data(m)end
    assert(m.Reads==reads,"Repeated incomplete-model reads reuse a bounded negative cache")
    local root={Parent=m,FindFirstChild=function()end,IsA=function(_,kind)return kind=="BasePart"end}
    local entity={Parent=m,Children={},FindFirstChild=function(self,name)return self.Children[name]end}
    local health={Parent=entity,Value=100}
    m.Children.HumanoidRootPart=root;m.Children.Entity=entity;entity.Children.Health=health
    m.DescendantAdded:Fire(health)
    local data=api.Data(m);assert(data and data.Health==health,"Late streamed health is available immediately without retry throttling")
    assert(activeConnections==2,"Ready enemies do not retain temporary missing-data listeners")
    entity.Children.HitLives={Value=4};assert(api.Data(m).HitLives.Value==4)
    data.SkipUntil=2;assert(api.Data(m)==data and api.Data(m).SkipUntil==2,"Controllers share combat observations")
    local nextMob=mob();current.Children[#current.Children+1]=nextMob;current.ChildAdded:Fire(nextMob)
    assert(api.Models[nextMob]and api.Count==2 and changes==2)
    m.Parent=nil;current.ChildRemoved:Fire(m)
    assert(not api.Models[m]and api.Count==1 and not api.Data(m))
    local old=current;current=folder();api.Refresh()
    assert(api.Count==0);old.ChildAdded:Fire(m);assert(api.Count==0,"Replaced folder listeners are disconnected")
    for _=1,1000 do
        local incomplete=mob();current.ChildAdded:Fire(incomplete);api.Data(incomplete)
        assert(activeConnections==4)
        incomplete.Parent=nil;current.ChildRemoved:Fire(incomplete)
        assert(activeConnections==2 and api.Count==0,"Incomplete-enemy churn releases temporary listeners immediately")
    end
    api.Destroy();api.Destroy();current.ChildAdded:Fire(m);assert(api.Count==0 and api.Refresh()==nil and activeConnections==0)
    print("PASS Enemy registry: shared data, immediate late health, independent hit lives, folder replacement, removal and cleanup")
end
