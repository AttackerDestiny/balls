-- WindUI is bundled at a fixed release; no compatibility window exists.
-- Executor adapter for the sole modern presentation.
do
    local librarySource=(function()
-- BEGIN BUNDLED WINDUI SOURCE
-- END BUNDLED WINDUI SOURCE
    end)()
    local make=(function()
-- BEGIN BUNDLED WINDUI
-- END BUNDLED WINDUI
    end)()
    local makeMemory=(function()
-- BEGIN BUNDLED UI MEMORY
-- END BUNDLED UI MEMORY
    end)()
    local parent=gui.Parent
    local retryVisibility=state.SetUIVisible
    local before={};for _,object in ipairs(parent:GetChildren())do before[object]=true end
    local library,uiMemory
    local ownedNames={WindUI=true,["WindUI/Notifications"]=true,["WindUI/Dropdowns"]=true,["WindUI/Tooltips"]=true}
    local rootNames={"ScreenGui","NotificationGui","DropdownGui","TooltipGui"}
    local function roots(fn)
        if not library then return end
        for _,name in ipairs(rootNames)do if library[name]then pcall(fn,library[name])end end
    end
    local function viewport()
        local camera=workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(1280,720)
    end
    local function validPosition(value)
        if type(value)~="table"or #value~=4 then return false end
        for _,coordinate in ipairs(value)do if type(coordinate)~="number"or coordinate~=coordinate or math.abs(coordinate)>100000 then return false end end
        return true
    end
    local function positionWindow(frame,size)
        local saved=state.WindUIPosition
        if validPosition(saved)then
            local x=saved[1]*size.X+saved[2]
            local y=saved[3]*size.Y+saved[4]
            frame.Position=UDim2.fromOffset(math.clamp(x,math.min(150,size.X/2),math.max(size.X-150,size.X/2)),
                math.clamp(y,math.min(100,size.Y/2),math.max(size.Y-100,size.Y/2)))
        end
        bind(frame:GetPropertyChangedSignal("Position"),function()
            if not state.Running then return end
            local p=frame.Position
            state.WindUIPosition={p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset};requestSave()
        end)
    end
    local function installFeather()
        local icon=library.Creator.Icon("feather")
        if not icon then return end
        create("ImageLabel",{Name="FeatherIcon",BackgroundTransparency=1,Size=UDim2.fromOffset(26,26),Position=UDim2.fromScale(.5,.5),
            AnchorPoint=Vector2.new(.5,.5),Image=icon[1],ImageRectSize=icon[2].ImageRectSize,ImageRectOffset=icon[2].ImageRectPosition,
            ImageColor3=Color3.fromRGB(239,239,241)},showUI)
        showUI.Text=""
    end
    local function mark(button,on)
        local indicator=button:FindFirstChild("AutoHideIndicator")
        if not indicator then
            indicator=create("Frame",{Name="AutoHideIndicator",Size=UDim2.fromOffset(6,6),Position=UDim2.new(1,-8,1,-8),BorderSizePixel=0},button)
            corner(indicator,3)
        end
        indicator.BackgroundColor3=on and Color3.fromRGB(51,199,89)or Color3.fromRGB(110,110,115)
    end
    local function clearButton(control,callback)
        local host=control.InputFrame.UIElements.Main
        local title=host:FindFirstChild("TitleFrame",true)
        if title then title.Size=UDim2.new(1,-188,title.Size.Y.Scale,title.Size.Y.Offset)end
        local button=library.Creator.New("TextButton",{Name="ClearWhitelist",Text="X",TextSize=16,Font=Enum.Font.GothamBold,
            BackgroundTransparency=1,AutoButtonColor=true,Size=UDim2.fromOffset(28,36),Position=UDim2.new(1,-158,.5,0),
            AnchorPoint=Vector2.new(1,.5),ThemeTag={TextColor3="Text"},ZIndex=host.ZIndex+2},nil)
        button.Parent=host;bind(button.Activated,callback)
        return button
    end
    local function visible(show)
        if state.PerformanceBoost then state.PerformanceBoost.SetUIVisible(show)end
        showUI.Visible=state.Running==true
        roots(function(root)root.Enabled=show end)
    end
    local function loadLibrary()
        local chunk=assert(loadstring(librarySource,"Feather WindUI"))
        local nativeMake=makefolder
        local environment=setmetatable({gethui=function()return parent end,makefolder=function(path)
            if type(isfolder)=="function"and isfolder(path)then return end
            assert(type(nativeMake)=="function","Executor filesystem is unavailable")
            nativeMake(path)
        end},{__index=getfenv()})
        setfenv(chunk,environment)
        return chunk()
    end
    local ok,result=pcall(function()
        state.WindUIStartedAt=os.clock();library=loadLibrary();uiMemory=makeMemory(library.Creator)
        roots(function(root)root.DisplayOrder=gui.DisplayOrder+1 end)
        pcall(installFeather)
        local size=viewport()
        state.UI.ActiveTab=preference("ActiveTab",state.UI.ActiveTab or "Main")
        state.WindUIPosition=preference("WindUIPosition",nil)
        function state.SetAutoHideUI(on)state.AutoHideUI=on==true;state.SaveNow()end
        local controller=make({State=state,WindUI=library,Memory=uiMemory,PlaceId=game.PlaceId,Defer=task.defer,
            Size=UDim2.fromOffset(math.min(640,math.max(320,size.X-24)),math.min(520,math.max(280,size.Y-70))),
            MinSize=Vector2.new(300,240),SideBarWidth=size.X<500 and 110 or 155,
            Visibility=visible,MarkAutoHide=mark,AddWhitelistClear=clearButton,
            DestroyRoots=function()roots(function(root)root:Destroy()end)end,
            FriendPresent=function(name)
                if name==""then return false end
                local wanted=name:lower()
                for _,person in ipairs(Players:GetPlayers())do if person~=player and person.Name:lower()==wanted then return true end end
                return false
            end})
        state.WindUI=controller;state.WindUIMainReadySeconds=os.clock()-state.WindUIStartedAt
        state.UI.WindWindow=controller.Window;state.UI.WindControls=controller.Controls;state.SetUIVisible=controller.SetVisible
        local frame=controller.Window.UIElements and controller.Window.UIElements.Main
        if frame then positionWindow(frame,size)end
        controller.SetVisible(not state.AutoHideUI and not state.UIHidden)
        task.spawn(function()
            while state.Running and state.WindUI==controller do
                local painted,reason=pcall(controller.Update,os.clock())
                if not painted then state.WindUIError=tostring(reason)end
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
