-- A small ownership ledger prevents duplicate native blade touches during aura use.
return function(ctx)
    local api={}
    local held=setmetatable({}, {__mode="k"})
    local container,listener
    local active,closed,nextCheck=false,false,0
    local function releaseBlades()
        for blade,value in pairs(held)do pcall(function()blade.CanTouch=value end)end
        table.clear(held)
    end
    local function own(blade)
        if not active or closed or not blade or blade.Name~="Blade"or not blade:IsA("BasePart")then return end
        local tool=blade.Parent;local weapon=tool and tool.Parent
        if not tool or tool.Name~="Tool"or not weapon or weapon.Parent~=container then return end
        if weapon.Name~="RightWeapon"and weapon.Name~="LeftWeapon"then return end
        pcall(function()
            if held[blade]==nil then held[blade]=blade.CanTouch end
            blade.CanTouch=false
        end)
    end
    local function switch(nextContainer)
        if listener then listener:Disconnect();listener=nil end
        releaseBlades();container=nextContainer
        if container then listener=container.DescendantAdded:Connect(own)end
    end
    function api.Update(now)
        if closed then return end
        now=now or os.clock()
        local desired=ctx.Active()==true
        if now<nextCheck and active==desired then return end
        nextCheck=now+.5;active=desired
        local nextContainer=ctx.Items()
        if nextContainer~=container then switch(nextContainer)end
        if not active then releaseBlades();return end
        if not container then return end
        for _,slot in ipairs({"RightWeapon","LeftWeapon"})do
            local weapon=container:FindFirstChild(slot)
            local tool=weapon and weapon:FindFirstChild("Tool")
            own(tool and tool:FindFirstChild("Blade"))
        end
    end
    function api.Destroy()
        if closed then return end
        closed=true;active=false;switch(nil)
    end
    return api
end
