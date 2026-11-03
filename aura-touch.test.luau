return function(source)
    local function signal()
        local event={}
        function event:Connect(fn)
            local connection={Connected=true}
            function connection:Disconnect()self.Connected=false end
            event.Fire=function(value)if connection.Connected then fn(value)end end
            return connection
        end
        return event
    end
    local function object(name,parent)
        local item={Name=name,Parent=parent,Children={}}
        if parent then parent.Children[name]=item end
        function item:FindFirstChild(key)return self.Children[key]end
        function item:IsA(kind)return kind=="BasePart"and self.Name=="Blade"end
        return item
    end
    local root=object("My items");root.DescendantAdded=signal()
    local function weapon(name,touch)
        local blade=object("Blade",object("Tool",object(name,root)));blade.CanTouch=touch;return blade
    end
    local right,left=weapon("RightWeapon",true),weapon("LeftWeapon",false)
    local active=true
    local api=assert(loadstring(source))()({Items=function()return root end,Active=function()return active end})
    api.Update(0);assert(not right.CanTouch and not left.CanTouch,"Suppress native weapon touches during aura damage")
    local replacement=weapon("RightWeapon",true)
    root.DescendantAdded.Fire(replacement);assert(not replacement.CanTouch,"Newly equipped blades must be suppressed immediately")
    local other=object("Blade",object("Tool",object("OtherPlayerWeapon",root)));other.CanTouch=true
    root.DescendantAdded.Fire(other);assert(other.CanTouch,"Only this account's exact native weapon slots are affected")
    active=false;api.Update(.1)
    assert(right.CanTouch and replacement.CanTouch and not left.CanTouch,"Restore each blade's original value, including false")
    active=true;api.Update(.2);assert(not replacement.CanTouch)
    api.Destroy();assert(replacement.CanTouch and not left.CanTouch)
    local later=weapon("RightWeapon",true);root.DescendantAdded.Fire(later);assert(later.CanTouch,"Cleanup disconnects the native container observer")
    print("PASS Aura blade touches: exact weapon slots, equipment changes, original values and cleanup")
end
