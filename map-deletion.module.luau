-- Explicit static-world cleanup owns one cancellable streamed-work session.
return function(ctx)
    local api={Removed=0,Pending=0,MaxQueued=0}
    local session,closed=nil,false
    local excluded={Mobs=true,Characters=true,CharacterItems=true,HitEffects=true,WaveDefenseStuff=true,MobSpawnEffects=true,CurrentCamera=true}
    local names={"teleport","portal","spawn","checkpoint","trigger","hazard","npc","shop","quest","pad","door"}
    local function protected(node)
        if excluded[node.Name]or node:IsA("Camera")or node:IsA("Tool")then return true end
        local normalized=node.Name:lower()
        for _,word in ipairs(names)do if normalized:find(word,1,true)then return true end end
        if node:IsA("Model")and (ctx.Players:GetPlayerFromCharacter(node)or node:FindFirstChildOfClass("Humanoid")
            or node:FindFirstChildOfClass("AnimationController")or node:FindFirstChild("Entity")
            or node:FindFirstChild("HumanoidRootPart")or node:FindFirstChild("RootPart"))then return true end
        for _,kind in ipairs({"ProximityPrompt","ClickDetector","TouchTransmitter"})do if node:FindFirstChildOfClass(kind)then return true end end
        return false
    end
    function api.Removable(part)
        if not part.Parent or not part:IsA("BasePart")or part:IsA("Terrain")or not part.Anchored or ctx.Protected(part)then return false end
        local node=part
        repeat
            if node==ctx.Root then return true end
            if protected(node)then return false end
            node=node.Parent
        until not node
        return false
    end
    local function active(owner)return not closed and session==owner and ctx.State.Running end
    local function census(owner)
        owner.Scan=ctx.Root:QueryDescendants("BasePart");owner.Cursor=1;owner.Length=#owner.Scan;owner.Rescan=false
    end
    local function pending(owner)return math.max(0,owner.Length-owner.Cursor+1)+math.max(0,owner.Tail-owner.Head+1)end
    local function start(owner)
        if owner.Worker then return end
        owner.Worker=true
        ctx.Defer(function()
            if not active(owner)then return end
            if owner.Rescan then census(owner)end
            if ctx.ClearTerrain then
                local ok,reason=pcall(ctx.ClearTerrain);api.TerrainCleared=ok
                if not ok then api.LastError=tostring(reason)end
            end
            while active(owner)do
                if ctx.State.StopEverything then ctx.Wait(.25)
                else
                    local due=ctx.Now()+.0015
                    local processed=0
                    while processed<128 and ctx.Now()<due and active(owner)do
                        local part
                        if owner.Cursor<=owner.Length then
                            part=owner.Scan[owner.Cursor];owner.Scan[owner.Cursor]=nil;owner.Cursor+=1
                        elseif owner.Head<=owner.Tail then
                            part=owner.Queue[owner.Head];owner.Queue[owner.Head]=nil;owner.Head+=1;owner.Seen[part]=nil
                        else break end
                        local checked,allowed=pcall(api.Removable,part)
                        if checked and allowed and pcall(function()part:Destroy()end)then api.Removed+=1 end
                        processed+=1
                    end
                    api.Pending=pending(owner)
                    if api.Pending==0 then
                        if owner.Rescan then census(owner)else break end
                    end
                    ctx.Wait()
                end
            end
            if active(owner)then
                owner.Worker=false;owner.Queue={};owner.Seen={};owner.Head=1;owner.Tail=0;owner.Scan={};owner.Cursor=1;owner.Length=0;api.Pending=0
            end
        end)
    end
    function api.Set(enabled)
        if closed then return false end
        enabled=enabled==true
        if enabled==(session~=nil)then return true end
        local previous=session;session=nil
        if previous then
            previous.Added:Disconnect();table.clear(previous.Queue);table.clear(previous.Scan);table.clear(previous.Seen)
        end
        api.Pending=0
        if enabled then
            local owner={Queue={},Seen=setmetatable({}, {__mode="k"}),Head=1,Tail=0,Scan={},Cursor=1,Length=0,Rescan=true,Worker=false}
            session=owner
            owner.Added=ctx.Root.DescendantAdded:Connect(function(part)
                if not active(owner)or not part:IsA("BasePart")or owner.Seen[part]then return end
                if owner.Tail-owner.Head+1>=8192 then owner.Rescan=true;return end
                owner.Tail+=1;owner.Queue[owner.Tail]=part;owner.Seen[part]=true
                api.MaxQueued=math.max(api.MaxQueued,owner.Tail-owner.Head+1)
                start(owner)
            end)
            start(owner)
        end
        return true
    end
    function api.Destroy()if closed then return end;api.Set(false);closed=true end
    return api
end
