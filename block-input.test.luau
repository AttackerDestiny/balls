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
    print("PASS Block confirmation uses the live-verified CoreGui input coordinate")

    local events,waits={},0
    button.Visible=true;button.Active=true;button.Activated={}
    local env={blockPoint=point,canTouch=true,canMouse=true,
        GuiService={GetGuiInset=function()return vec(0,58)end},
        Enum={UserInputState={Begin={Value=0},End={Value=2}}},
        task={wait=function()waits+=1 end},
        virtualInput={
            SendTouchEvent=function(_,id,phase,x,y)
                assert(id>=1 and x==960 and y==549.5)
                events[#events+1]="touch"..phase
            end,
            SendMouseButtonEvent=function(_,x,y,_,pressed)
                assert(x==960 and y==549.5)
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
    print("PASS Android block input uses touch, falls back to mouse, then the verified button signal")
end
