return function(source)
    local mt={};mt.__add=function(a,b)return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},mt)end
    local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end
    local state={SafeRejoinRequested=false,AutomationTeleporting=true,SafePanicPosition=vec(10,100,30)}
    local holds=0;state.PanicToSpawn=function()holds+=1;return true end
    local chunk=assert(loadstring(source));setfenv(chunk,setmetatable({state=state,player={},Vector3={new=vec}},{__index=getfenv()}));chunk()
    assert(not state.EscapeSafeRejoin()and holds==0)
    state.SafeRejoinRequested=true;assert(state.EscapeSafeRejoin())
    assert(state.SafeRejoinAway.X==10010 and state.SafeRejoinAway.Y==100 and state.SafeRejoinAway.Z==30)
    state.SafePanicPosition=state.SafeRejoinAway;state.EscapeSafeRejoin();assert(state.SafeRejoinAway.X==10010,"Move once, not another 10000 each frame")
    state.AutomationTeleporting=false;assert(not state.EscapeSafeRejoin())
    state.AutomationTeleporting=true;state.ModeratorBlocking=true;assert(not state.EscapeSafeRejoin())
    state.ModeratorBlocking=false;state.StopEverything=true;assert(not state.EscapeSafeRejoin())
    print("PASS Safe rejoin away: armed request required, fixed 10000-stud offset, same height, one destination, cancellation and moderator priority")
end
