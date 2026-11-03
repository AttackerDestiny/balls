return function(source)
    local s={Running=true,MultiSpot=false,MultiSpotStatus="Travelling"}
    local time,callback,visible,text,dead=0,nil,nil,nil,false
    local connected=true
    local api=assert(loadstring(source))()({State=s,Now=function()return time end,
        Pulse={Connect=function(_,fn)callback=fn;return {Disconnect=function()connected=false end}end},
        Visible=function(value)visible=value end,Text=function(value)text=value end,Destroy=function()dead=true end})
    assert(not visible and not text)
    s.MultiSpot=true;time=.2;callback();assert(visible and text=="Travelling")
    s.UIHidden=true;s.MultiSpotStatus="Clearing mobs";time=.4;callback();assert(visible and text=="Clearing mobs")
    s.MultiSpot=false;time=.61;callback();assert(not visible)
    s.MultiSpot=true;s.Running=false;time=1;callback();assert(not visible)
    api.Destroy();api.Destroy();assert(dead and not connected)
    s.Running=true;time=2;callback();assert(not visible)
    print("PASS Multi Spot HUD: enabled-only status, independent UI visibility, OFF, stop and cleanup")
end
