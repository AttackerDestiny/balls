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
    local function animator()
        return {IsA=function(_,class)return class=="Animator"end,AnimationPlayed=signal(),GetPlayingAnimationTracks=function()return {track()}end}
    end
    local a,b=animator(),animator()
    local root={DescendantAdded=signal(),DescendantRemoving=signal(),QueryDescendants=function()return {a}end}
    local api=factory({State=state,Root=root})
    api.Set(true);assert(stopped==1 and state.RemovingAnimations)
    a.AnimationPlayed:Fire(track());assert(stopped==2)
    root.DescendantAdded:Fire(b);assert(stopped==3)
    root.DescendantRemoving:Fire(b);b.AnimationPlayed:Fire(track());assert(stopped==3,"Removed animators release their event connection")
    api.Set(false);a.AnimationPlayed:Fire(track());assert(stopped==3 and not state.RemovingAnimations)
    api.Set(true);local before=stopped;api.Destroy();a.AnimationPlayed:Fire(track());assert(stopped==before)
    print("PASS Animation removal: existing and new tracks, streamed animators, removal, OFF and cleanup")
end
