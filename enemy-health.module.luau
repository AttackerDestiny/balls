return function(ctx)
    local state,create,corner=ctx.State,ctx.Create,ctx.Corner
    local now=ctx.Now or os.clock
    local rows,connections={},{}
    local healthRows={}
    local disposed=false
    local serial,nextUpdate,primary=0,0,nil
    local layoutDirty,snapshotDirty,nextRankCheck=true,true,0
    local api={Rows=rows,Count=0}
    -- Executors may reload with a fresh getgenv while the old GUI is still alive.
    -- Destroy only our previous HUD, never the game's own health displays.
    for _,child in ipairs(ctx.Parent:GetChildren()) do
        if child.Name=="EnemyHealth" and child:IsA("ScrollingFrame") then child:Destroy() end
    end
    local root=create("ScrollingFrame",{
        Name="EnemyHealth",Position=UDim2.new(.5,0,.7,0),AnchorPoint=Vector2.new(.5,.5),
        Size=UDim2.fromOffset(280,52),Visible=false,Active=true,BackgroundTransparency=1,
        BorderSizePixel=0,CanvasSize=UDim2.new(),ScrollBarThickness=0,
        ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,
    },ctx.Parent)
    api.Root=root
    create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},root)
    local function connect(signal,callback)
        local connection=signal:Connect(callback); connections[#connections+1]=connection; return connection
    end
    function api.Number(value)
        local digits=string.format("%.0f",math.floor(math.max(0,value)))
        return (string.reverse(string.gsub(string.reverse(digits),"(%d%d%d)","%1,")):gsub("^,",""))
    end
    local function viewport()
        local size=ctx.Viewport and ctx.Viewport() or ctx.Parent.AbsoluteSize
        return size.X>0 and size.Y>0 and size or Vector2.new(1280,720)
    end
    local function clampPosition()
        local size=viewport()
        local p=root.Position
        local x,y=p.X.Scale*size.X+p.X.Offset,p.Y.Scale*size.Y+p.Y.Offset
        local hw,hh=root.Size.X.Offset/2,root.Size.Y.Offset/2
        local cx=math.clamp(x,hw+4,math.max(hw+4,size.X-hw-4))
        local cy=math.clamp(y,hh+4,math.max(hh+4,size.Y-hh-4))
        if cx~=x or cy~=y then root.Position=UDim2.new(p.X.Scale,p.X.Offset+cx-x,p.Y.Scale,p.Y.Offset+cy-y) end
    end
    local function layout()
        local list={}
        for _,row in pairs(rows) do list[#list+1]=row end
        table.sort(list,function(a,b)
            local ar,br=a.Priority,b.Priority
            return ar~=br and ar<br or ar==br and a.Serial<b.Serial
        end)
        local compact=#list>1
        local width,height=compact and 244 or 280,compact and 42 or 52
        local total=math.max(height,#list*(height+5)-5)
        local maximum=math.max(52,math.min(360,math.floor(viewport().Y*.45)))
        root.Size=UDim2.fromOffset(width,math.min(total,maximum))
        root.CanvasSize=UDim2.fromOffset(0,total)
        root.ScrollBarThickness=total>maximum and 3 or 0
        root.Visible=#list>0
        api.Count=#list; state.HealthHUDCount=#list
        for index,row in ipairs(list) do
            row.Frame.LayoutOrder=index
            row.Frame.Size=UDim2.fromOffset(width,height)
            row.Name.Size=UDim2.fromOffset(width-20,15)
            row.Name.TextSize=compact and 11 or 12
            row.Track.Position=UDim2.fromOffset(10,compact and 22 or 25)
            row.Track.Size=UDim2.fromOffset(width-20,compact and 6 or 7)
            row.Numbers.Position=UDim2.fromOffset(10,compact and 30 or 35)
            row.Numbers.Size=UDim2.fromOffset(width-20,compact and 11 or 13)
            row.Numbers.TextSize=compact and 9 or 10
        end
        clampPosition()
        layoutDirty=false
    end
    local function remove(mob)
        local row=rows[mob]
        if not row then return end
        rows[mob]=nil
        if healthRows[row.Health]==row then healthRows[row.Health]=nil end
        layoutDirty,snapshotDirty=true,true
        for _,connection in ipairs(row.Connections or {}) do pcall(function()connection:Disconnect()end)end
        if row.Tween then pcall(function()row.Tween:Cancel()end)end
        if row.Frame then pcall(function()row.Frame:Destroy()end)end
    end
    function api.Touch(mob)
        if disposed or not root.Parent or not state.Running or not mob or not mob.Parent then return end
        local row=rows[mob]
        if row then row.LastAttack=now(); return end
        local data=ctx.GetData(mob)
        if not data or not data.Health or data.Health.Value<=0 then return end
        local sameHealth=healthRows[data.Health]
        if sameHealth then sameHealth.LastAttack=now();return end
        serial+=1
        row={Mob=mob,Health=data.Health,LastAttack=now(),Serial=serial,Connections={},ObservedMax=data.Health.Value,Priority=ctx.Priority and ctx.Priority(mob) or 3}
        rows[mob]=row
        healthRows[data.Health]=row
        layoutDirty,snapshotDirty=true,true
        row.Frame=create("Frame",{Name="Target_"..serial,Size=UDim2.fromOffset(280,52),BackgroundColor3=Color3.fromRGB(42,42,44),BackgroundTransparency=0,BorderSizePixel=0},root)
        if disposed or not state.Running or not root.Parent then remove(mob);return end
        row.Frame:SetAttribute("TargetName",mob.Name)
        corner(row.Frame,14)
        create("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=.92},row.Frame)
        row.Name=create("TextLabel",{Name="Name",Text=mob.Name,BackgroundTransparency=1,Position=UDim2.fromOffset(10,4),Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.fromRGB(255,255,255),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
        row.Track=create("Frame",{Name="Track",BackgroundColor3=Color3.fromRGB(24,24,26),BorderSizePixel=0},row.Frame)
        corner(row.Track,3)
        row.Fill=create("Frame",{Name="Fill",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(51,199,89),BorderSizePixel=0},row.Track)
        corner(row.Fill,3)
        row.Numbers=create("TextLabel",{Name="Values",BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(161,161,170),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
        local maximum=data.Entity:FindFirstChild("MaxHealth")
        local constrained=data.Health:IsA("IntConstrainedValue") or data.Health:IsA("DoubleConstrainedValue")
        local initial=true
        local function render()
            if disposed or not root.Parent or not state.Running or rows[mob]~=row then return end
            row.Dirty=false
            local hp=math.max(0,row.Health.Value)
            row.ObservedMax=math.max(row.ObservedMax,hp)
            local maxHP=math.max(1,constrained and row.Health.MaxValue or maximum and maximum.Value or row.ObservedMax)
            local fraction=math.clamp(hp/maxHP,0,1)
            local color=Color3.fromRGB(51,199,89)
            if row.Tween then row.Tween:Cancel() end
            if initial then row.Fill.Size=UDim2.fromScale(fraction,1); row.Fill.BackgroundColor3=color; initial=false
            else row.Tween=ctx.TweenService:Create(row.Fill,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(fraction,1),BackgroundColor3=color}); row.Tween:Play() end
            row.Numbers.Text=string.format("%s / %s HP · %.0f%%",api.Number(hp),api.Number(maxHP),fraction*100)
            row.Current,row.Maximum=hp,maxHP
            snapshotDirty=true
            row.DeadAt=hp<=0 and (row.DeadAt or now()) or nil
            if mob==primary or api.Count<=1 then state.ObservedHealth,state.ObservedMaxHealth=hp,maxHP end
            state.HealthUpdates=(state.HealthUpdates or 0)+1
        end
        row.Render=render
        local function dirty()row.Dirty=true end
        row.Connections[#row.Connections+1]=data.Health:GetPropertyChangedSignal("Value"):Connect(dirty)
        if constrained then row.Connections[#row.Connections+1]=data.Health:GetPropertyChangedSignal("MaxValue"):Connect(dirty)
        elseif maximum and maximum:IsA("ValueBase") then row.Connections[#row.Connections+1]=maximum.Changed:Connect(dirty) end
        render(); layout()
    end
    function api.Focus(mob) primary=mob end
    function api.Update(time)
        if disposed or not root.Parent then return end
        time=time or now()
        if time<nextUpdate then return end
        nextUpdate=time+.12
        local refreshRanks=time>=nextRankCheck
        if refreshRanks then nextRankCheck=time+.5 end
        for mob,row in pairs(rows) do
            local present=mob.Parent and row.Health.Parent and (not ctx.Present or ctx.Present(mob))
            if present and row.Dirty then row.Render()end
            if row.DeadAt then if time-row.DeadAt>.45 then remove(mob) end
            elseif not present or (time-row.LastAttack>1.4 and not (mob==primary and (state.SkillPreparing or state.SkillCastRunning))) then remove(mob) end
            if rows[mob] and refreshRanks and ctx.Priority then
                local priority=ctx.Priority(mob)
                if priority~=row.Priority then row.Priority=priority; layoutDirty=true end
            end
        end
        if snapshotDirty then
            local snapshot={}
            for mob,row in pairs(rows) do snapshot[#snapshot+1]={Name=mob.Name,Health=row.Current,MaxHealth=row.Maximum} end
            state.HealthHUDTargets=snapshot
            snapshotDirty=false
        end
        if layoutDirty then layout() end
    end
    local position=ctx.Position
    if type(position)=="table" and #position==4 then
        local valid=true
        for _,value in ipairs(position) do if type(value)~="number" or value~=value or math.abs(value)>100000 then valid=false end end
        if valid then root.Position=UDim2.new(position[1],position[2],position[3],position[4]); clampPosition() end
    end
    connect(ctx.Parent:GetPropertyChangedSignal("AbsoluteSize"),function() layoutDirty=true end)
    local dragInput,dragStart,dragPosition
    connect(root.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragInput,dragStart,dragPosition=input,input.Position,root.Position end
    end)
    connect(ctx.Input.InputChanged,function(input)
        if dragInput and (input==dragInput or input.UserInputType==Enum.UserInputType.MouseMovement) then
            local delta=input.Position-dragStart
            root.Position=UDim2.new(dragPosition.X.Scale,dragPosition.X.Offset+delta.X,dragPosition.Y.Scale,dragPosition.Y.Offset+delta.Y)
            clampPosition()
        end
    end)
    connect(ctx.Input.InputEnded,function(input) if input==dragInput or (dragInput and input.UserInputType==Enum.UserInputType.MouseButton1 and dragInput.UserInputType==Enum.UserInputType.MouseButton1) then dragInput=nil; if ctx.Save then ctx.Save() end end end)
    function api.Destroy(fromDestroying)
        if disposed then return end
        disposed=true
        for _,connection in ipairs(connections) do connection:Disconnect() end
        local mobs={}; for mob in pairs(rows) do mobs[#mobs+1]=mob end
        for _,mob in ipairs(mobs) do remove(mob) end
        api.Count=0; state.HealthHUDCount=0; state.HealthHUDTargets={}
        if not fromDestroying then root:Destroy() end
    end
    connect(root.Destroying,function()api.Destroy(true)end)
    return api
end
