-- Health subscriptions mark rows dirty; one projection pass coalesces hit bursts.
return function(ctx)
    local state=ctx.State
    local time=ctx.Now or os.clock
    local rows,byHealth={},{}
    local subscriptions={}
    local stopped=false
    local sequence,paintDue,rankDue=0,0,0
    local focus
    local dirtyLayout,dirtySnapshot=true,true
    local api={Rows=rows,Count=0}
    for _,object in ipairs(ctx.Parent:GetChildren())do
        if object.Name=="EnemyHealth"and object:IsA("ScrollingFrame")then object:Destroy()end
    end
    local function make(class,properties,parent)return ctx.Create(class,properties,parent)end
    local root=make("ScrollingFrame",{Name="EnemyHealth",Position=UDim2.new(.5,0,.7,0),AnchorPoint=Vector2.new(.5,.5),
        Size=UDim2.fromOffset(280,52),Visible=false,Active=true,BackgroundTransparency=1,BorderSizePixel=0,
        CanvasSize=UDim2.new(),ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},ctx.Parent)
    api.Root=root
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)},root)
    local function subscribe(signal,fn)
        local value=signal:Connect(fn);subscriptions[#subscriptions+1]=value;return value
    end
    function api.Number(value)
        local digits=string.format("%.0f",math.floor(math.max(0,value)))
        local parts={}
        while #digits>3 do table.insert(parts,1,digits:sub(-3));digits=digits:sub(1,-4)end
        table.insert(parts,1,digits)
        return table.concat(parts,",")
    end
    local function viewport()
        local size=ctx.Viewport and ctx.Viewport()or ctx.Parent.AbsoluteSize
        if size.X<=0 or size.Y<=0 then return Vector2.new(1280,720)end
        return size
    end
    local function keepOnScreen()
        local view=viewport()
        local p=root.Position
        local x=p.X.Scale*view.X+p.X.Offset
        local y=p.Y.Scale*view.Y+p.Y.Offset
        local halfX,halfY=root.Size.X.Offset/2,root.Size.Y.Offset/2
        local boundedX=math.clamp(x,halfX+4,math.max(halfX+4,view.X-halfX-4))
        local boundedY=math.clamp(y,halfY+4,math.max(halfY+4,view.Y-halfY-4))
        if boundedX~=x or boundedY~=y then root.Position=UDim2.new(p.X.Scale,p.X.Offset+boundedX-x,p.Y.Scale,p.Y.Offset+boundedY-y)end
    end
    local function remove(mob)
        local row=rows[mob]
        if not row then return end
        rows[mob]=nil
        if byHealth[row.Health]==row then byHealth[row.Health]=nil end
        for _,connection in ipairs(row.Connections or {})do pcall(function()connection:Disconnect()end)end
        if row.Tween then pcall(function()row.Tween:Cancel()end)end
        if row.Frame then pcall(function()row.Frame:Destroy()end)end
        dirtyLayout=true;dirtySnapshot=true
    end
    local function arrange()
        local list={};for _,row in pairs(rows)do if row.Frame then list[#list+1]=row end end
        table.sort(list,function(a,b)return a.Priority==b.Priority and a.Serial<b.Serial or a.Priority<b.Priority end)
        local compact=#list>1
        local width,height=compact and 244 or 280,compact and 42 or 52
        local fullHeight=math.max(height,#list*(height+5)-5)
        local maximum=math.max(52,math.min(360,math.floor(viewport().Y*.45)))
        root.Size=UDim2.fromOffset(width,math.min(fullHeight,maximum))
        root.CanvasSize=UDim2.fromOffset(0,fullHeight);root.ScrollBarThickness=fullHeight>maximum and 3 or 0
        root.Visible=#list>0;api.Count=#list;state.HealthHUDCount=#list
        for index,row in ipairs(list)do
            row.Frame.LayoutOrder=index;row.Frame.Size=UDim2.fromOffset(width,height)
            row.Name.Size=UDim2.fromOffset(width-20,15);row.Name.TextSize=compact and 11 or 12
            row.Track.Position=UDim2.fromOffset(10,compact and 22 or 25);row.Track.Size=UDim2.fromOffset(width-20,compact and 6 or 7)
            row.Numbers.Position=UDim2.fromOffset(10,compact and 30 or 35);row.Numbers.Size=UDim2.fromOffset(width-20,compact and 11 or 13)
            row.Numbers.TextSize=compact and 9 or 10
        end
        keepOnScreen();dirtyLayout=false
    end
    local function paint(row,initial)
        if stopped or not state.Running or not root.Parent or rows[row.Mob]~=row then return end
        local hp=math.max(0,row.Health.Value)
        row.ObservedMax=math.max(row.ObservedMax,hp)
        local maximum=math.max(1,row.Constrained and row.Health.MaxValue or row.MaximumValue and row.MaximumValue.Value or row.ObservedMax)
        local fraction=math.clamp(hp/maximum,0,1)
        if row.Tween then row.Tween:Cancel()end
        local fill={Size=UDim2.fromScale(fraction,1),BackgroundColor3=Color3.fromRGB(51,199,89)}
        if initial then row.Fill.Size=fill.Size;row.Fill.BackgroundColor3=fill.BackgroundColor3
        else row.Tween=ctx.TweenService:Create(row.Fill,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),fill);row.Tween:Play()end
        row.Numbers.Text=string.format("%s / %s HP · %.0f%%",api.Number(hp),api.Number(maximum),fraction*100)
        row.Current,row.Maximum=hp,maximum;row.Dirty=false
        row.DeadAt=hp<=0 and (row.DeadAt or time())or nil
        if row.Mob==focus or api.Count<=1 then state.ObservedHealth=hp;state.ObservedMaxHealth=maximum end
        state.HealthUpdates=(state.HealthUpdates or 0)+1;dirtySnapshot=true
    end
    local function visuals(row)
        row.Frame=make("Frame",{Name="Target_"..row.Serial,Size=UDim2.fromOffset(280,52),BackgroundColor3=Color3.fromRGB(42,42,44),BackgroundTransparency=0,BorderSizePixel=0},root)
        row.Frame:SetAttribute("TargetName",row.Mob.Name);ctx.Corner(row.Frame,14)
        make("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1,Transparency=.92},row.Frame)
        row.Name=make("TextLabel",{Name="Name",Text=row.Mob.Name,BackgroundTransparency=1,Position=UDim2.fromOffset(10,4),Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.fromRGB(255,255,255),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
        row.Track=make("Frame",{Name="Track",BackgroundColor3=Color3.fromRGB(24,24,26),BorderSizePixel=0},row.Frame);ctx.Corner(row.Track,3)
        row.Fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(51,199,89),BorderSizePixel=0},row.Track);ctx.Corner(row.Fill,3)
        row.Numbers=make("TextLabel",{Name="Values",BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(161,161,170),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row.Frame)
    end
    function api.Touch(mob)
        if stopped or not root.Parent or not state.Running or not mob or not mob.Parent then return end
        local existing=rows[mob]
        if existing then existing.LastAttack=time();return end
        local data=ctx.GetData(mob)
        if not data or not data.Health or data.Health.Value<=0 then return end
        if byHealth[data.Health]then byHealth[data.Health].LastAttack=time();return end
        sequence+=1
        local row={Mob=mob,Health=data.Health,Connections={},Serial=sequence,LastAttack=time(),ObservedMax=data.Health.Value,
            Priority=ctx.Priority and ctx.Priority(mob)or 3,MaximumValue=data.Entity:FindFirstChild("MaxHealth")}
        row.Constrained=row.Health:IsA("IntConstrainedValue")or row.Health:IsA("DoubleConstrainedValue")
        rows[mob]=row;byHealth[row.Health]=row
        visuals(row)
        if stopped or not root.Parent or not state.Running then remove(mob);return end
        local function changed()row.Dirty=true end
        row.Connections[#row.Connections+1]=row.Health:GetPropertyChangedSignal("Value"):Connect(changed)
        if row.Constrained then row.Connections[#row.Connections+1]=row.Health:GetPropertyChangedSignal("MaxValue"):Connect(changed)
        elseif row.MaximumValue and row.MaximumValue:IsA("ValueBase")then row.Connections[#row.Connections+1]=row.MaximumValue.Changed:Connect(changed)end
        row.Render=function()paint(row,false)end
        paint(row,true);dirtyLayout=true;arrange()
    end
    function api.Focus(mob)focus=mob end
    function api.Update(stamp)
        if stopped or not root.Parent then return end
        stamp=stamp or time();if stamp<paintDue then return end;paintDue=stamp+.12
        local ranking=stamp>=rankDue;if ranking then rankDue=stamp+.5 end
        for mob,row in pairs(rows)do
            local present=mob.Parent and row.Health.Parent and (not ctx.Present or ctx.Present(mob))
            if present and row.Dirty then paint(row,false)end
            local expired=row.DeadAt and stamp-row.DeadAt>.45
            local idle=stamp-row.LastAttack>1.4 and not(mob==focus and (state.SkillPreparing or state.SkillCastRunning))
            if expired or not row.DeadAt and (not present or idle)then remove(mob)
            elseif ranking and ctx.Priority then local rank=ctx.Priority(mob);if rank~=row.Priority then row.Priority=rank;dirtyLayout=true end end
        end
        if dirtySnapshot then
            local snapshot={};for mob,row in pairs(rows)do snapshot[#snapshot+1]={Name=mob.Name,Health=row.Current,MaxHealth=row.Maximum}end
            state.HealthHUDTargets=snapshot;dirtySnapshot=false
        end
        if dirtyLayout then arrange()end
    end
    local saved=ctx.Position
    if type(saved)=="table"and #saved==4 then
        local valid=true;for _,n in ipairs(saved)do if type(n)~="number"or n~=n or math.abs(n)>100000 then valid=false end end
        if valid then root.Position=UDim2.new(saved[1],saved[2],saved[3],saved[4]);keepOnScreen()end
    end
    local dragging
    subscribe(ctx.Parent:GetPropertyChangedSignal("AbsoluteSize"),function()dirtyLayout=true end)
    subscribe(root.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging={Input=input,Origin=input.Position,Position=root.Position}end
    end)
    subscribe(ctx.Input.InputChanged,function(input)
        if dragging and (input==dragging.Input or input.UserInputType==Enum.UserInputType.MouseMovement)then
            local delta=input.Position-dragging.Origin;local p=dragging.Position
            root.Position=UDim2.new(p.X.Scale,p.X.Offset+delta.X,p.Y.Scale,p.Y.Offset+delta.Y);keepOnScreen()
        end
    end)
    subscribe(ctx.Input.InputEnded,function(input)
        if dragging and (input==dragging.Input or input.UserInputType==Enum.UserInputType.MouseButton1 and dragging.Input.UserInputType==Enum.UserInputType.MouseButton1)then dragging=nil;if ctx.Save then ctx.Save()end end
    end)
    function api.Destroy(fromRoot)
        if stopped then return end
        stopped=true
        for _,connection in ipairs(subscriptions)do connection:Disconnect()end;table.clear(subscriptions)
        for mob in pairs(rows)do remove(mob)end
        table.clear(byHealth);api.Count=0;state.HealthHUDCount=0;state.HealthHUDTargets={}
        if not fromRoot then root:Destroy()end
    end
    subscribe(root.Destroying,function()api.Destroy(true)end)
    return api
end
