return function(source)
    local make=assert(loadstring(source))()
    local mode="Farm"
    local subject={Parent=true,CameraOffset=0}
    local root={Parent=true,Position={X=0,Y=20,Z=0}}
    local camera={Parent=true,CameraSubject=subject}
    local surface,raycasts,created,removed=0,0,0,0
    local render
    local ended,held=0,0
    local api=make({Mode=function()return mode,"Paused"end,Character=function()return root,subject end,
        Camera=function()return camera end,CameraOffset=function(_,base,depth)return base+depth end,
        Surface=function()raycasts+=1;return surface end,
        Ground=function()return surface end,
        BeginHold=function(characterRoot,_,floor)
            held+=1
            local point=characterRoot.Position
            characterRoot.Position={X=point.X,Y=floor-20,Z=point.Z}
            return {Floor=floor,Position=characterRoot.Position,Previous=point}
        end,
        HoldValid=function(hold)return root.Position==hold.Position end,
        EndHold=function(hold,restore)
            ended+=1
            if restore then root.Position=hold.Previous end
        end,
        Render={Connect=function(_,callback)
            created+=1
            render=callback;return {Disconnect=function()removed+=1;render=nil end}
        end}})
    api.Update(0);assert(not api.Active and camera.CameraSubject==subject)
    root.Position={X=0,Y=-20,Z=0}
    api.Update(.1);assert(api.Active and camera.CameraSubject==subject and subject.CameraOffset==20 and root.Position.Y==-20)
    root.Position={X=5,Y=-20,Z=0};subject.CameraOffset=3;render();assert(subject.CameraOffset==23,"Preserve a new native offset")
    api.Update(.2);assert(raycasts==2 and created==1)
    root.Position={X=80,Y=-20,Z=0};render();assert(not api.Active and removed==1 and camera.CameraSubject==subject and subject.CameraOffset==3)
    surface=nil;api.Update(.3);assert(not api.Active)
    surface=0;api.Update(.6);assert(api.Active and created==2)
    local thirdParty={Parent=true}
    camera.CameraSubject=thirdParty;render();assert(camera.CameraSubject==thirdParty and not api.Active)
    camera.CameraSubject=subject;api.Update(.7);assert(api.Active)
    mode=nil;api.Update(.8);assert(not render and camera.CameraSubject==subject and removed==3)
    mode="Farm";api.Update(.9);assert(api.Active)
    root={Parent=true,Position={X=80,Y=5,Z=0}}
    api.Update(1);assert(not api.Active and removed==4 and camera.CameraSubject==subject)
    api.Release();assert(removed==4 and held==0,"Auto Farm keeps exclusive control of movement")
    mode="Hold";api.Update(2)
    assert(api.Active and root.Position.Y==-20 and held==1 and ended==0,"The toggle works with Auto Farm off")
    api.Release("Off",true)
    assert(root.Position.Y==5 and camera.CameraSubject==subject and ended==1)
    api.Update(3);mode="Farm";api.Update(3.1)
    assert(held==2 and ended==2,"Hand off to another controller without a manual restore")
    mode="Hold";camera.CameraSubject=thirdParty;api.Update(4)
    assert(api.Active and camera.CameraSubject==thirdParty and root.Position.Y==-20,"Spectating does not prevent the physical hold or get interrupted")
    mode=nil;api.Update(4.1)
    assert(ended==3 and not api.Active,"Dodge and travel can take over the standalone hold")
    print("PASS Farm Desync: standalone hold, verified surface, camera ownership, recovery and farm handoff")
end
