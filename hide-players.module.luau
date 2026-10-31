-- Local rendering only. Never hide the local character or change physics.
return function(ctx)
    local api={BlockedEffects=0}
    local enabled,disposed=false,false
    local hideCharacters,hideEffects=false,false
    local players,connections,characters={},{},{}
    local itemFolder,itemConnections=nil,{}
    local effectHooks={}
    local selector="BasePart,Decal,ParticleEmitter,Beam,Trail,Light,Highlight,BillboardGui,SurfaceGui,Humanoid,Sound"
    local invisible=NumberSequence.new(1)
    local function restore(record)
        for _,connection in ipairs(record.Connections) do connection:Disconnect() end
        for _,connection in pairs(record.Guards) do connection:Disconnect() end
        for instance,properties in pairs(record.Properties) do
            for name,value in pairs(properties) do pcall(function() instance[name]=value end) end
        end
    end
    local function detach(character)
        local record=characters[character]
        if record then characters[character]=nil; restore(record) end
    end
    local function attach(player,character)
        if disposed or not enabled or player==ctx.Players.LocalPlayer or not character or characters[character] then return end
        local record={Properties={},Connections={},Guards={}}
        characters[character]=record
        local function hide(instance)
            if disposed or not enabled or characters[character]~=record or record.Properties[instance] then return end
            local properties
            if instance:IsA("BasePart") and hideCharacters then properties={Transparency=1,LocalTransparencyModifier=1,CastShadow=false}
            elseif instance:IsA("Decal") and hideCharacters then properties={Transparency=1}
            elseif instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then properties={Enabled=false,Transparency=invisible}
            elseif instance:IsA("Highlight") then properties={Enabled=false}
            elseif (instance:IsA("BillboardGui") or instance:IsA("SurfaceGui")) and hideCharacters then properties={Enabled=false}
            elseif instance:IsA("Light") then properties={Brightness=0}
            elseif instance:IsA("Sound") then properties={Volume=0}
            elseif instance:IsA("Humanoid") and hideCharacters then properties={DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None} end
            if not properties then return end
            local before={}
            for name,value in pairs(properties) do before[name]=instance[name]; instance[name]=value end
            record.Properties[instance]=before
            if properties.Enabled==false then
                record.Guards[instance]=instance:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if enabled and not disposed and characters[character]==record and record.Properties[instance] and instance.Enabled then instance.Enabled=false end
                end)
            end
            if instance:IsA("ParticleEmitter") then instance:Clear() end
        end
        record.Connections[1]=character.DescendantAdded:Connect(hide)
        record.Connections[2]=character.DescendantRemoving:Connect(function(instance)
            local before=record.Properties[instance]
            if before then
                record.Properties[instance]=nil
                if record.Guards[instance] then record.Guards[instance]:Disconnect(); record.Guards[instance]=nil end
                for name,value in pairs(before) do pcall(function() instance[name]=value end) end
            end
        end)
        for _,instance in ipairs(character:QueryDescendants(selector)) do hide(instance) end
    end
    local function removePlayer(player)
        local record=players[player]
        if not record then return end
        for _,connection in ipairs(record.Connections) do connection:Disconnect() end
        if record.Character then detach(record.Character) end
        if record.Items then detach(record.Items) end
        players[player]=nil
    end
    local function attachItems(player)
        local record=players[player]
        if not record then return end
        local items=itemFolder and itemFolder:FindFirstChild(tostring(player.UserId))
        if items==record.Items then return end
        if record.Items then detach(record.Items) end
        record.Items=items
        attach(player,items)
    end
    local function watchItems()
        local folder=ctx.Workspace and ctx.Workspace:FindFirstChild("CharacterItems")
        if folder==itemFolder then return end
        for _,connection in ipairs(itemConnections) do connection:Disconnect() end
        table.clear(itemConnections)
        itemFolder=folder
        if folder then
            itemConnections[1]=folder.ChildAdded:Connect(function(child)
                for player in pairs(players) do if child.Name==tostring(player.UserId) then attachItems(player) end end
            end)
            itemConnections[2]=folder.ChildRemoved:Connect(function(child)
                for _,record in pairs(players) do if record.Items==child then detach(child); record.Items=nil end end
            end)
        end
        for player in pairs(players) do attachItems(player) end
    end
    local function addPlayer(player)
        if disposed or not enabled or player==ctx.Players.LocalPlayer or players[player] then return end
        local record={Connections={}}
        players[player]=record
        local function changed(character)
            if record.Character then detach(record.Character) end
            record.Character=character; attach(player,character)
        end
        record.Connections[1]=player.CharacterAdded:Connect(changed)
        record.Connections[2]=player.CharacterRemoving:Connect(function(character)
            detach(character); if record.Character==character then record.Character=nil end
        end)
        changed(player.Character)
        attachItems(player)
    end
    local function owner(value)
        if typeof(value)~="Instance" and type(value)~="table" then return nil end
        if value==ctx.Players.LocalPlayer then return false end
        for player,record in pairs(players) do
            if value==player then return true end
            if typeof(value)=="Instance" then
                if record.Character and (value==record.Character or value:IsDescendantOf(record.Character)) then return true end
                if record.Items and (value==record.Items or value:IsDescendantOf(record.Items)) then return true end
            end
        end
        local localCharacter=ctx.Players.LocalPlayer.Character
        if typeof(value)=="Instance" and localCharacter and (value==localCharacter or value:IsDescendantOf(localCharacter)) then return false end
        return nil
    end
    function api.IsOtherEffect(data)
        if type(data)~="table" then return owner(data)==true end
        -- Only source/caster fields; target ownership must not suppress hazards.
        for _,field in ipairs({"Character","Player","SourceCharacter","SourcePlayer","Caster"}) do
            local result=owner(data[field])
            if result~=nil then return result end
        end
        return false
    end
    local function hookEffects()
        for _,service in ipairs(ctx.EffectServices or {}) do
            if type(service.DoEffect)=="function" then
                local previous=service.DoEffect
                local wrapper=function(name,data,...)
                    if enabled and not disposed and name~="Damage Text" and api.IsOtherEffect(data) then api.BlockedEffects+=1; return end
                    return previous(name,data,...)
                end
                service.DoEffect=wrapper
                effectHooks[#effectHooks+1]={Service=service,Previous=previous,Wrapper=wrapper}
            end
        end
    end
    local function clear()
        for _,connection in ipairs(connections) do connection:Disconnect() end
        table.clear(connections)
        for _,connection in ipairs(itemConnections) do connection:Disconnect() end
        table.clear(itemConnections); itemFolder=nil
        for _,hook in ipairs(effectHooks) do if hook.Service.DoEffect==hook.Wrapper then hook.Service.DoEffect=hook.Previous end end
        table.clear(effectHooks)
        for player in pairs(players) do removePlayer(player) end
        for character in pairs(characters) do detach(character) end
    end
    local function setMode(charactersValue,effectsValue)
        if disposed then return false end
        charactersValue=charactersValue==true; effectsValue=effectsValue==true
        local wasEnabled,wasCharacters=enabled,hideCharacters
        hideCharacters,hideEffects=charactersValue,effectsValue
        enabled=hideCharacters or hideEffects
        if wasEnabled==enabled and wasCharacters==hideCharacters then return true end
        clear()
        if not enabled then return true end
        connections[1]=ctx.Players.PlayerAdded:Connect(addPlayer)
        connections[2]=ctx.Players.PlayerRemoving:Connect(removePlayer)
        if ctx.Workspace then
            connections[3]=ctx.Workspace.ChildAdded:Connect(function(child) if child.Name=="CharacterItems" then watchItems() end end)
            connections[4]=ctx.Workspace.ChildRemoved:Connect(function(child) if child==itemFolder then watchItems() end end)
        end
        watchItems(); hookEffects()
        for _,player in ipairs(ctx.Players:GetPlayers()) do addPlayer(player) end
        return true
    end
    function api.Set(value) return setMode(value,hideEffects) end
    function api.SetEffects(value) return setMode(hideCharacters,value) end
    function api.Destroy()
        if disposed then return end
        disposed=true; enabled=false; clear()
    end
    return api
end
