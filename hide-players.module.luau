-- Visibility is a reversible property overlay scoped to remote player roots.
return function(ctx)
    local api={BlockedEffects=0}
    local modes={Characters=false,Effects=false,Closed=false}
    local roster,roots,globalConnections,itemConnections,hooks={},{},{},{},{}
    local itemFolder
    local invisible=NumberSequence.new(1)
    local classes="BasePart,Decal,ParticleEmitter,Beam,Trail,Light,Highlight,BillboardGui,SurfaceGui,Humanoid,Sound"
    local function disconnect(list)
        for _,connection in pairs(list)do connection:Disconnect()end
        table.clear(list)
    end
    local function enabled()return not modes.Closed and (modes.Characters or modes.Effects)end
    local function restoreValue(layer,object)
        local before=layer.Values[object]
        layer.Values[object]=nil
        local guard=layer.Guards[object]
        if guard then guard:Disconnect();layer.Guards[object]=nil end
        if before then for property,value in pairs(before)do pcall(function()object[property]=value end)end end
    end
    local function release(root)
        local layer=roots[root]
        if not layer then return end
        roots[root]=nil;disconnect(layer.Connections)
        for object in pairs(layer.Values)do restoreValue(layer,object)end
        disconnect(layer.Guards)
    end
    local function properties(object)
        if modes.Characters then
            if object:IsA("BasePart")then return {Transparency=1,LocalTransparencyModifier=1,CastShadow=false}end
            if object:IsA("Decal")then return {Transparency=1}end
            if object:IsA("BillboardGui")or object:IsA("SurfaceGui")then return {Enabled=false}end
            if object:IsA("Humanoid")then return {DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None}end
        end
        if object:IsA("ParticleEmitter")or object:IsA("Beam")or object:IsA("Trail")then return {Enabled=false,Transparency=invisible}end
        if object:IsA("Highlight")then return {Enabled=false}end
        if object:IsA("Light")then return {Brightness=0}end
        if object:IsA("Sound")then return {Volume=0}end
    end
    local function overlay(person,root)
        if not root or not enabled()or person==ctx.Players.LocalPlayer or roots[root]then return end
        local layer={Owner=person,Values={},Guards={},Connections={}}
        roots[root]=layer
        local function apply(object)
            if not enabled()or roots[root]~=layer or layer.Values[object]then return end
            local changes=properties(object)
            if not changes then return end
            local old={}
            for property,value in pairs(changes)do old[property]=object[property];object[property]=value end
            layer.Values[object]=old
            if changes.Enabled==false then
                layer.Guards[object]=object:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if enabled()and roots[root]==layer and layer.Values[object]and object.Enabled then object.Enabled=false end
                end)
            end
            if object:IsA("ParticleEmitter")then pcall(function()object:Clear()end)end
        end
        layer.Connections={root.DescendantAdded:Connect(apply),root.DescendantRemoving:Connect(function(object)restoreValue(layer,object)end)}
        for _,object in ipairs(root:QueryDescendants(classes))do apply(object)end
    end
    local function unwatch(person)
        local record=roster[person]
        if not record then return end
        roster[person]=nil;disconnect(record.Connections)
        if record.Character then release(record.Character)end
        if record.Items then release(record.Items)end
    end
    local function updateItems(person)
        local record=roster[person]
        if not record then return end
        local nextRoot=itemFolder and itemFolder:FindFirstChild(tostring(person.UserId))
        if record.Items==nextRoot then return end
        if record.Items then release(record.Items)end
        record.Items=nextRoot;overlay(person,nextRoot)
    end
    local function itemFolderChanged()
        local current=ctx.Workspace and ctx.Workspace:FindFirstChild("CharacterItems")
        if current==itemFolder then return end
        disconnect(itemConnections);itemFolder=current
        if current then
            itemConnections={current.ChildAdded:Connect(function(child)
                for person in pairs(roster)do if tostring(person.UserId)==child.Name then updateItems(person)end end
            end),current.ChildRemoved:Connect(function(child)
                for _,record in pairs(roster)do if record.Items==child then release(child);record.Items=nil end end
            end)}
        end
        for person in pairs(roster)do updateItems(person)end
    end
    local function watch(person)
        if not enabled()or person==ctx.Players.LocalPlayer or roster[person]then return end
        local record={Connections={}}
        roster[person]=record
        local function characterChanged(character)
            if record.Character then release(record.Character)end
            record.Character=character;overlay(person,character)
        end
        record.Connections={person.CharacterAdded:Connect(characterChanged),person.CharacterRemoving:Connect(function(character)
            release(character);if record.Character==character then record.Character=nil end
        end)}
        characterChanged(person.Character);updateItems(person)
    end
    local function owner(value)
        local kind=typeof(value)
        if kind~="Instance"and type(value)~="table"then return nil end
        if value==ctx.Players.LocalPlayer then return false end
        local localCharacter=ctx.Players.LocalPlayer.Character
        if kind=="Instance"and localCharacter and (value==localCharacter or value:IsDescendantOf(localCharacter))then return false end
        for person,record in pairs(roster)do
            if value==person then return true end
            if kind=="Instance"then
                for _,root in pairs({record.Character,record.Items})do if value==root or value:IsDescendantOf(root)then return true end end
            end
        end
        return nil
    end
    function api.IsOtherEffect(payload)
        if type(payload)~="table"then return owner(payload)==true end
        for _,field in ipairs({"Character","Player","SourceCharacter","SourcePlayer","Caster"})do
            local found=owner(payload[field]);if found~=nil then return found end
        end
        return false
    end
    local function cleanup()
        disconnect(globalConnections);disconnect(itemConnections);itemFolder=nil
        for _,hook in ipairs(hooks)do if hook.Service.DoEffect==hook.Wrapper then hook.Service.DoEffect=hook.Previous end end
        table.clear(hooks)
        for person in pairs(roster)do unwatch(person)end
        for root in pairs(roots)do release(root)end
    end
    local function initialize()
        globalConnections={ctx.Players.PlayerAdded:Connect(watch),ctx.Players.PlayerRemoving:Connect(unwatch)}
        if ctx.Workspace then
            globalConnections[#globalConnections+1]=ctx.Workspace.ChildAdded:Connect(function(child)if child.Name=="CharacterItems"then itemFolderChanged()end end)
            globalConnections[#globalConnections+1]=ctx.Workspace.ChildRemoved:Connect(function(child)if child==itemFolder then itemFolderChanged()end end)
        end
        itemFolderChanged()
        for _,person in ipairs(ctx.Players:GetPlayers())do watch(person)end
        for _,service in ipairs(ctx.EffectServices or {})do
            if type(service.DoEffect)=="function"then
                local old=service.DoEffect
                local wrapper=function(name,payload,...)
                    if enabled()and name~="Damage Text"and api.IsOtherEffect(payload)then api.BlockedEffects+=1;return end
                    return old(name,payload,...)
                end
                service.DoEffect=wrapper;hooks[#hooks+1]={Service=service,Previous=old,Wrapper=wrapper}
            end
        end
    end
    local function mode(characters,effects)
        if modes.Closed then return false end
        characters,effects=characters==true,effects==true
        if modes.Characters==characters and modes.Effects==effects then return true end
        cleanup();modes.Characters=characters;modes.Effects=effects
        if enabled()then initialize()end
        return true
    end
    function api.Set(value)return mode(value,modes.Effects)end
    function api.SetEffects(value)return mode(modes.Characters,value)end
    function api.Destroy()if modes.Closed then return end;modes.Closed=true;cleanup()end
    return api
end
