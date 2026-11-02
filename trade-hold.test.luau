return function(source)
    local make=assert(loadstring(source))()
    local r={X=100,Y=70,Z=200};local active,blocked=false,false
    local pauses,releases,holds=0,0,{}
    local worker=make({Active=function()return active end,Blocked=function()return blocked end,
        Root=function()return r end,Anchor=function(root)return {X=root.X,Y=100,Z=root.Z}end,
        Pause=function()pauses+=1 end,Release=function()releases+=1 end,
        Hold=function(anchor)holds[#holds+1]={X=anchor.X,Y=anchor.Y-20,Z=anchor.Z}end})
    worker.Update();assert(pauses==0)
    active=true;worker.Update();r.X=900;worker.Update()
    assert(pauses==1 and holds[2].X==100 and holds[2].Y==80 and holds[2].Z==200)
    blocked=true;worker.Update();assert(#holds==2 and releases==0)
    blocked=false;worker.Update();assert(pauses==2 and holds[3].X==900)
    r={X=1,Z=2};worker.Update();assert(pauses==3 and holds[4].X==1)
    active=false;worker.Update();worker.Update();assert(releases==1)
    print("PASS Trade hold: fixed X/Z, ground minus 20, pause once, protection priority, respawn, release and resume once")
end
