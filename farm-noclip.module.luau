-- Auto Farm owns collision changes across idle, travel and farming handoffs.
return function(ctx)
    local api={}
    local character,added,pulse
    local originals={}
    local disposed=false
    local function restore()
        if added then added:Disconnect();added=nil end
        for part,value in pairs(originals)do if part.Parent then part.CanCollide=value end end
        originals={};character=nil
    end
    local function remember(part)
        if part:IsA("BasePart")then
            if originals[part]==nil then originals[part]=part.CanCollide end
            part.CanCollide=false
        end
    end
    function api.Original(part)return originals[part]end
    function api.Update()
        if disposed then return end
        if not ctx.Enabled()then
            restore()
            if pulse then pulse:Disconnect();pulse=nil end
            return
        end
        local current=ctx.Player.Character
        if current~=character then
            restore();character=current
            if current then
                for _,part in ipairs(current:QueryDescendants("BasePart"))do remember(part)end
                added=current.DescendantAdded:Connect(remember)
            end
        end
        for part in pairs(originals)do
            if not part.Parent then originals[part]=nil
            elseif character and not part:IsDescendantOf(character)then
                part.CanCollide=originals[part];originals[part]=nil
            elseif part.CanCollide then part.CanCollide=false end
        end
        if not pulse then pulse=ctx.Pulse:Connect(api.Update)end
    end
    function api.Destroy()
        if disposed then return end
        disposed=true
        if pulse then pulse:Disconnect();pulse=nil end
        restore()
    end
    return api
end
