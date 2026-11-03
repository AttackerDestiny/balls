return function(source)
    local mt={__add=function(a)return a end}
    local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    local humanoid={Health=100,HipHeight=2,Parent=true,AutoRotate=true,PlatformStand=false,ChangeState=function()end}
    local root={Position=vec(10,50,20),Size=vec(2,2,2),Parent={FindFirstChildOfClass=function()return humanoid end}}
    local state={Running=true,Moving=true,TravelHold=true,ArenaFloat={Root=root}}
    local released,pivots=0,0
    state.ArenaFloat.Release=function()released+=1;state.ArenaFloat.Root=nil end
    local env={state=state,collisionParts={},lastSurfaceY=80,env={},movementStatus=function()end,
        Vector3={zero=vec(0,0,0),new=vec},RaycastParams={new=function()return {}end},
        Enum={RaycastFilterType={Exclude=1},HumanoidStateType={GettingUp=1}},
        workspace={FindFirstChild=function()end,Raycast=function()end},
        pivotRoot=function(_,position)pivots+=1;assert(position.Y==80)end}
    local fn=assert(loadstring(source.."\nreturn stopMovement"))
    setfenv(fn,setmetatable(env,{__index=getfenv()}))
    local stop=fn()
    stop("Disabled")
    assert(released==1 and pivots==1 and not state.Recovering and not state.Moving and not state.TravelHold)
    assert(humanoid.AutoRotate==true and humanoid.PlatformStand==false,"Float-only cleanup restores valid boolean properties")
    stop("Disabled again")
    assert(not state.Recovering,"Repeated OFF cannot leave recovery stuck")
    print("PASS Float-only movement cleanup: no missing AlignPosition access, valid humanoid properties, recovery release and repeated stop")
end
