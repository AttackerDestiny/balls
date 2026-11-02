return function(source)
    local mt={}
    local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    mt.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    mt.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    mt.__index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
    local root={Position=vec(100,200,300),Size=vec(2,2,2)}
    local human={Health=100,HipHeight=2}
    local character={FindFirstChild=function()return root end,FindFirstChildOfClass=function()return human end}
    local state={Running=true};local queries,pauses=0,0
    local pad={Parent=true,Position=vec(0,10,0),Size=vec(10,4,10)}
    local env=setmetatable({state=state,player={Character=character},Vector3={new=vec},destinations={},
        workspace={QueryDescendants=function()queries+=1;return {pad}end},
        movementRoot=root,positionAlign={},os={clock=function()return 1 end},
        finishAttackBurst=function()pauses+=1 end,stopSword=function()end,stopMovement=function()end,
        ensureMovementController=function()end,pivotRoot=function(r,p)r.Position=p end},{__index=getfenv()})
    local chunk=assert(loadstring(source));setfenv(chunk,env);chunk()
    assert(state.PanicInPlace()and queries==0 and root.Position.X==100 and root.Position.Y==200)
    root.Position=vec(101,205,301);state.PanicInPlace()
    assert(queries==0 and root.Position.X==100 and root.Position.Y==200 and pauses==1)
    state.SafeRejoinRequested=true;state.AutomationTeleporting=true;state.EscapeSafeRejoin()
    assert(root.Position.X==10100 and root.Position.Y==200 and root.Position.Z==300 and queries==0)
    state.ReleaseSafePanic();assert(not state.SafeModePanic and not state.SafePanicHerePosition)
    state.AutomationTeleporting=false;state.PanicToSpawn()
    assert(queries==1 and root.Position.X==0 and root.Position.Y==15.5,"Pad mode remains available for native floor/friend travel")
    print("PASS Direct Safe Mode: no spawn queries or detour, fixed current position, after-dispatch away move, cleanup, native pad mode intact")
end
