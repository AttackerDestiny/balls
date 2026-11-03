-- The supplied source disables native blade touches while aura sends damage.
-- Watch only this player's weapon container and restore original properties.
return function(ctx)
    local api={}
    local originals=setmetatable({}, {__mode="k"})
    local root,connection,enabled
    local nextPoll=0
    local function restore()
        for blade,value in pairs(originals)do pcall(function()blade.CanTouch=value end)end
        table.clear(originals)
    end
    local function apply(blade)
        local tool=blade and blade.Parent
        local weapon=tool and tool.Parent
        if not enabled or not blade or not blade:IsA("BasePart")or blade.Name~="Blade"or not tool or tool.Name~="Tool"
            or not weapon or weapon.Parent~=root or (weapon.Name~="RightWeapon"and weapon.Name~="LeftWeapon")then return end
        pcall(function()
            if originals[blade]==nil then originals[blade]=blade.CanTouch end
            if blade.CanTouch then blade.CanTouch=false end
        end)
    end
    function api.Update(now)
        now=now or os.clock()
        local active=ctx.Active()==true
        if now<nextPoll and active==enabled then return end
        nextPoll=now+.5
        local current=ctx.Items()
        if current~=root then
            if connection then connection:Disconnect();connection=nil end
            restore();root=current
            if root then connection=root.DescendantAdded:Connect(apply)end
        end
        enabled=active
        if not enabled then restore();return end
        if not root then return end
        for _,name in ipairs({"RightWeapon","LeftWeapon"})do
            local weapon=root:FindFirstChild(name)
            local tool=weapon and weapon:FindFirstChild("Tool")
            local blade=tool and tool:FindFirstChild("Blade")
            if blade then apply(blade)end
        end
    end
    function api.Destroy()
        if connection then connection:Disconnect();connection=nil end
        enabled=false;restore();root=nil
    end
    return api
end
