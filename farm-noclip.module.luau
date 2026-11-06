-- Character-scoped collision ownership survives farm/travel handoffs and respawns.
return function(ctx)
    local api={}
    local ledger={}
    local owner,partsAdded,physics
    local closed=false
    local function restorePart(part)
        local value=ledger[part]
        ledger[part]=nil
        if part.Parent then part.CanCollide=value end
    end
    local function detach()
        if partsAdded then partsAdded:Disconnect();partsAdded=nil end
        for part in pairs(ledger)do restorePart(part)end
        owner=nil
    end
    local function claim(part)
        if not part:IsA("BasePart")then return end
        if ledger[part]==nil then ledger[part]=part.CanCollide end
        part.CanCollide=false
    end
    function api.Original(part)return ledger[part]end
    function api.Update()
        if closed then return end
        if not ctx.Enabled()then
            detach();if physics then physics:Disconnect();physics=nil end;return
        end
        local current=ctx.Player.Character
        if current~=owner then
            detach();owner=current
            if owner then
                for _,part in ipairs(owner:QueryDescendants("BasePart"))do claim(part)end
                partsAdded=owner.DescendantAdded:Connect(claim)
            end
        end
        for part in pairs(ledger)do
            if not part.Parent then ledger[part]=nil
            elseif owner and not part:IsDescendantOf(owner)then restorePart(part)
            else part.CanCollide=false end
        end
        if not physics then physics=ctx.Pulse:Connect(api.Update)end
    end
    function api.Destroy()
        if closed then return end
        closed=true
        if physics then physics:Disconnect();physics=nil end
        detach()
    end
    return api
end
