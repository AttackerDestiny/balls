-- Client-only static geometry removal; never delete gameplay containers/models.
return function(ctx)
    local api={Removed=0,Pending=0,MaxQueued=0}
    local enabled,disposed,worker=false,false,false
    local generation=0
    local added
    local needsScan=false
    local queue,queued={},setmetatable({}, {__mode="k"})
    local head,tail=1,0
    local protectedNames={Mobs=true,Characters=true,CharacterItems=true,HitEffects=true,
        WaveDefenseStuff=true,MobSpawnEffects=true,CurrentCamera=true}
    local protectedWords={"teleport","portal","spawn","checkpoint","trigger","hazard","npc","shop","quest","pad","door"}
    local function removable(part)
        if not part.Parent or not part:IsA("BasePart")or part:IsA("Terrain")then return false end
        if ctx.Protected(part)then return false end
        local current=part
        while current and current~=ctx.Root do
            if protectedNames[current.Name]or current:IsA("Camera")or current:IsA("Tool")then return false end
            local name=current.Name:lower()
            for _,word in ipairs(protectedWords)do
                if name:find(word,1,true)then return false end
            end
            if current:IsA("Model")and (ctx.Players:GetPlayerFromCharacter(current)
                or current:FindFirstChildOfClass("Humanoid")or current:FindFirstChild("Entity"))then return false end
            if current:FindFirstChildOfClass("ProximityPrompt")or current:FindFirstChildOfClass("ClickDetector")
                or current:FindFirstChildOfClass("TouchTransmitter")then return false end
            current=current.Parent
        end
        return current==ctx.Root
    end
    api.Removable=removable
    local function start()
        if worker or not enabled or disposed then return end
        worker=true
        local token=generation
        ctx.Defer(function()
            if token~=generation or disposed or not ctx.State.Running then return end
            local scan=needsScan and ctx.Root:QueryDescendants("BasePart")or {}
            needsScan=false
            local index,scanTail=1,#scan
            if ctx.ClearTerrain then
                local ok,reason=pcall(ctx.ClearTerrain)
                api.TerrainCleared=ok
                if not ok then api.LastError=tostring(reason)end
            end
            while token==generation and enabled and not disposed and ctx.State.Running do
                if ctx.State.StopEverything then ctx.Wait(.25)
                else
                    local deadline=ctx.Now()+.0015
                    local count=0
                    while count<128 and ctx.Now()<deadline and token==generation and enabled do
                        local part
                        if index<=scanTail then part=scan[index];scan[index]=nil;index+=1
                        elseif head<=tail then part=queue[head];queue[head]=nil;head+=1;queued[part]=nil
                        else break end
                        local checked,canRemove=pcall(removable,part)
                        if checked and canRemove then
                            local ok=pcall(function()part:Destroy()end)
                            if ok then api.Removed+=1 end
                        end
                        count+=1
                    end
                    api.Pending=math.max(0,scanTail-index+1)+math.max(0,tail-head+1)
                    if index>scanTail and head>tail then
                        if needsScan then scan=ctx.Root:QueryDescendants("BasePart");index=1;scanTail=#scan;needsScan=false
                        else break end
                    end
                    ctx.Wait()
                end
            end
            if token==generation then
                table.clear(queue);table.clear(queued);head,tail=1,0;worker=false;api.Pending=0
            end
        end)
    end
    function api.Set(value)
        if disposed then return false end
        value=value==true
        if value==enabled then return true end
        enabled=value;generation+=1
        if added then added:Disconnect();added=nil end
        table.clear(queue);table.clear(queued);head,tail=1,0;worker=false;api.Pending=0
        if enabled then
            needsScan=true
            added=ctx.Root.DescendantAdded:Connect(function(part)
                if not enabled or not part:IsA("BasePart")or queued[part]then return end
                if tail-head+1>=8192 then needsScan=true;return end
                tail+=1;queue[tail]=part;queued[part]=true
                api.MaxQueued=math.max(api.MaxQueued,tail-head+1)
                start()
            end)
            start()
        end
        return true
    end
    function api.Destroy()
        if disposed then return end
        api.Set(false);disposed=true
    end
    return api
end
