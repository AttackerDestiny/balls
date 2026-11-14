return function(source)
    local make=assert(loadstring(source))()
    local jobs,connection={},nil
    local now,chunk,peak,scans,terrainClears=0,0,0,0,0
    local state={Running=true}
    local root={Name="Workspace"}
    local parts={}
    local function node(name,class,parent)
        local n={Name=name,ClassName=class,Parent=parent,Children={}}
        function n:IsA(kind)return self.ClassName==kind or (kind=="BasePart"and (class=="Part"or class=="Terrain"))end
        function n:FindFirstChild(name)return self.Children[name]end
        function n:FindFirstChildOfClass(kind)for _,v in pairs(self.Children)do if v.ClassName==kind then return v end end end
        function n:Destroy()self.Parent=nil;self.Deleted=true;chunk+=1;now+=.00005 end
        return n
    end
    local protected={}
    for _,name in ipairs({"Mobs","Characters","CharacterItems","HitEffects","WaveDefenseStuff","MobSpawnEffects","TeleportPad","QuestNPC","Camera"})do
        local container=node(name,name=="Camera"and "Camera"or "Folder",root)
        protected[#protected+1]=node("Part","Part",container)
    end
    local character=node("OtherAccount","Model",root)
    protected[#protected+1]=node("Head","Part",character)
    protected[#protected+1]=node("Terrain","Terrain",root)
    local hazard=node("Wave","Part",root);hazard.Protected=true;protected[#protected+1]=hazard
    local touch=node("Pad","Part",root);touch.Children.Touch={ClassName="TouchTransmitter"};protected[#protected+1]=touch
    for i=1,200 do parts[#parts+1]=node("Wall","Part",root)end
    for _,part in ipairs(protected)do parts[#parts+1]=part end
    root.DescendantAdded={Connect=function(_,fn)
        connection={Callback=fn,Disconnect=function(self)self.Disconnected=true end};return connection
    end}
    function root:QueryDescendants(selector)assert(selector=="BasePart");scans+=1;return table.clone(parts)end
    local api=make({State=state,Root=root,Players={GetPlayerFromCharacter=function(_,value)return value==character end},
        Protected=function(part)return part.Protected end,ClearTerrain=function()terrainClears+=1 end,Now=function()return now end,
        Defer=function(fn)jobs[#jobs+1]=fn end,Wait=function()peak=math.max(peak,chunk);chunk=0 end})
    assert(scans==0 and #jobs==0,"Default OFF does no map work")
    api.Set(true);assert(api.Removed==0 and #jobs==1,"Enabling never destroys map synchronously")
    table.remove(jobs,1)()
    assert(terrainClears==1 and api.TerrainCleared and api.Pending==0,"Terrain cleanup is deferred and pending references are released")
    assert(api.Removed==200 and peak<=32,"Initial map deletion is spread across bounded slices")
    for _,part in ipairs(protected)do assert(not part.Deleted,"Gameplay objects and terrain must survive")end
    local streamed=node("NewWall","Part",root)
    connection.Callback(streamed);connection.Callback(streamed)
    assert(#jobs==1 and not streamed.Deleted,"Streaming bursts share one deferred worker")
    table.remove(jobs,1)();assert(streamed.Deleted and scans==1,"Streaming never rescans the whole workspace")
    for i=1,8300 do
        local part=node("BurstWall","Part",root);parts[#parts+1]=part;connection.Callback(part)
    end
    assert(api.MaxQueued<=8192 and #jobs==1,"Stream bursts have a bounded retained queue")
    table.remove(jobs,1)();assert(api.Pending==0 and api.Removed==8501,"Overflow is recovered with one deferred rescan")
    local cancelled=node("LaterWall","Part",root)
    connection.Callback(cancelled);api.Set(false);table.remove(jobs,1)()
    assert(not cancelled.Deleted and connection.Disconnected,"OFF cancels pending destruction and disconnects streaming")
    api.Set(true);api.Destroy();table.remove(jobs,1)()
    assert(not cancelled.Deleted,"Disposal cancels a pending initial scan")
    print("PASS Map deletion: default OFF, bounded deletion, streamed parts, no rescans, gameplay protection, cancellation and cleanup")
end
