-- WindUI is bundled at a fixed release; queued rejoins need no library download.
do
    local librarySource=(function()
-- BEGIN BUNDLED WINDUI SOURCE
-- END BUNDLED WINDUI SOURCE
    end)()
    local make=(function()
-- BEGIN BUNDLED WINDUI
-- END BUNDLED WINDUI
    end)()
    local parent=gui.Parent
    local retryVisibility=state.SetUIVisible
    local before={};for _,child in ipairs(parent:GetChildren())do before[child]=true end
    local library,uiMemory
    local ownedNames={WindUI=true,["WindUI/Notifications"]=true,["WindUI/Dropdowns"]=true,["WindUI/Tooltips"]=true}
    local function roots(fn)
        if library then
            for _,key in ipairs({"ScreenGui","NotificationGui","DropdownGui","TooltipGui"})do
                local root=library[key]
                if root then pcall(fn,root)end
            end
        end
    end
    local ok,result=pcall(function()
        state.WindUIStartedAt=os.clock()
        local run=assert(loadstring(librarySource,"WindUI 1.6.66"))
        local base=getfenv()
        local nativeMake=makefolder
        setfenv(run,setmetatable({gethui=function()return parent end,makefolder=function(path)
            if type(isfolder)=="function"and isfolder(path)then return end
            assert(type(nativeMake)=="function","Executor filesystem is unavailable")
            return nativeMake(path)
        end},{__index=base}))
        library=run()
        pcall(function()
            local icon=library.Creator.Icon("feather")
            if icon then
                create("ImageLabel",{Name="FeatherIcon",BackgroundTransparency=1,Size=UDim2.fromOffset(26,26),
                    Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),Image=icon[1],
                    ImageRectSize=icon[2].ImageRectSize,ImageRectOffset=icon[2].ImageRectPosition,
                    ImageColor3=Color3.fromRGB(239,239,241)},showUI)
                showUI.Text=""
            end
        end)
        roots(function(root)root.DisplayOrder=gui.DisplayOrder+1 end)
        local camera=workspace.CurrentCamera
        local size=camera and camera.ViewportSize or Vector2.new(1280,720)
        state.UI.ActiveTab=preference("ActiveTab",state.UI.ActiveTab or "Main")
        state.WindUIPosition=preference("WindUIPosition",nil)
        local makeMemory=(function()
-- BEGIN BUNDLED UI MEMORY
-- END BUNDLED UI MEMORY
        end)()
        function state.SetAutoHideUI(on)state.AutoHideUI=on==true;state.SaveNow()end
        uiMemory=makeMemory(library.Creator)
        local controller=make({Memory=uiMemory,State=state,WindUI=library,PlaceId=game.PlaceId,Defer=task.defer,
            DestroyRoots=function()roots(function(root)root:Destroy()end)end,
            FriendPresent=function(name)
                if name==""then return false end
                for _,person in ipairs(Players:GetPlayers())do
                    if person~=player and person.Name:lower()==name:lower()then return true end
                end
                return false
            end,
            Size=UDim2.fromOffset(math.min(640,math.max(320,size.X-24)),math.min(520,math.max(280,size.Y-70))),
            MinSize=Vector2.new(300,240),SideBarWidth=size.X<500 and 110 or 155,
            AddWhitelistClear=function(control,clear)
                local main=control.InputFrame.UIElements.Main
                local title=main:FindFirstChild("TitleFrame",true)
                if title then title.Size=UDim2.new(1,-188,title.Size.Y.Scale,title.Size.Y.Offset)end
                local button=library.Creator.New("TextButton",{
                    Name="ClearWhitelist",Text="X",TextSize=16,Font=Enum.Font.GothamBold,
                    BackgroundTransparency=1,AutoButtonColor=true,Size=UDim2.fromOffset(28,36),
                    Position=UDim2.new(1,-158,.5,0),AnchorPoint=Vector2.new(1,.5),
                    ThemeTag={TextColor3="Text"},ZIndex=main.ZIndex+2},nil)
                button.Parent=main
                bind(button.Activated,clear)
                return button
            end,
            MarkAutoHide=function(button,on)
                local dot=button:FindFirstChild("AutoHideIndicator")
                if not dot then
                    dot=create("Frame",{Name="AutoHideIndicator",Size=UDim2.fromOffset(6,6),Position=UDim2.new(1,-8,1,-8),BorderSizePixel=0},button)
                    corner(dot,3)
                end
                dot.BackgroundColor3=on and Color3.fromRGB(51,199,89)or Color3.fromRGB(110,110,115)
            end,
            Visibility=function(visible)
                if state.PerformanceBoost then state.PerformanceBoost.SetUIVisible(visible)end
                if state.Running then showUI.Visible=true else showUI.Visible=false end
                roots(function(root)root.Enabled=visible end)
            end})
        state.WindUI=controller
        state.WindUIMainReadySeconds=os.clock()-state.WindUIStartedAt
        state.UI.WindWindow=controller.Window;state.UI.WindControls=controller.Controls
        state.SetUIVisible=controller.SetVisible
        local frame=controller.Window.UIElements and controller.Window.UIElements.Main
        local saved=state.WindUIPosition
        if frame then
            if type(saved)=="table"and #saved==4 then
                local valid=true
                for _,value in ipairs(saved)do if type(value)~="number"or value~=value or math.abs(value)>100000 then valid=false end end
                if valid then
                    local x=saved[1]*size.X+saved[2]
                    local y=saved[3]*size.Y+saved[4]
                    frame.Position=UDim2.fromOffset(math.clamp(x,math.min(150,size.X/2),math.max(size.X-150,size.X/2)),
                        math.clamp(y,math.min(100,size.Y/2),math.max(size.Y-100,size.Y/2)))
                end
            end
            bind(frame:GetPropertyChangedSignal("Position"),function()
                if not state.Running then return end
                local p=frame.Position
                state.WindUIPosition={p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset};requestSave()
            end)
        end
        controller.SetVisible(not state.AutoHideUI and not state.UIHidden)
        task.spawn(function()
            while state.Running do
                local updated,reason=pcall(controller.Update,os.clock())
                if not updated then state.WindUIError=tostring(reason)end
                task.wait(.25)
            end
        end)
    end)
    -- BEGIN MODERN UI FAILURE
    if not ok then
        local current=state.Running and env.SB2LoadToken==loadToken and runtimeOwner.Alive()
        if state.WindUI then pcall(state.WindUI.Destroy);state.WindUI=nil end
        if library and library.Window then pcall(function()library.Window:Destroy()end)end
        if uiMemory then pcall(uiMemory.Destroy)
        elseif library and library.Creator and library.Creator.DisconnectAll then pcall(library.Creator.DisconnectAll)end
        roots(function(root)root:Destroy()end)
        if current then
            state.WindUIError=tostring(result);state.SetUIVisible=retryVisibility
            for _,child in ipairs(parent:GetChildren())do
                if not before[child]and child:IsA("ScreenGui")and ownedNames[child.Name]then child:Destroy()end
            end
            showUI.Visible=true;state.UIHidden=true
            warn("[SB2 WindUI] Modern UI unavailable; use the feather button to reload: "..state.WindUIError)
        end
    end
    -- END MODERN UI FAILURE
end

