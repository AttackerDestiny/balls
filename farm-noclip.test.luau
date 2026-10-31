return function(source)
    local make=assert(loadstring(source))()
    local function signal()
        local api={Listeners={}}
        function api:Connect(fn)
            local c={Connected=true};function c:Disconnect()self.Connected=false end
            self.Listeners[#self.Listeners+1]={Fn=fn,C=c};return c
        end
        function api:Fire(value)for _,v in ipairs(self.Listeners)do if v.C.Connected then v.Fn(value)end end end
        function api:Count()local n=0;for _,v in ipairs(self.Listeners)do if v.C.Connected then n+=1 end end;return n end
        return api
    end
    local function character()
        local c={DescendantAdded=signal(),Parts={},Scans=0}
        function c:QueryDescendants()self.Scans+=1;return self.Parts end
        return c
    end
    local function part(c,collide)
        local p={Parent=c,CanCollide=collide,CanTouch=true,CanQuery=true}
        function p:IsA(kind)return kind=="BasePart"end
        function p:IsDescendantOf(ancestor)return self.Parent==ancestor end
        c.Parts[#c.Parts+1]=p;return p
    end
    local c=character();local torso=part(c,true);local root=part(c,false)
    local player={Character=c};local active=false;local pulse=signal()
    local api=make({Player=player,Pulse=pulse,Enabled=function()return active end})
    api.Update();assert(torso.CanCollide and pulse:Count()==0)
    active=true;api.Update();assert(not torso.CanCollide and not root.CanCollide)
    assert(api.Original(torso)==true and api.Original(root)==false)
    torso.CanCollide=true;pulse:Fire();assert(not torso.CanCollide and c.Scans==1)
    local handle=part(c,true);c.DescendantAdded:Fire(handle);assert(not handle.CanCollide)
    assert(handle.CanTouch and handle.CanQuery)
    print("PASS Auto Farm noclip covers idle physics resets and new character parts without repeated scans")
    handle.Parent={};pulse:Fire();assert(handle.CanCollide and api.Original(handle)==nil)
    local c2=character();local nextTorso=part(c2,true);player.Character=c2;pulse:Fire()
    assert(torso.CanCollide and not root.CanCollide and not nextTorso.CanCollide)
    active=false;pulse:Fire();assert(nextTorso.CanCollide and pulse:Count()==0)
    assert(c.DescendantAdded:Count()==0 and c2.DescendantAdded:Count()==0)
    print("PASS Auto Farm noclip restores original collisions on item removal, respawn and toggle OFF")
    active=true;api.Update();assert(not nextTorso.CanCollide)
    api.Destroy();api.Destroy();assert(nextTorso.CanCollide and pulse:Count()==0)
    print("PASS Auto Farm noclip cleanup restores collisions and disconnects its physics listener")
end
