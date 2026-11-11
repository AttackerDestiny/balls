return function(source,clickSource)
    local point=assert(loadstring(source))()
    local mt={}
    local function vec(x,y)return setmetatable({X=x,Y=y},mt)end
    mt.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y)end
    mt.__div=function(a,b)return vec(a.X/b,a.Y/b)end
    local root={IgnoreGuiInset=true}
    local button={AbsolutePosition=vec(784,475.5),AbsoluteSize=vec(352,32),
        FindFirstAncestorWhichIsA=function()return root end}
    local p=point(button,vec(0,58))
    assert(p.X==960 and p.Y==549.5,"Live FoundationOverlay input includes the CoreGui inset")
    root.IgnoreGuiInset=false;p=point(button,vec(0,58));assert(p.X==960 and p.Y==549.5)
    p=point(button,vec(0,0));assert(p.X==960 and p.Y==491.5)
    assert(point(button,vec(0,58),function(at)return at.Y==491.5 end).Y==549.5,
        "Verify the CoreGui center, then convert to the input coordinates that include the inset")
    assert(not point(button,vec(0,58),function(at)return at.Y==549.5 end),
        "The neighboring button at a shifted hit-test position cannot authorize input")
    assert(not point(button,vec(0,58),function()return false end),"Never guess coordinates if neither point hits the intended button")
    print("PASS Block input separates CoreGui hit-test and VirtualInput coordinate spaces")

    local events,waits={},0
    button.Visible=true;button.Active=true;button.Activated={}
    local expectedY=549.5
    local obscured,queryFails=false,false
    local other={IsDescendantOf=function()return false end,IsA=function(_,class)return class=="GuiButton"end}
    local core={GetGuiObjectsAtPosition=function(_,x,y)
        if queryFails then error("Hit testing is unavailable")end
        return not obscured and x==960 and y==491.5 and {button}or {other}
    end}
    local env={state={},blockPoint=point,canTouch=true,canMouse=true,
        Vector2={new=vec},
        game={GetService=function(_,name)assert(name=="CoreGui");return core end},
        GuiService={GetGuiInset=function()return vec(0,58)end},
        Enum={UserInputState={Begin={Value=0},End={Value=2}}},
        task={wait=function()waits+=1 end},
        virtualInput={
            SendTouchEvent=function(_,id,phase,x,y)
                assert(id>=1 and x==960 and y==expectedY)
                events[#events+1]="touch"..phase
            end,
            SendMouseButtonEvent=function(_,x,y,_,pressed)
                assert(x==960 and y==expectedY)
                events[#events+1]=pressed and "down" or "up"
            end,
        },
        fireActivation=function(signal,_,count)
            assert(signal==button.Activated and count==1)
            events[#events+1]="activate"
        end,
    }
    env.supportsInput=function(name)return type(env.virtualInput[name])=="function"end
    local chunk=assert(loadstring(clickSource.."\nreturn click"))
    setfenv(chunk,setmetatable(env,{__index=getfenv()}))
    local click=chunk()
    click(button,1);click(button,2);click(button,3)
    assert(table.concat(events,",")=="down,up,touch0,touch2,activate" and waits==2)
    table.clear(events)
    local mouseOffset,cursor=24,vec(0,0)
    env.virtualInput.SendMouseMoveEvent=function(_,x,y)cursor=vec(x,y-mouseOffset)end
    env.inputService={GetMouseLocation=function()return cursor end}
    expectedY=573.5
    click(button,1)
    assert(table.concat(events,",")=="down,up" and env.state.LastBlockInput.OffsetY==24,
        "Android's extra 24-pixel window offset must be measured before native mouse confirmation")
    local blockDiagnostic=env.state.LastBlockInput
    click(button,nil,"Cancel")
    assert(env.state.LastBlockInput==blockDiagnostic and env.state.LastBlockCleanupInput.Method=="Mouse",
        "Cleanup input cannot replace the failed Block attempt's diagnostics")
    table.clear(events);mouseOffset=0;expectedY=549.5
    click(button,1)
    assert(table.concat(events,",")=="down,up" and env.state.LastBlockInput.OffsetY==0,
        "A client without a window offset must retain its original input coordinates")
    table.clear(events)
    local activation=env.fireActivation;env.fireActivation=nil;mouseOffset=200;env.canTouch=false
    assert(not pcall(click,button,1)and #events==0,
        "An implausible calibration must never press a native button")
    mouseOffset=24;local moves=0
    env.virtualInput.SendMouseMoveEvent=function(_,x,y)moves+=1;cursor=vec(x,y-(moves%2==0 and 48 or 24))end
    assert(not pcall(click,button,1)and #events==0,
        "A moving or unsupported pointer must settle before any press")
    env.fireActivation=activation;env.virtualInput.SendMouseMoveEvent=nil;env.canTouch=true
    expectedY=549.5
    table.clear(events)
    env.virtualInput.SendTouchEvent=function()error("Touch input denied")end
    click(button,2)
    assert(table.concat(events,",")=="down,up","An input exception can fall back in the same attempt")
    table.clear(events)
    env.virtualInput.SendTouchEvent=function(_,_,phase)events[#events+1]="touch"..phase end
    env.virtualInput.SendMouseMoveEvent=function()error("Pointer movement denied")end
    click(button,1)
    assert(table.concat(events,",")=="touch0,touch2","A mouse-only capability failure must not disable working touch input")
    env.virtualInput.SendMouseMoveEvent=nil
    table.clear(events);env.canTouch=false;env.canMouse=false
    click(button,1)
    assert(table.concat(events,",")=="activate","Signal-only executors can activate the verified button")
    table.clear(events);expectedY=491.5;env.canMouse=true;env.GuiService.GetGuiInset=function()return vec(0,0)end
    click(button,1)
    assert(table.concat(events,",")=="down,up","A zero-inset client uses unshifted input coordinates")
    table.clear(events);obscured=true
    assert(not pcall(click,button,1)and #events==0,"Another active GUI over the dialog prevents mouse, touch and signal activation")
    obscured=false;queryFails=true
    assert(not pcall(click,button,1)and #events==0,"A failed hit test must stop input rather than fall back to guessed coordinates")
    queryFails=false;env.canTouch=true;env.canMouse=true
    env.virtualInput.SendTouchEvent=function()error("Touch unavailable")end
    env.virtualInput.SendMouseButtonEvent=function()error("Mouse unavailable")end
    env.fireActivation=function()error("Signal unavailable")end
    local ok,reason=pcall(click,button,1)
    assert(not ok and tostring(reason):find("Automatic block input failed",1,true)
        and #env.state.LastBlockInput.Errors==3 and not env.state.LastBlockInput.Dispatched,
        "All failed methods must report their errors instead of being treated as successful input")
    local released=0;env.canTouch=false;env.fireActivation=nil
    env.virtualInput.SendMouseButtonEvent=function(_,_,_,_,pressed)
        if pressed then error("Partial press failed")else released+=1 end
    end
    assert(not pcall(click,button,2)and released==1,"An errored partial press must still release the input")
    print("PASS Android block input calibrates mouse coordinates and preserves independent touch/signal fallbacks")
end
