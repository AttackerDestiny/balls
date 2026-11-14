return function(source)
    local factory=assert(loadstring(source))()
    local function signal()
        local s={}
        function s:Connect(fn)
            local c={Connected=true,Disconnect=function(self)self.Connected=false end}
            self[#self+1]={Connection=c,Callback=fn};return c
        end
        function s:Fire(value)for _,v in ipairs(self)do if v.Connection.Connected then v.Callback(value)end end end
        return s
    end
    local state={Running=true}
    local stopped=0
    local function track()return {Stop=function()stopped+=1 end}end
    local root={DescendantAdded=signal(),DescendantRemoving=signal()}
    local function model(parent,player,entity)
        return {Name="Rig",Parent=parent,Player=player,IsA=function(_,class)return class=="Model"end,
            FindFirstChild=function(_,name)return name=="Entity"and entity or nil end}
    end
    local own,other=model(root,true,true),model(root,true,true)
    local function animator(parent)
        return {Parent=parent,IsA=function(_,class)return class=="Animator"end,AnimationPlayed=signal(),
            GetPlayingAnimationTracks=function()return {track()}end}
    end
    local a,b=animator(own),animator(other)
    local mobs={Name="Mobs",Parent=root,IsA=function()return false end}
    local enemy=animator(model(mobs))
    local streamed=animator(model(root))
    local entity=animator(model(root,false,true))
    root.QueryDescendants=function()return {a,enemy,streamed,entity}end
    local api=factory({State=state,Root=root,Players={GetPlayerFromCharacter=function(_,node)return node.Player end}})
    api.Set(true);assert(stopped==1 and state.RemovingAnimations)
    for _,protected in ipairs({enemy,streamed,entity})do
        protected.AnimationPlayed:Fire(track())
        assert(#protected.AnimationPlayed==0,"Enemy and unidentified NPC animators cannot acquire suppression listeners")
    end
    assert(stopped==1,"Existing enemy animations must remain untouched")
    a.AnimationPlayed:Fire(track());assert(stopped==2)
    root.DescendantAdded:Fire(b);assert(stopped==3)
    b.Parent=mobs;b.AnimationPlayed:Fire(track());assert(stopped==3,"Recheck ownership before suppressing a reparented Animator")
    b.Parent=other
    root.DescendantRemoving:Fire(b);b.AnimationPlayed:Fire(track());assert(stopped==3,"Removed animators release their event connection")
    api.Set(false);a.AnimationPlayed:Fire(track());assert(stopped==3 and not state.RemovingAnimations)
    api.Set(true);local before=stopped;api.Destroy();a.AnimationPlayed:Fire(track());assert(stopped==before)
    print("PASS Animation removal: player-only tracks, enemy/NPC exclusion, late rigs, ownership changes, removal, OFF and cleanup")
end
