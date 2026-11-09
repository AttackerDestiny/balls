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
    assert(point(button,vec(0,58),function(at)return at.Y==491.5 end).Y==491.5,
        "Android layouts whose raw center hits Block must not receive an extra inset")
    assert(point(button,vec(0,58),function(at)return at.Y==549.5 end).Y==549.5,
        "An inset candidate is only used when its target hit is verified")
    assert(not point(button,vec(0,58),function()return false end),"Never guess coordinates if neither point hits the intended button")
    print("PASS Block input selects raw or inset coordinates only after verifying the intended target")

    local events,waits={},0
    button.Visible=true;button.Active=true;button.Activated={}
    local expectedY=549.5
    local obscured,queryFails=false,false
    local other={IsDescendantOf=function()return false end,IsA=function(_,class)return class=="GuiButton"end}
    local core={GetGuiObjectsAtPosition=function(_,x,y)
        if queryFails then error("Hit testing is unavailable")end
        return not obscured and x==960 and y==expectedY and {button}or {other}
    end}
    local env={blockPoint=point,canTouch=true,canMouse=true,
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
    local chunk=assert(loadstring(clickSource.."\nreturn click"))
    setfenv(chunk,setmetatable(env,{__index=getfenv()}))
    local click=chunk()
    click(button,1);click(button,2);click(button,3)
    assert(table.concat(events,",")=="touch0,touch2,down,up,activate" and waits==2)
    table.clear(events)
    env.virtualInput.SendTouchEvent=function()error("Touch input denied")end
    click(button,1)
    assert(table.concat(events,",")=="down,up","An input exception can fall back in the same attempt")
    table.clear(events);env.canTouch=false;env.canMouse=false
    click(button,1)
    assert(table.concat(events,",")=="activate","Signal-only executors can activate the verified button")
    table.clear(events);expectedY=491.5;env.canMouse=true
    click(button,2)
    assert(table.concat(events,",")=="down,up","Android raw coordinates cannot click the neighboring report button")
    table.clear(events);obscured=true
    assert(not pcall(click,button,1)and #events==0,"Another active GUI over the dialog prevents mouse, touch and signal activation")
    obscured=false;queryFails=true
    assert(not pcall(click,button,1)and #events==0,"A failed hit test must stop input rather than fall back to guessed coordinates")
    print("PASS Android block input uses touch, falls back to mouse, then the verified button signal")
end
