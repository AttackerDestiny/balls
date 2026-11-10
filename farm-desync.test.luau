return function(source)
    local make=assert(loadstring(source))()
    local allowed=true
    local subject={Parent=true}
    local root={Parent=true,Position={X=0,Y=20,Z=0}}
    local camera={Parent=true,CameraSubject=subject}
    local surface,raycasts,created,removed=0,0,0,0
    local render
    local api=make({Allowed=function()return allowed end,Character=function()return root,subject end,
        Camera=function()return camera end,CameraHeight=function()return 3 end,
        Surface=function()raycasts+=1;return surface end,
        Render={Connect=function(_,callback)render=callback;return {Disconnect=function()render=nil end}end},
        CreateProxy=function()
            created+=1
            return {Destroy=function()removed+=1 end}
        end,
        MoveProxy=function(proxy,point,y)proxy.X=point.X;proxy.Y=y end})
    api.Update(0);assert(not api.Active and camera.CameraSubject==subject)
    root.Position={X=0,Y=-20,Z=0}
    api.Update(.1);assert(api.Active and camera.CameraSubject.Y==3 and root.Position.Y==-20)
    root.Position={X=5,Y=-20,Z=0};render();assert(camera.CameraSubject.X==5)
    api.Update(.2);assert(raycasts==2 and created==1)
    root.Position={X=80,Y=-20,Z=0};render();assert(not api.Active and removed==1 and camera.CameraSubject==subject)
    surface=nil;api.Update(.3);assert(not api.Active)
    surface=0;api.Update(.6);assert(api.Active and created==2)
    local thirdParty={Parent=true}
    camera.CameraSubject=thirdParty;render();assert(camera.CameraSubject==thirdParty and not api.Active)
    camera.CameraSubject=subject;api.Update(.7);assert(api.Active)
    allowed=false;api.Update(.8);assert(not render and camera.CameraSubject==subject and removed==3)
    allowed=true;api.Update(.9);assert(api.Active)
    root={Parent=true,Position={X=80,Y=5,Z=0}}
    api.Update(1);assert(not api.Active and removed==4 and camera.CameraSubject==subject)
    api.Destroy();assert(removed==4)
    print("PASS Farm Desync: verified surface, render follow, large travel, camera ownership, safety suspension and respawn")
end
